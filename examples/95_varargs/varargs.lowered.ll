; HAND-WRITTEN. Rules: 18, 20, 14, 7, 5, §1.4.
; Checked: sum3(1, a, x, b) (the clone's copied-out result %44, measured in the caller as %6 -> %7).
; Clean: every trip rail of the clone's accumulator loop (popped and uncomputed by the mirror), the s + 1 rail (%43, zeroed
; after the copy-out), the |0> seed of s (%21 / %49) and the promoted a, b rails (%8, %11; rule 7), all freed.
; Kept: x (%5, the rotated register) and the result rail (%44 / %6, measured). No _unc twin: the caller measures the copy.
; Rotations: (Ry, x, th, 1).
; A VARIADIC CALLEE is cloned per (taint mask, call-site arity): the clone is not variadic, it takes the call's actual
; arguments as parameters, __cq_q_sum3_0010(n, a, x, b). llvm.va_start is the target ABI's spill of the variadic
; parameters: on x86-64 SysV the register save area has 6 gp slots of 8 bytes, gp_offset starts at 8 * (named gp
; parameters) = 8, fp_offset at 48, and the overflow area is empty here. The save area is a SLOT ARRAY OF HANDLES (31/77):
; classical variadic args are promoted to rails, the quantum one is its handle. va_arg is -O1's own code: the gp_offset /
; overflow-area arithmetic and the slot pointer stay classical, and the load reads a handle. The loop is classically
; bounded (3 trips) and carries the quantum accumulator: 25's handle stack, mirrored after the result (s + 1: -O1
; propagated n = 1) is computed and copied into a fresh rail (rule 18). llvm.va_end is nothing. No _unc twin: the caller
; measures the copy (36).
source_filename = "varargs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }    ; IR: %struct.__va_list_tag  (gp_offset, fp_offset, overflow_arg_area, reg_save_area)

