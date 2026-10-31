; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 18, 20, 21, 22, 27, §0.
; Checked: memmove_overlap: a[j & 3] + 1 after the move, a = {x, x, y, 5} (measured; the loaded register is cleaned by rule 6). memcmp_qlen: the sign of
; memcmp(a, b, x & 3), = (x & 3) >= 2 ? sign(v - u) : 0 (measured). escape: a[0] as re-read after the call (measured).
; Clean: memmove_overlap: the displaced seed 6 and the seed 5 (never written, rule 7); the register cell j & 3 names (x for
; j & 3 in {0, 1}, y for 2): its old value is dead after r = cell + 1, a bijection, so rule 6 cleans it (t = r - 1 copied
; onto it, t uncomputed, both freed) under a classical branch on j & 3, since the compiler knows statically that cells
; 0..2 hold registers and cell 3 the seed 5, which rule 6 frees directly instead. memcmp_qlen: the length rail
; x & 3 and its zext to i64, the sign chain (ashr, icmp ne, its zext), the memcmp result rail (cleared by the twin);
; inside the clone and the twin the 0 seed and every trip rail (the n == j flag, the header predicate, the byte-equality flag, both
; zexts, the difference, the trip's exit value, the result select, the next-trip predicate, all three trips' included)
; and the two seeds. escape: the rail x + 1, after the twin of the declared clone has restored the cells.
; Kept: memmove_overlap: the rotated register cell j & 3 does NOT name (y, or x) and the result (measured). memcmp_qlen: x, u, v (rotated) and the result
; (measured). escape: x (rotated; measured through the handle re-read from cell 0).
; Rotations: memmove_overlap: (Ry, x, tx, 1); (Ry, y, ty, 1). memcmp_qlen: (Ry, x, tx, 1); (Ry, u, tu, 1); (Ry, v, tv, 1).
; escape: (Ry, x, tx, 1).
; memmove_overlap. a is accessed only at classical offsets (the initializer, the memmove cells, the runtime j & 3), so it
; is a SLOT ARRAY of 4 int cells = 4 handle slots (rule 20). Every cell holds a handle on some path (cells 2 and 3
; receive y and the seed of 5 from the move), so the classical 5 and 6 are seed rails (rule 7, homogeneous cells).
; Rule 22 with a CLASSICAL length (12 bytes = cells 1..3): one slot update per cell, cell j+1 takes the handle of the
; OLD cell j. The ranges overlap with the destination above the source, so the cells are moved from the highest down
; (3 <- 2, 2 <- 1, 1 <- 0): every source cell is read before it is overwritten, which is memmove's as-if-through-a-
; temporary semantics. No gate: handles move between slots. Afterwards x sits in cells 0 and 1 (one rail, two slots: a
; read never writes a rail, rule 4), and the seed 6 is held by no cell and is freed at once (basis state 6).
; memcmp_qlen. a, b: slot arrays of 3 byte cells (3 handle slots each). clang -O1 keeps `call @memcmp` (no bcmp: the
; result's sign is read; not inlined), so memcmp is a LIBRARY CALL: musl's source is injected and lifted by rule 18
; like any callee (175, 184), never lowered as an intrinsic. musl src/string/memcmp.c:
;     for (; n && *l == *r; n--, l++, r++); return n ? *l - *r : 0;
; whose clang -O1 IR the "IR: musl %N" comments name (%4 = icmp eq i64 %2, 0; loop %5 with phis %6, %7, %8, loads %9,
; %10, %11 = icmp eq; latch %12: %13 = n - 1, %16 = icmp eq %13, 0; %17: %18, %19 zexts, %20 = sub; %22 = phi [%20,
; %17], [0, %3], [0, %12]). The value is musl's byte difference *l - *r of the first differing bytes (C fixes only its
; sign; the program reads only the sign). The clone __cq_q_memcmp_00111001111_b3 (§1.4): each pointer crosses as the
; rule-21 triple (object, tag, idx), here (slot array, the classical tag of its single object, idx 0), followed by the
; compiler-added object-table entry of that object, its cell count (3; no digit). Mask, left to right: l's tag 0, idx 0,
; then one digit per pointee cell the clone accesses (cells idx + 0..2, all holding handles at the call: a = {u, v, u}
; -> 111), likewise r (0, 0, 111 for b = {u, u, v}), then n (1); the objects get none. _b3: the call site's range facts
; bound n = zext(x & 3) by 3. The CELLS hold handles, so *l, *r are slot loads (handles, no gate) at the classical
; idx + j, each checked against the object's cell count from the object table (rule 21): beyond it the load reads 0 (a
; shared |0> seed rail of the clone, freed at its end) and never touches host memory past the object (the address is
; redirected to cell 0 and the value discarded), so the body stays safe for any cutoff. The loop's exit reads quantum
; data (n, the bytes), so it is a rule-14 loop with quantum exit, re-rolled so the pre-header test %4 (n == 0) is trip 0
; of the latch test %16 (n - j == 0, SCEV): trip j runs the header under H[j] = P[j] & NOT (n == j), P[0] = |1>, P[j+1]
; = H[j] & (*l == *r). The cutoff uses only the bound in the clone's name and the clone's own range facts (§1.4, rule
; 14): B = 3, so min(K, B) = 3 trips; B <= K, so NO predicate is kept (every one is uncomputed by the mirror). The exit
; phi %22 is carried as R: trip j sets R = H[j] ? (*l == *r ? 0 : *l - *r) : R (block %17 hoisted and merged by select,
; rule 9); the seed 0 is the n == 0 exit. The clone copies R out into a fresh rail and uncomputes its body (rule 18); its
; twin recomputes, XORs the caller's copy out with copy_i32 and uncomputes. The caller computes the sign from the copy,
; uncomputes the sign chain, calls the twin, frees the copy, then uncomputes the length chain.
; escape. a is a slot array of 2 int cells: cell 0 holds the handle of x, cell 1 the rail x + 1. ext_sink has no body
; in this module, so rule 27 applies: the call is a call to the DECLARED clone __cq_q_ext_sink_0010, named from the call
; site alone: the pointer crosses as the rule-21 triple (object, tag, idx) plus the object-table cell count (2), and
; contributes its tag digit 0, idx digit 0 and ONE digit for the pointee object (1: its cells hold handles); n is
; classical (0). No _b bounds; default calling convention. The clone may overwrite cells of a with handles it minted, so
; before the call the caller copies the cells (the handle numbers, a classical copy) into the snapshot %4; the twin takes
; the same arguments plus the snapshot, uncomputes what the clone wrote and restores both cells. After the call the cell
; is re-read (-O1 keeps the load: ext_sink may write it) and the loaded handle is measured. The twin runs after that
; last cell read; only then is x + 1 (an input of the clone the twin recomputes from) uncomputed through the caller's
; own SSA value and freed. Clone and twin take the loop cutoff K (the corpus default 4) as the last forward argument.
source_filename = "memmove_memcmp_escape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"


