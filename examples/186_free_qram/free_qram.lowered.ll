; HAND-WRITTEN. Rules: 2, 4, 5, 6, 7, 16, 20, 21, 22.
; Checked: free_uncond and free_classical_cond: r = a[1] + a[k % 6] and s = k * 3 (both measured): a[1] = v when
; k & 3 == 1, else 0; a[k % 6] = v when k % 6 == k & 3 (k % 6 < 4, the cell the first store wrote, carried over by
; the realloc copy), 2 when k % 6 == 5, else 0 (zeroed __cq_alloc memory). free_entangled: a[1] + 1 (measured), a[1]
; = x's value before its second rotation when k & 3 == 1, else 0. qram_ptr_addr: p == other (0: other is the host
; object hostv, never inside a), p < a + 2, (uintptr_t)p - (uintptr_t)a = 4 * idx and a[1] (all measured).
; Clean: every address chain (and / urem / zext / mul / add_i64: uncomputed right after its store, after the un-copy of
; its load); in free_uncond and free_classical_cond the realloc's header load copy s and min(s, 6) (s is un-copied
; before the first copy store: rule 5 sentence 1) and the load copy a[k % 6] (un-copied after its last reader, the add;
; no memory version change follows); un-copied but left allocated (rule 5 sentence 1): the load copy a[1], un-copied
; right after its reader, the add, which follows the realloc (a memory version change); free_entangled: the load copy a[1] (un-copied after the add); qram_ptr_addr:
; k << 1, the masked byte offset 4 * idx, p's address rail, both compare flags.
; free_uncond and free_classical_cond also: the old k rail (rule 6: s = k * 3 is a bijection in k, 3 being odd; t = s *
; 0xAAAAAAAB, the inverse of 3 mod 2^32) and t, both freed right after the mul (k's last reader, the urem's _unc,
; precedes it).
; Kept (rule 5): free_uncond and free_classical_cond: the seed v and the tape slot of a[k & 3] = v; for each of the 6 copy
; trips the predicate p_j = (min(s, 6) > j), the controlled load copy of byte j (the value rail of its kept store) and
; that store's tape slot (rule 22); the seed 2 and the tape slot of a[5] = 2 (rule 7); both results (measured).
; free_entangled: k and x (rotated registers; x is also the value rail of the kept store a[k & 3] = x) and that store's
; tape slot; the seed 1 and the tape slot of a[0] = 1; the result (measured). qram_ptr_addr: k; the seed 5 and the
; tape slot of a[k & 3] = 5; the load copy a[1] and the results eq, lt, d (measured: rule 2).
; Rotations: free_uncond, free_classical_cond: (Ry, k, tk, 1). free_entangled: (Ry, k, tk, 1); (Ry, x, tx, 1);
; (Ry, x, t2, 1). qram_ptr_addr: (Ry, k, tk, 1).
; ONE BUS (rules 16, 20, 21). malloc(n) is __cq_alloc(n, 16) (zeroed host memory never reused, the size n as an i64 in
; the 8 bytes before it; alignment 16: the call names none); a pointer is its run-time i64 address, classical here
; (ptrtoint of the __cq_alloc result), and nothing about the block is known at compile time. a[k & 3] = ... is a bus
; store at an address rail (zext of the index, scaled by the element size, add_i64_hl of the classical base); a
; fixed-index access is the _hl form at the classical address base + offset. Every store is KEPT (rule 5 sentence 3):
; no store is popped and nothing is released. realloc(a, 6) is q = __cq_alloc(6, 16), s = the i64 bus load at a - 8,
; the length rail umin_i64_hl(s, 6) and a rule-22 quantum-length byte copy from a to q (trip bound 6, the new block's
; size; no overflow predicate), as in 201. free(a) is NOTHING (rule 16), under any condition: the clean-up at the free
; and the scope-end clean-up of the retired per-object model are gone, and every rail is cleaned or kept by rule 5 at
; its own point.
; free_classical_cond: the classical branch on c around the free stays as -O1 left it; its arm is empty.
; free_entangled: a[k & 3] = x copies x into the cell; the later Ry on x acts on x alone (rule 2), the stored copy and
; its tape slot are kept like any store, so x's rotation needs no special case. -O1 forwarded the read a[0] to the
; literal 1 (r = a[1] + 1).
; qram_ptr_addr: p = a + ((k >> 1) & 3) is ONE 64-bit address rail, add_i64_hl(4 * idx, a) (rule 21; a byte gep: no
; scale). p == other is icmp_eq_i64_hl of that rail against other's run-time address (ptrtoint at function entry). -O1
; cancelled the base in p < a + 2 (byte offset 4 * idx < 8) and in (uintptr_t)p - (uintptr_t)a (the byte offset,
; zext to i64), so those read only the offset rail. The load copy a[1] is measured, so it is never un-copied.
source_filename = "free_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @free_uncond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call ptr @__cq_alloc(i64 4, i64 16)    ; IR: %5 = call ptr @malloc(i64 4)  [rule 16: zeroed, never reused, the size 4 at a - 8]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  %8 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %6 = and i32 %4, 3
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %7 = zext nneg i32 %6 to i64
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %7)    ; IR: %8 = getelementptr inbounds i8, ptr %5, i64 %7  [address rail = a + (k & 3); size 1: no scale]
  %11 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8  [v as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %4, i32 %10, i32 %11)    ; IR: store i8 %2, ptr %8  [kept store at an address rail]
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 %7)    ; IR: uncompute %8 (the address rail, after its store)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %5, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %12 = add i64 %7, 1    ; IR: %9 = getelementptr inbounds i8, ptr %5, i64 1  (classical)
  %13 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %12)    ; IR: %10 = load i8, ptr %9  [a[1]; its reader %17 follows the realloc: overtaken, un-copied after it and left allocated, rule 5 sentence 1]
  %14 = call ptr @__cq_alloc(i64 6, i64 16)    ; IR: %11 = call ptr @realloc(ptr %5, i64 6)  [rule 16: the new block]
  %15 = ptrtoint ptr %14 to i64    ; IR: %11 as its run-time address (classical)
  %16 = add i64 %7, -8    ; IR: %11: the address of the old block's size header, a - 8
  %17 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %16)    ; IR: %11: s = the old block's size, loaded from the bus (a rail)
  %18 = call i32 @cq_template_umin_i64_hl(i32 %17, i64 6)    ; IR: %11: the copy length min(s, 6) (a rail: rule 22, quantum length)
  br label %19    ; IR: %11: the copy's load loop, 6 trips (the new block's size)

