; control_swap_reject_switch_datamux_angle.ll — DECLINE (4.5 WI-4, the closed
; silent-miscompile): an all-ConstantInt DATA-MUX switch whose merge result reaches
; a rotation arg-1 ANGLE through an `icmp` -> select-condition carrier.
;
; THE HAZARD (verify-clean, NO downstream backstop): the data-mux merge phi has
; all-ConstantInt incomings, so it is UNTAINTED by SSA data-flow — unlike the
; value/phase merge (tainted incomings) the L110 `declineTaintedAngle` cannot help
; here. The emitter re-taints the lowered %out but does NOT re-propagate, and G3
; (`mergeReachesRotationArg1`) — the SOLE pre-emit backstop — crosses only
; casts/binops/phi/select-VALUE, NOT an `icmp` (a CmpInst) or a select CONDITION. So
; `%ang = (rm != 0) ? a : b` feeding `cq_phi` arg-1 (an angle derived from the
; quantum-controlled mux result, entangled with the scrutinee) would be SILENTLY
; accepted and lowered to `cqrt_rz(h, %ang)` (opt exit 0, verify-clean) — a Rule-3
; f64/angle wrong unitary. `proveSwitchDataMux` forecloses it: the data-mux merge
; result must be consumed ONLY by a measurement sink or a `ret` (escape), the
; conservative carrier-independent gate (Prime Directive: over-decline is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %c = icmp ne i32 %rm, 0
  %ang = select i1 %c, double %a, double %b
  %g = call i32 @cq_phi_si32(i32 %qx, double %ang)
  %m = call i32 @cq_measure_si32(i32 %g)
  ret i32 %m
}
