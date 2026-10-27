; HAND-WRITTEN. Rules: 16, 8, 5, 2.
; Checked: printf_double: cq_measure(x) > 0.0; printf_compound_cond and printf_nested_cond: x + y (measured).
; Clean: the compare flags (x > k), (y > m) and the conjunction flags (compound: (x > k) & (y > m); nested: the inner
; predicate outer & inner).
; Kept: the user registers x (and y); the tape rails (never freed; the backend prints the entries whose predicate
; measured 1).
; Rotations: Ry(th) on x (printf_double); Ry(tx) on x and Ry(ty) on y (printf_compound_cond, printf_nested_cond).
; Expected tape: printf_double prints "%f" of x unconditionally; printf_compound_cond prints "both x y" iff
; x > k && y > m; printf_nested_cond prints "inner y" iff x > k && y > m, then "outer x" iff x > k.
; 47's tape with three widenings (rule 16). A quantum DOUBLE field is a copy like an integer field: cqrt_tape_write_f64
; appends a fresh write-only f64 rail (the f64 angle rail of rule 15 concerns rotation angles, not data). A COMPOUND
; condition (-O1: select i1 %a, i1 %b, false) is the conjunction flag of 23, built by Toffoli into a |0> rail (rule 8);
; the entry and its fields are controlled by that flag, which is uncomputed after the entry. A NESTED condition is the
; depth-2 predicate of 08: the inner entry is controlled by outer & inner, the outer entry by the outer flag alone, in
; program order. The tape rails are never freed (47).
source_filename = "tape_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str.1 = private unnamed_addr constant [12 x i8] c"both %d %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [10 x i8] c"inner %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [10 x i8] c"outer %d\0A\00", align 1

define i32 @printf_double(double noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  call void @cqrt_tape_fmt(i32 %3, ptr @.str)    ; IR: %4 = printf(@.str, %3): open the entry with its format string
  %5 = call i32 @cqrt_tape_write_f64(i32 %3, i32 %4)    ; IR: %4 = printf(..., %3): field 0, a quantum double copied onto a fresh tape rail
  %6 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%3)
  %7 = fcmp ogt double %6, 0.000000e+00    ; IR: %6 = fcmp ogt double %5, 0.0  (classical)
  %8 = zext i1 %7 to i32    ; IR: %7 = zext i1 %6 to i32  (classical)
  ret i32 %8    ; IR: ret i32 %7
}

define i32 @printf_compound_cond(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %7 = cq_theta_si32(%0, %2)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %8 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %8 = cq_theta_si32(%1, %3)  [Ry]
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %4)    ; IR: %9 = icmp sgt i32 %7, %4
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %5)    ; IR: %10 = icmp sgt i32 %8, %5
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %11 = select i1 %9, i1 %10, i1 false  [path predicate of block %12]
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: %11 = %9 & %10
  call void @cqrt_tape_fmt_controlled(i32 %12, i32 %7, ptr @.str.1)    ; IR: block %12: %13 = printf(@.str.1, %7, %8): entry opened under the predicate
  %13 = call i32 @cqrt_tape_write_i32_controlled(i32 %12, i32 %7, i32 %8)    ; IR: field 0: %7 under the predicate
  %14 = call i32 @cqrt_tape_write_i32_controlled(i32 %12, i32 %7, i32 %9)    ; IR: field 1: %8 under the predicate
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: uncompute %11
  call void @cqrt_free(i32 %12)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %9, i32 %5)    ; IR: uncompute %10
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %8, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %15 = cq_measure_si32(%7)
  %16 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %16 = cq_measure_si32(%8)
  %17 = add nsw i32 %16, %15    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %17    ; IR: ret i32 %17
}

define i32 @printf_nested_cond(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %7 = cq_theta_si32(%0, %2)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %8 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %8 = cq_theta_si32(%1, %3)  [Ry]
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %4)    ; IR: %9 = icmp sgt i32 %7, %4  [path predicate of block %10]
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %5)    ; IR: %11 = icmp sgt i32 %8, %5  (block %10; pure, computed unguarded)
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %12 = %9 & %11
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: br i1 %11 inside block %10
  call void @cqrt_tape_fmt_controlled(i32 %12, i32 %7, ptr @.str.2)    ; IR: block %12: %13 = printf(@.str.2, %8): the inner entry under %9 & %11
  %13 = call i32 @cqrt_tape_write_i32_controlled(i32 %12, i32 %7, i32 %9)    ; IR: field 0: %8 under the inner predicate
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: uncompute the %12 predicate
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cqrt_tape_fmt_controlled(i32 %10, i32 %7, ptr @.str.3)    ; IR: block %14: %15 = printf(@.str.3, %7): the outer entry under %9
  %14 = call i32 @cqrt_tape_write_i32_controlled(i32 %10, i32 %7, i32 %8)    ; IR: field 0: %7 under the outer predicate
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %9, i32 %5)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %8, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %17 = cq_measure_si32(%7)
  %16 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %18 = cq_measure_si32(%8)
  %17 = add nsw i32 %16, %15    ; IR: %19 = add nsw i32 %18, %17  (classical)
  ret i32 %17    ; IR: ret i32 %19
}

declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare void @cqrt_tape_fmt_controlled(i32, i32, ptr)
declare i32 @cqrt_tape_write_f64(i32, i32)
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)
declare i32 @cqrt_alloc_f64(double)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cqrt_measure_i32(i32)
