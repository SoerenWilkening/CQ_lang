; control_swap_reject_switch_datamux_angle.ll — DECLINE (4.5 WI-4, the closed
; silent-miscompile): an all-ConstantInt DATA-MUX switch whose merge result reaches
; a rotation arg-1 ANGLE through an `icmp` -> select-condition carrier.
;
; THE HAZARD (verify-clean, NO pre-emit backstop): the data-mux merge phi has
; all-ConstantInt incomings, so it is UNTAINTED by SSA data-flow. `%ang = (rm != 0)
; ? a : b` feeding `cq_phi` arg-1 is an angle derived from the quantum-controlled mux
; result (entangled with the scrutinee) — a Rule-3 f64/angle wrong unitary if lowered.
;
; Under dugh (Phase 4×6) the pre-emit `proveSwitchDataMux` G6 merge-out gate is
; retired; `repropagateControlMerges` re-seeds a second propagation from the emitted
; `%out`, which taints `rm`, the `icmp ne`, and the `select` — whose CONDITION is now
; tainted. That tainted-condition select is a NEW control construct on the merge (out
; of dugh scope), so `declineReClassifiedControl` declines it `control flow under
; quantum control` (fires before `declineTaintedAngle` would fire on the tainted
; angle at rotation lowering). Either way it declines loudly — the angle never reaches
; `cqrt_rz`. Over-decline is safe (Prime Directive).
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
