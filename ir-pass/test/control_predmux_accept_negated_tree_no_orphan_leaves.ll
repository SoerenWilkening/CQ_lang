; control_predmux_accept_negated_tree_no_orphan_leaves.ll — ACCEPT (bd qesi).
; ARM: `buildNegation` REPLACES each compare leaf with a fresh inverse-predicate
; compare, and the ORIGINAL leaves were never `track()`ed — so they survived
; `sweepDead` with zero uses and `lowerOps` lowered them to forward
; `cq_template_icmp_*` gates that are NEVER uncomputed and NEVER freed.
;
; *** THIS IS ORDINARY C, NOT A HAND-BUILT SHAPE. *** `if (q > 3 && q < 100)` at
; `clang -O1` canonicalizes to exactly this INVERTED polarity — the gate arm is the
; FALSE successor (CLAUDE.md Rule 9) — which is what routes the condition through
; `buildNegation` rather than through `canonicalizePred`.
;
; WHY NEITHER EXISTING GATE CAUGHT IT. `opt` exits 0 and the verifier is clean: the
; module is well-typed, the orphans are merely dead. And `free_pairing_check.py`
; reported "6 verified, 0 violation(s), 0 unproven" on the pre-fix output, because
; it counts only `cqrt_alloc_*` mints and an orphan rail is TEMPLATE-minted (filed
; as bd 1739). So this fixture is the only thing standing between that defect and a
; silent return — it must assert on the EMITTED STREAM, not on an exit code.
;
; PRE-FIX OUTPUT, verbatim, first four lines of the lowered body — note that every
; OTHER compare rail in the same function is properly `_unc`'d and then freed,
; which is what makes the two orphans unmistakable:
;     %h = call i32 @cqrt_alloc_i32(i32 %u)
;     call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
;     %h_cmp6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)     <-- ORPHAN
;     %h_cmp7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 100)   <-- ORPHAN
; Rule 6/8: a rail written and left entangled with `q`, never uncomputed, never
; freed. Harmless to the measured ANSWER but a coherence hazard — it dephases `q`
; under later interference — and, per the pass's own note at the sibling cleanup,
; "trivially avoidable since the op is DEAD".
;
; THE ASSERTION IS THAT THE ORIGINAL PREDICATES ARE ABSENT ENTIRELY. Post-fix the
; flag tree is built from the INVERSE predicates (`sle`/`sge`, leaf-inverted
; De Morgan — the no-NOT invariant), so `sgt`/`slt` must not appear anywhere in the
; module, not even as a `declare`. A CHECK-NOT here is NOT vacuous: this is an
; ACCEPT, so `cq-opt` prints the whole module to stdout.
;
; ARM-KILL: `control_predmux_accept_positive_tree_orphan_armkill.ll` is this exact
; module with only the branch polarity flipped. It orphans NOTHING, before or after
; the fix, because on THIS module's tree — a plain `and i1` over two compare leaves,
; with no shielded select anywhere — `canonicalizePred` REUSES the original leaves
; and only the tree ROOT dies, and the root is already tracked as the branch
; condition. That pair is what pins the cause to `buildNegation` specifically,
; rather than to "rebuilding".
;
; *** READ THAT SENTENCE ONLY AS SCOPED, which is the whole lesson of this family:
; it is true of a shield-free tree and was FALSE as a general statement about
; `canonicalizePred`, which orphaned a whole dead 4.4 merge on a shield at depth ≥ 1
; until bd `kqqv` (`trackCondCone(V)` at the top of that function). See
; control_predmux_accept_nonroot_shield_no_orphan.ll for the depth table. ***
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=NOORPHAN

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %sc = and i1 %a, %b
  br i1 %sc, label %merge, label %arm      ; arm = FALSE successor (clang -O1)

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The region IS claimed and flattened, and the flag tree uses the INVERSE
; predicates — that is the leaf-inverted De Morgan of `a && b`:
; CHECK: cq_template_icmp_sle_i32_hl
; CHECK: cq_template_icmp_sge_i32_hl
; CHECK: cqrt_copy_i32_controlled

; And the ORIGINAL predicates are gone from the module entirely — no orphan gate,
; and hence no dead entangled rail. These lines are the whole point of the file:
; NOORPHAN-NOT: cq_template_icmp_sgt
; NOORPHAN-NOT: cq_template_icmp_slt
