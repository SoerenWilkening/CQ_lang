; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 16, 20, 21, 22, §0 (run-time circuit, K2), §1.3 (the bus), §2, §6.
; Checked: realloc_shrink: r = q[k & 1] (the load copy at an address rail into the new block, measured): v iff
; k & 3 < 2 (byte k & 3 of the old block was copied), else 0 (zeroed __cq_alloc memory, §6).
; realloc_qsize: r = q[k & 1] + q[1] (measured): v + 7 for k & 3 == 0, 2v for k & 3 odd, v for k & 3 == 2.
; vla_qram: a[0] (measured): y iff x % n == 0, else 0 (zeroed __cq_alloc memory, §6). guarded_global: table[i & 7]
; (measured): y if x > k, else the cell's previous value (0 on the first call); the global's cells after the call,
; read from the bus at exit at &table + 4 (i & 7): y iff x > k.
; Clean: realloc_shrink: both address chains (k & 3, its zext, the address rail p + (k & 3); k & 1, its zext, the
; address rail q + (k & 1)), the header load copy s and min(s, 2). realloc_qsize: the chain k & 1, its zext and the
; address rails p + (k & 1) and q + (k & 1); k & 3; the size chain (k & 3) + 2 and its zext n; the header load copy s
; and min(s, n); the store's chain zext(k & 3), q + (k & 3), q + (k & 3) + 1; the two load copies q[k & 1] and q[1]
; (un-copied right after the add, before the measurement). vla_qram: x % n, its zext, the scaled index and the address
; rail. guarded_global: both chains i & 7, zext, scaled index, address rail.
; Kept: realloc_shrink: k (rotated); the seed v, value rail of the kept store a[k & 3] = v, and that store's tape slot
; (rules 5, 7); for each of the 2 copy trips the predicate p_j = (min(s, 2) > j), the controlled load copy of byte j
; (the value rail of its kept store) and that store's tape slot (rules 5, 22); r (measured, rule 2).
; realloc_qsize: k (rotated); the seed v and the tape slot of a[k & 1] = v; for each of the 4096 copy trips [K2] p_j,
; the byte copy and the tape slot (rules 5, 22); the seed 7 and the tape slot of a[(k & 3) + 1] = 7 (rule 7); the
; sum r (measured). vla_qram: x (rotated); the seed y and the tape slot of a[x % n] = y; the load copy a[0]
; (measured). guarded_global: x, i (rotated); the flag x > k, the seed y and the tape slot of the controlled store
; table[i & 7] = y (rule 5 sentence 3, rule 8: a flag that controls a kept store is kept with it; the slot stays |0>
; on the x <= k branch); the load copy table[i & 7] (measured).
; Rotations: realloc_shrink, realloc_qsize: (Ry, k, tk, 1). vla_qram: (Ry, x, tx, 1). guarded_global: (Ry, x, tx, 1);
; (Ry, i, ti, 1).
; ONE BUS (rule 20, §1.3). Every function fetches m = __cq_mem() once at entry. Nothing is known about an address at
; compile time: the heap blocks, the VLA and the global are all bus memory at their host addresses, and each
; getelementptr with a tainted index is 64-bit template arithmetic (-O1's zext of the index as zext_i32_to_i64, the
; scale mul_i64_hl by the element size, none for i8, and add_i64_hl of the classical base's run-time address). Every
; store is a KEPT store (rule 5 sentence 3): no store is popped, its tape slot, its value rail (a seed) and its control
; rail stay; its address rail is uncomputed right after it. free(a) is nothing (rule 16).
; realloc_shrink: malloc(4) is __cq_alloc(4, 16) (zeroed, never reused, the size 4 as an i64 at p - 8). a[k & 3] = v
; is a kept store at the address rail p + (k & 3). realloc(a, 2) with a classical p and n is q = __cq_alloc(2, 16), s =
; the i64 bus load at p - 8 (_hl; a rail, rule 3), the length rail umin_i64_hl(s, 2) and a rule-22 quantum-length copy
; of 2 trips (the new block's size, rule 16): byte j is loaded at p + j and stored at q + j under p_j = (min(s, 2) > j)
; by the _hl_controlled forms. s and min(s, 2) are cleaned between the two loops, before the first copy store. A v
; stored in byte 2 or 3 stays in the old block, which nothing reads again: q holds 0 there (C: the shrink discards
; it). The read q[k & 1] is a load at the address rail q + (k & 1); it is measured, so it is never un-copied and its
; address chain is uncomputed right after it.
; realloc_qsize: realloc(a, (k & 3) + 2) has a RAIL size n (-O1's zext to i64 is the template zext_i32_to_i64, the
; size argument's i64). A rail size is allocated at K2 = 4096 bytes (the built-in default, lines tagged [K2]); range
; facts bound n by 5 <= K2 ((k & 3) + 2, nuw nsw), so the overflow predicate n > K2 is omitted (rule 16). Then s = the
; bus load at p - 8, the length rail umin_i64(s, n) (two rails) and the copy, whose trip bound is the new block's size
; K2 (rule 16: the block size in place of min(K2, B), no overflow predicate of its own). The length rail, s and the
; size chain n are cleaned between the two loops. a[(k & 3) + 1] = 7 is -O1's two getelementptrs, each its own add
; (rule 20: per instruction): q + zext(k & 3), then + 1; the seed 7 is kept with its store. The loads q[k & 1] (at an
; address rail, the k & 1 chain kept alive since the first store) and q[1] (_hl at q + 1) feed only the measured add:
; no memory version change follows, so both are un-copied right after the add (rule 5 sentence 1).
; vla_qram: int a[n] is an alloca of RUN-TIME length n (classical); a store through a tainted getelementptr makes it
; bus-resident (rule 20 (b)), so it is __cq_alloc(4 n, 16) at the alloca's program point with the host value n, and no
; alloca remains (the circuit is built at run time, §0). a[x % n] = y is a kept store at the address rail
; a + 4 zext(x % n) (urem_i32_hl with the classical n as the literal). a[0] is a load at the classical address a, its
; copy measured. No stackrestore is emitted by -O1 and nothing is undone at the scope's end (rule 20).
; guarded_global: static int table[8] is a mutable global, not host-resident (it is stored to): it stays the ordinary
; LLVM global at its host address and is on the bus through the overlay (rule 20): nothing is allocated, seeded or
; registered for it (no constructor, no handle cell). The store sits in an arm under the quantum flag x > k (rule 8):
; its address chain is pure and hoisted unguarded (rule 9), and the store is ONE qram_store_i32_controlled(flag, m,
; &table + 4 zext(i & 7), y): under flag = 0 nothing is touched and its tape slot stays |0> (§2). The store is kept;
; its seed y and its control rail, the flag, are kept with it (rules 5, 7, 8); its address chain is uncomputed right
; after it. The read table[i & 7] after the merge is -O1's separate %15 = and i32 %8, 7: its own chain, a bus load at
; that address rail, measured (never un-copied), the chain uncomputed after the load.
; Regenerated 2026-11-05 (flat memory): the 2026-11-02 version used per-object QRAMs (qram_alloc_i8(n),
; qram_alloc_host_i32 with a constructor and @table.qram, qram_realloc[_unc], store pops, qram_free, i32 cell indices).
source_filename = "realloc_vla_global_guarded.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@table = internal unnamed_addr global [8 x i32] zeroinitializer, align 16    ; IR: @table = internal global [8 x i32] zeroinitializer  (kept as it is: its host cells are the bus cells, rule 20)

define i32 @realloc_shrink(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call ptr @__cq_alloc(i64 4, i64 16)    ; IR: %5 = call ptr @malloc(i64 4)  [rule 16: zeroed, never reused, the size 4 at p - 8]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  %8 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %6 = and i32 %4, 3
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %7 = zext nneg i32 %6 to i64
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %7)    ; IR: %8 = getelementptr inbounds i8, ptr %5, i64 %7  [address rail p + (k & 3); no scale for i8]
  %11 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %4, i32 %10, i32 %11)    ; IR: store i8 %2, ptr %8  [kept store at an address rail: its slot and its seed v stay]
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 %7)    ; IR: uncompute %8 (the address rail, after its store)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %5, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %12 = call ptr @__cq_alloc(i64 2, i64 16)    ; IR: %9 = call ptr @realloc(ptr %5, i64 2)  [rule 16: the new block q, classical]
  %13 = ptrtoint ptr %12 to i64    ; IR: %9 as its run-time address (classical)
  %14 = add i64 %7, -8    ; IR: %9: the address of the old block's size header, p - 8
  %15 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %14)    ; IR: %9: s = the old block's size, loaded from the bus (a rail)
  %16 = call i32 @cq_template_umin_i64_hl(i32 %15, i64 2)    ; IR: %9: the copy length min(s, 2) (a rail: rule 22, quantum length)
  br label %17    ; IR: %9: the copy's load loop, 2 trips (the new block's size)

