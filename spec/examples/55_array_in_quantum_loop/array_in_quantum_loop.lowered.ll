; HAND-WRITTEN. Rules: 20, 22, 21, 16, 14 (a_K kept), 5, 7, 8, 4, 2.
; Checked: a[m - 1] after the K-bounded loop a[i] = i * c, i = 0..m (the load copy at the address rail, measured,
; %35 -> %43); the cells of a at exit, read from the bus at the block's address: a[j] = j * c where trip j ran (j <= m,
; j < K), else 0.
; Clean: the hoisted bound m + 1 and its zext (%16, %17); every trip's latch flag (%27, pushed, popped and uncomputed by
; the reverse loop); the address chain of &a[m - 1] (the index m - 1, its sext, the scaled index, the address rail:
; %31..%34), uncomputed right after the load (the load copy is measured, so the load is the rail's last reader).
; Kept: the user register m (%7); the load copy a[m - 1] (%35, measured: rule 2, never un-copied); by rule 5: the 16
; tape slots of the memset's byte stores and their one value seed i8 0 (%8, rule 7); per trip j the tape slot of the
; store a[j] = j * c, its value seed j * c (%23) and its control rail, the trip predicate a_j (%20: a_0 is the guard
; flag %15 inside its X bracket, a_1..a_{K-1} are %28 of trips 0..K-2), none of them pushed (rule 14: a trip rail rule
; 5 keeps is not pushed); the LAST trip predicate a_K (%28 of trip K - 1; rule 14: a_K = 1 means the loop had not
; exited after K trips, which is observable; the trip count m + 1 has no range bound, so B is unknown and a_K is kept).
; Rotations: (Ry, m, th, 1).
; ONE BUS (rule 20). a is BUS-RESIDENT: the loop's store through it is under a quantum predicate (the trip predicate)
; and the read a[m - 1] goes through a getelementptr with a tainted index, so rule 20 (b) fails for it: __cq_alloc(16,
; 16) at the alloca's program point (rules 16, 20: one zeroed block, no alloca remains, the lifetime markers are
; dropped and the end of the lifetime undoes nothing). m = __cq_mem() once at entry. Nothing is known about the block
; at compile time: its address is a classical i64 (ptrtoint), and no index is narrowed, bounded or checked (rule 21).
; THE INITIALIZER (rule 22). `= {0, 0, 0, 0}` is -O1's llvm.memset(a, 0, 16): ONE host loop of 16 kept byte stores
; qram_store_i8_hl at the classical addresses a + j, all of one value seed alloc_i8(0) (rule 7). It is emitted although
; the block is already zero (§0). Value, address and control are classical-valued, so the cells stay HOST.
; THE LOOP. The bound is quantum (m + 1 trips), so it is the rolled K-bounded loop of example 05 (rule 14), unchanged:
; its first predicate is NOT (m < 0) (an X bracket on the guard flag) and the next predicate is a_j & NOT (j + 1 ==
; m + 1). Inside trip j the store a[i] = i * c has the CLASSICAL address &a[j] (an affine induction with a classical
; start, recomputed from the trip index by a getelementptr without inbounds, never carried or pushed) and the
; classical value j * c, minted as the seed alloc_i32(j * c) (rule 7). It is ONE kept store
; qram_store_i32_hl_controlled(a_j, m, &a[j], seed) (rule 14: every bus access of trip j is under a_j): under a_j = 0
; nothing is touched and its slot stays |0>; under a_j = 1 the cell becomes QUANTUM (§1.3). The store is never popped
; (rule 5 sentence 3), so its control a_j and its value seed stay; the reverse loop pops only the latch flags.
; THE READ (rules 20, 21). a[m - 1] is one qram_load_i32 at an ADDRESS RAIL: the index m - 1 (add template), -O1's
; sext to i64 (sext template), scaled by mul_i64_hl(., 4) and added to the classical base by add_i64_hl. An address
; outside the block reads whatever the bus holds there (HOST bytes, or 0 where unreadable, §2): nothing is checked.
; Basis check (driver array_in_quantum_loop(1, .5, 3)): Ry(.5) flips each of the 32 bits of m0 = 1 with p = sin^2(.25)
; = 0.061209. On the unflipped branch ((1 - p)^32 = 0.132498) m = 1: trips 0 and 1 run (a_0 = a_1 = 1, a_2 = a_3 =
; a_K = 0), a = {0, 3, 0, 0} and a[0] = 0 is measured. m = 3 (bit 1 flipped): four trips, a = {0, 3, 6, 9}, a[2] = 6,
; a_K = 0 (the loop exits after exactly K trips). m = 5 (bit 2 flipped): four trips, a_K = 1, and a[4] reads the bytes
; just past the block.
; SPEC GAP: rule 8 closes the X bracket of a flag; the guard flag %15 here is trip 0's predicate and so the control of a
; kept store (rule 5), never uncomputed. Chosen: the bracket is still closed (not_i1 after the loop, where the old
; construction closed it before the flag's _unc), so the kept rail holds the IR's %6 = (m < 0).
source_filename = "array_in_quantum_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @array_in_quantum_loop(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [bus-resident (rule 20): one zeroed block, no alloca remains (rule 16)]
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical, rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register m]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%4, i8 0, 16): the byte value as ONE seed rail (rules 7, 22), kept with its stores; llvm.lifetime.start dropped (rule 16)
  br label %9

