; HAND-WRITTEN. Rules: 20, 22, 14 (a_K kept), 8, 4, 5, 7, 2.
; Checked: a[m - 1] after the K-bounded loop a[i] = i * c, i = 0..m (measured).
; Clean: the guard flag m < 0, the hoisted bound m + 1 and its zext, the index rail m - 1, every trip's latch flag and
; basis-state store value (rule 7), the shared memset handle 0 (rule 7), the next-trip predicates a_1..a_{K-1}, every
; store's tape slot (each pop returns it to |0>), and the QRAM a (every store popped, then cqrt_qram_free).
; Kept: the user register m; the loaded result rail (measured); the LAST trip predicate a_K (rule 14: a_K = 1 means the
; loop had not exited after K trips, which is observable; the trip count m + 1 has no range bound, so B is unknown and
; a_K is kept). a_K is the predicate computed by the last forward trip, the first popped in the reverse loop (reverse
; index K - 1); the reverse loop skips its and_i1 uncompute and its free by a classical branch and leaves it allocated.
; Rotations: Ry(th) on m.
; The array's cells become quantum (written under the trip predicate of a quantum-bounded loop, then read at a quantum
; index), so the array is a QRAM (rule 20; address decoding is the backend's circuit; ABI = the QRAM contract of §1.3,
; reference conversions 30 and 84): cqrt_qram_alloc_<W>(4) at the alloca (cells |0>) and every access ONE call. The
; initializer `= {0, 0, 0, 0}` is -O1's llvm.memset(a, 0, 16), a memory intrinsic with a classical length: one
; cqrt_qram_store_<W>_hl(arr, j, val) per cell (rule 22), all four reading ONE basis-state handle cqrt_alloc_i32(0)
; (shared; freed after its last store is popped). The loop's bound is quantum (m + 1 trips), so it is the rolled
; K-bounded loop of example 05 (rule 14), unchanged: its first predicate is NOT (m < 0) (an X bracket on the guard
; flag) and the next predicate is a_j & NOT (j + 1 == m + 1). Inside a trip the store index i = j is the CLASSICAL trip
; counter and the stored value i*c is classical, so the store is one cqrt_qram_store_<W>_hl_controlled(a_j, arr, j,
; val) (_hl = classical INDEX) under the trip predicate, with the value materialised as a basis-state handle by
; cqrt_alloc_<W> (a store value is ALWAYS a handle; the handle is pushed with the trip's flags for the mirror and freed
; once its store is popped). Each store owns a fresh tape slot (the displaced cell is swapped into it, then cell ^= val;
; under a_j = 0 nothing happens and the slot stays |0>). The read a[m - 1] has a QUANTUM index over QUANTUM cells, so it
; is one cqrt_qram_load_<W>(arr, idx) -> fresh rail (the result; not a QROM, which reads classical cells: 29/30) with the
; logical-i32 index rail m - 1 (-O1's sext to i64 and the gep scaling are not emitted; an index outside 0..3 reads 0,
; §2). Pops (_unc, same arguments) need the value, index and control at their forward values, which they hold (the
; predicates and value handles are popped from the stack unchanged), and are ordered last-in-first-out only among
; stores that may touch the same cell: the reverse loop pops trip j's store (cell j) before cell j's memset store, the
; memset stores (distinct cells, commuting) follow, then cqrt_qram_free releases the all-|0> array before the
; measurement. This is the k_rem_pio2 shape (iq[], f[], q[] written at the loop index, read at jz-relative indices).
; K = 4 (the literal 4 below, tagged [K]) also bounds the cell index.
source_filename = "array_in_quantum_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @array_in_quantum_loop(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4 = alloca [4 x i32]: a 4-cell QRAM, cells |0>
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register m]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%4, 0, 16): the classical value 0 as ONE basis-state handle, shared by the four cell stores (rule 22)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %6)    ; IR: memset: a[0] = 0  (fixed-index store; its tape slot takes the displaced |0> cell)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %6)    ; IR: memset: a[1] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 2, i32 %6)    ; IR: memset: a[2] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 3, i32 %6)    ; IR: memset: a[3] = 0
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %5, i32 0)    ; IR: %6 = icmp slt i32 %5, 0  [guard]
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: the loop is entered under NOT %6 (used as trip 0's predicate)
  %8 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)    ; IR: %8 = add nuw i32 %5, 1  (pure, hoisted out of block %7)
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %9 = zext i32 %8 to i64
  br label %10

