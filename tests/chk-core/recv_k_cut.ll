; ModuleID = 'recv_k_cut.O1.ll'
source_filename = "recv_k_cut.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fp = global ptr @g, align 8
@__cq_k_e = internal constant i32 2, align 4
@llvm.used = appending global [1 x ptr] [ptr @__cq_k_e], section "llvm.metadata"
@__cq_act_g = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@__cq_act_e = internal global i32 0, align 4
@.cq.sig.1 = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @g(i32 noundef %0) #0 {
  %2 = icmp ugt i32 %0, 2
  br i1 %2, label %3, label %18

3:                                                ; preds = %1
  %4 = add i32 %0, -6
  %5 = icmp ult i32 %4, -3
  %6 = select i1 %5, i32 2, i32 1
  br label %7

7:                                                ; preds = %7, %3
  %8 = phi i32 [ %14, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %13, %7 ], [ 1, %3 ]
  %10 = phi i32 [ %11, %7 ], [ %0, %3 ]
  %11 = add i32 %10, -3
  %12 = mul i32 %9, 5
  %13 = add i32 %12, %11
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, %6
  br i1 %15, label %16, label %7, !llvm.loop !6

16:                                               ; preds = %7
  %17 = shl i32 %13, 4
  br label %18

18:                                               ; preds = %16, %1
  %19 = phi i32 [ %0, %1 ], [ %11, %16 ]
  %20 = phi i32 [ 16, %1 ], [ %17, %16 ]
  %21 = add i32 %20, %19
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %5, double %1)
  %6 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr @fp to i64))
  %7 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %8 = call i32 @cqrt_alloc_i1(i1 true)
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  br label %10

10:                                               ; preds = %15, %2
  %11 = phi i32 [ 0, %2 ], [ %25, %15 ]
  %12 = phi i32 [ %8, %2 ], [ %23, %15 ]
  %13 = phi i32 [ %9, %2 ], [ %24, %15 ]
  %14 = icmp ult i32 %11, %7
  br i1 %14, label %15, label %26

15:                                               ; preds = %10
  %16 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %11)
  %17 = ptrtoint ptr %16 to i64
  %18 = call i32 @cq_template_icmp_eq_i64_hl(i32 %6, i64 %17)
  %19 = call ptr @__cq_clone_resolve(ptr %16, i32 1)
  %20 = call i32 %19(i32 %18, i32 %5, i32 2)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %20, i32 %21)
  %22 = call ptr @__cq_clone_resolve(ptr %16, i32 3)
  call void %22(i32 %18, i32 %20, i32 %5, i32 2)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_and_i1(i32 %12, i32 %18, i32 %23)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_push(i32 %12)
  %24 = call i32 @cq_template_select_i32(i32 %18, i32 %21, i32 %13)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %18)
  %25 = add i32 %11, 1
  br label %10

26:                                               ; preds = %10
  %27 = call i32 @cqrt_tape_write_i64_controlled(i32 %12, i32 %3, i32 %6)
  %28 = call i32 @cqrt_tape_write_i32_controlled(i32 %12, i32 %3, i32 %5)
  %29 = call i32 @cqrt_tape_effect_i32_controlled(i32 %12, i32 %3, ptr null, i32 2)
  %30 = call i32 @cq_template_select_i32(i32 %12, i32 %29, i32 %13)
  %31 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %30, i32 %31)
  call void @cq_template_select_i32_unc(i32 %30, i32 %12, i32 %29, i32 %13)
  call void @cqrt_free(i32 %30)
  br label %32

32:                                               ; preds = %37, %26
  %33 = phi i32 [ %7, %26 ], [ %38, %37 ]
  %34 = phi i32 [ %12, %26 ], [ %42, %37 ]
  %35 = phi i32 [ %13, %26 ], [ %41, %37 ]
  %36 = icmp eq i32 %33, 0
  br i1 %36, label %45, label %37

37:                                               ; preds = %32
  %38 = add i32 %33, -1
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %35, i32 %39, i32 %40, i32 %41)
  call void @cqrt_free(i32 %35)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_and_i1(i32 %42, i32 %39, i32 %34)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_free(i32 %34)
  %43 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %38)
  %44 = ptrtoint ptr %43 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %39, i32 %6, i64 %44)
  call void @cqrt_free(i32 %39)
  br label %32

45:                                               ; preds = %32
  call void @cqrt_free(i32 %34)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_load_i64_hl_unc(i32 %6, i32 %4, i64 ptrtoint (ptr @fp to i64))
  %46 = call i32 @cqrt_measure_i32(i32 %31), !cq.measure !9
  ret i32 %46
}

define internal i32 @__cq_q_g_1_t(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %0, i32 2)
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -6)
  %6 = call i32 @cq_template_icmp_ult_i32_hl(i32 %5, i32 -3)
  %7 = call i32 @cq_template_select_i32_ll(i32 %6, i32 2, i32 1)
  br label %8

