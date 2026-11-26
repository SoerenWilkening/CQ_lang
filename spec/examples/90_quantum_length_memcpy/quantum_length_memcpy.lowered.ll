; HAND-WRITTEN. Rules: 22, 20, 21, 16, 14, 5, 6, 7, 9, 4, 2.
; Checked: memcpy_quantum_len: d[0] + d[3] (the zext rail of d[3], updated in place into the sum, measured), with n = x & 3 and m = (x >> 2) & 3:
; d[0] = m > 0 ? 0 : (n > 0 ? src[0] : 9) and d[3] = 9 (no trip of either intrinsic reaches byte 3: n, m <= 3).
; memcpy_quantum_src: d[0] + d[1] (the zext rail of d[1], updated in place into the sum, measured): x & 1 == 1 copies 2 bytes from s1 (s1[0] + s1[1]),
; x & 1 == 0 copies 1 byte from s2 (s2[0] + 9).
; Clean: memcpy_quantum_len: the memcpy length chain (x & 3, its zext n; uncomputed between the copy's two loops), the
; memset length chain (x >> 2, & 3, its zext m; uncomputed after the memset loop), the load copy of d[3] (un-copied
; right after its zext), the zext of d[0] and its load copy (uncomputed, then un-copied, after the add; no memory
; version change follows the loads).
; memcpy_quantum_src: x & 1, the flag (x & 1) == 0, the address rail s = select(flag, s2, s1) and the length rail
; n = select(flag, 1, 2) (uncomputed between the copy's two loops, after their last readers in the load loop), each
; trip's source address rail s + j (uncomputed right after its load), the load copy of d[1] (un-copied right after its
; zext), the zext of d[0] and its load copy (uncomputed, then un-copied, after the add).
; Kept: the register x of each function (rotated) and each result rail (the second zext's, measured); by rule 5: the initializer's seed
; (i32 151587081 / i16 2313) and its tape slot; for every copy trip j the predicate p_j = (n >u j), the controlled load
; copy of source byte j (the value rail of its kept store) and that store's tape slot; for every memset trip j the
; predicate p_j = (m >u j) and the tape slot of its store, and the memset's one value seed alloc_i8(0) (rule 22).
; Rotations: memcpy_quantum_len: (Ry, x, th, 1). memcpy_quantum_src: (Ry, x, th, 1).
; Driver memcpy_quantum_len(0, .5, sb), sb = {1, 2, 3, 4}: Ry acts on every qubit of x, so each bit flips with
; p = sin^2(.25) = 0.061209. m > 0 (0.118671) gives d[0] = 0 and 9; m == 0, n > 0 (0.104588) gives sb[0] + 9 = 10;
; m == 0, n == 0 (0.776741) gives 18. memcpy_quantum_src(0, .5, sb, sc), sc = {5, 6, 7, 8}: x & 1 == 1 (0.061209)
; gives sb[0] + sb[1] = 3, x & 1 == 0 (0.938791) gives sc[0] + 9 = 14.
; ONE BUS (rules 20, 21, 22). d is an alloca with a memory-intrinsic user of tainted length (and, in
; memcpy_quantum_src, a tainted source), so it is BUS-RESIDENT (rule 20 (b)): __cq_alloc(size, align) at its program
; point (one zeroed block per activation, rule 16), no alloca remains and the lifetime markers are dropped. -O1's
; punned initializer is ONE i32 / i16 store: the seed alloc_<W>(lit) and a kept qram_store_<W>_hl at d (rules 5, 7),
; never split into bytes. The reads d[0], d[3] / d[0], d[1] are qram_load_i8_hl at the classical addresses d + k: d's
; ptrtoint, or the ptrtoint of -O1's untainted getelementptr, which stays (rule 20).
; Nothing is known about src, s1, s2: each is its run-time i64 (ptrtoint once at function entry, after __cq_mem()).
; QUANTUM LENGTH (rule 22). A memcpy loads ALL its source bytes in one loop, then stores ALL of them in a second; trip j
; of both runs under ONE predicate p_j = icmp_ugt_i64_hl(n, j), computed in the load loop, pushed (p_j, then the byte
; rail) and popped by the store loop, so bytes are stored n_max - 1 down to 0. The length is the i64 of -O1's zext /
; select (rule 22 compares i64; the zext is emitted). The trip count is min(K2, B), B from range facts: x & 3 <= 3 and
; (x >> 2) & 3 <= 3 (known bits) give 3 trips (bytes 0..2), select(c, 1, 2) <= 2 gives 2 trips; K2 = 4096 does not
; bind and there is no overflow predicate (B <= K2). A trip C would not run touches no cell: every byte access of a
; quantum-length intrinsic is the _controlled form under p_j. The memset is ONE loop of controlled byte stores of its
; one i8 seed.
; QUANTUM SOURCE POINTER (rule 21). s = (x & 1) ? s1 : s2 is a pointer select under a quantum flag: select_i64_ll of
; the two run-time addresses, ONE 64-bit address rail. Byte j of the copy is read at the fresh address rail
; add_i64_hl(s, j) (j = 0 included, rule 22) by ONE qram_load_i8_controlled: which of s1, s2 is read is the QRAM query
; alone; no object table, no per-origin load, no bound. s2[1] is not loaded on the s2 branch because p_1 = 0 there.
; SPEC GAP (rule 22, memset with a quantum length): the rule places p_j "in the load loop" and uncomputes the length
; "between the two loops"; a memset has one loop. Chosen: p_j is computed in the memset's store loop, kept as that
; store's control (rule 5), and the length chain is uncomputed right after the loop.
; THE FINAL ADD (rule 6, in-place update; owner ruling 2026-11-26: it applies though the operand is rule-5 garbage).
; Both operands are zexts of load copies, both garbage and dead after the add, so operand 0 of the IR add (the zext of
; d[3] / d[1]) is updated: ONE core gate add_i32(zext d[0], that rail), which is the sum from there on and is measured.
; That zext's _unc is never called; its load copy is un-copied right after the zext, its last reader.
source_filename = "quantum_length_memcpy.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memcpy_quantum_len(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %5 = ptrtoint ptr %2 to i64    ; IR: %2 as its run-time address (classical; once at function entry, rule 20)
  %6 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %4 = alloca i32, align 4: d is bus-resident (rule 20), one zeroed block (rule 16)
  %7 = ptrtoint ptr %6 to i64    ; IR: %4 as its run-time address (classical)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 151587081)    ; IR: store i32 151587081, ptr %4  [the stored value as a seed rail, kept with its store: rule 7; llvm.lifetime.start dropped]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %7, i32 %9)    ; IR: store i32 151587081, ptr %4: d = {9, 9, 9, 9}  [kept store at a classical address]
  %10 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %6 = and i32 %5, 3
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)    ; IR: %7 = zext nneg i32 %6 to i64  [the memcpy length n <= 3 (rule 22, quantum length)]
  br label %12    ; IR: llvm.memcpy(%4, %2, %7): the copy's load loop, min(K2, B) = B = 3 trips (range facts)

