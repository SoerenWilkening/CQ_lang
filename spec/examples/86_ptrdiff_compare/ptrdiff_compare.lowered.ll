; HAND-WRITTEN. Rules: 21, 20, 22, 16, 7, 5, 4, 3, 2; §1.3.
; Checked: ptrdiff_q: q - p in elements (%11 -> %12). ptr_less: p < q, the unsigned compare of the two addresses
; (%21 -> %22 -> %23). ptr_eq_two_objects: p == q, the equality of the two addresses (%36 -> %37 -> %38); the 32 cells
; of a and b at exit, all 0 (HOST cells: every memset store is classical-valued, so it writes the host byte, §1.3).
; Clean: every rail but the registers, the result rails and what rule 5 keeps: the byte-offset chains of ptrdiff_q
; (%5..%10); in ptr_less the condition chain (%8, %9), the base address rail select(flag, b, a) (%10), the index chains
; with their widened and scaled forms (%11..%14, %16..%19), the address rails p (%15) and q (%20) and the compare %21;
; in ptr_eq_two_objects the same chains (%23..%35) and the compare %36; all uncomputed in LIFO order after the
; result's zext, before the measurement, and freed.
; Kept: the register x of each function (%4 / %7 / %8, rotated) and each result rail (measured); in
; ptr_eq_two_objects by rule 5 (rules 7, 22): the seed i8 0 of a's memset (%9) with the 16 tape slots of its byte
; stores, and the seed i8 0 of b's memset (%16) with the 16 tape slots of its byte stores.
; Rotations: ptrdiff_q: (Ry, x, th, 1). ptr_less: (Ry, x, th, 1). ptr_eq_two_objects: (Ry, x, th, 1).
; A POINTER IS AN INTEGER, ITS ADDRESS (rule 21): a classical ptr/i64 or ONE 64-bit address rail. Three shapes.
; ptrdiff_q: -O1 already folds p = a + i, q = a + j, q - p into integer IR (p's byte offset (x & 3) * 4 = %6, q's byte
; offset ((x >> 2) & 3) * 4 = %8, sub, ashr exact by the stride); no pointer survives, so that IR is lowered as the
; integer ops it is (the readnone ptr parameter is unused).
; ptr_less: p = ((x & 1) ? a : b) + ((x >> 1) & 3) is a pointer select under a quantum flag, select_i64_ll of the two
; classical run-time addresses (rule 21 Merge: both incomings classical, entering as their i64 values, the ptrtoint of
; the parameters at function entry), then rule 20's address arithmetic for the gep with a tainted index: the zext -O1
; wrote, mul_i64_hl by the element size 4, add_i64 to the base rail. q = a + ((x >> 3) & 3) is the same arithmetic on a
; classical base: add_i64_hl with a's address as the literal. icmp ult on pointers is icmp_ult_i64 of the two address
; rails (rule 21 Compare). a and b may alias; nothing about them is asked: the compare is of addresses only.
; ptr_eq_two_objects: a and b are local arrays whose addresses are selected under a quantum flag and indexed by a rail,
; so both allocas are BUS-RESIDENT (rule 20 (b): a select and a gep with a tainted index are not among the
; host-resident users): each is __cq_alloc(16, 16) at its program point (one zeroed block, an address never reused),
; no alloca remains and the lifetime markers are dropped (rule 16). Each memset is rule 22's host loop of 16 kept byte
; stores of one i8 seed at the classical addresses base + j; it is emitted although the block is already zero (§0).
; The pointers p and q are built exactly as in ptr_less, and icmp eq on pointers is icmp_eq_i64 of the two address
; rails: at run time p (in b's block) never equals q (in a's block) because the blocks are distinct, which the
; addresses decide with no compile-time knowledge of objects. No pointer is dereferenced, so no bus load occurs.
source_filename = "ptrdiff_compare.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @ptrdiff_q(i32 noundef %0, double noundef %1, ptr noundef %2) {
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

