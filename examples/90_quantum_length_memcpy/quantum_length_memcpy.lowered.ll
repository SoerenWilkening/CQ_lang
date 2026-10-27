; HAND-WRITTEN. Rules: 22, 20, 21, 9, 7, 4, 5.
; Checked: memcpy_quantum_len: d[0] + d[3] (the result rail, measured). memcpy_quantum_src: d[0] + d[1] (the result
; rail, measured).
; Clean: every rail but the register and the result: the length rails n, m (and x >> 2), the per-cell guards, every
; per-cell select rail (the slot gets the handle it held before back), the source-object flag and the merged source byte,
; the tag and length selects, the two zexts of the reads, and the per-cell initializer seeds 9 (never written: freed
; directly, rule 7).
; Kept: the register x of each function (rotated) and each result rail (measured).
; Rotations: memcpy_quantum_len: (Ry, x, th, 1). memcpy_quantum_src: (Ry, x, th, 1).
; Rule 20: d is never accessed at a QUANTUM OFFSET (the intrinsics write fixed cells j, the reads are d[0], d[3] / d[0],
; d[1]), so it is not a QRAM; it may hold a handle (the quantum-length intrinsics make its cells quantum), so it is a SLOT
; ARRAY: a classical array of handles, one 4-byte slot per CELL. The cell is the element type, unsigned char, so -O1's
; punned initializer store (i32 151587081 / i16 2313) is one store per byte cell and its byte-offset GEPs are cell
; indices (size 1). Slot cells are homogeneous (rule 20): each cell holds a handle from the start, the classical 9 as a
; basis-state seed alloc_i8(9) per cell (rule 7; no cell is ever written in place, rule 4).
; Rule 22: llvm.memcpy / llvm.memset with a QUANTUM LENGTH n (bytes) guard cell j (size 1) by n >= j + 1, i.e. the flag
; n >u j; the guarded cell is select(flag_j, new, old) into a fresh rail (rule 9) and the slot takes the new handle. Only
; cells some execution can touch exist: cell j iff j < the length's upper bound. memcpy_quantum_len: n = x & 3 <= 3 and
; m = (x >> 2) & 3 <= 3 (known bits), so both intrinsics cover cells 0..2, src[3] is never loaded and d[3] keeps its seed.
; A classical source byte is a host load (the select's literal arm, select_i8_lh); the memset fill is the literal 0.
; The length is compared as the logical i32 (-O1's zext to i64 is not emitted, like an index).
; memcpy_quantum_src: the source is a quantum fat pointer (rule 21; object table 1 = d, 2 = s1, 3 = s2; tag rail =
; select(x & 1 == 0, 3, 2), idx the CLASSICAL 0 + j). A quantum tag with a classical idx is a guarded classical-offset
; access of each object in the provenance: s1, s2 are classical memory, so the source byte j is two classical host loads
; merged by select on the flag tag == 2 (complement arm s2 innermost: the provenance is exactly {s1, s2}), never a QRAM
; or QROM. The per-object length bound (rule 22) decides which loads exist: s1 is selected iff n = 2 (cells 0, 1), s2 iff
; n = 1 (cell 0 only), so s2[1] is never loaded and cell 1's new value is s1[1] alone (its guard n >u 1 implies tag ==
; 2). Uncomputation runs LIFO: the reads' zexts, each cell's selects in reverse (each slot store is undone by storing
; the old handle back), the guards, the length and tag chains; the seeds are freed directly.
source_filename = "quantum_length_memcpy.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memcpy_quantum_len(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = alloca [4 x i32], align 4    ; IR: %4 = alloca i32  (d, a slot array of 4 byte cells: one handle per cell)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i32 151587081, ptr %4: d[0] = 9  [seed rail]
  store i32 %6, ptr %4, align 4    ; IR: (slot 0)
  %7 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i32 151587081, ptr %4: d[1] = 9  [seed rail]
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 1
  store i32 %7, ptr %8, align 4    ; IR: (slot 1)
  %9 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i32 151587081, ptr %4: d[2] = 9  [seed rail]
  %10 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 2
  store i32 %9, ptr %10, align 4    ; IR: (slot 2)
  %11 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i32 151587081, ptr %4: d[3] = 9  [seed rail]
  %12 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 3
  store i32 %11, ptr %12, align 4    ; IR: (slot 3)
  %13 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %6 = and i32 %5, 3  [the memcpy length n <= 3: cells 0..2 only (rule 22); the %7 zext is not emitted]
  %14 = load i8, ptr %2, align 1    ; IR: llvm.memcpy(%4, %2, %7): src[0]  (classical host load)
  %15 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 0)    ; IR: memcpy: cell 0 written iff n >u 0
  %16 = call i32 @cq_template_select_i8_lh(i32 %15, i8 %14, i32 %6)    ; IR: memcpy: d[0] = n > 0 ? src[0] : d[0]  [fresh rail]
  store i32 %16, ptr %4, align 4    ; IR: (slot 0 takes the new cell)
  %17 = getelementptr inbounds i8, ptr %2, i64 1    ; IR: memcpy: &src[1]  (classical)
  %18 = load i8, ptr %17, align 1    ; IR: memcpy: src[1]  (classical host load)
  %19 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 1)    ; IR: memcpy: cell 1 written iff n >u 1
  %20 = call i32 @cq_template_select_i8_lh(i32 %19, i8 %18, i32 %7)    ; IR: memcpy: d[1] = n > 1 ? src[1] : d[1]  [fresh rail]
  store i32 %20, ptr %8, align 4    ; IR: (slot 1 takes the new cell)
  %21 = getelementptr inbounds i8, ptr %2, i64 2    ; IR: memcpy: &src[2]  (classical)
  %22 = load i8, ptr %21, align 1    ; IR: memcpy: src[2]  (classical host load)
  %23 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 2)    ; IR: memcpy: cell 2 written iff n >u 2
  %24 = call i32 @cq_template_select_i8_lh(i32 %23, i8 %22, i32 %9)    ; IR: memcpy: d[2] = n > 2 ? src[2] : d[2]  [fresh rail]
  store i32 %24, ptr %10, align 4    ; IR: (slot 2 takes the new cell)
  %25 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 2)    ; IR: %8 = lshr i32 %5, 2
  %26 = call i32 @cq_template_and_i32_hl(i32 %25, i32 3)    ; IR: %9 = and i32 %8, 3  [the memset length m <= 3: cells 0..2 only; the %10 zext is not emitted]
  %27 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %26, i32 0)    ; IR: llvm.memset(%4, 0, %10): cell 0 written iff m >u 0
  %28 = call i32 @cq_template_select_i8_lh(i32 %27, i8 0, i32 %16)    ; IR: memset: d[0] = m > 0 ? 0 : d[0]  [fresh rail]
  store i32 %28, ptr %4, align 4    ; IR: (slot 0 takes the new cell)
  %29 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %26, i32 1)    ; IR: memset: cell 1 written iff m >u 1
  %30 = call i32 @cq_template_select_i8_lh(i32 %29, i8 0, i32 %20)    ; IR: memset: d[1] = m > 1 ? 0 : d[1]  [fresh rail]
  store i32 %30, ptr %8, align 4    ; IR: (slot 1 takes the new cell)
  %31 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %26, i32 2)    ; IR: memset: cell 2 written iff m >u 2
  %32 = call i32 @cq_template_select_i8_lh(i32 %31, i8 0, i32 %24)    ; IR: memset: d[2] = m > 2 ? 0 : d[2]  [fresh rail]
  store i32 %32, ptr %10, align 4    ; IR: (slot 2 takes the new cell)
  %33 = load i32, ptr %4, align 4    ; IR: %11 = load i8, ptr %4: d[0]  (the handle in slot 0, no gate)
  %34 = call i32 @cq_template_zext_i8_to_i32(i32 %33)    ; IR: %12 = zext i8 %11 to i32
  %35 = load i32, ptr %12, align 4    ; IR: %14 = load i8, ptr %13: d[3]  (%13 = &d[3]: cell 3; the handle in slot 3, the seed)
  %36 = call i32 @cq_template_zext_i8_to_i32(i32 %35)    ; IR: %15 = zext i8 %14 to i32
  %37 = call i32 @cq_template_add_i32(i32 %36, i32 %34)    ; IR: %16 = add nuw nsw i32 %15, %12  [result rail]
  call void @cq_template_zext_i8_to_i32_unc(i32 %36, i32 %35)    ; IR: uncompute %15
  call void @cqrt_free(i32 %36)    ; IR: release the %15 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %34, i32 %33)    ; IR: uncompute %12
  call void @cqrt_free(i32 %34)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %32, i32 %31, i8 0, i32 %24)    ; IR: uncompute memset's cell 2
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  store i32 %24, ptr %10, align 4    ; IR: adjoint of the store: slot 2 holds memcpy's cell again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %31, i32 %26, i32 2)    ; IR: uncompute memset's cell-2 guard
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %30, i32 %29, i8 0, i32 %20)    ; IR: uncompute memset's cell 1
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  store i32 %20, ptr %8, align 4    ; IR: adjoint of the store: slot 1 holds memcpy's cell again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %29, i32 %26, i32 1)    ; IR: uncompute memset's cell-1 guard
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %28, i32 %27, i8 0, i32 %16)    ; IR: uncompute memset's cell 0
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  store i32 %16, ptr %4, align 4    ; IR: adjoint of the store: slot 0 holds memcpy's cell again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %27, i32 %26, i32 0)    ; IR: uncompute memset's cell-0 guard
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %26, i32 %25, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %26)    ; IR: release the %9 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %25, i32 %5, i32 2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %25)    ; IR: release the %8 rail (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %24, i32 %23, i8 %22, i32 %9)    ; IR: uncompute memcpy's cell 2
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  store i32 %9, ptr %10, align 4    ; IR: adjoint of the store: slot 2 holds its seed again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %23, i32 %13, i32 2)    ; IR: uncompute memcpy's cell-2 guard
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %20, i32 %19, i8 %18, i32 %7)    ; IR: uncompute memcpy's cell 1
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  store i32 %7, ptr %8, align 4    ; IR: adjoint of the store: slot 1 holds its seed again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %19, i32 %13, i32 1)    ; IR: uncompute memcpy's cell-1 guard
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %16, i32 %15, i8 %14, i32 %6)    ; IR: uncompute memcpy's cell 0
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  store i32 %6, ptr %4, align 4    ; IR: adjoint of the store: slot 0 holds its seed again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %15, i32 %13, i32 0)    ; IR: uncompute memcpy's cell-0 guard
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %5, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %13)    ; IR: release the %6 rail (|0>)
  call void @cqrt_free(i32 %11)    ; IR: llvm.lifetime.end: release the seeds (never written, basis state 9, rule 7)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %7)
  call void @cqrt_free(i32 %6)
  %38 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %38    ; IR: ret i32 %17
}

