; ModuleID = 'src/rv3/xwv7r_w.O1.ll'
source_filename = "src/rv3/xwv7r_w.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i32] [i32 37, i32 100, i32 10, i32 0], align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.effect.vwprintf = private unnamed_addr constant [9 x i8] c"vwprintf\00", align 1
@.cq.sig = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)
  %6 = call i32 @cq_template_or_i32_hl(i32 %5, i32 100)
  %7 = call ptr @__cq_alloc(i64 16, i64 16)
  %8 = ptrtoint ptr %7 to i64
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %5)
  %9 = add i64 %8, 8
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %9, i32 %6)
  %10 = call i32 @__cq_q_after_00(i32 poison, ptr %7)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_or_i32_hl(i32, i32)

define internal i32 @__cq_q_after_00(i32 %0, ptr %1) unnamed_addr {
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
  call void @cqrt_tape_effect_controlled(i32 %15, i32 %3, ptr @.cq.effect.vwprintf, i32 2)
  call void @cqrt_free(i32 %15)
  %16 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %16, i32 41)
  %18 = getelementptr inbounds i8, ptr %5, i64 16
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %17, i32 %4, i64 %19)
  %21 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  %22 = call i32 @cq_template_add_i64(i32 %20, i32 %21)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %17, i32 %4, i64 %6, i32 %23)
  %24 = call i32 @cq_template_add_i32_hl(i32 %23, i32 8)
  %25 = call i32 @cq_template_select_i32(i32 %17, i32 %24, i32 %23)
  call void @cq_template_add_i32_hl_unc(i32 %24, i32 %23, i32 8)
  call void @cqrt_free(i32 %24)
  %26 = call i32 @cq_template_sub_i32_hl(i32 %25, i32 8)
  %27 = call i32 @cq_template_select_i32(i32 %17, i32 %26, i32 %25)
  call void @cqrt_copy_i32(i32 %27, i32 %23)
  call void @cq_template_select_i32_unc(i32 %27, i32 %17, i32 %26, i32 %25)
  call void @cqrt_free(i32 %27)
  call void @cq_template_sub_i32_hl_unc(i32 %26, i32 %25, i32 8)
  call void @cqrt_free(i32 %26)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %17, i32 %4, i64 %6, i32 %25)
  call void @cqrt_free(i32 %25)
  %28 = getelementptr inbounds i8, ptr %5, i64 8
  %29 = ptrtoint ptr %28 to i64
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %17, i32 %30)
  %31 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %30, i32 %4, i64 %29)
  %32 = call i32 @cq_template_add_i64_hl(i32 %31, i64 8)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %17, i32 %4, i64 %29, i32 %32)
  call void @cqrt_not_i1(i32 %17)
  %33 = call i32 @cq_template_select_i64(i32 %17, i32 %22, i32 %31)
  %34 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %33)
  %35 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %34, i32 %35)
  call void @cqrt_qram_load_i32_unc(i32 %34, i32 %4, i32 %33)
  call void @cqrt_free(i32 %34)
  call void @cq_template_select_i64_unc(i32 %33, i32 %17, i32 %22, i32 %31)
  call void @cqrt_free(i32 %33)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %31, i32 %30, i32 %4, i64 %29)
  call void @cqrt_xor_i1(i32 %17, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cq_template_add_i64_unc(i32 %22, i32 %20, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_zext_i32_to_i64_unc(i32 %21, i32 %16)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %17, i32 %4, i64 %19)
  call void @cqrt_qram_load_i32_hl_unc(i32 %16, i32 %4, i64 %6)
  ret i32 %35
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_measure_i32(i32)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = alloca { i32, ptr }, align 8
  %7 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 0
  store i32 %5, ptr %7, align 4
  %8 = load ptr, ptr %cq.mints, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %6, i32 0, i32 1
  store ptr %8, ptr %9, align 8
  store ptr %6, ptr %cq.mints, align 8
  %10 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)
  %11 = call i32 @cq_template_or_i32_hl(i32 %10, i32 100)
  %12 = call ptr @__cq_alloc(i64 16, i64 16)
  %13 = ptrtoint ptr %12 to i64
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %13, i32 %10)
  %14 = add i64 %13, 8
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %14, i32 %11)
  %15 = call i32 @__cq_q_after_00(i32 poison, ptr %12)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  %18 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %18)
  %19 = call i32 @cqrt_alloc_i32(i32 %17)
  ret i32 %19
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32_qangle(i32, i32)

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

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %26

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %10)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %10, i32 %2)
  %11 = alloca { i32, ptr }, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 0
  store i32 %10, ptr %12, align 4
  %13 = load ptr, ptr %cq.mints, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %11, i32 0, i32 1
  store ptr %13, ptr %14, align 8
  store ptr %11, ptr %cq.mints, align 8
  %15 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)
  %16 = call i32 @cq_template_or_i32_hl(i32 %15, i32 100)
  %17 = call ptr @__cq_alloc(i64 16, i64 16)
  %18 = ptrtoint ptr %17 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %18, i32 %15)
  %19 = add i64 %18, 8
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %19, i32 %16)
  %20 = call i32 @__cq_q_after_00_ctl(i32 %0, i32 poison, ptr %17)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %20, i32 %21)
  %22 = call i32 @cqrt_measure_i32(i32 %21), !cq.measure !6
  %23 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %23)
  %24 = load i32, ptr @__cq_act_f, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_f, align 4
  ret i32 %21

