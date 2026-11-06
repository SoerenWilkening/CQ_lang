; ModuleID = '<stdin>'
source_filename = "fpcand.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@__cq_act_l1 = internal global i32 0, align 4
@__cq_act_l2 = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig.1 = private unnamed_addr constant [15 x i8] c"i32 (i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @l1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = and i32 %0, 63
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %21, %1
  %6 = phi i32 [ %9, %21 ], [ poison, %1 ]
  %cq.run = phi i1 [ true, %21 ], [ false, %1 ]
  %7 = phi i32 [ %16, %21 ], [ 0, %1 ]
  br i1 %cq.run, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %5
  call void @cqrt_qram_load_i32_hl_unc(i32 %6, i32 %2, i64 ptrtoint (ptr @g to i64))
  br label %.cq.after

.cq.after:                                        ; preds = %5, %.cq.arm
  ret i32 %7

8:                                                ; preds = %1
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64))
  br label %10

10:                                               ; preds = %8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %9, i32 %11)
  br label %13

12:                                               ; preds = %13
  br label %22

13:                                               ; preds = %13, %10
  %from = phi i32 [ 0, %13 ], [ 1, %10 ]
  %14 = phi i32 [ 0, %10 ], [ %16, %13 ]
  %15 = phi i32 [ %11, %10 ], [ %17, %13 ]
  call void @cqrt_push(i32 %from)
  %16 = add nuw nsw i32 %14, 1
  %17 = call i32 @cq_template_xor_i32_hl(i32 %15, i32 %16)
  %18 = call i32 @cq_template_xor_i32_hl(i32 %17, i32 %16)
  call void @cqrt_copy_i32(i32 %18, i32 %15)
  call void @cq_template_xor_i32_hl_unc(i32 %18, i32 %17, i32 %16)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %15)
  %19 = mul nuw nsw i32 %16, %16
  %20 = icmp ult i32 %19, %3
  br i1 %20, label %13, label %12

21:                                               ; preds = %22
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %17)
  br label %5

22:                                               ; preds = %12, %22
  %23 = call i32 @cqrt_pop()
  switch i32 %23, label %22 [
    i32 1, label %21
  ]
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483645, -2147483648) i32 @l2(i32 noundef %0) local_unnamed_addr #1 {
  %2 = add nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %5, double 1.000000e+00)
  %6 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %6, double 1.000000e+00)
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 128)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %9 = call i32 @cq_template_select_i64_ll(i32 %8, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  %10 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %11 = call i32 @cqrt_alloc_i1(i1 true)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  br label %13

13:                                               ; preds = %18, %2
  %14 = phi i32 [ 0, %2 ], [ %28, %18 ]
  %15 = phi i32 [ %11, %2 ], [ %26, %18 ]
  %16 = phi i32 [ %12, %2 ], [ %27, %18 ]
  %17 = icmp ult i32 %14, %10
  br i1 %17, label %18, label %29

18:                                               ; preds = %13
  %19 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %14)
  %20 = ptrtoint ptr %19 to i64
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %9, i64 %20)
  %22 = call ptr @__cq_clone_resolve(ptr %19, i32 1)
  %23 = call i32 %22(i32 %21, i32 %6, i32 4)
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %23, i32 %24)
  %25 = call ptr @__cq_clone_resolve(ptr %19, i32 3)
  call void %25(i32 %21, i32 %23, i32 %6, i32 4)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %26)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_push(i32 %15)
  %27 = call i32 @cq_template_select_i32(i32 %21, i32 %24, i32 %16)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %21)
  %28 = add i32 %14, 1
  br label %13