define i32 @memcpy_quantum_src(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3) {
  %5 = alloca [2 x i32], align 4    ; IR: %5 = alloca i16  (object 1: d, a slot array of 2 byte cells: one handle per cell)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i16 2313, ptr %5: d[0] = 9  [seed rail]
  store i32 %7, ptr %5, align 4    ; IR: (slot 0)
  %8 = call i32 @cqrt_alloc_i8(i8 9)    ; IR: store i16 2313, ptr %5: d[1] = 9  [seed rail]
  %9 = getelementptr inbounds [2 x i32], ptr %5, i64 0, i64 1
  store i32 %8, ptr %9, align 4    ; IR: (slot 1)
  %10 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %7 = and i32 %6, 1
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %12 = call i32 @cq_template_select_i32_ll(i32 %11, i32 3, i32 2)    ; IR: %9 = select i1 %8, ptr %3, ptr %2  [the source pointer's tag: s2 (3) or s1 (2); its idx is the classical 0]
  %13 = call i32 @cq_template_select_i32_ll(i32 %11, i32 1, i32 2)    ; IR: %10 = select i1 %8, i64 1, i64 2  [the length n, as the logical i32: 2 on the s1 path, 1 on the s2 path]
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 2)    ; IR: llvm.memcpy(%5, %9, %10): source object s1 addressed iff tag == 2, else s2
  %15 = load i8, ptr %2, align 1    ; IR: memcpy: s1[0]  (classical memory at the classical offset 0: host load)
  %16 = load i8, ptr %3, align 1    ; IR: memcpy: s2[0]  (classical host load)
  %17 = call i32 @cq_template_select_i8_ll(i32 %14, i8 %15, i8 %16)    ; IR: memcpy: the source byte *s = tag == 2 ? s1[0] : s2[0]  (the guarded loads merged by select)
  %18 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 0)    ; IR: memcpy: cell 0 written iff n >u 0
  %19 = call i32 @cq_template_select_i8(i32 %18, i32 %17, i32 %7)    ; IR: memcpy: d[0] = n > 0 ? s[0] : d[0]  [fresh rail]
  store i32 %19, ptr %5, align 4    ; IR: (slot 0 takes the new cell)
  %20 = getelementptr inbounds i8, ptr %2, i64 1    ; IR: memcpy: &s1[1]
  %21 = load i8, ptr %20, align 1    ; IR: memcpy: s1[1]  (classical host load; only s1 reaches cell 1: n = 1 on every s2 path, so s2[1] is never loaded, rule 22)
  %22 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 1)    ; IR: memcpy: cell 1 written iff n >u 1 (which implies tag == 2)
  %23 = call i32 @cq_template_select_i8_lh(i32 %22, i8 %21, i32 %8)    ; IR: memcpy: d[1] = n > 1 ? s1[1] : d[1]  [fresh rail]
  store i32 %23, ptr %9, align 4    ; IR: (slot 1 takes the new cell)
  %24 = load i32, ptr %5, align 4    ; IR: %11 = load i8, ptr %5: d[0]  (the handle in slot 0, no gate)
  %25 = call i32 @cq_template_zext_i8_to_i32(i32 %24)    ; IR: %12 = zext i8 %11 to i32
  %26 = load i32, ptr %9, align 4    ; IR: %14 = load i8, ptr %13: d[1]  (%13 = &d[1]: cell 1)
  %27 = call i32 @cq_template_zext_i8_to_i32(i32 %26)    ; IR: %15 = zext i8 %14 to i32
  %28 = call i32 @cq_template_add_i32(i32 %27, i32 %25)    ; IR: %16 = add nuw nsw i32 %15, %12  [result rail]
  call void @cq_template_zext_i8_to_i32_unc(i32 %27, i32 %26)    ; IR: uncompute %15
  call void @cqrt_free(i32 %27)    ; IR: release the %15 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %25, i32 %24)    ; IR: uncompute %12
  call void @cqrt_free(i32 %25)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_i8_lh_unc(i32 %23, i32 %22, i8 %21, i32 %8)    ; IR: uncompute cell 1
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  store i32 %8, ptr %9, align 4    ; IR: adjoint of the store: slot 1 holds its seed again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %22, i32 %13, i32 1)    ; IR: uncompute the cell-1 guard
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_select_i8_unc(i32 %19, i32 %18, i32 %17, i32 %7)    ; IR: uncompute cell 0
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  store i32 %7, ptr %5, align 4    ; IR: adjoint of the store: slot 0 holds its seed again
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %18, i32 %13, i32 0)    ; IR: uncompute the cell-0 guard
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_select_i8_ll_unc(i32 %17, i32 %14, i8 %15, i8 %16)    ; IR: uncompute the source byte
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %12, i32 2)    ; IR: uncompute the s1 flag
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %11, i32 1, i32 2)    ; IR: uncompute the length %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %11, i32 3, i32 2)    ; IR: uncompute the source pointer's tag %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %6, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: llvm.lifetime.end: release the seeds (never written, basis state 9, rule 7)
  call void @cqrt_free(i32 %7)
  %29 = call i32 @cqrt_measure_i32(i32 %28)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %29    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i8(i32, i32, i32)
declare void @cq_template_select_i8_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i8_lh(i32, i8, i32)
declare void @cq_template_select_i8_lh_unc(i32, i32, i8, i32)
declare i32 @cq_template_select_i8_ll(i32, i8, i8)
declare void @cq_template_select_i8_ll_unc(i32, i32, i8, i8)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
