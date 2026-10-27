; HAND-WRITTEN. Rules: 2, 4, 5, 7, 9, 18, 20, 21, 26, §1.4.
; Checked: union_ptr_to_int: *u.p + w (measured, %25 -> %26): x odd: a[1] + w = 2 + w; x even: b + 1 + 4 bytes is b's
; cell 2, one past the end, which reads 0 (§2): w. union_int_to_ptr: *u.p = a[x & 3] = w + (x & 3) (measured, %20 ->
; %21). union_slot: *u.p + w (measured, %19 -> %20): x odd: a[1] + w = 2 + w; x even: b[1] + w = 4 + w.
; Clean: in every function every flag, tag/idx, base, flat-address, byte-offset and cell-index rail, the per-object QROM
; loads and their merge; in union_slot also the slot's |0> idx seed (rule 7) and the new idx rail bump's clone stored
; (zeroed by the __cq_q_bump_0011_unc twin, freed by the caller); every clone-internal rail.
; Kept: x (%6 in union_ptr_to_int, %5 in union_int_to_ptr, %7 in union_slot: the rotated user registers) and the three
; measured results.
; Rotations: (Ry, x, th, 1) in each of the three functions.
; A UNION of a pointer and an integer on quantum data. The IR never says "union": with plain code SROA folds the union
; into its value, and the member punning is ptrtoint / inttoptr ON VALUES, i.e. example 89: the fat pointer (tag, idx)
; of 84, idx always a CELL index (rule 21), crosses to the flat address u = base[tag] + 4 * idx (a select over the
; classical bases of the object table plus the byte offset of idx) and back. inttoptr of an integer DERIVED FROM
; ptrtoint(p) keeps p's provenance (rule 21, LLVM's rule): tag = p's tag (the same rail), idx = (u' - base[tag]) / 4
; (sub, lshr by log2 4, trunc to the logical i32 index rail), one-past-the-end included; no range test, so no checked
; value depends on where the host placed the arrays. Only an integer of unknown origin would be decoded by range tests.
; The rebuilt cell index is QUANTUM in all three functions, so every deref is a quantum-offset access of each object in
; the provenance (rule 21). The arrays only ever hold classical values (their -O1 initializers), so by rule 20 each
; access is a QROM read over the object's current contents (cq_template_qrom_load_i32, length = the cell count) and the
; arrays stay ordinary classical memory, never QRAMs. The pure per-object loads run unguarded and are merged by one
; select on the object flag g_a = tag == 1 (provenance {a, b}: b is the complement, innermost; rule 9).
; union_ptr_to_int: p = (x & 1) ? a : b + 1 is (select(x & 1 == 0, 2, 1), select(x & 1 == 0, 1, 0)): b + 1 is b's cell
; 1; ptrtoint, + 4, inttoptr gives idx + 1 in the same object: a's cell 1, or b's cell 2 = one past the end of b (the
; program's own UB at the deref; the QROM reads 0 out of range, §2). union_int_to_ptr: the integer is derived from
; ptrtoint(a) (or disjoint a quantum byte offset), so the pointer is a's (tag 1, classical) with the quantum cell idx
; ((u - base[1]) >> 2); one object and a classical tag: one QROM load, no guard, no merge; it is the measured result.
; union_slot: the union's address escapes to a callee, so the union stays an alloca: a SLOT (rule 20: it holds handles
; and is only accessed at classical offsets) whose cell is of POINTER KIND (its defining store is a store ptr) and holds a
; fat pointer, i.e. TWO HANDLES (tag, idx; the classical cell idx 0 becomes a |0> seed rail because a cell holds
; handles, rule 20). A cell's kind is fixed by its defining store; a mismatched access converts at the access: a load of
; an integer from a pointer-kind cell is a ptrtoint AT THE LOAD, a store of an integer into it is an inttoptr AT THE STORE
; (so the cell keeps holding a pair and the caller's load ptr needs no conversion). bump's i64 is derived from the
; ptrtoint at its load, so the store keeps that pointer's provenance: the tag handle stays in the cell, and the new idx
; is ((base[T] + 4 * I) + 4 - base[T]) / 4. The derived integer is carried as its provenance plus the byte offset 4 * I
; (rule 21's addr - base[tag]); base[T] is never materialised because the integer is never observed as a number (no
; compare, mask or print reads it). bump's argument &u crosses the clone boundary as the rule-21 triple (object u, tag 3,
; cell idx 0): u is object 3 of union_slot's table (a = 1, b = 2), one object, so the object component is the host
; pointer of u itself and NO object table is passed (rule 21: the provenance is one object and the callee needs no base,
; since base[T] cancels between the ptrtoint at the load and the inttoptr at the store). Mask per §1.4: tag 0, idx 0
; (classical; the object gets no digit), then one digit per pointee cell the callee accesses, the cell's tag and idx
; halves, both handles at the call: __cq_q_bump_0011. The clone stores the new idx
; rail into the slot; its _unc twin takes (args..., old slot handles in slot order) = (object, tag, idx, old tag, old
; idx) per §1.4 (no outs: a void callee), recomputes the new idx from the old one, zeroes it and restores the slot. The
; clones never touch the arrays.
source_filename = "pointer_int_union.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @union_ptr_to_int(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [2 x i32], align 8    ; IR: %4 = alloca [2 x i32]  (object 1: a, classical memory: holds only classical values; base[1] = its host address)
  %5 = alloca [2 x i32], align 8    ; IR: %5 = alloca [2 x i32]  (object 2: b, classical memory; base[2])
  store i64 8589934593, ptr %4, align 8    ; IR: store i64 8589934593, ptr %4  (a = {1, 2}, classical)
  store i64 17179869187, ptr %5, align 8    ; IR: store i64 17179869187, ptr %5  (b = {3, 4}, classical)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = ptrtoint ptr %4 to i64    ; IR: base[1] = &a  (classical, from the object table)
  %8 = ptrtoint ptr %5 to i64    ; IR: base[2] = &b  (classical)
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %7 = and i32 %6, 1
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %11 = call i32 @cq_template_select_i32_ll(i32 %10, i32 2, i32 1)    ; IR: %10 = select i1 %8, ptr %9, ptr %4  [the pointer's tag: b (2) or a (1)]
  %12 = call i32 @cq_template_select_i32_ll(i32 %10, i32 1, i32 0)    ; IR: %10: its cell idx: %9 = b + 1 is cell 1, a is cell 0
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 1)    ; IR: %11 = ptrtoint ptr %10 to i64: the object flag g_a = tag == 1 (else b)
  %14 = call i32 @cq_template_select_i64_ll(i32 %13, i64 %7, i64 %8)    ; IR: %11: base[tag] (base[1] when a, else base[2])
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %12)    ; IR: %11: the cell idx widened
  %16 = call i32 @cq_template_shl_i64_hl(i32 %15, i64 2)    ; IR: %11: its byte offset 4 * idx
  %17 = call i32 @cq_template_add_i64(i32 %14, i32 %16)    ; IR: %11 = base[tag] + 4 * idx  [the flat address: u.v]
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 4)    ; IR: %12 = add i64 %11, 4  (u.v += 4)
  %19 = call i32 @cq_template_sub_i64(i32 %18, i32 %14)    ; IR: %13 = inttoptr i64 %12 to ptr: provenance of %10 (tag %10's rail); byte offset = %12 - base[tag]
  %20 = call i32 @cq_template_lshr_i64_hl(i32 %19, i64 2)    ; IR: %13: the byte offset rescaled to the CELL index (lshr by log2 of the i32 cell width)
  %21 = call i32 @cq_template_trunc_i64_to_i32(i32 %20)    ; IR: %13: as the logical i32 index rail  [u.p = (tag %10, this idx)]
  %22 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 2, i32 %21)    ; IR: %14 = load i32, ptr %13 in a: a[idx], a QROM over the classical array (quantum index)
  %23 = call i32 @cq_template_qrom_load_i32(ptr %5, i64 2, i32 %21)    ; IR: %14 in b: b[idx], a QROM (idx 2 = one past the end reads 0, §2)
  %24 = call i32 @cq_template_select_i32(i32 %13, i32 %22, i32 %23)    ; IR: %14 = load i32, ptr %13: g_a ? a[idx] : b[idx]  [the load: the per-object merge]
  %25 = call i32 @cq_template_add_i32_hl(i32 %24, i32 %2)    ; IR: %15 = add nsw i32 %14, %2  [result rail]
  call void @cq_template_select_i32_unc(i32 %24, i32 %13, i32 %22, i32 %23)    ; IR: uncompute the merged load %14
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %23, ptr %5, i64 2, i32 %21)    ; IR: uncompute object b's read
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %22, ptr %4, i64 2, i32 %21)    ; IR: uncompute object a's read
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %21, i32 %20)    ; IR: uncompute the cell idx
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %20, i32 %19, i64 2)    ; IR: uncompute the rescale
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_sub_i64_unc(i32 %19, i32 %18, i32 %14)    ; IR: uncompute the byte offset
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %18)    ; IR: release the %12 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %17, i32 %14, i32 %16)    ; IR: uncompute %11
  call void @cqrt_free(i32 %17)    ; IR: release the %11 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %16, i32 %15, i64 2)    ; IR: uncompute the byte offset of idx
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %12)    ; IR: uncompute its widening
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %14, i32 %13, i64 %7, i64 %8)    ; IR: uncompute base[tag]
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %11, i32 1)    ; IR: uncompute the object flag g_a
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %10, i32 1, i32 0)    ; IR: uncompute the pointer's idx
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %11, i32 %10, i32 2, i32 1)    ; IR: uncompute the pointer's tag %10
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %26 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %26    ; IR: ret i32 %16
}

