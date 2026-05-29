; lowering_add_qq_f64.ll — Per-width Q+Q fadd for the f64 ABI.
; Two classical thetas allocate two handles that flow through `fadd double`
; and lower to `cq_template_fadd_f64(handle, handle)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double 2.718280e+00)
; CHECK:     call void @cqrt_ry_f64(
; CHECK:     call i32 @cqrt_alloc_f64(double 3.141590e+00)
; CHECK:     call void @cqrt_ry_f64(
; CHECK:     call i32 @cq_template_fadd_f64(
;
; CHECK-NOT: call i32 @cq_template_fadd_f64_hl(
; CHECK-NOT: cq_theta_f64
; CHECK-NOT: fadd double

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)

define void @example() {
entry:
  %a = call double @cq_theta_f64(double 2.718280e+00, double 5.000000e-01)
  %b = call double @cq_theta_f64(double 3.141590e+00, double 5.000000e-01)
  %c = fadd double %a, %b
  ret void
}