17:
  %18 = phi i64 [ 0, %3 ], [ %22, %17 ]    ; IR: %9: byte index j (classical)
  %19 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %16, i64 %18)    ; IR: %9: p_j = (min(s, 2) > j), the predicate of byte j
  %20 = add i64 %7, %18    ; IR: %9: the source address p + j
  %21 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %19, i32 %4, i64 %20)    ; IR: %9: byte j of the old block under p_j
  call void @cqrt_push(i32 %19)    ; IR: %9: p_j to the store loop
  call void @cqrt_push(i32 %21)    ; IR: %9: the byte rail to the store loop
  %22 = add nuw nsw i64 %18, 1
  %23 = icmp eq i64 %22, 2    ; IR: %9: trip bound = the new block's size (rule 16)
  br i1 %23, label %24, label %17

24:
  call void @cq_template_umin_i64_hl_unc(i32 %16, i32 %15, i64 2)    ; IR: uncompute min(s, 2) (after the last p_j)
  call void @cqrt_free(i32 %16)    ; IR: release the min(s, 2) rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %15, i32 %4, i64 %14)    ; IR: un-copy s (rule 5 sentence 1: before the next memory version change, the first copy store)
  call void @cqrt_free(i32 %15)    ; IR: release the s rail (|0>)
  br label %25    ; IR: %9: the copy's store loop

