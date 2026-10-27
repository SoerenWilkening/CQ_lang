; HAND-WRITTEN. Rules: 4, 18, 20, 14, 7, 5, 2, §1.4.
; Checked: smin_q: min(x, c) (measured, %5 -> %6); bswap_q: bswap(x) (measured, %4 -> %5); usub_sat_q: x > c ? x - c : 0
; (measured, %5 -> %6); va_copy_q: sum_twice(2, x, a) = 2 * (x + a) (measured: the clone's copied-out result rail %69,
; %5 -> %6 in the caller); vla_loop_q: acc (measured, the copied-out rail %23 -> %34, or the never-written |0> rail %6
; when m <= 0).
; Clean: in __cq_q_sum_twice_010 every trip rail of both walks (popped and uncomputed by the two reverse loops), the
; final sums s and t, the |0> incomings of the two accumulator phis and the promoted rail of the classical argument a
; (freed directly); in vla_loop_q every trip's x + i and acc rails (popped and uncomputed) and the |0> incoming of acc.
; Kept: x in each function (%4 of smin_q, %3 of bswap_q, %4 of usub_sat_q, %4 of va_copy_q, %5 of vla_loop_q: the
; rotated user registers).
; Rotations: (Ry, x, th, 1) in each of the five functions.
; The last intrinsics of the musl census
; (LIBC_COVERAGE.md), each the width/op variant of an existing family: llvm.smin is 56's smax/umin family
; (cq_template_smin_<W>[_hl]); llvm.bswap is a unary bit permutation like 56's ctlz (cq_template_bswap_<W>, no classical
; operand); llvm.usub.sat is 92's uadd.sat family (cq_template_usub_sat_<W>[_hl|_lh]). llvm.va_copy is a classical copy of
; the 24-byte va_list (gp_offset, fp_offset, overflow_arg_area, reg_save_area): the copy points at the SAME register save
; area, the slot array of handles of 95, so the second walk reads the same handles and no gate is emitted; each walk is a
; classically bounded rolled loop (n = 2 propagated by -O1) carrying a quantum accumulator with 25's handle stack, and the
; two reverse loops run in reverse order (second walk first) after s + t is copied into a fresh result rail (rule 18).
; llvm.stacksave/stackrestore around a VLA in a loop are the
; host's classical stack bookkeeping and stay as written (74): the VLA is one classical object per trip (a slot of
; handles here: put's clone stores the argument's handle into v[0]: no gate, so no _unc twin), and the loop carries
; acc with 25's stack; the reverse loop recomputes the classical i of each trip (m - 1 - j) for the add's _unc.
source_filename = "intrinsic_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }    ; IR: %struct.__va_list_tag  (gp_offset, fp_offset, overflow_arg_area, reg_save_area)

