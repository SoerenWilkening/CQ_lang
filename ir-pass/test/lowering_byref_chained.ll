; lowering_byref_chained.ll — bd g387 Rule-13 regression (DEFECT C): a CHAINED
; by-ref call (one by-ref primary result feeding another by-ref's fp input, the
; intended compose shape, e.g. modf(frexp(x).mantissa)) must lower correctly, not
; strand the outer call as a raw @modf taking an i32 handle (broken module).
; lowerByRefMath seeds each freshly-minted primary marker into the live taint set,
; so a later site whose fp source is that marker is recognized and lowered in the
; same forward pass (sites are in program order, def before use).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Inner frexp -> two producers off the source; OUTER modf reads the inner MANTISSA
; producer (%[[M]]) as its fp source -> its own two producers.
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_frexp_f64(i32 %[[Q:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[Q]])
; CHECK:     call i32 @cq_template_modf_f64(i32 %[[M]])
; CHECK:     call i32 @cq_template_modfint_f64(i32 %[[M]])
;
; No raw libc by-ref call survives, no memory cell left.
; CHECK-NOT: call {{.*}}@frexp(
; CHECK-NOT: call {{.*}}@modf(
; CHECK-NOT: alloca
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @frexp(double, ptr)
declare double @modf(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @ex() {
entry:
  %e = alloca i32, align 4
  %ip = alloca double, align 8
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  %m = call double @frexp(double %q, ptr %e)      ; inner: mantissa
  %fb = call double @modf(double %m, ptr %ip)     ; outer: modf of the mantissa
  %fbi = fptosi double %fb to i32
  %r1 = call i32 @cq_measure_si32(i32 %fbi)
  %ev = load i32, ptr %e, align 4
  %r2 = call i32 @cq_measure_si32(i32 %ev)
  %ipv = load double, ptr %ip, align 8
  %ipi = fptosi double %ipv to i32
  %r3 = call i32 @cq_measure_si32(i32 %ipi)
  %s1 = add i32 %r1, %r2
  %s2 = add i32 %s1, %r3
  ret i32 %s2
}