29:                                               ; preds = %13
  %30 = call i32 @cqrt_tape_write_i64_controlled(i32 %15, i32 %4, i32 %9)
  %31 = call i32 @cqrt_tape_write_i32_controlled(i32 %15, i32 %4, i32 %6)
  %32 = call i32 @cqrt_tape_effect_i32_controlled(i32 %15, i32 %4, ptr null, i32 2)
  %33 = call i32 @cq_template_select_i32(i32 %15, i32 %32, i32 %16)
  %34 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %33, i32 %34)
  call void @cq_template_select_i32_unc(i32 %33, i32 %15, i32 %32, i32 %16)
  call void @cqrt_free(i32 %33)
  br label %35

35:                                               ; preds = %40, %29
  %36 = phi i32 [ %10, %29 ], [ %41, %40 ]
  %37 = phi i32 [ %15, %29 ], [ %45, %40 ]
  %38 = phi i32 [ %16, %29 ], [ %44, %40 ]
  %39 = icmp eq i32 %36, 0
  br i1 %39, label %48, label %40

40:                                               ; preds = %35
  %41 = add i32 %36, -1
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %38, i32 %42, i32 %43, i32 %44)
  call void @cqrt_free(i32 %38)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_and_i1(i32 %45, i32 %42, i32 %37)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_free(i32 %37)
  %46 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %41)
  %47 = ptrtoint ptr %46 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %42, i32 %9, i64 %47)
  call void @cqrt_free(i32 %42)
  br label %35

48:                                               ; preds = %35
  call void @cqrt_free(i32 %37)
  call void @cqrt_free(i32 %38)
  call void @cq_template_select_i64_ll_unc(i32 %9, i32 %8, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)
  call void @cqrt_free(i32 %8)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 128)
  call void @cqrt_free(i32 %7)
  %49 = call i32 @cqrt_measure_i32(i32 %34), !cq.measure !6
  %50 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64))
  %51 = call i32 @cqrt_measure_i32(i32 %50), !cq.measure !6
  %52 = shl nsw i32 %51, 6
  %53 = add nsw i32 %52, %49
  ret i32 %53
}

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_l1_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cq_template_and_i32_hl(i32 %0, i32 63)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  %7 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %6, i32 %3, i64 ptrtoint (ptr @g to i64))
  br label %8

