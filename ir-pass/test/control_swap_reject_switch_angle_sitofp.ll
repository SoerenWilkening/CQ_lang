; control_swap_reject_switch_angle_sitofp.ll — DECLINE: the INTEGER merge result
; reaches a rotation arg-1 ANGLE via an int->fp cast (`sitofp i32 %qm to double`).
; The Rule-13 H3 over-accept: G3 is the SOLE backstop for the switch (the emitter
; RAUWs the merge to an untainted handle, so declineTaintedAngle cannot fire later),
; so G3 must cross sitofp/uitofp. The f64/angle miscompile family (Rule 3).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 2.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ]
  %ang = sitofp i32 %qm to double
  %z = call i32 @cq_phi_si32(i32 %q, double %ang)
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
