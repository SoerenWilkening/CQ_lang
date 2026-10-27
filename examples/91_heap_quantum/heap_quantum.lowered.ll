; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 16, 20, 21.
; Checked: heap_quantum_size: r = a[1] + a[5] (measured). heap_in_loop: last ? last[0] : 7 (measured).
; Clean: heap_quantum_size: the quantum size n & 3 and its zext, the index rail k & 3, the value handles v and 1, the
; copy-out a[1] and the free predicate k > 100, all freed; both stores are popped (their tape slots back to |0>), the
; realloc undone and the QRAM a released. heap_in_loop: the trip count x & 3, the NULL tag seed, the |1> seed predicate,
; every trip's rails (exit compare, trip predicate, x + i and its trunc, which is the trip object's cell, the tag
; select) popped and uncomputed, the object flags, the select chain of the read and its zext, the null test.
; Kept: heap_quantum_size: n and k, the rotated registers, and r (measured). heap_in_loop: x (the rotated register) and
; the result (measured). No trip predicate is kept: the loop's exit is quantum (i == x & 3) and its cutoff is
; min(K, B) with B = 3, the upper bound of the trip count x & 3 from LLVM's range facts (rule 14); B <= K, so a_K is
; not kept and every predicate, the last included, is uncomputed by the mirror.
; Rotations: heap_quantum_size: (Ry, n, tn, 1); (Ry, k, tk, 1). heap_in_loop: (Ry, x, th, 1).
; HEAP OBJECTS are objects of the table like an alloca and are classified by rule 20 over all their accesses.
; heap_quantum_size: a[k & 3] = v is a QUANTUM-OFFSET store, so the block (malloc site and its realloc: the same object)
; is a QRAM for its whole lifetime and every other access is the _hl form: cqrt_qram_alloc_i8 at the malloc site with
; the upper bound of its quantum size, 3 byte cells (n & 3 lies in [0, 3]; a cell past the real size n & 3 is the
; program's own undefined behaviour, read as the cell's content), and realloc(a, 6) is cqrt_qram_realloc_i8(a, 6) -> a'
; (§1.3: a logical resize to 6 cells, no gate, no cell moves; cells 3..5 are new |0> cells), undone by
; cqrt_qram_realloc_i8_unc(a', 3) after every store made through a' is popped. No host block is kept: every cell is a
; QRAM cell, so malloc and realloc emit no host call. The store is ONE cqrt_qram_store_i8(a, idx, v) with the
; logical-i32 index rail k & 3 (-O1's zext to i64 and the gep are not emitted) and v materialised as a basis-state
; handle. It runs at the logical size 3: on the branch k & 3 == 3 its index is out of range and the store is a no-op
; whose tape slot stays |0> (§2); the realloc does not retroactively make it land in cell 3. a[5] = 1 is
; cqrt_qram_store_i8_hl(a', 5, 1) of a basis-state handle (-O1 folded the later read of a[5] to 1); the read a[1] is a
; fixed-index copy-out cqrt_qram_load_i8_hl(a', 1). Each store owns a fresh tape slot (the displaced cell is swapped in,
; then cell ^= v). FREE under a quantum predicate emits nothing (rule 16): deallocation is a lifetime end, a reset
; cannot be conditioned on quantum data, so the block lives to the end of the scope. There the copy-out is un-copied
; (cell 1 holds the value it had at the load), the store a[5] = 1 is popped (made through a', so before the realloc is
; undone), the realloc is undone, and the quantum-index store is popped at the same logical size 3 as its forward
; (stores to cells {0, 1, 2} and {5} are disjoint and commute; pop preconditions hold: v, 1 and k & 3 are unchanged),
; then the QRAM is released. The predicate is computed and uncomputed as any flag.
; heap_in_loop: the loop exit i == x & 3 is quantum and the trip count has the range bound B = 3, so the loop is rolled
; for min(K, B) = 3 trips (tagged [B]: independent of K for K >= 3) under the predicate chain seeded |1> (rule 14). A
; malloc site inside the loop is one object per (site, trip): tags 1..3 for trips 0..2, three host mallocs. Each object
; is written only at the classical offset 0 (p[0] = x + i), and the deref last[0] after the loop has a QUANTUM TAG but
; the CLASSICAL idx 0 (rule 21: a guarded classical-offset access per object, merged by select), so no object is a QRAM:
; each may hold a handle and is a SLOT ARRAY of one cell, a heap block of handle cells (malloc(1): one byte cell = one
; 4-byte handle slot, host malloc(4)). The block pointers sit in a classical table filled by the rolled loop. The store
; is a slot store of the rail trunc(x + i) (no gate); it runs unguarded under the trip predicate because the object is
; fresh in its trip and a trip that did not run never has its object addressed (the select of rule 20 would differ only
; on branches where the cell is unobservable). The read is one slot load per object (the handle, no gate) merged by
; cq_template_select_i8 on the object flags tag == o, chained with object 3 (the complement) innermost (rule 9); the
; NULL test then selects 7. Everything is uncomputed in reverse order before the measurement: the read's chain, then per
; trip (last first) its tag select, its cell rail by its producers, its predicate. The heap blocks are never freed by the
; program and stay allocated (classical host memory). Object tables: heap_quantum_size: 1 = a (QRAM of 3, then 6 byte
; cells). heap_in_loop: j+1 = the block of trip j (a 1-cell slot block).
source_filename = "heap_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"


define i32 @heap_quantum_size(i8 noundef zeroext %0, double noundef %1, i32 noundef %2, double noundef %3, i8 noundef zeroext %4) {
  %6 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %6 = cq_theta_ui8(%0, %1)  [register n]
  call void @cqrt_ry_i8(i32 %6, double %1)    ; IR: %6 = cq_theta_ui8(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_ui32(%2, %3)  [register k]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_ui32(%2, %3)  [Ry]
  %8 = call i32 @cq_template_and_i8_hl(i32 %6, i8 3)    ; IR: %8 = and i8 %6, 3  [the quantum size, range [0, 4)]
  %9 = call i32 @cq_template_zext_i8_to_i64(i32 %8)    ; IR: %9 = zext nneg i8 %8 to i64
  %10 = call i32 @cqrt_qram_alloc_i8(i32 3)    ; IR: %10 = call @malloc(%9): object 1, a QRAM at the upper bound 3 of its quantum size n & 3: 3 byte cells |0> (no host block)
  %11 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %11 = and i32 %7, 3  [the index rail; %12 = zext to i64 and the gep %13 are not emitted]
  %12 = call i32 @cqrt_alloc_i8(i8 %4)    ; IR: store i8 %4, ptr %13: the classical value v as a basis-state handle (a QRAM store value is always a handle)
  call void @cqrt_qram_store_i8(i32 %10, i32 %11, i32 %12)    ; IR: store i8 %4, ptr %13: a[k & 3] = v  (one access at size 3; the displaced cell goes into this store's tape slot; on the branch k & 3 == 3 the index is out of range: no-op, the slot stays |0> (§2))
  %13 = call i32 @cqrt_qram_realloc_i8(i32 %10, i32 6)    ; IR: %14 = call @realloc(%10, 6): the same object resized to 6 cells (logical resize: cells 0..2 keep their state, cells 3..5 are new |0> cells; no gate); the result is the bus from here on
  %14 = call i32 @cqrt_alloc_i8(i8 1)    ; IR: store i8 1, ptr %15: the classical 1 as a basis-state handle
  call void @cqrt_qram_store_i8_hl(i32 %13, i32 5, i32 %14)    ; IR: %15 = gep %14, 5; store i8 1, ptr %15: a[5] = 1  (fixed index 5 of the same QRAM)
  %15 = call i32 @cqrt_qram_load_i8_hl(i32 %13, i32 1)    ; IR: %16 = getelementptr i8, ptr %14, 1; %17 = load i8, ptr %16: a[1]  (fixed-index copy-out)
  %16 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %7, i32 100)    ; IR: %18 = icmp ugt i32 %7, 100  [predicate of block %19]
  ; IR: br i1 %18 -> block %19: free(%15) under a quantum predicate emits nothing (rule 16); the block lives to the end of the scope
  %17 = call i32 @cq_template_add_i8_hl(i32 %15, i8 1)    ; IR: %21 = add i8 %17, 1  (a[5] folded to 1)  [result rail]
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %16, i32 %7, i32 100)    ; IR: uncompute %18
  call void @cqrt_free(i32 %16)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %15, i32 %13, i32 1)    ; IR: un-copy %17 (a[1]): the cell is unchanged since the copy-out
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %13, i32 5, i32 %14)    ; IR: pop the store a[5] = 1 (made through a': popped before the realloc is undone; no other store touches cell 5)
  call void @cqrt_free(i32 %14)    ; IR: release the value handle (basis state 1)
  call void @cqrt_qram_realloc_i8_unc(i32 %13, i32 3)    ; IR: undo the realloc: the logical size is 3 again (cells 3..5 are |0>); %10 is the bus again
  call void @cqrt_qram_store_i8_unc(i32 %10, i32 %11, i32 %12)    ; IR: pop the store a[k & 3] = v at the same logical size 3 as the forward store (k & 3 == 3 stays a no-op): every cell and its slot back to |0>
  call void @cqrt_free(i32 %12)    ; IR: release the value handle (basis state v)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %7, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_zext_i8_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i8_hl_unc(i32 %8, i32 %6, i8 3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cqrt_qram_free(i32 %10)    ; IR: scope end: release object 1's QRAM (every store popped, all cells |0>)
  %18 = call i8 @cqrt_measure_i8(i32 %17)    ; IR: %22 = cq_measure_ui8(%21)
  %19 = zext i8 %18 to i32    ; IR: %23 = zext i8 %22 to i32  (classical)
  ret i32 %19    ; IR: ret i32 %23
}

define i32 @heap_in_loop(i32 noundef %0, double noundef %1) {
  %3 = alloca [3 x ptr], align 16    ; IR: the object table: the slot blocks of the trip objects 1..3 (filled by the loop)
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %4 = and i32 %3, 3  [the trip count, range [0, 3]: B = 3]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming null of phi %7: last's tag before trip 0 (NULL = 0)
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test (always 1)
  br label %8
8:
  %9 = phi i64 [ 0, %2 ], [ %21, %8 ]    ; IR: trip index, bounded by min(K, B) = 3  [B]
  %10 = phi i32 [ %6, %2 ], [ %20, %8 ]    ; IR: %7 = phi ptr [ null, %2 ], [ %11, %9 ]: last's tag so far
  %11 = phi i32 [ %7, %2 ], [ %14, %8 ]    ; IR: predicate of reaching this trip's test
  %12 = trunc nuw nsw i64 %9 to i32    ; IR: %10 = phi i32 (i, classical)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %12)    ; IR: %5 = icmp eq i32 %4, 0 (trip 0) / %15 = icmp eq i32 %14, %4: the loop is over when i == %4
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %9 at this trip
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: the trip runs when i != %4
  call void @cqrt_and_i1(i32 %11, i32 %13, i32 %14)    ; IR: br i1 %5 / %15 not taken: a = ap & NOT e
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket
  %15 = call ptr @malloc(i64 4)    ; IR: %11 = call @malloc(1): object j+1, a slot block of one byte cell = one handle slot  (host call, one per trip: 3 in all)
  %16 = getelementptr inbounds [3 x ptr], ptr %3, i64 0, i64 %9    ; IR: the table entry of object j+1
  store ptr %15, ptr %16, align 8    ; IR: table[j+1] = the block of %11  (classical)
  %17 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %12)    ; IR: %12 = add i32 %10, %3
  %18 = call i32 @cq_template_trunc_i32_to_i8(i32 %17)    ; IR: %13 = trunc i32 %12 to i8
  store i32 %18, ptr %15, align 4    ; IR: store i8 %13, ptr %11: p[0] = (unsigned char)(x + i)  (slot store: the cell takes the handle, no gate)
  %19 = add nuw nsw i32 %12, 1    ; IR: %14 = add nuw nsw i32 %10, 1  (classical; also this trip's object tag j+1)
  %20 = call i32 @cq_template_select_i32_lh(i32 %14, i32 %19, i32 %10)    ; IR: next %7 = a ? %11 (object j+1) : last
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  %21 = add nuw nsw i64 %9, 1
  %22 = icmp ult i64 %21, 3    ; IR: br i1 %15, label %6, label %9, bounded by min(K, B) = 3 trips: after trip 2, i = 3 >= x & 3 on every branch  [B]
  br i1 %22, label %8, label %23
23:
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 0)    ; IR: %8 = icmp eq ptr %7, null: tag == 0
  %25 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 1)    ; IR: %17 = load i8, ptr %7: object 1 addressed iff tag == 1
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 2)    ; IR: %17: object 2 addressed iff tag == 2 (object 3 is the complement)  [B]
  %27 = load ptr, ptr %3, align 8    ; IR: table[1]  (classical)
  %28 = load i32, ptr %27, align 4    ; IR: %17: object 1's cell 0 (the handle in its slot, no gate)
  %29 = getelementptr inbounds [3 x ptr], ptr %3, i64 0, i64 1
  %30 = load ptr, ptr %29, align 8    ; IR: table[2]
  %31 = load i32, ptr %30, align 4    ; IR: %17: object 2's cell 0
  %32 = getelementptr inbounds [3 x ptr], ptr %3, i64 0, i64 2
  %33 = load ptr, ptr %32, align 8    ; IR: table[3]  [B]
  %34 = load i32, ptr %33, align 4    ; IR: %17: object 3's cell 0
  %35 = call i32 @cq_template_select_i8(i32 %26, i32 %31, i32 %34)    ; IR: %17: tag == 2 ? obj2[0] : obj3[0]  (innermost: the complement)
  %36 = call i32 @cq_template_select_i8(i32 %25, i32 %28, i32 %35)    ; IR: %17 = load i8, ptr %7: tag == 1 ? obj1[0] : ...
  %37 = call i32 @cq_template_zext_i8_to_i32(i32 %36)    ; IR: %18 = zext i8 %17 to i32
  %38 = call i32 @cq_template_select_i32_lh(i32 %24, i32 7, i32 %37)    ; IR: %20 = phi i32 [ %18, %16 ], [ 7, %6 ]: null ? 7 : the load  [result rail]
  call void @cq_template_zext_i8_to_i32_unc(i32 %37, i32 %36)    ; IR: uncompute %18
  call void @cqrt_free(i32 %37)    ; IR: release the %18 rail (|0>)
  call void @cq_template_select_i8_unc(i32 %36, i32 %25, i32 %28, i32 %35)    ; IR: uncompute %17
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cq_template_select_i8_unc(i32 %35, i32 %26, i32 %31, i32 %34)    ; IR: uncompute the innermost select
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %26, i32 %20, i32 2)    ; IR: uncompute the object-2 flag
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %25, i32 %20, i32 1)    ; IR: uncompute the object-1 flag
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %20, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %24)    ; IR: release the %8 rail (|0>)
  br label %39
