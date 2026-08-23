; control_predmux_accept_xor_kept_cone_no_orphan.ll — ACCEPT (bd 3c6m.67), and
; the fixture for the SECOND orphan the Rule-13 rounds found. It is an ACCEPT
; fixture whose whole content is a NEGATIVE: the module must lower with the
; condition tree fully swept and NO stray gate left behind.
;
; THE SHAPE. A nested PredMux region whose entry branch condition is
; `xor i1 %ca, %cb`, and whose merge phi is `i1 false` on EVERY incoming. That
; phi is the trigger: the BoolAlg `∧ false` rule computes each edge predicate and
; then DROPS it, so BOTH literals die — the original xor (the true-edge literal)
; and the rebuilt `xor(a, ¬b)` (the false-edge literal). Contrived, yes; it is
; the smallest witness, and hand-written IR is the idiom every committed reject
; fixture in this tree is written to.
;
; *** WHAT WENT WRONG. *** `buildNegation`'s contract is bd `qesi`'s: "TRACK THE
; NODE WE ARE ABOUT TO REPLACE, or it is STRANDED." Every pre-existing arm
; honours it for free by RE-ENTERING `buildNegation` on each operand, which
; tracks on entry. The two-operand xor arm is the FIRST path that keeps an
; operand VERBATIM — necessarily so, because ¬(a⊕b) = a ⊕ ¬b negates only one
; side. So the kept cone entered no `MaybeDead`, `sweepDead` erased both xors,
; `%ca` dropped to zero uses, and nothing erased it. `lowerOps` then lowered that
; still-TAINTED compare into
;     %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
; with ZERO uses, no `_unc` and no `cqrt_free` — a dangling ENTANGLED which-path
; flag on a rail the user MEASURES two lines later (Rules 6/8). HEAD declines
; this module; the un-tracked version accepted it and leaked.
;
; *** THE TWIN CONTROL IS WHAT MAKES IT A DEFECT RATHER THAN A QUIRK. *** The
; byte-identical module with `or` substituted for `xor` emits NO compare at all —
; its cone is swept, because the or/and arm recurses and therefore tracks. So the
; leak was specific to this arm, not to the degenerate phi. After the fix the two
; emit IDENTICAL bodies, which is exactly what this fixture asserts.
;
; ONE `track()` WOULD NOT HAVE BEEN ENOUGH, and that is why the fix is a walk
; (`trackCondCone`): `sweepDead` is a `use_empty` fixpoint over `MaybeDead` ONLY,
; so erasing a tracked parent makes its children `use_empty` without ever erasing
; them. Measured on the sibling shape where the kept operand is `and i1 %ca, %cb`:
; THREE gates leaked (both compares and the `and`), not one.
;
; BOTH SHIPPED GATES ARE BLIND TO THIS, which is the whole reason it needs a
; fixture: `opt -verify` exits 0, and `free_pairing_check.py` prints the
; IDENTICAL line for the leaking module and its clean `or` twin — it counts
; `cqrt_alloc_*` mints, and an orphan compare flag is TEMPLATE-minted (bd `1739`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ca = icmp sgt i32 %q, 1
  %cb = icmp slt i32 %q, 9
  %cc = xor i1 %ca, %cb
  br i1 %cc, label %inband, label %merge
inband:
  %v1 = add i32 %q, 1
  %zz = icmp eq i32 %q, 4
  br i1 %zz, label %four, label %merge
four:
  %v2 = add i32 %q, 12
  br label %merge
merge:
  %pb = phi i1 [ false, %entry ], [ false, %inband ], [ false, %four ]
  %zx = zext i1 %pb to i32
  %s2 = add i32 %q, %zx
  %m  = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m
}

; The region lowers, and the whole condition tree is GONE — the `add i32 %q, 0`
; residue and the measure are all that survive:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     call i32 @cqrt_measure_i32(
;
; NOT ONE stray condition gate anywhere in the module. Every one of these would
; be a forward gate with no adjoint and no free — an entangled flag left on a
; measured rail, invisible to `opt -verify` and to free_pairing_check alike:
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: cq_template_and_i1
; CHECK-NOT: cq_template_or_i1
; CHECK-NOT: cq_template_xor_i1
; CHECK-NOT: cqrt_cnot
; CHECK-NOT: cqrt_toffoli
