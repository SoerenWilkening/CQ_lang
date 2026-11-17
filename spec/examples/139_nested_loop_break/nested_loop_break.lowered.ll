; HAND-WRITTEN. Rules: 14 (mixed exit inside classical nesting), 8, 7, 9, 4, 5.
; Checked: acc (the copied-out result %33 -> %55, measured; where no trip runs the |0> seed %7 -> %12 is measured).
; Clean: every inner trip's rails (the xor %22, the unguarded sum %23, the break flag %24, the carried select %25, the
; old acc %19 and EVERY predicate a_j, the inner chain's last a_{m-1} included), popped and uncomputed by the nested
; reverse loop; each outer trip's |1> seed (%16) and the |0> seed of acc (%7), never written and freed directly.
; Kept: x (%6, the rotated register) and the measured result rail. No predicate is kept: both bounds are classical, so
; every predicate is a function of the inputs and the mirror uncomputes it (rule 14, classical bound with a quantum exit).
; Rotations: (Ry, x, th, 1).
; 27's nested rolled loops composed with 26's quantum break, the break confined to the INNER loop. -O1 tests the break
; after the body and folds it with the classical exit into `select i1 %22, i1 %24, i1 false`; the classical half keeps
; the inner loop a classical loop over all m trips, the quantum half is the trip predicate: inner trip j of outer trip i
; runs iff a_{j-1} (no break before it in THIS inner loop), u_j = acc_{j-1} + (x ^ (i + j)) is computed unguarded
; (pure), the break flag is e_j = u_j > lim, the carried value is acc_j = a_{j-1} ? u_j : acc_{j-1}, and
; a_j = a_{j-1} AND NOT e_j. Each outer trip starts a fresh predicate chain (a_{-1} = |1>): the break resets with the
; inner loop, the outer loop continues. Every trip's rails are pushed and the nested reverse loop pops them (27). If
; n <= 0 or m <= 0 no inner trip ever runs: one classical edge, acc is the seed rail. Both bounds are classical: no K.
; No output rail (rule 14, classical bound with a quantum exit): each outer trip's inner chain pushes its LAST
; predicate a_{m-1} (%26 of inner trip m-1, pushed by block %29 and popped as %37 = %42 of the first inner reverse trip),
; and the inner reverse loop uncomputes it like every earlier a_j. Each outer trip's |1> seed is freed directly (rule 7).
source_filename = "nested_loop_break.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_loop_break(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %12 / %14  [acc before any trip]
  %8 = icmp sgt i32 %2, 0    ; IR: %7 = icmp sgt i32 %2, 0  (classical)
  %9 = icmp sgt i32 %3, 0    ; IR: %9 = icmp sgt i32 %3, 0  (classical)
  %10 = and i1 %8, %9    ; IR: an inner trip runs at all (otherwise %14 = 0 from %5 or %12 unchanged)
  br i1 %10, label %13, label %11
11:
  %12 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %15 = cq_measure_si32(%14), %14 = 0
  ret i32 %12    ; IR: ret i32 %15
13:
  %14 = phi i32 [ 0, %5 ], [ %30, %29 ]    ; IR: %11 = phi i32 [ 0, %8 ], [ %28, %26 ]  (classical i)
  %15 = phi i32 [ %7, %5 ], [ %25, %29 ]    ; IR: %12 = phi i32 [ 0, %8 ], [ %27, %26 ]  [acc at the start of outer trip i]
  %16 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of running inner trip 0 of this outer trip (always 1)
  br label %17