define i32 @memmove_overlap(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = alloca [4 x i32], align 16    ; IR: %6 = alloca [4 x i32]  (a slot array: 4 handle cells)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  store i32 %7, ptr %6, align 16    ; IR: store i32 %7, ptr %6: a[0] = x  (slot store, no gate)
  %9 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %9 = gep %6, 4
  store i32 %8, ptr %9, align 4    ; IR: store i32 %8, ptr %9: a[1] = y
  %10 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: store i32 5, ptr %10: the classical 5 as a seed rail  [seed]
  %11 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %10 = gep %6, 8
  store i32 %10, ptr %11, align 8    ; IR: store i32 5, ptr %10: a[2] = 5
  %12 = call i32 @cqrt_alloc_i32(i32 6)    ; IR: store i32 6, ptr %11: the classical 6 as a seed rail  [seed]
  %13 = getelementptr inbounds i8, ptr %6, i64 12    ; IR: %11 = gep %6, 12
  store i32 %12, ptr %13, align 4    ; IR: store i32 6, ptr %11: a[3] = 6
  %14 = load i32, ptr %11, align 8    ; IR: llvm.memmove(%9, %6, 12): cell 3 <- old cell 2 (highest first: dst above src)
  store i32 %14, ptr %13, align 4    ; IR: llvm.memmove: a[3] = a[2]  (the handle moves, no gate)
  %15 = load i32, ptr %9, align 4    ; IR: llvm.memmove: cell 2 <- old cell 1
  store i32 %15, ptr %11, align 8    ; IR: llvm.memmove: a[2] = a[1]
  %16 = load i32, ptr %6, align 16    ; IR: llvm.memmove: cell 1 <- old cell 0
  store i32 %16, ptr %9, align 4    ; IR: llvm.memmove: a[1] = a[0]
  call void @cqrt_free(i32 %12)    ; IR: llvm.memmove: the seed 6 is held by no cell any more (never written: basis state 6, rule 7)
  %17 = and i32 %4, 3    ; IR: %12 = and i32 %4, 3  (classical)
  %18 = zext nneg i32 %17 to i64    ; IR: %13 = zext nneg i32 %12 to i64
  %19 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %18    ; IR: %14 = gep [4 x i32], %6, 0, %13
  %20 = load i32, ptr %19, align 4    ; IR: %15 = load i32, ptr %14: a[j & 3]  (slot load: the handle, no gate)
  %21 = call i32 @cq_template_add_i32_hl(i32 %20, i32 1)    ; IR: %16 = add nsw i32 %15, 1  [result rail]
  %22 = icmp eq i32 %17, 3    ; IR: rule 6 (classical): cell 3 holds the seed 5, cells 0..2 hold the registers x, x, y
  br i1 %22, label %25, label %23    ; IR: a seed is freed directly (rule 7); a register is cleaned

23:
  %24 = call i32 @cq_template_sub_i32_hl(i32 %21, i32 1)    ; IR: rule 6: t = r - 1 recomputes the loaded register (r = cell + 1 is a bijection in it; the cell is dead: nothing reads a after the load)
  call void @cqrt_copy_i32(i32 %24, i32 %20)    ; IR: rule 6: the old register ^= t: |0>
  call void @cq_template_sub_i32_hl_unc(i32 %24, i32 %21, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %24)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %20)    ; IR: release the old register rail (|0> after the copy; x when j & 3 in {0, 1}, y when 2)
  br label %25