12:
  %13 = phi i64 [ 0, %3 ], [ %17, %12 ]    ; IR: llvm.memcpy: byte index j (classical)
  %14 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %11, i64 %13)    ; IR: llvm.memcpy: p_j = (n > j), the predicate of byte j
  %15 = add i64 %5, %13    ; IR: llvm.memcpy: the source address src + j (classical)
  %16 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %14, i32 %4, i64 %15)    ; IR: llvm.memcpy: byte j of src under p_j
  call void @cqrt_push(i32 %14)    ; IR: llvm.memcpy: p_j to the store loop (rule 22's hand-over)
  call void @cqrt_push(i32 %16)    ; IR: llvm.memcpy: the byte rail to the store loop
  %17 = add nuw nsw i64 %13, 1
  %18 = icmp eq i64 %17, 3    ; IR: llvm.memcpy: trip bound B = 3 (x & 3 <= 3)
  br i1 %18, label %19, label %12

19:
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)    ; IR: uncompute %7 (after the last p_j)
  call void @cqrt_free(i32 %11)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %8, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %10)    ; IR: release the %6 rail (|0>)
  br label %20    ; IR: llvm.memcpy: the copy's store loop

20:
  %21 = phi i64 [ 2, %19 ], [ %25, %20 ]    ; IR: llvm.memcpy: byte index, 2 down to 0 (the pop order)
  %22 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: the rail of byte i
  %23 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: p_i
  %24 = add i64 %7, %21    ; IR: llvm.memcpy: the destination address d + i (classical)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %23, i32 %4, i64 %24, i32 %22)    ; IR: llvm.memcpy: d[i] = src[i] under p_i  [kept store: slot, byte rail and p_i stay]
  %25 = add nsw i64 %21, -1
  %26 = icmp eq i64 %21, 0
  br i1 %26, label %27, label %20

27:
  %28 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 2)    ; IR: %8 = lshr i32 %5, 2
  %29 = call i32 @cq_template_and_i32_hl(i32 %28, i32 3)    ; IR: %9 = and i32 %8, 3
  %30 = call i32 @cq_template_zext_i32_to_i64(i32 %29)    ; IR: %10 = zext nneg i32 %9 to i64  [the memset length m <= 3 (rule 22, quantum length)]
  %31 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: llvm.memset(%4, 0, %10): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %32    ; IR: llvm.memset: ONE loop of byte stores, min(K2, B) = B = 3 trips (range facts)

