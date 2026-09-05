; control_inplace_ry_reject_stateprep_negzero_incoming.ll — DECLINE (F1):
; `-0.0` merge incoming against a `0.0` seed.
;
;     double r = -0.0;  if (q > 5.0) r = cq_theta(0.0, .9);   // probe `p07b`, from C
;
; ⚠ THIS IS WHY F1 IS SPELLED AS BIT IDENTITY AND NOT AS NUMERIC EQUALITY. `-0.0
; == 0.0` is TRUE in IEEE, so an `APFloat::compare` (or `==`) would ACCEPT this
; and prepare a rail holding `+0.0` for a source whose straight-through value is
; `-0.0` — a wrong initial state, silently. A hand-written comparison must use
; `bitwiseIsEqual`. The shipped test is pointer equality, which is correct
; because LLVM uniques `ConstantFP` on the `APFloat` BITS, and both constants
; survive `-O1` distinct (measured).
; F1 — SEED IDENTITY (PRD §14.2a). On the `f=0` component the fresh rail holds
; |SEED>, so the merge is FAITHFUL only if the source's straight-through value IS
; the seed. Anything else is a DATA MUX between a prepared rail and an unrelated
; value, and a data mux has no rotation-arm lowering.
;
; F1 is an EXPLICIT clause with its own string, and that is the point of it.
; Before Inc 4 the shape was refused twice over BY POINTER IDENTITY ON UNIQUED
; CONSTANTS — R3's `RotBase != Routed` and the emitter's `T->getArgOperand(0) !=
; Base` — with no comment saying so and no fixture pinning it. Those two keep
; their own string for the shape they are about (a cross-handle mux); F1 runs
; FIRST so the message names the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control
; CHECK-NOT: cqrt_ry_f64_controlled

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define i32 @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 0.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ -0.000000e+00, %entry ]
  %mq = call double @cq_measure_f64(double %q)
  %mr = call double @cq_measure_f64(double %rm)
  ret i32 0
}
