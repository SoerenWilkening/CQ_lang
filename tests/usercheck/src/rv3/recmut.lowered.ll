; ModuleID = '<stdin>'
source_filename = "recmut.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_f = internal global i32 0, align 4
@__cq_act_ev = internal global i32 0, align 4
@__cq_act_od = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %2, double 1.000000e+00)
  %3 = call i32 @cq_template_and_i32_hl(i32 %2, i32 64)
  %4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %3, i32 0)
  %5 = call i32 @cq_template_and_i32_hl(i32 %2, i32 15)
  %6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_xor_i1(i32 %4, i32 %6)
  %7 = call fastcc i32 @__cq_q_ev_1_b15_ctl(i32 %6, i32 %5)
  %8 = call i32 @cq_template_select_i32_lh(i32 %4, i32 0, i32 %7)
  call void @__cq_q_ev_1_b15_ctl_unc(i32 %6, i32 %7, i32 %5)
  call void @cqrt_free(i32 %7)
  call void @cqrt_xor_i1(i32 %4, i32 %6)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %2, i32 15)
  call void @cqrt_free(i32 %5)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %4, i32 %3, i32 0)
  call void @cqrt_free(i32 %4)
  call void @cq_template_and_i32_hl_unc(i32 %3, i32 %2, i32 64)
  call void @cqrt_free(i32 %3)
  %9 = call i32 @cqrt_measure_i32(i32 %8), !cq.measure !6
  ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

define internal fastcc i32 @__cq_q_ev_1_b15_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_ev, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_ev, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %16

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  %10 = call fastcc i32 @__cq_q_od_1_ctl(i32 %9, i32 %8)
  %11 = call i32 @cq_template_shl_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_select_i32_lh(i32 %7, i32 1, i32 %11)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %12, i32 %13)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %7, i32 1, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_shl_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  call void @__cq_q_od_1_ctl_unc(i32 %9, i32 %10, i32 %8)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %14 = load i32, ptr @__cq_act_ev, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_ev, align 4
  ret i32 %13

16:                                               ; preds = %2
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %18)
  %19 = load i32, ptr @__cq_act_ev, align 4
  %20 = add i32 %19, -1
  store i32 %20, ptr @__cq_act_ev, align 4
  ret i32 %17
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cqrt_measure_i32(i32)

define internal fastcc void @__cq_q_ev_1_b15_ctl_unc(i32 %0, i32 %out, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_ev, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_ev, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %15

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  %10 = call fastcc i32 @__cq_q_od_1_ctl(i32 %9, i32 %8)
  %11 = call i32 @cq_template_shl_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_select_i32_lh(i32 %7, i32 1, i32 %11)
  call void @cqrt_copy_i32(i32 %12, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %7, i32 1, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_shl_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  call void @__cq_q_od_1_ctl_unc(i32 %9, i32 %10, i32 %8)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %13 = load i32, ptr @__cq_act_ev, align 4
  %14 = add i32 %13, -1
  store i32 %14, ptr @__cq_act_ev, align 4
  ret void

15:                                               ; preds = %2
  %16 = load i32, ptr @__cq_act_ev, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_ev, align 4
  ret void
}

declare void @cqrt_free(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %3)
  call void @cqrt_ry_i32(i32 %3, double 1.000000e+00)
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 64)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cq_template_and_i32_hl(i32 %3, i32 15)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  %8 = call fastcc i32 @__cq_q_ev_1_b15_ctl(i32 %7, i32 %6)
  %9 = call i32 @cq_template_select_i32_lh(i32 %5, i32 0, i32 %8)
  call void @__cq_q_ev_1_b15_ctl_unc(i32 %7, i32 %8, i32 %6)
  call void @cqrt_free(i32 %8)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %3, i32 15)
  call void @cqrt_free(i32 %6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)
  call void @cqrt_free(i32 %5)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 64)
  call void @cqrt_free(i32 %4)
  %10 = call i32 @cqrt_measure_i32(i32 %9), !cq.measure !6
  call void @cqrt_push(i32 %3)
  %11 = call i32 @cqrt_alloc_i32(i32 %10)
  ret i32 %11
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_push(i32)

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %25

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %8)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %8, double 1.000000e+00)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 64)
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)
  %15 = call i32 @cq_template_and_i32_hl(i32 %8, i32 15)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_xor_i1(i32 %14, i32 %17)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %16)
  %18 = call fastcc i32 @__cq_q_ev_1_b15_ctl(i32 %16, i32 %15)
  %19 = call i32 @cq_template_select_i32_lh(i32 %14, i32 0, i32 %18)
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %19, i32 %20)
  call void @cq_template_select_i32_lh_unc(i32 %19, i32 %14, i32 0, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @__cq_q_ev_1_b15_ctl_unc(i32 %16, i32 %18, i32 %15)
  call void @cqrt_free(i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %17, i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cqrt_xor_i1(i32 %14, i32 %17)
  call void @cqrt_not_i1(i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %8, i32 15)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %13, i32 0)
  call void @cqrt_free(i32 %14)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 64)
  call void @cqrt_free(i32 %13)
  %21 = call i32 @cqrt_measure_i32(i32 %20), !cq.measure !6
  %22 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %22)
  %23 = load i32, ptr @__cq_act_f, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_f, align 4
  ret i32 %20

