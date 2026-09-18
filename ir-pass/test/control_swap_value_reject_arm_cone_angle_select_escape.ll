; control_swap_value_reject_arm_cone_angle_select_escape.ll — DECLINE, the other
; half of the F-2 re-proof (see
; control_swap_value_reject_arm_cone_angle_select_consumer.ll for the obligation).
;
; THIS HALF: the angle select's consumer (`cq_theta`) is OUTSIDE the arm, so the
; select ESCAPES its block — which cone conjunct **(K3)** refuses. ⚠ Note WHICH
; string fires: `rotation angle`, not a cone string. (K3) keeps the select out of
; the cone, the region is not claimed, and the ordinary tainted-angle fence then
; speaks. That is the right owner and the reason the pre-flight's hazard cannot
; arise; do not "fix" this file to report a cone string.
;
; ⚠ IDENTICAL ON THE PRE-INCREMENT ORACLE (cq-opt 3368af1262695d7e4c…).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %ac = icmp slt i32 %q, 9
  %ang = select i1 %ac, double 1.0, double 2.0
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %ap = phi double [ %ang, %arm ], [ 0.0, %entry ]
  %r = call i32 @cq_theta_si32(i32 %pm, double %ap)
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