8:                                                ; preds = %2
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_xor_i1(i32 %5, i32 %9)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  %11 = add i32 0, 1
  %12 = call i32 @cq_template_xor_i32_hl(i32 %7, i32 %11)
  %13 = mul i32 %11, %11
  %14 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %13)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %9, i32 %14, i32 %15)
  %16 = sub i32 %11, 0
  %17 = call i32 @cq_template_add_i32_hl(i32 %10, i32 %16)
  %18 = call i32 @cq_template_select_i32(i32 %9, i32 %17, i32 %10)
  %19 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %7)
  %20 = add i32 %11, 1
  %21 = call i32 @cq_template_xor_i32_hl(i32 %19, i32 %20)
  %22 = mul i32 %20, %20
  %23 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %23, i32 %24)
  %25 = sub i32 %20, %11
  %26 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %25)
  %27 = call i32 @cq_template_select_i32(i32 %15, i32 %26, i32 %18)
  %28 = call i32 @cq_template_select_i32(i32 %15, i32 %21, i32 %19)
  %29 = add i32 %20, 1
  %30 = call i32 @cq_template_xor_i32_hl(i32 %28, i32 %29)
  %31 = mul i32 %29, %29
  %32 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  %34 = sub i32 %29, %20
  %35 = call i32 @cq_template_add_i32_hl(i32 %27, i32 %34)
  %36 = call i32 @cq_template_select_i32(i32 %24, i32 %35, i32 %27)
  %37 = call i32 @cq_template_select_i32(i32 %24, i32 %30, i32 %28)
  %38 = add i32 %29, 1
  %39 = call i32 @cq_template_xor_i32_hl(i32 %37, i32 %38)
  %40 = mul i32 %38, %38
  %41 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %40)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %41, i32 %42)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %41, i32 %4, i32 %40)
  call void @cqrt_free(i32 %41)
  %43 = sub i32 %38, %29
  %44 = call i32 @cq_template_add_i32_hl(i32 %36, i32 %43)
  %45 = call i32 @cq_template_select_i32(i32 %33, i32 %44, i32 %36)
  %46 = call i32 @cq_template_select_i32(i32 %33, i32 %39, i32 %37)
  call void @cq_template_xor_i32_hl_unc(i32 %39, i32 %37, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i32_unc(i32 %37, i32 %24, i32 %30, i32 %28)
  call void @cqrt_free(i32 %37)
  call void @cq_template_xor_i32_hl_unc(i32 %30, i32 %28, i32 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_select_i32_unc(i32 %28, i32 %15, i32 %21, i32 %19)
  call void @cqrt_free(i32 %28)
  call void @cq_template_xor_i32_hl_unc(i32 %21, i32 %19, i32 %20)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i32_unc(i32 %19, i32 %9, i32 %12, i32 %7)
  call void @cqrt_free(i32 %19)
  call void @cq_template_xor_i32_hl_unc(i32 %12, i32 %7, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %7, i32 %6, i32 %3, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %7)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_free(i32 %6)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %5, i32 %3, i64 ptrtoint (ptr @g to i64), i32 %46)
  call void @cqrt_not_i1(i32 %5)
  %47 = call i32 @cq_template_select_i32_lh(i32 %5, i32 0, i32 %45)
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %47, i32 %48)
  call void @cq_template_select_i32_lh_unc(i32 %47, i32 %5, i32 0, i32 %45)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i32_unc(i32 %45, i32 %33, i32 %44, i32 %36)
  call void @cqrt_free(i32 %45)
  call void @cq_template_add_i32_hl_unc(i32 %44, i32 %36, i32 %43)
  call void @cqrt_free(i32 %44)
  call void @cq_template_select_i32_unc(i32 %36, i32 %24, i32 %35, i32 %27)
  call void @cqrt_free(i32 %36)
  call void @cq_template_add_i32_hl_unc(i32 %35, i32 %27, i32 %34)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %32, i32 %4, i32 %31)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i32_unc(i32 %27, i32 %15, i32 %26, i32 %18)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i32_hl_unc(i32 %26, i32 %18, i32 %25)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %15, i32 %23, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %23, i32 %4, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cq_template_select_i32_unc(i32 %18, i32 %9, i32 %17, i32 %10)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %10, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %9, i32 %14, i32 %15)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %14, i32 %4, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_free(i32 %10)
  call void @cqrt_xor_i1(i32 %5, i32 %9)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %0, i32 63)
  call void @cqrt_free(i32 %4)
  ret i32 %48
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_l1_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_l1, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_l1, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %60

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_and_i32_hl(i32 %1, i32 63)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)
  %11 = call i32 @cqrt_alloc_i1(i1 false)
  %12 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %11)
  %13 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %11, i32 %8, i64 ptrtoint (ptr @g to i64))
  br label %14

