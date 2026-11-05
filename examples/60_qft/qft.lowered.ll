; HAND-WRITTEN. Rules: 2, 5, 8, 20, 21; §1.3 (the bus, __cq_mem, qram_swap).
; Checked: nothing is measured here; the result is the n byte cells q + 0 .. q + n-1 of the bus (one _Bool each, the
;          state in its low bit).
; Clean: per outer trip, the swap rail of the in-place form on q[i] (|0> after its swap-in). Per inner trip, the Toffoli
;        flag q[j] & q[i] and the two load copies it reads: q[j] (un-copied) and q[i] (loaded under q[j], un-copied
;        under the same q[j]).
; Kept: nothing: no tape slot (the only cell update is an in-place form), no load copy (each is un-copied before the
;       next memory version change, the next trip's in-place form).
; Rotations: for i = 0..n-1: (Ry at width i1, the cell q + i, base, 1); then for j = i+1..n-1: (P, the flag
;            q[j] & q[i], base / 2^(j-i), 1).
; Expected: the QFT ladder on n qubits with base as the opening rotation and the controlled phases base/2^(j-i)
; between q[i] and every later q[j], without the final bit-reversal swaps.
; MEMORY (rule 20). `q` is an ordinary pointer: its cells are bytes on the one bus M, at the run-time address q + i
; (rule 21: a classical i64, the ptrtoint of the getelementptr); nothing is asked about what they hold. The caller
; passes a _Bool array; the cells start HOST (the caller's bytes) and become QUANTUM at their first in-place form.
; The outer loop's `cq_theta(&q[i], base)` is `load i8 %16; trunc nuw to i1; cq_theta_i1; zext; store i8 %16` on the
; same SSA pointer with nothing between: rule 5's in-place form through the Width-casts clause, at width i1 (rule 2):
; qram_swap_i1_hl, ry_i1, qram_swap_i1_hl, free. The rotated value has no other reader (-O1 reloads q[i] in the inner
; loop), so no plain load follows the swap-in.
; The inner loop's `if (q[j] && q[i])` is two nested branches (-O1 keeps the short-circuit): the first conjunct's load
; of q[j] is a plain bus load (no quantum predicate in scope), the second conjunct's reload of q[i] sits in the arm of
; the q[j] flag and is the _controlled load under it (rule 5: every bus access under a quantum predicate). The two are
; folded into ONE Toffoli flag (rule 8); the cq_phi with its classically computed angle is a kickback on that flag; the
; flag is un-Toffoli'd and freed, then the q[i] copy is un-copied under q[j] and the q[j] copy un-copied (rule 5
; sentence 1: the inner loop makes no memory version change). Both loops are classical-bound: no predicate chain, no
; stack.
; SPEC GAP 1: each read of a _Bool cell is the program's own `load i8; trunc nuw i8 to i1`, no in-place form's Readers
; clause. Chosen as 117 and 205 (SPEC GAP 5): the load at the width i1 the value is used at (qram_load_i1_hl, §1.3: the
; low bit of the cell), not a qram_load_i8 and a trunc template (BACKEND_ABI lists no trunc i8 -> i1).
source_filename = "qft.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define void @qft(ptr nocapture noundef %0, i32 noundef %1, double noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = icmp sgt i32 %1, 0    ; IR: %4  (classical)
  br i1 %5, label %6, label %13    ; IR: br i1 %4

6:; preds = %3
  %7 = zext nneg i32 %1 to i64    ; IR: %6  (classical)
  %8 = zext nneg i32 %1 to i64    ; IR: %7  (classical)
  %9 = zext nneg i32 %1 to i64    ; IR: %8  (classical)
  br label %14

10:; preds = %34, %14
  %11 = add nuw nsw i64 %16, 1    ; IR: %10  (classical)
  %12 = icmp eq i64 %20, %8    ; IR: %11  (classical)
  br i1 %12, label %13, label %14    ; IR: br i1 %11

13:; preds = %10, %3
  ret void    ; IR: ret void

14:; preds = %6, %10
  %15 = phi i64 [ 0, %6 ], [ %20, %10 ]    ; IR: %14  (classical i)
  %16 = phi i64 [ 1, %6 ], [ %11, %10 ]    ; IR: %15  (classical i+1)
  %17 = getelementptr inbounds i8, ptr %0, i64 %15    ; IR: %16  (&q[i], classical)
  %18 = ptrtoint ptr %17 to i64    ; IR: %16 as its run-time address (rule 20)
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %17 = load i8, ptr %16; %18 = trunc nuw to i1: in-place form at width i1 (Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %18, i32 %19)    ; IR: %17 = load i8, ptr %16; %18 = trunc: swap-out of the low bit: the rail holds q[i], the cell's bit |0>
  call void @cqrt_ry_i1(i32 %19, double %2)    ; IR: %19 = cq_theta_i1(%18, %2)  [Ry in place on q[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %18, i32 %19)    ; IR: %20 = zext i1 %19 to i8; store i8 %20, ptr %16: swap-in: the cell holds the rotated bit
  call void @cqrt_free(i32 %19)    ; IR: release the swap rail (|0>)
  %20 = add nuw nsw i64 %15, 1    ; IR: %21  (classical)
  %21 = icmp ult i64 %20, %7    ; IR: %22  (classical)
  br i1 %21, label %22, label %10    ; IR: br i1 %22

22:; preds = %14, %34
  %23 = phi i64 [ %35, %34 ], [ %16, %14 ]    ; IR: %24  (classical j)
  %24 = getelementptr inbounds i8, ptr %0, i64 %23    ; IR: %25  (&q[j], classical)
  %25 = ptrtoint ptr %24 to i64    ; IR: %25 as its run-time address (rule 20)
  %26 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %25)    ; IR: %26 = load i8, ptr %25; %27 = trunc nuw to i1  (a plain bus load of q[j] at width i1, SPEC GAP 1; the flag of br i1 %27)
  %27 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %26, i32 %4, i64 %18)    ; IR: block %28: %29 = load i8, ptr %16; %30 = trunc nuw to i1  (in the arm of %27: the _controlled load, rule 5; SPEC GAP 1)
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %31 = %27 & %30
  call void @cqrt_and_i1(i32 %26, i32 %27, i32 %28)    ; IR: br i1 %27 -> block %28, br i1 %30 -> block %31: one Toffoli flag (rule 8)
  %29 = sub nuw nsw i64 %23, %15    ; IR: %32  (classical j - i)
  %30 = trunc nsw i64 %29 to i32    ; IR: %33  (classical)
  %31 = shl nuw i32 1, %30    ; IR: %34  (classical 1 << (j - i))
  %32 = sitofp i32 %31 to double    ; IR: %35  (classical)
  %33 = fdiv double %2, %32    ; IR: %36  (classical angle)
  call void @cqrt_rz_i1(i32 %28, double %33)    ; IR: block %31: cq_phi(%36)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %26, i32 %27, i32 %28)    ; IR: uncompute the %31 predicate
  call void @cqrt_free(i32 %28)    ; IR: release the flag (|0>)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %27, i32 %26, i32 %4, i64 %18)    ; IR: un-copy %29 under the same %27 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %27)    ; IR: release the %29 rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %26, i32 %4, i64 %25)    ; IR: un-copy %26
  call void @cqrt_free(i32 %26)    ; IR: release the %26 rail (|0>)
  br label %34    ; IR: br label %37

34:; preds = %22
  %35 = add nuw nsw i64 %23, 1    ; IR: %38  (classical)
  %36 = icmp eq i64 %35, %9    ; IR: %39  (classical)
  br i1 %36, label %10, label %22    ; IR: br i1 %39
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare i32 @cqrt_qram_load_i1_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i1_hl_controlled_unc(i32, i32, i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
