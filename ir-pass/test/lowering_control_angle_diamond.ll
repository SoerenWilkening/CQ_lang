; lowering_control_angle_diamond.ll — Family B2, diamond form, POSITIVE
; (test_C_libtooling-byx, cwk fix (b)). The `br`-diamond analog of
; lowering_control_angle_rotdiff.ll: a tainted-condition one-content-arm diamond
; whose merge `φ` is a classical `double` rotation ANGLE feeding a `cq_phi`. Like
; the select form it lowers as controlled-rotation-by-difference: the
; unconditional base `Rz(u, b)` (the flag==0 / straight-through angle) then a
; flag-controlled `Rz(u, a−b)`. The `φ`'s flag==0 edge is `entry` (the
; true-successor diamond), so the base is `%b` and the difference is `%a − %b`.
; (Was the cwk-fix-(a) negative guard; fix (b) lowers it.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     call void @cqrt_rz_i32(i32 %[[H]], double %b)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = fsub double %a, %b
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]], double %[[D]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[H]], i32 5)
; CHECK-NOT: phi double
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]  ; flag==1 ? %a : %b
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
