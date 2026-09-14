; control_inplace_ry_reject_rail_inloop_tainted_angle.ll — DECLINE (R2, Rule 3):
; a QUANTUM-DERIVED rotation angle on the in-loop bare-`_Bool` controlled-Ry arm.
;
; bd `test_C_libtooling-wx8g` moves nothing about the angle axis. R2 sits ABOVE
; R7's loop half in `classifyArms`, so this declines with the ANGLE string and
; not with the loop one — which is what makes the file a discriminator rather
; than a second copy of the loop reject.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle{{.*}}under quantum control

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %qa = call i32 @cq_theta_si32(i32 3, double 1.250000e-01)
  %fa = sitofp i32 %qa to double
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double %fa)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 1
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
