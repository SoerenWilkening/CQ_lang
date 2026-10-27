; HAND-WRITTEN. Rules: 10, 8, 20, 7, 2, 5.
; Checked: controlled_ry_chain: q[0] + q[n-1]; controlled_ry_two: q0 + q1 + q2 (measured).
; Clean: controlled_ry_two's conjunction flag q0 & q1.
; Kept: the i1 registers (q[0..n-1] behind the runtime-sized slot array; q0, q1, q2), rotated in place and measured.
; Rotations: controlled_ry_chain: Ry(theta[i]) on q[i] for i = 0..n-1; then Ry(c) on q[i+1] under q[i] for
; i = 0..n-2 (classical n). controlled_ry_two: Ry(t0) on q0; Ry(t1) on q1; Ry(c) on q2 under q0 & q1.
; `bool q[n]` is a runtime-sized register (rule 20): one `alloca i32, n` of handle cells, as in example 58; -O1 folds the
; zero-init loop into `llvm.memset(q, 0, n)` under `n > 0`, which becomes a classical loop minting one |0> seed rail per
; cell (rule 7). -O1's byte GEPs over i8 cells are cell indices; q[n-1] is `q + sext(n) - 1`, re-emitted over i32 cells.
; A bare _Bool rail read from a register-array slot is a condition by itself (no compare, rule 8):
; `if (q[i]) cq_theta(&q[i+1], c)` is one `cqrt_ry_i1_controlled(q[i], q[i+1], c)` with the control rail as the flag
; (rule 10), inside the classical loop (no predicate chain, no stack: nothing is computed into fresh rails). Two
; controls (`q0 && q1`, which -O1 spells `select i1 %4, i1 %5, i1 false`) become a Toffoli into a fresh |0> flag, the
; controlled Ry on that flag, the Toffoli again to return the flag to |0>, and one free.
source_filename = "controlled_ry_bits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @controlled_ry_chain(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = zext i32 %1 to i64    ; IR: %4  (classical n)
  %5 = alloca i32, i64 %4, align 16    ; IR: %5 = alloca i8, i64 %4  (runtime-sized classical slots: one handle per cell)
  %6 = icmp sgt i32 %1, 0    ; IR: %6  (classical)
  br i1 %6, label %7, label %15    ; IR: br i1 %6

7:
  %8 = zext nneg i32 %1 to i64    ; IR: %8  (classical memset length n)
  br label %9    ; IR: block %7: llvm.memset(%5, 0, %8) becomes a loop over the n cells

9:
  %10 = phi i64 [ 0, %7 ], [ %13, %9 ]    ; IR: memset cell index (classical)
  %11 = getelementptr inbounds i32, ptr %5, i64 %10    ; IR: memset byte %z = cell q[z]  (slot of q[z])
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: llvm.memset(%5, 0, %8): cell q[z] = 0  [register q[z], a |0> seed rail]
  store i32 %12, ptr %11, align 4    ; IR: llvm.memset(%5, 0, %8)  (slot z holds the handle of q[z])
  %13 = add nuw nsw i64 %10, 1    ; IR: memset cell index + 1 (classical)
  %14 = icmp eq i64 %13, %8    ; IR: all n cells written (classical)
  br i1 %14, label %15, label %9    ; IR: br label %9

15:
  %16 = icmp sgt i32 %1, 0    ; IR: %10  (classical)
  br i1 %16, label %17, label %19    ; IR: br i1 %10

17:
  %18 = zext nneg i32 %1 to i64    ; IR: %12  (classical)
  br label %24    ; IR: br label %18

19:
  %20 = icmp sgt i32 %1, 1    ; IR: %14  (classical)
  br i1 %20, label %21, label %32    ; IR: br i1 %14

21:
  %22 = add nsw i32 %1, -1    ; IR: %16  (classical)
  %23 = zext i32 %22 to i64    ; IR: %17  (classical)
  br label %43    ; IR: br label %42

24:
  %25 = phi i64 [ 0, %17 ], [ %30, %24 ]    ; IR: %19  (classical trip counter i)
  %26 = getelementptr inbounds i32, ptr %5, i64 %25    ; IR: %20 = getelementptr i8, ptr %5, %19  (slot of q[i])
  %27 = load i32, ptr %26, align 4    ; IR: %21 = load i8; %22 = trunc to i1  (handle of q[i]; no gate)
  %28 = getelementptr inbounds double, ptr %0, i64 %25    ; IR: %23  (classical)
  %29 = load double, ptr %28, align 8    ; IR: %24 = load double  (classical angle theta[i])
  call void @cqrt_ry_i1(i32 %27, double %29)    ; IR: %25 = cq_theta_i1(%22, %24)  [Ry in place on q[i]]; %26/store: handle unchanged
  %30 = add nuw nsw i64 %25, 1    ; IR: %27  (classical)
  %31 = icmp eq i64 %30, %18    ; IR: %28  (classical)
  br i1 %31, label %19, label %24    ; IR: br i1 %28

