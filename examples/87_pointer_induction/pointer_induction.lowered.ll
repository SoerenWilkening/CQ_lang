; HAND-WRITTEN. Rules: 21, 20, 14 (re-rolled; a_K kept), 16, 5, 8, 9, 4, 7, 2.
; Checked: n = the number of leading nonzero bytes of s = {c, c + 1, c ^ 3, 0}, over at most K = 4 trips (measured
; through the copied-out rail %32 -> %47); the cells of s at exit, read from the bus at the block's address:
; {c, c + 1, c ^ 3, 0}.
; Clean: every trip's load copy *p (%20, un-copied by the reverse loop under the control it was loaded with: no memory
; version change follows the initializer stores), its flag (%21), n + 1 (%23), the select merge of n (%24) and the trip
; predicate a_0..a_{K-1} (%22, uncomputed by the reverse loop: a_{K-1} enters it through %36, a_0..a_{K-2} are popped
; as %40; a_K is a separate kept rail); the after-trip-K exit test (its
; load %29 and flag %30, undone at once); the |1> seed (%14) and the |0> seed of n (%13) (rule 7).
; Kept: the user register c (%6, also the value rail of the kept store s[0]); the value rails of the other three kept
; stores (rule 5 sentence 3): c + 1 (%7), c ^ 3 (%9) and the seed of the literal 0 (%11; rule 7, a basis state, no
; qubit); the four stores' tape slots (backend rails); the copied-out result rail (%32, measured); a_K (%31: the exit
; test *p != 0 evaluated after the K-th body, ANDed with trip K's predicate; rule 14: a_K = 1 iff the loop would run
; a (K+1)-th trip, which is observable; a loop that exits after exactly K trips reads 0). No range fact bounds the
; trip count (it depends on memory contents; the array's extent and the inbounds gep are never a bound, rule 21), so
; the cutoff is K and a_K is kept.
; Rotations: (Ry, c, th, 1).
; Expected: count_nonzero(0, .5). Ry(.5) flips each of the 8 bits of c with p = sin^2(.25) = 0.061209 and everything
; after it is a basis permutation, so n is distributed as the C program on the flipped c: c = 0 gives n = 0
; (0.603326), c = 255 gives n = 1 (s[1] = 0; 1.97e-10), c = 3 gives n = 2 (s[2] = 0; 0.002565), every other c n = 3
; (0.394109, s[3] = 0 stops it). n never reaches K, so a_K = 0 on every branch.
; A POINTER AS THE LOOP INDUCTION of a rolled loop whose exit depends on quantum data (rules 21, 14). ONE BUS (rule 20):
; the alloca s is BUS-RESIDENT, because a store through it of a tainted value (s[0] = c) is among its users, so no
; alloca remains: its block is __cq_alloc(4, 1) at the alloca's program point (rule 16, zeroed) and the lifetime
; markers are dropped. m = __cq_mem() is called once, at entry. The block's run-time address is a classical i64
; (rule 21) and every address below is that i64 plus a classical offset: nothing is known about what it points to.
; THE INITIALIZER: four bus stores at the classical addresses s + 0..3, in program order (two bus accesses never
; commute, rule 5), each ONE qram_store_i8_hl whose value is always a handle: the register c itself, the template
; results c + 1 and c ^ 3, and for s[3] = 0 the seed alloc_i8(0) (rules 7, 20; the store is emitted although the
; fresh block already holds 0: that is never asked, §0). Every store is KEPT (rule 5 sentence 3): no pop, its tape
; slot and its value rail stay, so c + 1 and c ^ 3 are never uncomputed. The s[3] store has classical-valued address,
; value and control, so it writes the host byte and that cell stays HOST (§1.3).
; THE POINTER p: -O1 carries it as phi ptr [s, +1]. Its SCEV is {s,+,1}: a loop-invariant classical start and an
; unconditional classical step, so it is an AFFINE INDUCTION (rule 14) and is NOT carried: in trip j it is the
; classical i64 s + j, recomputed from the trip index in the forward and in the reverse loop (arithmetic without
; inbounds/nuw/nsw) and never pushed. Its exit value is never read after the loop, so no carried address rail
; exists. Every *p is therefore an _hl access at a classical address.
; Re-rolled (rule 14): -O1's pre-header test *s != 0 is the latch test *(p + 1) != 0 one trip earlier (the same i8
; load at the SCEV-equal address s, no memory version change between the guard and the loop header), so it is trip
; 0. Trip j loads *p = s[j] (ONE cqrt_qram_load_i8_hl_controlled, copy-out, cells preserved) under the predicate of
; REACHING its test (a_{j-1}; the |1> seed for trip 0): a trip C would not run touches no cell and no host byte. It
; tests the copy and forms a_j = a_{j-1} & NOT(*p == 0) (the IR's flag is the exit edge, so the conjunction sits in
; an X bracket, rule 8); n++ is select-merged on a_j (rule 9; the arm's pure add runs unguarded). The literal 4 is K
; [K]. After trip K the exit test is evaluated once more at s + K under a_{K-1} (one cell past the block, read only on
; the branch where C reads it too; no bound is checked, rule 21; it reads 0 by §2 or whatever the address holds) and
; a_K = a_{K-1} & NOT(*p == 0) is kept; that load and flag are undone at once. After n is copied out the reverse loop
; pops each trip and uncomputes it, the load's controlled _unc un-copying against the preserved cell at the address
; recomputed from the trip index. Nothing is popped or freed for the block: a store is never popped and a block is
; never freed (rules 5, 16).
source_filename = "pointer_induction.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @count_nonzero(i8 noundef zeroext %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry
  %4 = call ptr @__cq_alloc(i64 4, i64 1)    ; IR: %3 = alloca [4 x i8], align 1  [bus-resident (a tainted value is stored through it): one zeroed block, no alloca remains (rules 16, 20)]
  %5 = ptrtoint ptr %4 to i64    ; the block's run-time address s, a classical i64 (rule 21)
  %6 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %4 = cq_theta_ui8(%0, %1)  [register c]
  call void @cqrt_ry_i8(i32 %6, double %1)    ; IR: %4 = cq_theta_ui8(%0, %1)  [Ry]; llvm.lifetime.start(4, %3) dropped (rule 16)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %5, i32 %6)    ; IR: store i8 %4, ptr %3: s[0] = c  [kept store at a classical address; the value rail is the register c]
  %7 = call i32 @cq_template_add_i8_hl(i32 %6, i8 1)    ; IR: %5 = add i8 %4, 1
  %8 = add i64 %5, 1    ; IR: %6 = getelementptr inbounds i8, ptr %3, i64 1  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %8, i32 %7)    ; IR: store i8 %5, ptr %6: s[1] = c + 1  [kept store; %5's rail is its value rail, KEPT]
  %9 = call i32 @cq_template_xor_i8_hl(i32 %6, i8 3)    ; IR: %7 = xor i8 %4, 3
  %10 = add i64 %5, 2    ; IR: %8 = getelementptr inbounds i8, ptr %3, i64 2  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %10, i32 %9)    ; IR: store i8 %7, ptr %8: s[2] = c ^ 3  [kept store; %7's rail is its value rail, KEPT]
  %11 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %9  [the seed of the literal 0: the store's value rail, KEPT with it (rules 5, 7)]
  %12 = add i64 %5, 3    ; IR: %9 = getelementptr inbounds i8, ptr %3, i64 3  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %12, i32 %11)    ; IR: store i8 0, ptr %9: s[3] = 0  [kept store; classical-valued, so the host byte is written and the cell stays HOST]
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %17 / %13
  %14 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %2 (always 1)
  br label %15

15:
  %16 = phi i64 [ 0, %2 ], [ %25, %15 ]    ; IR: trip index j, bounded by K; p = s + j (%16 = phi ptr: an affine induction, not carried)  [K]
  %17 = phi i32 [ %13, %2 ], [ %24, %15 ]    ; IR: %17 = phi i32 [ %18, %15 ], [ 0, %2 ]
  %18 = phi i32 [ %14, %2 ], [ %22, %15 ]    ; IR: predicate of reaching this trip's test
  %19 = add i64 %5, %16    ; IR: p: %3 (trip 0) / %19 = getelementptr inbounds i8, ptr %16, i64 1  [the classical address s + j]
  %20 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %18, i32 %3, i64 %19)    ; IR: %10 = load i8, ptr %3 (trip 0) / %20 = load i8, ptr %19: *p, ONE bus access under the predicate of reaching the test
  %21 = call i32 @cq_template_icmp_eq_i8_hl(i32 %20, i8 0)    ; IR: %11 = icmp eq i8 %10, 0 (trip 0) / %21 = icmp eq i8 %20, 0
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket: the loop body runs when the test is false
  call void @cqrt_and_i1(i32 %18, i32 %21, i32 %22)    ; IR: br i1 %11 (trip 0) / br i1 %21 not taken: a_j = a_{j-1} & NOT test
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket
  %23 = call i32 @cq_template_add_i32_hl(i32 %17, i32 1)    ; IR: %18 = add nuw nsw i32 %17, 1
  %24 = call i32 @cq_template_select_i32(i32 %22, i32 %23, i32 %17)    ; IR: next %17 / %13 = a ? %18 : %17
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %23)
  %25 = add nuw nsw i64 %16, 1    ; IR: p++ is j + 1 (no gate)
  %26 = icmp ult i64 %25, 4    ; IR: K-bounded br i1 %21, label %12, label %15  [K]
  br i1 %26, label %15, label %27

