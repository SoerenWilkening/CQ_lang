; ModuleID = '<stdin>'
source_filename = "rdsdj2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@__cq_act_r = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %3, double 1.000000e+00)
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 64)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cq_template_and_i32_hl(i32 %3, i32 15)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  %8 = call fastcc i32 @__cq_q_r_1_b15_ctl(i32 %7, i32 %6)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %3, i32 15)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_select_i32_lh(i32 %5, i32 0, i32 %8)
  %10 = call i32 @cq_template_and_i32_hl(i32 %3, i32 128)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 0)
  %12 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %13)
  call void @cqrt_xor_i1(i32 %11, i32 %13)
  %14 = call fastcc i32 @__cq_q_r_1_b7_ctl(i32 %13, i32 %12)
  call void @cqrt_xor_i1(i32 %11, i32 %13)
  call void @cqrt_not_i1(i32 %13)
  call void @cqrt_free(i32 %13)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %3, i32 7)
  call void @cqrt_free(i32 %12)
  %15 = call i32 @cq_template_add_i32(i32 %14, i32 %9)
  %16 = call i32 @cq_template_select_i32(i32 %11, i32 %9, i32 %15)
  call void @cq_template_add_i32_unc(i32 %15, i32 %14, i32 %9)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 0)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %3, i32 128)
  call void @cqrt_free(i32 %10)
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %5, i32 0, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)
  call void @cqrt_free(i32 %5)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 64)
  call void @cqrt_free(i32 %4)
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  %18 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64))
  %19 = call i32 @cqrt_measure_i32(i32 %18), !cq.measure !6
  %20 = add nsw i32 %19, %17
  ret i32 %20
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

define internal fastcc i32 @__cq_q_r_1_b15_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_r, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_r, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %24

6:                                                ; preds = %2
  %7 = call i32 @__cq_mem()
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %10)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_select_i32(i32 %9, i32 %11, i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  %13 = call i32 @cq_template_sub_i32_hl(i32 %12, i32 1)
  %14 = call i32 @cq_template_select_i32(i32 %9, i32 %13, i32 %12)
  call void @cqrt_copy_i32(i32 %14, i32 %10)
  call void @cq_template_select_i32_unc(i32 %14, i32 %9, i32 %13, i32 %12)
  call void @cqrt_free(i32 %14)
  call void @cq_template_sub_i32_hl_unc(i32 %13, i32 %12, i32 1)
  call void @cqrt_free(i32 %13)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %12)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %12)
  %15 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %16)
  %17 = call fastcc i32 @__cq_q_r_1_ctl(i32 %16, i32 %15)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %16)
  call void @cqrt_xor_i1(i32 %0, i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_add_i32_hl_unc(i32 %15, i32 %1, i32 -1)
  call void @cqrt_free(i32 %15)
  %18 = call i32 @cq_template_mul_i32(i32 %17, i32 %17)
  %19 = call i32 @cq_template_add_i32(i32 %18, i32 %1)
  %20 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %19)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %20, i32 %21)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %8, i32 0, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_add_i32_unc(i32 %19, i32 %18, i32 %1)
  call void @cqrt_free(i32 %19)
  call void @cq_template_mul_i32_unc(i32 %18, i32 %17, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %22 = load i32, ptr @__cq_act_r, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_r, align 4
  ret i32 %21

24:                                               ; preds = %2
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %26)
  %27 = load i32, ptr @__cq_act_r, align 4
  %28 = add i32 %27, -1
  store i32 %28, ptr @__cq_act_r, align 4
  ret i32 %25
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

define internal fastcc i32 @__cq_q_r_1_b7_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_r, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_r, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %26