14:                                               ; preds = %7
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_xor_i1(i32 %10, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %15)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  %18 = add i32 0, 1
  %19 = call i32 @cq_template_xor_i32_hl(i32 %13, i32 %18)
  %20 = mul i32 %18, %18
  %21 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %20)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  %23 = sub i32 %18, 0
  %24 = call i32 @cq_template_add_i32_hl(i32 %17, i32 %23)
  %25 = call i32 @cq_template_select_i32(i32 %15, i32 %24, i32 %17)
  %26 = call i32 @cq_template_select_i32(i32 %15, i32 %19, i32 %13)
  %27 = add i32 %18, 1
  %28 = call i32 @cq_template_xor_i32_hl(i32 %26, i32 %27)
  %29 = mul i32 %27, %27
  %30 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %29)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %31)
  %32 = sub i32 %27, %18
  %33 = call i32 @cq_template_add_i32_hl(i32 %25, i32 %32)
  %34 = call i32 @cq_template_select_i32(i32 %22, i32 %33, i32 %25)
  %35 = call i32 @cq_template_select_i32(i32 %22, i32 %28, i32 %26)
  %36 = add i32 %27, 1
  %37 = call i32 @cq_template_xor_i32_hl(i32 %35, i32 %36)
  %38 = mul i32 %36, %36
  %39 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %39, i32 %40)
  %41 = sub i32 %36, %27
  %42 = call i32 @cq_template_add_i32_hl(i32 %34, i32 %41)
  %43 = call i32 @cq_template_select_i32(i32 %31, i32 %42, i32 %34)
  %44 = call i32 @cq_template_select_i32(i32 %31, i32 %37, i32 %35)
  %45 = add i32 %36, 1
  %46 = call i32 @cq_template_xor_i32_hl(i32 %44, i32 %45)
  %47 = mul i32 %45, %45
  %48 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %47)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %48, i32 %49)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %48, i32 %9, i32 %47)
  call void @cqrt_free(i32 %48)
  %50 = sub i32 %45, %36
  %51 = call i32 @cq_template_add_i32_hl(i32 %43, i32 %50)
  %52 = call i32 @cq_template_select_i32(i32 %40, i32 %51, i32 %43)
  %53 = call i32 @cq_template_select_i32(i32 %40, i32 %46, i32 %44)
  call void @cq_template_xor_i32_hl_unc(i32 %46, i32 %44, i32 %45)
  call void @cqrt_free(i32 %46)
  call void @cq_template_select_i32_unc(i32 %44, i32 %31, i32 %37, i32 %35)
  call void @cqrt_free(i32 %44)
  call void @cq_template_xor_i32_hl_unc(i32 %37, i32 %35, i32 %36)
  call void @cqrt_free(i32 %37)
  call void @cq_template_select_i32_unc(i32 %35, i32 %22, i32 %28, i32 %26)
  call void @cqrt_free(i32 %35)
  call void @cq_template_xor_i32_hl_unc(i32 %28, i32 %26, i32 %27)
  call void @cqrt_free(i32 %28)
  call void @cq_template_select_i32_unc(i32 %26, i32 %15, i32 %19, i32 %13)
  call void @cqrt_free(i32 %26)
  call void @cq_template_xor_i32_hl_unc(i32 %19, i32 %13, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %13, i32 %11, i32 %8, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %13)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %11)
  call void @cqrt_free(i32 %11)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_free(i32 %12)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_xor_i1(i32 %10, i32 %55)
  call void @cqrt_and_i1(i32 %0, i32 %55, i32 %54)
  call void @cqrt_xor_i1(i32 %10, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %54, i32 %8, i64 ptrtoint (ptr @g to i64), i32 %53)
  %56 = call i32 @cq_template_select_i32_lh(i32 %10, i32 0, i32 %52)
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %56, i32 %57)
  call void @cq_template_select_i32_lh_unc(i32 %56, i32 %10, i32 0, i32 %52)
  call void @cqrt_free(i32 %56)
  call void @cq_template_select_i32_unc(i32 %52, i32 %40, i32 %51, i32 %43)
  call void @cqrt_free(i32 %52)
  call void @cq_template_add_i32_hl_unc(i32 %51, i32 %43, i32 %50)
  call void @cqrt_free(i32 %51)
  call void @cq_template_select_i32_unc(i32 %43, i32 %31, i32 %42, i32 %34)
  call void @cqrt_free(i32 %43)
  call void @cq_template_add_i32_hl_unc(i32 %42, i32 %34, i32 %41)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %31, i32 %39, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %39, i32 %9, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i32_unc(i32 %34, i32 %22, i32 %33, i32 %25)
  call void @cqrt_free(i32 %34)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %25, i32 %32)
  call void @cqrt_free(i32 %33)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %30, i32 %9, i32 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_select_i32_unc(i32 %25, i32 %15, i32 %24, i32 %17)
  call void @cqrt_free(i32 %25)
  call void @cq_template_add_i32_hl_unc(i32 %24, i32 %17, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %21, i32 %9, i32 %20)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %15)
  call void @cqrt_free(i32 %15)
  call void @cqrt_xor_i1(i32 %10, i32 %16)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %1, i32 63)
  call void @cqrt_free(i32 %9)
  %58 = load i32, ptr @__cq_act_l1, align 4
  %59 = add i32 %58, -1
  store i32 %59, ptr @__cq_act_l1, align 4
  ret i32 %57