10:
  %11 = phi i64 [ 0, %3 ], [ %16, %10 ]    ; IR: %17 = phi i64 [ 0, %7 ], [ %21, %16 ]  (classical trip index, bounded by K)  [K]
  %12 = phi i32 [ %7, %3 ], [ %18, %10 ]    ; IR: predicate of this trip (trip 0: NOT %6)
  %13 = trunc i64 %11 to i32    ; IR: %19 = trunc i64 %17 to i32  (classical)
  %14 = mul i32 %13, %2    ; IR: %20 = mul i32 %19, %2  (classical)
  %15 = call i32 @cqrt_alloc_i32(i32 %14)    ; IR: store i32 %20, ptr %18: the classical value i*c of this trip as a basis-state handle
  call void @cqrt_qram_store_i32_hl_controlled(i32 %12, i32 %4, i32 %13, i32 %15)    ; IR: store i32 %20, ptr %18: a[i] = i*c under this trip's predicate (fixed index i = the classical trip counter; the %18 gep is not emitted; the displaced cell goes onto the backend's tape)
  %16 = add nuw nsw i64 %11, 1    ; IR: %21 = add nuw nsw i64 %17, 1  (classical)
  %17 = call i32 @cq_template_icmp_eq_i64_hl(i32 %9, i64 %16)    ; IR: %22 = icmp eq i64 %21, %9
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next trip = a & NOT %22
  call void @cqrt_not_i1(i32 %17)    ; IR: bracket
  call void @cqrt_and_i1(i32 %12, i32 %17, i32 %18)    ; IR: br i1 %22 not taken
  call void @cqrt_not_i1(i32 %17)    ; IR: bracket
  call void @cqrt_push(i32 %15)    ; IR: the value handle of this trip's store, for the mirror
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %17)
  %19 = icmp ult i64 %16, 4    ; IR: K-bounded br i1 %22, label %10, label %16  [K]
  br i1 %19, label %10, label %20

20:
  %21 = call i32 @cq_template_add_i32_hl(i32 %5, i32 -1)    ; IR: %11 = add nsw i32 %5, -1  [the index rail; the %12 sext and the %13 gep are not emitted]
  %22 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %21)    ; IR: %14 = load i32, ptr %13: a[m - 1]  (one access: quantum index over quantum cells, copy-out into a fresh rail)  [result rail]
  call void @cq_template_add_i32_hl_unc(i32 %21, i32 %5, i32 -1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %21)    ; IR: release the %11 rail (|0>)
  br label %23

23:
  %24 = phi i64 [ 3, %20 ], [ %34, %33 ]    ; IR: reverse trip index (K - 1 down to 0)  [K]
  %25 = phi i32 [ %18, %20 ], [ %27, %33 ]    ; IR: predicate computed by this trip (on the first reverse trip: a_K, kept)
  %26 = call i32 @cqrt_pop()    ; IR: %22 of that trip
  %27 = call i32 @cqrt_pop()    ; IR: the predicate of that trip
  %28 = call i32 @cqrt_pop()    ; IR: the value handle of that trip's store
  %29 = trunc i64 %24 to i32    ; IR: %19 of that trip (classical)
  %30 = add nuw nsw i64 %24, 1
  %31 = icmp eq i64 %24, 3    ; IR: reverse index K - 1 is the last forward trip: the predicate it computed is a_K, the output rail (rule 14)  [K]
  br i1 %31, label %33, label %32

32:
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  call void @cqrt_and_i1(i32 %27, i32 %26, i32 %25)    ; IR: uncompute the next-trip predicate (a_1..a_{K-1})
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  br label %33

33:
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %26, i32 %9, i64 %30)    ; IR: uncompute %22
  call void @cqrt_free(i32 %26)    ; IR: release %22 (|0>)
  call void @cqrt_qram_store_i32_hl_controlled_unc(i32 %27, i32 %4, i32 %29, i32 %28)    ; IR: pop store i32 %20, ptr %18 of that trip (before the memset store of the same cell): a[i] holds its memset 0 again, the slot is |0> and released
  call void @cqrt_free(i32 %28)    ; IR: release the value handle (basis state i*c)
  %34 = add nsw i64 %24, -1
  %35 = icmp sgt i64 %34, -1    ; IR: K  [K]
  br i1 %35, label %23, label %36

36:
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: %6 back
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %5, i32 0)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release %6 (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %5, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 3, i32 %6)    ; IR: pop the memset stores (after the trip stores to the same cells; distinct cells commute, written in reverse): a[3] back to |0>
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 2, i32 %6)    ; IR: a[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %6)    ; IR: a[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %6)    ; IR: a[0]
  call void @cqrt_free(i32 %6)    ; IR: release the basis-state handle 0 (its last store was popped)
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %37 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %37    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_controlled_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
