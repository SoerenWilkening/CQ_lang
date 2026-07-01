; lowering_byref_modf_f64.ll — bd g387: by-ref math out-param, modf.
; modf's SECOND result is fp (the integer part, written through a `double*` cell),
; and it flows through `fptosi` before measure — the downstream-taint case. The
; marker canonicalization + re-propagate re-taints that whole `load->fptosi->
; measure` chain via the NORMAL mechanism, and lowerOps' up-front cast-width
; capture reads the marker's `double` result (before it is rewritten), so the
; fptosi lowers at the correct f64 width — NOT i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_modf_f64(i32 %[[Q:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cq_template_modfint_f64(i32 %[[Q]])
; Both results are converted to int for measure — the f64->i32 cast is preserved
; for the secondary (a wrong i32->i32 capture would be a silent miscompile).
; CHECK-DAG: call i32 @cq_template_fptosi_f64_to_i32(
;
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: call {{.*}}@modf(
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @modf(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @ex() {
entry:
  %ip = alloca double, align 8
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 8, ptr %ip)
  %fp = call double @modf(double %q, ptr %ip)
  %fpi = fptosi double %fp to i32
  %r1 = call i32 @cq_measure_si32(i32 %fpi)
  %ipv = load double, ptr %ip, align 8
  %ipi = fptosi double %ipv to i32
  %r2 = call i32 @cq_measure_si32(i32 %ipi)
  %sum = add i32 %r1, %r2
  call void @llvm.lifetime.end.p0(i64 8, ptr %ip)
  ret i32 %sum
}
