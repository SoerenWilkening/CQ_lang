; HAND-WRITTEN. Rules: 24, 9, 8, 4, 5, 2.
; Checked: r = x < k ? x * tiny : x - tiny (%9, measured as %10).
; Clean: both arm rails (%7 = x * tiny, %8 = x - tiny) and the select flag x < k (%5), uncomputed and freed.
; Kept: x (%4, the rotated register, a source of r) and r (%9, measured).
; Rotations: (Ry_f64, x, th, 1).
; The volatile global is internal, never written and its address never escapes, so nothing outside the program can
; observe the read: it is a classical constant (rule 24, the same ruling as the volatile local of 32) and becomes a plain
; classical load passed as the _hl literal of each arm. The folded if/else is a select on a fresh rail (rule 9, as 04):
; both arms are computed unguarded into fresh rails, merged by one select template under the compare flag, and then
; both arm rails and the flag are uncomputed.
source_filename = "volatile_global.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tiny = internal global double 1.000000e-300, align 8    ; IR: @tiny: internal, never written, address never escapes

define double @volatile_global(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %4, double %2)    ; IR: %5 = fcmp olt double %4, %2  [select flag]
  %6 = load double, ptr @tiny, align 8    ; IR: %6 = load volatile double, ptr @tiny: unobservable, so a plain classical load
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %4, double %6)    ; IR: %7 = fmul double %4, %6  (then arm)
  %8 = call i32 @cq_template_fsub_f64_hl(i32 %4, double %6)    ; IR: %8 = fsub double %4, %6  (else arm)
  %9 = call i32 @cq_template_select_f64(i32 %5, i32 %7, i32 %8)    ; IR: %9 = select i1 %5, double %7, double %8  [result rail]
  call void @cq_template_fsub_f64_hl_unc(i32 %8, i32 %4, double %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %4, double %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %5, i32 %4, double %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %10 = call double @cqrt_measure_f64(i32 %9)    ; IR: %10 = cq_measure_f64(%9)
  ret double %10    ; IR: ret double %10
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fcmp_olt_f64_hl(i32, double)
declare void @cq_template_fcmp_olt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fsub_f64_hl(i32, double)
declare void @cq_template_fsub_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