25:
  call void @cqrt_free(i32 %10)    ; IR: llvm.lifetime.end(%6): release the seed 5 (never written, basis state 5): the loaded cell itself when j & 3 == 3 (rule 6: a seed is freed directly), else still held by cell 3
  %26 = call i32 @cqrt_measure_i32(i32 %21)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %26    ; IR: ret i32 %17
}

define i32 @memcmp_qlen(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) {
  %7 = alloca [3 x i32], align 4    ; IR: %7 = alloca [3 x i8]  (a: a slot array of 3 byte cells, one handle slot per cell; object 1)
  %8 = alloca [3 x i32], align 4    ; IR: %8 = alloca [3 x i8]  (b: likewise; object 2)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: %10 = cq_theta_ui8(%2, %3)  [register u]
  call void @cqrt_ry_i8(i32 %10, double %3)    ; IR: %10 = cq_theta_ui8(%2, %3)  [Ry]
  %11 = call i32 @cqrt_alloc_i8(i8 %4)    ; IR: %11 = cq_theta_ui8(%4, %5)  [register v]
  call void @cqrt_ry_i8(i32 %11, double %5)    ; IR: %11 = cq_theta_ui8(%4, %5)  [Ry]
  store i32 %10, ptr %7, align 4    ; IR: store i8 %10, ptr %7: a[0] = u  (slot store, no gate)
  %12 = getelementptr inbounds i32, ptr %7, i64 1    ; IR: %12 = gep %7, 1  (cell 1)
  store i32 %11, ptr %12, align 4    ; IR: store i8 %11, ptr %12: a[1] = v
  %13 = getelementptr inbounds i32, ptr %7, i64 2    ; IR: %13 = gep %7, 2  (cell 2)
  store i32 %10, ptr %13, align 4    ; IR: store i8 %10, ptr %13: a[2] = u
  store i32 %10, ptr %8, align 4    ; IR: store i8 %10, ptr %8: b[0] = u
  %14 = getelementptr inbounds i32, ptr %8, i64 1    ; IR: %14 = gep %8, 1
  store i32 %10, ptr %14, align 4    ; IR: store i8 %10, ptr %14: b[1] = u
  %15 = getelementptr inbounds i32, ptr %8, i64 2    ; IR: %15 = gep %8, 2
  store i32 %11, ptr %15, align 4    ; IR: store i8 %11, ptr %15: b[2] = v
  %16 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %16 = and i32 %9, 3  [range [0, 4): the clone's B = 3]
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)    ; IR: %17 = zext nneg i32 %16 to i64  (a size_t argument, not an index: emitted)
  %18 = call fastcc i32 @__cq_q_memcmp_00111001111_b3(ptr %7, i32 1, i32 0, i32 3, ptr %8, i32 2, i32 0, i32 3, i32 %17)    ; IR: %18 = call @memcmp(%7, %8, %17): the lifted musl memcmp, pointers as (object, tag, idx) + the object-table cell count 3; n <= 3 by range facts: _b3  [the result copy]
  %19 = call i32 @cq_template_ashr_i32_hl(i32 %18, i32 31)    ; IR: %19 = ashr i32 %18, 31
  %20 = call i32 @cq_template_icmp_ne_i32_hl(i32 %18, i32 0)    ; IR: %20 = icmp ne i32 %18, 0
  %21 = call i32 @cq_template_zext_i1_to_i32(i32 %20)    ; IR: %21 = zext i1 %20 to i32
  %22 = call i32 @cq_template_or_i32(i32 %19, i32 %21)    ; IR: %22 = or i32 %19, %21  [result rail]
  call void @cq_template_zext_i1_to_i32_unc(i32 %21, i32 %20)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %20, i32 %18, i32 0)    ; IR: uncompute %20
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %19, i32 %18, i32 31)    ; IR: uncompute %19
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call fastcc void @__cq_q_memcmp_00111001111_b3_unc(i32 %18, ptr %7, i32 1, i32 0, i32 3, ptr %8, i32 2, i32 0, i32 3, i32 %17)    ; IR: twin of %18: XOR the result copy to |0>
  call void @cqrt_free(i32 %18)    ; IR: release the %18 copy (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %9, i32 3)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %23 = cq_measure_si32(%22)
  ret i32 %23    ; IR: ret i32 %23
}

