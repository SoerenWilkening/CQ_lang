; HAND-WRITTEN. Rules: 20, 22, 21, 16, 14, 5, 6, 7, 4, 2.
; Checked: histogram: h[0] | h[1] << 4 | h[2] << 8 | h[3] << 12 with h[b] = #{i < 4 : (x >> 2i) & 3 == b} (measured).
; gather_scatter: s = sum over i < 4 of t[(x >> 3i) & 7] (the carried rail, measured) and out[0] | out[1] << 8 |
; out[2] << 16 | out[3] << 24 after out[(x >> 2i) & 3] = v0 + i for i = 0..3 in order (measured); the classical result
; is their sum. The cells of the two blocks at exit (h[b], out[b] at the block's address + 4b) are not named outputs.
; Clean: histogram: per trip the shift rail, the bucket index rail, its zext, the scaled index and the address rail
; (uncomputed and freed right after the in-place form's second swap), the in-place form's swap rail (the count, updated
; in place by rule 6, |0> after the swap-in); after the loop the four
; fixed-address load copies, the three shl rails and two inner ors. gather_scatter, per trip: the table chain (shift,
; index, zext, scaled index, address rail), the load copy of t[j] (un-copied in the trip, before the scatter store),
; the old s (rule 6 in the body; trip 0's old s is the |0> seed) and its rule-6 rail t, the scatter chain (shift, index,
; zext, scaled index, address rail, uncomputed right after the store); after the loop the same pack garbage as
; histogram. Nothing is pushed and neither function has a reverse loop.
; Kept: histogram: the user register x and the pack result rail (measured); by rule 5 the 16 tape slots of the memset's
; byte stores and their one value seed (i8 0). gather_scatter: x, the final s (measured), the pack result rail
; (measured); by rule 5 the 16 memset tape slots with their seed (i8 0), and per trip the scatter store's tape slot and
; its value seed v0 + i (rule 7: a basis state, no qubit).
; Rotations: (Ry, x, th, 1) in each entry.
; ONE BUS (rule 20): h and out are indexed by a rail, so each alloca is BUS-RESIDENT: one __cq_alloc(16, 16) at the
; alloca's program point, no alloca remains, the lifetime markers are dropped (rule 16). m = __cq_mem() once at entry.
; The `= {0}` memset is rule 22's ONE host loop of 16 kept byte stores qram_store_i8_hl of one seed alloc_i8(0) at the
; classical addresses base + j (classical-valued: the cells stay HOST); it is emitted although the block is already
; zero (§0). Each getelementptr with a tainted index is 64-bit template arithmetic: -O1's zext of the index as
; zext_i32_to_i64, mul_i64_hl by the element size 4, add_i64_hl of the classical base (the block's run-time address,
; or ptrtoint (ptr @t to i64)). No index is narrowed, bounded or checked.
; histogram: h[idx]++ is load, add 1, store on the same SSA pointer with no memory version change between, so it is
; rule 5's IN-PLACE FORM at the address rail (rule 6, a memory cell): alloc_i32(0), qram_swap_i32 out, the add as rule
; 6's in-place update on that rail (addc_i32: the old count is dead after the add), qram_swap_i32 in, free. No copy of the cell, tape slot or
; old count remains, so the trip pushes nothing; the address chain is template garbage, uncomputed after the second
; swap. The four post-loop reads are bus loads at classical addresses (the block + 0, 4, 8, 12); no memory version
; change follows them, so each is un-copied after its last reader's _unc, before the measurement (rule 5 sentence 1).
; gather_scatter: t is a constant global, but its getelementptr has a TAINTED index, so it is not host-resident there
; (rule 20 (a) covers untainted indices only): t[j] is a bus load qram_load_i32 at an address rail over the HOST cells
; of @t (no QROM, nothing seeded). s is a carried accumulator, s' = t[j] + s a bijection in s that no trip predicate
; reads, so rule 6 cleans the old s in the body (as 27, 204): t = s' - t[j], copied onto the old s, uncomputed, both
; freed; the final s is measured directly, no copy-out. Its other operand, the load copy, is then un-copied after the
; clean (its last reader) and before the trip's next memory version change, the scatter store (rule 5 sentence 1). The
; scatter out[k] = v0 + i is a KEPT store at an address rail of the seed alloc_i32(v0 + i) (rules 5, 7): a later store
; to the same cell displaces the earlier value onto its own tape slot, so the cell ends with the LAST value written to
; it, as in C. -O1 measures s before reading out; s is measured at that program point.
; Basis check: x = 0x1b = 0b00_01_10_11 (buckets 3, 2, 1, 0): h = {1, 1, 1, 1}, result 0x1111. For gather_scatter with
; x = 0x1b and v0 = 10: table indices 3, 3, 0, 0 give s = 1 + 1 + 3 + 3 = 8; out[3] = 10, out[2] = 11, out[1] = 12,
; out[0] = 13, pack = 0x0a0b0c0d; result 8 + 0x0a0b0c0d.
; Rule 5 sentence 1: the consumer of the t[j] copy (%32, the carried s) is a rule-6 image with no _unc, so the copy's last
; reader is rule 6's inverse (sub_i32_unc), and the copy is un-copied right after it, before the scatter store. Rule 6
; 'Both operands dead': the copy is a bus load copy that sentence 1 un-copies, so rule 6 cleans the other operand, the old s (195).
; SPEC GAP: rule 19 / §1.3 ask for a __cq_clone_register row (the _t clone, _t_ctl and their twins) per externally
; visible function. The corpus emits a row only for an address-taken function; this module follows it and registers
; nothing for histogram and gather_scatter (neither address is taken).
source_filename = "histogram_scatter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@t = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @histogram(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %4 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %3 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %5 = ptrtoint ptr %4 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: llvm.lifetime.start(16, %3) dropped (rule 16); call @llvm.memset(%3, i8 0, 16): the byte value as ONE seed rail, kept with its stores (rules 7, 22)
  br label %8

8:
  %9 = phi i64 [ 0, %2 ], [ %11, %8 ]    ; IR: call @llvm.memset(%3, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %10 = add i64 %5, %9    ; IR: the classical address h + j
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %10, i32 %7)    ; IR: call @llvm.memset(%3, i8 0, 16): byte store j  [kept store (rule 5); classical-valued, the cell stays HOST]
  %11 = add nuw nsw i64 %9, 1
  %12 = icmp eq i64 %11, 16
  br i1 %12, label %13, label %8    ; IR: br label %20

13:
  %14 = phi i32 [ 0, %8 ], [ %22, %13 ]    ; IR: %21 = phi i32  (classical trip counter)
  %15 = shl nuw nsw i32 %14, 1    ; IR: %22 = shl nuw nsw i32 %21, 1  (classical shift amount 2i)
  %16 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 %15)    ; IR: %23 = lshr i32 %4, %22
  %17 = call i32 @cq_template_and_i32_hl(i32 %16, i32 3)    ; IR: %24 = and i32 %23, 3  [the bucket index rail]
  %18 = call i32 @cq_template_zext_i32_to_i64(i32 %17)    ; IR: %25 = zext nneg i32 %24 to i64
  %19 = call i32 @cq_template_mul_i64_hl(i32 %18, i64 4)    ; IR: %26 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %25  [the tainted index scaled by the element size (rule 20)]
  %20 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %5)    ; IR: %26 = getelementptr  [+ the classical part, the run-time base: the address rail of &h[idx]]
  %21 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %27 = load i32, ptr %26 ... store i32 %28, ptr %26: the in-place form (rule 5), a fresh |0> rail
  call void @cqrt_qram_swap_i32(i32 %3, i32 %20, i32 %21)    ; IR: %27 = load i32, ptr %26: swap out: the rail holds h[idx], the cell |0>
  call void @cqrt_addc_i32(i32 %21, i32 1)    ; IR: %28 = add nsw i32 %27, 1  [rule 6, in-place update: the old count is dead after the add, so the new count IS the swap rail]
  call void @cqrt_qram_swap_i32(i32 %3, i32 %20, i32 %21)    ; IR: store i32 %28, ptr %26: swap in: the cell holds h[idx] + 1, the rail |0>
  call void @cqrt_free(i32 %21)    ; IR: release the swap rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %20, i32 %19, i64 %5)    ; IR: uncompute %26  [the address rail follows its producer: a template result, uncomputed after the second swap (rule 5)]
  call void @cqrt_free(i32 %20)    ; IR: release the %26 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %19, i32 %18, i64 4)    ; IR: uncompute %26 (the scaled index)
  call void @cqrt_free(i32 %19)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %18, i32 %17)    ; IR: uncompute %25
  call void @cqrt_free(i32 %18)    ; IR: release the %25 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %16, i32 3)    ; IR: uncompute %24
  call void @cqrt_free(i32 %17)    ; IR: release the %24 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %16, i32 %6, i32 %15)    ; IR: uncompute %23
  call void @cqrt_free(i32 %16)    ; IR: release the %23 rail (|0>)
  %22 = add nuw nsw i32 %14, 1    ; IR: %29  (classical)
  %23 = icmp eq i32 %22, 4    ; IR: %30 = icmp eq i32 %29, 4  (classical)
  br i1 %23, label %24, label %13    ; IR: br i1 %30, label %5, label %20

