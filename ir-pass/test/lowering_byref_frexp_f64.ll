; lowering_byref_frexp_f64.ll — bd g387: by-ref math out-param, frexp.
; A tainted `@frexp(double, ptr)` (mantissa returned, exponent written through the
; out-cell) is canonicalized by `lowerByRefMath` into TWO Class-2 producer markers
; over the SAME live source — `cq_template_frexp_f64` (mantissa, same_unary) and
; `cq_template_frexpexp_f64_to_i32` (exponent, cross_unary) — and the memory cell
; (alloca + load + lifetime markers) is ERASED. Taint does not cross memory, so
; the read-back load's value is injected as the secondary producer, NOT propagated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_ry_f64(i32 %[[Q:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:     call i32 @cq_template_frexp_f64(i32 %[[Q]])
; CHECK:     call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[Q]])
;
; The memory cell is gone: no alloca, no load, no leftover @frexp / @cq_byref_*.
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: call {{.*}}@frexp(
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @frexp(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @ex() {
entry:
  %e = alloca i32, align 4
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %e)
  %m = call double @frexp(double %q, ptr %e)
  %mi = fptosi double %m to i32
  %r1 = call i32 @cq_measure_si32(i32 %mi)
  %ev = load i32, ptr %e, align 4
  %r2 = call i32 @cq_measure_si32(i32 %ev)
  %sum = add i32 %r1, %r2
  call void @llvm.lifetime.end.p0(i64 4, ptr %e)
  ret i32 %sum
}
