; HAND-WRITTEN. Rules: 16, 22, 21, 20, 14, 9, 5, 2, 4, 7.
; Checked: the return value r1 + r2, r1 = q[1] and r2 = q[2] after the realloc (the load copies at the classical
; addresses q + 4 and q + 8, each measured; the sum is classical, rule 2). k & 1 == 1 (p = a): the header at a - 8
; reads 8, bytes 0..7 of a are copied, so r1 = a[1] = x and r2 = 0 (bytes 8..11 of q are not written: zeroed
; __cq_alloc memory). k & 1 == 0 (p = b): the header at b - 8 reads 16, bytes 0..15 of b are copied, so r1 = b[1] = 5
; and r2 = b[2] = 7. r1 witnesses the address rail (which block is read), r2 the length predicate p_j = (j < min(s, 24))
; for j = 8..11: a copy of all 24 bytes, or of a fixed 16, would read on the p = a branch the 4 bytes at a + 8, which
; here are the low half of b's size header (b = a + 16 in the bump arena), and return x + 16.
; Clean: k & 1, the flag (k & 1) == 0 and the address rail p = select(flag, b, a) (uncomputed after p's last reader,
; the _unc of p - 8); the address rail p - 8 (after the un-copy of s, which reads it); the header load copy s and
; min(s, 24) (s is un-copied before the first copy store: its only consumer umin and that consumer's _unc precede the
; next memory version change, rule 5 sentence 1); for each of the 24 copy trips the source address rail p + j
; (uncomputed right after its load, before the next trip).
; Kept: k and x (rotated; x is also the value rail of the kept store a[1] = x); the tape slot of that store; the seeds
; 5 and 7 and the tape slots of b[1] = 5 and b[2] = 7 (rule 7); for each of the 24 copy trips the predicate
; p_j = (min(s, 24) > j), the controlled load copy of byte j (the value rail of its kept store) and that store's tape
; slot (rule 5 sentence 3, rule 22); the two load copies r1 and r2 (measured: rule 2).
; Rotations: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Driver realloc_pointer_rail(1, .5, 9, .25): Ry acts on every qubit of a register, so each bit of k flips with
; probability p = sin^2(.25) = 0.061209 and each bit of x with q = sin^2(.125) = 0.015544, independently; everything
; after the two rotations is a basis permutation. k & 1 == 1 (1 - p = 0.938791): the address rail holds a, s = 8,
; p_0..p_7 are 1 and p_8..p_23 are 0, 8 bytes are copied, r1 = x, r2 = 0 and the function returns x: 9 with
; (1 - p)(1 - q)^32 = 0.568662, each single-bit neighbour of 9 with (1 - p) q (1 - q)^31 = 0.008979. k & 1 == 0
; (p = 0.061209): the address rail holds b, s = 16, p_0..p_15 are 1, 16 bytes are copied, r1 = 5, r2 = 7 and the
; function returns 12 whatever x is (0.061350 with x = 12 on the other branch, two bit flips from 9). The other values
; of x share 0.369988.
; REALLOC OF A POINTER RAIL (rule 16). Both mallocs are __cq_alloc(size, 16) (classical host code; alignment 16: the
; call names none), each with its size as an i64 in the 8 bytes before the block. The pointer select on the quantum
; flag is select_i64_ll (rule 21: both incomings classical, entering as their run-time i64 addresses), so p is ONE
; 64-bit address rail and nothing about a or b belongs to it. realloc(p, 24) is, in this order, q = __cq_alloc(24, 16),
; CLASSICAL (the new block does not depend on p); s = the i64 bus load at the address rail p - 8 (add_i64_hl(p, -8),
; rule 20's address arithmetic; the plain load form, an address rail); the length rail umin_i64_hl(s, 24); and a
; rule-22 copy of min(s, 24) bytes from p to q. The length is a rail, so the copy is the quantum-length form, its trip
; bound the new block's size 24 (not K2; no overflow predicate: min(s, 24) <= 24). Byte j is loaded under
; p_j = icmp_ugt_i64_hl(min(s, 24), j) by qram_load_i8_controlled at the address rail add_i64_hl(p, j) and stored
; under the same p_j by qram_store_i8_hl_controlled at the classical address q + j. The copy loads all its bytes, then
; stores all of them. A trip C would not run touches no cell: on the k & 1 == 1 branch the loads at a + 8 .. a + 23,
; beyond the 8-byte block, are under p_j = 0. Nothing is done for p: both old blocks stay.
; No compile-time pointer knowledge is used: the old size is read from the bus on each branch of the address rail,
; and which block is copied is decided by the QRAM query alone.
; The header cells are HOST (written by __cq_alloc, read through the overlay); a[1] is QUANTUM after the store of x.
; SPEC GAP (rule 22 against rule 14, as in 201): rule 22 calls the two copy loops rule-14 K-loops, and rule 14 says a
; predicate that controls a kept store and every trip rail rule 5 keeps is NOT pushed; then the store loop cannot
; name p_j or the byte rail. Chosen, as the one exception to that sentence: the load loop computes ONE p_j per byte
; and pushes, per trip, p_j and then the byte rail on cqrt_push (a handle is never stored in program memory, §1.1);
; the store loop pops them (byte rail first, then p_j), so it stores bytes 23 down to 0 under the same p_j (a copy has
; no direction). There is no reverse loop: both rails are kept. With one p_j per byte, min(s, 24), s, p - 8 and p are
; dead before the first store and are cleaned between the two loops.
; SPEC GAP (rule 22): byte 0 of an address rail r. The rule spells every byte address add_i64_hl(r, j); chosen: j = 0
; too (add_i64_hl(p, 0), a fresh rail uncomputed and freed right after its access like the others), so the trip body
; is uniform and p itself is never the address operand of an access.
; SPEC GAP (rule 16, realloc): neither the template of p - 8 nor the order of the allocation and the header load is
; stated. Chosen: add_i64_hl(p, -8) (rule 20 forms every address with add_i64_hl), and the allocation FIRST: it is a
; memory version change (rule 5), so a header load made before it would be overtaken and s KEPT; made after it, s is
; un-copied before the copy's first store.
source_filename = "realloc_pointer_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @realloc_pointer_rail(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call ptr @__cq_alloc(i64 8, i64 16)    ; IR: %7 = call ptr @malloc(i64 8)  [rule 16: zeroed, never reused, the size 8 at a - 8]
  %9 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address (classical)
  %10 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %8 = call ptr @malloc(i64 16)  [rule 16: the size 16 at b - 8]
  %11 = ptrtoint ptr %10 to i64    ; IR: %8 as its run-time address (classical)
  %12 = add i64 %9, 4    ; IR: %9 = getelementptr inbounds i8, ptr %7, i64 4  (classical)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %12, i32 %7)    ; IR: store i32 %6, ptr %9  [kept store at a classical address: its slot and its value rail x stay]
  %13 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: store i32 5, ptr %10  [the stored value as a seed rail, kept with its store: rule 7]
  %14 = add i64 %11, 4    ; IR: %10 = getelementptr inbounds i8, ptr %8, i64 4  (classical)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %14, i32 %13)    ; IR: store i32 5, ptr %10  [kept store at a classical address]
  %15 = call i32 @cqrt_alloc_i32(i32 7)    ; IR: store i32 7, ptr %11  [seed rail, kept with its store: rule 7]
  %16 = add i64 %11, 8    ; IR: %11 = getelementptr inbounds i8, ptr %8, i64 8  (classical)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %16, i32 %15)    ; IR: store i32 7, ptr %11  [kept store at a classical address: bytes 8..11 of b]
  %17 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %12 = and i32 %5, 1
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 0)    ; IR: %13 = icmp eq i32 %12, 0
  %19 = call i32 @cq_template_select_i64_ll(i32 %18, i64 %11, i64 %9)    ; IR: %14 = select i1 %13, ptr %8, ptr %7  [rule 21: the address rail p = flag ? b : a]
  %20 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %15 = call ptr @realloc(ptr %14, i64 24)  [rule 16: the new block q, classical]
  %21 = ptrtoint ptr %20 to i64    ; IR: %15 as its run-time address (classical)
  %22 = call i32 @cq_template_add_i64_hl(i32 %19, i64 -8)    ; IR: %15: the address rail of the old block's size header, p - 8 (after the allocation: s is then un-copied, not kept)
  %23 = call i32 @cqrt_qram_load_i64(i32 %5, i32 %22)    ; IR: %15: s = the old block's size, loaded from the bus at the address rail p - 8
  %24 = call i32 @cq_template_umin_i64_hl(i32 %23, i64 24)    ; IR: %15: the copy length min(s, 24) (a rail: rule 22, quantum length)
  br label %25    ; IR: %15: the copy's load loop, 24 trips (the new block's size)

