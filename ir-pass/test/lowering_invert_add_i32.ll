; lowering_invert_add_i32.ll — manual inversion bracket (i32 ABI). EXPECTED
; TO FAIL until the inversion-lowering milestone lands (CQ.h calls it M10;
; the runtime already ships the cq_template_*_inv bodies).
;
; A theta taint source feeds an `add` that sits inside a
; cq_invert_begin()/cq_invert_end() bracket (the __cq_invert_begin/_end marker
; calls, pinned by the asm memory barriers the header macro emits). The desired
; lowering (a) consumes the markers — they must NOT survive into the output —
; and (b) lowers the bracketed add to the INVERSE template
; cq_template_add_i32_hl_inv (note the _inv suffix) rather than the plain
; cq_template_add_i32_hl.
;
; Today the pass ignores the markers: they survive as calls (so the program
; won't even link — no runtime body for __cq_invert_*) and the add lowers to
; the plain forward template. Hence XFAIL. When inversion lands this test will
; XPASS — that is the signal to delete the XFAIL line below.
;
; XFAIL: *
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double
; CHECK:     call i32 @cq_template_add_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: @__cq_invert_begin
; CHECK-NOT: @__cq_invert_end
; CHECK-NOT: call i32 @cq_template_add_i32_hl(i32
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @__cq_invert_begin()
declare void @__cq_invert_end()

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  call void @__cq_invert_begin()
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
  %b = add nsw i32 %a, 2
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
  call void @__cq_invert_end()
  %m = call i32 @cq_measure_si32(i32 %b)
  ret void
}
