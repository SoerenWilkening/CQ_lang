; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 16, 20, 21, 22.
; Checked: heap_quantum_size: r = a[1] + a[5] (measured): a[1] is v when k & 3 == 1 (the cell the address-rail store
; wrote, carried over by realloc's copy), else 0 (zeroed __cq_alloc memory), and -O1 folded a[5] to 1, so r = v + 1 or 1.
; heap_in_loop: last ? last[0] : 7 (measured): 7 when x & 3 == 0, else (unsigned char)(x + (x & 3) - 1), the cell the
; last trip that ran wrote.
; Clean: heap_quantum_size: the size chain n & 3 and its zext (no consumer but the allocation), the store's address
; chain k & 3, its zext and the address rail a + (k & 3) (uncomputed right after the store, rule 20), realloc's header
; load copy s and the length rail min(s, 6) (un-copied and uncomputed between the copy's two loops, before its first
; store, rule 5 sentence 1), the copy-out a[1] (un-copied after its reader, no memory version change follows) and the
; free predicate k > 100. heap_in_loop: the trip count x & 3, the NULL seed of last and the |1> seed (rule 7), every
; trip's exit compare, x + i and its carried pointer select (popped and uncomputed by the reverse loop), the null test,
; the controlled load copy last[0] (un-copied inside its X bracket) and its zext.
; Kept: heap_quantum_size: n and k (rotated registers); the seed v and the tape slot of a[k & 3] = v; for each of the 6
; copy trips the predicate p_j = (min(s, 6) > j), the controlled load copy of byte j (the value rail of its store) and
; that store's tape slot (rules 5, 22); the seed 1 and the tape slot of a[5] = 1 (rule 7); r (measured). heap_in_loop:
; x (rotated); per trip j = 0..2 the trip predicate a_j, the value rail trunc(x + j) and the tape slot of p[0] = ...
; (rule 5 sentence 3: control rail, value rail and slot of a kept store); the result (measured). The loop's exit is
; quantum (i == x & 3) and its cutoff is min(K, B) with B = 3, the upper bound of the trip count x & 3 from LLVM's
; range facts (rule 14); B <= K, so a_K is not kept.
; Rotations: heap_quantum_size: (Ry, n, tn, 1); (Ry, k, tk, 1). heap_in_loop: (Ry, x, th, 1).
; ONE BUS (rules 16, 20, 21). Nothing is known about a heap block at compile time: every malloc is __cq_alloc(size, 16)
; (classical host code, alignment 16: the call names none; zeroed, never reused, the size as an i64 in the 8 bytes
; before the block), every access is one bus access at the pointer's run-time i64 address, and free emits nothing.
; heap_quantum_size: malloc(n & 3) has a RAIL size, so it is allocated at K2 = 4096 bytes (the built-in default; lines
; tagged [K2]) and its header holds K2. Range facts bound the size (zext nneg of n & 3, in [0, 3]) by K2, so the
; overflow predicate n > K2 is omitted (rule 16). The size chain has no other consumer and is uncomputed right after
; the allocation. The returned address is classical. a[k & 3] = v: the gep has a tainted index, so it is rule 20's
; address arithmetic into a 64-bit address rail, add_i64_hl(zext(k & 3), a) (size 1: no scale), and the store is ONE
; cqrt_qram_store_i8 at that rail with v as the seed alloc_i8(v) (rule 7), a KEPT store (rule 5 sentence 3). The block
; is K2 bytes, so k & 3 == 3 lands in cell 3 like the others; no index is bounded or checked (rule 21).
; realloc(a, 6) is, in this order (rule 16): q = __cq_alloc(6, 16); s = the i64 bus load at a - 8 (_hl, a classical
; address; a rail all the same, rule 3; here it reads K2); the length rail umin_i64_hl(s, 6); a rule-22 quantum-length
; copy of min(s, 6) bytes from a to q, its trip bound the new size 6 (no overflow predicate: min(s, 6) <= 6), byte j
; loaded and stored under p_j = icmp_ugt_i64_hl(min(s, 6), j) by the _hl_controlled forms at a + j and q + j; the load
; loop pushes p_j and the byte rail, the store loop pops them (bytes 5 down to 0). Nothing is done for a: the old block
; stays. a[5] = 1 is a kept store of the seed 1 at q + 5; a[1] is the load copy at q + 1, un-copied after its reader
; (the add; no memory version change follows: free is nothing). free(a) under the quantum predicate k > 100 emits
; nothing (rule 16); the predicate is computed and uncomputed as any flag.
; heap_in_loop: the loop exit i == x & 3 is quantum and the trip count has the range bound B = 3, so the loop is rolled
; for min(K, B) = 3 trips (tagged [B]: independent of K for K >= 3) under the predicate chain seeded |1> (rule 14).
; malloc(1) in the body is __cq_alloc(1, 16), executed unguarded in every trip (rule 16: classical host code), so the
; block address p_j of trip j is classical. p[0] = trunc(x + i) is a bus store at that classical address under the trip
; predicate a_j (qram_store_i8_hl_controlled): a kept store, so a_j and the value rail stay (rule 5) and are not
; uncomputed. last is a value defined in the quantum-exit loop and used after it, so it is ONE 64-bit address rail
; (rules 3, 21): a carried pointer with the classical start null enters as the seed alloc_i64(0) and advances by
; select_i64_lh(a_j, p_j, last) (the classical p_j as its i64 literal). After the loop the null test is
; icmp_eq_i64_hl(last, 0) (rule 21: null is the literal 0) and last[0] is ONE bus load at the address rail, in the arm
; last != null: qram_load_i8_controlled under the flag inside its X bracket (rules 8, 9), un-copied inside the same
; bracket after the zext's uncompute (no memory version change follows). The phi with 7 is select_i32_lh. The reverse
; loop pops each trip and uncomputes its pointer select, x + i and its exit compare; no trip predicate is uncomputed.
; The carried pointer select reads the kept trip predicate a_j, so the handle of that predicate is pushed and popped
; only to NAME it in the select's _unc (rule 14, as rule 19's c_i): the trip pushes its reach predicate a_{j-1}, which
; the reverse loop's predicate phi hands to the next-lower trip; it is never uncomputed or freed, and the |1> seed
; (a_{-1}) is freed directly (rule 7). The block address p_j is a per-trip classical value the select's _unc needs and
; the trip index cannot express, so it is pushed (rule 14) as two i32 words, low word first (BACKEND_ABI §1.12), and the
; reverse loop rebuilds it.
source_filename = "heap_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"