define i32 @union_int_to_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [4 x i32], align 16    ; IR: %4 = alloca [4 x i32]  (object 1: a, 16 bytes, classical memory: holds only classical values; base[1] = its host address)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  store i32 %2, ptr %4, align 16    ; IR: store i32 %2, ptr %4  (a[0] = w, classical)
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %6 = &a[1]
  %7 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  store i32 %7, ptr %6, align 4    ; IR: store i32 %7, ptr %6  (a[1])
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %8 = &a[2]
  %9 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  store i32 %9, ptr %8, align 8    ; IR: store i32 %9, ptr %8  (a[2])
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; IR: %10 = &a[3]
  %11 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  store i32 %11, ptr %10, align 4    ; IR: store i32 %11, ptr %10  (a[3])
  %12 = ptrtoint ptr %4 to i64    ; IR: %12 = ptrtoint ptr %4 to i64  (classical: base[1] = &a)
  %13 = call i32 @cq_template_shl_i32_hl(i32 %5, i32 2)    ; IR: %13 = shl i32 %5, 2
  %14 = call i32 @cq_template_and_i32_hl(i32 %13, i32 12)    ; IR: %14 = and i32 %13, 12
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)    ; IR: %15 = zext nneg i32 %14 to i64
  %16 = call i32 @cq_template_or_i64_hl(i32 %15, i64 %12)    ; IR: %16 = or disjoint i64 %15, %12  [u.v: a flat address derived from ptrtoint(a), quantum]
  %17 = call i32 @cq_template_sub_i64_hl(i32 %16, i64 %12)    ; IR: %17 = inttoptr i64 %16 to ptr: provenance of %4 (tag 1, classical); byte offset = %16 - base[1]
  %18 = call i32 @cq_template_lshr_i64_hl(i32 %17, i64 2)    ; IR: %17: the byte offset rescaled to the CELL index (lshr by log2 of the i32 cell width)
  %19 = call i32 @cq_template_trunc_i64_to_i32(i32 %18)    ; IR: %17: as the logical i32 index rail  [u.p = (tag 1, this idx)]
  %20 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 4, i32 %19)    ; IR: %18 = load i32, ptr %17: a[idx], a QROM over the classical array (quantum index; one object, classical tag: no guard)  [the load; the result rail]
  call void @cq_template_trunc_i64_to_i32_unc(i32 %19, i32 %18)    ; IR: uncompute the cell idx
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %18, i32 %17, i64 2)    ; IR: uncompute the rescale
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_sub_i64_hl_unc(i32 %17, i32 %16, i64 %12)    ; IR: uncompute the byte offset
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %16, i32 %15, i64 %12)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %13, i32 12)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %13, i32 %5, i32 2)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  %21 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %21    ; IR: ret i32 %19
}

