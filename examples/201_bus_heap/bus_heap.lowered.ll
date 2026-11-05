; HAND-WRITTEN. Rules: 16, 22, 20, 21, 5, 2, 3, 4, 7, 14.
; Checked: r = a[k & 7] after the realloc (the load copy at the address rail, measured): x when k & 4 == 0 (the cell
; a[k & 3] the first store wrote, carried over by the copy), 2 when k & 7 == 7, else 0 (zeroed __cq_alloc memory).
; Clean: both address chains (and, zext, mul, add: uncomputed right after their access), min(s, 32) and the header load
; copy s (un-copied before the first copy store: its only consumer umin and that consumer's _unc precede the next memory
; version change, rule 5 sentence 1).
; Kept: k and x (rotated; x is also the value rail of the kept store a[k & 3] = x); the tape slot of that store; for
; each of the 32 copy trips the predicate p_j = (min(s, 32) > j), the controlled load copy of byte j (the value rail
; of its kept store) and that store's tape slot (rule 5 sentence 3, rule 22); the seed 2 and the tape slot of a[7] = 2
; (rule 7); r (the load copy, measured: rule 2).
; Rotations: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Driver bus_heap(1, .5, 9, .25): Ry acts on every qubit of a register, so each bit of k flips with probability
; p = sin^2(.25) = 0.061209 and each bit of x with q = sin^2(.125) = 0.015544, independently. The header at P0 - 8
; reads 16, so p_0..p_15 are 1 and p_16..p_31 are 0: 16 bytes are copied. Measured r: k & 4 == 0 (1 - p = 0.938791)
; gives r = x, so r = 9 with (1 - p)(1 - q)^32 = 0.568662 and each single-bit neighbour of 9 with
; (1 - p) q (1 - q)^31 = 0.008979; k & 7 == 7 gives r = 2 with p^2 (1 - p) = 0.003517 (0.003519 with x = 2);
; k & 4 != 0 and k & 7 != 7 gives r = 0 with p - p^2 (1 - p) = 0.057692 (0.057833 with x = 0).
; ALLOCATION (rule 16). malloc(16) is __cq_alloc(16, 16) (alignment 16: the call names none): zeroed host memory at an
; address never reused, its size as an i64 in the 8 bytes before it. Nothing is known about the block at compile time.
; realloc(p, 32) with a classical p is q = __cq_alloc(32, 16), s = the i64 bus load at p - 8 (_hl: a classical
; address; a rail all the same, rule 3) and a rule-22 copy of min(s, 32) bytes from p to q: the length is the rail
; umin_i64_hl(s, 32), so the copy is the quantum-length form, its trip bound the new block's size 32 (not K2; no
; overflow predicate: min(s, 32) <= 32), byte j loaded and stored under p_j = icmp_ugt_i64_hl(min(s, 32), j) by the
; _hl_controlled forms at the classical addresses p + j and q + j. The copy loads all its bytes, then stores all of
; them. Nothing is done for p: the old block stays, and free(a) emits nothing. A pointer is its run-time i64 (rule 21):
; p and q are classical here, and nothing else is known about them. The size is always the bus load, never a host read
; of the header, also for a classical p and n: the header cells are bus cells and may be QUANTUM (rule 3).
; The cells of the old block are QUANTUM after the address-rail store (it can reach all 16), so the 16 copied bytes
; are quantum data although every address and predicate of the copy is classical-valued here.
; SPEC GAP (rule 22, carrier): how the byte rails of the load loop reach the store loop is not stated. Chosen: the load
; loop pushes p_j, then the byte rail, on cqrt_push (a handle that outlives its SSA value, §1.1; never stored in program
; memory) and the store loop pops them, so it stores bytes 31 down to 0 (a copy has no direction). These pushes are the
; carrier between the two loops, not rule 14's reverse-loop pushes: the rails are kept (rule 5) and no reverse loop
; follows, so rule 14's "a kept trip rail is not pushed" does not apply to them.
; SPEC GAP (rule 22, quantum length): whether the store loop computes its own p_j is not stated. Chosen: ONE p_j per
; byte, computed in the load loop; it controls byte j's load and byte j's store and is kept as that store's control
; rail (rule 5). The length rail and what produced it (min(s, 32), s) then have their last consumer in the load loop
; and are uncomputed between the two loops, before the first store; a second set of p_j computed in the store loop
; would keep s (overtaken by the stores) and uncompute 32 more flags.
; SPEC GAP (rule 16, realloc): the template of min(s, n) is not named. Chosen: the length rail is umin_i64_hl(s, n)
; and p_j compares that rail; the trip bound is the new block's size in place of min(K2, B) (so no loop-cutoff tag on any line), and there is
; no overflow predicate, since the length never exceeds the bound.
source_filename = "bus_heap.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bus_heap(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = call ptr @malloc(i64 16)  [rule 16: zeroed, never reused, the size 16 at p - 8]
  %9 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address (classical)
  %10 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %8 = and i32 %5, 3
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)    ; IR: %9 = zext nneg i32 %8 to i64
  %12 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 4)    ; IR: %10 = getelementptr inbounds i32, ptr %7, i64 %9  [the index scaled by sizeof(i32)]
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 %9)    ; IR: %10  [address rail = p + 4 * (k & 3)]
  call void @cqrt_qram_store_i32(i32 %5, i32 %13, i32 %7)    ; IR: store i32 %6, ptr %10  [kept store at an address rail: its slot and its value rail x stay]
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 %9)    ; IR: uncompute %10 (the address rail, after its store)
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %11, i64 4)    ; IR: uncompute the scaled index of %10
  call void @cqrt_free(i32 %12)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %6, i32 3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  %14 = call ptr @__cq_alloc(i64 32, i64 16)    ; IR: %11 = call ptr @realloc(ptr %7, i64 32)  [rule 16: the new block]
  %15 = ptrtoint ptr %14 to i64    ; IR: %11 as its run-time address (classical)
  %16 = add i64 %9, -8    ; IR: %11: the address of the old block's size header, p - 8
  %17 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %16)    ; IR: %11: s = the old block's size, loaded from the bus (a rail)
  %18 = call i32 @cq_template_umin_i64_hl(i32 %17, i64 32)    ; IR: %11: the copy length min(s, 32) (a rail: rule 22, quantum length)
  br label %19    ; IR: %11: the copy's load loop, 32 trips (the new block's size)

