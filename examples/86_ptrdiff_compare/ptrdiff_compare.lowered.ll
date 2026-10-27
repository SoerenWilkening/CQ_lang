; HAND-WRITTEN. Rules: 21, 4, 5, 2.
; Checked: ptrdiff_q: q - p in elements (%11 -> %12). ptr_less: p < q (%24 -> %25). ptr_eq_two_objects: p == q (%16 -> %17).
; Clean: every rail but the registers and the result rails: the byte-offset chains of ptrdiff_q (%5..%10), the tag and
; cell-index chains of ptr_less (%6..%12), its base select (%15, %16), its two address chains (%17..%22) and its
; compare %23, the tag and index chains of ptr_eq_two_objects (%6..%12), its two compares and their conjunction
; (%13..%15), all uncomputed in LIFO order and freed. The arrays a, b of ptr_eq_two_objects are classical memory and
; are never touched.
; Kept: the register x of each function (%4 / %5 / %5, rotated) and each result rail (measured).
; Rotations: ptrdiff_q: (Ry, x, th, 1). ptr_less: (Ry, x, th, 1). ptr_eq_two_objects: (Ry, x, th, 1).
; Pointer arithmetic and comparison on fat pointers (tag, idx; example 84), idx a CELL index (rule 21). Three shapes.
; ptrdiff_q: -O1 already folds p = a + i, q = a + j, q - p into integer IR (p's byte offset (x & 3) * 4 = %6, q's byte
; offset ((x >> 2) & 3) * 4 = %8, sub, ashr exact by the stride); no pointer survives, so that IR is lowered as the
; integer ops it is. ptr_less: p is a select of two objects (tag rail) plus the cell index (x >> 1) & 3, q is
; a + ((x >> 3) & 3) (classical tag 1, cell-index rail); the GEPs add the C index expression to the base's idx 0 (the
; zext to i64 and the scaling by sizeof(int) are address arithmetic, never emitted for an access). a and b are
; PARAMETERS, so they may alias (b may point into a's array): the compare is over ADDRESSES (rule 21),
; base[tag] + 4 * idx, the classical bases being the parameter values themselves. p's base is a select_i64_ll on the
; tag (tag == 2 ? b : a, the complement a innermost), q's base the classical a (an _hl literal); the byte offset 4 * idx
; (zext, shl by 2) is emitted here only as part of the address; icmp ult on pointers is the unsigned i64 compare of the
; two addresses. ptr_eq_two_objects: a and b are two distinct local allocations of the function, so icmp eq on pointers
; reduces to tag == tag' AND idx == idx'; pointers into different objects are never equal, which the tag test decides.
; The conjunction is DATA (it is zext'ed into the result), so it is the cq_template_and_i1 form of rule 8, not a flag.
; Object tables: ptr_less: 1 = a (param %2), 2 = b (param %3); ptr_eq_two_objects: 1 = a (%3), 2 = b (%4). No deref
; here, so the objects are never touched.
source_filename = "ptrdiff_compare.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @ptrdiff_q(i32 noundef %0, double noundef %1, ptr nocapture noundef readnone %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 2)    ; IR: %5 = shl i32 %4, 2  (x << 2)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 12)    ; IR: %6 = and i32 %5, 12  (p's byte offset: (x & 3) * 4)
  %7 = call i32 @cq_template_zext_i32_to_i64(i32 %6)    ; IR: %7 = zext nneg i32 %6 to i64
  %8 = call i32 @cq_template_and_i32_hl(i32 %4, i32 12)    ; IR: %8 = and i32 %4, 12  (q's byte offset: ((x >> 2) & 3) * 4)
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %9 = zext nneg i32 %8 to i64
  %10 = call i32 @cq_template_sub_i64(i32 %9, i32 %7)    ; IR: %10 = sub nsw i64 %9, %7  (q - p in bytes: -O1 folded the pointers away)
  %11 = call i32 @cq_template_ashr_i64_hl(i32 %10, i64 2)    ; IR: %11 = ashr exact i64 %10, 2  (in elements)  [result rail]
  call void @cq_template_sub_i64_unc(i32 %10, i32 %9, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %4, i32 12)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 12)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %5, i32 %4, i32 2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %12 = call i64 @cqrt_measure_i64(i32 %11)    ; IR: %12 = cq_measure_sl(%11)
  ret i64 %12    ; IR: ret i64 %12
}

define i32 @ptr_less(i32 noundef %0, double noundef %1, ptr noundef readnone %2, ptr noundef readnone %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)    ; IR: %6 = and i32 %5, 1
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)    ; IR: %7 = icmp eq i32 %6, 0
  %8 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2, i32 1)    ; IR: %8 = select i1 %7, ptr %3, ptr %2  [p.tag: b (2) or a (1); the base's idx is the classical 0]
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 1)    ; IR: %9 = lshr i32 %5, 1
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %10 = and i32 %9, 3  [p.idx: %12 = getelementptr i32, ptr %8, i64 %11 adds the CELL index 0 + %10; the zext %11 and the scaling by 4 are address arithmetic, not emitted]
  %11 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 3)    ; IR: %13 = lshr i32 %5, 3
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 3)    ; IR: %14 = and i32 %13, 3  [q.idx: %16 = getelementptr i32, ptr %2, i64 %15, cell index %14; q.tag is the classical 1: a]
  %13 = ptrtoint ptr %2 to i64    ; IR: base[1] = a  (classical: the parameter's address)
  %14 = ptrtoint ptr %3 to i64    ; IR: base[2] = b  (classical)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 2)    ; IR: %17 = icmp ult ptr %12, %16: p's object is b iff p.tag == 2
  %16 = call i32 @cq_template_select_i64_ll(i32 %15, i64 %14, i64 %13)    ; IR: %17: base[p.tag] = b when tag == 2, else a
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %10)    ; IR: %17: p.idx widened (address arithmetic, emitted only for the compare)
  %18 = call i32 @cq_template_shl_i64_hl(i32 %17, i64 2)    ; IR: %17: p's byte offset 4 * p.idx
  %19 = call i32 @cq_template_add_i64(i32 %16, i32 %18)    ; IR: %17: p's address base[p.tag] + 4 * p.idx
  %20 = call i32 @cq_template_zext_i32_to_i64(i32 %12)    ; IR: %17: q.idx widened
  %21 = call i32 @cq_template_shl_i64_hl(i32 %20, i64 2)    ; IR: %17: q's byte offset 4 * q.idx
  %22 = call i32 @cq_template_add_i64_hl(i32 %21, i64 %13)    ; IR: %17: q's address a + 4 * q.idx (q.tag is the classical 1)
  %23 = call i32 @cq_template_icmp_ult_i64(i32 %19, i32 %22)    ; IR: %17 = icmp ult ptr %12, %16: the addresses compare (a and b may alias)
  %24 = call i32 @cq_template_zext_i1_to_i32(i32 %23)    ; IR: %18 = zext i1 %17 to i32  [result rail]
  call void @cq_template_icmp_ult_i64_unc(i32 %23, i32 %19, i32 %22)    ; IR: uncompute %17
  call void @cqrt_free(i32 %23)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %22, i32 %21, i64 %13)    ; IR: uncompute q's address
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %21, i32 %20, i64 2)    ; IR: uncompute q's byte offset
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %20, i32 %12)    ; IR: uncompute q.idx widened
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_add_i64_unc(i32 %19, i32 %16, i32 %18)    ; IR: uncompute p's address
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %18, i32 %17, i64 2)    ; IR: uncompute p's byte offset
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %10)    ; IR: uncompute p.idx widened
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %16, i32 %15, i64 %14, i64 %13)    ; IR: uncompute base[p.tag]
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %8, i32 2)    ; IR: uncompute the object flag
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 3)    ; IR: uncompute %14 (q.idx)
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %11, i32 %5, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 3)    ; IR: uncompute %10 (p.idx)
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %9, i32 %5, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %8, i32 %7, i32 2, i32 1)    ; IR: uncompute p.tag (%8)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %25    ; IR: ret i32 %19
}