define i32 @union_slot(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [2 x i32], align 8    ; IR: %4 = alloca [2 x i32]  (object 1: a, classical memory: holds only classical values)
  %5 = alloca [2 x i32], align 8    ; IR: %5 = alloca [2 x i32]  (object 2: b, classical memory)
  %6 = alloca { i32, i32 }, align 8    ; IR: %6 = alloca %union.pv  (object 3: the slot u, one pointer-kind cell = two handles, tag and idx; not a QRAM: only classical offsets reach it)
  store i64 8589934593, ptr %4, align 8    ; IR: store i64 8589934593, ptr %4  (a = {1, 2}, classical)
  store i64 17179869187, ptr %5, align 8    ; IR: store i64 17179869187, ptr %5  (b = {3, 4}, classical)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)    ; IR: %8 = and i32 %7, 1
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)    ; IR: %9 = icmp eq i32 %8, 0
  %10 = call i32 @cq_template_select_i32_ll(i32 %9, i32 2, i32 1)    ; IR: %10 = select i1 %9, ptr %5, ptr %4  [the pointer's tag: b (2) or a (1)]
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %10: its cell idx, the classical 0 as a |0> seed rail (the cell holds handles, rule 20)
  store i32 %10, ptr %6, align 8    ; IR: store ptr %10, ptr %6: the tag handle into the slot
  %12 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: the slot's idx half
  store i32 %11, ptr %12, align 4    ; IR: store ptr %10, ptr %6: the idx handle into the slot
  call fastcc void @__cq_q_bump_0011(ptr %6, i32 3, i32 0)    ; IR: call @bump(%6): clone, &u as the rule-21 triple (object u, tag 3, cell idx 0); mask 0011: tag and idx classical, the accessed cell's two handles quantum
  %13 = load i32, ptr %6, align 8    ; IR: %11 = load ptr, ptr %6: the tag handle in the slot (unchanged: %10; no gate)
  %14 = load i32, ptr %12, align 4    ; IR: %11: the new idx handle the clone stored (no gate)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 1)    ; IR: %12 = load i32, ptr %11: the object flag g_a = tag == 1 (else b)
  %16 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 2, i32 %14)    ; IR: %12 in a: a[idx], a QROM over the classical array (quantum index)
  %17 = call i32 @cq_template_qrom_load_i32(ptr %5, i64 2, i32 %14)    ; IR: %12 in b: b[idx], a QROM over the classical array
  %18 = call i32 @cq_template_select_i32(i32 %15, i32 %16, i32 %17)    ; IR: %12 = load i32, ptr %11: g_a ? a[idx] : b[idx]  [the load: the per-object merge]
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %2)    ; IR: %13 = add nsw i32 %12, %2  [result rail]
  call void @cq_template_select_i32_unc(i32 %18, i32 %15, i32 %16, i32 %17)    ; IR: uncompute the merged load %12
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %17, ptr %5, i64 2, i32 %14)    ; IR: uncompute object b's read
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %16, ptr %4, i64 2, i32 %14)    ; IR: uncompute object a's read
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %13, i32 1)    ; IR: uncompute g_a
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call fastcc void @__cq_q_bump_0011_unc(ptr %6, i32 3, i32 0, i32 %10, i32 %11)    ; IR: uncompute the call: twin (args..., old slot handles in slot order): zero the new idx from the old one, restore the slot
  call void @cqrt_free(i32 %14)    ; IR: release the new idx rail (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the idx seed of %10 (never written, |0>; rule 7)
  call void @cq_template_select_i32_ll_unc(i32 %10, i32 %9, i32 2, i32 1)    ; IR: uncompute the pointer's tag %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %14 = cq_measure_si32(%13)
  ret i32 %20    ; IR: ret i32 %14
}