define i32 @heap_quantum_size(i8 noundef zeroext %0, double noundef %1, i32 noundef %2, double noundef %3, i8 noundef zeroext %4) {
  %6 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %7 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %6 = cq_theta_ui8(%0, %1)  [register n]
  call void @cqrt_ry_i8(i32 %7, double %1)    ; IR: %6 = cq_theta_ui8(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_ui32(%2, %3)  [register k]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %7 = cq_theta_ui32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_and_i8_hl(i32 %7, i8 3)    ; IR: %8 = and i8 %6, 3  [the quantum size, range [0, 4)]
  %10 = call i32 @cq_template_zext_i8_to_i64(i32 %9)    ; IR: %9 = zext nneg i8 %8 to i64  [a rail size; range facts bound it by 3 <= K2: no overflow predicate]
  %11 = call ptr @__cq_alloc(i64 4096, i64 16)    ; IR: %10 = call ptr @malloc(i64 %9)  [K2] [rule 16: a rail size is allocated at K2 bytes; zeroed, never reused, K2 at a - 8]
  %12 = ptrtoint ptr %11 to i64    ; IR: %10 as its run-time address (classical)
  call void @cq_template_zext_i8_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %9 (its last consumer was the allocation)
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i8_hl_unc(i32 %9, i32 %7, i8 3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %11 = and i32 %7, 3
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)    ; IR: %12 = zext nneg i32 %11 to i64
  %15 = call i32 @cq_template_add_i64_hl(i32 %14, i64 %12)    ; IR: %13 = getelementptr inbounds i8, ptr %10, i64 %12  [address rail = a + (k & 3); size 1: no scale]
  %16 = call i32 @cqrt_alloc_i8(i8 %4)    ; IR: store i8 %4, ptr %13  [the stored value as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %6, i32 %15, i32 %16)    ; IR: store i8 %4, ptr %13  [kept store at an address rail: its slot and its value rail v stay]
  call void @cq_template_add_i64_hl_unc(i32 %15, i32 %14, i64 %12)    ; IR: uncompute %13 (the address rail, after its store)
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  %17 = call ptr @__cq_alloc(i64 6, i64 16)    ; IR: %14 = call ptr @realloc(ptr %10, i64 6)  [rule 16: the new block q, classical]
  %18 = ptrtoint ptr %17 to i64    ; IR: %14 as its run-time address (classical)
  %19 = add i64 %12, -8    ; IR: %14: the address of the old block's size header, a - 8 (classical)
  %20 = call i32 @cqrt_qram_load_i64_hl(i32 %6, i64 %19)    ; IR: %14: s = the old block's size, loaded from the bus (a rail; here K2)
  %21 = call i32 @cq_template_umin_i64_hl(i32 %20, i64 6)    ; IR: %14: the copy length min(s, 6) (a rail: rule 22, quantum length)
  br label %22    ; IR: %14: the copy's load loop, 6 trips (the new block's size)

22:
  %23 = phi i64 [ 0, %5 ], [ %27, %22 ]    ; IR: %14: byte index j (classical)
  %24 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %21, i64 %23)    ; IR: %14: p_j = (min(s, 6) > j), the predicate of byte j
  %25 = add i64 %12, %23    ; IR: %14: the source address a + j (classical)
  %26 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %24, i32 %6, i64 %25)    ; IR: %14: byte j of the old block under p_j
  call void @cqrt_push(i32 %24)    ; IR: %14: p_j to the store loop (rule 22's hand-over)
  call void @cqrt_push(i32 %26)    ; IR: %14: the byte rail to the store loop
  %27 = add nuw nsw i64 %23, 1
  %28 = icmp eq i64 %27, 6    ; IR: %14: trip bound = the new block's size (rule 16)
  br i1 %28, label %29, label %22

29:
  call void @cq_template_umin_i64_hl_unc(i32 %21, i32 %20, i64 6)    ; IR: uncompute min(s, 6) (after the last p_j)
  call void @cqrt_free(i32 %21)    ; IR: release the min(s, 6) rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %20, i32 %6, i64 %19)    ; IR: un-copy s (rule 5 sentence 1: before the next memory version change, the first copy store)
  call void @cqrt_free(i32 %20)    ; IR: release the s rail (|0>)
  br label %30    ; IR: %14: the copy's store loop

