; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 16, 18, 19, 20, 21, 22, 27; §1.3, §1.4.
; Checked: memmove_overlap: a[j & 3] + 1 after the move, a = {x, x, y, 5} (the add rail, measured); the cells of a at
; exit, read from the bus at the block's address: {x, x, y, 5}. memcmp_qlen: the sign of memcmp(a, b, x & 3),
; = (x & 3) >= 2 ? sign(v - u) : 0 (the or rail, measured); the cells a = {u, v, u}, b = {u, u, v} unchanged by the
; call. escape: a[0] as re-read after the call (the load copy, measured); whatever the cells of a hold after the
; declared clone is the library's (rule 27).
; Clean: memmove_overlap: the load copy of a[j & 3] (un-copied right after the add, its only reader, before the
; measurement: no memory version change follows the load, rule 5 sentence 1). memcmp_qlen: the length rail x & 3
; and its zext to i64, the sign chain (ashr, icmp ne, its zext), the memcmp result copy (zeroed by the twin, which
; runs before any memory version change: the call is a load for rule 5, rule 18); inside the clone and the twin the
; 0 seed, the |1> seed, and every trip rail (the n == j flag, the header predicate, the two byte load copies *l and
; *r (un-copied by the reverse loop under the header predicate they were loaded with), the byte-equality flag, both
; zexts, the difference, the trip's exit value, the result select, the next-trip predicate, all three trips'
; included).
; Kept: memmove_overlap: x and y (rotated; also the value rails of the kept stores a[0] = x, a[1] = y), the seeds 5
; and 6 (the value rails of the kept stores a[2] = 5, a[3] = 6, rule 7), the tape slots of those four stores; the 12
; byte load copies of the memmove (each the value rail of its kept byte store) and the tape slots of the 12 byte
; stores (rules 5, 22); the result (measured). memcmp_qlen: x, u, v (rotated; u and v also the value rails of the six
; kept byte stores), the tape slots of those six stores, the result (measured). escape: x (rotated; the value rail of
; the kept store a[0] = x), the rail x + 1 (the value rail of the kept store a[1] = x + 1, rule 5 sentence 3), the
; two tape slots, the load copy of a[0] (measured, rule 2); what the declared clone keeps is the library's.
; Rotations: memmove_overlap: (Ry, x, tx, 1); (Ry, y, ty, 1). memcmp_qlen: (Ry, x, tx, 1); (Ry, u, tu, 1); (Ry, v, tv, 1).
; escape: (Ry, x, tx, 1).
; ONE BUS (rules 20, 21). In all three functions the local arrays receive stores of rails (and are passed to a
; callee), so each alloca is BUS-RESIDENT: __cq_alloc(size, align) at the alloca's program point, no alloca remains
; and the lifetime markers are dropped (rule 16). m = __cq_mem() once at entry (§5). Every address is the block's
; run-time address plus a classical offset, a classical i64: every access is an _hl bus access. Nothing is known at
; compile time about which object an address lies in or what its cells hold.
; memmove_overlap. The initializer is four kept i32 stores (x, y, and the seeds 5 and 6, rule 7). Rule 22, classical
; length 12: a host loop of 12 qram_load_i8_hl at the source a + j, each byte rail pushed, then a host loop of 12
; qram_store_i8_hl at the destination a + 4 + j from byte 11 down to 0 (the pop order). A copy LOADS ALL its source
; bytes before it STORES ANY, so it has no direction and is exact for the overlap (destination above source): after it
; a = {x, x, y, 5} as cells. No handle moves and no rail is freed: the byte copies and their stores are kept. The read
; a[j & 3] is a bus load at the classical address a + 4 * (j & 3), a fresh rail (rule 3); a load copy is never cleaned
; by rule 6: it is un-copied after the add, its only reader, and the add rail is measured.
; memcmp_qlen. a, b: two 3-byte bus blocks, each written by three kept i8 stores. clang -O1 keeps `call @memcmp` (no
; bcmp: the result's sign is read; not inlined), so memcmp is a LIBRARY CALL: musl's source is injected and lifted by
; rule 18 like any callee (175), never lowered as an intrinsic. musl src/string/memcmp.c:
;     for (; n && *l == *r; n--, l++, r++); return n ? *l - *r : 0;
; whose clang -O1 IR the "IR: musl %N" comments name (%4 = icmp eq i64 %2, 0; loop %5 with phis %6, %7, %8, loads %9,
; %10, %11 = icmp eq; latch %12: %13 = n - 1, %16 = icmp eq %13, 0; %17: %18, %19 zexts, %20 = sub; %22 = phi [%20,
; %17], [0, %3], [0, %12]). The value is musl's byte difference *l - *r of the first differing bytes (C fixes only its
; sign; the program reads only the sign). The clone __cq_q_memcmp_001_b3 (§1.4): a pointer is ONE scalar, here a
; classical ptr (digits 0, 0: the block addresses are classical), n a rail (digit 1); nothing about the pointees
; crosses the call. _b3: the call site's range facts bound n = zext(x & 3) by 3. In the clone *l and *r are bus loads
; at the classical addresses l + j, r + j (an affine induction with a classical start: recomputed from the trip index,
; never carried, rule 14), no bound checked (rule 21). The loop's exit reads quantum data (n, the bytes), so it is a
; rule-14 loop with quantum exit, re-rolled so the pre-header test %4 (n == 0) is trip 0 of the latch test %16 (n - j
; == 0, SCEV): trip j runs the header under H[j] = P[j] & NOT (n == j), P[0] = |1>, P[j+1] = H[j] & (*l == *r). The two
; loads are read by the exit test *l == *r of trip j, so they are _hl_controlled under H[j], the predicate of reaching
; that test (a trip C would not run touches no cell); their _unc takes the same H[j]. The cutoff uses only the bound in
; the clone's name (§1.4, rule 14): B = 3, so min(K, B) = 3 trips; B <= K, so NO predicate is kept (every one is
; uncomputed by the reverse loop). The exit phi %22 is carried as R: trip j sets R = H[j] ? (*l == *r ? 0 : *l - *r) : R
; (block %17 hoisted and merged by select, rule 9); the seed 0 is the n == 0 exit. Each trip pushes its rails, the two
; load copies included; the clone writes no memory, so the reverse loop pops them and un-copies both loads after their
; readers' _unc (rule 5 sentence 1). The clone copies R out into a fresh rail and uncomputes its body (rule 18); its
; twin recomputes (bus loads again: no memory version change lies between the call and the twin), XORs the caller's
; copy out with copy_i32 and uncomputes. The caller computes the sign from the copy, uncomputes the sign chain, calls
; the twin, frees the copy, then uncomputes the length chain.
; escape. a is a bus block of 8 bytes: a[0] = x and a[1] = x + 1 are kept i32 stores. ext_sink has no body in this
; module and is listed by a lowered library the program links (a build input, rule 27). Both actuals are classical,
; but the module stores rails into memory (a[0] = x), so a cell can be QUANTUM at the call: its inputs arrive through
; memory, and the call is a call of its DECLARED clone of the all-zero arrangement, the table clone
; __cq_q_ext_sink_00_t (§1.4): the classical pointer and the classical 2 as their C values, then K (4, the default) as
; a classical i32; default C calling convention. The call is a memory version change. Its twin _t_unc(args..., K) is
; called exactly once (rule 19), at its rule-18 position: the clone returns nothing, so right after the call. After
; the call cell 0 is re-read by a bus load (-O1 keeps the load: ext_sink may write
; it), and that load copy is measured. x + 1 is never uncomputed: it is the value rail of a kept store (rule 5).
; SPEC GAP: rule 19 places a table twin "at its rule-18 position", which rule 18 states only for a clone with results
; (after the results' last consumer). Construction followed: a clone with no results has its twin immediately after
; the call; a twin, a table twin _t_unc included, uncomputes only the clone's own non-memory rails and never undoes a
; kept store, so it is no memory version change and the load of a[0] after it sees the cells ext_sink left.
source_filename = "memmove_memcmp_escape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"


define i32 @memmove_overlap(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5)
  %7 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %6 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %8 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (classical, rule 21)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %10, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %8, i32 %9)    ; IR: llvm.lifetime.start dropped (rule 16); store i32 %7, ptr %6: a[0] = x  [kept store: its slot and its value rail x stay (rule 5)]
  %11 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %9 = getelementptr inbounds i8, ptr %6, i64 4  (nothing tainted: the gep stays)
  %12 = ptrtoint ptr %11 to i64    ; IR: %9 as its run-time address
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %12, i32 %10)    ; IR: store i32 %8, ptr %9: a[1] = y  [kept store]
  %13 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: store i32 5, ptr %10: the classical 5 as a seed (rule 7), kept with its store
  %14 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %10 = getelementptr inbounds i8, ptr %6, i64 8
  %15 = ptrtoint ptr %14 to i64    ; IR: %10 as its run-time address
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %15, i32 %13)    ; IR: store i32 5, ptr %10: a[2] = 5  [kept store]
  %16 = call i32 @cqrt_alloc_i32(i32 6)    ; IR: store i32 6, ptr %11: the classical 6 as a seed (rule 7), kept with its store
  %17 = getelementptr inbounds i8, ptr %7, i64 12    ; IR: %11 = getelementptr inbounds i8, ptr %6, i64 12
  %18 = ptrtoint ptr %17 to i64    ; IR: %11 as its run-time address
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %18, i32 %16)    ; IR: store i32 6, ptr %11: a[3] = 6  [kept store]
  br label %19    ; IR: llvm.memmove(%9, %6, 12)  [rule 22: load all 12 source bytes, then store all 12; exact for the overlap]