17:
  %18 = phi i32 [ 0, %13 ], [ %27, %17 ]    ; IR: %17 = phi i32 [ %23, %16 ], [ 0, %10 ]  (classical j)
  %19 = phi i32 [ %15, %13 ], [ %25, %17 ]    ; IR: %18 = phi i32 [ %21, %16 ], [ %12, %10 ]  [acc_{j-1}]
  %20 = phi i32 [ %16, %13 ], [ %26, %17 ]    ; IR: predicate a_{j-1}: this trip's body runs
  %21 = add nuw nsw i32 %18, %14    ; IR: %19 = add nuw nsw i32 %17, %11  (classical)
  %22 = call i32 @cq_template_xor_i32_hl(i32 %6, i32 %21)    ; IR: %20 = xor i32 %19, %6
  %23 = call i32 @cq_template_add_i32(i32 %22, i32 %19)    ; IR: %21 = add nsw i32 %20, %18  (unguarded)
  %24 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %23, i32 %4)    ; IR: NOT %22 = icmp sle i32 %21, %4  [break flag e_j]
  %25 = call i32 @cq_template_select_i32(i32 %20, i32 %23, i32 %19)    ; IR: next %18 / %27 = a_{j-1} ? %21 : %18
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate a_j of the next trip
  call void @cqrt_not_i1(i32 %24)    ; IR: bracket: the loop continues when the break flag is false
  call void @cqrt_and_i1(i32 %20, i32 %24, i32 %26)    ; IR: %25 = select i1 %22, %24, false, quantum half: a_j = a_{j-1} & NOT e_j
  call void @cqrt_not_i1(i32 %24)    ; IR: bracket
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  %27 = add nuw nsw i32 %18, 1    ; IR: %23 = add nuw nsw i32 %17, 1  (classical)
  %28 = icmp slt i32 %27, %3    ; IR: %24 = icmp slt i32 %23, %3  (classical half of %25)
  br i1 %28, label %17, label %29    ; IR: br i1 %25 on its classical half
29:
  call void @cqrt_push(i32 %26)    ; IR: the inner loop's final predicate (which-path rail, uncomputed by the mirror)
  %30 = add nuw nsw i32 %14, 1    ; IR: %28 = add nuw nsw i32 %11, 1  (classical)
  %31 = icmp eq i32 %30, %2    ; IR: %29 = icmp eq i32 %28, %2  (classical)
  br i1 %31, label %32, label %13    ; IR: br i1 %29, label %13, label %10
32:
  %33 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %14 = phi i32 [ %27, %26 ]  [copied-out acc]
  call void @cqrt_copy_i32(i32 %25, i32 %33)    ; IR: %14
  br label %34
34:
  %35 = phi i32 [ %14, %32 ], [ %52, %51 ]    ; IR: outer trip being undone, from the last down to 0
  %36 = phi i32 [ %25, %32 ], [ %47, %51 ]    ; IR: acc at the end of outer trip ri
  %37 = call i32 @cqrt_pop()    ; IR: that trip's final inner predicate
  %38 = add nsw i32 %3, -1
  br label %39
39:
  %40 = phi i32 [ %38, %34 ], [ %49, %39 ]    ; IR: inner trip being undone, from m-1 down to 0
  %41 = phi i32 [ %36, %34 ], [ %47, %39 ]    ; IR: acc_j
  %42 = phi i32 [ %37, %34 ], [ %46, %39 ]    ; IR: a_j
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  %48 = add nsw i32 %40, %35    ; IR: %19 of that trip (classical)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_and_i1(i32 %46, i32 %43, i32 %42)    ; IR: uncompute a_j (every inner trip, a_{m-1} included: rule 14, classical bound)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %41, i32 %46, i32 %44, i32 %47)    ; IR: uncompute acc_j
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %43, i32 %44, i32 %4)    ; IR: uncompute e_j
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %44, i32 %45, i32 %47)    ; IR: uncompute %21
  call void @cqrt_free(i32 %44)    ; IR: release the %21 rail (|0>)
  call void @cq_template_xor_i32_hl_unc(i32 %45, i32 %6, i32 %48)    ; IR: uncompute %20
  call void @cqrt_free(i32 %45)    ; IR: release the %20 rail (|0>)
  %49 = add nsw i32 %40, -1
  %50 = icmp sge i32 %49, 0
  br i1 %50, label %39, label %51
51:
  call void @cqrt_free(i32 %46)    ; IR: release this outer trip's |1> seed directly (rule 7: known basis state)
  %52 = add nsw i32 %35, -1
  %53 = icmp sge i32 %52, 0
  br i1 %53, label %34, label %54
54:
  call void @cqrt_free(i32 %47)    ; IR: release incoming 0 of phi %12 (never written, |0>)
  %55 = call i32 @cqrt_measure_i32(i32 %33)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %55    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
