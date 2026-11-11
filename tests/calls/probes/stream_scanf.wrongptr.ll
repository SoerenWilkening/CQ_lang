; cq-tgl3i mutant: the lowered scanf entry passes &a where C passes &n and &n where C passes &a (must be REJECTED)
; ModuleID = 'tests/calls/probes/stream_scanf.O1.ll'
source_filename = "stream_scanf.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [5 x i8] c"%n%d\00", align 1
@.cq.effect.scanf = private unnamed_addr constant [6 x i8] c"scanf\00", align 1
@__cq_act_stream_scanf = internal global i32 0, align 4
@.cq.effect.vscanf = private unnamed_addr constant [7 x i8] c"vscanf\00", align 1
@.cq.sig = private unnamed_addr constant [9 x i8] c"i32 (i8)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @stream_scanf(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 4, i64 4)
  %5 = call ptr @__cq_alloc(i64 4, i64 4)
  %6 = call ptr @__cq_alloc(i64 4, i64 4)
  %7 = call i32 @cqrt_alloc_i8(i8 %0)
  call void @cqrt_ry_i8(i32 %7, double 3.000000e-01)
  %8 = ptrtoint ptr %4 to i64
  %9 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)
  %10 = ptrtoint ptr %5 to i64
  %11 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %10, i32 %11)
  %12 = ptrtoint ptr %6 to i64
  %13 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %12, i32 %13)
  %14 = call i32 @cq_template_sext_i8_to_i32(i32 %7)
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 1)
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_xor_i1(i32 %16, i32 %17)
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 ptrtoint (ptr @.str to i64))
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 %8)
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 %10)
  %18 = call i32 @cqrt_tape_effect_i32_controlled(i32 %17, i32 %2, ptr @.cq.effect.scanf, i32 3)
  call void @cqrt_xor_i1(i32 %16, i32 %17)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_free(i32 %17)
  %19 = call i32 @cq_template_mul_i32_hl(i32 %18, i32 1000)
  %20 = call i32 @cq_template_select_i32_lh(i32 %16, i32 0, i32 %19)
  %21 = call ptr @__cq_alloc(i64 16, i64 16)
  %22 = ptrtoint ptr %21 to i64
  %23 = ptrtoint ptr %6 to i64
  %24 = call i32 @cqrt_alloc_i64(i64 %23)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %22, i32 %24)
  %25 = add i64 %22, 8
  %26 = ptrtoint ptr %4 to i64
  %27 = call i32 @cqrt_alloc_i64(i64 %26)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %25, i32 %27)
  %28 = call i32 @__cq_q_rd_00(ptr poison, ptr %21)
  %29 = call i32 @cq_template_mul_i32_hl(i32 %28, i32 100)
  %30 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %10)
  %31 = call i32 @cq_template_mul_i32_hl(i32 %30, i32 10)
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %23)
  %33 = call i32 @cq_template_mul_i32_hl(i32 %32, i32 3)
  %34 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %26)
  %35 = call i32 @cq_template_add_i32(i32 %20, i32 %14)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %16, i32 0, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_mul_i32_hl_unc(i32 %19, i32 %18, i32 1000)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 1)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %7)
  call void @cqrt_free(i32 %14)
  %36 = call i32 @cq_template_add_i32(i32 %35, i32 %29)
  %37 = call i32 @cq_template_sub_i32(i32 %36, i32 %29)
  call void @cqrt_copy_i32(i32 %37, i32 %35)
  call void @cq_template_sub_i32_unc(i32 %37, i32 %36, i32 %29)
  call void @cqrt_free(i32 %37)
  call void @cqrt_free(i32 %35)
  call void @cq_template_mul_i32_hl_unc(i32 %29, i32 %28, i32 100)
  call void @cqrt_free(i32 %29)
  %38 = call i32 @cq_template_add_i32(i32 %36, i32 %31)
  %39 = call i32 @cq_template_sub_i32(i32 %38, i32 %31)
  call void @cqrt_copy_i32(i32 %39, i32 %36)
  call void @cq_template_sub_i32_unc(i32 %39, i32 %38, i32 %31)
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %36)
  call void @cq_template_mul_i32_hl_unc(i32 %31, i32 %30, i32 10)
  call void @cqrt_free(i32 %31)
  call void @cqrt_qram_load_i32_hl_unc(i32 %30, i32 %3, i64 %10)
  call void @cqrt_free(i32 %30)
  %40 = call i32 @cq_template_add_i32(i32 %38, i32 %33)
  %41 = call i32 @cq_template_sub_i32(i32 %40, i32 %33)
  call void @cqrt_copy_i32(i32 %41, i32 %38)
  call void @cq_template_sub_i32_unc(i32 %41, i32 %40, i32 %33)
  call void @cqrt_free(i32 %41)
  call void @cqrt_free(i32 %38)
  call void @cq_template_mul_i32_hl_unc(i32 %33, i32 %32, i32 3)
  call void @cqrt_free(i32 %33)
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %3, i64 %23)
  call void @cqrt_free(i32 %32)
  %42 = call i32 @cq_template_add_i32(i32 %40, i32 %34)
  %43 = call i32 @cq_template_sub_i32(i32 %42, i32 %34)
  call void @cqrt_copy_i32(i32 %43, i32 %40)
  call void @cq_template_sub_i32_unc(i32 %43, i32 %42, i32 %34)
  call void @cqrt_free(i32 %43)
  call void @cqrt_free(i32 %40)
  call void @cqrt_qram_load_i32_hl_unc(i32 %34, i32 %3, i64 %26)
  call void @cqrt_free(i32 %34)
  %44 = call i32 @cqrt_measure_i32(i32 %42), !cq.measure !6
  ret i32 %44
}

