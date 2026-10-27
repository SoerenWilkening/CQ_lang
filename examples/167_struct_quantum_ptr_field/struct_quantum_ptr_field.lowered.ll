; HAND-WRITTEN. Rules: 21, 26, 20, 9, 4, 5, 2.
; Checked: n.p[n.w] (measured).
; Clean: the compare flag, n.p's tag rail, n.w, the object guard g_A, both QROM loads.
; Kept: the register x (frozen) and the measured merge rail.
; Rotations: Ry(tx) on x.
; `struct node n = { (x > k) ? bufA : bufB, x & 3 }` never reaches memory (-O1 scalarises it), so by rule 26 the struct
; is the TUPLE of its fields: n.p is a QUANTUM POINTER, i.e. a fat pointer (tag, idx) (rule 21) with tag the rail
; select(x > k, 1, 2) over the function's object table (bufA = 1, bufB = 2) and idx the classical cell 0 of the base;
; n.w is the rail x & 3. The index of n.p[n.w] is idx + n.w = the n.w rail itself (adding the classical 0 emits
; nothing; -O1's zext to i64 and the gep's 4-byte scaling are address arithmetic, never emitted). That index is
; QUANTUM, so the dereference is a quantum-offset access of each object in the provenance (rule 21); bufA and bufB only
; ever hold classical values (a, a + 1, ...; b, b + 1, ...), so by rule 20 each access is a QROM read over the object's
; current contents (cq_template_qrom_load_i32, length 4), not a QRAM: the buffers stay ordinary classical memory with
; their -O1 initializer stores. The per-object loads are pure and run unguarded; the guard g_A = tag == 1 merges them by
; ONE select with the complement object bufB innermost (rule 9; the provenance {bufA, bufB} is exhaustive). The select
; is the measured result. Everything else is uncomputed LIFO: the loads, the guard, n.w, the tag and its flag.
source_filename = "struct_quantum_ptr_field.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @struct_quantum_ptr_field(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = alloca [4 x i32], align 16    ; IR: %6 = alloca [4 x i32]  (object 1: bufA, classical memory: holds only classical values)
  %7 = alloca [4 x i32], align 16    ; IR: %7 = alloca [4 x i32]  (object 2: bufB, classical memory)
  store i32 %3, ptr %6, align 16    ; IR: store i32 %3, ptr %6  (bufA[0] = a, classical)
  %8 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %8
  %9 = add nsw i32 %3, 1    ; IR: %9 = add nsw i32 %3, 1  (classical)
  store i32 %9, ptr %8, align 4    ; IR: store i32 %9, ptr %8  (bufA[1])
  %10 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %10
  %11 = add nsw i32 %3, 2    ; IR: %11 = add nsw i32 %3, 2  (classical)
  store i32 %11, ptr %10, align 8    ; IR: store i32 %11, ptr %10  (bufA[2])
  %12 = getelementptr inbounds i8, ptr %6, i64 12    ; IR: %12
  %13 = add nsw i32 %3, 3    ; IR: %13 = add nsw i32 %3, 3  (classical)
  store i32 %13, ptr %12, align 4    ; IR: store i32 %13, ptr %12  (bufA[3])
  store i32 %4, ptr %7, align 16    ; IR: store i32 %4, ptr %7  (bufB[0] = b, classical)
  %14 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %14
  %15 = add nsw i32 %4, 1    ; IR: %15 = add nsw i32 %4, 1  (classical)
  store i32 %15, ptr %14, align 4    ; IR: store i32 %15, ptr %14  (bufB[1])
  %16 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %16
  %17 = add nsw i32 %4, 2    ; IR: %17 = add nsw i32 %4, 2  (classical)
  store i32 %17, ptr %16, align 8    ; IR: store i32 %17, ptr %16  (bufB[2])
  %18 = getelementptr inbounds i8, ptr %7, i64 12    ; IR: %18
  %19 = add nsw i32 %4, 3    ; IR: %19 = add nsw i32 %4, 3  (classical)
  store i32 %19, ptr %18, align 4    ; IR: store i32 %19, ptr %18  (bufB[3])
  %20 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %20 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %20, double %1)    ; IR: %20 = cq_theta_si32(%0, %1)  [Ry]
  %21 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %20, i32 %2)    ; IR: %21 = icmp sgt i32 %20, %2  [the select's flag]
  %22 = call i32 @cq_template_select_i32_ll(i32 %21, i32 1, i32 2)    ; IR: %22 = select i1 %21, ptr %6, ptr %7  [n.p's TAG: bufA (1) or bufB (2); its idx is the classical cell 0]
  %23 = call i32 @cq_template_and_i32_hl(i32 %20, i32 3)    ; IR: %23 = and i32 %20, 3  [n.w; also n.p[n.w]'s cell index 0 + n.w: %24 = zext and the gep %25 are not emitted]
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 1)    ; IR: %26 = load i32, ptr %25: guard g_A = tag == 1 (the block predicate is true)
  %25 = call i32 @cq_template_qrom_load_i32(ptr %6, i64 4, i32 %23)    ; IR: %26: bufA[n.w], a QROM over the classical buffer (quantum index, classical contents)
  %26 = call i32 @cq_template_qrom_load_i32(ptr %7, i64 4, i32 %23)    ; IR: %26: bufB[n.w], a QROM over the classical buffer
  %27 = call i32 @cq_template_select_i32(i32 %24, i32 %25, i32 %26)    ; IR: %26 = load i32, ptr %25: g_A ? bufA[n.w] : bufB[n.w]  [the per-object merge; result rail]
  call void @cq_template_qrom_load_i32_unc(i32 %26, ptr %7, i64 4, i32 %23)    ; IR: uncompute bufB's read
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %25, ptr %6, i64 4, i32 %23)    ; IR: uncompute bufA's read
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %22, i32 1)    ; IR: uncompute g_A
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %20, i32 3)    ; IR: uncompute %23 (n.w)
  call void @cqrt_free(i32 %23)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %22, i32 %21, i32 1, i32 2)    ; IR: uncompute n.p's tag %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %21, i32 %20, i32 %2)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  %28 = call i32 @cqrt_measure_i32(i32 %27)    ; IR: %27 = cq_measure_si32(%26)
  ret i32 %28    ; IR: ret i32 %27
}

declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