25:
  %26 = phi i64 [ 1, %24 ], [ %30, %25 ]    ; IR: %9: byte index, 1 down to 0 (the pop order)
  %27 = call i32 @cqrt_pop()    ; IR: %9: the rail of byte i
  %28 = call i32 @cqrt_pop()    ; IR: %9: p_i
  %29 = add i64 %13, %26    ; IR: %9: the destination address q + i
  call void @cqrt_qram_store_i8_hl_controlled(i32 %28, i32 %4, i64 %29, i32 %27)    ; IR: %9: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %30 = add nsw i64 %26, -1
  %31 = icmp eq i64 %26, 0
  br i1 %31, label %32, label %25

32:
  %33 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)    ; IR: %10 = and i32 %4, 1
  %34 = call i32 @cq_template_zext_i32_to_i64(i32 %33)    ; IR: %11 = zext nneg i32 %10 to i64
  %35 = call i32 @cq_template_add_i64_hl(i32 %34, i64 %13)    ; IR: %12 = getelementptr inbounds i8, ptr %9, i64 %11  [address rail q + (k & 1)]
  %36 = call i32 @cqrt_qram_load_i8(i32 %4, i32 %35)    ; IR: %13 = load i8, ptr %12  [load copy at an address rail; measured, so never un-copied]
  call void @cq_template_add_i64_hl_unc(i32 %35, i32 %34, i64 %13)    ; IR: uncompute %12 (the address rail, after its load)
  call void @cqrt_free(i32 %35)    ; IR: release the %12 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %34, i32 %33)    ; IR: uncompute %11
  call void @cqrt_free(i32 %34)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %33, i32 %5, i32 1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %33)    ; IR: release the %10 rail (|0>)
  %37 = call i8 @cqrt_measure_i8(i32 %36)    ; IR: call void @free(ptr %9) is nothing (rule 16); %14 = cq_measure_ui8(%13)
  %38 = zext i8 %37 to i32    ; IR: %15 = zext i8 %14 to i32  (classical)
  ret i32 %38    ; IR: ret i32 %15
}