8:                                                ; preds = %2
  %9 = call i32 @cqrt_alloc_i32(i32 1)
  %10 = icmp ult i32 0, %1
  br i1 %10, label %11, label %32

11:                                               ; preds = %11, %8
  %from = phi i32 [ 0, %11 ], [ 1, %8 ]
  %12 = phi i32 [ 0, %8 ], [ %30, %11 ]
  %13 = phi i32 [ %4, %8 ], [ %25, %11 ]
  %14 = phi i32 [ 0, %8 ], [ %22, %11 ]
  %15 = phi i32 [ %9, %8 ], [ %26, %11 ]
  %16 = phi i32 [ %0, %8 ], [ %29, %11 ]
  %17 = phi i32 [ 0, %8 ], [ %28, %11 ]
  %18 = phi i32 [ %0, %8 ], [ %27, %11 ]
  call void @cqrt_push(i32 %from)
  %19 = call i32 @cq_template_add_i32_hl(i32 %16, i32 -3)
  %20 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 5)
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %19)
  %22 = add i32 %14, 1
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_xor_i1(i32 %23, i32 %24)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %13, i32 %24, i32 %25)
  %26 = call i32 @cq_template_select_i32(i32 %13, i32 %21, i32 %15)
  %27 = call i32 @cq_template_select_i32(i32 %13, i32 %19, i32 %18)
  %28 = add i32 %17, -3
  %29 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %28)
  %30 = add i32 %12, 1
  %31 = icmp ult i32 %30, %1
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %16)
  br i1 %31, label %11, label %32

32:                                               ; preds = %11, %8
  %33 = phi i32 [ 0, %8 ], [ 1, %11 ]
  %34 = phi i32 [ 0, %8 ], [ %22, %11 ]
  %35 = phi i32 [ %9, %8 ], [ %26, %11 ]
  %36 = phi i32 [ %0, %8 ], [ %29, %11 ]
  %37 = phi i32 [ 0, %8 ], [ %28, %11 ]
  %38 = phi i32 [ %0, %8 ], [ %27, %11 ]
  %39 = phi i32 [ %4, %8 ], [ %25, %11 ]
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %39, i32 %40)
  %41 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %38, i32 %41)
  %42 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %35, i32 %42)
  br label %43

43:                                               ; preds = %32
  %44 = call i32 @cq_template_shl_i32_hl(i32 %42, i32 4)
  %45 = call i32 @cq_template_select_i32(i32 %4, i32 %41, i32 %0)
  %46 = call i32 @cq_template_select_i32_hl(i32 %4, i32 %44, i32 16)
  %47 = call i32 @cq_template_add_i32(i32 %46, i32 %45)
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %47, i32 %48)
  call void @cq_template_add_i32_unc(i32 %47, i32 %46, i32 %45)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i32_hl_unc(i32 %46, i32 %4, i32 %44, i32 16)
  call void @cqrt_free(i32 %46)
  call void @cq_template_select_i32_unc(i32 %45, i32 %4, i32 %41, i32 %0)
  call void @cqrt_free(i32 %45)
  call void @cq_template_shl_i32_hl_unc(i32 %44, i32 %42, i32 4)
  call void @cqrt_free(i32 %44)
  br label %68

49:                                               ; preds = %50
  call void @cqrt_free(i32 %9)
  call void @cq_template_select_i32_ll_unc(i32 %7, i32 %6, i32 2, i32 1)
  call void @cqrt_free(i32 %7)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %6, i32 %5, i32 -3)
  call void @cqrt_free(i32 %6)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 -6)
  call void @cqrt_free(i32 %5)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %4, i32 %0, i32 2)
  call void @cqrt_free(i32 %4)
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %48

50:                                               ; preds = %69, %51
  br label %49

51:                                               ; preds = %69, %51
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_hl_unc(i32 %66, i32 %0, i32 %65)
  call void @cqrt_free(i32 %66)
  call void @cq_template_select_i32_unc(i32 %64, i32 %63, i32 %62, i32 %61)
  call void @cqrt_free(i32 %64)
  call void @cq_template_select_i32_unc(i32 %60, i32 %63, i32 %59, i32 %58)
  call void @cqrt_free(i32 %60)
  call void @cqrt_and_i1(i32 %63, i32 %57, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_xor_i1(i32 %55, i32 %57)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %55, i32 %7, i32 %54)
  call void @cqrt_free(i32 %55)
  call void @cq_template_add_i32_unc(i32 %59, i32 %53, i32 %62)
  call void @cqrt_free(i32 %59)
  call void @cq_template_mul_i32_hl_unc(i32 %53, i32 %58, i32 5)
  call void @cqrt_free(i32 %53)
  call void @cq_template_add_i32_hl_unc(i32 %62, i32 %52, i32 -3)
  call void @cqrt_free(i32 %62)
  %67 = call i32 @cqrt_pop()
  switch i32 %67, label %51 [
    i32 1, label %50
  ]