25:
  %26 = phi i64 [ 0, %4 ], [ %30, %25 ]    ; IR: %15: byte index j (classical)
  %27 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %24, i64 %26)    ; IR: %15: p_j = (min(s, 24) > j), the predicate of byte j
  %28 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %26)    ; IR: %15: the source address rail p + j (rule 22)
  %29 = call i32 @cqrt_qram_load_i8_controlled(i32 %27, i32 %5, i32 %28)    ; IR: %15: byte j of the old block at the address rail, under p_j
  call void @cq_template_add_i64_hl_unc(i32 %28, i32 %19, i64 %26)    ; IR: uncompute p + j (the address rail, after its load; the load copy is kept)
  call void @cqrt_free(i32 %28)    ; IR: release the p + j rail (|0>)
  call void @cqrt_push(i32 %27)    ; IR: %15: p_j to the store loop (rule 22's hand-over: pushed although kept, no reverse loop)
  call void @cqrt_push(i32 %29)    ; IR: %15: the byte rail to the store loop
  %30 = add nuw nsw i64 %26, 1
  %31 = icmp eq i64 %30, 24    ; IR: %15: trip bound = the new block's size (rule 16)
  br i1 %31, label %32, label %25

32:
  call void @cq_template_umin_i64_hl_unc(i32 %24, i32 %23, i64 24)    ; IR: uncompute min(s, 24) (after the last p_j)
  call void @cqrt_free(i32 %24)    ; IR: release the min(s, 24) rail (|0>)
  call void @cqrt_qram_load_i64_unc(i32 %23, i32 %5, i32 %22)    ; IR: un-copy s (rule 5 sentence 1: before the next memory version change, the first copy store)
  call void @cqrt_free(i32 %23)    ; IR: release the s rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %22, i32 %19, i64 -8)    ; IR: uncompute p - 8 (the address rail, after its load's _unc, which reads it)
  call void @cqrt_free(i32 %22)    ; IR: release the p - 8 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %19, i32 %18, i64 %11, i64 %9)    ; IR: uncompute %14 (the address rail p, after its last reader, the _unc of p - 8)
  call void @cqrt_free(i32 %19)    ; IR: release the %14 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %18, i32 %17, i32 0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %18)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %6, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %17)    ; IR: release the %12 rail (|0>)
  br label %33    ; IR: %15: the copy's store loop