32:
  %33 = phi i64 [ 0, %27 ], [ %36, %32 ]    ; IR: llvm.memset: byte index j (classical)
  %34 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %30, i64 %33)    ; IR: llvm.memset: p_j = (m > j), the predicate of byte j
  %35 = add i64 %7, %33    ; IR: llvm.memset: the destination address d + j (classical)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %34, i32 %4, i64 %35, i32 %31)    ; IR: llvm.memset: d[j] = 0 under p_j  [kept store: slot, seed and p_j stay]
  %36 = add nuw nsw i64 %33, 1
  %37 = icmp eq i64 %36, 3    ; IR: llvm.memset: trip bound B = 3 ((x >> 2) & 3 <= 3)
  br i1 %37, label %38, label %32

38:
  call void @cq_template_zext_i32_to_i64_unc(i32 %30, i32 %29)    ; IR: uncompute %10 (after the last p_j)
  call void @cqrt_free(i32 %30)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %29, i32 %28, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %29)    ; IR: release the %9 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %28, i32 %8, i32 2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %28)    ; IR: release the %8 rail (|0>)
  %39 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %7)    ; IR: %11 = load i8, ptr %4: d[0]  [load copy at a classical address]
  %40 = call i32 @cq_template_zext_i8_to_i32(i32 %39)    ; IR: %12 = zext i8 %11 to i32
  %41 = getelementptr inbounds i8, ptr %6, i64 3    ; IR: %13 = getelementptr inbounds i8, ptr %4, i64 3  (classical: nothing tainted, the getelementptr stays, rule 20)
  %42 = ptrtoint ptr %41 to i64    ; IR: %13 as its run-time address (classical)
  %43 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %42)    ; IR: %14 = load i8, ptr %13: d[3]  [load copy at a classical address]
  %44 = call i32 @cq_template_zext_i8_to_i32(i32 %43)    ; IR: %15 = zext i8 %14 to i32
  call void @cqrt_qram_load_i8_hl_unc(i32 %43, i32 %4, i64 %42)    ; IR: un-copy %14 (its last reader, the zext %15, is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %43)    ; IR: release the %14 rail (|0>)
  call void @cqrt_add_i32(i32 %40, i32 %44)    ; IR: %16 = add nuw nsw i32 %15, %12  [rule 6, in-place update (owner ruling 2026-11-26: it applies to the zext, rule-5 garbage): %15 is dead after the add, so the result IS the %15 rail: %15 += %12]
  call void @cq_template_zext_i8_to_i32_unc(i32 %40, i32 %39)    ; IR: uncompute %12
  call void @cqrt_free(i32 %40)    ; IR: release the %12 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %39, i32 %4, i64 %7)    ; IR: un-copy %11
  call void @cqrt_free(i32 %39)    ; IR: release the %11 rail (|0>)
  %45 = call i32 @cqrt_measure_i32(i32 %44)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %45    ; IR: ret i32 %17  (llvm.lifetime.end dropped)
}

