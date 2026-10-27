; HAND-WRITTEN. Rules: 21, 20, 14 (re-rolled; a_K kept), 8, 9, 4, 5, 7, 2.
; Checked: n = the number of leading nonzero bytes of s = {c, c + 1, c ^ 3, 0}, over at most K = 4 trips (measured).
; Clean: the initializer rails c + 1 and c ^ 3, every trip's load *p, its flag, n + 1, idx + 1, both select merges and
; its predicate a_0..a_{K-1} (popped and uncomputed by the mirror, the K-th included), the after-trip-K exit test (its
; load and flag, uncomputed at once), the |1> seed and the |0> seeds of p.idx and n (rule 7), and the QRAM s (every
; store popped, then cqrt_qram_free).
; Kept: the user register c (also cell 0's value); the copied-out result rail (measured); a_K (%27: the exit test
; *p != 0 evaluated after the K-th body, ANDed with trip K's predicate; rule 14: a_K = 1 iff the loop would run a
; (K+1)-th trip, which is observable; a loop that exits after exactly K trips reads 0). No range fact bounds the trip
; count (it depends on memory contents), so the cutoff is K and a_K is kept.
; Rotations: Ry(th) on c.
; A POINTER AS THE LOOP-CARRIED VARIABLE of a rolled loop whose exit depends on quantum data (rules 21, 14). The
; buffer s is object 1; its cells hold QUANTUM values from the start (s[0] is the register c, s[1], s[2] fresh rails,
; s[3] the classical 0), and the loop reads it through p at a QUANTUM offset (p's idx is a loop-carried rail), so by
; rule 20 (a quantum-offset load of an object that may hold a handle) the whole array is a QRAM for its lifetime (the
; address decoding is the backend's circuit; ABI = the QRAM contract of §1.3, reference conversions 30 and 84):
; cqrt_qram_alloc_i8(4) at the alloca (cells |0>), each initializer cell one cqrt_qram_store_i8_hl(s, j, rail) with
; the classical index and the value always a handle (the rail stays live and is uncomputed by its own producer; c is the
; user register and is never freed); s[3] = 0 writes the all-|0> cell's own value and needs nothing (30's memset-0
; rule). p is a fat pointer (84) with the classical tag 1 and a loop-carried idx rail seeded |0>, like n; idx is the
; logical-i32 CELL index (p++ is idx + 1; -O1's i64 byte offset is not emitted, the cells are bytes).
; Re-rolled (rule 14): -O1's pre-header test *s != 0 is the latch test *(p + 1) != 0 one trip earlier (SCEV: p starts
; at s), so it is trip 0 of the loop: trip j loads *p at the carried idx (ONE cqrt_qram_load_i8 per trip, copy-out,
; cells preserved), tests it and forms a_j = a_{j-1} & NOT(*p == 0) from the |1> seed; n++ and p++ are select-merged
; on a_j (rule 9; the arm's pure ops run unguarded as in 84). The literal 4 is K [K]. After trip K the exit test is
; evaluated once more on the carried idx and a_K = a_{K-1} & NOT(*p == 0) is kept; that load and flag are uncomputed at
; once. idx only grows under a_j, so it never passes 3 (s[3] = 0 stops the chain); a read at 4 would be the program's
; own read of s[4] and reads 0 by §2. After n is copied out the reverse loop pops each trip and uncomputes it (the
; load's _unc un-copies against the preserved cell), every trip predicate included. Then the initializer stores are
; popped (cells 2, 1, 0), each rail by its producer, and cqrt_qram_free.
source_filename = "pointer_induction.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @count_nonzero(i8 noundef zeroext %0, double noundef %1) {
  %3 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %3 = alloca [4 x i8]: object 1, a 4-cell QRAM of bytes, cells |0> (read at a quantum offset while it holds handles)
  %4 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %4 = cq_theta_ui8(%0, %1)  [register c]
  call void @cqrt_ry_i8(i32 %4, double %1)    ; IR: %4 = cq_theta_ui8(%0, %1)  [Ry]
  call void @cqrt_qram_store_i8_hl(i32 %3, i32 0, i32 %4)    ; IR: store i8 %4, ptr %3: s[0] = c  (fixed index, the value a handle: the register c itself)
  %5 = call i32 @cq_template_add_i8_hl(i32 %4, i8 1)    ; IR: %5 = add i8 %4, 1
  call void @cqrt_qram_store_i8_hl(i32 %3, i32 1, i32 %5)    ; IR: store i8 %5, ptr %6: s[1] = c + 1  (%6 = gep 1 is cell 1)
  %6 = call i32 @cq_template_xor_i8_hl(i32 %4, i8 3)    ; IR: %7 = xor i8 %4, 3
  call void @cqrt_qram_store_i8_hl(i32 %3, i32 2, i32 %6)    ; IR: store i8 %7, ptr %8: s[2] = c ^ 3  (%8 = gep 2 is cell 2); store i8 0, ptr %9: s[3] = 0 writes the |0> cell's own value, nothing emitted
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming %3 of phi %16: p = s, p.idx = cell 0 (p.tag is the classical 1)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %17 / %13
  %9 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %2 (always 1)
  br label %10

10:
  %11 = phi i32 [ 0, %2 ], [ %22, %10 ]    ; IR: trip index, bounded by K  [K]
  %12 = phi i32 [ %7, %2 ], [ %21, %10 ]    ; IR: %16 = phi ptr [ %19, %15 ], [ %3, %2 ]: p.idx
  %13 = phi i32 [ %8, %2 ], [ %19, %10 ]    ; IR: %17 = phi i32 [ %18, %15 ], [ 0, %2 ]
  %14 = phi i32 [ %9, %2 ], [ %17, %10 ]    ; IR: predicate of reaching this trip's test
  %15 = call i32 @cqrt_qram_load_i8(i32 %3, i32 %12)    ; IR: %10 = load i8, ptr %3 (trip 0) / %20 = load i8, ptr %19: *p, ONE access at the index rail (copy-out, cells preserved)
  %16 = call i32 @cq_template_icmp_eq_i8_hl(i32 %15, i8 0)    ; IR: %11 = icmp eq i8 %10, 0 (trip 0) / %21 = icmp eq i8 %20, 0
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket: the loop body runs when the test is false
  call void @cqrt_and_i1(i32 %14, i32 %16, i32 %17)    ; IR: br i1 %11 (trip 0) / br i1 %21 not taken: a_j = a_{j-1} & NOT test
  call void @cqrt_not_i1(i32 %16)    ; IR: bracket
  %18 = call i32 @cq_template_add_i32_hl(i32 %13, i32 1)    ; IR: %18 = add nuw nsw i32 %17, 1
  %19 = call i32 @cq_template_select_i32(i32 %17, i32 %18, i32 %13)    ; IR: next %17 / %13 = a ? %18 : %17
  %20 = call i32 @cq_template_add_i32_hl(i32 %12, i32 1)    ; IR: %19 = getelementptr i8, ptr %16, i64 1: p.idx + 1 (the logical-i32 cell index)
  %21 = call i32 @cq_template_select_i32(i32 %17, i32 %20, i32 %12)    ; IR: next %16 = a ? %19 : %16
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  %22 = add nuw nsw i32 %11, 1
  %23 = icmp ult i32 %22, 4    ; IR: K-bounded br i1 %21, label %12, label %15  [K]
  br i1 %23, label %10, label %24

24:
  %25 = call i32 @cqrt_qram_load_i8(i32 %3, i32 %21)    ; IR: %20 = load i8, ptr %19 after trip K: *p for the exit test that would admit a (K+1)-th trip
  %26 = call i32 @cq_template_icmp_eq_i8_hl(i32 %25, i8 0)    ; IR: %21 = icmp eq i8 %20, 0 after trip K
  %27 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & NOT that test  [output rail, kept]
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  call void @cqrt_and_i1(i32 %17, i32 %26, i32 %27)    ; IR: br i1 %21 not taken once more (rule 14)
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %26, i32 %25, i8 0)    ; IR: uncompute that test
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %25, i32 %3, i32 %21)    ; IR: un-copy that load against the preserved cell
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  %28 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %13 = phi i32 [ 0, %2 ], [ %18, %15 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %19, i32 %28)    ; IR: %13
  br label %29

29:
  %30 = phi i32 [ 0, %24 ], [ %41, %29 ]    ; IR: reverse trip index
  %31 = phi i32 [ %21, %24 ], [ %40, %29 ]    ; IR: %16 written by this trip
  %32 = phi i32 [ %19, %24 ], [ %39, %29 ]    ; IR: %17 written by this trip
  %33 = phi i32 [ %17, %24 ], [ %38, %29 ]    ; IR: predicate of this trip
  %34 = call i32 @cqrt_pop()    ; IR: %19 (p.idx + 1) of this trip
  %35 = call i32 @cqrt_pop()    ; IR: %18 (n + 1)
  %36 = call i32 @cqrt_pop()    ; IR: the test flag %11 / %21
  %37 = call i32 @cqrt_pop()    ; IR: the load %10 / %20
  %38 = call i32 @cqrt_pop()    ; IR: predicate of the previous trip (trip 0: the |1> seed)
  %39 = call i32 @cqrt_pop()    ; IR: %17 incoming
  %40 = call i32 @cqrt_pop()    ; IR: %16 incoming
  call void @cq_template_select_i32_unc(i32 %32, i32 %33, i32 %35, i32 %39)    ; IR: uncompute next %17
  call void @cqrt_free(i32 %32)    ; IR: release next %17 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %35, i32 %39, i32 1)    ; IR: uncompute %18
  call void @cqrt_free(i32 %35)    ; IR: release %18 (|0>)
  call void @cq_template_select_i32_unc(i32 %31, i32 %33, i32 %34, i32 %40)    ; IR: uncompute next %16
  call void @cqrt_free(i32 %31)    ; IR: release next %16 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %34, i32 %40, i32 1)    ; IR: uncompute %19
  call void @cqrt_free(i32 %34)    ; IR: release %19 (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket
  call void @cqrt_and_i1(i32 %38, i32 %36, i32 %33)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket
  call void @cqrt_free(i32 %33)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %36, i32 %37, i8 0)    ; IR: uncompute %11 / %21
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %37, i32 %3, i32 %40)    ; IR: un-copy %10 / %20 against the preserved cell
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  %41 = add nuw nsw i32 %30, 1
  %42 = icmp ult i32 %41, 4    ; IR: K  [K]
  br i1 %42, label %29, label %43