6:                                                ; preds = %2
  %7 = call i32 @__cq_mem()
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %8, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %11)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_sub_i32_hl(i32 %13, i32 1)
  %15 = call i32 @cq_template_select_i32(i32 %9, i32 %14, i32 %13)
  call void @cqrt_copy_i32(i32 %15, i32 %11)
  call void @cq_template_select_i32_unc(i32 %15, i32 %9, i32 %14, i32 %13)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sub_i32_hl_unc(i32 %14, i32 %13, i32 1)
  call void @cqrt_free(i32 %14)
  call void @cqrt_free(i32 %11)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %13)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %8, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cqrt_free(i32 %13)
  %16 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %8, i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  %19 = call fastcc i32 @__cq_q_r_1_ctl(i32 %17, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %8, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %1, i32 -1)
  call void @cqrt_free(i32 %16)
  %20 = call i32 @cq_template_mul_i32(i32 %19, i32 %19)
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %1)
  %22 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %21)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %22, i32 %23)
  call void @cq_template_select_i32_lh_unc(i32 %22, i32 %8, i32 0, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i32_unc(i32 %21, i32 %20, i32 %1)
  call void @cqrt_free(i32 %21)
  call void @cq_template_mul_i32_unc(i32 %20, i32 %19, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %24 = load i32, ptr @__cq_act_r, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_r, align 4
  ret i32 %23

26:                                               ; preds = %2
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  %29 = load i32, ptr @__cq_act_r, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_r, align 4
  ret i32 %27
}

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %4)
  call void @cqrt_ry_i32(i32 %4, double 1.000000e+00)
  %5 = alloca { i32, ptr }, align 8
  %6 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 0
  store i32 %4, ptr %6, align 4
  %7 = load ptr, ptr %cq.mints, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %5, i32 0, i32 1
  store ptr %7, ptr %8, align 8
  store ptr %5, ptr %cq.mints, align 8
  %9 = call i32 @cq_template_and_i32_hl(i32 %4, i32 64)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)
  %11 = call i32 @cq_template_and_i32_hl(i32 %4, i32 15)
  %12 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  %13 = call fastcc i32 @__cq_q_r_1_b15_ctl(i32 %12, i32 %11)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %4, i32 15)
  call void @cqrt_free(i32 %11)
  %14 = call i32 @cq_template_select_i32_lh(i32 %10, i32 0, i32 %13)
  %15 = call i32 @cq_template_and_i32_hl(i32 %4, i32 128)
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %17 = call i32 @cq_template_and_i32_hl(i32 %4, i32 7)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  %19 = call fastcc i32 @__cq_q_r_1_b7_ctl(i32 %18, i32 %17)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %4, i32 7)
  call void @cqrt_free(i32 %17)
  %20 = call i32 @cq_template_add_i32(i32 %19, i32 %14)
  %21 = call i32 @cq_template_select_i32(i32 %16, i32 %14, i32 %20)
  call void @cq_template_add_i32_unc(i32 %20, i32 %19, i32 %14)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %4, i32 128)
  call void @cqrt_free(i32 %15)
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %10, i32 0, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %4, i32 64)
  call void @cqrt_free(i32 %9)
  %22 = call i32 @cqrt_measure_i32(i32 %21), !cq.measure !6
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64))
  %24 = call i32 @cqrt_measure_i32(i32 %23), !cq.measure !6
  %25 = add nsw i32 %24, %22
  %26 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %26)
  %27 = call i32 @cqrt_alloc_i32(i32 %25)
  ret i32 %27
}