19:
  %20 = phi i64 [ 0, %3 ], [ %24, %19 ]    ; IR: %11: byte index j (classical)
  %21 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %18, i64 %20)    ; IR: %11: p_j = (min(s, 6) > j), the predicate of byte j
  %22 = add i64 %7, %20    ; IR: %11: the source address a + j
  %23 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %21, i32 %4, i64 %22)    ; IR: %11: byte j of the old block under p_j
  call void @cqrt_push(i32 %21)    ; IR: %11: p_j to the store loop
  call void @cqrt_push(i32 %23)    ; IR: %11: the byte rail to the store loop
  %24 = add nuw nsw i64 %20, 1
  %25 = icmp eq i64 %24, 6    ; IR: %11: trip bound = the new block's size (rule 16)
  br i1 %25, label %26, label %19

26:
  call void @cq_template_umin_i64_hl_unc(i32 %18, i32 %17, i64 6)    ; IR: uncompute min(s, 6) (after the last p_j)
  call void @cqrt_free(i32 %18)    ; IR: release the min(s, 6) rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %4, i64 %16)    ; IR: un-copy s (rule 5 sentence 1: before the first copy store)
  call void @cqrt_free(i32 %17)    ; IR: release the s rail (|0>)
  br label %27    ; IR: %11: the copy's store loop

27:
  %28 = phi i64 [ 5, %26 ], [ %32, %27 ]    ; IR: %11: byte index, 5 down to 0 (the pop order)
  %29 = call i32 @cqrt_pop()    ; IR: %11: the rail of byte i
  %30 = call i32 @cqrt_pop()    ; IR: %11: p_i
  %31 = add i64 %15, %28    ; IR: %11: the destination address q + i
  call void @cqrt_qram_store_i8_hl_controlled(i32 %30, i32 %4, i64 %31, i32 %29)    ; IR: %11: byte i of the new block under p_i  [kept store: slot, byte rail and p_i stay]
  %32 = add nsw i64 %28, -1
  %33 = icmp eq i64 %28, 0
  br i1 %33, label %34, label %27

