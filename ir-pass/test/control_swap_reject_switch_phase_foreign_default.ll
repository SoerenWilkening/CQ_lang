; control_swap_reject_switch_phase_foreign_default.ll — DECLINE: a PHASE switch whose
; default/straight-through edge carries a SEPARATE tainted rail %b, not the scrutinee
; %q (the Rule-13 round-2 R2-1 over-accept). The phase model is single-rail on q: the
; WI-2 emitter routes q and RAUWs the merge -> q, so a default of %b would be silently
; dropped while the case arms' q-encoding const rails mux against an unrelated wire.
; proveSwitchPhase's straight-through == scrutinee guard declines it. control flow.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %b0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %b0, double 6.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 2.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %b, %entry ], [ %g0, %a0 ], [ %g1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
