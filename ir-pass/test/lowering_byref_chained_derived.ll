; lowering_byref_chained_derived.ll — bd g387 Rule-13 re-review regression
; (DEFECT C residual): a chained by-ref where the OUTER call's fp source is
; DERIVED from the inner call's OUT-CELL through an intervening op (here
; `modf(i + 1.0)` with `i` = the inner modf's integer-part cell), not the inner
; primary marker directly. The single-pass marker-seed fix missed this (the
; derived `fadd` isn't tainted at by-ref time), stranding the outer call as a raw
; @modf(i32 handle) -> broken module. The FIXPOINT (re-propagate between passes)
; taints the out-cell marker's downstream (the fadd) on the next pass, so the
; outer call is recognized and lowered. Must lower clean, no raw @modf survivor.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Inner modf -> frac + int-part(%[[I]]); the int-part feeds `+ 1.0`; the OUTER
; modf reads that derived value (%[[OP]]).
; CHECK:     call i32 @cq_template_modf_f64(i32 %[[Q:[a-zA-Z0-9_.]+]])
; CHECK:     %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_modfint_f64(i32 %[[Q]])
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[I]], double 1.000000e+00)
; CHECK:     call i32 @cq_template_modf_f64(i32 %[[OP]])
; CHECK:     call i32 @cq_template_modfint_f64(i32 %[[OP]])
;
; CHECK-NOT: call {{.*}}@modf(
; CHECK-NOT: alloca
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @modf(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @slice(double %0) {
entry:
  %i = alloca double, align 8
  %j = alloca double, align 8
  %q = call double @cq_theta_f64(double %0, double 5.000000e-01)
  %frac = call double @modf(double %q, ptr %i)      ; inner: int part -> %i
  %iv = load double, ptr %i, align 8
  %d = fadd double %iv, 1.000000e+00                 ; derived: i + 1.0
  %f = call double @modf(double %d, ptr %j)          ; outer: fp source is derived
  %fraci = fptosi double %frac to i32
  %m1 = call i32 @cq_measure_si32(i32 %fraci)
  %fi = fptosi double %f to i32
  %m2 = call i32 @cq_measure_si32(i32 %fi)
  %jv = load double, ptr %j, align 8
  %ji = fptosi double %jv to i32
  %m3 = call i32 @cq_measure_si32(i32 %ji)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  ret i32 %s2
}