define i32 @memcpy_quantum_src(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %6 = ptrtoint ptr %2 to i64    ; IR: %2 (s1) as its run-time address (classical; once at function entry, rule 20)
  %7 = ptrtoint ptr %3 to i64    ; IR: %3 (s2) as its run-time address (classical)
  %8 = call ptr @__cq_alloc(i64 2, i64 2)    ; IR: %5 = alloca i16, align 2: d is bus-resident (rule 20), one zeroed block (rule 16)
  %9 = ptrtoint ptr %8 to i64    ; IR: %5 as its run-time address (classical)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i16(i16 2313)    ; IR: store i16 2313, ptr %5  [the stored value as a seed rail, kept with its store: rule 7; llvm.lifetime.start dropped]
  call void @cqrt_qram_store_i16_hl(i32 %5, i64 %9, i32 %11)    ; IR: store i16 2313, ptr %5: d = {9, 9}  [kept store at a classical address]
  %12 = call i32 @cq_template_and_i32_hl(i32 %10, i32 1)    ; IR: %7 = and i32 %6, 1
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %14 = call i32 @cq_template_select_i64_ll(i32 %13, i64 %7, i64 %6)    ; IR: %9 = select i1 %8, ptr %3, ptr %2  [rule 21: the address rail s = flag ? s2 : s1]
  %15 = call i32 @cq_template_select_i64_ll(i32 %13, i64 1, i64 2)    ; IR: %10 = select i1 %8, i64 1, i64 2  [the copy length n <= 2 (rule 22, quantum length)]
  br label %16    ; IR: llvm.memcpy(%5, %9, %10): the copy's load loop, min(K2, B) = B = 2 trips (range facts)

16:
  %17 = phi i64 [ 0, %4 ], [ %21, %16 ]    ; IR: llvm.memcpy: byte index j (classical)
  %18 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %15, i64 %17)    ; IR: llvm.memcpy: p_j = (n > j), the predicate of byte j
  %19 = call i32 @cq_template_add_i64_hl(i32 %14, i64 %17)    ; IR: llvm.memcpy: the source address rail s + j (rule 22)
  %20 = call i32 @cqrt_qram_load_i8_controlled(i32 %18, i32 %5, i32 %19)    ; IR: llvm.memcpy: byte j of s at the address rail, under p_j
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %14, i64 %17)    ; IR: uncompute s + j (the address rail, after its load; the load copy is kept)
  call void @cqrt_free(i32 %19)    ; IR: release the s + j rail (|0>)
  call void @cqrt_push(i32 %18)    ; IR: llvm.memcpy: p_j to the store loop (rule 22's hand-over)
  call void @cqrt_push(i32 %20)    ; IR: llvm.memcpy: the byte rail to the store loop
  %21 = add nuw nsw i64 %17, 1
  %22 = icmp eq i64 %21, 2    ; IR: llvm.memcpy: trip bound B = 2 (select of 1, 2)
  br i1 %22, label %23, label %16

23:
  call void @cq_template_select_i64_ll_unc(i32 %15, i32 %13, i64 1, i64 2)    ; IR: uncompute %10 (after the last p_j)
  call void @cqrt_free(i32 %15)    ; IR: release the %10 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %14, i32 %13, i64 %7, i64 %6)    ; IR: uncompute %9 (the address rail s, after its last reader, the _unc of s + 1)
  call void @cqrt_free(i32 %14)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %13)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %10, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %12)    ; IR: release the %7 rail (|0>)
  br label %24    ; IR: llvm.memcpy: the copy's store loop

24:
  %25 = phi i64 [ 1, %23 ], [ %29, %24 ]    ; IR: llvm.memcpy: byte index, 1 down to 0 (the pop order)
  %26 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: the rail of byte i
  %27 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: p_i
  %28 = add i64 %9, %25    ; IR: llvm.memcpy: the destination address d + i (classical)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %27, i32 %5, i64 %28, i32 %26)    ; IR: llvm.memcpy: d[i] = s[i] under p_i  [kept store: slot, byte rail and p_i stay]
  %29 = add nsw i64 %25, -1
  %30 = icmp eq i64 %25, 0
  br i1 %30, label %31, label %24

31:
  %32 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %9)    ; IR: %11 = load i8, ptr %5: d[0]  [load copy at a classical address]
  %33 = call i32 @cq_template_zext_i8_to_i32(i32 %32)    ; IR: %12 = zext i8 %11 to i32
  %34 = getelementptr inbounds i8, ptr %8, i64 1    ; IR: %13 = getelementptr inbounds i8, ptr %5, i64 1  (classical: nothing tainted, the getelementptr stays, rule 20)
  %35 = ptrtoint ptr %34 to i64    ; IR: %13 as its run-time address (classical)
  %36 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %35)    ; IR: %14 = load i8, ptr %13: d[1]  [load copy at a classical address]
  %37 = call i32 @cq_template_zext_i8_to_i32(i32 %36)    ; IR: %15 = zext i8 %14 to i32
  call void @cqrt_qram_load_i8_hl_unc(i32 %36, i32 %5, i64 %35)    ; IR: un-copy %14 (its last reader, the zext %15, is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %36)    ; IR: release the %14 rail (|0>)
  call void @cqrt_add_i32(i32 %33, i32 %37)    ; IR: %16 = add nuw nsw i32 %15, %12  [rule 6, in-place update (owner ruling 2026-11-26: it applies to the zext, rule-5 garbage): %15 is dead after the add, so the result IS the %15 rail: %15 += %12]
  call void @cq_template_zext_i8_to_i32_unc(i32 %33, i32 %32)    ; IR: uncompute %12
  call void @cqrt_free(i32 %33)    ; IR: release the %12 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %32, i32 %5, i64 %9)    ; IR: un-copy %11
  call void @cqrt_free(i32 %32)    ; IR: release the %11 rail (|0>)
  %38 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %38    ; IR: ret i32 %17  (llvm.lifetime.end dropped)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i16(i16)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i16_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_controlled(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare void @cqrt_add_i32(i32, i32)