define i32 @realloc_qsize(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call ptr @__cq_alloc(i64 2, i64 16)    ; IR: %5 = call ptr @malloc(i64 2)  [rule 16: zeroed, never reused, the size 2 at p - 8]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  %8 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)    ; IR: %6 = and i32 %4, 1
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %7 = zext nneg i32 %6 to i64  [also the index of %16: kept until then]
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %7)    ; IR: %8 = getelementptr inbounds i8, ptr %5, i64 %7  [address rail p + (k & 1)]
  %11 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %4, i32 %10, i32 %11)    ; IR: store i8 %2, ptr %8  [kept store at an address rail: its slot and its seed v stay]
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 %7)    ; IR: uncompute %8 (the address rail, after its store)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  %12 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %9 = and i32 %4, 3
  %13 = call i32 @cq_template_add_i32_hl(i32 %12, i32 2)    ; IR: %10 = add nuw nsw i32 %9, 2
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)    ; IR: %11 = zext nneg i32 %10 to i64  [the quantum size n; range facts: n <= 5 <= K2, so no overflow predicate]
  %15 = call ptr @__cq_alloc(i64 4096, i64 16)    ; IR: %12 = call ptr @realloc(ptr %5, i64 %11)  [K2] [rule 16: a rail size is allocated at K2 bytes; the new block q, classical]
  %16 = ptrtoint ptr %15 to i64    ; IR: %12 as its run-time address (classical)
  %17 = add i64 %7, -8    ; IR: %12: the address of the old block's size header, p - 8
  %18 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %17)    ; IR: %12: s = the old block's size, loaded from the bus (a rail)
  %19 = call i32 @cq_template_umin_i64(i32 %18, i32 %14)    ; IR: %12: the copy length min(s, n) (a rail: rule 22, quantum length)
  br label %20    ; IR: %12: the copy's load loop, K2 trips (the new block's size)

20:
  %21 = phi i64 [ 0, %3 ], [ %25, %20 ]    ; IR: %12: byte index j (classical)
  %22 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %19, i64 %21)    ; IR: %12: p_j = (min(s, n) > j), the predicate of byte j
  %23 = add i64 %7, %21    ; IR: %12: the source address p + j
  %24 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %22, i32 %4, i64 %23)    ; IR: %12: byte j of the old block under p_j
  call void @cqrt_push(i32 %22)    ; IR: %12: p_j to the store loop
  call void @cqrt_push(i32 %24)    ; IR: %12: the byte rail to the store loop
  %25 = add nuw nsw i64 %21, 1
  %26 = icmp eq i64 %25, 4096    ; IR: %12: trip bound = the new block's size K2 (rule 16)  [K2]
  br i1 %26, label %27, label %20

27:
  call void @cq_template_umin_i64_unc(i32 %19, i32 %18, i32 %14)    ; IR: uncompute min(s, n) (after the last p_j)
  call void @cqrt_free(i32 %19)    ; IR: release the min(s, n) rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %18, i32 %4, i64 %17)    ; IR: un-copy s (rule 5 sentence 1: before the next memory version change, the first copy store)
  call void @cqrt_free(i32 %18)    ; IR: release the s rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %11 (n: its last reader was umin)
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %13, i32 %12, i32 2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  br label %28    ; IR: %12: the copy's store loop

28:
  %29 = phi i64 [ 4095, %27 ], [ %33, %28 ]    ; IR: %12: byte index, K2 - 1 down to 0 (the pop order)  [K2]
  %30 = call i32 @cqrt_pop()    ; IR: %12: the rail of byte i
  %31 = call i32 @cqrt_pop()    ; IR: %12: p_i
  %32 = add i64 %16, %29    ; IR: %12: the destination address q + i
  call void @cqrt_qram_store_i8_hl_controlled(i32 %31, i32 %4, i64 %32, i32 %30)    ; IR: %12: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %33 = add nsw i64 %29, -1
  %34 = icmp eq i64 %29, 0
  br i1 %34, label %35, label %28