define internal fastcc void @__cq_q_bump_0011(ptr %0, i32 %1, i32 %2) {
  %4 = getelementptr inbounds { i32, i32 }, ptr %0, i32 %2    ; IR: %0: cell idx of object u (tag %1 = 3, classical; the one object of the triple)
  %5 = load i32, ptr %4, align 8    ; IR: %2 = load i64, ptr %0: the cell is of pointer kind: its tag handle T (no gate; stays in the cell)
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: the cell's idx half
  %7 = load i32, ptr %6, align 4    ; IR: %2: its idx handle I (no gate)
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)    ; IR: %2 = ptrtoint at the load: base[T] + 4 * I, carried as provenance T plus the byte offset: I widened
  %9 = call i32 @cq_template_shl_i64_hl(i32 %8, i64 2)    ; IR: %2: the byte offset 4 * I (= %2 - base[T])
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 4)    ; IR: %3 = add i64 %2, 4: the byte offset of %3 (= %3 - base[T])
  %11 = call i32 @cq_template_lshr_i64_hl(i32 %10, i64 2)    ; IR: store i64 %3, ptr %0: inttoptr at the store keeps the provenance T; idx = (%3 - base[T]) >> 2
  %12 = call i32 @cq_template_trunc_i64_to_i32(i32 %11)    ; IR: store i64 %3: as the logical i32 index rail  [the new idx rail]
  store i32 %12, ptr %6, align 4    ; IR: store i64 %3, ptr %0: the new idx handle into the cell (the tag T stays)
  call void @cq_template_lshr_i64_hl_unc(i32 %11, i32 %10, i64 2)    ; IR: uncompute the rescale
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 4)    ; IR: uncompute %3's offset
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %9, i32 %8, i64 2)    ; IR: uncompute %2's offset
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute the widening
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  ret void    ; IR: ret void  (the cell holds (T, new idx); the old idx stays the caller's)
}