declare void @cqrt_copy_i32(i32, i32)

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

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %39

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %9)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %9, double 1.000000e+00)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  %14 = call i32 @cq_template_and_i32_hl(i32 %9, i32 64)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %16 = call i32 @cq_template_and_i32_hl(i32 %9, i32 15)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %15, i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  %19 = call fastcc i32 @__cq_q_r_1_b15_ctl(i32 %17, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %15, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %9, i32 15)
  call void @cqrt_free(i32 %16)
  %20 = call i32 @cq_template_select_i32_lh(i32 %15, i32 0, i32 %19)
  %21 = call i32 @cq_template_and_i32_hl(i32 %9, i32 128)
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %21, i32 0)
  %23 = call i32 @cq_template_and_i32_hl(i32 %9, i32 7)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_xor_i1(i32 %22, i32 %25)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  %26 = call fastcc i32 @__cq_q_r_1_b7_ctl(i32 %24, i32 %23)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_xor_i1(i32 %22, i32 %25)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %9, i32 7)
  call void @cqrt_free(i32 %23)
  %27 = call i32 @cq_template_add_i32(i32 %26, i32 %20)
  %28 = call i32 @cq_template_select_i32(i32 %22, i32 %20, i32 %27)
  %29 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %28, i32 %29)
  call void @cq_template_select_i32_unc(i32 %28, i32 %22, i32 %20, i32 %27)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i32_unc(i32 %27, i32 %26, i32 %20)
  call void @cqrt_free(i32 %27)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %21, i32 0)
  call void @cqrt_free(i32 %22)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %9, i32 128)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %15, i32 0, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %14, i32 0)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %9, i32 64)
  call void @cqrt_free(i32 %14)
  %30 = call i32 @cqrt_measure_i32(i32 %29), !cq.measure !6
  %31 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @g to i64))
  %32 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %31, i32 %32)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %31, i32 %0, i32 %8, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %31)
  %33 = call i32 @cqrt_measure_i32(i32 %32), !cq.measure !6
  %34 = call i32 @cq_template_add_i32(i32 %32, i32 %29)
  %35 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %35)
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %34, i32 %36)
  call void @cq_template_add_i32_unc(i32 %34, i32 %32, i32 %29)
  call void @cqrt_free(i32 %34)
  %37 = load i32, ptr @__cq_act_f, align 4
  %38 = add i32 %37, -1
  store i32 %38, ptr @__cq_act_f, align 4
  ret i32 %36

39:                                               ; preds = %3
  %40 = call i32 @cqrt_alloc_i32(i32 0)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %41)
  call void @cqrt_push(i32 0)
  %42 = load i32, ptr @__cq_act_f, align 4
  %43 = add i32 %42, -1
  store i32 %43, ptr @__cq_act_f, align 4
  ret i32 %40
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

define internal fastcc i32 @__cq_q_r_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_r, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_r, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %26

6:                                                ; preds = %2
  %7 = call i32 @__cq_mem()
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %8, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %11)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_sub_i32_hl(i32 %13, i32 1)
  %15 = call i32 @cq_template_select_i32(i32 %9, i32 %14, i32 %13)
  call void @cqrt_copy_i32(i32 %15, i32 %11)
  call void @cq_template_select_i32_unc(i32 %15, i32 %9, i32 %14, i32 %13)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sub_i32_hl_unc(i32 %14, i32 %13, i32 1)
  call void @cqrt_free(i32 %14)
  call void @cqrt_free(i32 %11)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %7, i64 ptrtoint (ptr @g to i64), i32 %13)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %8, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cqrt_free(i32 %13)
  %16 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %8, i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  %19 = call fastcc i32 @__cq_q_r_1_ctl(i32 %17, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %8, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %1, i32 -1)
  call void @cqrt_free(i32 %16)
  %20 = call i32 @cq_template_mul_i32(i32 %19, i32 %19)
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %1)
  %22 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %21)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %22, i32 %23)
  call void @cq_template_select_i32_lh_unc(i32 %22, i32 %8, i32 0, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i32_unc(i32 %21, i32 %20, i32 %1)
  call void @cqrt_free(i32 %21)
  call void @cq_template_mul_i32_unc(i32 %20, i32 %19, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)
  call void @cqrt_free(i32 %8)
  %24 = load i32, ptr @__cq_act_r, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_r, align 4
  ret i32 %23

26:                                               ; preds = %2
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  %29 = load i32, ptr @__cq_act_r, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_r, align 4
  ret i32 %27
}

declare i32 @cq_template_mul_i32(i32, i32)

declare void @cq_template_mul_i32_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1_t_unc(i32 %0, i32 %1, i32 %2) {
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

define internal void @__cq_q_f_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_f, align 4
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

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