35:
  %36 = call i32 @cq_template_zext_i32_to_i64(i32 %12)    ; IR: %13 = zext nneg i32 %9 to i64
  %37 = call i32 @cq_template_add_i64_hl(i32 %36, i64 %16)    ; IR: %14 = getelementptr inbounds i8, ptr %12, i64 %13  [address rail q + (k & 3)]
  %38 = call i32 @cq_template_add_i64_hl(i32 %37, i64 1)    ; IR: %15 = getelementptr inbounds i8, ptr %14, i64 1  [address rail q + (k & 3) + 1]
  %39 = call i32 @cqrt_alloc_i8(i8 7)    ; IR: store i8 7, ptr %15  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %4, i32 %38, i32 %39)    ; IR: store i8 7, ptr %15  [kept store at an address rail]
  call void @cq_template_add_i64_hl_unc(i32 %38, i32 %37, i64 1)    ; IR: uncompute %15 (the address rail, after its store)
  call void @cqrt_free(i32 %38)    ; IR: release the %15 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %37, i32 %36, i64 %16)    ; IR: uncompute %14
  call void @cqrt_free(i32 %37)    ; IR: release the %14 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %36, i32 %12)    ; IR: uncompute %13
  call void @cqrt_free(i32 %36)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %5, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  %40 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %16)    ; IR: %16 = getelementptr inbounds i8, ptr %12, i64 %7  [address rail q + (k & 1)]
  %41 = call i32 @cqrt_qram_load_i8(i32 %4, i32 %40)    ; IR: %17 = load i8, ptr %16  [load copy at an address rail]
  %42 = add i64 %16, 1    ; IR: %18 = getelementptr inbounds i8, ptr %12, i64 1  (classical)
  %43 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %42)    ; IR: %19 = load i8, ptr %18  [load copy at a classical address]
  %44 = call i32 @cq_template_add_i8(i32 %43, i32 %41)    ; IR: %20 = add i8 %19, %17  [result rail r]
  call void @cqrt_qram_load_i8_hl_unc(i32 %43, i32 %4, i64 %42)    ; IR: un-copy %19 (rule 5 sentence 1: its reader is measured; no memory version change since the load)
  call void @cqrt_free(i32 %43)    ; IR: release the %19 rail (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %41, i32 %4, i32 %40)    ; IR: un-copy %17
  call void @cqrt_free(i32 %41)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %40, i32 %9, i64 %16)    ; IR: uncompute %16 (the address rail, after its load's _unc)
  call void @cqrt_free(i32 %40)    ; IR: release the %16 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %5, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %45 = call i8 @cqrt_measure_i8(i32 %44)    ; IR: call void @free(ptr %12) is nothing (rule 16); %21 = cq_measure_ui8(%20)
  %46 = zext i8 %45 to i32    ; IR: %22 = zext i8 %21 to i32  (classical)
  ret i32 %46    ; IR: ret i32 %22
}

define i32 @vla_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = zext i32 %3 to i64    ; IR: %6 = zext i32 %3 to i64  (classical)
  %8 = mul i64 %7, 4    ; IR: %7 = alloca i32, i64 %6, align 16  [the VLA's size in bytes, 4 n (classical, run time)]
  %9 = call ptr @__cq_alloc(i64 %8, i64 16)    ; IR: %7 = alloca i32, i64 %6, align 16  [bus-resident (a store through a tainted gep): one zeroed block, no alloca remains (rules 16, 20)]
  %10 = ptrtoint ptr %9 to i64    ; IR: %7 as its run-time address (classical)
  %11 = call i32 @cq_template_urem_i32_hl(i32 %6, i32 %3)    ; IR: %8 = urem i32 %5, %3
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)    ; IR: %9 = zext i32 %8 to i64
  %13 = call i32 @cq_template_mul_i64_hl(i32 %12, i64 4)    ; IR: %10 = getelementptr inbounds i32, ptr %7, i64 %9  [the index scaled by sizeof(i32)]
  %14 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %10)    ; IR: %10  [address rail a + 4 (x % n)]
  %15 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %10  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i32(i32 %5, i32 %14, i32 %15)    ; IR: store i32 %2, ptr %10  [kept store at an address rail: its slot and its seed y stay]
  call void @cq_template_add_i64_hl_unc(i32 %14, i32 %13, i64 %10)    ; IR: uncompute %10 (the address rail, after its store)
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %13, i32 %12, i64 4)    ; IR: uncompute the scaled index of %10
  call void @cqrt_free(i32 %13)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %11, i32 %6, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  %16 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %10)    ; IR: %11 = load i32, ptr %7  [load copy at a classical address; measured, so never un-copied]
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %12 = cq_measure_si32(%11)
  ret i32 %17    ; IR: ret i32 %12  (the VLA's scope ends: nothing is undone, rule 20)
}