34:
  %35 = call i32 @cqrt_alloc_i8(i8 2)    ; IR: store i8 2, ptr %12  [the stored value as a seed rail, kept with its store: rule 7]
  %36 = add i64 %15, 5    ; IR: %12 = getelementptr inbounds i8, ptr %11, i64 5  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %36, i32 %35)    ; IR: store i8 2, ptr %12  [kept store at a classical address]
  %37 = call i32 @cq_template_urem_i32_hl(i32 %5, i32 6)    ; IR: %13 = urem i32 %4, 6
  %38 = call i32 @cq_template_zext_i32_to_i64(i32 %37)    ; IR: %14 = zext nneg i32 %13 to i64
  %39 = call i32 @cq_template_add_i64_hl(i32 %38, i64 %15)    ; IR: %15 = getelementptr inbounds i8, ptr %11, i64 %14  [address rail = q + k % 6]
  %40 = call i32 @cqrt_qram_load_i8(i32 %4, i32 %39)    ; IR: %16 = load i8, ptr %15  [load copy at an address rail]
  %41 = call i32 @cq_template_add_i8(i32 %40, i32 %13)    ; IR: %17 = add i8 %16, %10  [result rail r]
  call void @cqrt_qram_load_i8_hl_unc(i32 %13, i32 %4, i64 %12)    ; IR: un-copy %10 (after its last reader %17; the realloc overtook it, so it stays allocated: rule 5 sentence 1)
  call void @cqrt_qram_load_i8_unc(i32 %40, i32 %4, i32 %39)    ; IR: un-copy %16 (after its last reader %17; no memory version change follows)
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %39, i32 %38, i64 %15)    ; IR: uncompute %15 (the address rail, after its load's _unc)
  call void @cqrt_free(i32 %39)    ; IR: release the %15 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %38, i32 %37)    ; IR: uncompute %14
  call void @cqrt_free(i32 %38)    ; IR: release the %14 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %37, i32 %5, i32 6)    ; IR: uncompute %13
  call void @cqrt_free(i32 %37)    ; IR: release the %13 rail (|0>)
  %42 = call i32 @cq_template_mul_i32_hl(i32 %5, i32 3)    ; IR: call void @free(ptr %11) is nothing (rule 16); %18 = mul i32 %4, 3  [result rail s]
  %43 = call i32 @cq_template_mul_i32_hl(i32 %42, i32 -1431655765)    ; IR: rule 6: t = s * 3^-1 (0xAAAAAAAB, the inverse of 3 mod 2^32) recomputes the old k (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %43, i32 %5)    ; IR: rule 6: k ^= t: the dead k rail is now |0>
  call void @cq_template_mul_i32_hl_unc(i32 %43, i32 %42, i32 -1431655765)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %43)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old k rail (|0> after the copy)
  %44 = call i8 @cqrt_measure_i8(i32 %41)    ; IR: %19 = cq_measure_ui8(%17)
  %45 = zext i8 %44 to i32    ; IR: %20 = zext i8 %19 to i32  (classical)
  %46 = call i32 @cqrt_measure_i32(i32 %42)    ; IR: %21 = cq_measure_ui32(%18)
  %47 = add i32 %46, %45    ; IR: %22 = add i32 %21, %20  (classical)
  ret i32 %47    ; IR: ret i32 %22
}

