; lowering_control_angle_nested_and.ll — Family B2, nested-AND diamond form,
; POSITIVE (test_C_libtooling-byx, cwk fix (b) PR2). The un-flattened
; `if(a){if(b){ang=x;}}` shape (PRD §2.7): `entry -[a]-> {mid, merge}`,
; `mid -[b]-> {arm, merge}`, `arm -> merge`, with a 3-way merge `φ`. When that φ
; is a classical `double` rotation angle it is the nested-AND analog of the
; one-content-arm diamond cwk hole. It lowers as controlled-rotation-by-difference
; on the COMBINED `a ∧ b` conjunction flag: the 3-way φ reduces to 2-way because
; the base angle `%y` rides BOTH the flag==0 edges (`%mid`, the inner-guard-false
; path, and `%entry`, the outer-guard-false path — SSA-identical), while the
; flag==1 angle `%x` rides the innermost `%arm` edge. So the base is `%y` and the
; controlled difference is `%x − %y`, gated by `f_conj = a ∧ b`.
;
; POLARITY LOCK: `reduceAngleDiamondPhi` names the flag==1 edge EXPLICITLY as the
; innermost `Arm` (one=Arm, zero=Pred) — NOT "the first non-zero φ incoming",
; which a 3-way φ could order as `%mid` (also base `%y`), giving a zero difference
; (a silent miscompile). The defensive base-equality check also forbids a φ whose
; non-arm edges disagree.
;
; This is the third of the four guarded detection paths now LOWERED (the other
; diamonds: lowering_control_angle_diamond.ll, _sym, _armneg; the fourth, the
; gated switch in lowering_control_angle_switch_gated.ll, is PR3).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The conjunction flag `f_conj = a ∧ b` (one Toffoli over the two eq-compares):
; CHECK:     %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 20)
; CHECK:     %[[FC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[FC]])
; The base + controlled-difference on the conjunction flag (base %y, diff %x−%y):
; CHECK:     call void @cqrt_rz_i32(i32 %[[HV:[a-zA-Z0-9_.]+]], double %y)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = fsub double %x, %y
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FC]], i32 %[[HV]], double %[[D]])
; Reverse-LIFO uncompute: conjunction first, then each sub-compare:
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[FA]], i32 %[[FB]], i32 %[[FC]])
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv(i32 %[[H]], i32 20)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[H]], i32 5)
; CHECK-NOT: phi double
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  br i1 %a, label %mid, label %merge
mid:
  %b = icmp slt i32 %q, 20
  br i1 %b, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %x, %arm ], [ %y, %mid ], [ %y, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