68:                                               ; preds = %43
  call void @cqrt_copy_i32(i32 %35, i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_copy_i32(i32 %38, i32 %41)
  call void @cqrt_free(i32 %41)
  br label %69

69:                                               ; preds = %68
  switch i32 %33, label %50 [
    i32 1, label %51
  ]
}

declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_g_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_g, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_g, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %78

8:                                                ; preds = %3
  %9 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %1, i32 2)
  %10 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -6)
  %11 = call i32 @cq_template_icmp_ult_i32_hl(i32 %10, i32 -3)
  %12 = call i32 @cq_template_select_i32_ll(i32 %11, i32 2, i32 1)
  br label %13

13:                                               ; preds = %8
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %14)
  %15 = call i32 @cqrt_alloc_i32(i32 1)
  %16 = icmp ult i32 0, %2
  br i1 %16, label %17, label %38

17:                                               ; preds = %17, %13
  %from = phi i32 [ 0, %17 ], [ 1, %13 ]
  %18 = phi i32 [ 0, %13 ], [ %36, %17 ]
  %19 = phi i32 [ %14, %13 ], [ %31, %17 ]
  %20 = phi i32 [ 0, %13 ], [ %28, %17 ]
  %21 = phi i32 [ %15, %13 ], [ %32, %17 ]
  %22 = phi i32 [ %1, %13 ], [ %35, %17 ]
  %23 = phi i32 [ 0, %13 ], [ %34, %17 ]
  %24 = phi i32 [ %1, %13 ], [ %33, %17 ]
  call void @cqrt_push(i32 %from)
  %25 = call i32 @cq_template_add_i32_hl(i32 %22, i32 -3)
  %26 = call i32 @cq_template_mul_i32_hl(i32 %21, i32 5)
  %27 = call i32 @cq_template_add_i32(i32 %26, i32 %25)
  %28 = add i32 %20, 1
  %29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 %28)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %29, i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %30, i32 %31)
  %32 = call i32 @cq_template_select_i32(i32 %19, i32 %27, i32 %21)
  %33 = call i32 @cq_template_select_i32(i32 %19, i32 %25, i32 %24)
  %34 = add i32 %23, -3
  %35 = call i32 @cq_template_add_i32_hl(i32 %1, i32 %34)
  %36 = add i32 %18, 1
  %37 = icmp ult i32 %36, %2
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %22)
  br i1 %37, label %17, label %38

38:                                               ; preds = %17, %13
  %39 = phi i32 [ 0, %13 ], [ 1, %17 ]
  %40 = phi i32 [ 0, %13 ], [ %28, %17 ]
  %41 = phi i32 [ %15, %13 ], [ %32, %17 ]
  %42 = phi i32 [ %1, %13 ], [ %35, %17 ]
  %43 = phi i32 [ 0, %13 ], [ %34, %17 ]
  %44 = phi i32 [ %1, %13 ], [ %33, %17 ]
  %45 = phi i32 [ %14, %13 ], [ %31, %17 ]
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %45, i32 %46)
  %47 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %44, i32 %47)
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %41, i32 %48)
  br label %49

49:                                               ; preds = %38
  %50 = call i32 @cq_template_shl_i32_hl(i32 %48, i32 4)
  %51 = call i32 @cq_template_select_i32(i32 %9, i32 %47, i32 %1)
  %52 = call i32 @cq_template_select_i32_hl(i32 %9, i32 %50, i32 16)
  %53 = call i32 @cq_template_add_i32(i32 %52, i32 %51)
  %54 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %53, i32 %54)
  call void @cq_template_add_i32_unc(i32 %53, i32 %52, i32 %51)
  call void @cqrt_free(i32 %53)
  call void @cq_template_select_i32_hl_unc(i32 %52, i32 %9, i32 %50, i32 16)
  call void @cqrt_free(i32 %52)
  call void @cq_template_select_i32_unc(i32 %51, i32 %9, i32 %47, i32 %1)
  call void @cqrt_free(i32 %51)
  call void @cq_template_shl_i32_hl_unc(i32 %50, i32 %48, i32 4)
  call void @cqrt_free(i32 %50)
  br label %76

55:                                               ; preds = %58
  call void @cqrt_free(i32 %15)
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %11, i32 2, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %11, i32 %10, i32 -3)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %1, i32 -6)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %9, i32 %1, i32 2)
  call void @cqrt_free(i32 %9)
  %56 = load i32, ptr @__cq_act_g, align 4
  %57 = add i32 %56, -1
  store i32 %57, ptr @__cq_act_g, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %54

58:                                               ; preds = %77, %59
  br label %55