; Function Attrs: nofree nounwind
declare noundef i32 @scanf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

define internal i32 @__cq_q_rd_00(ptr %0, ptr %1) unnamed_addr {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 24, i64 16)
  %6 = ptrtoint ptr %5 to i64
  %7 = ptrtoint ptr %1 to i64
  %8 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %8)
  %9 = add i64 %6, 4
  %10 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %10)
  %11 = add i64 %6, 8
  %12 = call i32 @cqrt_alloc_i64(i64 %7)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %11, i32 %12)
  %13 = add i64 %6, 16
  %14 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %13, i32 %14)
  %15 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 ptrtoint (ptr @.str to i64))
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %6)
  %16 = call i32 @cqrt_tape_effect_i32_controlled(i32 %15, i32 %3, ptr @.cq.effect.vscanf, i32 2)
  call void @cqrt_free(i32 %15)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %16, i32 %17)
  ret i32 %17
}

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

define internal i32 @__cq_q_stream_scanf_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %5 = call ptr @__cq_alloc(i64 4, i64 4)
  %6 = call ptr @__cq_alloc(i64 4, i64 4)
  %7 = call ptr @__cq_alloc(i64 4, i64 4)
  %8 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %8)
  call void @cqrt_ry_i8(i32 %8, double 3.000000e-01)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = ptrtoint ptr %5 to i64
  %14 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %13, i32 %14)
  %15 = ptrtoint ptr %6 to i64
  %16 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %15, i32 %16)
  %17 = ptrtoint ptr %7 to i64
  %18 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %17, i32 %18)
  %19 = call i32 @cq_template_sext_i8_to_i32(i32 %8)
  %20 = call i32 @cq_template_and_i32_hl(i32 %19, i32 1)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %21, i32 %22)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 ptrtoint (ptr @.str to i64))
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %15)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %13)
  %23 = call i32 @cqrt_tape_effect_i32_controlled(i32 %22, i32 %3, ptr @.cq.effect.scanf, i32 3)
  call void @cqrt_xor_i1(i32 %21, i32 %22)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_free(i32 %22)
  %24 = call i32 @cq_template_mul_i32_hl(i32 %23, i32 1000)
  %25 = call i32 @cq_template_select_i32_lh(i32 %21, i32 0, i32 %24)
  %26 = call ptr @__cq_alloc(i64 16, i64 16)
  %27 = ptrtoint ptr %26 to i64
  %28 = ptrtoint ptr %7 to i64
  %29 = call i32 @cqrt_alloc_i64(i64 %28)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %27, i32 %29)
  %30 = add i64 %27, 8
  %31 = ptrtoint ptr %5 to i64
  %32 = call i32 @cqrt_alloc_i64(i64 %31)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %30, i32 %32)
  %33 = call i32 @__cq_q_rd_00(ptr poison, ptr %26)
  %34 = call i32 @cq_template_mul_i32_hl(i32 %33, i32 100)
  %35 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %15)
  %36 = call i32 @cq_template_mul_i32_hl(i32 %35, i32 10)
  %37 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %28)
  %38 = call i32 @cq_template_mul_i32_hl(i32 %37, i32 3)
  %39 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %31)
  %40 = call i32 @cq_template_add_i32(i32 %25, i32 %19)
  %41 = call i32 @cq_template_add_i32(i32 %40, i32 %34)
  %42 = call i32 @cq_template_add_i32(i32 %41, i32 %36)
  %43 = call i32 @cq_template_add_i32(i32 %42, i32 %38)
  %44 = call i32 @cq_template_add_i32(i32 %43, i32 %39)
  %45 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %44, i32 %45)
  call void @cq_template_add_i32_unc(i32 %44, i32 %43, i32 %39)
  call void @cqrt_free(i32 %44)
  call void @cq_template_add_i32_unc(i32 %43, i32 %42, i32 %38)
  call void @cqrt_free(i32 %43)
  call void @cq_template_add_i32_unc(i32 %42, i32 %41, i32 %36)
  call void @cqrt_free(i32 %42)
  call void @cq_template_add_i32_unc(i32 %41, i32 %40, i32 %34)
  call void @cqrt_free(i32 %41)
  call void @cq_template_add_i32_unc(i32 %40, i32 %25, i32 %19)
  call void @cqrt_free(i32 %40)
  call void @cqrt_qram_load_i32_hl_unc(i32 %39, i32 %4, i64 %31)
  call void @cqrt_free(i32 %39)
  call void @cq_template_mul_i32_hl_unc(i32 %38, i32 %37, i32 3)
  call void @cqrt_free(i32 %38)
  call void @cqrt_qram_load_i32_hl_unc(i32 %37, i32 %4, i64 %28)
  call void @cqrt_free(i32 %37)
  call void @cq_template_mul_i32_hl_unc(i32 %36, i32 %35, i32 10)
  call void @cqrt_free(i32 %36)
  call void @cqrt_qram_load_i32_hl_unc(i32 %35, i32 %4, i64 %15)
  call void @cqrt_free(i32 %35)
  call void @cq_template_mul_i32_hl_unc(i32 %34, i32 %33, i32 100)
  call void @cqrt_free(i32 %34)
  call void @cq_template_select_i32_lh_unc(i32 %25, i32 %21, i32 0, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_mul_i32_hl_unc(i32 %24, i32 %23, i32 1000)
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %20, i32 0)
  call void @cqrt_free(i32 %21)
  call void @cq_template_and_i32_hl_unc(i32 %20, i32 %19, i32 1)
  call void @cqrt_free(i32 %20)
  call void @cq_template_sext_i8_to_i32_unc(i32 %19, i32 %8)
  call void @cqrt_free(i32 %19)
  %46 = call i32 @cqrt_measure_i32(i32 %45), !cq.measure !6
  %47 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %47)
  %48 = call i32 @cqrt_alloc_i32(i32 %46)
  ret i32 %48
}