19:
  %20 = phi i64 [ 0, %5 ], [ %23, %19 ]    ; IR: llvm.memmove: byte index j of the load loop (classical length 12, a host loop)
  %21 = add i64 %8, %20    ; IR: llvm.memmove: the source byte's address a + j (classical)
  %22 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %21)    ; IR: llvm.memmove: source byte j  [a bus load; the copy is the value rail of byte j's store, KEPT (rules 5, 22)]
  call void @cqrt_push(i32 %22)    ; IR: llvm.memmove: the byte rail to the store loop (rule 22's hand-over)
  %23 = add nuw nsw i64 %20, 1
  %24 = icmp eq i64 %23, 12
  br i1 %24, label %25, label %19

25:
  %26 = phi i64 [ 12, %19 ], [ %27, %25 ]    ; IR: llvm.memmove: bytes left to store (classical)
  %27 = add nsw i64 %26, -1    ; IR: llvm.memmove: byte index of this store, 11 down to 0 (the pop order)
  %28 = call i32 @cqrt_pop()    ; IR: llvm.memmove: the load copy of source byte %27
  %29 = add i64 %12, %27    ; IR: llvm.memmove: the destination byte's address a + 4 + j (classical)
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %29, i32 %28)    ; IR: llvm.memmove: destination byte j  [kept store (rule 5): its slot and the byte rail stay]
  %30 = icmp eq i64 %27, 0
  br i1 %30, label %31, label %25

31:
  %32 = and i32 %4, 3    ; IR: %12 = and i32 %4, 3  (classical)
  %33 = zext nneg i32 %32 to i64    ; IR: %13 = zext nneg i32 %12 to i64
  %34 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %33    ; IR: %14 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %13  (untainted index: the gep stays)
  %35 = ptrtoint ptr %34 to i64    ; IR: %14 as its run-time address
  %36 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %35)    ; IR: %15 = load i32, ptr %14: a[j & 3]  [a bus load: a fresh rail (rule 3)]
  %37 = call i32 @cq_template_add_i32_hl(i32 %36, i32 1)    ; IR: %16 = add nsw i32 %15, 1  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %36, i32 %6, i64 %35)    ; IR: un-copy %15 (its only reader %16 is done; no memory version change since the load, rule 5 sentence 1)
  call void @cqrt_free(i32 %36)    ; IR: release the %15 rail (|0>)
  %38 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %38    ; IR: llvm.lifetime.end dropped (rule 16); ret i32 %17
}