define i32 @escape(i32 noundef %0, double noundef %1) {
  %3 = alloca [2 x i32], align 4    ; IR: %3 = alloca [2 x i32]  (a slot array: 2 handle cells)
  %4 = alloca [2 x i32], align 4    ; IR: (the caller's snapshot of a's cells for the twin, rule 27)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  store i32 %5, ptr %3, align 4    ; IR: store i32 %4, ptr %3: a[0] = x  (slot store, no gate)
  %6 = getelementptr inbounds i8, ptr %3, i64 4    ; IR: %5 = gep %3, 4
  %7 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)    ; IR: %6 = add nsw i32 %4, 1
  store i32 %7, ptr %6, align 4    ; IR: store i32 %6, ptr %5: a[1] = x + 1  (slot store)
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %4, ptr align 4 %3, i64 8, i1 false)    ; IR: snapshot of the cells (handle numbers; classical copy)
  call void @__cq_q_ext_sink_0010(ptr %3, i32 1, i32 0, i32 2, i32 2, i32 4)    ; IR: call @ext_sink(%3, 2): the declared clone (rule 27), pointer as (object, tag, idx) + cell count
  %8 = load i32, ptr %3, align 4    ; IR: %7 = load i32, ptr %3: a[0] re-read after the call (the handle the cell now holds)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %8 = cq_measure_si32(%7)
  call void @__cq_q_ext_sink_0010_unc(ptr %3, i32 1, i32 0, i32 2, i32 2, i32 4, ptr %4)    ; IR: twin: uncompute the clone's writes, restore the cells from the snapshot
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %5, i32 1)    ; IR: uncompute %6 (after the twin, which reads it)
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  ret i32 %9    ; IR: ret i32 %8
}