43:
  call void @cqrt_free(i32 %38)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %39)    ; IR: release incoming 0 of phi %17 (never written, |0>)
  call void @cqrt_free(i32 %40)    ; IR: release incoming %3 of phi %16 (p.idx seed, never written, |0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %3, i32 2, i32 %6)    ; IR: pop the initializer of s[2]
  call void @cq_template_xor_i8_hl_unc(i32 %6, i32 %4, i8 3)    ; IR: uncompute %7 by its producer
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %3, i32 1, i32 %5)    ; IR: pop the initializer of s[1]
  call void @cq_template_add_i8_hl_unc(i32 %5, i32 %4, i8 1)    ; IR: uncompute %5 by its producer
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %3, i32 0, i32 %4)    ; IR: pop the initializer of s[0] (the register c stays allocated: a user register)
  call void @cqrt_qram_free(i32 %3)    ; IR: llvm.lifetime.end: release the array (all cells |0>)
  %44 = call i32 @cqrt_measure_i32(i32 %28)    ; IR: %14 = cq_measure_si32(%13)
  ret i32 %44    ; IR: ret i32 %14
}

declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i8(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i8_hl(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare void @cq_template_add_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_xor_i8_hl(i32, i8)
declare void @cq_template_xor_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_icmp_eq_i8_hl(i32, i8)
declare void @cq_template_icmp_eq_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