26:                                               ; preds = %4
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  call void @cqrt_push(i32 0)
  %29 = load i32, ptr @__cq_act_f, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_f, align 4
  ret i32 %27
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

define internal i32 @__cq_q_after_00_ctl(i32 %0, i32 %1, ptr %2) unnamed_addr {
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
  call void @cqrt_tape_effect_controlled(i32 %0, i32 %4, ptr @.cq.effect.vwprintf, i32 2)
  %16 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %5, i64 %7)
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %16, i32 41)
  %18 = getelementptr inbounds i8, ptr %6, i64 16
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %20)
  %21 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %20, i32 %5, i64 %19)
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  %23 = call i32 @cq_template_add_i64(i32 %21, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %24)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %24, i32 %5, i64 %7, i32 %25)
  %26 = call i32 @cq_template_add_i32_hl(i32 %25, i32 8)
  %27 = call i32 @cq_template_select_i32(i32 %24, i32 %26, i32 %25)
  call void @cq_template_add_i32_hl_unc(i32 %26, i32 %25, i32 8)
  call void @cqrt_free(i32 %26)
  %28 = call i32 @cq_template_sub_i32_hl(i32 %27, i32 8)
  %29 = call i32 @cq_template_select_i32(i32 %24, i32 %28, i32 %27)
  call void @cqrt_copy_i32(i32 %29, i32 %25)
  call void @cq_template_select_i32_unc(i32 %29, i32 %24, i32 %28, i32 %27)
  call void @cqrt_free(i32 %29)
  call void @cq_template_sub_i32_hl_unc(i32 %28, i32 %27, i32 8)
  call void @cqrt_free(i32 %28)
  call void @cqrt_free(i32 %25)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %24, i32 %5, i64 %7, i32 %27)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_free(i32 %27)
  %30 = getelementptr inbounds i8, ptr %6, i64 8
  %31 = ptrtoint ptr %30 to i64
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_xor_i1(i32 %17, i32 %33)
  call void @cqrt_and_i1(i32 %0, i32 %33, i32 %32)
  %34 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %32, i32 %5, i64 %31)
  %35 = call i32 @cq_template_add_i64_hl(i32 %34, i64 8)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %17, i32 %37)
  call void @cqrt_and_i1(i32 %0, i32 %37, i32 %36)
  call void @cqrt_xor_i1(i32 %17, i32 %37)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %36, i32 %5, i64 %31, i32 %35)
  %38 = call i32 @cq_template_select_i64(i32 %17, i32 %23, i32 %34)
  %39 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %5, i32 %38)
  %40 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %39, i32 %40)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %39, i32 %0, i32 %5, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i64_unc(i32 %38, i32 %17, i32 %23, i32 %34)
  call void @cqrt_free(i32 %38)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %34, i32 %32, i32 %5, i64 %31)
  call void @cqrt_and_i1(i32 %0, i32 %33, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cqrt_xor_i1(i32 %17, i32 %33)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cq_template_add_i64_unc(i32 %23, i32 %21, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %16)
  call void @cqrt_free(i32 %22)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %21, i32 %20, i32 %5, i64 %19)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %17, i32 %16, i32 41)
  call void @cqrt_free(i32 %17)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %16, i32 %0, i32 %5, i64 %7)
  ret i32 %40
}

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare void @cqrt_qram_load_i32_unc(i32, i32, i32)

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