24:
  %25 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %6 = load i32, ptr %3  [h[0]: a bus load at a classical address, a rail (rule 3)]
  %26 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %7 = getelementptr inbounds i8, ptr %3, i64 4  (nothing tainted: the getelementptr stays, rule 20)
  %27 = ptrtoint ptr %26 to i64    ; the run-time address of h[1], a classical i64 (rule 21)
  %28 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %27)    ; IR: %8 = load i32, ptr %7  [h[1]]
  %29 = call i32 @cq_template_shl_i32_hl(i32 %28, i32 4)    ; IR: %9 = shl i32 %8, 4
  %30 = call i32 @cq_template_or_i32(i32 %29, i32 %25)    ; IR: %10 = or i32 %9, %6
  %31 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %11 = getelementptr inbounds i8, ptr %3, i64 8
  %32 = ptrtoint ptr %31 to i64    ; the run-time address of h[2]
  %33 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %32)    ; IR: %12 = load i32, ptr %11  [h[2]]
  %34 = call i32 @cq_template_shl_i32_hl(i32 %33, i32 8)    ; IR: %13 = shl i32 %12, 8
  %35 = call i32 @cq_template_or_i32(i32 %30, i32 %34)    ; IR: %14 = or i32 %10, %13
  %36 = getelementptr inbounds i8, ptr %4, i64 12    ; IR: %15 = getelementptr inbounds i8, ptr %3, i64 12
  %37 = ptrtoint ptr %36 to i64    ; the run-time address of h[3]
  %38 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %37)    ; IR: %16 = load i32, ptr %15  [h[3]]
  %39 = call i32 @cq_template_shl_i32_hl(i32 %38, i32 12)    ; IR: %17 = shl i32 %16, 12
  %40 = call i32 @cq_template_or_i32(i32 %35, i32 %39)    ; IR: %18 = or i32 %14, %17  [result rail]
  call void @cq_template_shl_i32_hl_unc(i32 %39, i32 %38, i32 12)    ; IR: uncompute %17
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %38, i32 %3, i64 %37)    ; IR: un-copy %16 (h[3]; rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %35, i32 %30, i32 %34)    ; IR: uncompute %14
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %34, i32 %33, i32 8)    ; IR: uncompute %13
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %33, i32 %3, i64 %32)    ; IR: un-copy %12 (h[2])
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %30, i32 %29, i32 %25)    ; IR: uncompute %10
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %29, i32 %28, i32 4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %28, i32 %3, i64 %27)    ; IR: un-copy %8 (h[1])
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %25, i32 %3, i64 %5)    ; IR: un-copy %6 (h[0])
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  %41 = call i32 @cqrt_measure_i32(i32 %40)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %41    ; IR: llvm.lifetime.end(16, %3) dropped (rule 16); ret i32 %19
}