30:
  %31 = phi i64 [ 5, %29 ], [ %35, %30 ]    ; IR: %14: byte index, 5 down to 0 (the pop order)
  %32 = call i32 @cqrt_pop()    ; IR: %14: the rail of byte i
  %33 = call i32 @cqrt_pop()    ; IR: %14: p_i
  %34 = add i64 %18, %31    ; IR: %14: the destination address q + i (classical)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %33, i32 %6, i64 %34, i32 %32)    ; IR: %14: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %35 = add nsw i64 %31, -1
  %36 = icmp eq i64 %31, 0
  br i1 %36, label %37, label %30

37:
  %38 = call i32 @cqrt_alloc_i8(i8 1)    ; IR: store i8 1, ptr %15  [the stored value as a seed rail, kept with its store: rule 7]
  %39 = add i64 %18, 5    ; IR: %15 = getelementptr inbounds i8, ptr %14, i64 5  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %39, i32 %38)    ; IR: store i8 1, ptr %15: a[5] = 1  [kept store at a classical address]
  %40 = add i64 %18, 1    ; IR: %16 = getelementptr inbounds i8, ptr %14, i64 1  (classical)
  %41 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %40)    ; IR: %17 = load i8, ptr %16: a[1]  [load copy at a classical address]
  %42 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %8, i32 100)    ; IR: %18 = icmp ugt i32 %7, 100  [predicate of block %19]
  ; IR: br i1 %18 -> block %19: free(%14) emits nothing, under any predicate (rule 16)
  %43 = call i32 @cq_template_add_i8_hl(i32 %41, i8 1)    ; IR: %21 = add i8 %17, 1  (a[5] folded to 1)  [result rail]
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %42, i32 %8, i32 100)    ; IR: uncompute %18
  call void @cqrt_free(i32 %42)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %41, i32 %6, i64 %40)    ; IR: un-copy %17 (rule 5 sentence 1: after its reader, no memory version change since the load)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  %44 = call i8 @cqrt_measure_i8(i32 %43)    ; IR: %22 = cq_measure_ui8(%21)
  %45 = zext i8 %44 to i32    ; IR: %23 = zext i8 %22 to i32  (classical)
  ret i32 %45    ; IR: ret i32 %23
}