define i32 @ptr_less(i32 noundef %0, double noundef %1, ptr noundef %2, ptr noundef %3) {
  %5 = ptrtoint ptr %2 to i64    ; IR: %2 (a) as its run-time address (rule 20: once, at function entry)
  %6 = ptrtoint ptr %3 to i64    ; IR: %3 (b) as its run-time address
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)    ; IR: %6 = and i32 %5, 1
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)    ; IR: %7 = icmp eq i32 %6, 0
  %10 = call i32 @cq_template_select_i64_ll(i32 %9, i64 %6, i64 %5)    ; IR: %8 = select i1 %7, ptr %3, ptr %2  [a pointer merge under a quantum flag: ONE address rail, b or a (rule 21)]
  %11 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 1)    ; IR: %9 = lshr i32 %5, 1
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 3)    ; IR: %10 = and i32 %9, 3
  %13 = call i32 @cq_template_zext_i32_to_i64(i32 %12)    ; IR: %11 = zext nneg i32 %10 to i64
  %14 = call i32 @cq_template_mul_i64_hl(i32 %13, i64 4)    ; IR: %12 = getelementptr inbounds i32, ptr %8, i64 %11: the index scaled by the element size (rule 20)
  %15 = call i32 @cq_template_add_i64(i32 %10, i32 %14)    ; IR: %12: plus the base rail  [address rail p]
  %16 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 3)    ; IR: %13 = lshr i32 %5, 3
  %17 = call i32 @cq_template_and_i32_hl(i32 %16, i32 3)    ; IR: %14 = and i32 %13, 3
  %18 = call i32 @cq_template_zext_i32_to_i64(i32 %17)    ; IR: %15 = zext nneg i32 %14 to i64
  %19 = call i32 @cq_template_mul_i64_hl(i32 %18, i64 4)    ; IR: %16 = getelementptr inbounds i32, ptr %2, i64 %15: the index scaled by the element size
  %20 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %5)    ; IR: %16: plus the classical base address a  [address rail q]
  %21 = call i32 @cq_template_icmp_ult_i64(i32 %15, i32 %20)    ; IR: %17 = icmp ult ptr %12, %16  (the unsigned compare of the two addresses, rule 21)
  %22 = call i32 @cq_template_zext_i1_to_i32(i32 %21)    ; IR: %18 = zext i1 %17 to i32  [result rail]
  call void @cq_template_icmp_ult_i64_unc(i32 %21, i32 %15, i32 %20)    ; IR: uncompute %17
  call void @cqrt_free(i32 %21)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %20, i32 %19, i64 %5)    ; IR: uncompute %16 (address rail q)
  call void @cqrt_free(i32 %20)    ; IR: release the %16 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %19, i32 %18, i64 4)    ; IR: uncompute %16 (the scaled index)
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %18, i32 %17)    ; IR: uncompute %15
  call void @cqrt_free(i32 %18)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %16, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %17)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %16, i32 %7, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %16)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %15, i32 %10, i32 %14)    ; IR: uncompute %12 (address rail p)
  call void @cqrt_free(i32 %15)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %14, i32 %13, i64 4)    ; IR: uncompute %12 (the scaled index)
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %13, i32 %12)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %11, i32 %7, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %10, i32 %9, i64 %6, i64 %5)    ; IR: uncompute %8 (the base address rail)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %23    ; IR: ret i32 %19
}

define i32 @ptr_eq_two_objects(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %4 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %3 = alloca [4 x i32], align 16  (a: bus-resident, rule 20; one zeroed block, rule 16)
  %5 = ptrtoint ptr %4 to i64    ; IR: %3 as its run-time address
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  (b: bus-resident)
  %7 = ptrtoint ptr %6 to i64    ; IR: %4 as its run-time address
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%3, i8 0, 16): the byte value as ONE seed rail (rules 7, 22), kept with its stores; llvm.lifetime.start dropped
  br label %10
10:
  %11 = phi i64 [ 0, %2 ], [ %13, %10 ]    ; IR: call @llvm.memset(%3, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %12 = add i64 %5, %11    ; IR: the classical address a + j
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %12, i32 %9)    ; IR: call @llvm.memset(%3, i8 0, 16): byte store j  (kept store, rule 5)
  %13 = add nuw nsw i64 %11, 1
  %14 = icmp eq i64 %13, 16
  br i1 %14, label %15, label %10
15:
  %16 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%4, i8 0, 16): the byte value as ONE seed rail, kept with its stores; llvm.lifetime.start dropped
  br label %17