19:
  %20 = phi i64 [ 0, %4 ], [ %24, %19 ]    ; IR: %11: byte index j (classical)
  %21 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %18, i64 %20)    ; IR: %11: p_j = (min(s, 32) > j), the predicate of byte j
  %22 = add i64 %9, %20    ; IR: %11: the source address p + j
  %23 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %21, i32 %5, i64 %22)    ; IR: %11: byte j of the old block under p_j
  call void @cqrt_push(i32 %21)    ; IR: %11: p_j to the store loop
  call void @cqrt_push(i32 %23)    ; IR: %11: the byte rail to the store loop
  %24 = add nuw nsw i64 %20, 1
  %25 = icmp eq i64 %24, 32    ; IR: %11: trip bound = the new block's size (rule 16)
  br i1 %25, label %26, label %19

26:
  call void @cq_template_umin_i64_hl_unc(i32 %18, i32 %17, i64 32)    ; IR: uncompute min(s, 32) (after the last p_j)
  call void @cqrt_free(i32 %18)    ; IR: release the min(s, 32) rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %5, i64 %16)    ; IR: un-copy s (rule 5 sentence 1: before the next memory version change, the first copy store)
  call void @cqrt_free(i32 %17)    ; IR: release the s rail (|0>)
  br label %27    ; IR: %11: the copy's store loop

27:
  %28 = phi i64 [ 31, %26 ], [ %32, %27 ]    ; IR: %11: byte index, 31 down to 0 (the pop order)
  %29 = call i32 @cqrt_pop()    ; IR: %11: the rail of byte i
  %30 = call i32 @cqrt_pop()    ; IR: %11: p_i
  %31 = add i64 %15, %28    ; IR: %11: the destination address q + i
  call void @cqrt_qram_store_i8_hl_controlled(i32 %30, i32 %5, i64 %31, i32 %29)    ; IR: %11: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %32 = add nsw i64 %28, -1
  %33 = icmp eq i64 %28, 0
  br i1 %33, label %34, label %27

34:
  %35 = call i32 @cqrt_alloc_i32(i32 2)    ; IR: store i32 2, ptr %12  [the stored value as a seed rail, kept with its store: rule 7]
  %36 = add i64 %15, 28    ; IR: %12 = getelementptr inbounds i8, ptr %11, i64 28  (classical)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %36, i32 %35)    ; IR: store i32 2, ptr %12  [kept store at a classical address]
  %37 = call i32 @cq_template_and_i32_hl(i32 %6, i32 7)    ; IR: %13 = and i32 %5, 7
  %38 = call i32 @cq_template_zext_i32_to_i64(i32 %37)    ; IR: %14 = zext nneg i32 %13 to i64
  %39 = call i32 @cq_template_mul_i64_hl(i32 %38, i64 4)    ; IR: %15 = getelementptr inbounds i32, ptr %11, i64 %14  [the index scaled by sizeof(i32)]
  %40 = call i32 @cq_template_add_i64_hl(i32 %39, i64 %15)    ; IR: %15  [address rail = q + 4 * (k & 7)]
  %41 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %40)    ; IR: %16 = load i32, ptr %15  [load copy at an address rail; measured, so never un-copied]
  call void @cq_template_add_i64_hl_unc(i32 %40, i32 %39, i64 %15)    ; IR: uncompute %15 (the address rail, after its load)
  call void @cqrt_free(i32 %40)    ; IR: release the %15 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %39, i32 %38, i64 4)    ; IR: uncompute the scaled index of %15
  call void @cqrt_free(i32 %39)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %38, i32 %37)    ; IR: uncompute %14
  call void @cqrt_free(i32 %38)    ; IR: release the %14 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %37, i32 %6, i32 7)    ; IR: uncompute %13
  call void @cqrt_free(i32 %37)    ; IR: release the %13 rail (|0>)
  %42 = call i32 @cqrt_measure_i32(i32 %41)    ; IR: call void @free(ptr %11) is nothing (rule 16); %17 = cq_measure_si32(%16)
  ret i32 %42    ; IR: ret i32 %17
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64_hl(i32, i64)
declare void @cq_template_umin_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
