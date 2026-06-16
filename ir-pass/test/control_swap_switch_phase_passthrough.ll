; control_swap_switch_phase_passthrough.ll — a clean PHASE switch with an EMPTY
; passthrough case (case 2 routes q unchanged, empty arm body). Confirms the
; round-3 driver passthrough-arm scan does NOT over-decline a LEGITIMATE empty
; passthrough: the classifier reaches the would-be-ACCEPT and fires the transitional
; "switch" string (graduates to the lowered stream in WI-2).
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
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ], [ %q, %a2 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