define i32 @heap_in_loop(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %4 = and i32 %3, 3  [the trip count, range [0, 3]: B = 3]
  %6 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: incoming null of phi %7: last before trip 0, a carried pointer with a classical start (seed, rule 14)
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test (always 1)
  br label %8

8:
  %9 = phi i64 [ 0, %2 ], [ %23, %8 ]    ; IR: trip index, bounded by min(K, B) = 3  [B]
  %10 = phi i32 [ %6, %2 ], [ %19, %8 ]    ; IR: %7 = phi ptr [ null, %2 ], [ %11, %9 ]: the address rail last so far
  %11 = phi i32 [ %7, %2 ], [ %14, %8 ]    ; IR: predicate of reaching this trip's test
  %12 = trunc nuw nsw i64 %9 to i32    ; IR: %10 = phi i32 (i, classical)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %12)    ; IR: %5 = icmp eq i32 %4, 0 (trip 0) / %15 = icmp eq i32 %14, %4: the loop is over when i == %4
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %9 at this trip
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: the trip runs when i != %4
  call void @cqrt_and_i1(i32 %11, i32 %13, i32 %14)    ; IR: br i1 %5 / %15 not taken: a = ap & NOT e
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket
  %15 = call ptr @__cq_alloc(i64 1, i64 16)    ; IR: %11 = call ptr @malloc(i64 1)  [rule 16: classical host code, unguarded, one block per trip]
  %16 = ptrtoint ptr %15 to i64    ; IR: %11 as its run-time address p_j (classical)
  %17 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %12)    ; IR: %12 = add i32 %10, %3
  %18 = call i32 @cq_template_trunc_i32_to_i8(i32 %17)    ; IR: %13 = trunc i32 %12 to i8
  call void @cqrt_qram_store_i8_hl_controlled(i32 %14, i32 %3, i64 %16, i32 %18)    ; IR: store i8 %13, ptr %11: p[0] = (unsigned char)(x + i) under the trip predicate  [kept store: slot, value rail %13 and predicate stay]
  %19 = call i32 @cq_template_select_i64_lh(i32 %14, i64 %16, i32 %10)    ; IR: next %7 = a ? %11 : last  [rule 21: the address rail, p_j as its i64 literal]
  %20 = trunc i64 %16 to i32    ; IR: p_j, low word (classical, for the reverse loop)
  %21 = lshr i64 %16, 32
  %22 = trunc i64 %21 to i32    ; IR: p_j, high word
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)    ; IR: the reach predicate a_{j-1}, pushed only to name it in the reverse loop's select _unc (kept: never uncomputed, rule 14)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %20)    ; IR: p_j, a per-trip classical value the select's _unc needs (rule 14), low word first (BACKEND_ABI §1.12)
  call void @cqrt_push(i32 %22)
  %23 = add nuw nsw i64 %9, 1
  %24 = icmp ult i64 %23, 3    ; IR: br i1 %15, label %6, label %9, bounded by min(K, B) = 3 trips: after trip 2, i = 3 >= x & 3 on every branch  [B]
  br i1 %24, label %8, label %25