59:                                               ; preds = %77, %59
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  %67 = call i32 @cqrt_pop()
  %68 = call i32 @cqrt_pop()
  %69 = call i32 @cqrt_pop()
  %70 = call i32 @cqrt_pop()
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  %73 = call i32 @cqrt_pop()
  %74 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_hl_unc(i32 %74, i32 %1, i32 %73)
  call void @cqrt_free(i32 %74)
  call void @cq_template_select_i32_unc(i32 %72, i32 %71, i32 %70, i32 %69)
  call void @cqrt_free(i32 %72)
  call void @cq_template_select_i32_unc(i32 %68, i32 %71, i32 %67, i32 %66)
  call void @cqrt_free(i32 %68)
  call void @cqrt_and_i1(i32 %71, i32 %65, i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cqrt_xor_i1(i32 %63, i32 %65)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %63, i32 %12, i32 %62)
  call void @cqrt_free(i32 %63)
  call void @cq_template_add_i32_unc(i32 %67, i32 %61, i32 %70)
  call void @cqrt_free(i32 %67)
  call void @cq_template_mul_i32_hl_unc(i32 %61, i32 %66, i32 5)
  call void @cqrt_free(i32 %61)
  call void @cq_template_add_i32_hl_unc(i32 %70, i32 %60, i32 -3)
  call void @cqrt_free(i32 %70)
  %75 = call i32 @cqrt_pop()
  switch i32 %75, label %59 [
    i32 1, label %58
  ]

76:                                               ; preds = %49
  call void @cqrt_copy_i32(i32 %41, i32 %48)
  call void @cqrt_free(i32 %48)
  call void @cqrt_copy_i32(i32 %44, i32 %47)
  call void @cqrt_free(i32 %47)
  br label %77

77:                                               ; preds = %76
  switch i32 %39, label %58 [
    i32 1, label %59
  ]

78:                                               ; preds = %3
  %79 = call i32 @cqrt_alloc_i32(i32 0)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %80)
  %81 = load i32, ptr @__cq_act_g, align 4
  %82 = add i32 %81, -1
  store i32 %82, ptr @__cq_act_g, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %79
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

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

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_e_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_tape_alloc()
  %6 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32_qangle(i32 %7, i32 %1)
  %8 = alloca { i32, ptr }, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 0
  store i32 %7, ptr %9, align 4
  %10 = load ptr, ptr %cq.mints, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 1
  store ptr %10, ptr %11, align 8
  store ptr %8, ptr %cq.mints, align 8
  %12 = call i32 @cqrt_qram_load_i64_hl(i32 %6, i64 ptrtoint (ptr @fp to i64))
  %13 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %14 = call i32 @cqrt_alloc_i1(i1 true)
  %15 = call i32 @cqrt_alloc_i32(i32 0)
  br label %16

16:                                               ; preds = %21, %3
  %17 = phi i32 [ 0, %3 ], [ %31, %21 ]
  %18 = phi i32 [ %14, %3 ], [ %29, %21 ]
  %19 = phi i32 [ %15, %3 ], [ %30, %21 ]
  %20 = icmp ult i32 %17, %13
  br i1 %20, label %21, label %32

21:                                               ; preds = %16
  %22 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %17)
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 %23)
  %25 = call ptr @__cq_clone_resolve(ptr %22, i32 1)
  %26 = call i32 %25(i32 %24, i32 %7, i32 %2)
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %26, i32 %27)
  %28 = call ptr @__cq_clone_resolve(ptr %22, i32 3)
  call void %28(i32 %24, i32 %26, i32 %7, i32 %2)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_and_i1(i32 %18, i32 %24, i32 %29)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_push(i32 %18)
  %30 = call i32 @cq_template_select_i32(i32 %24, i32 %27, i32 %19)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %24)
  %31 = add i32 %17, 1
  br label %16

32:                                               ; preds = %16
  %33 = call i32 @cqrt_tape_write_i64_controlled(i32 %18, i32 %5, i32 %12)
  %34 = call i32 @cqrt_tape_write_i32_controlled(i32 %18, i32 %5, i32 %7)
  %35 = call i32 @cqrt_tape_effect_i32_controlled(i32 %18, i32 %5, ptr null, i32 2)
  %36 = call i32 @cq_template_select_i32(i32 %18, i32 %35, i32 %19)
  %37 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %36, i32 %37)
  call void @cq_template_select_i32_unc(i32 %36, i32 %18, i32 %35, i32 %19)
  call void @cqrt_free(i32 %36)
  br label %38

38:                                               ; preds = %43, %32
  %39 = phi i32 [ %13, %32 ], [ %44, %43 ]
  %40 = phi i32 [ %18, %32 ], [ %48, %43 ]
  %41 = phi i32 [ %19, %32 ], [ %47, %43 ]
  %42 = icmp eq i32 %39, 0
  br i1 %42, label %51, label %43

43:                                               ; preds = %38
  %44 = add i32 %39, -1
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  %48 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %41, i32 %45, i32 %46, i32 %47)
  call void @cqrt_free(i32 %41)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_and_i1(i32 %48, i32 %45, i32 %40)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_free(i32 %40)
  %49 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %44)
  %50 = ptrtoint ptr %49 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %45, i32 %12, i64 %50)
  call void @cqrt_free(i32 %45)
  br label %38