define i32 @memcmp_qlen(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) {
  %7 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5)
  %8 = call ptr @__cq_alloc(i64 3, i64 1)    ; IR: %7 = alloca [3 x i8], align 1  [a: bus-resident, one zeroed block (rules 16, 20)]
  %9 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address
  %10 = call ptr @__cq_alloc(i64 3, i64 1)    ; IR: %8 = alloca [3 x i8], align 1  [b: likewise]
  %11 = ptrtoint ptr %10 to i64    ; IR: %8 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %12, double %1)    ; IR: %9 = cq_theta_ui32(%0, %1)  [Ry]
  %13 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: %10 = cq_theta_ui8(%2, %3)  [register u]
  call void @cqrt_ry_i8(i32 %13, double %3)    ; IR: %10 = cq_theta_ui8(%2, %3)  [Ry]
  %14 = call i32 @cqrt_alloc_i8(i8 %4)    ; IR: %11 = cq_theta_ui8(%4, %5)  [register v]
  call void @cqrt_ry_i8(i32 %14, double %5)    ; IR: %11 = cq_theta_ui8(%4, %5)  [Ry]
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %9, i32 %13)    ; IR: llvm.lifetime.start dropped; store i8 %10, ptr %7: a[0] = u  [kept store (rule 5)]
  %15 = getelementptr inbounds i8, ptr %8, i64 1    ; IR: %12 = getelementptr inbounds i8, ptr %7, i64 1
  %16 = ptrtoint ptr %15 to i64    ; IR: %12 as its run-time address
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %16, i32 %14)    ; IR: store i8 %11, ptr %12: a[1] = v  [kept store]
  %17 = getelementptr inbounds i8, ptr %8, i64 2    ; IR: %13 = getelementptr inbounds i8, ptr %7, i64 2
  %18 = ptrtoint ptr %17 to i64    ; IR: %13 as its run-time address
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %18, i32 %13)    ; IR: store i8 %10, ptr %13: a[2] = u  [kept store]
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %11, i32 %13)    ; IR: llvm.lifetime.start dropped; store i8 %10, ptr %8: b[0] = u  [kept store]
  %19 = getelementptr inbounds i8, ptr %10, i64 1    ; IR: %14 = getelementptr inbounds i8, ptr %8, i64 1
  %20 = ptrtoint ptr %19 to i64    ; IR: %14 as its run-time address
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %20, i32 %13)    ; IR: store i8 %10, ptr %14: b[1] = u  [kept store]
  %21 = getelementptr inbounds i8, ptr %10, i64 2    ; IR: %15 = getelementptr inbounds i8, ptr %8, i64 2
  %22 = ptrtoint ptr %21 to i64    ; IR: %15 as its run-time address
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %22, i32 %14)    ; IR: store i8 %11, ptr %15: b[2] = v  [kept store]
  %23 = call i32 @cq_template_and_i32_hl(i32 %12, i32 3)    ; IR: %16 = and i32 %9, 3  [range [0, 4): the clone's B = 3]
  %24 = call i32 @cq_template_zext_i32_to_i64(i32 %23)    ; IR: %17 = zext nneg i32 %16 to i64  (a size_t argument: emitted)
  %25 = call fastcc i32 @__cq_q_memcmp_001_b3(ptr %8, ptr %10, i32 %24)    ; IR: %18 = call @memcmp(%7, %8, %17): the lifted musl memcmp, two classical ptrs (digits 0) and the length rail (digit 1); n <= 3 by range facts: _b3  [the result copy]
  %26 = call i32 @cq_template_ashr_i32_hl(i32 %25, i32 31)    ; IR: %19 = ashr i32 %18, 31
  %27 = call i32 @cq_template_icmp_ne_i32_hl(i32 %25, i32 0)    ; IR: %20 = icmp ne i32 %18, 0
  %28 = call i32 @cq_template_zext_i1_to_i32(i32 %27)    ; IR: %21 = zext i1 %20 to i32
  %29 = call i32 @cq_template_or_i32(i32 %26, i32 %28)    ; IR: %22 = or i32 %19, %21  [result rail]
  call void @cq_template_zext_i1_to_i32_unc(i32 %28, i32 %27)    ; IR: uncompute %21
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %27, i32 %25, i32 0)    ; IR: uncompute %20
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %26, i32 %25, i32 31)    ; IR: uncompute %19
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call fastcc void @__cq_q_memcmp_001_b3_unc(i32 %25, ptr %8, ptr %10, i32 %24)    ; IR: twin of %18: XOR the result copy to |0> (it loads again: no memory version change since the call, rule 18)
  call void @cqrt_free(i32 %25)    ; IR: release the %18 copy (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %24, i32 %23)    ; IR: uncompute %17
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %12, i32 3)    ; IR: uncompute %16
  call void @cqrt_free(i32 %23)    ; IR: release the %16 rail (|0>)
  %30 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %23 = cq_measure_si32(%22)
  ret i32 %30    ; IR: llvm.lifetime.end dropped (rule 16); ret i32 %23
}