define i32 @ptr_eq_two_objects(i32 noundef %0, double noundef %1) {
  %3 = alloca [4 x i32], align 16    ; IR: %3 = alloca [4 x i32]  (object 1: a, classical memory)
  %4 = alloca [4 x i32], align 16    ; IR: %4 = alloca [4 x i32]  (object 2: b, classical memory)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)    ; IR: memset %3  (classical: a = {0, 0, 0, 0})
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)    ; IR: memset %4  (classical: b = {0, 0, 0, 0})
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)    ; IR: %6 = and i32 %5, 1
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)    ; IR: %7 = icmp eq i32 %6, 0
  %8 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2, i32 1)    ; IR: %8 = select i1 %7, ptr %4, ptr %3  [p.tag: b (2) or a (1); the base's idx is the classical 0]
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 1)    ; IR: %9 = lshr i32 %5, 1
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %10 = and i32 %9, 3  [p.idx: %12 = getelementptr i32, ptr %8, i64 %11 adds the CELL index 0 + %10; the zext %11 and the scaling by 4 are not emitted]
  %11 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 3)    ; IR: %13 = lshr i32 %5, 3
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 3)    ; IR: %14 = and i32 %13, 3  [q.idx: %16 = getelementptr i32, ptr %3, i64 %15, cell index %14; q.tag is the classical 1: a]
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 1)    ; IR: %17 = icmp eq ptr %12, %16: same object iff p.tag == 1
  %14 = call i32 @cq_template_icmp_eq_i32(i32 %10, i32 %12)    ; IR: %17: same cell index
  %15 = call i32 @cq_template_and_i1(i32 %13, i32 %14)    ; IR: %17 = same object and same cell index
  %16 = call i32 @cq_template_zext_i1_to_i32(i32 %15)    ; IR: %18 = zext i1 %17 to i32  [result rail]
  call void @cq_template_and_i1_unc(i32 %15, i32 %13, i32 %14)    ; IR: uncompute %17
  call void @cqrt_free(i32 %15)    ; IR: release the %17 rail (|0>)
  call void @cq_template_icmp_eq_i32_unc(i32 %14, i32 %10, i32 %12)    ; IR: uncompute the index test
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %8, i32 1)    ; IR: uncompute the object test
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 3)    ; IR: uncompute %14 (q.idx)
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %11, i32 %5, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 3)    ; IR: uncompute %10 (p.idx)
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %9, i32 %5, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %8, i32 %7, i32 2, i32 1)    ; IR: uncompute p.tag (%8)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %17    ; IR: ret i32 %19
}

declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ult_i64(i32, i32)
declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i64 @cqrt_measure_i64(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_sub_i64(i32, i32)
declare void @cq_template_sub_i64_unc(i32, i32, i32)
declare i32 @cq_template_ashr_i64_hl(i32, i64)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32(i32, i32)
declare void @cq_template_icmp_eq_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i1(i32, i32)
declare void @cq_template_and_i1_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