27:
  %28 = add i64 %5, 4    ; IR: %19 = getelementptr after trip K: the classical address s + K  [K]
  %29 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %22, i32 %3, i64 %28)    ; IR: %20 = load i8, ptr %19 after trip K, under the predicate of trip K: *p for the exit test that would admit a (K+1)-th trip
  %30 = call i32 @cq_template_icmp_eq_i8_hl(i32 %29, i8 0)    ; IR: %21 = icmp eq i8 %20, 0 after trip K
  %31 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & NOT that test  [output rail, kept]
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %31)    ; IR: br i1 %21 not taken once more (rule 14)
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %30, i32 %29, i8 0)    ; IR: uncompute that test
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %29, i32 %22, i32 %3, i64 %28)    ; IR: un-copy that load under the same control (rule 5)
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  %32 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %13 = phi i32 [ 0, %2 ], [ %18, %15 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %24, i32 %32)    ; IR: %13
  br label %33

33:
  %34 = phi i64 [ 0, %27 ], [ %44, %33 ]    ; IR: reverse trip index
  %35 = phi i32 [ %24, %27 ], [ %41, %33 ]    ; IR: %17 written by this trip
  %36 = phi i32 [ %22, %27 ], [ %40, %33 ]    ; IR: predicate of this trip
  %37 = call i32 @cqrt_pop()    ; IR: %18 (n + 1)
  %38 = call i32 @cqrt_pop()    ; IR: the test flag %11 / %21
  %39 = call i32 @cqrt_pop()    ; IR: the load %10 / %20
  %40 = call i32 @cqrt_pop()    ; IR: predicate of the previous trip (trip 0: the |1> seed)
  %41 = call i32 @cqrt_pop()    ; IR: %17 incoming
  %42 = sub i64 3, %34    ; IR: this trip's index j = K - 1 - reverse index  [K]
  %43 = add i64 %5, %42    ; IR: p = s + j, recomputed from the trip index
  call void @cq_template_select_i32_unc(i32 %35, i32 %36, i32 %37, i32 %41)    ; IR: uncompute next %17
  call void @cqrt_free(i32 %35)    ; IR: release next %17 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %37, i32 %41, i32 1)    ; IR: uncompute %18
  call void @cqrt_free(i32 %37)    ; IR: release %18 (|0>)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket
  call void @cqrt_and_i1(i32 %40, i32 %38, i32 %36)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket
  call void @cqrt_free(i32 %36)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %38, i32 %39, i8 0)    ; IR: uncompute %11 / %21
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %39, i32 %40, i32 %3, i64 %43)    ; IR: un-copy %10 / %20 under the control it was loaded with (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  %44 = add nuw nsw i64 %34, 1
  %45 = icmp ult i64 %44, 4    ; IR: K  [K]
  br i1 %45, label %33, label %46

46:
  call void @cqrt_free(i32 %40)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %41)    ; IR: release incoming 0 of phi %17 (never written, |0>)
  %47 = call i32 @cqrt_measure_i32(i32 %32)    ; IR: %14 = cq_measure_si32(%13); llvm.lifetime.end(4, %3) dropped: the block is never freed (rule 16)
  ret i32 %47    ; IR: ret i32 %14
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
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
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_xor_i8_hl(i32, i8)
declare i32 @cq_template_icmp_eq_i8_hl(i32, i8)
declare void @cq_template_icmp_eq_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
