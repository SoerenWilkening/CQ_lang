; control_angle_select_ry_fresh_icmp_int.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; CQ_FINDINGS F4 with an INT condition register): a Ry ANGLE SELECT on a FRESH
; |0> `_Bool` target under a compare of a rotated int.
;
;     int x = 0; bool t = 0; cq_theta(&x, 1.0);
;     cq_theta(&t, x == 3 ? 0.3 : 0.7);
;
; The shipped single-compare stream with a LITERAL seed (admitted because the
; call site carries `nomerge`, `angleSelectLiteralSeedAdmissible`): the flag is
; the compare template, the target is minted by the true-arm gate.
; ANALYTIC: x == 3 -> t = Ry(.3)|0>, else t = Ry(.7)|0>; the flag strip
; recomputes `x == 3` on an untouched `x`, so the free is a proven-|0> free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %x = call i32 @cq_theta_si32(i32 0, double 1.000000e+00) #0
  %c = icmp eq i32 %x, 3
  %ang = select i1 %c, double 3.000000e-01, double 0x3FE6666666666666
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %mx = call i32 @cq_measure_si32(i32 %x)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %zt = zext i1 %mt to i32
  %s = add i32 %mx, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[X]], double 1.000000e+00)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[X]], i32 3)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[X]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[X]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])

; NEG-NOT: = select
; NEG-NOT: = icmp
; NEG-NOT: cq_theta_