51:                                               ; preds = %38
  call void @cqrt_free(i32 %40)
  call void @cqrt_free(i32 %41)
  call void @cqrt_qram_load_i64_hl_unc(i32 %12, i32 %6, i64 ptrtoint (ptr @fp to i64))
  %52 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %37, i32 %52)
  %53 = call i32 @cqrt_measure_i32(i32 %52), !cq.measure !9
  %54 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %54)
  %55 = call i32 @cqrt_alloc_i32(i32 %53)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %55
}

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

define internal i32 @__cq_q_e_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_e, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_e, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %62

9:                                                ; preds = %4
  %10 = call i32 @cqrt_tape_alloc()
  %11 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %12, i32 %2)
  %13 = alloca { i32, ptr }, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 0
  store i32 %12, ptr %14, align 4
  %15 = load ptr, ptr %cq.mints, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 1
  store ptr %15, ptr %16, align 8
  store ptr %13, ptr %cq.mints, align 8
  %17 = call i32 @cqrt_qram_load_i64_hl(i32 %11, i64 ptrtoint (ptr @fp to i64))
  %18 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  br label %20

20:                                               ; preds = %25, %9
  %21 = phi i32 [ 0, %9 ], [ %36, %25 ]
  %22 = phi i32 [ %0, %9 ], [ %34, %25 ]
  %23 = phi i32 [ %19, %9 ], [ %35, %25 ]
  %24 = icmp ult i32 %21, %18
  br i1 %24, label %25, label %37

25:                                               ; preds = %20
  %26 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %21)
  %27 = ptrtoint ptr %26 to i64
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 %27)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %29)
  %30 = call ptr @__cq_clone_resolve(ptr %26, i32 1)
  %31 = call i32 %30(i32 %29, i32 %12, i32 %3)
  %32 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %31, i32 %32)
  %33 = call ptr @__cq_clone_resolve(ptr %26, i32 3)
  call void %33(i32 %29, i32 %31, i32 %12, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %29)
  call void @cqrt_free(i32 %29)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_and_i1(i32 %22, i32 %28, i32 %34)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_push(i32 %22)
  %35 = call i32 @cq_template_select_i32(i32 %28, i32 %32, i32 %23)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %28)
  %36 = add i32 %21, 1
  br label %20

37:                                               ; preds = %20
  %38 = call i32 @cqrt_tape_write_i64_controlled(i32 %22, i32 %10, i32 %17)
  %39 = call i32 @cqrt_tape_write_i32_controlled(i32 %22, i32 %10, i32 %12)
  %40 = call i32 @cqrt_tape_effect_i32_controlled(i32 %22, i32 %10, ptr null, i32 2)
  %41 = call i32 @cq_template_select_i32(i32 %22, i32 %40, i32 %23)
  %42 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %41, i32 %42)
  call void @cq_template_select_i32_unc(i32 %41, i32 %22, i32 %40, i32 %23)
  call void @cqrt_free(i32 %41)
  br label %43

43:                                               ; preds = %48, %37
  %44 = phi i32 [ %18, %37 ], [ %49, %48 ]
  %45 = phi i32 [ %22, %37 ], [ %53, %48 ]
  %46 = phi i32 [ %23, %37 ], [ %52, %48 ]
  %47 = icmp eq i32 %44, 0
  br i1 %47, label %56, label %48

48:                                               ; preds = %43
  %49 = add i32 %44, -1
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %46, i32 %50, i32 %51, i32 %52)
  call void @cqrt_free(i32 %46)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_and_i1(i32 %53, i32 %50, i32 %45)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_free(i32 %45)
  %54 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %49)
  %55 = ptrtoint ptr %54 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %50, i32 %17, i64 %55)
  call void @cqrt_free(i32 %50)
  br label %43

56:                                               ; preds = %43
  call void @cqrt_free(i32 %46)
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %11, i64 ptrtoint (ptr @fp to i64))
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %42, i32 %57)
  %58 = call i32 @cqrt_measure_i32(i32 %57), !cq.measure !9
  %59 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %59)
  %60 = load i32, ptr @__cq_act_e, align 4
  %61 = add i32 %60, -1
  store i32 %61, ptr @__cq_act_e, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %57

62:                                               ; preds = %4
  %63 = call i32 @cqrt_alloc_i32(i32 0)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %64)
  call void @cqrt_push(i32 0)
  %65 = load i32, ptr @__cq_act_e, align 4
  %66 = add i32 %65, -1
  store i32 %66, ptr @__cq_act_e, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %63
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

define internal i32 @__cq_q_e_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_tape_alloc()
  %6 = call i32 @__cq_mem()
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32_qangle(i32 %7, i32 %1)
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %6, i64 ptrtoint (ptr @fp to i64))
  %9 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %10 = call i32 @cqrt_alloc_i1(i1 true)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  br label %12

12:                                               ; preds = %17, %3
  %13 = phi i32 [ 0, %3 ], [ %27, %17 ]
  %14 = phi i32 [ %10, %3 ], [ %25, %17 ]
  %15 = phi i32 [ %11, %3 ], [ %26, %17 ]
  %16 = icmp ult i32 %13, %9
  br i1 %16, label %17, label %28