25:
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 0)    ; IR: %8 = icmp eq ptr %7, null  [rule 21: the address compared with the literal 0]
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket: block %16 is the false edge of %8
  %27 = call i32 @cqrt_qram_load_i8_controlled(i32 %26, i32 %3, i32 %19)    ; IR: %17 = load i8, ptr %7: last[0], one bus load at the address rail under last != null (rule 9: never hoisted)
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  %28 = call i32 @cq_template_zext_i8_to_i32(i32 %27)    ; IR: %18 = zext i8 %17 to i32
  %29 = call i32 @cq_template_select_i32_lh(i32 %26, i32 7, i32 %28)    ; IR: %20 = phi i32 [ %18, %16 ], [ 7, %6 ]: null ? 7 : the load  [result rail]
  call void @cq_template_zext_i8_to_i32_unc(i32 %28, i32 %27)    ; IR: uncompute %18
  call void @cqrt_free(i32 %28)    ; IR: release the %18 rail (|0>)
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket (the un-copy inside the load's own bracket)
  call void @cqrt_qram_load_i8_controlled_unc(i32 %27, i32 %26, i32 %3, i32 %19)    ; IR: un-copy %17 (rule 5 sentence 1: no memory version change since the load)
  call void @cqrt_not_i1(i32 %26)    ; IR: bracket
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %26, i32 %19, i64 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %26)    ; IR: release the %8 rail (|0>)
  br label %30

30:
  %31 = phi i64 [ 2, %25 ], [ %45, %30 ]    ; IR: reverse of the loop: trip 2 down to 0  [B]
  %32 = phi i32 [ %19, %25 ], [ %39, %30 ]    ; IR: %7 as written by this trip
  %33 = phi i32 [ %14, %25 ], [ %38, %30 ]    ; IR: predicate of this trip (kept: named only)
  %34 = call i32 @cqrt_pop()    ; IR: p_j of this trip, high word
  %35 = call i32 @cqrt_pop()    ; IR: p_j of this trip, low word
  %36 = call i32 @cqrt_pop()    ; IR: %12 of this trip
  %37 = call i32 @cqrt_pop()    ; IR: %5 / %15 of this trip
  %38 = call i32 @cqrt_pop()    ; IR: predicate of reaching this trip's test
  %39 = call i32 @cqrt_pop()    ; IR: %7 incoming to this trip
  %40 = zext i32 %35 to i64
  %41 = zext i32 %34 to i64
  %42 = shl i64 %41, 32
  %43 = or i64 %42, %40    ; IR: p_j (classical)
  %44 = trunc i64 %31 to i32    ; IR: i of that trip (classical)
  call void @cq_template_select_i64_lh_unc(i32 %32, i32 %33, i64 %43, i32 %39)    ; IR: uncompute next %7
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %36, i32 %4, i32 %44)    ; IR: uncompute %12 (its consumer %13 is a kept store's value rail and has no _unc)
  call void @cqrt_free(i32 %36)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %37, i32 %5, i32 %44)    ; IR: uncompute %5 / %15 (the trip predicate it fed is kept)
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  %45 = add nsw i64 %31, -1
  %46 = icmp sge i64 %45, 0
  br i1 %46, label %30, label %47

47:
  call void @cqrt_free(i32 %38)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %39)    ; IR: release incoming null of phi %7 (a seed never written, |0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  %48 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %21 = cq_measure_si32(%20)
  ret i32 %48    ; IR: ret i32 %21
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_controlled(i32, i32, i32)
declare void @cqrt_qram_load_i8_controlled_unc(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i8_hl(i32, i8)
declare void @cq_template_and_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_zext_i8_to_i64(i32)
declare void @cq_template_zext_i8_to_i64_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64_hl(i32, i64)
declare void @cq_template_umin_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_trunc_i32_to_i8(i32)
declare i32 @cq_template_select_i64_lh(i32, i64, i32)
declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