define i32 @escape(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5)
  %4 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %3 = alloca [2 x i32], align 4  [bus-resident: one zeroed block (rules 16, 20)]
  %5 = ptrtoint ptr %4 to i64    ; IR: %3 as its run-time address
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %6)    ; IR: llvm.lifetime.start dropped; store i32 %4, ptr %3: a[0] = x  [kept store (rule 5)]
  %7 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %5 = getelementptr inbounds i8, ptr %3, i64 4
  %8 = ptrtoint ptr %7 to i64    ; IR: %5 as its run-time address
  %9 = call i32 @cq_template_add_i32_hl(i32 %6, i32 1)    ; IR: %6 = add nsw i32 %4, 1
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)    ; IR: store i32 %6, ptr %5: a[1] = x + 1  [kept store: its slot and its value rail %6 stay (rule 5 sentence 3)]
  call void @__cq_q_ext_sink_00_t(ptr %4, i32 2, i32 4)    ; IR: call void @ext_sink(ptr %3, i32 2): the declared (table) clone of the all-zero arrangement (every actual classical, a cell QUANTUM: rule 27), the C values and K; a memory version change  [K]
  call void @__cq_q_ext_sink_00_t_unc(ptr %4, i32 2, i32 4)    ; IR: its twin, exactly once (rule 19), right after the call (no results)  [K]  ; SPEC GAP: the twin position of a void table clone (header)
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %7 = load i32, ptr %3: a[0] re-read after the call  [a bus load: whatever the cell holds; measured, so never un-copied]
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %11    ; IR: llvm.lifetime.end dropped (rule 16); ret i32 %8
}

