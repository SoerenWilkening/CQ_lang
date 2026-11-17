; HAND-WRITTEN. Rules: 14 (quantum-dependent exit, cutoff K), 8, 10, 12, 9, 7, 5.
; Checked: r + x (measured).
; Clean: every trip rail and every trip predicate, the K-th included (the phase-arm flags are uncomputed inside their
; trip); the after-trip-K exit test; the |1> seed is freed directly.
; Kept: a_K (%24: the exit test x_K > k evaluated after the K-th body, ANDed with trip K's predicate; rule 14: a_K = 1
; iff the loop would run a (K+1)-th trip; a loop that exits after exactly K trips reads 0). r is a user register: it
; is rotated in place under a_j every trip and FROZEN (rule 10: never reverse-played, never freed), then measured. The
; user register x stays allocated.
; Rotations: (Ry, x, tx, 1); for each trip j = 0..3: (P, h_j, p, a_j && (x_j & 1) != 0), (Ry, r, t, a_j) where a_j =
; AND_{i<=j} (x_i > k) and x_i = x >> i.
; The loop is 05's K-loop (trip j runs under a_j = a_{j-1} & (x_j > k)) with two gates in its body. The phase arm `if (x & 1)
; cq_phi(p)` is a nested quantum branch inside the trip: its path predicate a_j & NOT(x_j & 1 == 0) is one X-bracketed
; Toffoli into a fresh |0> flag h_j (rule 8; -O1 tests the FALSE edge `== 0`), the phase is a kickback on h_j (rule 12),
; and h_j, the compare and the `and` are uncomputed right after the kickback, inside the trip (rule 5: their sources x_j
; and a_j are unchanged, so no push is needed). The in-place cq_theta(&r, t) under the trip is rule 10:
; cqrt_ry_i32_controlled(a_j, r, t) on the one r rail seeded with the classical 0; nothing reads r, so a_j can still be
; uncomputed afterwards (it reads x only). The carried x advances by a select on a_j; after K trips it is copied out and the
; mirror pops and uncomputes LIFO, every trip predicate included. Before the copy the exit test is evaluated once more
; on x_K and a_K = (predicate of trip K) & (x_K > k) is kept (rule 14); the test is uncomputed at once.
source_filename = "phase_in_kloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @phase_in_kloop(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %9 / %20  [register r: the classical 0, rotated in place below, frozen]
  %8 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %5 (always 1)
  br label %9

9:
  %10 = phi i32 [ 0, %5 ], [ %20, %9 ]    ; IR: trip index, bounded by K  [K]
  %11 = phi i32 [ %6, %5 ], [ %19, %9 ]    ; IR: %10 = phi i32 [ %16, %14 ], [ %6, %5 ]
  %12 = phi i32 [ %8, %5 ], [ %14, %9 ]    ; IR: predicate of reaching this trip's test
  %13 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %11, i32 %2)    ; IR: %7 = icmp ugt i32 %6, %2 (trip 0) / %17 = icmp ugt i32 %16, %2
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip (block %8)
  call void @cqrt_and_i1(i32 %12, i32 %13, i32 %14)    ; IR: br i1 %7 / %17 taken: a_j = a_{j-1} & cond_j
  %15 = call i32 @cq_template_and_i32_hl(i32 %11, i32 1)    ; IR: %11 = and i32 %10, 1
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)    ; IR: %12 = icmp eq i32 %11, 0  (block %13 is its FALSE edge)
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %13 = a_j & NOT %12  [fresh |0> flag]
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket: block %13 runs under NOT %12
  call void @cqrt_and_i1(i32 %14, i32 %16, i32 %17)    ; IR: br i1 %12 inside the trip, false edge
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket
  call void @cqrt_rz_i1(i32 %17, double %3)    ; IR: block %13: cq_phi(%3)  [kickback on the path predicate]
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket
  call void @cqrt_and_i1(i32 %14, i32 %16, i32 %17)    ; IR: uncompute the %13 predicate (a_j, %12 unchanged)
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket
  call void @cqrt_free(i32 %17)    ; IR: release the %13 predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)    ; IR: uncompute %12
  call void @cqrt_free(i32 %16)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %11, i32 1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cqrt_ry_i32_controlled(i32 %14, i32 %7, double %4)    ; IR: block %14: %15 = cq_theta_si32(%9, %4)  [Ry in place on r under a_j; r frozen]
  %18 = call i32 @cq_template_lshr_i32_hl(i32 %11, i32 1)    ; IR: %16 = lshr i32 %10, 1
  %19 = call i32 @cq_template_select_i32(i32 %14, i32 %18, i32 %11)    ; IR: next %10 = a ? %16 : %10
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %18)
  %20 = add nuw nsw i32 %10, 1
  %21 = icmp ult i32 %20, 4    ; IR: K-bounded br i1 %17, label %8, label %18  [K]
  br i1 %21, label %9, label %22

22:
  %23 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %19, i32 %2)    ; IR: %17 = icmp ugt i32 %16, %2 after trip K: the exit test that would admit a (K+1)-th trip
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %14, i32 %23, i32 %24)    ; IR: br i1 %17 taken once more (rule 14)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %23, i32 %19, i32 %2)    ; IR: uncompute that test
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  %25 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %19 = phi i32 [ %6, %5 ], [ %16, %14 ]  [copied-out result: the carried x]
  call void @cqrt_copy_i32(i32 %19, i32 %25)    ; IR: %19
  br label %26

26:
  %27 = phi i32 [ 0, %22 ], [ %34, %26 ]    ; IR: reverse trip index
  %28 = phi i32 [ %19, %22 ], [ %33, %26 ]    ; IR: %10 written by this trip
  %29 = phi i32 [ %14, %22 ], [ %32, %26 ]    ; IR: predicate of this trip
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %28, i32 %29, i32 %30, i32 %33)    ; IR: uncompute next %10
  call void @cqrt_free(i32 %28)    ; IR: release next %10 (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %30, i32 %33, i32 1)    ; IR: uncompute %16  (the controlled Ry on r is frozen: not reverse-played)
  call void @cqrt_free(i32 %30)    ; IR: release %16 (|0>)
  call void @cqrt_and_i1(i32 %32, i32 %31, i32 %29)    ; IR: uncompute the predicate of this trip (every trip 1..K; it reads x only, never r)
  call void @cqrt_free(i32 %29)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %31, i32 %33, i32 %2)    ; IR: uncompute %7 / %17
  call void @cqrt_free(i32 %31)    ; IR: release %7 / %17 (|0>)
  %34 = add nuw nsw i32 %27, 1
  %35 = icmp ult i32 %34, 4    ; IR: K  [K]
  br i1 %35, label %26, label %36

36:
  call void @cqrt_free(i32 %32)    ; IR: release the |1> seed directly (rule 7: known basis state)
  %37 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %21 = cq_measure_si32(%20): the r rail itself
  %38 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %22 = cq_measure_ui32(%19)
  %39 = add i32 %38, %37    ; IR: %23 = add i32 %22, %21  (classical)
  ret i32 %39    ; IR: ret i32 %23
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