define i32 @guarded_global(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5) {
  %7 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %8 = cq_theta_ui32(%3, %4)  [register i]
  call void @cqrt_ry_i32(i32 %9, double %4)    ; IR: %8 = cq_theta_ui32(%3, %4)  [Ry]
  %10 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp ugt i32 %7, %2  [flag; it controls a kept store: KEPT with it, rule 8]
  %11 = call i32 @cq_template_and_i32_hl(i32 %9, i32 7)    ; IR: %11 = and i32 %8, 7  [block %10, pure: hoisted unguarded]
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)    ; IR: %12 = zext nneg i32 %11 to i64  [hoisted]
  %13 = call i32 @cq_template_mul_i64_hl(i32 %12, i64 4)    ; IR: %13 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %12  [the index scaled by sizeof(i32); hoisted]
  %14 = call i32 @cq_template_add_i64_hl(i32 %13, i64 ptrtoint (ptr @table to i64))    ; IR: %13  [address rail &table + 4 (i & 7); hoisted]
  %15 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %13  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i32_controlled(i32 %10, i32 %7, i32 %14, i32 %15)    ; IR: store i32 %5, ptr %13 under %9: table[i & 7] = y iff x > k  [kept store: slot, seed y and flag stay]
  call void @cq_template_add_i64_hl_unc(i32 %14, i32 %13, i64 ptrtoint (ptr @table to i64))    ; IR: uncompute %13 (the address rail, after its store)
  call void @cqrt_free(i32 %14)    ; IR: release the %13 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %13, i32 %12, i64 4)    ; IR: uncompute the scaled index of %13
  call void @cqrt_free(i32 %13)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %9, i32 7)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  %16 = call i32 @cq_template_and_i32_hl(i32 %9, i32 7)    ; IR: %15 = and i32 %8, 7  [block %14]
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)    ; IR: %16 = zext nneg i32 %15 to i64
  %18 = call i32 @cq_template_mul_i64_hl(i32 %17, i64 4)    ; IR: %17 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %16  [the index scaled by sizeof(i32)]
  %19 = call i32 @cq_template_add_i64_hl(i32 %18, i64 ptrtoint (ptr @table to i64))    ; IR: %17  [address rail &table + 4 (i & 7)]
  %20 = call i32 @cqrt_qram_load_i32(i32 %7, i32 %19)    ; IR: %18 = load i32, ptr %17: table[i & 7]  [load copy at an address rail; measured, so never un-copied]
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %18, i64 ptrtoint (ptr @table to i64))    ; IR: uncompute %17 (the address rail, after its load)
  call void @cqrt_free(i32 %19)    ; IR: release the %17 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %18, i32 %17, i64 4)    ; IR: uncompute the scaled index of %17
  call void @cqrt_free(i32 %18)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)    ; IR: uncompute %16
  call void @cqrt_free(i32 %17)    ; IR: release the %16 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %9, i32 7)    ; IR: uncompute %15
  call void @cqrt_free(i32 %16)    ; IR: release the %15 rail (|0>)
  %21 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %21    ; IR: ret i32 %19
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8(i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64_hl(i32, i64)
declare void @cq_template_umin_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64(i32, i32)
declare void @cq_template_umin_i64_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
