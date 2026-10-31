; HAND-WRITTEN. Rules: 14 (quantum-dependent exit, cutoff K), 9, 6, 7, 5.
; Checked: x + n (measured: x as the copied-out x_K, %26 -> %42; n as the carried rail n_K, %18 -> %43, measured directly
; because rule 6 leaves it the only n rail).
; Clean: every x-chain trip rail except a_K (the products, sums, next-x selects, the tests and the predicates a_1..a_{K-1}),
; popped and uncomputed by the reverse loop; the |1> seed is freed directly; the OLD n of every trip (rule 6, in the body:
; n' = a ? n + 1 : n is a bijection in n for every a and the trip predicate reads x, never n, so the arm's garbage n + 1 is
; uncomputed first and t = a ? n' - 1 : n' is copied onto the old n, uncomputed and both freed; trip 0's old n is the |0>
; incoming %7, and trip 0's predicate is the |1> seed, so there t = n' - 1 = 0).
; Kept: a_K, the predicate computed by the last trip's test (the first rail popped by the reverse loop; rule 14: a_K
; = 1 means a fifth body would have run, which is observable). The user register x (%6) stays allocated: x = x * a + b is
; no bijection in x (a may be even) and the exit test reads x, so rule 6 does not apply and the x chain is pushed and
; reversed (x_K is copied out for the measurement).
; Rotations: (Ry, x, tx, 1).
; A do-while: the body runs before the test, so trip 0's body is unconditional (its predicate is the |1> seed) and the
; test at the END of trip j produces the predicate of trip j+1: a_{j+1} = a_j & (x_{j+1} > k), on the CARRIED value
; (where the loop has already exited the carried x is frozen and a_j = 0 absorbs the test). The loop is re-rolled to K = 4
; bodies and K tests; both carried values advance by a select on a_j (rule 9). Each trip pushes its x-chain rails; x_K is
; copied out (alloc + copy) and a reverse loop pops and uncomputes every trip LIFO, skipping a_K on its first
; iteration. RULE 6 IN A ROLLED LOOP (2026-10-31, as in 05): a carried value whose trip update is a bijection and whose
; trip predicate does not read it (n here) is cleaned in the body of the same trip: the new rail is the only one that
; survives, it is not pushed, the reverse loop never sees it, and no copy-out is needed (the measurement reads n_K). The
; do-while changes nothing: trip 0's clean-up is the same code under the |1> seed. A carried value the exit test reads (x)
; cannot be cleaned: x = k and x = k + 1 both leave `x -= 1 under x > k` at k, so that update is not injective (05, 149,
; 54, 68).
source_filename = "do_while_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @do_while_quantum(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %9  [n before trip 0: trip 0's old n, freed by rule 6 in the body]
  %8 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of trip 0's body (a do-while body runs unconditionally once)
  br label %9

9:
  %10 = phi i32 [ 0, %5 ], [ %23, %9 ]    ; IR: trip index, bounded by K  [K]
  %11 = phi i32 [ %6, %5 ], [ %17, %9 ]    ; IR: %8 = phi i32 [ %6, %5 ], [ %11, %7 ]
  %12 = phi i32 [ %7, %5 ], [ %18, %9 ]    ; IR: %9 = phi i32 [ 0, %5 ], [ %12, %7 ]
  %13 = phi i32 [ %8, %5 ], [ %22, %9 ]    ; IR: predicate of this trip's body
  %14 = call i32 @cq_template_mul_i32_hl(i32 %11, i32 %2)    ; IR: %10 = mul nsw i32 %8, %2
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %3)    ; IR: %11 = add nsw i32 %10, %3
  %16 = call i32 @cq_template_add_i32_hl(i32 %12, i32 1)    ; IR: %12 = add nuw nsw i32 %9, 1
  %17 = call i32 @cq_template_select_i32(i32 %13, i32 %15, i32 %11)    ; IR: next %8 = a ? %11 : %8
  %18 = call i32 @cq_template_select_i32(i32 %13, i32 %16, i32 %12)    ; IR: next %9 = a ? %12 : %9  [n_{j+1}: the only n rail after this trip]
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %12, i32 1)    ; IR: rule 6: the arm's garbage %12 is uncomputed first (its _unc reads the old n)
  call void @cqrt_free(i32 %16)    ; IR: release %12 (|0>)
  %19 = call i32 @cq_template_sub_i32_hl(i32 %18, i32 1)    ; IR: rule 6: n' - 1
  %20 = call i32 @cq_template_select_i32(i32 %13, i32 %19, i32 %18)    ; IR: rule 6: t = a ? n' - 1 : n' recomputes the old n (the composite update n' = n + a is a bijection in n)
  call void @cqrt_copy_i32(i32 %20, i32 %12)    ; IR: rule 6: old n ^= t: |0> (trip 0: the |0> incoming %7, unchanged; its predicate is the |1> seed, so t = n' - 1 = 0)
  call void @cq_template_select_i32_unc(i32 %20, i32 %13, i32 %19, i32 %18)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %20)    ; IR: release t (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %19, i32 %18, i32 1)    ; IR: rule 6: uncompute n' - 1
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %12)    ; IR: rule 6: release the old n rail (|0> after the copy); it is not pushed
  %21 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %17, i32 %4)    ; IR: %13 = icmp sgt i32 %11, %4  (on the carried x)
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next trip's body
  call void @cqrt_and_i1(i32 %13, i32 %21, i32 %22)    ; IR: br i1 %13 taken: a_{j+1} = a_j & cond
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %21)
  %23 = add nuw nsw i32 %10, 1
  %24 = icmp ult i32 %23, 4    ; IR: K-bounded br i1 %13, label %7, label %14  [K]
  br i1 %24, label %9, label %25

25:
  %26 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %15 = cq_measure_si32(%11): the carried x  [copied-out result; n needs none: rule 6 left n_K the only n rail]
  call void @cqrt_copy_i32(i32 %17, i32 %26)    ; IR: %11 of the last trip
  br label %27

27:
  %28 = phi i32 [ 0, %25 ], [ %39, %38 ]    ; IR: reverse trip index
  %29 = phi i32 [ %17, %25 ], [ %35, %38 ]    ; IR: %8 written by this trip
  %30 = phi i32 [ %22, %25 ], [ %34, %38 ]    ; IR: predicate produced by this trip's test
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = icmp eq i32 %28, 0    ; IR: reverse index 0 is trip K-1: the predicate its test produced is a_K, the output rail (rule 14)
  br i1 %36, label %38, label %37

37:
  call void @cqrt_and_i1(i32 %34, i32 %31, i32 %30)    ; IR: uncompute the predicate produced by this trip (trips 0..K-2)
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  br label %38

38:
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %31, i32 %29, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %31)    ; IR: release %13 (|0>)
  call void @cq_template_select_i32_unc(i32 %29, i32 %34, i32 %32, i32 %35)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %29)    ; IR: release next %8 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %32, i32 %33, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %32)    ; IR: release %11 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %33, i32 %35, i32 %2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %33)    ; IR: release %10 (|0>)
  %39 = add nuw nsw i32 %28, 1
  %40 = icmp ult i32 %39, 4    ; IR: K  [K]
  br i1 %40, label %27, label %41

41:
  call void @cqrt_free(i32 %34)    ; IR: release the |1> seed directly (rule 7: known basis state)
  %42 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %15 = cq_measure_si32(%11)
  %43 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %16 = cq_measure_si32(%12)  [n_K, the carried rail: rule 6 left no other n rail, so no copy-out; the |0> incoming %7 was freed as trip 0's old n]
  %44 = add nsw i32 %43, %42    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %44    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