define i32 @varargs(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_sum3_0010(i32 poison, i32 %2, i32 %5, i32 %3)    ; IR: %6 = call @sum3(poison, %2, %5, %3), clone for arity 4 (arg 2 quantum)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_sum3_0010(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = alloca [1 x %struct.__va_list_tag], align 16    ; IR: %2 = alloca va_list  (classical: offsets and pointers)
  %6 = alloca [6 x i64], align 16    ; IR: va_start: the register save area, 6 gp slots  (a slot array of handles)
  %7 = alloca i64, align 8    ; IR: va_start: the overflow argument area  (empty: all variadic args are in registers)
  %8 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: va_start: variadic arg a (classical) promoted to a rail
  %9 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: va_start: gp slot 1 (slot 0 is the named parameter's)
  store i32 %8, ptr %9, align 8    ; IR: va_start: spill a's handle
  %10 = getelementptr inbounds i8, ptr %6, i64 16    ; IR: va_start: gp slot 2
  store i32 %2, ptr %10, align 8    ; IR: va_start: spill x's handle
  %11 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: va_start: variadic arg b (classical) promoted to a rail
  %12 = getelementptr inbounds i8, ptr %6, i64 24    ; IR: va_start: gp slot 3
  store i32 %11, ptr %12, align 8    ; IR: va_start: spill b's handle
  store i32 8, ptr %5, align 16    ; IR: va_start: gp_offset = 8  (one named gp parameter)
  %13 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: va_start: &fp_offset
  store i32 48, ptr %13, align 4    ; IR: va_start: fp_offset = 48
  %14 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: va_start: &overflow_arg_area
  store ptr %7, ptr %14, align 8    ; IR: va_start: overflow_arg_area
  %15 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: va_start: &reg_save_area
  store ptr %6, ptr %15, align 8    ; IR: va_start: reg_save_area
  %16 = load i32, ptr %5, align 16    ; IR: %3 = load i32, ptr %2  (gp_offset, classical)
  %17 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %4
  %18 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: %5
  %19 = load ptr, ptr %18, align 16    ; IR: %6 = load ptr, ptr %5  (reg_save_area, classical)
  %20 = load ptr, ptr %17, align 8    ; IR: %7 = load ptr, ptr %4  (overflow_arg_area, classical)
  %21 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %13  [s before trip 0]
  br label %22    ; IR: br label %10
22:
  %23 = phi ptr [ %20, %4 ], [ %35, %34 ]    ; IR: %11 = phi ptr  (classical)
  %24 = phi i32 [ 0, %4 ], [ %40, %34 ]    ; IR: %12 = phi i32  (i, classical)
  %25 = phi i32 [ %21, %4 ], [ %39, %34 ]    ; IR: %13 = phi i32 [ 0, %1 ], [ %27, %22 ]  (s: a handle)
  %26 = phi i32 [ %16, %4 ], [ %36, %34 ]    ; IR: %14 = phi i32  (gp_offset, classical)
  %27 = icmp ult i32 %26, 41    ; IR: %15 = icmp ult i32 %14, 41  (classical)
  br i1 %27, label %28, label %32    ; IR: br i1 %15, label %16, label %20
28:
  %29 = zext nneg i32 %26 to i64    ; IR: %17 = zext nneg i32 %14 to i64  (classical)
  %30 = getelementptr i8, ptr %19, i64 %29    ; IR: %18 = getelementptr i8, ptr %6, i64 %17  (the slot)
  %31 = add nuw nsw i32 %26, 8    ; IR: %19 = add nuw nsw i32 %14, 8  (classical)
  store i32 %31, ptr %5, align 16    ; IR: store i32 %19, ptr %2  (classical)
  br label %34    ; IR: br label %22
32:
  %33 = getelementptr i8, ptr %23, i64 8    ; IR: %21 = getelementptr i8, ptr %11, i64 8  (classical)
  store ptr %33, ptr %17, align 8    ; IR: store ptr %21, ptr %4  (classical)
  br label %34    ; IR: br label %22
34:
  %35 = phi ptr [ %23, %28 ], [ %33, %32 ]    ; IR: %23 = phi ptr  (classical)
  %36 = phi i32 [ %31, %28 ], [ %26, %32 ]    ; IR: %24 = phi i32  (classical)
  %37 = phi ptr [ %30, %28 ], [ %23, %32 ]    ; IR: %25 = phi ptr  (the argument slot, classical)
  %38 = load i32, ptr %37, align 4    ; IR: %26 = load i32, ptr %25  (the argument's handle)
  %39 = call i32 @cq_template_add_i32(i32 %38, i32 %25)    ; IR: %27 = add nsw i32 %26, %13
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %38)
  %40 = add nuw nsw i32 %24, 1    ; IR: %28 = add nuw nsw i32 %12, 1  (classical)
  %41 = icmp eq i32 %40, 3    ; IR: %29 = icmp eq i32 %28, 3  (classical)
  br i1 %41, label %42, label %22    ; IR: br i1 %29, label %8, label %10
42:
  %43 = call i32 @cq_template_add_i32_hl(i32 %39, i32 1)    ; IR: va_end: nothing; %9 = add nsw i32 %27, 1
  %44 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9  [result rail of the call, rule 18]
  call void @cqrt_copy_i32(i32 %43, i32 %44)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %43, i32 %39, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %43)    ; IR: release the %9 rail (|0>)
  br label %45
45:
  %46 = phi i32 [ 0, %42 ], [ %50, %45 ]
  %47 = phi i32 [ %39, %42 ], [ %49, %45 ]    ; IR: %27 of the trip being undone
  %48 = call i32 @cqrt_pop()    ; IR: %26 of that trip (the argument's handle)
  %49 = call i32 @cqrt_pop()    ; IR: %13 of that trip
  call void @cq_template_add_i32_unc(i32 %47, i32 %48, i32 %49)    ; IR: uncompute %27
  call void @cqrt_free(i32 %47)    ; IR: release the %27 rail (|0>)
  %50 = add nuw nsw i32 %46, 1
  %51 = icmp eq i32 %50, 3
  br i1 %51, label %52, label %45
52:
  call void @cqrt_free(i32 %49)    ; IR: release incoming 0 of phi %13 (never written, |0>)
  call void @cqrt_free(i32 %11)    ; IR: release b's rail (never entangled, holds the classical %3)
  call void @cqrt_free(i32 %8)    ; IR: release a's rail (never entangled, holds the classical %1)
  ret i32 %44    ; IR: ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
