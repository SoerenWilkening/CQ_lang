; control_angle_select_ry_constexpr_arm.ll — ACCEPT: the TRUE arm is a
; link-time constant that is not a `ConstantFP` (bd test_C_libtooling-dm7f.6,
; owner ruling 2026-10-03).
;
;     %ang = select i1 %c, double bitcast (i64 ptrtoint (ptr @g to i64) to double), double 0.3
;
; Hand IR only (every C punning idiom goes through a `load`, and a literal
; `bitcast (i64 K to double)` folds to a `ConstantFP` in the parser). The retired
; by-difference stream declined it (drbq Inc-2b round-2 finding R1 item 5)
; because the difference `fl(A - 0.3)` could not be evaluated at compile time. The
; X-bracket route (owner ruling 2026-10-13) evaluates nothing: the constant
; expression is the source's angle and lands in the f = 1 gate unchanged, so the gate
; denotes whatever value the linker gives it, exactly as an uncontrolled
; `cq_theta(&r, <that expression>)` would. It is not `undef` (the shared
; `valueCarriesUndef` clause still refuses one; see
; `control_angle_select_reject_undef_constexpr_arm.ll`).
;
; THIS FILE WAS `control_angle_select_reject_constexpr_arm.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOSUB < %t.ll

@g = global i32 7

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double bitcast (i64 ptrtoint (ptr @g to i64) to double), double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double bitcast (i64 ptrtoint (ptr @g to i64) to double))
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NOSUB-NOT: fsub