define i32 @gather_scatter(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: llvm.lifetime.start(16, %4) dropped (rule 16); call @llvm.memset(%4, i8 0, 16): the byte value as ONE seed rail, kept with its stores (rules 7, 22)
  br label %9

9:
  %10 = phi i64 [ 0, %3 ], [ %12, %9 ]    ; IR: call @llvm.memset(%4, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %11 = add i64 %6, %10    ; IR: the classical address out + j
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %11, i32 %8)    ; IR: call @llvm.memset(%4, i8 0, 16): byte store j  [kept store (rule 5); classical-valued, the cell stays HOST]
  %12 = add nuw nsw i64 %10, 1
  %13 = icmp eq i64 %12, 16
  br i1 %13, label %14, label %9

14:
  %15 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %25  [s before trip 0: trip 0's old s, cleaned by rule 6 in the body]
  br label %16    ; IR: br label %23

16:
  %17 = phi i32 [ 0, %14 ], [ %36, %16 ]    ; IR: %24 = phi i32  (classical trip counter)
  %18 = phi i32 [ %15, %14 ], [ %26, %16 ]    ; IR: %25 = phi i32 [ 0, %3 ], [ %32, %23 ]
  %19 = mul nuw nsw i32 %17, 3    ; IR: %26 = mul nuw nsw i32 %24, 3  (classical shift amount 3i)
  %20 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 %19)    ; IR: %27 = lshr i32 %5, %26
  %21 = call i32 @cq_template_and_i32_hl(i32 %20, i32 7)    ; IR: %28 = and i32 %27, 7  [the table index rail]
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %29 = zext nneg i32 %28 to i64
  %23 = call i32 @cq_template_mul_i64_hl(i32 %22, i64 4)    ; IR: %30 = getelementptr inbounds [8 x i32], ptr @t, i64 0, i64 %29  [the tainted index scaled by the element size (rule 20)]
  %24 = call i32 @cq_template_add_i64_hl(i32 %23, i64 ptrtoint (ptr @t to i64))    ; IR: %30 = getelementptr  [+ the classical base &t: the address rail of &t[j]]
  %25 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %24)    ; IR: %31 = load i32, ptr %30  [a bus load at an address rail over the HOST cells of the constant @t (no QROM)]
  %26 = call i32 @cq_template_add_i32(i32 %25, i32 %18)    ; IR: %32 = add nsw i32 %31, %25  [s after this trip: the only s rail that survives it]
  %27 = call i32 @cq_template_sub_i32(i32 %26, i32 %25)    ; IR: rule 6: t = s' - t[j] recomputes the old s (the add is a bijection in s; the other operand is the load copy, rule-5 garbage)
  call void @cqrt_copy_i32(i32 %27, i32 %18)    ; IR: rule 6: old s ^= t: |0> (trip 0: the |0> seed, unchanged)
  call void @cq_template_sub_i32_unc(i32 %27, i32 %26, i32 %25)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %27)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %18)    ; IR: rule 6: release the old s rail (|0> after the copy); it is not pushed
  call void @cqrt_qram_load_i32_unc(i32 %25, i32 %4, i32 %24)    ; IR: un-copy %31 (rule 5: before the next memory version change, the store below)  [last reader: rule 6's inverse at the sub_i32_unc above; %32 is a rule-6 image with no _unc (rule 5 sentence 1)]
  call void @cqrt_free(i32 %25)    ; IR: release the %31 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %23, i64 ptrtoint (ptr @t to i64))    ; IR: uncompute %30  [the address rail outlives its access's _unc (rule 20)]
  call void @cqrt_free(i32 %24)    ; IR: release the %30 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %23, i32 %22, i64 4)    ; IR: uncompute %30 (the scaled index)
  call void @cqrt_free(i32 %23)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)    ; IR: uncompute %29
  call void @cqrt_free(i32 %22)    ; IR: release the %29 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %20, i32 7)    ; IR: uncompute %28
  call void @cqrt_free(i32 %21)    ; IR: release the %28 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %20, i32 %7, i32 %19)    ; IR: uncompute %27
  call void @cqrt_free(i32 %20)    ; IR: release the %27 rail (|0>)
  %28 = add nsw i32 %17, %2    ; IR: %33 = add nsw i32 %24, %2  (classical)
  %29 = shl nuw nsw i32 %17, 1    ; IR: %34 = shl nuw nsw i32 %24, 1  (classical shift amount 2i)
  %30 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 %29)    ; IR: %35 = lshr i32 %5, %34
  %31 = call i32 @cq_template_and_i32_hl(i32 %30, i32 3)    ; IR: %36 = and i32 %35, 3  [the store index rail]
  %32 = call i32 @cq_template_zext_i32_to_i64(i32 %31)    ; IR: %37 = zext nneg i32 %36 to i64
  %33 = call i32 @cq_template_mul_i64_hl(i32 %32, i64 4)    ; IR: %38 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %37  [the tainted index scaled by the element size (rule 20)]
  %34 = call i32 @cq_template_add_i64_hl(i32 %33, i64 %6)    ; IR: %38 = getelementptr  [+ the classical part, the run-time base: the address rail of &out[k]]
  %35 = call i32 @cqrt_alloc_i32(i32 %28)    ; IR: store i32 %33, ptr %38  [the seed of the classical value v0 + i: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i32(i32 %4, i32 %34, i32 %35)    ; IR: store i32 %33, ptr %38, align 4  [a kept store at an address rail: the displaced cells go to its tape slot, which stays (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %34, i32 %33, i64 %6)    ; IR: uncompute %38  [the address rail follows its producer: a template result, uncomputed after the store (rule 5)]
  call void @cqrt_free(i32 %34)    ; IR: release the %38 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %33, i32 %32, i64 4)    ; IR: uncompute %38 (the scaled index)
  call void @cqrt_free(i32 %33)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %32, i32 %31)    ; IR: uncompute %37
  call void @cqrt_free(i32 %32)    ; IR: release the %37 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %31, i32 %30, i32 3)    ; IR: uncompute %36
  call void @cqrt_free(i32 %31)    ; IR: release the %36 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %30, i32 %7, i32 %29)    ; IR: uncompute %35
  call void @cqrt_free(i32 %30)    ; IR: release the %35 rail (|0>)
  %36 = add nuw nsw i32 %17, 1    ; IR: %39  (classical)
  %37 = icmp eq i32 %36, 4    ; IR: %40 = icmp eq i32 %39, 4  (classical)
  br i1 %37, label %38, label %16    ; IR: br i1 %40, label %6, label %23

