; control_angle_select_ry_rail_cond_rotated_after.ll — ACCEPT (bd
; test_C_libtooling-dm7f.54, adversarial probe "the condition is rotated
; after"): a Ry ANGLE SELECT on a fresh target under a bare `_Bool`, then a Ry on
; the CONDITION register.
;
;     bool a = 0, t = 0; cq_theta(&a, 1.0);
;     cq_theta(&t, a ? 0.7 : 0.3);
;     cq_theta(&a, 0.2);
;
; The later Ry relabels `a`'s basis, so it must land AFTER the copy flag is
; un-copied (`cnot(a, bf)` reads the pre-Ry basis the first cnot read) — the
; strip is emitted right after the consumer, and the rail ladder's DT prong
; (re-asked at the consumer, S11) accepts a gate PROVEN after it.
; ANALYTIC: t = a ? Ry(.7)|0> : Ry(.3)|0> on the PRE-Ry `a`; bf returns to 0 on
; every branch before Ry(.2) touches `a`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a0 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %ang = select i1 %a0, double 0x3FE6666666666666, double 3.000000e-01
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %a = call i1 @cq_theta_i1(i1 %a0, double 2.000000e-01) #0
  %ma = call i1 @cq_measure_i1(i1 %a)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %za = zext i1 %ma to i32
  %zt = zext i1 %mt to i32
  %s = add i32 %za, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 1.000000e+00)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 2.000000e-01)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])
