; lowering_libm_sqrtl_f80.ll — bd 3c6m.4: the headline `…l` shape. clang -O1
; lowers `sqrtl(long double)` to `@llvm.sqrt.f80`, an fp-DATA producer at the new
; long-double width. IntrinsicLowering (widthInTableSet now admits f80/f128)
; rewrites it to the additive-producer template `cq_template_sqrt_f80(handle)`.
; This is the single biggest coverage lever — the 26 intrinsic-backed `…l` trig/
; transcendental/round/fma variants all ride this path.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call i32 @cq_template_sqrt_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call x86_fp80 @cqrt_measure_f80(
;
; CHECK-NOT: llvm.sqrt.f80
; CHECK-NOT: cq_template_sqrt_f64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.sqrt.f80(x86_fp80)

define x86_fp80 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %s = call x86_fp80 @llvm.sqrt.f80(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}