define internal fastcc i32 @__cq_q_memcmp_001_b3(ptr %0, ptr %1, i32 %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5)
  %5 = ptrtoint ptr %0 to i64    ; IR: musl %0 (l) as its run-time address (mask digit 0: a classical ptr)
  %6 = ptrtoint ptr %1 to i64    ; IR: musl %1 (r) as its run-time address
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: musl %3: predicate of reaching the n == 0 test (%4 is trip 0 of the latch test %16 by SCEV: remaining = n - j)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22's incoming 0 from %3 / %12  [seed]
  br label %9
9:
  %10 = phi i32 [ 0, %3 ], [ %27, %9 ]    ; IR: musl %8 = n - j; l = vl + j, r = vr + j (SCEV): j is classical, bounded by B = 3 (_b3)  [B]
  %11 = phi i32 [ %7, %3 ], [ %26, %9 ]    ; IR: predicate of reaching this trip's test %4 / %16
  %12 = phi i32 [ %8, %3 ], [ %25, %9 ]    ; IR: musl %22 so far
  %13 = zext i32 %10 to i64
  %14 = call i32 @cq_template_icmp_eq_i64_hl(i32 %2, i64 %13)    ; IR: musl %4 = icmp eq i64 %2, 0 (trip 0) / %16 = icmp eq i64 %13, 0: n == j
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the header %5 in this trip
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket: the header runs when n != j
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: br i1 %4 / %16 not taken: H = P & NOT (n == j)
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket
  %16 = add i64 %5, %13    ; IR: musl %7 = vl + j: the address l + j (classical affine induction, rule 14)
  %17 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %15, i32 %4, i64 %16)    ; IR: musl %9 = load i8, ptr %7: *l  [a bus load under H, the predicate of reaching the test that reads it (rule 14)]
  %18 = add i64 %6, %13    ; IR: musl %6 = vr + j (classical)
  %19 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %15, i32 %4, i64 %18)    ; IR: musl %10 = load i8, ptr %6: *r  [under H]
  %20 = call i32 @cq_template_icmp_eq_i8(i32 %17, i32 %19)    ; IR: musl %11 = icmp eq i8 %9, %10
  %21 = call i32 @cq_template_zext_i8_to_i32(i32 %17)    ; IR: musl %18 = zext i8 %9 to i32  (block %17 hoisted, rule 9)
  %22 = call i32 @cq_template_zext_i8_to_i32(i32 %19)    ; IR: musl %19 = zext i8 %10 to i32
  %23 = call i32 @cq_template_sub_i32(i32 %21, i32 %22)    ; IR: musl %20 = sub nsw i32 %18, %19
  %24 = call i32 @cq_template_select_i32_lh(i32 %20, i32 0, i32 %23)    ; IR: musl %22 = phi [ %20, %17 ], [ 0, %12 ]: this trip's exit value, equal ? 0 : *l - *r
  %25 = call i32 @cq_template_select_i32(i32 %15, i32 %24, i32 %12)    ; IR: next %22 = H ? (this trip's exit value) : so far
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the next trip's test
  call void @cqrt_and_i1(i32 %15, i32 %20, i32 %26)    ; IR: br i1 %11 taken: P' = H & (*l == *r)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %17)    ; IR: the load copy *l (un-copied by the reverse loop: no memory version change in the clone)
  call void @cqrt_push(i32 %19)    ; IR: the load copy *r
  %27 = add nuw nsw i32 %10, 1
  %28 = icmp ult i32 %27, 3    ; IR: cutoff min(K, B) = 3 trips (B = 3: the bound _b3 in the clone's name)  [B]
  br i1 %28, label %9, label %29
29:
  %30 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22  [copied-out result, rule 18]
  call void @cqrt_copy_i32(i32 %25, i32 %30)    ; IR: %22
  br label %31
31:
  %32 = phi i32 [ 0, %29 ], [ %50, %31 ]    ; IR: reverse index (trip 2 - k)
  %33 = phi i32 [ %25, %29 ], [ %45, %31 ]    ; IR: %22 written by this trip
  %34 = phi i32 [ %26, %29 ], [ %44, %31 ]    ; IR: the next-trip predicate written by this trip
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = sub nsw i32 2, %32    ; IR: j of that trip (classical)  [B]
  %47 = zext i32 %46 to i64
  %48 = add i64 %5, %47    ; IR: the address l + j of that trip, recomputed from the trip index
  %49 = add i64 %6, %47    ; IR: the address r + j of that trip
  call void @cqrt_and_i1(i32 %42, i32 %41, i32 %34)    ; IR: uncompute the next-trip predicate (every one, the last included: B < K, nothing kept)
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %33, i32 %42, i32 %37, i32 %45)    ; IR: uncompute next %22
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %37, i32 %41, i32 0, i32 %38)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %38, i32 %40, i32 %39)    ; IR: uncompute musl %20
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %39, i32 %35)    ; IR: uncompute musl %19
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %40, i32 %36)    ; IR: uncompute musl %18
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %41, i32 %36, i32 %35)    ; IR: uncompute musl %11
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %35, i32 %42, i32 %4, i64 %49)    ; IR: un-copy musl %10 (*r) under the H it was loaded with, after its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %36, i32 %42, i32 %4, i64 %48)    ; IR: un-copy musl %9 (*l)
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_and_i1(i32 %44, i32 %43, i32 %42)    ; IR: uncompute the header predicate
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %2, i64 %47)    ; IR: uncompute musl %4 / %16
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  %50 = add nuw nsw i32 %32, 1
  %51 = icmp ult i32 %50, 3    ; IR: B  [B]
  br i1 %51, label %31, label %52
