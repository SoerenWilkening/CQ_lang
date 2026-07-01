; lowering_reject_byref_array_cell.ll — bd g387 decline. The out-param must be a
; simple scalar cell of the expected width; an aggregate/array cell is off-pattern
; (its shape is not the single-value producer model) → decline LOUDLY.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq by-ref math out-param under quantum lift (out-param cell type mismatch)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @frexp(double, ptr)

define i32 @ex() {
entry:
  %arr = alloca [2 x i32], align 4
  %q = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  %m = call double @frexp(double %q, ptr %arr)
  %ev = load i32, ptr %arr, align 4
  %r = call i32 @cq_measure_si32(i32 %ev)
  ret i32 %r
}