define internal i32 @__cq_q_after_00_ctl_pure(i32 %0, i32 %1, ptr %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 24, i64 16)
  %6 = ptrtoint ptr %5 to i64
  %7 = ptrtoint ptr %2 to i64
  %8 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %4, i64 %6, i32 %8)
  %9 = add i64 %6, 4
  %10 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %4, i64 %9, i32 %10)
  %11 = add i64 %6, 8
  %12 = call i32 @cqrt_alloc_i64(i64 %7)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %4, i64 %11, i32 %12)
  %13 = add i64 %6, 16
  %14 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %4, i64 %13, i32 %14)
  %15 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %4, i64 %6)
  %16 = call i32 @cq_template_icmp_ult_i32_hl(i32 %15, i32 41)
  %17 = getelementptr inbounds i8, ptr %5, i64 16
  %18 = ptrtoint ptr %17 to i64
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %19)
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %19, i32 %4, i64 %18)
  %21 = call i32 @cq_template_zext_i32_to_i64(i32 %15)
  %22 = call i32 @cq_template_add_i64(i32 %20, i32 %21)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %23)
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %23, i32 %4, i64 %6, i32 %24)
  %25 = call i32 @cq_template_add_i32_hl(i32 %24, i32 8)
  %26 = call i32 @cq_template_select_i32(i32 %23, i32 %25, i32 %24)
  call void @cq_template_add_i32_hl_unc(i32 %25, i32 %24, i32 8)
  call void @cqrt_free(i32 %25)
  %27 = call i32 @cq_template_sub_i32_hl(i32 %26, i32 8)
  %28 = call i32 @cq_template_select_i32(i32 %23, i32 %27, i32 %26)
  call void @cqrt_copy_i32(i32 %28, i32 %24)
  call void @cq_template_select_i32_unc(i32 %28, i32 %23, i32 %27, i32 %26)
  call void @cqrt_free(i32 %28)
  call void @cq_template_sub_i32_hl_unc(i32 %27, i32 %26, i32 8)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %24)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %23, i32 %4, i64 %6, i32 %26)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cqrt_free(i32 %26)
  %29 = getelementptr inbounds i8, ptr %5, i64 8
  %30 = ptrtoint ptr %29 to i64
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_xor_i1(i32 %16, i32 %32)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  %33 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %31, i32 %4, i64 %30)
  %34 = call i32 @cq_template_add_i64_hl(i32 %33, i64 8)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_xor_i1(i32 %16, i32 %36)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  call void @cqrt_xor_i1(i32 %16, i32 %36)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %35, i32 %4, i64 %30, i32 %34)
  %37 = call i32 @cq_template_select_i64(i32 %16, i32 %22, i32 %33)
  %38 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %4, i32 %37)
  %39 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %38, i32 %39)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %38, i32 %0, i32 %4, i32 %37)
  call void @cqrt_free(i32 %38)
  call void @cq_template_select_i64_unc(i32 %37, i32 %16, i32 %22, i32 %33)
  call void @cqrt_free(i32 %37)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %33, i32 %31, i32 %4, i64 %30)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_xor_i1(i32 %16, i32 %32)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_add_i64_unc(i32 %22, i32 %20, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_zext_i32_to_i64_unc(i32 %21, i32 %15)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %19, i32 %4, i64 %18)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %16, i32 %15, i32 41)
  call void @cqrt_free(i32 %16)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %15, i32 %0, i32 %4, i64 %6)
  ret i32 %39
}

