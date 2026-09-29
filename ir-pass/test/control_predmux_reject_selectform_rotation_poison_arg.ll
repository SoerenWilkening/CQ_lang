; control_predmux_reject_selectform_rotation_poison_arg.ll — REJECT.
; A VERIFY-CLEAN SILENT MISCOMPILE, found by the bd u1rp Rule-13 round and fixed
; with it. Read this one before touching the rotation leaf.
;
; `coneDefinedAfterFlagDrop` treats a `cq_theta`/`cq_phi` result as a defined
; leaf and `continue`s WITHOUT operand recursion. That assumption covers the
; ROTATION'S RESULT — and for `cq_phi` the result IS operand 0, because
; `RotationLowering` RAUWs it verbatim (`Phi->replaceAllUsesWith(Op)`). So a
; `poison` argument does not stay in the argument slot: it becomes the leaf's
; VALUE and flows into the predicate. The `valueCarriesUndef` fence bd 3c6m.14.2
; shipped for a DIRECT poison operand (see
; control_predmux_reject_selectform_undef_leaf.ll, `%r = add i32 %q, poison`) was
; evaded by exactly one hop through a rotation.
;
; WHAT THE PRE-FIX PLUGIN DID, measured end to end: `opt` exit 0, `opt -verify`
; clean, `free_pairing_check.py` STRICT 6/6 verified, 0 violations. Linked at the
; shipped -O0 stage 3 the trace read, IDENTICALLY ACROSS RUNS (so this is not the
; ASLR artefact refuted in bd bu96):
;
;     cq_template_icmp_slt_i32_hl(h0, 73896)      -> h4
;     cq_template_icmp_slt_i32_hl_unc(h4, h0, 1401299752)
;     cqrt_free(h4)
;
; `poison` lowers to `IMPLICIT_DEF`, which LLVM may materialise DIFFERENTLY PER
; USE. The adjoint therefore inverts a different predicate than the forward
; computed, so rail h4 is left dirty AND entangled with h0, and the `cqrt_free`
; on the next line is a hidden measurement that collapses `q` — Rules 6 and 8.
; No gate in the tree could see it: the trace cannot witness "freed at |0>", and
; the free-pairing checker sees a structurally correct forward/`_unc`/free triple
; because the operands differ only at RUNTIME.
;
; THE PAIRING CHANNEL IS THE WHOLE DISTINCTION, and it is why this rejects while
; bd bu96's poison-generating ConstantExpr does not: a uniqued Constant is ONE
; link-time relocation, so both uses read the same value and the adjoint stays
; paired (measured: 1 distinct literal across 4 paired sites, versus 2 here).
;
; SCOPE, stated so the fence is not later "generalised" wrongly: the same shape
; with a plain `and i1 %a, %b` instead of the shielded select still lowers, and
; that is CORRECT for THIS surface — there the poison reaches the `br`, so the
; SOURCE is already UB and nothing well-defined is broken, whereas
; `select i1 %a, i1 %b, i1 false` yields `false` CLEANLY when %a is false and the
; flatten's `and` destroys that. THE FENCE THEREFORE BELONGS IN THE CONE PROOF,
; NOT IN THE LOWERING.
;
; What that sentence must NOT be read as claiming: that the shielded form is the
; only place in the compiler where a literal poison breaks forward/`_unc`
; pairing. A Rule-13 round exhibited the same pairing break on the 4.4 SELECT
; surface with no branch anywhere and no UB in the source — a different owner
; (`SelectClassify`/`SelectMergeEmit`), filed separately, and NOT fixed by this
; fence.
;
; POSITIVE CONTROL: control_predmux_accept_selectform_seed_flags_preserved.ll —
; a rotation with a DEFINED, non-trivial argument must still accept.
;
;
; ── MERGED 2026-09-29 (bd test_C_libtooling-2dfk, exact-duplicate removal) ──
; `control_predmux_reject_selectform_rotation_hop_chained.ll` was DELETED: it was this module with this
; file's RUN and CHECK lines byte-for-byte (every non-comment line and every
; directive identical, so it re-ran this exact test). Why: the bd 3qlq migration RAUWed each `cq_phi_si32(x, .)` to `x`, so the two-hop chain collapsed to the depth-1 `poison` this file pins.
; Its unique header prose follows VERBATIM, because it carries the history (and
; any retirement trigger) of the shape it once pinned:
;
; │ control_predmux_reject_selectform_rotation_hop_chained.ll — REJECT (bd u1rp).
; │ THE FENCE MUST BE A RECURSION, NOT AN OPERAND CHECK. This fixture exists
; │ because the first draft of the sibling fence was evaded by ONE MORE HOP, and a
; │ Rule-13 round exhibited it end to end.
; │
; │ `RotationLowering` RAUWs a `cq_phi` result to OPERAND 0 verbatim
; │ (`Phi->replaceAllUsesWith(Op)`), so `cq_phi` is NOT a defined cone leaf — its
; │ value IS operand 0. A draft that merely inspected the rotation's ARGUMENTS for
; │ `undef`/`poison` therefore fenced depth 1 and nothing else:
; │
; │ %r1 = call i32 @cq_phi_si32(i32 poison, double 2.500000e-01)   ; caught
; │ %r2 = call i32 @cq_phi_si32(i32 %r1,    double 7.500000e-01)   ; NOT caught
; │
; │ because `%r1` is an Instruction, not an `undef` Constant, so the argument scan
; │ saw nothing. `classifyConeNode` now returns `ConeNode::PassThrough` for
; │ `cq_phi` and both walkers follow operand 0, so the chain is traversed to its
; │ root at any depth.
; │
; │ ON THE PRE-FIX PLUGIN this module CLAIMED AND FLATTENED (`opt` exit 0,
; │ `opt -verify` clean, `free_pairing_check` STRICT 6/6, 5 toffolis) and the
; │ linked -O0 binary printed the same pairing break the depth-1 exhibit did:
; │ a forward `cq_template_icmp_slt_i32_hl(h0, 73896)` against an adjoint
; │ `_unc(h4, h0, 1401299752)`, then `cqrt_free(h4)` on a rail that is neither
; │ |0> nor unentangled. Rules 6 and 8.
; │
; │ IT IS REACHABLE FROM STOCK clang -O1, not only from hand-written IR: an
; │ uninitialised local passed through two chained `cq_phi` phases emits
; │ `cq_phi_si32(i32 noundef undef, ...)` into a genuine two-merge-phi shielded
; │ diamond.
; │
; │ SIBLINGS: control_predmux_reject_selectform_rotation_poison_arg.ll is depth 1;
; │ control_predmux_reject_selectform_rotation_hop_inherent_poison.ll is the same
; │ hop laundering an op that has no flag to drop at all. The positive control for
; │ all three is control_predmux_accept_selectform_seed_flags_preserved.ll, whose
; │ `cq_theta` seed is a defined, non-trivial expression and must still accept —
; │ `cq_theta` remains a genuine leaf because its result is a fresh
; │ `cqrt_alloc_<W>` handle that does not depend on the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:  | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  ; cq_phi RAUWs its result to operand 0 — so poison IS `poison`.
  %b = icmp slt i32 %q, poison
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

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

; CHECK: error: {{.*}}in function probe i32 (i32): cq controlled lowering: control flow under quantum control
