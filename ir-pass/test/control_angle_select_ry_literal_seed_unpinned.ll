; control_angle_select_ry_literal_seed_unpinned.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; item A1): the R10 twin of `control_angle_select_reject_literal_seed_forward_pinned.ll`
; with seed 6. `%t` is pinned to 5, nothing is pinned to 6, so the `nomerge`
; literal seed is a FRESH rail: `alloc(6); ry_c(bf, h, .9); x; ry_c(bf, h, .3); x`
; on the CNOT copy of the `_Bool` condition.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[F:bf[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[F]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %k, double 5.000000e-01) #0
  %c = call i1 @cq_theta_i1(i1 false, double 6.000000e-01) #0
  %lo = and i32 %q, 3
  %q20 = or i32 %lo, 20
  %t = sdiv i32 %q20, 4
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 6, double %ang) #0
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mr, %mt
  ret i32 %s
}
attributes #0 = { nomerge nounwind }