define internal fastcc void @__cq_q_bump_0011_unc(ptr %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = getelementptr inbounds { i32, i32 }, ptr %0, i32 %2    ; IR: the cell (%3, %4: the old tag and idx handles, in slot order, passed by the caller)
  %7 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: the cell's idx half
  %8 = load i32, ptr %7, align 4    ; IR: the new idx handle in the cell (no gate)
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %4)    ; IR: recompute the widening from the old idx
  %10 = call i32 @cq_template_shl_i64_hl(i32 %9, i64 2)    ; IR: recompute %2's offset
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 4)    ; IR: recompute %3's offset
  %12 = call i32 @cq_template_lshr_i64_hl(i32 %11, i64 2)    ; IR: recompute the rescale
  call void @cq_template_trunc_i64_to_i32_unc(i32 %8, i32 %12)    ; IR: zero the new idx rail; the caller frees it
  call void @cq_template_lshr_i64_hl_unc(i32 %12, i32 %11, i64 2)    ; IR: uncompute the rescale
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 4)    ; IR: uncompute %3's offset
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %10, i32 %9, i64 2)    ; IR: uncompute %2's offset
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %4)    ; IR: uncompute the widening
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  store i32 %3, ptr %6, align 8    ; IR: restore the cell: the old tag handle
  store i32 %4, ptr %7, align 4    ; IR: restore the cell: the old idx handle
  ret void    ; IR: ret void
}

declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_or_i64_hl(i32, i64)
declare void @cq_template_or_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_sub_i64(i32, i32)
declare void @cq_template_sub_i64_unc(i32, i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
