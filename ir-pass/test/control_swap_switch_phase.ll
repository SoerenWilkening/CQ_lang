; control_swap_switch_phase.ll — a clean homogeneous PHASE switch (N=3).
;
; WI-1 (emit stubbed): the classifier PROVES the shape (each arm a const-folded
; cq_phi over its case literal — the §5 re-anchor signature, arg-0 = the case
; constant) and reaches the would-be-ACCEPT, firing the TRANSITIONAL "switch"
; decline. This pins that a clean phase switch is RECOGNISED-but-deferred (not
; wrongly declined). WI-2 graduates: lands emitSwitchPhaseRegion + the routed
; stream CHECKs (eq -> cswap -> rz -> cswap -> free -> eq_inv -> free), flips the
; classifier accept to push, and replaces this RUN with the positive pipeline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1
                                i32 2, label %a2 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 2.000000e-01)
  br label %merge
a2:
  %g2 = call i32 @cq_phi_si32(i32 2, double 3.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ], [ %g2, %a2 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
