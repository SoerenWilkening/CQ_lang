; HAND-WRITTEN. Rules: 20, 8, 2, 5.
; Checked: nothing is measured here; the caller's registers q[0..n-1] hold the result.
; Clean: every per-trip Toffoli flag q[j] & q[i].
; Kept: the caller's n i1 registers behind the slot array q (never freed; they belong to the caller).
; Rotations: for i = 0..n-1: Ry(base) on q[i]; then for j = i+1..n-1: P(base / 2^(j-i)) on (q[j] & q[i]).
; Expected: the QFT ladder on n qubits with base as the opening rotation and the controlled phases base/2^(j-i)
; between q[i] and every later q[j], without the final bit-reversal swaps.
; A `bool *` parameter that points at quantum registers arrives as a pointer to i32 HANDLE SLOTS (the caller's register
; array, example 58, rule 20), so `q[i]` is a classical-index load of a handle. The outer loop rotates q[i] in place;
; the inner loop's `if (q[j] && q[i])` is two nested branches on bare rails (-O1 keeps the short-circuit as nested br),
; folded into ONE Toffoli flag (rule 8); the cq_phi with its classically computed angle is an uncontrolled kickback on
; that flag; the flag is un-Toffoli'd and freed every trip. Both loops are classical-bound: no predicate chain, no
; stack. Nothing but the caller's registers survives.
source_filename = "qft.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define void @qft(ptr nocapture noundef %0, i32 noundef %1, double noundef %2) {
  %4 = icmp sgt i32 %1, 0    ; IR: %4  (classical)
  br i1 %4, label %5, label %12    ; IR: br i1 %4

5:; preds = %3
  %6 = zext nneg i32 %1 to i64    ; IR: %6  (classical)
  %7 = zext nneg i32 %1 to i64    ; IR: %7  (classical)
  %8 = zext nneg i32 %1 to i64    ; IR: %8  (classical)
  br label %13

9:; preds = %37, %13
  %10 = add nuw nsw i64 %15, 1    ; IR: %10  (classical)
  %11 = icmp eq i64 %18, %7    ; IR: %11  (classical)
  br i1 %11, label %12, label %13    ; IR: br i1 %11

12:; preds = %9, %3
  ret void    ; IR: ret void

13:; preds = %5, %9
  %14 = phi i64 [ 0, %5 ], [ %18, %9 ]    ; IR: %14  (classical i)
  %15 = phi i64 [ 1, %5 ], [ %10, %9 ]    ; IR: %15  (classical i+1)
  %16 = getelementptr inbounds i32, ptr %0, i64 %14    ; IR: %16 = getelementptr i8, ptr %0, %14  (slot of q[i]; slots are i32 handles)
  %17 = load i32, ptr %16, align 4    ; IR: %17 = load i8, ptr %16; %18 = trunc to i1  (handle of q[i]; no gate)
  call void @cqrt_ry_i1(i32 %17, double %2)    ; IR: %19 = cq_theta_i1(%18, %2)  [Ry in place on q[i]]; %20/store: handle unchanged
  %18 = add nuw nsw i64 %14, 1    ; IR: %21  (classical)
  %19 = icmp ult i64 %18, %6    ; IR: %22  (classical)
  br i1 %19, label %20, label %9    ; IR: br i1 %22

20:; preds = %13, %37
  %21 = phi i64 [ %31, %30 ], [ %15, %13 ]    ; IR: %24  (classical j)
  %22 = getelementptr inbounds i32, ptr %0, i64 %21    ; IR: %25 = getelementptr i8, ptr %0, %24  (slot of q[j])
  %23 = load i32, ptr %22, align 4    ; IR: %26 = load i8, ptr %25; %27 = trunc to i1  (handle of q[j]; no gate)
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %31 = %27 & %30  (%29 = load i8, ptr %16 reloads q[i]: same handle %hi)
  call void @cqrt_and_i1(i32 %23, i32 %17, i32 %24)    ; IR: br i1 %27 -> block %28, br i1 %30 -> block %31: one Toffoli flag
  %25 = sub nuw nsw i64 %21, %14    ; IR: %32  (classical j - i)
  %26 = trunc nsw i64 %25 to i32    ; IR: %33  (classical)
  %27 = shl nuw i32 1, %26    ; IR: %34  (classical 1 << (j - i))
  %28 = sitofp i32 %27 to double    ; IR: %35  (classical)
  %29 = fdiv double %2, %28    ; IR: %36  (classical angle)
  call void @cqrt_rz_i1(i32 %24, double %29)    ; IR: block %31: cq_phi(%36)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %23, i32 %17, i32 %24)    ; IR: uncompute the %31 predicate
  call void @cqrt_free(i32 %24)    ; IR: release the flag (|0>)
  br label %30    ; IR: br label %37

30:; preds = %23
  %31 = add nuw nsw i64 %21, 1    ; IR: %38  (classical)
  %32 = icmp eq i64 %31, %8    ; IR: %39  (classical)
  br i1 %32, label %9, label %20    ; IR: br i1 %39
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