define i32 @free_classical_cond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (function entry) the bus M
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call ptr @__cq_alloc(i64 4, i64 16)    ; IR: %6 = call ptr @malloc(i64 4)  [rule 16]
  %8 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (classical)
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %7 = and i32 %5, 3
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)    ; IR: %8 = zext nneg i32 %7 to i64
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 %8)    ; IR: %9 = getelementptr inbounds i8, ptr %6, i64 %8  [address rail = a + (k & 3)]
  %12 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %9  [v as a seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8(i32 %5, i32 %11, i32 %12)    ; IR: store i8 %2, ptr %9  [kept store at an address rail]
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 %8)    ; IR: uncompute %9 (after its store)
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %13 = add i64 %8, 1    ; IR: %10 = getelementptr inbounds i8, ptr %6, i64 1  (classical)
  %14 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %13)    ; IR: %11 = load i8, ptr %10  [a[1]; its reader %21 follows the realloc: overtaken, un-copied after it and left allocated, rule 5 sentence 1]
  %15 = call ptr @__cq_alloc(i64 6, i64 16)    ; IR: %12 = call ptr @realloc(ptr %6, i64 6)  [rule 16: the new block]
  %16 = ptrtoint ptr %15 to i64    ; IR: %12 as its run-time address (classical)
  %17 = add i64 %8, -8    ; IR: %12: the address of the old block's size header, a - 8
  %18 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %17)    ; IR: %12: s = the old block's size (a rail)
  %19 = call i32 @cq_template_umin_i64_hl(i32 %18, i64 6)    ; IR: %12: the copy length min(s, 6)
  br label %20    ; IR: %12: the copy's load loop, 6 trips

20:
  %21 = phi i64 [ 0, %4 ], [ %25, %20 ]    ; IR: %12: byte index j (classical)
  %22 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %19, i64 %21)    ; IR: %12: p_j = (min(s, 6) > j)
  %23 = add i64 %8, %21    ; IR: %12: the source address a + j
  %24 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %22, i32 %5, i64 %23)    ; IR: %12: byte j of the old block under p_j
  call void @cqrt_push(i32 %22)    ; IR: %12: p_j to the store loop
  call void @cqrt_push(i32 %24)    ; IR: %12: the byte rail to the store loop
  %25 = add nuw nsw i64 %21, 1
  %26 = icmp eq i64 %25, 6    ; IR: %12: trip bound = the new block's size
  br i1 %26, label %27, label %20

27:
  call void @cq_template_umin_i64_hl_unc(i32 %19, i32 %18, i64 6)    ; IR: uncompute min(s, 6)
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %18, i32 %5, i64 %17)    ; IR: un-copy s (before the first copy store)
  call void @cqrt_free(i32 %18)    ; IR: release the s rail (|0>)
  br label %28    ; IR: %12: the copy's store loop

28:
  %29 = phi i64 [ 5, %27 ], [ %33, %28 ]    ; IR: %12: byte index, 5 down to 0
  %30 = call i32 @cqrt_pop()    ; IR: %12: the rail of byte i
  %31 = call i32 @cqrt_pop()    ; IR: %12: p_i
  %32 = add i64 %16, %29    ; IR: %12: the destination address q + i
  call void @cqrt_qram_store_i8_hl_controlled(i32 %31, i32 %5, i64 %32, i32 %30)    ; IR: %12: byte i under p_i  [kept store]
  %33 = add nsw i64 %29, -1
  %34 = icmp eq i64 %29, 0
  br i1 %34, label %35, label %28

35:
  %36 = call i32 @cqrt_alloc_i8(i8 2)    ; IR: store i8 2, ptr %13  [seed rail, kept with its store: rule 7]
  %37 = add i64 %16, 5    ; IR: %13 = getelementptr inbounds i8, ptr %12, i64 5  (classical)
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %37, i32 %36)    ; IR: store i8 2, ptr %13  [kept store]
  %38 = call i32 @cq_template_urem_i32_hl(i32 %6, i32 6)    ; IR: %14 = urem i32 %5, 6
  %39 = call i32 @cq_template_zext_i32_to_i64(i32 %38)    ; IR: %15 = zext nneg i32 %14 to i64
  %40 = call i32 @cq_template_add_i64_hl(i32 %39, i64 %16)    ; IR: %16 = getelementptr inbounds i8, ptr %12, i64 %15  [address rail = q + k % 6]
  %41 = call i32 @cqrt_qram_load_i8(i32 %5, i32 %40)    ; IR: %17 = load i8, ptr %16  [load copy at an address rail]
  %42 = icmp eq i32 %3, 0    ; IR: %18 = icmp eq i32 %3, 0  (classical)
  br i1 %42, label %44, label %43    ; IR: br i1 %18, label %20, label %19  (classical branch)

43:
  br label %44    ; IR: block %19: call void @free(ptr %12) is nothing (rule 16)