declare void @cqrt_copy_i8(i32, i32)

define internal void @__cq_mints_push(ptr %0) {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi ptr [ %0, %1 ], [ %10, %6 ]
  %4 = phi i32 [ 0, %1 ], [ %11, %6 ]
  %5 = icmp eq ptr %3, null
  br i1 %5, label %12, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 0
  %8 = load i32, ptr %7, align 4
  call void @cqrt_push(i32 %8)
  %9 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 1
  %10 = load ptr, ptr %9, align 8
  %11 = add i32 %4, 1
  br label %2

12:                                               ; preds = %2
  call void @cqrt_push(i32 %4)
  ret void
}

declare void @cqrt_push(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

define internal i32 @__cq_q_stream_scanf_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stream_scanf, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stream_scanf, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %56

7:                                                ; preds = %3
  %8 = call i32 @cqrt_tape_alloc()
  %9 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call ptr @__cq_alloc(i64 4, i64 4)
  %11 = call ptr @__cq_alloc(i64 4, i64 4)
  %12 = call ptr @__cq_alloc(i64 4, i64 4)
  %13 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %1, i32 %13)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %13, double 3.000000e-01)
  %14 = alloca { i32, ptr }, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 0
  store i32 %13, ptr %15, align 4
  %16 = load ptr, ptr %cq.mints, align 8
  %17 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 1
  store ptr %16, ptr %17, align 8
  store ptr %14, ptr %cq.mints, align 8
  %18 = ptrtoint ptr %10 to i64
  %19 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %18, i32 %19)
  %20 = ptrtoint ptr %11 to i64
  %21 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %20, i32 %21)
  %22 = ptrtoint ptr %12 to i64
  %23 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %22, i32 %23)
  %24 = call i32 @cq_template_sext_i8_to_i32(i32 %13)
  %25 = call i32 @cq_template_and_i32_hl(i32 %24, i32 1)
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %25, i32 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %27)
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 ptrtoint (ptr @.str to i64))
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 %20)
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 %18)
  %29 = call i32 @cqrt_tape_effect_i32_controlled(i32 %27, i32 %8, ptr @.cq.effect.scanf, i32 3)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_free(i32 %28)
  %30 = call i32 @cq_template_mul_i32_hl(i32 %29, i32 1000)
  %31 = call i32 @cq_template_select_i32_lh(i32 %26, i32 0, i32 %30)
  %32 = call ptr @__cq_alloc(i64 16, i64 16)
  %33 = ptrtoint ptr %32 to i64
  %34 = ptrtoint ptr %12 to i64
  %35 = call i32 @cqrt_alloc_i64(i64 %34)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %33, i32 %35)
  %36 = add i64 %33, 8
  %37 = ptrtoint ptr %10 to i64
  %38 = call i32 @cqrt_alloc_i64(i64 %37)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %36, i32 %38)
  %39 = call i32 @__cq_q_rd_00_ctl(i32 %0, ptr poison, ptr %32)
  %40 = call i32 @cq_template_mul_i32_hl(i32 %39, i32 100)
  %41 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %9, i64 %20)
  %42 = call i32 @cq_template_mul_i32_hl(i32 %41, i32 10)
  %43 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %9, i64 %34)
  %44 = call i32 @cq_template_mul_i32_hl(i32 %43, i32 3)
  %45 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %9, i64 %37)
  %46 = call i32 @cq_template_add_i32(i32 %31, i32 %24)
  %47 = call i32 @cq_template_add_i32(i32 %46, i32 %40)
  %48 = call i32 @cq_template_add_i32(i32 %47, i32 %42)
  %49 = call i32 @cq_template_add_i32(i32 %48, i32 %44)
  %50 = call i32 @cq_template_add_i32(i32 %49, i32 %45)
  %51 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %50, i32 %51)
  call void @cq_template_add_i32_unc(i32 %50, i32 %49, i32 %45)
  call void @cqrt_free(i32 %50)
  call void @cq_template_add_i32_unc(i32 %49, i32 %48, i32 %44)
  call void @cqrt_free(i32 %49)
  call void @cq_template_add_i32_unc(i32 %48, i32 %47, i32 %42)
  call void @cqrt_free(i32 %48)
  call void @cq_template_add_i32_unc(i32 %47, i32 %46, i32 %40)
  call void @cqrt_free(i32 %47)
  call void @cq_template_add_i32_unc(i32 %46, i32 %31, i32 %24)
  call void @cqrt_free(i32 %46)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %45, i32 %0, i32 %9, i64 %37)
  call void @cqrt_free(i32 %45)
  call void @cq_template_mul_i32_hl_unc(i32 %44, i32 %43, i32 3)
  call void @cqrt_free(i32 %44)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %43, i32 %0, i32 %9, i64 %34)
  call void @cqrt_free(i32 %43)
  call void @cq_template_mul_i32_hl_unc(i32 %42, i32 %41, i32 10)
  call void @cqrt_free(i32 %42)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %41, i32 %0, i32 %9, i64 %20)
  call void @cqrt_free(i32 %41)
  call void @cq_template_mul_i32_hl_unc(i32 %40, i32 %39, i32 100)
  call void @cqrt_free(i32 %40)
  call void @cq_template_select_i32_lh_unc(i32 %31, i32 %26, i32 0, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cq_template_mul_i32_hl_unc(i32 %30, i32 %29, i32 1000)
  call void @cqrt_free(i32 %30)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %26, i32 %25, i32 0)
  call void @cqrt_free(i32 %26)
  call void @cq_template_and_i32_hl_unc(i32 %25, i32 %24, i32 1)
  call void @cqrt_free(i32 %25)
  call void @cq_template_sext_i8_to_i32_unc(i32 %24, i32 %13)
  call void @cqrt_free(i32 %24)
  %52 = call i32 @cqrt_measure_i32(i32 %51), !cq.measure !6
  %53 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %53)
  %54 = load i32, ptr @__cq_act_stream_scanf, align 4
  %55 = add i32 %54, -1
  store i32 %55, ptr @__cq_act_stream_scanf, align 4
  ret i32 %51

