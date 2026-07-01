; lowering_libm_erfl_f80.ll — bd 3c6m.4: the DIRECT-libm `…l` path. clang -O1
; keeps `erfl(long double)` as a direct `@erfl` call (NOT an @llvm.* intrinsic),
; so LibmLowering recognizes it by EXACT name (nameLd == "erfl") and, with
; isFpWidth now admitting f80, lowers it to the same-width additive-producer
; template `cq_template_erf_f80(handle)`. Covers the 20 direct-libm `…l` variants
; (cbrtl/erfl/atan2l/ldexpl/ilogbl/…).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call i32 @cq_template_erf_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call x86_fp80 @cqrt_measure_f80(
;
; CHECK-NOT: call x86_fp80 @erfl(
; CHECK-NOT: cq_template_erf_f64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @erfl(x86_fp80)

define x86_fp80 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call x86_fp80 @erfl(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}