9:
  %10 = phi i64 [ 0, %3 ], [ %12, %9 ]    ; IR: call @llvm.memset(%4, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %11 = add i64 %6, %10    ; IR: the classical address a + j
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %11, i32 %8)    ; IR: call @llvm.memset(%4, i8 0, 16): byte store j  (kept store, rule 5; classical-valued, the cell stays HOST)
  %12 = add nuw nsw i64 %10, 1
  %13 = icmp eq i64 %12, 16
  br i1 %13, label %14, label %9

14:
  %15 = call i32 @cq_template_icmp_slt_i32_hl(i32 %7, i32 0)    ; IR: %6 = icmp slt i32 %5, 0  [guard]
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: the loop is entered under NOT %6 (used as trip 0's predicate)
  %16 = call i32 @cq_template_add_i32_hl(i32 %7, i32 1)    ; IR: %8 = add nuw i32 %5, 1  (pure, hoisted out of block %7)
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)    ; IR: %9 = zext i32 %8 to i64
  br label %18

18:
  %19 = phi i64 [ 0, %14 ], [ %26, %18 ]    ; IR: %17 = phi i64 [ 0, %7 ], [ %21, %16 ]  (classical trip index, bounded by K)  [K]
  %20 = phi i32 [ %15, %14 ], [ %28, %18 ]    ; IR: predicate of this trip (trip 0: NOT %6)
  %21 = trunc i64 %19 to i32    ; IR: %19 = trunc i64 %17 to i32  (classical)
  %22 = mul i32 %21, %2    ; IR: %20 = mul i32 %19, %2  (classical)
  %23 = call i32 @cqrt_alloc_i32(i32 %22)    ; IR: store i32 %20, ptr %18: the classical value i*c of this trip as a seed (rule 7), the store's value rail, kept with it
  %24 = getelementptr [4 x i32], ptr %5, i64 0, i64 %19    ; IR: %18 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %17  [affine induction, classical start: recomputed from the trip index, not carried]
  %25 = ptrtoint ptr %24 to i64    ; IR: &a[i], the _hl address
  call void @cqrt_qram_store_i32_hl_controlled(i32 %20, i32 %4, i64 %25, i32 %23)    ; IR: store i32 %20, ptr %18: a[i] = i*c under this trip's predicate  [kept store (rule 5): its slot, its value seed and its control a_j stay]
  %26 = add nuw nsw i64 %19, 1    ; IR: %21 = add nuw nsw i64 %17, 1  (classical)
  %27 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 %26)    ; IR: %22 = icmp eq i64 %21, %9
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next trip = a & NOT %22
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_and_i1(i32 %20, i32 %27, i32 %28)    ; IR: br i1 %22 not taken
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_push(i32 %27)    ; IR: %22 of this trip, for the reverse loop (a_j and the value seed are kept, not pushed: rule 14)
  %29 = icmp ult i64 %26, 4    ; IR: K-bounded br i1 %22, label %10, label %16  [K]
  br i1 %29, label %18, label %30

30:
  %31 = call i32 @cq_template_add_i32_hl(i32 %7, i32 -1)    ; IR: %11 = add nsw i32 %5, -1
  %32 = call i32 @cq_template_sext_i32_to_i64(i32 %31)    ; IR: %12 = sext i32 %11 to i64
  %33 = call i32 @cq_template_mul_i64_hl(i32 %32, i64 4)    ; IR: %13 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %12  [the tainted index scaled by the element size (rule 20)]
  %34 = call i32 @cq_template_add_i64_hl(i32 %33, i64 %6)    ; IR: %13 = getelementptr  [+ the classical base: the address rail of &a[m - 1]]
  %35 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %34)    ; IR: %14 = load i32, ptr %13: a[m - 1]  [a load at an address rail; measured below, so never un-copied (rules 2, 5)]  [result rail]
  call void @cq_template_add_i64_hl_unc(i32 %34, i32 %33, i64 %6)    ; IR: uncompute %13  [the address rail: its load is its last reader (rule 20)]
  call void @cqrt_free(i32 %34)    ; IR: release the %13 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %33, i32 %32, i64 4)    ; IR: uncompute %13 (the scaled index)
  call void @cqrt_free(i32 %33)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %32, i32 %31)    ; IR: uncompute %12
  call void @cqrt_free(i32 %32)    ; IR: release the %12 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %31, i32 %7, i32 -1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %31)    ; IR: release the %11 rail (|0>)
  br label %36

36:
  %37 = phi i64 [ 3, %30 ], [ %40, %36 ]    ; IR: reverse trip index (K - 1 down to 0)  [K]
  %38 = call i32 @cqrt_pop()    ; IR: %22 of that trip
  %39 = add nuw nsw i64 %37, 1    ; IR: %21 of that trip (classical)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %38, i32 %17, i64 %39)    ; IR: uncompute %22
  call void @cqrt_free(i32 %38)    ; IR: release %22 (|0>)
  %40 = add nsw i64 %37, -1
  %41 = icmp sgt i64 %40, -1    ; IR: K  [K]
  br i1 %41, label %36, label %42

42:
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket closed: %6 back; the flag is trip 0's store control and stays (rule 5)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)    ; IR: uncompute %9
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %7, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %16)
  %43 = call i32 @cqrt_measure_i32(i32 %35)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %43    ; IR: llvm.lifetime.end(16, %4) dropped (rule 16); ret i32 %15
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cq_template_sext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