60:                                               ; preds = %3
  %61 = call i32 @cqrt_alloc_i32(i32 0)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %62)
  %63 = load i32, ptr @__cq_act_l1, align 4
  %64 = add i32 %63, -1
  store i32 %64, ptr @__cq_act_l1, align 4
  ret i32 %61
}

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal i32 @__cq_q_l2_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 3)
  call void @cqrt_free(i32 %3)
  ret i32 %4
}

define internal i32 @__cq_q_l2_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_l2, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_l2, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %12

7:                                                ; preds = %3
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 3)
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %8, i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 3)
  call void @cqrt_free(i32 %8)
  %10 = load i32, ptr @__cq_act_l2, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_l2, align 4
  ret i32 %9

12:                                               ; preds = %3
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %14)
  %15 = load i32, ptr @__cq_act_l2, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_l2, align 4
  ret i32 %13
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_select_i64_ll(i32, i64, i64)

declare i32 @__cq_clone_count(ptr)

declare ptr @__cq_clone_at(ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare ptr @__cq_clone_resolve(ptr, i32)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %6)
  call void @cqrt_ry_i32(i32 %6, double 1.000000e+00)
  %7 = alloca { i32, ptr }, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 0
  store i32 %6, ptr %8, align 4
  %9 = load ptr, ptr %cq.mints, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 1
  store ptr %9, ptr %10, align 8
  store ptr %7, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %11)
  call void @cqrt_ry_i32(i32 %11, double 1.000000e+00)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cq_template_and_i32_hl(i32 %6, i32 128)
  %17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %16, i32 0)
  %18 = call i32 @cq_template_select_i64_ll(i32 %17, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  %19 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %20 = call i32 @cqrt_alloc_i1(i1 true)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  br label %22

22:                                               ; preds = %27, %3
  %23 = phi i32 [ 0, %3 ], [ %37, %27 ]
  %24 = phi i32 [ %20, %3 ], [ %35, %27 ]
  %25 = phi i32 [ %21, %3 ], [ %36, %27 ]
  %26 = icmp ult i32 %23, %19
  br i1 %26, label %27, label %38

27:                                               ; preds = %22
  %28 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %23)
  %29 = ptrtoint ptr %28 to i64
  %30 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 %29)
  %31 = call ptr @__cq_clone_resolve(ptr %28, i32 1)
  %32 = call i32 %31(i32 %30, i32 %11, i32 %2)
  %33 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %32, i32 %33)
  %34 = call ptr @__cq_clone_resolve(ptr %28, i32 3)
  call void %34(i32 %30, i32 %32, i32 %11, i32 %2)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_and_i1(i32 %24, i32 %30, i32 %35)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_push(i32 %24)
  %36 = call i32 @cq_template_select_i32(i32 %30, i32 %33, i32 %25)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %30)
  %37 = add i32 %23, 1
  br label %22

38:                                               ; preds = %22
  %39 = call i32 @cqrt_tape_write_i64_controlled(i32 %24, i32 %5, i32 %18)
  %40 = call i32 @cqrt_tape_write_i32_controlled(i32 %24, i32 %5, i32 %11)
  %41 = call i32 @cqrt_tape_effect_i32_controlled(i32 %24, i32 %5, ptr null, i32 2)
  %42 = call i32 @cq_template_select_i32(i32 %24, i32 %41, i32 %25)
  %43 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %42, i32 %43)
  call void @cq_template_select_i32_unc(i32 %42, i32 %24, i32 %41, i32 %25)
  call void @cqrt_free(i32 %42)
  br label %44