52:
  call void @cqrt_free(i32 %44)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %45)    ; IR: release the result seed (never written, |0>)
  ret i32 %30    ; IR: musl ret i32 %22: the copy
}

define internal fastcc void @__cq_q_memcmp_001_b3_unc(i32 %0, ptr %1, ptr %2, i32 %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5)
  %6 = ptrtoint ptr %1 to i64    ; IR: musl %0 (l) as its run-time address
  %7 = ptrtoint ptr %2 to i64    ; IR: musl %1 (r) as its run-time address
  %8 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: musl %3: predicate of reaching the n == 0 test (%4 is trip 0 of the latch test %16 by SCEV: remaining = n - j)
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22's incoming 0 from %3 / %12  [seed]
  br label %10
10:
  %11 = phi i32 [ 0, %4 ], [ %28, %10 ]    ; IR: musl %8 = n - j; l = vl + j, r = vr + j (SCEV): j is classical, bounded by B = 3 (_b3)  [B]
  %12 = phi i32 [ %8, %4 ], [ %27, %10 ]    ; IR: predicate of reaching this trip's test %4 / %16
  %13 = phi i32 [ %9, %4 ], [ %26, %10 ]    ; IR: musl %22 so far
  %14 = zext i32 %11 to i64
  %15 = call i32 @cq_template_icmp_eq_i64_hl(i32 %3, i64 %14)    ; IR: musl %4 = icmp eq i64 %2, 0 (trip 0) / %16 = icmp eq i64 %13, 0: n == j
  %16 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the header %5 in this trip
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: the header runs when n != j
  call void @cqrt_and_i1(i32 %12, i32 %15, i32 %16)    ; IR: br i1 %4 / %16 not taken: H = P & NOT (n == j)
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket
  %17 = add i64 %6, %14    ; IR: musl %7 = vl + j: the address l + j (classical affine induction, rule 14)
  %18 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %16, i32 %5, i64 %17)    ; IR: musl %9 = load i8, ptr %7: *l  [a bus load under H (rule 14)]
  %19 = add i64 %7, %14    ; IR: musl %6 = vr + j (classical)
  %20 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %16, i32 %5, i64 %19)    ; IR: musl %10 = load i8, ptr %6: *r  [under H]
  %21 = call i32 @cq_template_icmp_eq_i8(i32 %18, i32 %20)    ; IR: musl %11 = icmp eq i8 %9, %10
  %22 = call i32 @cq_template_zext_i8_to_i32(i32 %18)    ; IR: musl %18 = zext i8 %9 to i32  (block %17 hoisted, rule 9)
  %23 = call i32 @cq_template_zext_i8_to_i32(i32 %20)    ; IR: musl %19 = zext i8 %10 to i32
  %24 = call i32 @cq_template_sub_i32(i32 %22, i32 %23)    ; IR: musl %20 = sub nsw i32 %18, %19
  %25 = call i32 @cq_template_select_i32_lh(i32 %21, i32 0, i32 %24)    ; IR: musl %22 = phi [ %20, %17 ], [ 0, %12 ]: this trip's exit value, equal ? 0 : *l - *r
  %26 = call i32 @cq_template_select_i32(i32 %16, i32 %25, i32 %13)    ; IR: next %22 = H ? (this trip's exit value) : so far
  %27 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the next trip's test
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %27)    ; IR: br i1 %11 taken: P' = H & (*l == *r)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %18)    ; IR: the load copy *l
  call void @cqrt_push(i32 %20)    ; IR: the load copy *r
  %28 = add nuw nsw i32 %11, 1
  %29 = icmp ult i32 %28, 3    ; IR: cutoff min(K, B) = 3 trips (B = 3: the bound _b3 in the clone's name)  [B]
  br i1 %29, label %10, label %30
30:
  call void @cqrt_copy_i32(i32 %26, i32 %0)    ; IR: XOR the result out of the caller's copy (rule 18 twin)
  br label %31
31:
  %32 = phi i32 [ 0, %30 ], [ %50, %31 ]    ; IR: reverse index (trip 2 - k)
  %33 = phi i32 [ %26, %30 ], [ %45, %31 ]    ; IR: %22 written by this trip
  %34 = phi i32 [ %27, %30 ], [ %44, %31 ]    ; IR: the next-trip predicate written by this trip
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = sub nsw i32 2, %32    ; IR: j of that trip (classical)  [B]
  %47 = zext i32 %46 to i64
  %48 = add i64 %6, %47    ; IR: the address l + j of that trip, recomputed from the trip index
  %49 = add i64 %7, %47    ; IR: the address r + j of that trip
  call void @cqrt_and_i1(i32 %42, i32 %41, i32 %34)    ; IR: uncompute the next-trip predicate (every one, the last included: B < K, nothing kept)
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %33, i32 %42, i32 %37, i32 %45)    ; IR: uncompute next %22
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %37, i32 %41, i32 0, i32 %38)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %38, i32 %40, i32 %39)    ; IR: uncompute musl %20
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %39, i32 %35)    ; IR: uncompute musl %19
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %40, i32 %36)    ; IR: uncompute musl %18
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %41, i32 %36, i32 %35)    ; IR: uncompute musl %11
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %35, i32 %42, i32 %5, i64 %49)    ; IR: un-copy musl %10 (*r) under the H it was loaded with (rule 5 sentence 1)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %36, i32 %42, i32 %5, i64 %48)    ; IR: un-copy musl %9 (*l)
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_and_i1(i32 %44, i32 %43, i32 %42)    ; IR: uncompute the header predicate
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %3, i64 %47)    ; IR: uncompute musl %4 / %16
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  %50 = add nuw nsw i32 %32, 1
  %51 = icmp ult i32 %50, 3    ; IR: B  [B]
  br i1 %51, label %31, label %52
52:
  call void @cqrt_free(i32 %44)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %45)    ; IR: release the result seed (never written, |0>)
  ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare void @__cq_q_ext_sink_00_t(ptr, i32, i32)
declare void @__cq_q_ext_sink_00_t_unc(ptr, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_eq_i8(i32, i32)
declare void @cq_template_icmp_eq_i8_unc(i32, i32, i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)
declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