define internal fastcc i32 @__cq_q_memcmp_00111001111_b3(ptr %0, i32 %1, i32 %2, i32 %3, ptr %4, i32 %5, i32 %6, i32 %7, i32 %8) {
  %10 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: musl %3: predicate of reaching the n == 0 test (%4 is trip 0 of the latch test %16 by SCEV: remaining = n - j)
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22's incoming 0 from %3 / %12  [seed]
  %12 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: the value 0 a slot load beyond the object reads (rule 21; a shared |0> seed rail, read only)
  br label %13
13:
  %14 = phi i32 [ 0, %9 ], [ %41, %13 ]    ; IR: musl %8 = n - j; l = vl + j, r = vr + j (SCEV): j is classical, bounded by B = 3 (_b3)  [B]
  %15 = phi i32 [ %10, %9 ], [ %40, %13 ]    ; IR: predicate of reaching this trip's test %4 / %16
  %16 = phi i32 [ %11, %9 ], [ %39, %13 ]    ; IR: musl %22 so far
  %17 = zext i32 %14 to i64
  %18 = call i32 @cq_template_icmp_eq_i64_hl(i32 %8, i64 %17)    ; IR: musl %4 = icmp eq i64 %2, 0 (trip 0) / %16 = icmp eq i64 %13, 0: n == j
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the header %5 in this trip
  call void @cqrt_not_i1(i32 %18)    ; IR: bracket: the header runs when n != j
  call void @cqrt_and_i1(i32 %15, i32 %18, i32 %19)    ; IR: br i1 %4 / %16 not taken: H = P & NOT (n == j)
  call void @cqrt_not_i1(i32 %18)    ; IR: bracket
  %20 = add nsw i32 %2, %14    ; IR: musl %7 = vl + j: cell idx + j of the object (classical)
  %21 = icmp ult i32 %20, %3    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %22 = select i1 %21, i32 %20, i32 0    ; IR: beyond the object no host memory is read: the load is redirected to cell 0 and discarded
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds i32, ptr %0, i64 %23
  %25 = load i32, ptr %24, align 4    ; IR: musl %9 = load i8, ptr %7: *l  (slot load: the handle, no gate)
  %26 = select i1 %21, i32 %25, i32 %12    ; IR: *l = the cell's handle, or 0 beyond the object
  %27 = add nsw i32 %6, %14    ; IR: musl %6 = vr + j (classical)
  %28 = icmp ult i32 %27, %7    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %29 = select i1 %28, i32 %27, i32 0
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds i32, ptr %4, i64 %30
  %32 = load i32, ptr %31, align 4    ; IR: musl %10 = load i8, ptr %6: *r  (slot load)
  %33 = select i1 %28, i32 %32, i32 %12    ; IR: *r = the cell's handle, or 0 beyond the object
  %34 = call i32 @cq_template_icmp_eq_i8(i32 %26, i32 %33)    ; IR: musl %11 = icmp eq i8 %9, %10
  %35 = call i32 @cq_template_zext_i8_to_i32(i32 %26)    ; IR: musl %18 = zext i8 %9 to i32  (block %17 hoisted, rule 9)
  %36 = call i32 @cq_template_zext_i8_to_i32(i32 %33)    ; IR: musl %19 = zext i8 %10 to i32
  %37 = call i32 @cq_template_sub_i32(i32 %35, i32 %36)    ; IR: musl %20 = sub nsw i32 %18, %19
  %38 = call i32 @cq_template_select_i32_lh(i32 %34, i32 0, i32 %37)    ; IR: musl %22 = phi [ %20, %17 ], [ 0, %12 ]: this trip's exit value, equal ? 0 : *l - *r
  %39 = call i32 @cq_template_select_i32(i32 %19, i32 %38, i32 %16)    ; IR: next %22 = H ? (this trip's exit value) : so far
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the next trip's test
  call void @cqrt_and_i1(i32 %19, i32 %34, i32 %40)    ; IR: br i1 %11 taken: P' = H & (*l == *r)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %38)
  %41 = add nuw nsw i32 %14, 1
  %42 = icmp ult i32 %41, 3    ; IR: cutoff min(K, B) = 3 trips (B = 3: the bound _b3 in the clone's name)  [B]
  br i1 %42, label %13, label %43
43:
  %44 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22  [copied-out result, rule 18]
  call void @cqrt_copy_i32(i32 %39, i32 %44)    ; IR: %22
  br label %45
45:
  %46 = phi i32 [ 0, %43 ], [ %74, %45 ]    ; IR: reverse index (trip 2 - k)
  %47 = phi i32 [ %39, %43 ], [ %57, %45 ]    ; IR: %22 written by this trip
  %48 = phi i32 [ %40, %43 ], [ %56, %45 ]    ; IR: the next-trip predicate written by this trip
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = sub nsw i32 2, %46    ; IR: j of that trip (classical)  [B]
  %59 = zext i32 %58 to i64
  %60 = add nsw i32 %2, %58
  %61 = icmp ult i32 %60, %3    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %62 = select i1 %61, i32 %60, i32 0
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds i32, ptr %0, i64 %63
  %65 = load i32, ptr %64, align 4    ; IR: *l of that trip again (the slot is unchanged)
  %66 = select i1 %61, i32 %65, i32 %12
  %67 = add nsw i32 %6, %58
  %68 = icmp ult i32 %67, %7
  %69 = select i1 %68, i32 %67, i32 0
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds i32, ptr %4, i64 %70
  %72 = load i32, ptr %71, align 4    ; IR: *r of that trip again
  %73 = select i1 %68, i32 %72, i32 %12
  call void @cqrt_and_i1(i32 %54, i32 %53, i32 %48)    ; IR: uncompute the next-trip predicate (every one, the last included: B < K, nothing kept)
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %47, i32 %54, i32 %49, i32 %57)    ; IR: uncompute next %22
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %49, i32 %53, i32 0, i32 %50)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %50, i32 %52, i32 %51)    ; IR: uncompute musl %20
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %51, i32 %73)    ; IR: uncompute musl %19
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %52, i32 %66)    ; IR: uncompute musl %18
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %53, i32 %66, i32 %73)    ; IR: uncompute musl %11
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %55)    ; IR: bracket
  call void @cqrt_and_i1(i32 %56, i32 %55, i32 %54)    ; IR: uncompute the header predicate
  call void @cqrt_not_i1(i32 %55)    ; IR: bracket
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %55, i32 %8, i64 %59)    ; IR: uncompute musl %4 / %16
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  %74 = add nuw nsw i32 %46, 1
  %75 = icmp ult i32 %74, 3    ; IR: B  [B]
  br i1 %75, label %45, label %76