17:                                               ; preds = %12
  %18 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %13)
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %8, i64 %19)
  %21 = call ptr @__cq_clone_resolve(ptr %18, i32 1)
  %22 = call i32 %21(i32 %20, i32 %7, i32 %2)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %22, i32 %23)
  %24 = call ptr @__cq_clone_resolve(ptr %18, i32 3)
  call void %24(i32 %20, i32 %22, i32 %7, i32 %2)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_and_i1(i32 %14, i32 %20, i32 %25)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_push(i32 %14)
  %26 = call i32 @cq_template_select_i32(i32 %20, i32 %23, i32 %15)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %20)
  %27 = add i32 %13, 1
  br label %12

28:                                               ; preds = %12
  %29 = call i32 @cqrt_tape_write_i64_controlled(i32 %14, i32 %5, i32 %8)
  %30 = call i32 @cqrt_tape_write_i32_controlled(i32 %14, i32 %5, i32 %7)
  %31 = call i32 @cqrt_tape_effect_i32_controlled(i32 %14, i32 %5, ptr null, i32 2)
  %32 = call i32 @cq_template_select_i32(i32 %14, i32 %31, i32 %15)
  %33 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %32, i32 %33)
  call void @cq_template_select_i32_unc(i32 %32, i32 %14, i32 %31, i32 %15)
  call void @cqrt_free(i32 %32)
  br label %34

34:                                               ; preds = %39, %28
  %35 = phi i32 [ %9, %28 ], [ %40, %39 ]
  %36 = phi i32 [ %14, %28 ], [ %44, %39 ]
  %37 = phi i32 [ %15, %28 ], [ %43, %39 ]
  %38 = icmp eq i32 %35, 0
  br i1 %38, label %47, label %39

39:                                               ; preds = %34
  %40 = add i32 %35, -1
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %37, i32 %41, i32 %42, i32 %43)
  call void @cqrt_free(i32 %37)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_and_i1(i32 %44, i32 %41, i32 %36)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_free(i32 %36)
  %45 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %40)
  %46 = ptrtoint ptr %45 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %41, i32 %8, i64 %46)
  call void @cqrt_free(i32 %41)
  br label %34

47:                                               ; preds = %34
  call void @cqrt_free(i32 %36)
  call void @cqrt_free(i32 %37)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %6, i64 ptrtoint (ptr @fp to i64))
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %33, i32 %48)
  %49 = call i32 @cqrt_measure_i32(i32 %48), !cq.measure !9
  %50 = call i32 @cqrt_alloc_i32(i32 %49)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %50
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @g, ptr @.cq.sig, ptr @__cq_q_g_1_t, ptr @__cq_q_g_1_t_ctl, ptr @__cq_q_g_1_t_unc, ptr @__cq_q_g_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @e, ptr @.cq.sig.1, ptr @__cq_q_e_11_t, ptr @__cq_q_e_11_t_ctl, ptr @__cq_q_e_11_t_unc, ptr @__cq_q_e_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_g_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %0, i32 2)
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -6)
  %6 = call i32 @cq_template_icmp_ult_i32_hl(i32 %5, i32 -3)
  %7 = call i32 @cq_template_select_i32_ll(i32 %6, i32 2, i32 1)
  br label %8

8:                                                ; preds = %2
  %9 = call i32 @cqrt_alloc_i32(i32 1)
  %10 = icmp ult i32 0, %1
  br i1 %10, label %11, label %32

11:                                               ; preds = %11, %8
  %from = phi i32 [ 0, %11 ], [ 1, %8 ]
  %12 = phi i32 [ 0, %8 ], [ %30, %11 ]
  %13 = phi i32 [ %4, %8 ], [ %25, %11 ]
  %14 = phi i32 [ 0, %8 ], [ %22, %11 ]
  %15 = phi i32 [ %9, %8 ], [ %26, %11 ]
  %16 = phi i32 [ %0, %8 ], [ %29, %11 ]
  %17 = phi i32 [ 0, %8 ], [ %28, %11 ]
  %18 = phi i32 [ %0, %8 ], [ %27, %11 ]
  call void @cqrt_push(i32 %from)
  %19 = call i32 @cq_template_add_i32_hl(i32 %16, i32 -3)
  %20 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 5)
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %19)
  %22 = add i32 %14, 1
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_xor_i1(i32 %23, i32 %24)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %13, i32 %24, i32 %25)
  %26 = call i32 @cq_template_select_i32(i32 %13, i32 %21, i32 %15)
  %27 = call i32 @cq_template_select_i32(i32 %13, i32 %19, i32 %18)
  %28 = add i32 %17, -3
  %29 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %28)
  %30 = add i32 %12, 1
  %31 = icmp ult i32 %30, %1
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %16)
  br i1 %31, label %11, label %32

32:                                               ; preds = %11, %8
  %33 = phi i32 [ 0, %8 ], [ 1, %11 ]
  %34 = phi i32 [ %9, %8 ], [ %26, %11 ]
  %35 = phi i32 [ %0, %8 ], [ %27, %11 ]
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %35, i32 %36)
  %37 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %34, i32 %37)
  br label %38

