; HAND-WRITTEN. Rules: 18, 14, 20, 7, 5.
; Checked: polyval(x, c, n) (the clone's result rail %6, measured as %7).
; Clean: every per-trip rail of the clone (popped and uncomputed by the reverse loop) and the seed rail holding c[0]
; (%5 on the n <= 1 path, %28 on the loop path), all freed.
; Kept: x (%5 of the caller, the rotated register) and the result rail %6 (measured).
; Rotations: (Ry, x, th, 1).
; The coefficient pointer is classical memory read at a classical index: each load stays a load and its value is passed
; as a literal. The clone __cq_q_polyval_100 (mask left to right, §1.4) runs the classical-bound loop with the handle
; stack (as example 25), copies the result into a fresh rail, mirrors the loop and returns the copy; on the n <= 1 path
; the result is the seed rail's value, copied out the same way, and the seed is freed directly (rule 7). No _unc twin:
; the caller measures the result.
source_filename = "callee_with_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_with_loop(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_polyval_100(i32 %5, ptr %2, i32 %3)    ; IR: %6 = call @polyval(%5, %2, %3), quantum clone (arg 0 quantum)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_polyval_100(i32 %0, ptr %1, i32 %2) {
  %4 = load i32, ptr %1, align 4    ; IR: %4 = load i32, ptr %1  (classical)
  %5 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: incoming %4 of phi %12 / %9  [s before trip 1]
  %6 = icmp sgt i32 %2, 1    ; IR: %5 = icmp sgt i32 %2, 1
  br i1 %6, label %9, label %7    ; IR: br i1 %5, label %6, label %8

7:
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9, %9 = %4 from %3  [result rail of the call, rule 18]
  call void @cqrt_copy_i32(i32 %5, i32 %8)    ; IR: copy the (classical-valued) s rail out
  call void @cqrt_free(i32 %5)    ; IR: release the seed directly (rule 7: a known basis state)
  ret i32 %8    ; IR: ret i32 %9

9:
  %10 = zext nneg i32 %2 to i64    ; IR: %7 = zext nneg i32 %2 to i64
  br label %11

11:
  %12 = phi i64 [ 1, %9 ], [ %18, %11 ]    ; IR: %11 = phi i64 [ 1, %6 ], [ %17, %10 ]  (classical)
  %13 = phi i32 [ %5, %9 ], [ %17, %11 ]    ; IR: %12 = phi i32 [ %4, %6 ], [ %16, %10 ]
  %14 = call i32 @cq_template_mul_i32(i32 %13, i32 %0)    ; IR: %13 = mul nsw i32 %12, %0
  %15 = getelementptr inbounds i32, ptr %1, i64 %12    ; IR: %14 = getelementptr inbounds i32, ptr %1, i64 %11
  %16 = load i32, ptr %15, align 4    ; IR: %15 = load i32, ptr %14  (classical)
  %17 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %16)    ; IR: %16 = add nsw i32 %15, %13  (commutative: classical operand moved to the _hl slot)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  %18 = add nuw nsw i64 %12, 1    ; IR: %17 = add nuw nsw i64 %11, 1
  %19 = icmp eq i64 %18, %10    ; IR: %18 = icmp eq i64 %17, %7
  br i1 %19, label %20, label %11    ; IR: br i1 %18, label %8, label %10

20:
  %21 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9, %9 = %16  [result rail of the call]
  call void @cqrt_copy_i32(i32 %17, i32 %21)    ; IR: copy the result out
  br label %22

22:
  %23 = phi i64 [ %12, %20 ], [ %29, %22 ]    ; IR: trip being undone, from the last down to 1
  %24 = phi i32 [ %17, %20 ], [ %28, %22 ]
  %25 = getelementptr inbounds i32, ptr %1, i64 %23
  %26 = load i32, ptr %25, align 4    ; IR: %15 of that trip (classical)
  %27 = call i32 @cqrt_pop()
  %28 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_hl_unc(i32 %24, i32 %27, i32 %26)    ; IR: uncompute %16
  call void @cqrt_free(i32 %24)    ; IR: release the %16 rail (|0>)
  call void @cq_template_mul_i32_unc(i32 %27, i32 %28, i32 %0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %27)    ; IR: release the %13 rail (|0>)
  %29 = add nsw i64 %23, -1
  %30 = icmp sgt i64 %29, 0
  br i1 %30, label %22, label %31

31:
  call void @cqrt_free(i32 %28)    ; IR: release the first s rail (never written, holds the classical %4)
  ret i32 %21    ; IR: ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
