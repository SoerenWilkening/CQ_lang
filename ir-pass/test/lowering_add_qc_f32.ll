; lowering_add_qc_f32.ll — Per-width Q+C fadd for the f32 ABI.
; One theta handle + one float literal flow through `fadd float` and lower
; to `cq_template_fadd_f32_hl(handle, classical)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f32(float 1.500000e+00)
; CHECK:     call i32 @cq_template_fadd_f32_hl(i32 %{{[a-zA-Z0-9_.]+}}, float 4.500000e+00)
;
; CHECK-NOT: call i32 @cq_template_fadd_f32(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_f32
; CHECK-NOT: fadd float

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare float @cq_theta_f32(float, double)

define void @example() {
entry:
  %a = call float @cq_theta_f32(float 1.500000e+00, double 5.000000e-01)
  %c = fadd float %a, 4.500000e+00
  ret void
}