32:
  %33 = load i32, ptr %5, align 4    ; IR: %30 = load i8, ptr %5; %31 = trunc to i1  (handle of q[0])
  %34 = call i1 @cqrt_measure_i1(i32 %33)    ; IR: %32 = cq_measure_i1(%31)
  %35 = zext i1 %34 to i32    ; IR: %33  (classical)
  %36 = sext i32 %1 to i64    ; IR: %34  (classical)
  %37 = getelementptr i32, ptr %5, i64 %36    ; IR: %35 = getelementptr i8, ptr %5, i64 %34  (cell index n)
  %38 = getelementptr i32, ptr %37, i64 -1    ; IR: %36 = getelementptr i8, ptr %35, i64 -1  (slot of q[n-1])
  %39 = load i32, ptr %38, align 4    ; IR: %37 = load i8; %38 = trunc to i1  (handle of q[n-1])
  %40 = call i1 @cqrt_measure_i1(i32 %39)    ; IR: %39 = cq_measure_i1(%38)
  %41 = zext i1 %40 to i32    ; IR: %40  (classical)
  %42 = add nuw nsw i32 %41, %35    ; IR: %41  (classical)
  ret i32 %42    ; IR: ret i32 %41

43:
  %44 = phi i64 [ 0, %21 ], [ %52, %50 ]    ; IR: %43  (classical i)
  %45 = phi i64 [ 1, %21 ], [ %51, %50 ]    ; IR: %44  (classical i+1)
  %46 = getelementptr inbounds i32, ptr %5, i64 %44    ; IR: %45  (slot of q[i])
  %47 = load i32, ptr %46, align 4    ; IR: %46 = load i8; %47 = trunc to i1  (handle of q[i]: the control rail)
  %48 = getelementptr inbounds i32, ptr %5, i64 %45    ; IR: %49  (slot of q[i+1], hoisted from block %48: pure)
  %49 = load i32, ptr %48, align 4    ; IR: %50 = load i8; %51 = trunc to i1  (handle of q[i+1]: the target)
  call void @cqrt_ry_i1_controlled(i32 %47, i32 %49, double %2)    ; IR: br i1 %47 -> block %48: %52 = cq_theta_i1(%51, %2)  [Ry on q[i+1] controlled by the bare rail q[i]]; %53/store: handle unchanged
  br label %50    ; IR: br label %54

50:
  %51 = add nuw nsw i64 %45, 1    ; IR: %55  (classical)
  %52 = add nuw nsw i64 %44, 1    ; IR: %56  (classical)
  %53 = icmp eq i64 %52, %23    ; IR: %57  (classical)
  br i1 %53, label %32, label %43    ; IR: br i1 %57
}

define i32 @controlled_ry_two(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %4 = cq_theta_i1(false, %0)  [register q0]
  call void @cqrt_ry_i1(i32 %4, double %0)    ; IR: %4 = cq_theta_i1(false, %0)  [Ry]
  %5 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %5 = cq_theta_i1(false, %1)  [register q1]
  call void @cqrt_ry_i1(i32 %5, double %1)    ; IR: %5 = cq_theta_i1(false, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %6 = select i1 %4, i1 %5, i1 false  [flag rail for q0 && q1]
  call void @cqrt_and_i1(i32 %4, i32 %5, i32 %6)    ; IR: %6 = q0 & q1  (Toffoli into the |0> flag)
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %10 = phi i1 [ %8, %7 ], [ false, %3 ]  [register q2, starts as false]
  call void @cqrt_ry_i1_controlled(i32 %6, i32 %7, double %2)    ; IR: br i1 %6 -> block %7: %8 = cq_theta_i1(false, %2)  [Ry on q2 under the flag]
  call void @cqrt_and_i1(i32 %4, i32 %5, i32 %6)    ; IR: uncompute %6 (q0, q1 unchanged)
  call void @cqrt_free(i32 %6)    ; IR: release the flag (|0>)
  %8 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %11 = cq_measure_i1(%4)
  %9 = zext i1 %8 to i32    ; IR: %12  (classical)
  %10 = call i1 @cqrt_measure_i1(i32 %5)    ; IR: %13 = cq_measure_i1(%5)
  %11 = zext i1 %10 to i32    ; IR: %14  (classical)
  %12 = add nuw nsw i32 %11, %9    ; IR: %15  (classical)
  %13 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %16 = cq_measure_i1(%10)
  %14 = zext i1 %13 to i32    ; IR: %17  (classical)
  %15 = add nuw nsw i32 %12, %14    ; IR: %18  (classical)
  ret i32 %15    ; IR: ret i32 %18
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