76:
  call void @cqrt_free(i32 %56)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %57)    ; IR: release the result seed (never written, |0>)
  call void @cqrt_free(i32 %12)    ; IR: release the 0 seed (never written, |0>)
  ret i32 %44    ; IR: musl ret i32 %22: the copy
}

define internal fastcc void @__cq_q_memcmp_00111001111_b3_unc(i32 %0, ptr %1, i32 %2, i32 %3, i32 %4, ptr %5, i32 %6, i32 %7, i32 %8, i32 %9) {
  %11 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: musl %3: predicate of reaching the n == 0 test (%4 is trip 0 of the latch test %16 by SCEV: remaining = n - j)
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: musl %22's incoming 0 from %3 / %12  [seed]
  %13 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: the value 0 a slot load beyond the object reads (rule 21; a shared |0> seed rail, read only)
  br label %14
14:
  %15 = phi i32 [ 0, %10 ], [ %42, %14 ]    ; IR: musl %8 = n - j; l = vl + j, r = vr + j (SCEV): j is classical, bounded by B = 3 (_b3)  [B]
  %16 = phi i32 [ %11, %10 ], [ %41, %14 ]    ; IR: predicate of reaching this trip's test %4 / %16
  %17 = phi i32 [ %12, %10 ], [ %40, %14 ]    ; IR: musl %22 so far
  %18 = zext i32 %15 to i64
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %9, i64 %18)    ; IR: musl %4 = icmp eq i64 %2, 0 (trip 0) / %16 = icmp eq i64 %13, 0: n == j
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the header %5 in this trip
  call void @cqrt_not_i1(i32 %19)    ; IR: bracket: the header runs when n != j
  call void @cqrt_and_i1(i32 %16, i32 %19, i32 %20)    ; IR: br i1 %4 / %16 not taken: H = P & NOT (n == j)
  call void @cqrt_not_i1(i32 %19)    ; IR: bracket
  %21 = add nsw i32 %3, %15    ; IR: musl %7 = vl + j: cell idx + j of the object (classical)
  %22 = icmp ult i32 %21, %4    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %23 = select i1 %22, i32 %21, i32 0    ; IR: beyond the object no host memory is read: the load is redirected to cell 0 and discarded
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds i32, ptr %1, i64 %24
  %26 = load i32, ptr %25, align 4    ; IR: musl %9 = load i8, ptr %7: *l  (slot load: the handle, no gate)
  %27 = select i1 %22, i32 %26, i32 %13    ; IR: *l = the cell's handle, or 0 beyond the object
  %28 = add nsw i32 %7, %15    ; IR: musl %6 = vr + j (classical)
  %29 = icmp ult i32 %28, %8    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %30 = select i1 %29, i32 %28, i32 0
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i32, ptr %5, i64 %31
  %33 = load i32, ptr %32, align 4    ; IR: musl %10 = load i8, ptr %6: *r  (slot load)
  %34 = select i1 %29, i32 %33, i32 %13    ; IR: *r = the cell's handle, or 0 beyond the object
  %35 = call i32 @cq_template_icmp_eq_i8(i32 %27, i32 %34)    ; IR: musl %11 = icmp eq i8 %9, %10
  %36 = call i32 @cq_template_zext_i8_to_i32(i32 %27)    ; IR: musl %18 = zext i8 %9 to i32  (block %17 hoisted, rule 9)
  %37 = call i32 @cq_template_zext_i8_to_i32(i32 %34)    ; IR: musl %19 = zext i8 %10 to i32
  %38 = call i32 @cq_template_sub_i32(i32 %36, i32 %37)    ; IR: musl %20 = sub nsw i32 %18, %19
  %39 = call i32 @cq_template_select_i32_lh(i32 %35, i32 0, i32 %38)    ; IR: musl %22 = phi [ %20, %17 ], [ 0, %12 ]: this trip's exit value, equal ? 0 : *l - *r
  %40 = call i32 @cq_template_select_i32(i32 %20, i32 %39, i32 %17)    ; IR: next %22 = H ? (this trip's exit value) : so far
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the next trip's test
  call void @cqrt_and_i1(i32 %20, i32 %35, i32 %41)    ; IR: br i1 %11 taken: P' = H & (*l == *r)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %39)
  %42 = add nuw nsw i32 %15, 1
  %43 = icmp ult i32 %42, 3    ; IR: cutoff min(K, B) = 3 trips (B = 3: the bound _b3 in the clone's name)  [B]
  br i1 %43, label %14, label %44
44:
  call void @cqrt_copy_i32(i32 %40, i32 %0)    ; IR: XOR the result out of the caller's copy (rule 18 twin)
  br label %45
45:
  %46 = phi i32 [ 0, %44 ], [ %74, %45 ]    ; IR: reverse index (trip 2 - k)
  %47 = phi i32 [ %40, %44 ], [ %57, %45 ]    ; IR: %22 written by this trip
  %48 = phi i32 [ %41, %44 ], [ %56, %45 ]    ; IR: the next-trip predicate written by this trip
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = sub nsw i32 2, %46    ; IR: j of that trip (classical)  [B]
  %59 = zext i32 %58 to i64
  %60 = add nsw i32 %3, %58
  %61 = icmp ult i32 %60, %4    ; IR: rule 21: cell idx + j checked against the object's cell count from the object table
  %62 = select i1 %61, i32 %60, i32 0
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds i32, ptr %1, i64 %63
  %65 = load i32, ptr %64, align 4    ; IR: *l of that trip again (the slot is unchanged)
  %66 = select i1 %61, i32 %65, i32 %13
  %67 = add nsw i32 %7, %58
  %68 = icmp ult i32 %67, %8
  %69 = select i1 %68, i32 %67, i32 0
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds i32, ptr %5, i64 %70
  %72 = load i32, ptr %71, align 4    ; IR: *r of that trip again
  %73 = select i1 %68, i32 %72, i32 %13
  call void @cqrt_and_i1(i32 %54, i32 %53, i32 %48)    ; IR: uncompute the next-trip predicate (every one, the last included: B < K, nothing kept)
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %47, i32 %54, i32 %49, i32 %57)    ; IR: uncompute next %22
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %49, i32 %53, i32 0, i32 %50)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %50, i32 %52, i32 %51)    ; IR: uncompute musl %20
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %51, i32 %73)    ; IR: uncompute musl %19
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %52, i32 %66)    ; IR: uncompute musl %18
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %53, i32 %66, i32 %73)    ; IR: uncompute musl %11
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %55)    ; IR: bracket
  call void @cqrt_and_i1(i32 %56, i32 %55, i32 %54)    ; IR: uncompute the header predicate
  call void @cqrt_not_i1(i32 %55)    ; IR: bracket
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %55, i32 %9, i64 %59)    ; IR: uncompute musl %4 / %16
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  %74 = add nuw nsw i32 %46, 1
  %75 = icmp ult i32 %74, 3    ; IR: B  [B]
  br i1 %75, label %45, label %76
76:
  call void @cqrt_free(i32 %56)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %57)    ; IR: release the result seed (never written, |0>)
  call void @cqrt_free(i32 %13)    ; IR: release the 0 seed (never written, |0>)
  ret void
}

declare void @__cq_q_ext_sink_0010(ptr, i32, i32, i32, i32, i32)
declare void @__cq_q_ext_sink_0010_unc(ptr, i32, i32, i32, i32, i32, ptr)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
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
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
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
declare void @cq_template_or_i32_unc(i32, i32, i32)