39:
  %40 = phi i64 [ 2, %23 ], [ %50, %39 ]    ; IR: reverse of the loop: trip 2 down to 0  [B]
  %41 = phi i32 [ %20, %23 ], [ %47, %39 ]    ; IR: %7 as written by this trip
  %42 = phi i32 [ %14, %23 ], [ %46, %39 ]    ; IR: predicate of this trip
  %43 = call i32 @cqrt_pop()    ; IR: %13 of this trip (the trip object's cell)
  %44 = call i32 @cqrt_pop()    ; IR: %12 of this trip
  %45 = call i32 @cqrt_pop()    ; IR: %5 / %15 of this trip
  %46 = call i32 @cqrt_pop()    ; IR: predicate of reaching this trip's test
  %47 = call i32 @cqrt_pop()    ; IR: %7 incoming to this trip
  %48 = trunc nuw nsw i64 %40 to i32    ; IR: i of that trip (classical)
  %49 = add nuw nsw i32 %48, 1    ; IR: its object tag
  call void @cq_template_select_i32_lh_unc(i32 %41, i32 %42, i32 %49, i32 %47)    ; IR: uncompute next %7
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_trunc_i32_to_i8_unc(i32 %43, i32 %44)    ; IR: uncompute %13, the cell of the trip's object (no read of it is left)
  call void @cqrt_free(i32 %43)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %44, i32 %4, i32 %48)    ; IR: uncompute %12
  call void @cqrt_free(i32 %44)    ; IR: release the %12 rail (|0>)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket
  call void @cqrt_and_i1(i32 %46, i32 %45, i32 %42)    ; IR: uncompute the trip predicate (the last one too: B <= K, nothing is kept)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket
  call void @cqrt_free(i32 %42)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %45, i32 %5, i32 %48)    ; IR: uncompute %5 / %15
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  %50 = add nsw i64 %40, -1
  %51 = icmp sge i64 %50, 0
  br i1 %51, label %39, label %52
52:
  call void @cqrt_free(i32 %46)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %47)    ; IR: release incoming null of phi %7 (never written, |0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  %53 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %21 = cq_measure_si32(%20)
  ret i32 %53    ; IR: ret i32 %21
}

declare ptr @malloc(i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i8(i32)
declare i32 @cqrt_qram_realloc_i8(i32, i32)
declare void @cqrt_qram_realloc_i8_unc(i32, i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_unc(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i32)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i8_hl(i32, i8)
declare void @cq_template_and_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_zext_i8_to_i64(i32)
declare void @cq_template_zext_i8_to_i64_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_trunc_i32_to_i8(i32)
declare void @cq_template_trunc_i32_to_i8_unc(i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i8(i32, i32, i32)
declare void @cq_template_select_i8_unc(i32, i32, i32, i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
