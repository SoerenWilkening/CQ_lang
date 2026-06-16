; control_swap_reject_switch_phase_passthrough_dirty.ll — DECLINE: a PHASE switch with
; a PASSTHROUGH case (case 2: merge incoming == the scrutinee, routes q unchanged)
; whose arm BLOCK holds a stray live op — a fresh qubit + a USER MEASUREMENT on a
; SIBLING handle %s. The Rule-13 round-3 over-accept: the per-class content-arm scan
; (armPureSpine) skips passthrough cases, and G10 / foreign-pred cannot see %s, so the
; flatten would silently DROP the user measurement (Rule 5) + dangle its taint pointer
; (UAF). The driver's uniform passthrough-arm-empty scan declines it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %s0) {
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
  %s = call i32 @cq_theta_si32(i32 %s0, double 9.000000e-01)
  %sm = call i32 @cq_measure_si32(i32 %s)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ], [ %q, %a2 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