define i32 @smin_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_smin_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.smin.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define i32 @bswap_q(i32 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_bswap_i32(i32 %3)    ; IR: %4 = llvm.bswap.i32(%3)  [result rail]
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_ui32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

define i32 @usub_sat_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_usub_sat_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.usub.sat.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define i32 @va_copy_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc i32 @__cq_q_sum_twice_010(i32 poison, i32 %4, i32 %2)    ; IR: %5 = call @sum_twice(poison, %4, %2), clone for arity 3 (arg 1 quantum)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define internal fastcc i32 @__cq_q_sum_twice_010(i32 %0, i32 %1, i32 %2) {
  %4 = alloca [1 x %struct.__va_list_tag], align 16    ; IR: %2 = alloca va_list ap  (classical: offsets and pointers)
  %5 = alloca [1 x %struct.__va_list_tag], align 16    ; IR: %3 = alloca va_list bp  (classical)
  %6 = alloca [6 x i64], align 16    ; IR: va_start: the register save area, 6 gp slots  (a slot array of handles)
  %7 = alloca i64, align 8    ; IR: va_start: the overflow argument area  (empty: both variadic args are in registers)
  %8 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: va_start: gp slot 1 (slot 0 is the named parameter's)
  store i32 %1, ptr %8, align 8    ; IR: va_start: spill x's handle
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: va_start: variadic arg a (classical) promoted to a rail
  %10 = getelementptr inbounds i8, ptr %6, i64 16    ; IR: va_start: gp slot 2
  store i32 %9, ptr %10, align 8    ; IR: va_start: spill a's handle
  store i32 8, ptr %4, align 16    ; IR: va_start: ap.gp_offset = 8  (one named gp parameter)
  %11 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: va_start: &ap.fp_offset
  store i32 48, ptr %11, align 4    ; IR: va_start: ap.fp_offset = 48
  %12 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: va_start: &ap.overflow_arg_area
  store ptr %7, ptr %12, align 8    ; IR: va_start: ap.overflow_arg_area
  %13 = getelementptr inbounds i8, ptr %4, i64 16    ; IR: va_start: &ap.reg_save_area
  store ptr %6, ptr %13, align 8    ; IR: va_start: ap.reg_save_area
  call void @llvm.memcpy.p0.p0.i64(ptr %5, ptr %4, i64 24, i1 false)    ; IR: llvm.va_copy(%3, %2): bp = ap, a classical copy of the four fields (same save area, same handles)
  %14 = load i32, ptr %4, align 16    ; IR: %4 = load i32, ptr %2  (ap.gp_offset, classical)
  %15 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %5
  %16 = getelementptr inbounds i8, ptr %4, i64 16    ; IR: %6
  %17 = load ptr, ptr %16, align 16    ; IR: %7 = load ptr, ptr %6  (ap.reg_save_area, classical)
  %18 = load ptr, ptr %15, align 8    ; IR: %8 = load ptr, ptr %5  (ap.overflow_arg_area, classical)
  %19 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %18  [s before trip 0]
  br label %20    ; IR: br label %15
20:
  %21 = phi ptr [ %18, %3 ], [ %33, %32 ]    ; IR: %16 = phi ptr  (classical)
  %22 = phi i32 [ 0, %3 ], [ %38, %32 ]    ; IR: %17 = phi i32  (i, classical)
  %23 = phi i32 [ %19, %3 ], [ %37, %32 ]    ; IR: %18 = phi i32 [ 0, %1 ], [ %32, %27 ]  (s: a handle)
  %24 = phi i32 [ %14, %3 ], [ %34, %32 ]    ; IR: %19 = phi i32  (ap.gp_offset, classical)
  %25 = icmp ult i32 %24, 41    ; IR: %20 = icmp ult i32 %19, 41  (classical)
  br i1 %25, label %26, label %30    ; IR: br i1 %20, label %21, label %25
26:
  %27 = zext nneg i32 %24 to i64    ; IR: %22 = zext nneg i32 %19 to i64  (classical)
  %28 = getelementptr i8, ptr %17, i64 %27    ; IR: %23 = getelementptr i8, ptr %7, i64 %22  (the slot)
  %29 = add nuw nsw i32 %24, 8    ; IR: %24 = add nuw nsw i32 %19, 8  (classical)
  store i32 %29, ptr %4, align 16    ; IR: store i32 %24, ptr %2  (classical)
  br label %32    ; IR: br label %27
30:
  %31 = getelementptr i8, ptr %21, i64 8    ; IR: %26 = getelementptr i8, ptr %16, i64 8  (classical)
  store ptr %31, ptr %15, align 8    ; IR: store ptr %26, ptr %5  (classical)
  br label %32    ; IR: br label %27
32:
  %33 = phi ptr [ %21, %26 ], [ %31, %30 ]    ; IR: %28 = phi ptr  (classical)
  %34 = phi i32 [ %29, %26 ], [ %24, %30 ]    ; IR: %29 = phi i32  (classical)
  %35 = phi ptr [ %28, %26 ], [ %21, %30 ]    ; IR: %30 = phi ptr  (the argument slot, classical)
  %36 = load i32, ptr %35, align 4    ; IR: %31 = load i32, ptr %30  (the argument's handle)
  %37 = call i32 @cq_template_add_i32(i32 %36, i32 %23)    ; IR: %32 = add nsw i32 %31, %18
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %36)
  %38 = add nuw nsw i32 %22, 1    ; IR: %33 = add nuw nsw i32 %17, 1  (classical)
  %39 = icmp eq i32 %22, 0    ; IR: %34 = icmp eq i32 %17, 0  (classical: 2 trips)
  br i1 %39, label %20, label %40    ; IR: br i1 %34, label %15, label %9
40:
  %41 = load i32, ptr %5, align 16    ; IR: %10 = load i32, ptr %3  (bp.gp_offset, classical: the copied 8)
  %42 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %11
  %43 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: %12
  %44 = load ptr, ptr %43, align 16    ; IR: %13 = load ptr, ptr %12  (bp.reg_save_area: the same save area)
  %45 = load ptr, ptr %42, align 8    ; IR: %14 = load ptr, ptr %11  (bp.overflow_arg_area, classical)
  %46 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %40  [t before trip 0]
  br label %47    ; IR: br label %37
47:
  %48 = phi ptr [ %45, %40 ], [ %60, %59 ]    ; IR: %38 = phi ptr  (classical)
  %49 = phi i32 [ 0, %40 ], [ %65, %59 ]    ; IR: %39 = phi i32  (i, classical)
  %50 = phi i32 [ %46, %40 ], [ %64, %59 ]    ; IR: %40 = phi i32 [ 0, %9 ], [ %54, %49 ]  (t: a handle)
  %51 = phi i32 [ %41, %40 ], [ %61, %59 ]    ; IR: %41 = phi i32  (bp.gp_offset, classical)
  %52 = icmp ult i32 %51, 41    ; IR: %42 = icmp ult i32 %41, 41  (classical)
  br i1 %52, label %53, label %57    ; IR: br i1 %42, label %43, label %47
53:
  %54 = zext nneg i32 %51 to i64    ; IR: %44 = zext nneg i32 %41 to i64  (classical)
  %55 = getelementptr i8, ptr %44, i64 %54    ; IR: %45 = getelementptr i8, ptr %13, i64 %44  (the slot)
  %56 = add nuw nsw i32 %51, 8    ; IR: %46 = add nuw nsw i32 %41, 8  (classical)
  store i32 %56, ptr %5, align 16    ; IR: store i32 %46, ptr %3  (classical)
  br label %59    ; IR: br label %49
57:
  %58 = getelementptr i8, ptr %48, i64 8    ; IR: %48 = getelementptr i8, ptr %38, i64 8  (classical)
  store ptr %58, ptr %42, align 8    ; IR: store ptr %48, ptr %11  (classical)
  br label %59    ; IR: br label %49
59:
  %60 = phi ptr [ %48, %53 ], [ %58, %57 ]    ; IR: %50 = phi ptr  (classical)
  %61 = phi i32 [ %56, %53 ], [ %51, %57 ]    ; IR: %51 = phi i32  (classical)
  %62 = phi ptr [ %55, %53 ], [ %48, %57 ]    ; IR: %52 = phi ptr  (the argument slot, classical)
  %63 = load i32, ptr %62, align 4    ; IR: %53 = load i32, ptr %52  (the argument's handle, the same as the first walk's)
  %64 = call i32 @cq_template_add_i32(i32 %63, i32 %50)    ; IR: %54 = add nsw i32 %53, %40
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %63)
  %65 = add nuw nsw i32 %49, 1    ; IR: %55 = add nuw nsw i32 %39, 1  (classical)
  %66 = icmp eq i32 %49, 0    ; IR: %56 = icmp eq i32 %39, 0  (classical: 2 trips)
  br i1 %66, label %47, label %67    ; IR: br i1 %56, label %37, label %35
67:
  %68 = call i32 @cq_template_add_i32(i32 %64, i32 %37)    ; IR: va_end(bp), va_end(ap): nothing; %36 = add nsw i32 %54, %32
  %69 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %36  [result rail of the call, rule 18]
  call void @cqrt_copy_i32(i32 %68, i32 %69)    ; IR: copy the result out
  call void @cq_template_add_i32_unc(i32 %68, i32 %64, i32 %37)    ; IR: uncompute %36
  call void @cqrt_free(i32 %68)    ; IR: release the %36 rail (|0>)
  br label %70
70:
  %71 = phi i32 [ 0, %67 ], [ %75, %70 ]
  %72 = phi i32 [ %64, %67 ], [ %74, %70 ]    ; IR: %54 of the trip being undone (second walk, undone first)
  %73 = call i32 @cqrt_pop()    ; IR: %53 of that trip
  %74 = call i32 @cqrt_pop()    ; IR: %40 of that trip
  call void @cq_template_add_i32_unc(i32 %72, i32 %73, i32 %74)    ; IR: uncompute %54
  call void @cqrt_free(i32 %72)    ; IR: release the %54 rail (|0>)
  %75 = add nuw nsw i32 %71, 1
  %76 = icmp eq i32 %75, 2
  br i1 %76, label %77, label %70
77:
  call void @cqrt_free(i32 %74)    ; IR: release incoming 0 of phi %40 (never written, |0>)
  br label %78
78:
  %79 = phi i32 [ 0, %77 ], [ %83, %78 ]
  %80 = phi i32 [ %37, %77 ], [ %82, %78 ]    ; IR: %32 of the trip being undone (first walk)
  %81 = call i32 @cqrt_pop()    ; IR: %31 of that trip
  %82 = call i32 @cqrt_pop()    ; IR: %18 of that trip
  call void @cq_template_add_i32_unc(i32 %80, i32 %81, i32 %82)    ; IR: uncompute %32
  call void @cqrt_free(i32 %80)    ; IR: release the %32 rail (|0>)
  %83 = add nuw nsw i32 %79, 1
  %84 = icmp eq i32 %83, 2
  br i1 %84, label %85, label %78
85:
  call void @cqrt_free(i32 %82)    ; IR: release incoming 0 of phi %18 (never written, |0>)
  call void @cqrt_free(i32 %9)    ; IR: release a's rail (never entangled, holds the classical %2)
  ret i32 %69    ; IR: ret i32 %36
}

define i32 @vla_loop_q(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %13 / %10  [acc before trip 0]
  %7 = icmp sgt i32 %3, 0    ; IR: %6 = icmp sgt i32 %3, 0  (classical)
  br i1 %7, label %10, label %8    ; IR: br i1 %6, label %7, label %9
8:
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%10), %10 = 0 from %4
  ret i32 %9    ; IR: ret i32 %11
10:
  %11 = zext i32 %2 to i64    ; IR: %8 = zext i32 %2 to i64  (classical element count)
  br label %12    ; IR: br label %12
12:
  %13 = phi i32 [ %6, %10 ], [ %19, %12 ]    ; IR: %13 = phi i32 [ 0, %7 ], [ %19, %12 ]  (acc: a handle)
  %14 = phi i32 [ 0, %10 ], [ %20, %12 ]    ; IR: %14 = phi i32  (i, classical)
  %15 = call ptr @llvm.stacksave.p0()    ; IR: %15 = llvm.stacksave()  (classical host stack mark)
  %16 = alloca i32, i64 %11, align 16    ; IR: %16 = alloca i32, i64 %8  (the VLA of this trip: classical memory, a slot of handles)
  %17 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %14)    ; IR: %17 = add nsw i32 %14, %5  (commutative: the _hl form)
  call fastcc void @__cq_q_put_01(ptr %16, i32 %17)    ; IR: call @put(%16, %17), clone (arg 1 quantum): stores the handle into v[0]
  %18 = load i32, ptr %16, align 16    ; IR: %18 = load i32, ptr %16  (v[0]: the handle %17)
  %19 = call i32 @cq_template_add_i32(i32 %18, i32 %13)    ; IR: %19 = add nsw i32 %18, %13
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %17)
  call void @llvm.stackrestore.p0(ptr %15)    ; IR: llvm.stackrestore(%15)  (classical: the VLA's storage is released; its handle lives on)
  %20 = add nuw nsw i32 %14, 1    ; IR: %20 = add nuw nsw i32 %14, 1  (classical)
  %21 = icmp eq i32 %20, %3    ; IR: %21 = icmp eq i32 %20, %3  (classical bound)
  br i1 %21, label %22, label %12    ; IR: br i1 %21, label %9, label %12
22:
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %10 = phi i32 [ %19, %12 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %19, i32 %23)    ; IR: %10
  %24 = add nsw i32 %3, -1    ; IR: m - 1  (classical: i of the last trip)
  br label %25
25:
  %26 = phi i32 [ 0, %22 ], [ %31, %25 ]
  %27 = phi i32 [ %19, %22 ], [ %29, %25 ]    ; IR: %19 of the trip being undone
  %28 = call i32 @cqrt_pop()    ; IR: %17 of that trip
  %29 = call i32 @cqrt_pop()    ; IR: %13 of that trip
  call void @cq_template_add_i32_unc(i32 %27, i32 %28, i32 %29)    ; IR: uncompute %19
  call void @cqrt_free(i32 %27)    ; IR: release the %19 rail (|0>)
  %30 = sub nsw i32 %24, %26    ; IR: i of that trip  (classical: m - 1 - j)
  call void @cq_template_add_i32_hl_unc(i32 %28, i32 %5, i32 %30)    ; IR: uncompute %17
  call void @cqrt_free(i32 %28)    ; IR: release the %17 rail (|0>)
  %31 = add nuw nsw i32 %26, 1
  %32 = icmp eq i32 %31, %3
  br i1 %32, label %33, label %25
33:
  call void @cqrt_free(i32 %29)    ; IR: release incoming 0 of phi %13 (never written, |0>)
  %34 = call i32 @cqrt_measure_i32(i32 %23)    ; IR: %11 = cq_measure_si32(%10)
  ret i32 %34    ; IR: ret i32 %11
}

define internal fastcc void @__cq_q_put_01(ptr noundef %0, i32 %1) {
  store i32 %1, ptr %0, align 4    ; IR: store i32 %1, ptr %0  (the cell takes the handle; no gate, so no _unc twin)
  ret void    ; IR: ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_smin_i32_hl(i32, i32)
declare i32 @cq_template_bswap_i32(i32)
declare i32 @cq_template_usub_sat_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare ptr @llvm.stacksave.p0()
declare void @llvm.stackrestore.p0(ptr)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