56:                                               ; preds = %3
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %58)
  call void @cqrt_push(i32 0)
  %59 = load i32, ptr @__cq_act_stream_scanf, align 4
  %60 = add i32 %59, -1
  store i32 %60, ptr @__cq_act_stream_scanf, align 4
  ret i32 %57
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_and_i1(i32, i32, i32)

define internal i32 @__cq_q_rd_00_ctl(i32 %0, ptr %1, ptr %2) unnamed_addr {
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 24, i64 16)
  %7 = ptrtoint ptr %6 to i64
  %8 = ptrtoint ptr %2 to i64
  %9 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %5, i64 %7, i32 %9)
  %10 = add i64 %7, 4
  %11 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %5, i64 %10, i32 %11)
  %12 = add i64 %7, 8
  %13 = call i32 @cqrt_alloc_i64(i64 %8)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %5, i64 %12, i32 %13)
  %14 = add i64 %7, 16
  %15 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %5, i64 %14, i32 %15)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 ptrtoint (ptr @.str to i64))
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 %7)
  %16 = call i32 @cqrt_tape_effect_i32_controlled(i32 %0, i32 %4, ptr @.cq.effect.vscanf, i32 2)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %16, i32 %17)
  ret i32 %17
}

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @stream_scanf, ptr @.cq.sig, ptr @__cq_q_stream_scanf_1_t, ptr @__cq_q_stream_scanf_1_t_ctl, ptr @__cq_q_stream_scanf_1_t_unc, ptr @__cq_q_stream_scanf_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_stream_scanf_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %3
  %6 = phi i32 [ %4, %3 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  ret void
}

define internal void @__cq_q_stream_scanf_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_stream_scanf, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stream_scanf, align 4
  %7 = load i32, ptr @__cq_act_stream_scanf, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_stream_scanf, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %4
  %11 = phi i32 [ %9, %4 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