44:
  %45 = call i32 @cq_template_add_i8(i32 %41, i32 %14)    ; IR: %21 = add i8 %17, %11  [result rail r]
  call void @cqrt_qram_load_i8_hl_unc(i32 %14, i32 %5, i64 %13)    ; IR: un-copy %11 (after its last reader %21; the realloc overtook it, so it stays allocated: rule 5 sentence 1)
  call void @cqrt_qram_load_i8_unc(i32 %41, i32 %5, i32 %40)    ; IR: un-copy %17 (after its last reader %21; no memory version change follows)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %40, i32 %39, i64 %16)    ; IR: uncompute %16 (after its load's _unc)
  call void @cqrt_free(i32 %40)    ; IR: release the %16 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %39, i32 %38)    ; IR: uncompute %15
  call void @cqrt_free(i32 %39)    ; IR: release the %15 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %38, i32 %6, i32 6)    ; IR: uncompute %14
  call void @cqrt_free(i32 %38)    ; IR: release the %14 rail (|0>)
  %46 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 3)    ; IR: %22 = mul i32 %5, 3  [result rail s]
  %47 = call i32 @cq_template_mul_i32_hl(i32 %46, i32 -1431655765)    ; IR: rule 6: t = s * 3^-1 (0xAAAAAAAB) recomputes the old k (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %47, i32 %6)    ; IR: rule 6: k ^= t: the dead k rail is now |0>
  call void @cq_template_mul_i32_hl_unc(i32 %47, i32 %46, i32 -1431655765)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %47)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old k rail (|0> after the copy)
  %48 = call i8 @cqrt_measure_i8(i32 %45)    ; IR: %23 = cq_measure_ui8(%21)
  %49 = zext i8 %48 to i32    ; IR: %24 = zext i8 %23 to i32  (classical)
  %50 = call i32 @cqrt_measure_i32(i32 %46)    ; IR: %25 = cq_measure_ui32(%22)
  %51 = add i32 %50, %49    ; IR: %26 = add i32 %25, %24  (classical)
  ret i32 %51    ; IR: ret i32 %26
}

define i32 @free_entangled(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: (function entry) the bus M
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: %7 = cq_theta_ui8(%2, %3)  [register x]
  call void @cqrt_ry_i8(i32 %8, double %3)    ; IR: %7 = cq_theta_ui8(%2, %3)  [Ry]
  %9 = call ptr @__cq_alloc(i64 4, i64 16)    ; IR: %8 = call ptr @malloc(i64 4)  [rule 16]
  %10 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address (classical)
  %11 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %9 = and i32 %6, 3
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)    ; IR: %10 = zext nneg i32 %9 to i64
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 %10)    ; IR: %11 = getelementptr inbounds i8, ptr %8, i64 %10  [address rail = a + (k & 3)]
  call void @cqrt_qram_store_i8(i32 %6, i32 %13, i32 %8)    ; IR: store i8 %7, ptr %11  [kept store: its slot and its value rail x stay]
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 %10)    ; IR: uncompute %11 (after its store)
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %7, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cqrt_ry_i8(i32 %8, double %4)    ; IR: %12 = cq_theta_ui8(%7, %4): x rotated in place (rule 2)  [Ry]
  %14 = call i32 @cqrt_alloc_i8(i8 1)    ; IR: store i8 1, ptr %8  [seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %10, i32 %14)    ; IR: store i8 1, ptr %8  [kept store at a classical address]
  %15 = add i64 %10, 1    ; IR: %13 = getelementptr inbounds i8, ptr %8, i64 1  (classical)
  %16 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %15)    ; IR: %14 = load i8, ptr %13  [a[1]: old x when k & 3 == 1]
  %17 = call i32 @cq_template_add_i8_hl(i32 %16, i8 1)    ; IR: %15 = add i8 %14, 1  (a[0] forwarded to 1)  [result rail]
  call void @cqrt_qram_load_i8_hl_unc(i32 %16, i32 %6, i64 %15)    ; IR: un-copy %14 (after its last reader %15; free(ptr %8) is nothing and no memory version change follows)
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  %18 = call i8 @cqrt_measure_i8(i32 %17)    ; IR: %16 = cq_measure_ui8(%15)
  %19 = zext i8 %18 to i32    ; IR: %17 = zext i8 %16 to i32  (classical)
  ret i32 %19    ; IR: ret i32 %17
}

