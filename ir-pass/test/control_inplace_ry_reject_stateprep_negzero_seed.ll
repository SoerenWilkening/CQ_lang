; control_inplace_ry_reject_stateprep_negzero_seed.ll — DECLINE (F1): the MIRROR
; of `..._negzero_incoming.ll` — a `-0.0` SEED against a `0.0` incoming.
;
;     double r = 0.0;  if (q > 5.0) r = cq_theta(-0.0, .9);   // probe `p07c`, from C
;
; Both directions are reachable from plain C and both must decline; a fence that
; only checked one order would be the classic half-fence.
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
  %rt = call double @cq_theta_f64(double -0.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 0.000000e+00, %entry ]
  %mq = call double @cq_measure_f64(double %q)
  %mr = call double @cq_measure_f64(double %rm)
  ret i32 0
}