17:
  %18 = phi i64 [ 0, %15 ], [ %20, %17 ]    ; IR: call @llvm.memset(%4, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %19 = add i64 %7, %18    ; IR: the classical address b + j
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %19, i32 %16)    ; IR: call @llvm.memset(%4, i8 0, 16): byte store j  (kept store, rule 5)
  %20 = add nuw nsw i64 %18, 1
  %21 = icmp eq i64 %20, 16
  br i1 %21, label %22, label %17
22:
  %23 = call i32 @cq_template_and_i32_hl(i32 %8, i32 1)    ; IR: %6 = and i32 %5, 1
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 0)    ; IR: %7 = icmp eq i32 %6, 0
  %25 = call i32 @cq_template_select_i64_ll(i32 %24, i64 %7, i64 %5)    ; IR: %8 = select i1 %7, ptr %4, ptr %3  [a pointer merge under a quantum flag: ONE address rail, b or a (rule 21)]
  %26 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 1)    ; IR: %9 = lshr i32 %5, 1
  %27 = call i32 @cq_template_and_i32_hl(i32 %26, i32 3)    ; IR: %10 = and i32 %9, 3
  %28 = call i32 @cq_template_zext_i32_to_i64(i32 %27)    ; IR: %11 = zext nneg i32 %10 to i64
  %29 = call i32 @cq_template_mul_i64_hl(i32 %28, i64 4)    ; IR: %12 = getelementptr inbounds i32, ptr %8, i64 %11: the index scaled by the element size (rule 20)
  %30 = call i32 @cq_template_add_i64(i32 %25, i32 %29)    ; IR: %12: plus the base rail  [address rail p]
  %31 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 3)    ; IR: %13 = lshr i32 %5, 3
  %32 = call i32 @cq_template_and_i32_hl(i32 %31, i32 3)    ; IR: %14 = and i32 %13, 3
  %33 = call i32 @cq_template_zext_i32_to_i64(i32 %32)    ; IR: %15 = zext nneg i32 %14 to i64
  %34 = call i32 @cq_template_mul_i64_hl(i32 %33, i64 4)    ; IR: %16 = getelementptr inbounds i32, ptr %3, i64 %15: the index scaled by the element size
  %35 = call i32 @cq_template_add_i64_hl(i32 %34, i64 %5)    ; IR: %16: plus the classical base address a  [address rail q]
  %36 = call i32 @cq_template_icmp_eq_i64(i32 %30, i32 %35)    ; IR: %17 = icmp eq ptr %12, %16  (the integer compare of the two addresses, rule 21)
  %37 = call i32 @cq_template_zext_i1_to_i32(i32 %36)    ; IR: %18 = zext i1 %17 to i32  [result rail]
  call void @cq_template_icmp_eq_i64_unc(i32 %36, i32 %30, i32 %35)    ; IR: uncompute %17
  call void @cqrt_free(i32 %36)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %35, i32 %34, i64 %5)    ; IR: uncompute %16 (address rail q)
  call void @cqrt_free(i32 %35)    ; IR: release the %16 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %34, i32 %33, i64 4)    ; IR: uncompute %16 (the scaled index)
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %33, i32 %32)    ; IR: uncompute %15
  call void @cqrt_free(i32 %33)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %32, i32 %31, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %32)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %31, i32 %8, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %31)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %30, i32 %25, i32 %29)    ; IR: uncompute %12 (address rail p)
  call void @cqrt_free(i32 %30)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %29, i32 %28, i64 4)    ; IR: uncompute %12 (the scaled index)
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %28, i32 %27)    ; IR: uncompute %11
  call void @cqrt_free(i32 %28)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %27, i32 %26, i32 3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %27)    ; IR: release the %10 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %26, i32 %8, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %26)    ; IR: release the %9 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %25, i32 %24, i64 %7, i64 %5)    ; IR: uncompute %8 (the base address rail)
  call void @cqrt_free(i32 %25)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %23, i32 0)    ; IR: uncompute %7
  call void @cqrt_free(i32 %24)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %8, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %23)    ; IR: release the %6 rail (|0>)
  %38 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %38    ; IR: ret i32 %19  (llvm.lifetime.end dropped)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ult_i64(i32, i32)
declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64(i32, i32)
declare void @cq_template_icmp_eq_i64_unc(i32, i32, i32)
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
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
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