25:                                               ; preds = %3
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %27)
  call void @cqrt_push(i32 0)
  %28 = load i32, ptr @__cq_act_f, align 4
  %29 = add i32 %28, -1
  store i32 %29, ptr @__cq_act_f, align 4
  ret i32 %26
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

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

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

define internal fastcc i32 @__cq_q_od_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_od, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_od, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %16

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  %10 = call fastcc i32 @__cq_q_ev_1_ctl(i32 %9, i32 %8)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_select_i32_lh(i32 %7, i32 0, i32 %11)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %12, i32 %13)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %7, i32 0, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  call void @__cq_q_ev_1_ctl_unc(i32 %9, i32 %10, i32 %8)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %14 = load i32, ptr @__cq_act_od, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_od, align 4
  ret i32 %13

16:                                               ; preds = %2
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %18)
  %19 = load i32, ptr @__cq_act_od, align 4
  %20 = add i32 %19, -1
  store i32 %20, ptr @__cq_act_od, align 4
  ret i32 %17
}

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

define internal fastcc void @__cq_q_od_1_ctl_unc(i32 %0, i32 %out, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_od, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_od, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %15

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  %10 = call fastcc i32 @__cq_q_ev_1_ctl(i32 %9, i32 %8)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)
  %12 = call i32 @cq_template_select_i32_lh(i32 %7, i32 0, i32 %11)
  call void @cqrt_copy_i32(i32 %12, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %7, i32 0, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 1)
  call void @cqrt_free(i32 %11)
  call void @__cq_q_ev_1_ctl_unc(i32 %9, i32 %10, i32 %8)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %7, i32 %9)
  call void @cqrt_xor_i1(i32 %0, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %13 = load i32, ptr @__cq_act_od, align 4
  %14 = add i32 %13, -1
  store i32 %14, ptr @__cq_act_od, align 4
  ret void

15:                                               ; preds = %2
  %16 = load i32, ptr @__cq_act_od, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_od, align 4
  ret void
}

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

define internal fastcc i32 @__cq_q_ev_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_ev, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_ev, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %17

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call fastcc i32 @__cq_q_od_1_ctl(i32 %9, i32 %8)
  %12 = call i32 @cq_template_shl_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_select_i32_lh(i32 %7, i32 1, i32 %12)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %13, i32 %14)
  call void @cq_template_select_i32_lh_unc(i32 %13, i32 %7, i32 1, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_shl_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  call void @__cq_q_od_1_ctl_unc(i32 %9, i32 %11, i32 %8)
  call void @cqrt_free(i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %15 = load i32, ptr @__cq_act_ev, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_ev, align 4
  ret i32 %14

17:                                               ; preds = %2
  %18 = call i32 @cqrt_alloc_i32(i32 0)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %19)
  %20 = load i32, ptr @__cq_act_ev, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_ev, align 4
  ret i32 %18
}

define internal fastcc void @__cq_q_ev_1_ctl_unc(i32 %0, i32 %out, i32 %1) unnamed_addr {
  %3 = load i32, ptr @__cq_act_ev, align 4
  %4 = add i32 %3, 1
  store i32 %4, ptr @__cq_act_ev, align 4
  %5 = icmp ult i32 %3, 4
  br i1 %5, label %6, label %16

6:                                                ; preds = %2
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  %11 = call fastcc i32 @__cq_q_od_1_ctl(i32 %9, i32 %8)
  %12 = call i32 @cq_template_shl_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_select_i32_lh(i32 %7, i32 1, i32 %12)
  call void @cqrt_copy_i32(i32 %13, i32 %out)
  call void @cq_template_select_i32_lh_unc(i32 %13, i32 %7, i32 1, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_shl_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  call void @__cq_q_od_1_ctl_unc(i32 %9, i32 %11, i32 %8)
  call void @cqrt_free(i32 %11)
  call void @cqrt_and_i1(i32 %0, i32 %10, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cqrt_xor_i1(i32 %7, i32 %10)
  call void @cqrt_not_i1(i32 %10)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %1, i32 1)
  call void @cqrt_free(i32 %7)
  %14 = load i32, ptr @__cq_act_ev, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_ev, align 4
  ret void

16:                                               ; preds = %2
  %17 = load i32, ptr @__cq_act_ev, align 4
  %18 = add i32 %17, -1
  store i32 %18, ptr @__cq_act_ev, align 4
  ret void
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cqrt_pop()
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 64)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cq_template_and_i32_hl(i32 %3, i32 15)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  %8 = call fastcc i32 @__cq_q_ev_1_b15_ctl(i32 %7, i32 %6)
  %9 = call i32 @cq_template_select_i32_lh(i32 %5, i32 0, i32 %8)
  call void @__cq_q_ev_1_b15_ctl_unc(i32 %7, i32 %8, i32 %6)
  call void @cqrt_free(i32 %8)
  call void @cqrt_xor_i1(i32 %5, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %3, i32 15)
  call void @cqrt_free(i32 %6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)
  call void @cqrt_free(i32 %5)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 64)
  call void @cqrt_free(i32 %4)
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
