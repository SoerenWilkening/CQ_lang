; lowering_control_angle_diamond_sym.ll — Family B2, symmetric diamond form,
; POSITIVE (test_C_libtooling-byx, cwk fix (b), WP8 path). The symmetric
; two-content-arm diamond (`if(q){ang=a;}else{ang=b;}`): BOTH arms fall through to
; a common merge whose `φ` is a classical `double` rotation angle. Lowered as
; controlled-rotation-by-difference. POLARITY LOCK: the flag==0 edge is the FALSE
; arm (`armF`), so the base MUST be `%b` and the difference `%a − %b` — NOT base
; `%a` (the design's naive "InPlaceEdge = ArmFalse ? Arm : Pred" rule would pick
; the true arm `%a` as base, a silent miscompile this fixture forbids).
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
  br i1 %c, label %armT, label %armF
armT:
  br label %merge
armF:
  br label %merge
merge:
  %ang = phi double [ %a, %armT ], [ %b, %armF ]  ; flag==1 ? %a : %b
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
