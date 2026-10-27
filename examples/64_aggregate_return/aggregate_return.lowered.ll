; HAND-WRITTEN. Rules: 18, 26, 1, 5.
; Checked: r.hi + r.lo (the fadd rail %8 -> %9).
; Clean: the clone's chain (hi = x * c, lo = x - hi: %3, %4 of __cq_q_split_10, uncomputed and freed inside the clone) and
; the two copied-out result rails (%6, %7 in the caller), zeroed by the _unc twin and freed by the caller.
; Kept: x (%4, the rotated register) and the sum (%8, measured).
; Rotations: (Ry, x, th, 1).
; An aggregate return is a call with TWO results: the clone __cq_q_split_10 (mask left to right, §1.4) returns { i32, i32 },
; the handles of two fresh result rails (hi, lo), each copied out of the callee's chain before the chain is uncomputed (the
; one-result form is 34); the _unc twin takes both result handles first and zeroes both by recomputing the chain. The caller
; extracts the two handles (extractvalue on handles, classical) and continues out of place; when the sum is formed both
; results are garbage and the twin runs, then the caller frees both result rails.
source_filename = "aggregate_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @aggregate_return(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call fastcc { i32, i32 } @__cq_q_split_10(i32 %4, double %2)    ; IR: %5 = call @split(%4, %2), clone for mask (quantum, classical): two result handles
  %6 = extractvalue { i32, i32 } %5, 0    ; IR: %6 = extractvalue %5, 0  (handle of the hi rail; classical)
  %7 = extractvalue { i32, i32 } %5, 1    ; IR: %7 = extractvalue %5, 1  (handle of the lo rail; classical)
  %8 = call i32 @cq_template_fadd_f64(i32 %6, i32 %7)    ; IR: %8 = fadd double %6, %7  [result rail]
  call fastcc void @__cq_q_split_10_unc(i32 %6, i32 %7, i32 %4, double %2)    ; IR: uncompute %6 and %7 (both results of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call double @cqrt_measure_f64(i32 %8)    ; IR: %9 = cq_measure_f64(%8)
  ret double %9    ; IR: ret double %9
}

define internal fastcc { i32, i32 } @__cq_q_split_10(i32 %0, double %1) {
  %3 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %1)    ; IR: %3 = fmul double %0, %1
  %4 = call i32 @cq_template_fsub_f64(i32 %0, i32 %3)    ; IR: %4 = fsub double %0, %3
  %5 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: insertvalue ..., %3, 0  [result rail hi]
  call void @cqrt_copy_f64(i32 %3, i32 %5)    ; IR: copy r.hi out
  %6 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: insertvalue ..., %4, 1  [result rail lo]
  call void @cqrt_copy_f64(i32 %4, i32 %6)    ; IR: copy r.lo out
  call void @cq_template_fsub_f64_unc(i32 %4, i32 %0, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %3, i32 %0, double %1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  %7 = insertvalue { i32, i32 } poison, i32 %5, 0    ; IR: %5 = insertvalue poison, %3, 0  (the aggregate now carries handles)
  %8 = insertvalue { i32, i32 } %7, i32 %6, 1    ; IR: %6 = insertvalue %5, %4, 1
  ret { i32, i32 } %8    ; IR: ret { double, double } %6
}

define internal fastcc void @__cq_q_split_10_unc(i32 %0, i32 %1, i32 %2, double %3) {
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %3)    ; IR: recompute %3
  %6 = call i32 @cq_template_fsub_f64(i32 %2, i32 %5)    ; IR: recompute %4
  call void @cqrt_copy_f64(i32 %5, i32 %0)    ; IR: xor r.hi out of the hi rail
  call void @cqrt_copy_f64(i32 %6, i32 %1)    ; IR: xor r.lo out of the lo rail
  call void @cq_template_fsub_f64_unc(i32 %6, i32 %2, i32 %5)    ; IR: uncompute %4
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %2, double %3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_copy_f64(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