define internal i32 @__cq_q_after_00_pure(i32 %0, ptr %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 24, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = ptrtoint ptr %1 to i64
  %7 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %7)
  %8 = add i64 %5, 4
  %9 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)
  %10 = add i64 %5, 8
  %11 = call i32 @cqrt_alloc_i64(i64 %6)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %10, i32 %11)
  %12 = add i64 %5, 16
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %12, i32 %13)
  %14 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)
  %15 = call i32 @cq_template_icmp_ult_i32_hl(i32 %14, i32 41)
  %16 = getelementptr inbounds i8, ptr %4, i64 16
  %17 = ptrtoint ptr %16 to i64
  %18 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %15, i32 %3, i64 %17)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %20 = call i32 @cq_template_add_i64(i32 %18, i32 %19)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %15, i32 %3, i64 %5, i32 %21)
  %22 = call i32 @cq_template_add_i32_hl(i32 %21, i32 8)
  %23 = call i32 @cq_template_select_i32(i32 %15, i32 %22, i32 %21)
  call void @cq_template_add_i32_hl_unc(i32 %22, i32 %21, i32 8)
  call void @cqrt_free(i32 %22)
  %24 = call i32 @cq_template_sub_i32_hl(i32 %23, i32 8)
  %25 = call i32 @cq_template_select_i32(i32 %15, i32 %24, i32 %23)
  call void @cqrt_copy_i32(i32 %25, i32 %21)
  call void @cq_template_select_i32_unc(i32 %25, i32 %15, i32 %24, i32 %23)
  call void @cqrt_free(i32 %25)
  call void @cq_template_sub_i32_hl_unc(i32 %24, i32 %23, i32 8)
  call void @cqrt_free(i32 %24)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %15, i32 %3, i64 %5, i32 %23)
  call void @cqrt_free(i32 %23)
  %26 = getelementptr inbounds i8, ptr %4, i64 8
  %27 = ptrtoint ptr %26 to i64
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %15, i32 %28)
  %29 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %28, i32 %3, i64 %27)
  %30 = call i32 @cq_template_add_i64_hl(i32 %29, i64 8)
  call void @cqrt_not_i1(i32 %15)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %15, i32 %3, i64 %27, i32 %30)
  call void @cqrt_not_i1(i32 %15)
  %31 = call i32 @cq_template_select_i64(i32 %15, i32 %20, i32 %29)
  %32 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %31)
  %33 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %32, i32 %33)
  call void @cqrt_qram_load_i32_unc(i32 %32, i32 %3, i32 %31)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i64_unc(i32 %31, i32 %15, i32 %20, i32 %29)
  call void @cqrt_free(i32 %31)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %29, i32 %28, i32 %3, i64 %27)
  call void @cqrt_xor_i1(i32 %15, i32 %28)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i64_unc(i32 %20, i32 %18, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %14)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %18, i32 %15, i32 %3, i64 %17)
  call void @cqrt_qram_load_i32_hl_unc(i32 %14, i32 %3, i64 %5)
  ret i32 %33
}

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %5)
  call void @cqrt_ry_i32_qangle(i32 %5, i32 %1)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)
  %7 = call i32 @cq_template_or_i32_hl(i32 %6, i32 100)
  %8 = call ptr @__cq_alloc(i64 16, i64 16)
  %9 = ptrtoint ptr %8 to i64
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %6)
  %10 = add i64 %9, 8
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %10, i32 %7)
  %11 = call i32 @__cq_q_after_00_pure(i32 poison, ptr %8)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %11, i32 %12)
  %13 = call i32 @cqrt_measure_i32(i32 %12), !cq.measure !6
  %14 = call i32 @cqrt_alloc_i32(i32 %13)
  ret i32 %14
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cqrt_pop()
  br label %6

6:                                                ; preds = %9, %4
  %7 = phi i32 [ %5, %4 ], [ %11, %9 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %6
  %10 = call i32 @cqrt_pop()
  %11 = sub i32 %7, 1
  br label %6

12:                                               ; preds = %6
  ret void
}

define internal void @__cq_q_f_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = call i32 @cqrt_pop()
  br label %11

11:                                               ; preds = %14, %5
  %12 = phi i32 [ %10, %5 ], [ %16, %14 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %17, label %14

14:                                               ; preds = %11
  %15 = call i32 @cqrt_pop()
  %16 = sub i32 %12, 1
  br label %11

17:                                               ; preds = %11
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
