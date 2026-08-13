; lowering_fcmp_ueq_qq_f32.ll — 8rvn (Phase 7.1 iw81.4 §4.4): `fcmp ueq`
; (unordered-or-equal) is now in scope. A tainted Q+Q data-position `ueq` compare
; over two f32 thetas lowers to the fp-named bare-QQ symbol
; `cq_template_fcmp_ueq_f32(i32, i32)`. The recovered LOGICAL width is f32 (from
; the `HandleWidth` side-table at each `cq_theta_f32` mint, Increment-A reader),
; and `compareInScope` admits `ueq` on the QQ path exactly as on HL.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 2.000000e+00)
; CHECK:     call i32 @cqrt_alloc_f32(float 3.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ueq_f32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `fcmp` must be gone; no integer-named symbol; not the HL/LH form.
; CHECK-NOT: = fcmp ueq
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: _f32_hl(
; CHECK-NOT: _f32_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  %b = call float @cq_theta_f32(float 3.0, double 2.500000e-01)
  %c = fcmp ueq float %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