33:
  %34 = phi i64 [ 23, %32 ], [ %38, %33 ]    ; IR: %15: byte index, 23 down to 0 (the pop order)
  %35 = call i32 @cqrt_pop()    ; IR: %15: the rail of byte i
  %36 = call i32 @cqrt_pop()    ; IR: %15: p_i
  %37 = add i64 %21, %34    ; IR: %15: the destination address q + i (classical)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %36, i32 %5, i64 %37, i32 %35)    ; IR: %15: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %38 = add nsw i64 %34, -1
  %39 = icmp eq i64 %34, 0
  br i1 %39, label %40, label %33

40:
  %41 = add i64 %21, 4    ; IR: %16 = getelementptr inbounds i8, ptr %15, i64 4  (classical)
  %42 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %41)    ; IR: %17 = load i32, ptr %16  [load copy at a classical address; measured, so never un-copied]
  %43 = call i32 @cqrt_measure_i32(i32 %42)    ; IR: %18 = cq_measure_si32(%17)
  %44 = add i64 %21, 8    ; IR: %19 = getelementptr inbounds i8, ptr %15, i64 8  (classical)
  %45 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %44)    ; IR: %20 = load i32, ptr %19  [load copy at a classical address; measured, so never un-copied]
  %46 = call i32 @cqrt_measure_i32(i32 %45)    ; IR: %21 = cq_measure_si32(%20)
  %47 = add nsw i32 %46, %43    ; IR: %22 = add nsw i32 %21, %18  (classical: both operands are measurement outcomes, rule 2)
  ret i32 %47    ; IR: ret i32 %22
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64_hl(i32, i64)
declare void @cq_template_umin_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cqrt_qram_load_i64(i32, i32)
declare void @cqrt_qram_load_i64_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_controlled(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