38:
  %39 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %7 = cq_measure_si32(%32)  [the carried s: rule 6 left no other s rail, so no copy-out and no reverse loop]
  %40 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %8 = load i32, ptr %4  [out[0]: a bus load at a classical address, a rail (rule 3)]
  %41 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %9 = getelementptr inbounds i8, ptr %4, i64 4  (nothing tainted: the getelementptr stays, rule 20)
  %42 = ptrtoint ptr %41 to i64    ; the run-time address of out[1], a classical i64 (rule 21)
  %43 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %42)    ; IR: %10 = load i32, ptr %9  [out[1]]
  %44 = call i32 @cq_template_shl_i32_hl(i32 %43, i32 8)    ; IR: %11 = shl i32 %10, 8
  %45 = call i32 @cq_template_or_i32(i32 %44, i32 %40)    ; IR: %12 = or i32 %11, %8
  %46 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %13 = getelementptr inbounds i8, ptr %4, i64 8
  %47 = ptrtoint ptr %46 to i64    ; the run-time address of out[2]
  %48 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %47)    ; IR: %14 = load i32, ptr %13  [out[2]]
  %49 = call i32 @cq_template_shl_i32_hl(i32 %48, i32 16)    ; IR: %15 = shl i32 %14, 16
  %50 = call i32 @cq_template_or_i32(i32 %45, i32 %49)    ; IR: %16 = or i32 %12, %15
  %51 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %17 = getelementptr inbounds i8, ptr %4, i64 12
  %52 = ptrtoint ptr %51 to i64    ; the run-time address of out[3]
  %53 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %52)    ; IR: %18 = load i32, ptr %17  [out[3]]
  %54 = call i32 @cq_template_shl_i32_hl(i32 %53, i32 24)    ; IR: %19 = shl i32 %18, 24
  %55 = call i32 @cq_template_or_i32(i32 %50, i32 %54)    ; IR: %20 = or i32 %16, %19  [result rail]
  call void @cq_template_shl_i32_hl_unc(i32 %54, i32 %53, i32 24)    ; IR: uncompute %19
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %53, i32 %4, i64 %52)    ; IR: un-copy %18 (out[3]; rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %50, i32 %45, i32 %49)    ; IR: uncompute %16
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %49, i32 %48, i32 16)    ; IR: uncompute %15
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %48, i32 %4, i64 %47)    ; IR: un-copy %14 (out[2])
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %45, i32 %44, i32 %40)    ; IR: uncompute %12
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %44, i32 %43, i32 8)    ; IR: uncompute %11
  call void @cqrt_free(i32 %44)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %43, i32 %4, i64 %42)    ; IR: un-copy %10 (out[1])
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %40, i32 %4, i64 %6)    ; IR: un-copy %8 (out[0])
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  %56 = call i32 @cqrt_measure_i32(i32 %55)    ; IR: %21 = cq_measure_si32(%20)
  %57 = add nsw i32 %56, %39    ; IR: %22 = add nsw i32 %21, %7  (classical)
  ret i32 %57    ; IR: llvm.lifetime.end(16, %4) dropped (rule 16); ret i32 %22
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare void @cqrt_addc_i32(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
