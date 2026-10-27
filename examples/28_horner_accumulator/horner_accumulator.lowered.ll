; HAND-WRITTEN. Rules: 14, 4, 5, 7, 2.
; Checked: s = Horner evaluation of coef[0..n-1] at x (measured).
; Clean: every trip's accumulator rail and product rail s * x (both popped and uncomputed by the mirror, the sum
; before the product it read) and the seed rail holding coef[0] (never written, freed directly, rule 7).
; Kept: the user register x; the copied-out result rail (measured).
; Rotations: Ry(th) on x.
; coef is classical memory read with a classical index, so each coefficient is an ordinary load passed as a literal
; (the fadd's _hl shape, rule 4). clang contracts s * x + coef[i] into llvm.fmuladd.f64, which is UNFUSED (§2): each
; trip is an fmul into a fresh product rail and an fadd_hl of the product and coef[i] into a fresh accumulator rail.
; The accumulator chain is a classical loop with the handle stack (rule 14, classical bound): each trip pushes the old
; accumulator and its product rail, and the mirror (after the result is copied out) pops them and uncomputes the sum
; then the product (rule 5, dependency order). n <= 1 takes the classical edge and
; measures the seed rail itself.
source_filename = "horner_accumulator.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @horner(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = load double, ptr %2, align 8    ; IR: %6 = load double, ptr %2  (classical)
  %7 = call i32 @cqrt_alloc_f64(double %6)    ; IR: incoming %6 of phi %15 / %11  [s before trip 1]
  %8 = icmp sgt i32 %3, 1    ; IR: %7 = icmp sgt i32 %3, 1
  br i1 %8, label %11, label %9    ; IR: br i1 %7, label %8, label %10

9:
  %10 = call double @cqrt_measure_f64(i32 %7)    ; IR: %12 = cq_measure_f64(%11), %11 = %6 from %4
  ret double %10    ; IR: ret double %12

11:
  %12 = zext nneg i32 %3 to i64    ; IR: %9 = zext nneg i32 %3 to i64
  br label %13

13:
  %14 = phi i64 [ 1, %11 ], [ %20, %13 ]    ; IR: %14 = phi i64 [ 1, %8 ], [ %19, %13 ]  (classical)
  %15 = phi i32 [ %7, %11 ], [ %19, %13 ]    ; IR: %15 = phi double [ %6, %8 ], [ %18, %13 ]
  %16 = getelementptr inbounds double, ptr %2, i64 %14    ; IR: %16 = getelementptr inbounds double, ptr %2, i64 %14
  %17 = load double, ptr %16, align 8    ; IR: %17 = load double, ptr %16  (classical)
  %18 = call i32 @cq_template_fmul_f64(i32 %15, i32 %5)    ; IR: %18 = llvm.fmuladd.f64(%15, %5, %17)  [product s * x]
  %19 = call i32 @cq_template_fadd_f64_hl(i32 %18, double %17)    ; IR: %18 = llvm.fmuladd.f64(%15, %5, %17)  [sum + coef[i]]
  call void @cqrt_push(i32 %15)    ; IR: %15 [old accumulator, kept for the mirror]
  call void @cqrt_push(i32 %18)    ; IR: %18 [product rail, kept for the mirror]
  %20 = add nuw nsw i64 %14, 1    ; IR: %19 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, %12    ; IR: %20 = icmp eq i64 %19, %9
  br i1 %21, label %22, label %13    ; IR: br i1 %20, label %10, label %13

22:
  %23 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %11 = phi double [ %18, %13 ]  [copied-out result]
  call void @cqrt_copy_f64(i32 %19, i32 %23)    ; IR: %11
  br label %24

24:
  %25 = phi i64 [ %14, %22 ], [ %31, %24 ]    ; IR: trip being undone, from the last down to 1
  %26 = phi i32 [ %19, %22 ], [ %30, %24 ]
  %27 = getelementptr inbounds double, ptr %2, i64 %25
  %28 = load double, ptr %27, align 8    ; IR: %17 of that trip (classical)
  %29 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %30 = call i32 @cqrt_pop()    ; IR: that trip's %15
  call void @cq_template_fadd_f64_hl_unc(i32 %26, i32 %29, double %28)    ; IR: uncompute %18 [sum]
  call void @cqrt_free(i32 %26)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %29, i32 %30, i32 %5)    ; IR: uncompute %18 [product]
  call void @cqrt_free(i32 %29)    ; IR: release the product rail (|0>)
  %31 = add nsw i64 %25, -1
  %32 = icmp sgt i64 %31, 0
  br i1 %32, label %24, label %33

33:
  call void @cqrt_free(i32 %30)    ; IR: release the first s rail (never written, holds the classical %6)
  %34 = call double @cqrt_measure_f64(i32 %23)    ; IR: %12 = cq_measure_f64(%11)
  ret double %34    ; IR: ret double %12
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