44:                                               ; preds = %49, %38
  %45 = phi i32 [ %19, %38 ], [ %50, %49 ]
  %46 = phi i32 [ %24, %38 ], [ %54, %49 ]
  %47 = phi i32 [ %25, %38 ], [ %53, %49 ]
  %48 = icmp eq i32 %45, 0
  br i1 %48, label %57, label %49

49:                                               ; preds = %44
  %50 = add i32 %45, -1
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %47, i32 %51, i32 %52, i32 %53)
  call void @cqrt_free(i32 %47)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_and_i1(i32 %54, i32 %51, i32 %46)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_free(i32 %46)
  %55 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %50)
  %56 = ptrtoint ptr %55 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %51, i32 %18, i64 %56)
  call void @cqrt_free(i32 %51)
  br label %44

57:                                               ; preds = %44
  call void @cqrt_free(i32 %46)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i64_ll_unc(i32 %18, i32 %17, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %17, i32 %16, i32 0)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %6, i32 128)
  call void @cqrt_free(i32 %16)
  %58 = call i32 @cqrt_measure_i32(i32 %43), !cq.measure !6
  %59 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64))
  %60 = call i32 @cqrt_measure_i32(i32 %59), !cq.measure !6
  %61 = shl nsw i32 %60, 6
  %62 = add nsw i32 %61, %58
  %63 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %63)
  %64 = call i32 @cqrt_alloc_i32(i32 %62)
  ret i32 %64
}

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

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %74

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %10 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %11)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %11, double 1.000000e+00)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %16)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %16, double 1.000000e+00)
  %17 = alloca { i32, ptr }, align 8
  %18 = getelementptr inbounds { i32, ptr }, ptr %17, i32 0, i32 0
  store i32 %16, ptr %18, align 4
  %19 = load ptr, ptr %cq.mints, align 8
  %20 = getelementptr inbounds { i32, ptr }, ptr %17, i32 0, i32 1
  store ptr %19, ptr %20, align 8
  store ptr %17, ptr %cq.mints, align 8
  %21 = call i32 @cq_template_and_i32_hl(i32 %11, i32 128)
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %21, i32 0)
  %23 = call i32 @cq_template_select_i64_ll(i32 %22, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  %24 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  br label %26

26:                                               ; preds = %31, %8
  %27 = phi i32 [ 0, %8 ], [ %42, %31 ]
  %28 = phi i32 [ %0, %8 ], [ %40, %31 ]
  %29 = phi i32 [ %25, %8 ], [ %41, %31 ]
  %30 = icmp ult i32 %27, %24
  br i1 %30, label %31, label %43

31:                                               ; preds = %26
  %32 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %27)
  %33 = ptrtoint ptr %32 to i64
  %34 = call i32 @cq_template_icmp_eq_i64_hl(i32 %23, i64 %33)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %34, i32 %35)
  %36 = call ptr @__cq_clone_resolve(ptr %32, i32 1)
  %37 = call i32 %36(i32 %35, i32 %16, i32 %3)
  %38 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %37, i32 %38)
  %39 = call ptr @__cq_clone_resolve(ptr %32, i32 3)
  call void %39(i32 %35, i32 %37, i32 %16, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %34, i32 %35)
  call void @cqrt_free(i32 %35)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_and_i1(i32 %28, i32 %34, i32 %40)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_push(i32 %28)
  %41 = call i32 @cq_template_select_i32(i32 %34, i32 %38, i32 %29)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %34)
  %42 = add i32 %27, 1
  br label %26

43:                                               ; preds = %26
  %44 = call i32 @cqrt_tape_write_i64_controlled(i32 %28, i32 %10, i32 %23)
  %45 = call i32 @cqrt_tape_write_i32_controlled(i32 %28, i32 %10, i32 %16)
  %46 = call i32 @cqrt_tape_effect_i32_controlled(i32 %28, i32 %10, ptr null, i32 2)
  %47 = call i32 @cq_template_select_i32(i32 %28, i32 %46, i32 %29)
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %47, i32 %48)
  call void @cq_template_select_i32_unc(i32 %47, i32 %28, i32 %46, i32 %29)
  call void @cqrt_free(i32 %47)
  br label %49

