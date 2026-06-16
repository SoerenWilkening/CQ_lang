; control_swap_reject_switch_angle_arith.ll — DECLINE: the integer merge result
; reaches a rotation arg-1 ANGLE through value-CHANGING arithmetic (`(double)(qm ^ 5)`
; = merge -> xor -> sitofp -> arg-1). The Rule-13 round-2 R2-2 over-accept: G3 is the
; SOLE backstop (no re-taint like the select), so it must cross arithmetic/bitwise/cast
; carriers, not only value-preserving ones. The f64/angle miscompile family (Rule 3).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %r0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %r0, double 3.000000e-01)
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
  %x = xor i32 %qm, 5
  %ang = sitofp i32 %x to double
  %z = call i32 @cq_phi_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
