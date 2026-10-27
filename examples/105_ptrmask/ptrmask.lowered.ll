; HAND-WRITTEN. Rules: 21, 20, 4, 5, 2.
; Checked: *q + *r (measured), q = align_down(&a[x & 7], 16), r = align_down(&a[x & 7] + 12 bytes, 16). With c = x & 7:
; q is cell c & 4 and r is cell (c + 3) & -4 (0, 4 or 8 = one past the end, which reads 0, §2), so *q + *r = 2v (c = 0),
; 2v + 4 (c = 1..3), 2v + 8 (c = 4), v + 4 (c = 5..7). The values never depend on the host address of a.
; Clean: every pointer-arithmetic rail (byte offsets, flat addresses, masked addresses, rebuilt byte offsets, cell
; indices) and both QROM loads.
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x.
; `llvm.ptrmask(p, m)` (clang's __builtin_align_down / __builtin_align_up, and the and-of-ptrtoint idiom when clang
; recognises it) masks the FLAT ADDRESS of a pointer, so on a fat pointer (84, rule 21) it is 89's round trip:
; materialise u = base[tag] + 4 * idx, `and` the mask, and rebuild. The masked integer is DERIVED FROM ptrtoint(p), so
; the rebuilt pointer keeps p's provenance (rule 21; ptrmask is provenance-preserving in LLVM): tag = p's tag, idx =
; (u' - base[tag]) / 4, one-past-the-end included; no range test, so nothing depends on where the host placed a. Object
; table: object 1 = a (%4), 32 bytes, align 16, 8 i32 cells. p = a + (x & 7) has the CLASSICAL tag 1 (one object) and the
; quantum cell idx x & 7 (the GEP's zext and scaling are address arithmetic, never emitted); %24's 12-byte offset is 3
; i32 cells. The byte form exists only inside the flat-address crossing: idx to a byte offset (zext, shl by log2 4), add
; base[1], mask, subtract base[1], back to a cell index (lshr 2, trunc to the logical i32 index rail). Since a is
; 16-aligned the masked address lands on a[0] or a[4] for q, and on a[0], a[4] or a + 32 (cell 8, one past the end:
; the align-up of a + 20..28) for r; the latter is a pointer of a with idx 8, and its deref is the program's own
; undefined behaviour, which the QROM reads as 0 (an out-of-range index, §2). The rebuilt idx is QUANTUM and the tag the
; classical 1, so each deref is a quantum-offset access of a alone (rule 21: no guard, no merge); a only ever holds the
; classical values v + j, so by rule 20 the access is a QROM read over its current contents (cq_template_qrom_load_i32,
; length 8) and a stays ordinary classical memory with its -O1 initializer stores, never a QRAM. A compiler that reads
; the alignment off the object table may equally lower such a mask as the cell-index mask idx' = idx & (m >> 2) = idx & -4
; with the tag unchanged (a fact of the table, not a peephole); the general route is shown. Everything is uncomputed in
; reverse.
source_filename = "ptrmask.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptrmask_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [8 x i32], align 16    ; IR: %4 = alloca [8 x i32]  (object 1: a, classical memory: holds only classical values; base[1] = its host address)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  store i32 %2, ptr %4, align 16    ; IR: store i32 %2, ptr %4  (a[0] = v, classical)
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %6 = &a[1]
  %7 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  store i32 %7, ptr %6, align 4    ; IR: store i32 %7, ptr %6  (a[1])
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %8 = &a[2]
  %9 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  store i32 %9, ptr %8, align 8    ; IR: store i32 %9, ptr %8  (a[2])
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; IR: %10 = &a[3]
  %11 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  store i32 %11, ptr %10, align 4    ; IR: store i32 %11, ptr %10  (a[3])
  %12 = getelementptr inbounds i8, ptr %4, i64 16    ; IR: %12 = &a[4]
  %13 = add nsw i32 %2, 4    ; IR: %13 = add nsw i32 %2, 4  (classical)
  store i32 %13, ptr %12, align 16    ; IR: store i32 %13, ptr %12  (a[4])
  %14 = getelementptr inbounds i8, ptr %4, i64 20    ; IR: %14 = &a[5]
  %15 = add nsw i32 %2, 5    ; IR: %15 = add nsw i32 %2, 5  (classical)
  store i32 %15, ptr %14, align 4    ; IR: store i32 %15, ptr %14  (a[5])
  %16 = getelementptr inbounds i8, ptr %4, i64 24    ; IR: %16 = &a[6]
  %17 = add nsw i32 %2, 6    ; IR: %17 = add nsw i32 %2, 6  (classical)
  store i32 %17, ptr %16, align 8    ; IR: store i32 %17, ptr %16  (a[6])
  %18 = getelementptr inbounds i8, ptr %4, i64 28    ; IR: %18 = &a[7]
  %19 = add nsw i32 %2, 7    ; IR: %19 = add nsw i32 %2, 7  (classical)
  store i32 %19, ptr %18, align 4    ; IR: store i32 %19, ptr %18  (a[7])
  %20 = ptrtoint ptr %4 to i64    ; IR: base[1] = &a  (classical, from the object table)
  %21 = call i32 @cq_template_and_i32_hl(i32 %5, i32 7)    ; IR: %20 = and i32 %5, 7  [p = (tag 1, idx = this CELL index): %22 = getelementptr i32, ptr %4, i64 %21; the zext %21 and the scaling by 4 are not emitted]
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %23 = llvm.ptrmask(%22, -16): the flat-address crossing converts p's cell index to a byte offset (rule 21)
  %23 = call i32 @cq_template_shl_i64_hl(i32 %22, i64 2)    ; IR: %23 = llvm.ptrmask(%22, -16): byte offset = idx * 4 (i32 cells)
  %24 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %20)    ; IR: %23 = llvm.ptrmask(%22, -16): u = base[1] + byte offset  (the flat address, 89)
  %25 = call i32 @cq_template_and_i64_hl(i32 %24, i64 -16)    ; IR: %23 = llvm.ptrmask(%22, -16): u & -16
  %26 = call i32 @cq_template_sub_i64_hl(i32 %25, i64 %20)    ; IR: %23 = llvm.ptrmask(%22, -16): provenance of %22 (tag 1, classical): (u & -16) - base[1]
  %27 = call i32 @cq_template_lshr_i64_hl(i32 %26, i64 2)    ; IR: %23 = llvm.ptrmask(%22, -16): the byte difference converted back to a cell index (lshr by log2 of the i32 cell width)
  %28 = call i32 @cq_template_trunc_i64_to_i32(i32 %27)    ; IR: %23 = llvm.ptrmask(%22, -16): as the logical i32 index rail  [q = (tag 1, this idx)]
  %29 = call i32 @cq_template_add_i32_hl(i32 %21, i32 3)    ; IR: %24 = getelementptr i8, ptr %22, i64 12: 12 bytes = 3 i32 cells, so idx + 3 (tag 1)
  %30 = call i32 @cq_template_zext_i32_to_i64(i32 %29)    ; IR: %25 = llvm.ptrmask(%24, -16): cell index to byte offset at the flat-address crossing
  %31 = call i32 @cq_template_shl_i64_hl(i32 %30, i64 2)    ; IR: %25 = llvm.ptrmask(%24, -16): byte offset = idx * 4
  %32 = call i32 @cq_template_add_i64_hl(i32 %31, i64 %20)    ; IR: %25 = llvm.ptrmask(%24, -16): u = base[1] + byte offset
  %33 = call i32 @cq_template_and_i64_hl(i32 %32, i64 -16)    ; IR: %25 = llvm.ptrmask(%24, -16): u & -16
  %34 = call i32 @cq_template_sub_i64_hl(i32 %33, i64 %20)    ; IR: %25 = llvm.ptrmask(%24, -16): provenance of %24 (tag 1): (u & -16) - base[1]
  %35 = call i32 @cq_template_lshr_i64_hl(i32 %34, i64 2)    ; IR: %25 = llvm.ptrmask(%24, -16): byte difference to cell index
  %36 = call i32 @cq_template_trunc_i64_to_i32(i32 %35)    ; IR: %25 = llvm.ptrmask(%24, -16): as the logical i32 index rail  [r = (tag 1, this idx); 8 = one past the end]
  %37 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 8, i32 %28)    ; IR: %26 = load i32, ptr %23: a[q.idx], a QROM over the classical array (quantum index; tag 1 classical: no guard)  [the load *q]
  %38 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 8, i32 %36)    ; IR: %27 = load i32, ptr %25: a[r.idx], a QROM (index 8 is out of range: reads 0, §2)  [the load *r]
  %39 = call i32 @cq_template_add_i32(i32 %38, i32 %37)    ; IR: %28 = add nsw i32 %27, %26  [result rail]
  call void @cq_template_qrom_load_i32_unc(i32 %38, ptr %4, i64 8, i32 %36)    ; IR: uncompute a[r.idx]
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %37, ptr %4, i64 8, i32 %28)    ; IR: uncompute a[q.idx]
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %36, i32 %35)    ; IR: uncompute r's idx
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %35, i32 %34, i64 2)    ; IR: uncompute the byte-to-cell conversion
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_sub_i64_hl_unc(i32 %34, i32 %33, i64 %20)    ; IR: uncompute the difference
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %33, i32 %32, i64 -16)    ; IR: uncompute the masked address
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %32, i32 %31, i64 %20)    ; IR: uncompute r's flat address
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %31, i32 %30, i64 2)    ; IR: uncompute r's byte offset
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %30, i32 %29)    ; IR: uncompute its widening
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %29, i32 %21, i32 3)    ; IR: uncompute %24's cell index
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %28, i32 %27)    ; IR: uncompute q's idx
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %27, i32 %26, i64 2)    ; IR: uncompute the byte-to-cell conversion
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_sub_i64_hl_unc(i32 %26, i32 %25, i64 %20)    ; IR: uncompute the difference
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %25, i32 %24, i64 -16)    ; IR: uncompute the masked address
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %23, i64 %20)    ; IR: uncompute q's flat address
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %23, i32 %22, i64 2)    ; IR: uncompute p's byte offset
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)    ; IR: uncompute its widening
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %5, i32 7)    ; IR: uncompute %20 (p's cell index)
  call void @cqrt_free(i32 %21)    ; IR: release the %20 rail (|0>)
  %40 = call i32 @cqrt_measure_i32(i32 %39)    ; IR: %29 = cq_measure_si32(%28)
  ret i32 %40    ; IR: ret i32 %29
}

declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