38:                                               ; preds = %32
  %39 = call i32 @cq_template_shl_i32_hl(i32 %37, i32 4)
  %40 = call i32 @cq_template_select_i32(i32 %4, i32 %36, i32 %0)
  %41 = call i32 @cq_template_select_i32_hl(i32 %4, i32 %39, i32 16)
  %42 = call i32 @cq_template_add_i32(i32 %41, i32 %40)
  call void @cqrt_copy_i32(i32 %42, i32 %out)
  call void @cq_template_add_i32_unc(i32 %42, i32 %41, i32 %40)
  call void @cqrt_free(i32 %42)
  call void @cq_template_select_i32_hl_unc(i32 %41, i32 %4, i32 %39, i32 16)
  call void @cqrt_free(i32 %41)
  call void @cq_template_select_i32_unc(i32 %40, i32 %4, i32 %36, i32 %0)
  call void @cqrt_free(i32 %40)
  call void @cq_template_shl_i32_hl_unc(i32 %39, i32 %37, i32 4)
  call void @cqrt_free(i32 %39)
  br label %62

43:                                               ; preds = %44
  call void @cqrt_free(i32 %9)
  call void @cq_template_select_i32_ll_unc(i32 %7, i32 %6, i32 2, i32 1)
  call void @cqrt_free(i32 %7)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %6, i32 %5, i32 -3)
  call void @cqrt_free(i32 %6)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 -6)
  call void @cqrt_free(i32 %5)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %4, i32 %0, i32 2)
  call void @cqrt_free(i32 %4)
  call void @cqrt_free(i32 %out)
  store i32 %3, ptr @__cq_k, align 4
  ret void

44:                                               ; preds = %63, %45
  br label %43

45:                                               ; preds = %63, %45
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  %48 = call i32 @cqrt_pop()
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_hl_unc(i32 %60, i32 %0, i32 %59)
  call void @cqrt_free(i32 %60)
  call void @cq_template_select_i32_unc(i32 %58, i32 %57, i32 %56, i32 %55)
  call void @cqrt_free(i32 %58)
  call void @cq_template_select_i32_unc(i32 %54, i32 %57, i32 %53, i32 %52)
  call void @cqrt_free(i32 %54)
  call void @cqrt_and_i1(i32 %57, i32 %51, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cqrt_xor_i1(i32 %49, i32 %51)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %49, i32 %7, i32 %48)
  call void @cqrt_free(i32 %49)
  call void @cq_template_add_i32_unc(i32 %53, i32 %47, i32 %56)
  call void @cqrt_free(i32 %53)
  call void @cq_template_mul_i32_hl_unc(i32 %47, i32 %52, i32 5)
  call void @cqrt_free(i32 %47)
  call void @cq_template_add_i32_hl_unc(i32 %56, i32 %46, i32 -3)
  call void @cqrt_free(i32 %56)
  %61 = call i32 @cqrt_pop()
  switch i32 %61, label %45 [
    i32 1, label %44
  ]

62:                                               ; preds = %38
  call void @cqrt_copy_i32(i32 %34, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_copy_i32(i32 %35, i32 %36)
  call void @cqrt_free(i32 %36)
  br label %63

63:                                               ; preds = %62
  switch i32 %33, label %44 [
    i32 1, label %45
  ]
}

define internal void @__cq_q_g_1_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_g, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_g, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %72

8:                                                ; preds = %3
  %9 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %1, i32 2)
  %10 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -6)
  %11 = call i32 @cq_template_icmp_ult_i32_hl(i32 %10, i32 -3)
  %12 = call i32 @cq_template_select_i32_ll(i32 %11, i32 2, i32 1)
  br label %13

13:                                               ; preds = %8
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %14)
  %15 = call i32 @cqrt_alloc_i32(i32 1)
  %16 = icmp ult i32 0, %2
  br i1 %16, label %17, label %38

17:                                               ; preds = %17, %13
  %from = phi i32 [ 0, %17 ], [ 1, %13 ]
  %18 = phi i32 [ 0, %13 ], [ %36, %17 ]
  %19 = phi i32 [ %14, %13 ], [ %31, %17 ]
  %20 = phi i32 [ 0, %13 ], [ %28, %17 ]
  %21 = phi i32 [ %15, %13 ], [ %32, %17 ]
  %22 = phi i32 [ %1, %13 ], [ %35, %17 ]
  %23 = phi i32 [ 0, %13 ], [ %34, %17 ]
  %24 = phi i32 [ %1, %13 ], [ %33, %17 ]
  call void @cqrt_push(i32 %from)
  %25 = call i32 @cq_template_add_i32_hl(i32 %22, i32 -3)
  %26 = call i32 @cq_template_mul_i32_hl(i32 %21, i32 5)
  %27 = call i32 @cq_template_add_i32(i32 %26, i32 %25)
  %28 = add i32 %20, 1
  %29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 %28)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %29, i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %30, i32 %31)
  %32 = call i32 @cq_template_select_i32(i32 %19, i32 %27, i32 %21)
  %33 = call i32 @cq_template_select_i32(i32 %19, i32 %25, i32 %24)
  %34 = add i32 %23, -3
  %35 = call i32 @cq_template_add_i32_hl(i32 %1, i32 %34)
  %36 = add i32 %18, 1
  %37 = icmp ult i32 %36, %2
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %22)
  br i1 %37, label %17, label %38

