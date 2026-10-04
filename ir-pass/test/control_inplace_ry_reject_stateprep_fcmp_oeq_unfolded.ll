; control_inplace_ry_reject_stateprep_fcmp_oeq_unfolded.ll — DECLINE: an
; `fcmp oeq` condition whose arm rotates the fp CONDITION register — MEASURED NOT
; TO FOLD, which is why F2 reads `ConstantInt` and is COMPLETE for the fp family.
;
;     double r = 0.0;  if (q == 0.0) { r = q; cq_theta(&r, .9); }  // probes `q32`/`q34`
;
; ⚠ THE REASON IS AN LLVM INVARIANT, NOT LUCK. `propagateEquality` will NOT
; substitute across `oeq`, because `oeq` is not a bitwise-equality proof
; (`+0.0 == -0.0`) — the SAME fact F1 relies on in the other direction when it
; refuses a `-0.0` seed against a `0.0` incoming. So the fp shapes reach the pass
; UNFOLDED, with the arm's arg-0 still naming `q`, and they decline on the
; condition-wire fence instead. Two consequences: F2 needs no `fcmp` arm, and the
; fp ACCEPT (`control_inplace_ry_stateprep_f64.ll`) is unambiguous BY
; CONSTRUCTION rather than by fence.
;
; RETIREMENT TRIGGER: if LLVM ever gains an `oeq`-edge substitution for non-zero,
; non-NaN constants, F2 owes an `fcmp` arm spelled with `bitwiseIsEqual` (never
; `compare`/`==`), and this fixture becomes its red-green pair.
;
; ⚠ PRD §14.3 ROW FP-1 PREDICTED R4's `rotation arm on a condition wire` AND IS
; CORRECTED HERE, for the same reason as the `..._unfolded_twin.ll` row: the
; arm's own theta IS the non-diagonal gate on the condition's wire, so
; `condWireDisposition` adjudicates first and `declineArm` re-spells. There is no
; unmasking move, because the masking gate is the arm itself. Measured IDENTICAL
; on the pre-Inc-4 oracle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_f64_controlled

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define i32 @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp oeq double %q, 0.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double %q, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 0.000000e+00, %entry ]
  %mq = call double @cq_measure_f64(double %q)
  %mr = call double @cq_measure_f64(double %rm)
  ret i32 0
}