49:                                               ; preds = %54, %43
  %50 = phi i32 [ %24, %43 ], [ %55, %54 ]
  %51 = phi i32 [ %28, %43 ], [ %59, %54 ]
  %52 = phi i32 [ %29, %43 ], [ %58, %54 ]
  %53 = icmp eq i32 %50, 0
  br i1 %53, label %62, label %54

54:                                               ; preds = %49
  %55 = add i32 %50, -1
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %52, i32 %56, i32 %57, i32 %58)
  call void @cqrt_free(i32 %52)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_and_i1(i32 %59, i32 %56, i32 %51)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_free(i32 %51)
  %60 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %55)
  %61 = ptrtoint ptr %60 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %56, i32 %23, i64 %61)
  call void @cqrt_free(i32 %56)
  br label %49

62:                                               ; preds = %49
  call void @cqrt_free(i32 %52)
  call void @cq_template_select_i64_ll_unc(i32 %23, i32 %22, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %21, i32 0)
  call void @cqrt_free(i32 %22)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %11, i32 128)
  call void @cqrt_free(i32 %21)
  %63 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %48, i32 %63)
  %64 = call i32 @cqrt_measure_i32(i32 %63), !cq.measure !6
  %65 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %9, i64 ptrtoint (ptr @g to i64))
  %66 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %65, i32 %66)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %65, i32 %0, i32 %9, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %65)
  %67 = call i32 @cqrt_measure_i32(i32 %66), !cq.measure !6
  %68 = call i32 @cq_template_shl_i32_hl(i32 %66, i32 6)
  %69 = call i32 @cq_template_add_i32(i32 %68, i32 %63)
  %70 = call i32 @cq_template_sub_i32(i32 %69, i32 %63)
  call void @cqrt_copy_i32(i32 %70, i32 %68)
  call void @cq_template_sub_i32_unc(i32 %70, i32 %69, i32 %63)
  call void @cqrt_free(i32 %70)
  call void @cqrt_free(i32 %68)
  %71 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %71)
  %72 = load i32, ptr @__cq_act_f, align 4
  %73 = add i32 %72, -1
  store i32 %73, ptr @__cq_act_f, align 4
  ret i32 %69

74:                                               ; preds = %4
  %75 = call i32 @cqrt_alloc_i32(i32 0)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %76)
  call void @cqrt_push(i32 0)
  %77 = load i32, ptr @__cq_act_f, align 4
  %78 = add i32 %77, -1
  store i32 %78, ptr @__cq_act_f, align 4
  ret i32 %75
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_tape_alloc()
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %6)
  call void @cqrt_ry_i32(i32 %6, double 1.000000e+00)
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %7)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = call i32 @cq_template_and_i32_hl(i32 %6, i32 128)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %10 = call i32 @cq_template_select_i64_ll(i32 %9, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  %11 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %12 = call i32 @cqrt_alloc_i1(i1 true)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  br label %14

14:                                               ; preds = %19, %3
  %15 = phi i32 [ 0, %3 ], [ %29, %19 ]
  %16 = phi i32 [ %12, %3 ], [ %27, %19 ]
  %17 = phi i32 [ %13, %3 ], [ %28, %19 ]
  %18 = icmp ult i32 %15, %11
  br i1 %18, label %19, label %30

19:                                               ; preds = %14
  %20 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %15)
  %21 = ptrtoint ptr %20 to i64
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %10, i64 %21)
  %23 = call ptr @__cq_clone_resolve(ptr %20, i32 1)
  %24 = call i32 %23(i32 %22, i32 %7, i32 %2)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %24, i32 %25)
  %26 = call ptr @__cq_clone_resolve(ptr %20, i32 3)
  call void %26(i32 %22, i32 %24, i32 %7, i32 %2)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_and_i1(i32 %16, i32 %22, i32 %27)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_push(i32 %16)
  %28 = call i32 @cq_template_select_i32(i32 %22, i32 %25, i32 %17)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %22)
  %29 = add i32 %15, 1
  br label %14