define i32 @qram_ptr_addr(i32 noundef %0, double noundef %1, ptr noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: (function entry) the bus M
  %5 = ptrtoint ptr %2 to i64    ; IR: other's run-time address (classical; a pointer argument, placed once at function entry)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = call ptr @malloc(i64 16)  [rule 16]
  %8 = ptrtoint ptr %7 to i64    ; IR: %5 as its run-time address (classical)
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %6 = and i32 %4, 3
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)    ; IR: %7 = zext nneg i32 %6 to i64
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 4)    ; IR: %8 = getelementptr inbounds i32, ptr %5, i64 %7  [the index scaled by sizeof(i32)]
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 %8)    ; IR: %8  [address rail = a + 4 * (k & 3)]
  %13 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: store i32 5, ptr %8  [seed rail, kept with its store: rule 7]
  call void @cqrt_qram_store_i32(i32 %4, i32 %12, i32 %13)    ; IR: store i32 5, ptr %8  [kept store at an address rail]
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 %8)    ; IR: uncompute %8 (after its store)
  call void @cqrt_free(i32 %12)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 4)    ; IR: uncompute the scaled index of %8
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %7
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %9)    ; IR: release the %6 rail (|0>)
  %14 = call i32 @cq_template_shl_i32_hl(i32 %6, i32 1)    ; IR: %9 = shl i32 %4, 1
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 12)    ; IR: %10 = and i32 %9, 12: the byte offset 4 * idx of p (idx = (k >> 1) & 3)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %15)    ; IR: %11 = zext nneg i32 %10 to i64  [result rail d = (uintptr_t)p - (uintptr_t)a]
  %17 = call i32 @cq_template_add_i64_hl(i32 %16, i64 %8)    ; IR: %12 = getelementptr inbounds i8, ptr %5, i64 %11  [p: ONE 64-bit address rail = a + 4 * idx (rule 21)]
  %18 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 %5)    ; IR: %13 = icmp eq ptr %12, %2  [the integer compare of the addresses (rule 21)]
  %19 = call i32 @cq_template_zext_i1_to_i32(i32 %18)    ; IR: %14 = zext i1 %13 to i32  [result rail eq]
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %18, i32 %17, i64 %5)    ; IR: uncompute %13
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %17, i32 %16, i64 %8)    ; IR: uncompute p's address rail %12
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  %20 = call i32 @cq_template_icmp_ult_i32_hl(i32 %15, i32 8)    ; IR: %15 = icmp ult i32 %10, 8: p < a + 2 (-O1 cancelled the common base)
  %21 = call i32 @cq_template_zext_i1_to_i32(i32 %20)    ; IR: %16 = zext i1 %15 to i32  [result rail lt]
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %20, i32 %15, i32 8)    ; IR: uncompute %15
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 12)    ; IR: uncompute %10 (its consumers %11, %15 done)
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %14, i32 %6, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  %22 = add i64 %8, 4    ; IR: %17 = getelementptr inbounds i8, ptr %5, i64 4  (classical)
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %22)    ; IR: %18 = load i32, ptr %17  [a[1]; measured, so never un-copied]  [result rail r]
  %24 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: call void @free(ptr %5) is nothing (rule 16); %19 = cq_measure_si32(%14)
  %25 = call i32 @cqrt_measure_i32(i32 %21)    ; IR: %20 = cq_measure_si32(%16)
  %26 = add nsw i32 %25, %24    ; IR: %21 = add nsw i32 %20, %19  (classical)
  %27 = call i64 @cqrt_measure_i64(i32 %16)    ; IR: %22 = cq_measure_sl(%11)
  %28 = call i32 @cqrt_measure_i32(i32 %23)    ; IR: %23 = cq_measure_si32(%18)
  %29 = trunc i64 %27 to i32    ; IR: %24 = trunc i64 %22 to i32  (classical)
  %30 = add i32 %26, %29    ; IR: %25 = add i32 %21, %24  (classical)
  %31 = add i32 %30, %28    ; IR: %26 = add i32 %25, %23  (classical)
  ret i32 %31    ; IR: ret i32 %26
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i64 @cqrt_measure_i64(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8(i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_umin_i64_hl(i32, i64)
declare void @cq_template_umin_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)
