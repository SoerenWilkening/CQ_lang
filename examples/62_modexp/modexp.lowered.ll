; HAND-WRITTEN. Rules: 14, 9, 8, 4, 5, 7, 2.
; Checked: r = a^e mod N over the nbits low bits of e, then e (measured, summed classically).
; Clean: every trip's and, eq flag, product, remainder and merge rails (popped and uncomputed by the mirror) and the
; seed rail holding the classical 1 (never written, freed directly, rule 7).
; Kept: the user register e; the copied-out result rail (measured).
; Rotations: Ry(th) on e.
; Shor's controlled modular multiply: the exponent bit `(e >> i) & 1` is the condition of a value arm inside a
; classical-bound loop (rule 14); -O1 rewrites it to `(1 << i) & e`, so the and is a commutative Q+C op whose classical
; operand moves to the _hl slot (rule 4). The loop is classical (no predicate chain): each trip computes the and, the
; eq flag, the modular product into fresh rails and merges by one select (eq ? r : product, rule 9); r is loop-carried
; and seeded CLASSICAL (a rail holding 1 before trip 0). The classical recurrence `base = base*base % N` runs beside
; it. The reverse loop needs each trip's classical `base` and `1 << i`: the shift is recomputed from the trip index,
; the base is pushed on the classical handle stack beside the handles (the stack is classical; a classical word on it
; is ordinary, §1.3 push/pop). After the result is copied out and the loop mirrored, r is measured, then the user
; register e. nbits <= 0 takes the classical edge and measures the seed rail itself.
source_filename = "modexp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @modexp(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register e]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: incoming 1 of phi %16 / %9  [r before trip 0: a rail holding the classical 1]
  %8 = icmp sgt i32 %4, 0    ; IR: %7 = icmp sgt i32 %4, 0  (classical)
  br i1 %8, label %13, label %9    ; IR: br i1 %7, label %13, label %8

9:
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %10 = cq_measure_ui32(%9), %9 = 1 from %5
  %11 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_ui32(%6)
  %12 = add i32 %11, %10    ; IR: %12 = add i32 %11, %10  (classical)
  ret i32 %12    ; IR: ret i32 %12

13:
  %14 = phi i32 [ %24, %13 ], [ %2, %5 ]    ; IR: %14 = phi i32 [ %26, %24 ], [ %2, %5 ]  (classical base)
  %15 = phi i32 [ %25, %13 ], [ 0, %5 ]    ; IR: %15 = phi i32 [ %27, %24 ], [ 0, %5 ]  (classical i)
  %16 = phi i32 [ %7, %5 ], [ %23, %13 ]    ; IR: %16 = phi i32 [ %25, %24 ], [ 1, %5 ]
  %17 = urem i32 %14, %3    ; IR: %17 = urem i32 %14, %3  (classical base % N)
  %18 = shl nuw i32 1, %15    ; IR: %18 = shl nuw i32 1, %15  (classical 1 << i)
  %19 = call i32 @cq_template_and_i32_hl(i32 %6, i32 %18)    ; IR: %19 = and i32 %18, %6  (commutative: classical operand moved to the _hl slot)
  %20 = call i32 @cq_template_icmp_eq_i32_hl(i32 %19, i32 0)    ; IR: %20 = icmp eq i32 %19, 0  [predicate of SKIPPING block %21]
  %21 = call i32 @cq_template_mul_i32_hl(i32 %16, i32 %17)    ; IR: %22 = mul i32 %17, %16  (block %21, hoisted: pure; commutative, classical operand to _hl)
  %22 = call i32 @cq_template_urem_i32_hl(i32 %21, i32 %3)    ; IR: %23 = urem i32 %22, %3  (block %21, hoisted)
  %23 = call i32 @cq_template_select_i32(i32 %20, i32 %16, i32 %22)    ; IR: %25 = phi i32 [ %23, %21 ], [ %16, %13 ] = %20 ? %16 : %23
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)    ; IR: classical %17 of this trip, needed by the reverse loop
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  %24 = mul i32 %17, %17    ; IR: %26 = mul i32 %17, %17  (classical)
  %25 = add nuw nsw i32 %15, 1    ; IR: %27 = add nuw nsw i32 %15, 1  (classical)
  %26 = icmp eq i32 %25, %4    ; IR: %28 = icmp eq i32 %27, %4  (classical)
  br i1 %26, label %27, label %13    ; IR: br i1 %28, label %8, label %13

27:
  %28 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = phi i32 [ %25, %24 ]  [copied-out result r]
  call void @cqrt_copy_i32(i32 %23, i32 %28)    ; IR: %9
  br label %29

29:
  %30 = phi i32 [ 0, %27 ], [ %41, %29 ]    ; IR: reverse trip index (undoes trip n-1-j)
  %31 = phi i32 [ %23, %27 ], [ %37, %29 ]    ; IR: %25 of the trip being undone
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()    ; IR: classical %17 of that trip
  %37 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %31, i32 %34, i32 %37, i32 %32)    ; IR: uncompute %25
  call void @cqrt_free(i32 %31)    ; IR: release the %25 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %32, i32 %33, i32 %3)    ; IR: uncompute %23
  call void @cqrt_free(i32 %32)    ; IR: release the %23 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %33, i32 %37, i32 %36)    ; IR: uncompute %22
  call void @cqrt_free(i32 %33)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %34, i32 %35, i32 0)    ; IR: uncompute %20
  call void @cqrt_free(i32 %34)    ; IR: release the %20 rail (|0>)
  %38 = sub i32 %4, %30    ; IR: i + 1 of the trip being undone  (classical)
  %39 = add i32 %38, -1    ; IR: i of the trip being undone  (classical)
  %40 = shl nuw i32 1, %39    ; IR: %18 of that trip, recomputed  (classical)
  call void @cq_template_and_i32_hl_unc(i32 %35, i32 %6, i32 %40)    ; IR: uncompute %19
  call void @cqrt_free(i32 %35)    ; IR: release the %19 rail (|0>)
  %41 = add nuw nsw i32 %30, 1
  %42 = icmp eq i32 %41, %4
  br i1 %42, label %43, label %29

43:
  call void @cqrt_free(i32 %37)    ; IR: release incoming 1 of phi %16 (never written, holds the classical 1)
  %44 = call i32 @cqrt_measure_i32(i32 %28)    ; IR: %10 = cq_measure_ui32(%9)
  %45 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_ui32(%6)
  %46 = add i32 %45, %44    ; IR: %12 = add i32 %11, %10  (classical)
  ret i32 %46    ; IR: ret i32 %12
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