30:                                               ; preds = %14
  %31 = call i32 @cqrt_tape_write_i64_controlled(i32 %16, i32 %5, i32 %10)
  %32 = call i32 @cqrt_tape_write_i32_controlled(i32 %16, i32 %5, i32 %7)
  %33 = call i32 @cqrt_tape_effect_i32_controlled(i32 %16, i32 %5, ptr null, i32 2)
  %34 = call i32 @cq_template_select_i32(i32 %16, i32 %33, i32 %17)
  %35 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %34, i32 %35)
  call void @cq_template_select_i32_unc(i32 %34, i32 %16, i32 %33, i32 %17)
  call void @cqrt_free(i32 %34)
  br label %36

36:                                               ; preds = %41, %30
  %37 = phi i32 [ %11, %30 ], [ %42, %41 ]
  %38 = phi i32 [ %16, %30 ], [ %46, %41 ]
  %39 = phi i32 [ %17, %30 ], [ %45, %41 ]
  %40 = icmp eq i32 %37, 0
  br i1 %40, label %49, label %41

41:                                               ; preds = %36
  %42 = add i32 %37, -1
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %39, i32 %43, i32 %44, i32 %45)
  call void @cqrt_free(i32 %39)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_and_i1(i32 %46, i32 %43, i32 %38)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %38)
  %47 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %42)
  %48 = ptrtoint ptr %47 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %10, i64 %48)
  call void @cqrt_free(i32 %43)
  br label %36

49:                                               ; preds = %36
  call void @cqrt_free(i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i64_ll_unc(i32 %10, i32 %9, i64 ptrtoint (ptr @l2 to i64), i64 ptrtoint (ptr @l1 to i64))
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %6, i32 128)
  call void @cqrt_free(i32 %8)
  %50 = call i32 @cqrt_measure_i32(i32 %35), !cq.measure !6
  %51 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64))
  %52 = call i32 @cqrt_measure_i32(i32 %51), !cq.measure !6
  %53 = shl nsw i32 %52, 6
  %54 = add nsw i32 %53, %50
  %55 = call i32 @cqrt_alloc_i32(i32 %54)
  ret i32 %55
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @l1, ptr @.cq.sig, ptr @__cq_q_l1_1_t, ptr @__cq_q_l1_1_t_ctl, ptr @__cq_q_l1_1_t_unc, ptr @__cq_q_l1_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @l2, ptr @.cq.sig, ptr @__cq_q_l2_1_t, ptr @__cq_q_l2_1_t_ctl, ptr @__cq_q_l2_1_t_unc, ptr @__cq_q_l2_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_l1_1_t_unc(i32 %0, i32 %1, i32 %2) {
  ret void
}

define internal void @__cq_q_l1_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_l1, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_l1, align 4
  %7 = load i32, ptr @__cq_act_l1, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_l1, align 4
  ret void
}

define internal void @__cq_q_l2_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  call void @cqrt_copy_i32(i32 %3, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 3)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %out)
  ret void
}

define internal void @__cq_q_l2_1_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_l2, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_l2, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %11

7:                                                ; preds = %3
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 3)
  call void @cqrt_copy_i32(i32 %8, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 3)
  call void @cqrt_free(i32 %8)
  %9 = load i32, ptr @__cq_act_l2, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_l2, align 4
  call void @cqrt_free(i32 %out)
  ret void

11:                                               ; preds = %3
  %12 = load i32, ptr @__cq_act_l2, align 4
  %13 = add i32 %12, -1
  store i32 %13, ptr @__cq_act_l2, align 4
  call void @cqrt_free(i32 %out)
  ret void
}

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

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