38:                                               ; preds = %17, %13
  %39 = phi i32 [ 0, %13 ], [ 1, %17 ]
  %40 = phi i32 [ %15, %13 ], [ %32, %17 ]
  %41 = phi i32 [ %1, %13 ], [ %33, %17 ]
  %42 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %41, i32 %42)
  %43 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %40, i32 %43)
  br label %44

44:                                               ; preds = %38
  %45 = call i32 @cq_template_shl_i32_hl(i32 %43, i32 4)
  %46 = call i32 @cq_template_select_i32(i32 %9, i32 %42, i32 %1)
  %47 = call i32 @cq_template_select_i32_hl(i32 %9, i32 %45, i32 16)
  %48 = call i32 @cq_template_add_i32(i32 %47, i32 %46)
  call void @cqrt_copy_i32(i32 %48, i32 %out)
  call void @cq_template_add_i32_unc(i32 %48, i32 %47, i32 %46)
  call void @cqrt_free(i32 %48)
  call void @cq_template_select_i32_hl_unc(i32 %47, i32 %9, i32 %45, i32 16)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i32_unc(i32 %46, i32 %9, i32 %42, i32 %1)
  call void @cqrt_free(i32 %46)
  call void @cq_template_shl_i32_hl_unc(i32 %45, i32 %43, i32 4)
  call void @cqrt_free(i32 %45)
  br label %70

49:                                               ; preds = %52
  call void @cqrt_free(i32 %15)
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %11, i32 2, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %11, i32 %10, i32 -3)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %1, i32 -6)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %9, i32 %1, i32 2)
  call void @cqrt_free(i32 %9)
  %50 = load i32, ptr @__cq_act_g, align 4
  %51 = add i32 %50, -1
  store i32 %51, ptr @__cq_act_g, align 4
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void

52:                                               ; preds = %71, %53
  br label %49

53:                                               ; preds = %71, %53
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  %67 = call i32 @cqrt_pop()
  %68 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_hl_unc(i32 %68, i32 %1, i32 %67)
  call void @cqrt_free(i32 %68)
  call void @cq_template_select_i32_unc(i32 %66, i32 %65, i32 %64, i32 %63)
  call void @cqrt_free(i32 %66)
  call void @cq_template_select_i32_unc(i32 %62, i32 %65, i32 %61, i32 %60)
  call void @cqrt_free(i32 %62)
  call void @cqrt_and_i1(i32 %65, i32 %59, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_xor_i1(i32 %57, i32 %59)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %57, i32 %12, i32 %56)
  call void @cqrt_free(i32 %57)
  call void @cq_template_add_i32_unc(i32 %61, i32 %55, i32 %64)
  call void @cqrt_free(i32 %61)
  call void @cq_template_mul_i32_hl_unc(i32 %55, i32 %60, i32 5)
  call void @cqrt_free(i32 %55)
  call void @cq_template_add_i32_hl_unc(i32 %64, i32 %54, i32 -3)
  call void @cqrt_free(i32 %64)
  %69 = call i32 @cqrt_pop()
  switch i32 %69, label %53 [
    i32 1, label %52
  ]

70:                                               ; preds = %44
  call void @cqrt_copy_i32(i32 %40, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cqrt_copy_i32(i32 %41, i32 %42)
  call void @cqrt_free(i32 %42)
  br label %71

71:                                               ; preds = %70
  switch i32 %39, label %52 [
    i32 1, label %53
  ]

72:                                               ; preds = %3
  %73 = load i32, ptr @__cq_act_g, align 4
  %74 = add i32 %73, -1
  store i32 %74, ptr @__cq_act_g, align 4
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_e_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  br label %7

7:                                                ; preds = %10, %4
  %8 = phi i32 [ %6, %4 ], [ %12, %10 ]
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %13, label %10

10:                                               ; preds = %7
  %11 = call i32 @cqrt_pop()
  %12 = sub i32 %8, 1
  br label %7

13:                                               ; preds = %7
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_e_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_e, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_e, align 4
  %9 = load i32, ptr @__cq_act_e, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_e, align 4
  %11 = call i32 @cqrt_pop()
  br label %12

12:                                               ; preds = %15, %5
  %13 = phi i32 [ %11, %5 ], [ %17, %15 ]
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %18, label %15

15:                                               ; preds = %12
  %16 = call i32 @cqrt_pop()
  %17 = sub i32 %13, 1
  br label %12

18:                                               ; preds = %12
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{}
