; HAND-WRITTEN. Rules: 20 (runtime-sized slot array), 7, 2, 1.
; Checked: e = sum of cq_measure(q[i]) over i < n: each measured q[i] (handle loaded from slot i, IR %33 -> %35).
; Clean: nothing to free: no garbage rail is ever minted (slot loads and the i8<->i1 casts emit no gate).
; Kept: the n cells q[0..n-1]: user registers seeded |0>, rotated in place and measured, they stay allocated.
; Rotations: (Ry, q[i], theta[i], 1) for i = 0..n-1 in loop order, each in place on its own rail.
; `bool q[n]` is a runtime-sized register: n i1 rails held in a classical array of SLOTS of runtime length (rule 20: the
; `alloca i8, n` becomes one `alloca i32, n`, one handle per 4-byte cell; -O1's byte GEPs over i8 cells are cell indices).
; The zero-init loop is folded by -O1 into `llvm.memset(q, 0, n)` under `n > 0`: a classical store into every cell, so each
; cell is a seed rail (rule 7) and the memset becomes a classical loop over the n cells minting one |0> rail per cell. A
; classical-index access `q[i]` is a load of the HANDLE from slot i (the i8<->i1 zext/trunc are representation changes,
; no gate); cq_theta rotates that rail in place, the store of its result changes nothing; the measure loop reads the
; slots. The n cells are user registers and stay allocated. This is the register-array shape of VQE/QPE (examples 59,
; 60, 114 build on it); the register size is a function input, never a compile-time constant.
source_filename = "register_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @register_array(ptr nocapture noundef readonly %0, i32 noundef %1) {
  %3 = zext i32 %1 to i64    ; IR: %3  (classical n)
  %4 = alloca i32, i64 %3, align 16    ; IR: %4 = alloca i8, i64 %3  (runtime-sized classical slots: one handle per cell)
  %5 = icmp sgt i32 %1, 0    ; IR: %5  (classical)
  br i1 %5, label %6, label %14    ; IR: br i1 %5

6:
  %7 = zext nneg i32 %1 to i64    ; IR: %7  (classical memset length n)
  br label %8    ; IR: block %6: llvm.memset(%4, 0, %7) becomes a loop over the n cells

8:
  %9 = phi i64 [ 0, %6 ], [ %12, %8 ]    ; IR: memset cell index (classical)
  %10 = getelementptr inbounds i32, ptr %4, i64 %9    ; IR: memset byte %z = cell q[z]  (slot of q[z])
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: llvm.memset(%4, 0, %7): cell q[z] = 0  [register q[z], a |0> seed rail]
  store i32 %11, ptr %10, align 4    ; IR: llvm.memset(%4, 0, %7)  (slot z holds the handle of q[z])
  %12 = add nuw nsw i64 %9, 1    ; IR: memset cell index + 1 (classical)
  %13 = icmp eq i64 %12, %7    ; IR: all n cells written (classical)
  br i1 %13, label %14, label %8    ; IR: br label %8

14:
  %15 = icmp sgt i32 %1, 0    ; IR: %9  (classical)
  br i1 %15, label %16, label %18    ; IR: br i1 %9

16:
  %17 = zext nneg i32 %1 to i64    ; IR: %11  (classical)
  br label %22    ; IR: br label %16

18:
  %19 = icmp sgt i32 %1, 0    ; IR: %13  (classical)
  br i1 %19, label %20, label %30    ; IR: br i1 %13

20:
  %21 = zext nneg i32 %1 to i64    ; IR: %15  (classical)
  br label %32    ; IR: br label %29

22:
  %23 = phi i64 [ 0, %16 ], [ %28, %22 ]    ; IR: %17 = phi i64  (classical trip counter i)
  %24 = getelementptr inbounds i32, ptr %4, i64 %23    ; IR: %18 = getelementptr i8, ptr %4, %17  (slot of q[i])
  %25 = load i32, ptr %24, align 4    ; IR: %19 = load i8, ptr %18; %20 = trunc i8 %19 to i1  (the handle of q[i]; no gate)
  %26 = getelementptr inbounds double, ptr %0, i64 %23    ; IR: %21  (classical)
  %27 = load double, ptr %26, align 8    ; IR: %22 = load double, ptr %21  (classical angle theta[i])
  call void @cqrt_ry_i1(i32 %25, double %27)    ; IR: %23 = cq_theta_i1(%20, %22)  [Ry in place on q[i]]; %24 = zext, store i8 %24, ptr %18: the handle is unchanged, nothing emitted
  %28 = add nuw nsw i64 %23, 1    ; IR: %25  (classical)
  %29 = icmp eq i64 %28, %17    ; IR: %26  (classical)
  br i1 %29, label %18, label %22    ; IR: br i1 %26

30:
  %31 = phi i32 [ 0, %18 ], [ %39, %32 ]    ; IR: %28 = phi i32  (classical sum of outcomes)
  ret i32 %31    ; IR: ret i32 %28

32:
  %33 = phi i64 [ 0, %20 ], [ %40, %32 ]    ; IR: %30  (classical trip counter)
  %34 = phi i32 [ 0, %20 ], [ %39, %32 ]    ; IR: %31  (classical running sum)
  %35 = getelementptr inbounds i32, ptr %4, i64 %33    ; IR: %32 = getelementptr i8, ptr %4, %30  (slot of q[i])
  %36 = load i32, ptr %35, align 4    ; IR: %33 = load i8, ptr %32; %34 = trunc to i1  (the handle of q[i])
  %37 = call i1 @cqrt_measure_i1(i32 %36)    ; IR: %35 = cq_measure_i1(%34)
  %38 = zext i1 %37 to i32    ; IR: %36 = zext i1 %35 to i32  (classical)
  %39 = add nuw nsw i32 %34, %38    ; IR: %37  (classical)
  %40 = add nuw nsw i64 %33, 1    ; IR: %38  (classical)
  %41 = icmp eq i64 %40, %21    ; IR: %39  (classical)
  br i1 %41, label %30, label %32    ; IR: br i1 %39
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare i1 @cqrt_measure_i1(i32)
