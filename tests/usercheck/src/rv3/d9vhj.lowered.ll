; ModuleID = '<stdin>'
source_filename = "d9vhj.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@__cq_act_fa = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig.1 = private unnamed_addr constant [20 x i8] c"i32 (i32, i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @fa(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %3)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 1)
  %5 = call i32 @cq_template_sub_i32_hl(i32 %4, i32 1)
  call void @cqrt_copy_i32(i32 %5, i32 %3)
  call void @cq_template_sub_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cqrt_free(i32 %3)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %4)
  call void @cqrt_free(i32 %4)
  %6 = add nsw i32 %0, 1
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_tape_alloc()
  %6 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %6, double 1.000000e+00)
  %7 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %10 = call i32 @cq_template_select_i64_ll(i32 %9, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
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
  %24 = call i32 %23(i32 %22, i32 %7, i32 4)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %24, i32 %25)
  %26 = call ptr @__cq_clone_resolve(ptr %20, i32 3)
  call void %26(i32 %22, i32 %24, i32 %7, i32 4)
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
  %33 = call i32 @cqrt_tape_effect_i32_controlled(i32 %16, i32 %5, ptr null)
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
  %50 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)
  %51 = call i32 @cq_template_icmp_eq_i32_hl(i32 %50, i32 0)
  %52 = icmp sgt i32 %2, 0
  %53 = select i1 %52, ptr @abs, ptr @fa
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_xor_i1(i32 %51, i32 %54)
  %55 = call ptr @__cq_clone_resolve(ptr %53, i32 1)
  %56 = icmp eq ptr %55, null
  br i1 %56, label %61, label %57

57:                                               ; preds = %49
  %58 = call i32 %55(i32 %54, i32 %6, i32 4)
  %59 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %58, i32 %59)
  %60 = call ptr @__cq_clone_resolve(ptr %53, i32 3)
  call void %60(i32 %54, i32 %58, i32 %6, i32 4)
  br label %65

61:                                               ; preds = %49
  %62 = ptrtoint ptr %53 to i64
  call void @cqrt_tape_write_i64_lit(i32 %5, i64 %62)
  %63 = call i32 @cqrt_tape_write_i32_controlled(i32 %54, i32 %5, i32 %6)
  %64 = call i32 @cqrt_tape_effect_i32_controlled(i32 %54, i32 %5, ptr null)
  br label %65

65:                                               ; preds = %61, %57
  %66 = phi i32 [ %59, %57 ], [ %64, %61 ]
  call void @cqrt_xor_i1(i32 %51, i32 %54)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_free(i32 %54)
  call void @cq_template_select_i64_ll_unc(i32 %10, i32 %9, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %6, i32 1)
  call void @cqrt_free(i32 %8)
  %67 = call i32 @cq_template_select_i32_lh(i32 %51, i32 0, i32 %66)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %51, i32 %50, i32 0)
  call void @cqrt_free(i32 %51)
  call void @cq_template_and_i32_hl_unc(i32 %50, i32 %7, i32 1)
  call void @cqrt_free(i32 %50)
  %68 = call i32 @cqrt_measure_i32(i32 %35), !cq.measure !6
  %69 = call i32 @cqrt_measure_i32(i32 %67), !cq.measure !6
  %70 = mul nsw i32 %69, 3
  %71 = add nsw i32 %70, %68
  %72 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64))
  %73 = call i32 @cqrt_measure_i32(i32 %72), !cq.measure !6
  %74 = mul nsw i32 %73, 5
  %75 = add nsw i32 %71, %74
  ret i32 %75
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare i32 @abs(i32 noundef) local_unnamed_addr #2

declare i32 @cqrt_alloc_i32(i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

define internal i32 @__cq_q_fa_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %4)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 1)
  call void @cqrt_copy_i32(i32 %6, i32 %4)
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  call void @cqrt_free(i32 %4)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %5)
  call void @cqrt_free(i32 %5)
  %7 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %7, i32 %8)
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %0, i32 1)
  call void @cqrt_free(i32 %7)
  ret i32 %8
}

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_fa_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_fa, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_fa, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %18

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @g to i64), i32 %9)
  %10 = call i32 @cq_template_add_i32_hl(i32 %9, i32 1)
  %11 = call i32 @cq_template_select_i32(i32 %0, i32 %10, i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %9, i32 1)
  call void @cqrt_free(i32 %10)
  %12 = call i32 @cq_template_sub_i32_hl(i32 %11, i32 1)
  %13 = call i32 @cq_template_select_i32(i32 %0, i32 %12, i32 %11)
  call void @cqrt_copy_i32(i32 %13, i32 %9)
  call void @cq_template_select_i32_unc(i32 %13, i32 %0, i32 %12, i32 %11)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sub_i32_hl_unc(i32 %12, i32 %11, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %8, i64 ptrtoint (ptr @g to i64), i32 %11)
  call void @cqrt_free(i32 %11)
  %14 = call i32 @cq_template_add_i32_hl(i32 %1, i32 1)
  %15 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %14, i32 %15)
  call void @cq_template_add_i32_hl_unc(i32 %14, i32 %1, i32 1)
  call void @cqrt_free(i32 %14)
  %16 = load i32, ptr @__cq_act_fa, align 4
  %17 = add i32 %16, -1
  store i32 %17, ptr @__cq_act_fa, align 4
  ret i32 %15

18:                                               ; preds = %3
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %20)
  %21 = load i32, ptr @__cq_act_fa, align 4
  %22 = add i32 %21, -1
  store i32 %22, ptr @__cq_act_fa, align 4
  ret i32 %19
}

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_select_i64_ll(i32, i64, i64)

declare i32 @__cq_clone_count(ptr)

declare void @cqrt_push(i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare ptr @__cq_clone_at(ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare ptr @__cq_clone_resolve(ptr, i32)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr)

declare i32 @cqrt_pop()

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = alloca { i32, ptr }, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 0
  store i32 %7, ptr %9, align 4
  %10 = load ptr, ptr %cq.mints, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 1
  store ptr %10, ptr %11, align 8
  store ptr %8, ptr %cq.mints, align 8
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32(i32 %12, double 1.000000e+00)
  %13 = alloca { i32, ptr }, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 0
  store i32 %12, ptr %14, align 4
  %15 = load ptr, ptr %cq.mints, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 1
  store ptr %15, ptr %16, align 8
  store ptr %13, ptr %cq.mints, align 8
  %17 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 0)
  %19 = call i32 @cq_template_select_i64_ll(i32 %18, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  %20 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %21 = call i32 @cqrt_alloc_i1(i1 true)
  %22 = call i32 @cqrt_alloc_i32(i32 0)
  br label %23

23:                                               ; preds = %28, %4
  %24 = phi i32 [ 0, %4 ], [ %38, %28 ]
  %25 = phi i32 [ %21, %4 ], [ %36, %28 ]
  %26 = phi i32 [ %22, %4 ], [ %37, %28 ]
  %27 = icmp ult i32 %24, %20
  br i1 %27, label %28, label %39

28:                                               ; preds = %23
  %29 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %24)
  %30 = ptrtoint ptr %29 to i64
  %31 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 %30)
  %32 = call ptr @__cq_clone_resolve(ptr %29, i32 1)
  %33 = call i32 %32(i32 %31, i32 %12, i32 %3)
  %34 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %33, i32 %34)
  %35 = call ptr @__cq_clone_resolve(ptr %29, i32 3)
  call void %35(i32 %31, i32 %33, i32 %12, i32 %3)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_and_i1(i32 %25, i32 %31, i32 %36)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_push(i32 %25)
  %37 = call i32 @cq_template_select_i32(i32 %31, i32 %34, i32 %26)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %31)
  %38 = add i32 %24, 1
  br label %23

39:                                               ; preds = %23
  %40 = call i32 @cqrt_tape_write_i64_controlled(i32 %25, i32 %6, i32 %19)
  %41 = call i32 @cqrt_tape_write_i32_controlled(i32 %25, i32 %6, i32 %12)
  %42 = call i32 @cqrt_tape_effect_i32_controlled(i32 %25, i32 %6, ptr null)
  %43 = call i32 @cq_template_select_i32(i32 %25, i32 %42, i32 %26)
  %44 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %43, i32 %44)
  call void @cq_template_select_i32_unc(i32 %43, i32 %25, i32 %42, i32 %26)
  call void @cqrt_free(i32 %43)
  br label %45

45:                                               ; preds = %50, %39
  %46 = phi i32 [ %20, %39 ], [ %51, %50 ]
  %47 = phi i32 [ %25, %39 ], [ %55, %50 ]
  %48 = phi i32 [ %26, %39 ], [ %54, %50 ]
  %49 = icmp eq i32 %46, 0
  br i1 %49, label %58, label %50

50:                                               ; preds = %45
  %51 = add i32 %46, -1
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %48, i32 %52, i32 %53, i32 %54)
  call void @cqrt_free(i32 %48)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_and_i1(i32 %55, i32 %52, i32 %47)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_free(i32 %47)
  %56 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %51)
  %57 = ptrtoint ptr %56 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %52, i32 %19, i64 %57)
  call void @cqrt_free(i32 %52)
  br label %45

58:                                               ; preds = %45
  call void @cqrt_free(i32 %47)
  call void @cqrt_free(i32 %48)
  %59 = call i32 @cq_template_and_i32_hl(i32 %12, i32 1)
  %60 = call i32 @cq_template_icmp_eq_i32_hl(i32 %59, i32 0)
  %61 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 0)
  %62 = call i32 @cq_template_select_i64_ll(i32 %61, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_xor_i1(i32 %60, i32 %63)
  %64 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %65 = call i32 @cqrt_alloc_i32(i32 0)
  br label %66

66:                                               ; preds = %71, %58
  %67 = phi i32 [ 0, %58 ], [ %82, %71 ]
  %68 = phi i32 [ %63, %58 ], [ %80, %71 ]
  %69 = phi i32 [ %65, %58 ], [ %81, %71 ]
  %70 = icmp ult i32 %67, %64
  br i1 %70, label %71, label %83

71:                                               ; preds = %66
  %72 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %67)
  %73 = ptrtoint ptr %72 to i64
  %74 = call i32 @cq_template_icmp_eq_i64_hl(i32 %62, i64 %73)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %63, i32 %74, i32 %75)
  %76 = call ptr @__cq_clone_resolve(ptr %72, i32 1)
  %77 = call i32 %76(i32 %75, i32 %7, i32 %3)
  %78 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %77, i32 %78)
  %79 = call ptr @__cq_clone_resolve(ptr %72, i32 3)
  call void %79(i32 %75, i32 %77, i32 %7, i32 %3)
  call void @cqrt_and_i1(i32 %63, i32 %74, i32 %75)
  call void @cqrt_free(i32 %75)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_and_i1(i32 %68, i32 %74, i32 %80)
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_push(i32 %68)
  %81 = call i32 @cq_template_select_i32(i32 %74, i32 %78, i32 %69)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %74)
  %82 = add i32 %67, 1
  br label %66

83:                                               ; preds = %66
  %84 = call i32 @cqrt_tape_write_i64_controlled(i32 %68, i32 %6, i32 %62)
  %85 = call i32 @cqrt_tape_write_i32_controlled(i32 %68, i32 %6, i32 %7)
  %86 = call i32 @cqrt_tape_effect_i32_controlled(i32 %68, i32 %6, ptr null)
  %87 = call i32 @cq_template_select_i32(i32 %68, i32 %86, i32 %69)
  %88 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %87, i32 %88)
  call void @cq_template_select_i32_unc(i32 %87, i32 %68, i32 %86, i32 %69)
  call void @cqrt_free(i32 %87)
  br label %89

89:                                               ; preds = %94, %83
  %90 = phi i32 [ %64, %83 ], [ %95, %94 ]
  %91 = phi i32 [ %68, %83 ], [ %99, %94 ]
  %92 = phi i32 [ %69, %83 ], [ %98, %94 ]
  %93 = icmp eq i32 %90, 0
  br i1 %93, label %102, label %94

94:                                               ; preds = %89
  %95 = add i32 %90, -1
  %96 = call i32 @cqrt_pop()
  %97 = call i32 @cqrt_pop()
  %98 = call i32 @cqrt_pop()
  %99 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %92, i32 %96, i32 %97, i32 %98)
  call void @cqrt_free(i32 %92)
  call void @cqrt_not_i1(i32 %96)
  call void @cqrt_and_i1(i32 %99, i32 %96, i32 %91)
  call void @cqrt_not_i1(i32 %96)
  call void @cqrt_free(i32 %91)
  %100 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %95)
  %101 = ptrtoint ptr %100 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %96, i32 %62, i64 %101)
  call void @cqrt_free(i32 %96)
  br label %89

102:                                              ; preds = %89
  call void @cq_template_select_i64_ll_unc(i32 %19, i32 %18, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %18, i32 %17, i32 0)
  call void @cqrt_free(i32 %18)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %7, i32 1)
  call void @cqrt_free(i32 %17)
  call void @cqrt_free(i32 %92)
  call void @cqrt_xor_i1(i32 %60, i32 %63)
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_free(i32 %63)
  call void @cq_template_select_i64_ll_unc(i32 %62, i32 %61, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  call void @cqrt_free(i32 %62)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %61, i32 %2, i32 0)
  call void @cqrt_free(i32 %61)
  %103 = call i32 @cq_template_select_i32_lh(i32 %60, i32 0, i32 %88)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %60, i32 %59, i32 0)
  call void @cqrt_free(i32 %60)
  call void @cq_template_and_i32_hl_unc(i32 %59, i32 %12, i32 1)
  call void @cqrt_free(i32 %59)
  %104 = call i32 @cqrt_measure_i32(i32 %44), !cq.measure !6
  %105 = call i32 @cqrt_measure_i32(i32 %103), !cq.measure !6
  %106 = mul nsw i32 %105, 3
  %107 = add nsw i32 %106, %104
  %108 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64))
  %109 = call i32 @cqrt_measure_i32(i32 %108), !cq.measure !6
  %110 = mul nsw i32 %109, 5
  %111 = add nsw i32 %107, %110
  %112 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %112)
  %113 = call i32 @cqrt_alloc_i32(i32 %111)
  ret i32 %113
}

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

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

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %4
  br i1 %8, label %9, label %126

9:                                                ; preds = %5
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %12, double 1.000000e+00)
  %13 = alloca { i32, ptr }, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 0
  store i32 %12, ptr %14, align 4
  %15 = load ptr, ptr %cq.mints, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 1
  store ptr %15, ptr %16, align 8
  store ptr %13, ptr %cq.mints, align 8
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %17)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %17, double 1.000000e+00)
  %18 = alloca { i32, ptr }, align 8
  %19 = getelementptr inbounds { i32, ptr }, ptr %18, i32 0, i32 0
  store i32 %17, ptr %19, align 4
  %20 = load ptr, ptr %cq.mints, align 8
  %21 = getelementptr inbounds { i32, ptr }, ptr %18, i32 0, i32 1
  store ptr %20, ptr %21, align 8
  store ptr %18, ptr %cq.mints, align 8
  %22 = call i32 @cq_template_and_i32_hl(i32 %12, i32 1)
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 0)
  %24 = call i32 @cq_template_select_i64_ll(i32 %23, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  %25 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  br label %27

27:                                               ; preds = %32, %9
  %28 = phi i32 [ 0, %9 ], [ %43, %32 ]
  %29 = phi i32 [ %0, %9 ], [ %41, %32 ]
  %30 = phi i32 [ %26, %9 ], [ %42, %32 ]
  %31 = icmp ult i32 %28, %25
  br i1 %31, label %32, label %44

32:                                               ; preds = %27
  %33 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %28)
  %34 = ptrtoint ptr %33 to i64
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %24, i64 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %36)
  %37 = call ptr @__cq_clone_resolve(ptr %33, i32 1)
  %38 = call i32 %37(i32 %36, i32 %17, i32 %4)
  %39 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %38, i32 %39)
  %40 = call ptr @__cq_clone_resolve(ptr %33, i32 3)
  call void %40(i32 %36, i32 %38, i32 %17, i32 %4)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %36)
  call void @cqrt_free(i32 %36)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_and_i1(i32 %29, i32 %35, i32 %41)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_push(i32 %29)
  %42 = call i32 @cq_template_select_i32(i32 %35, i32 %39, i32 %30)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %35)
  %43 = add i32 %28, 1
  br label %27

44:                                               ; preds = %27
  %45 = call i32 @cqrt_tape_write_i64_controlled(i32 %29, i32 %11, i32 %24)
  %46 = call i32 @cqrt_tape_write_i32_controlled(i32 %29, i32 %11, i32 %17)
  %47 = call i32 @cqrt_tape_effect_i32_controlled(i32 %29, i32 %11, ptr null)
  %48 = call i32 @cq_template_select_i32(i32 %29, i32 %47, i32 %30)
  %49 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %48, i32 %49)
  call void @cq_template_select_i32_unc(i32 %48, i32 %29, i32 %47, i32 %30)
  call void @cqrt_free(i32 %48)
  br label %50

50:                                               ; preds = %55, %44
  %51 = phi i32 [ %25, %44 ], [ %56, %55 ]
  %52 = phi i32 [ %29, %44 ], [ %60, %55 ]
  %53 = phi i32 [ %30, %44 ], [ %59, %55 ]
  %54 = icmp eq i32 %51, 0
  br i1 %54, label %63, label %55

55:                                               ; preds = %50
  %56 = add i32 %51, -1
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %53, i32 %57, i32 %58, i32 %59)
  call void @cqrt_free(i32 %53)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_and_i1(i32 %60, i32 %57, i32 %52)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %52)
  %61 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %56)
  %62 = ptrtoint ptr %61 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %57, i32 %24, i64 %62)
  call void @cqrt_free(i32 %57)
  br label %50

63:                                               ; preds = %50
  call void @cqrt_free(i32 %53)
  %64 = call i32 @cq_template_and_i32_hl(i32 %17, i32 1)
  %65 = call i32 @cq_template_icmp_eq_i32_hl(i32 %64, i32 0)
  %66 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %3, i32 0)
  %67 = call i32 @cq_template_select_i64_ll(i32 %66, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %69)
  call void @cqrt_xor_i1(i32 %65, i32 %69)
  call void @cqrt_and_i1(i32 %0, i32 %69, i32 %68)
  %70 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %71 = call i32 @cqrt_alloc_i32(i32 0)
  br label %72

72:                                               ; preds = %77, %63
  %73 = phi i32 [ 0, %63 ], [ %88, %77 ]
  %74 = phi i32 [ %68, %63 ], [ %86, %77 ]
  %75 = phi i32 [ %71, %63 ], [ %87, %77 ]
  %76 = icmp ult i32 %73, %70
  br i1 %76, label %77, label %89

77:                                               ; preds = %72
  %78 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %73)
  %79 = ptrtoint ptr %78 to i64
  %80 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 %79)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %68, i32 %80, i32 %81)
  %82 = call ptr @__cq_clone_resolve(ptr %78, i32 1)
  %83 = call i32 %82(i32 %81, i32 %12, i32 %4)
  %84 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %83, i32 %84)
  %85 = call ptr @__cq_clone_resolve(ptr %78, i32 3)
  call void %85(i32 %81, i32 %83, i32 %12, i32 %4)
  call void @cqrt_and_i1(i32 %68, i32 %80, i32 %81)
  call void @cqrt_free(i32 %81)
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %80)
  call void @cqrt_and_i1(i32 %74, i32 %80, i32 %86)
  call void @cqrt_not_i1(i32 %80)
  call void @cqrt_push(i32 %74)
  %87 = call i32 @cq_template_select_i32(i32 %80, i32 %84, i32 %75)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %80)
  %88 = add i32 %73, 1
  br label %72

89:                                               ; preds = %72
  %90 = call i32 @cqrt_tape_write_i64_controlled(i32 %74, i32 %11, i32 %67)
  %91 = call i32 @cqrt_tape_write_i32_controlled(i32 %74, i32 %11, i32 %12)
  %92 = call i32 @cqrt_tape_effect_i32_controlled(i32 %74, i32 %11, ptr null)
  %93 = call i32 @cq_template_select_i32(i32 %74, i32 %92, i32 %75)
  %94 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %93, i32 %94)
  call void @cq_template_select_i32_unc(i32 %93, i32 %74, i32 %92, i32 %75)
  call void @cqrt_free(i32 %93)
  br label %95

95:                                               ; preds = %100, %89
  %96 = phi i32 [ %70, %89 ], [ %101, %100 ]
  %97 = phi i32 [ %74, %89 ], [ %105, %100 ]
  %98 = phi i32 [ %75, %89 ], [ %104, %100 ]
  %99 = icmp eq i32 %96, 0
  br i1 %99, label %108, label %100

100:                                              ; preds = %95
  %101 = add i32 %96, -1
  %102 = call i32 @cqrt_pop()
  %103 = call i32 @cqrt_pop()
  %104 = call i32 @cqrt_pop()
  %105 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %98, i32 %102, i32 %103, i32 %104)
  call void @cqrt_free(i32 %98)
  call void @cqrt_not_i1(i32 %102)
  call void @cqrt_and_i1(i32 %105, i32 %102, i32 %97)
  call void @cqrt_not_i1(i32 %102)
  call void @cqrt_free(i32 %97)
  %106 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %101)
  %107 = ptrtoint ptr %106 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %102, i32 %67, i64 %107)
  call void @cqrt_free(i32 %102)
  br label %95

108:                                              ; preds = %95
  call void @cq_template_select_i64_ll_unc(i32 %24, i32 %23, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %23, i32 %22, i32 0)
  call void @cqrt_free(i32 %23)
  call void @cq_template_and_i32_hl_unc(i32 %22, i32 %12, i32 1)
  call void @cqrt_free(i32 %22)
  call void @cqrt_free(i32 %98)
  call void @cqrt_and_i1(i32 %0, i32 %69, i32 %68)
  call void @cqrt_free(i32 %68)
  call void @cqrt_xor_i1(i32 %65, i32 %69)
  call void @cqrt_not_i1(i32 %69)
  call void @cqrt_free(i32 %69)
  call void @cq_template_select_i64_ll_unc(i32 %67, i32 %66, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %66, i32 %3, i32 0)
  call void @cqrt_free(i32 %66)
  %109 = call i32 @cq_template_select_i32_lh(i32 %65, i32 0, i32 %94)
  %110 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %49, i32 %110)
  %111 = call i32 @cqrt_measure_i32(i32 %110), !cq.measure !6
  %112 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %109, i32 %112)
  call void @cq_template_select_i32_lh_unc(i32 %109, i32 %65, i32 0, i32 %94)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %65, i32 %64, i32 0)
  call void @cqrt_free(i32 %65)
  call void @cq_template_and_i32_hl_unc(i32 %64, i32 %17, i32 1)
  call void @cqrt_free(i32 %64)
  %113 = call i32 @cqrt_measure_i32(i32 %112), !cq.measure !6
  %114 = call i32 @cq_template_mul_i32_hl(i32 %112, i32 3)
  %115 = call i32 @cq_template_add_i32(i32 %114, i32 %110)
  %116 = call i32 @cq_template_sub_i32(i32 %115, i32 %110)
  call void @cqrt_copy_i32(i32 %116, i32 %114)
  call void @cq_template_sub_i32_unc(i32 %116, i32 %115, i32 %110)
  call void @cqrt_free(i32 %116)
  call void @cqrt_free(i32 %114)
  %117 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %10, i64 ptrtoint (ptr @g to i64))
  %118 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %117, i32 %118)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %117, i32 %0, i32 %10, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %117)
  %119 = call i32 @cqrt_measure_i32(i32 %118), !cq.measure !6
  %120 = call i32 @cq_template_mul_i32_hl(i32 %118, i32 5)
  %121 = call i32 @cq_template_add_i32(i32 %115, i32 %120)
  %122 = call i32 @cq_template_sub_i32(i32 %121, i32 %120)
  call void @cqrt_copy_i32(i32 %122, i32 %115)
  call void @cq_template_sub_i32_unc(i32 %122, i32 %121, i32 %120)
  call void @cqrt_free(i32 %122)
  call void @cqrt_free(i32 %115)
  call void @cq_template_mul_i32_hl_unc(i32 %120, i32 %118, i32 5)
  call void @cqrt_free(i32 %120)
  %123 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %123)
  %124 = load i32, ptr @__cq_act_f, align 4
  %125 = add i32 %124, -1
  store i32 %125, ptr @__cq_act_f, align 4
  ret i32 %121

126:                                              ; preds = %5
  %127 = call i32 @cqrt_alloc_i32(i32 0)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %128)
  call void @cqrt_push(i32 0)
  %129 = load i32, ptr @__cq_act_f, align 4
  %130 = add i32 %129, -1
  store i32 %130, ptr @__cq_act_f, align 4
  ret i32 %127
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

define internal i32 @__cq_q_f_111_t_pure(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cqrt_tape_alloc()
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %8)
  call void @cqrt_ry_i32(i32 %8, double 1.000000e+00)
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)
  %11 = call i32 @cq_template_select_i64_ll(i32 %10, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  %12 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %13 = call i32 @cqrt_alloc_i1(i1 true)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  br label %15

15:                                               ; preds = %20, %4
  %16 = phi i32 [ 0, %4 ], [ %30, %20 ]
  %17 = phi i32 [ %13, %4 ], [ %28, %20 ]
  %18 = phi i32 [ %14, %4 ], [ %29, %20 ]
  %19 = icmp ult i32 %16, %12
  br i1 %19, label %20, label %31

20:                                               ; preds = %15
  %21 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %16)
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %22)
  %24 = call ptr @__cq_clone_resolve(ptr %21, i32 1)
  %25 = call i32 %24(i32 %23, i32 %8, i32 %3)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %25, i32 %26)
  %27 = call ptr @__cq_clone_resolve(ptr %21, i32 3)
  call void %27(i32 %23, i32 %25, i32 %8, i32 %3)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_and_i1(i32 %17, i32 %23, i32 %28)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_push(i32 %17)
  %29 = call i32 @cq_template_select_i32(i32 %23, i32 %26, i32 %18)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %23)
  %30 = add i32 %16, 1
  br label %15

31:                                               ; preds = %15
  %32 = call i32 @cqrt_tape_write_i64_controlled(i32 %17, i32 %6, i32 %11)
  %33 = call i32 @cqrt_tape_write_i32_controlled(i32 %17, i32 %6, i32 %8)
  %34 = call i32 @cqrt_tape_effect_i32_controlled(i32 %17, i32 %6, ptr null)
  %35 = call i32 @cq_template_select_i32(i32 %17, i32 %34, i32 %18)
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %35, i32 %36)
  call void @cq_template_select_i32_unc(i32 %35, i32 %17, i32 %34, i32 %18)
  call void @cqrt_free(i32 %35)
  br label %37

37:                                               ; preds = %42, %31
  %38 = phi i32 [ %12, %31 ], [ %43, %42 ]
  %39 = phi i32 [ %17, %31 ], [ %47, %42 ]
  %40 = phi i32 [ %18, %31 ], [ %46, %42 ]
  %41 = icmp eq i32 %38, 0
  br i1 %41, label %50, label %42

42:                                               ; preds = %37
  %43 = add i32 %38, -1
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %40, i32 %44, i32 %45, i32 %46)
  call void @cqrt_free(i32 %40)
  call void @cqrt_not_i1(i32 %44)
  call void @cqrt_and_i1(i32 %47, i32 %44, i32 %39)
  call void @cqrt_not_i1(i32 %44)
  call void @cqrt_free(i32 %39)
  %48 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %43)
  %49 = ptrtoint ptr %48 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %44, i32 %11, i64 %49)
  call void @cqrt_free(i32 %44)
  br label %37

50:                                               ; preds = %37
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %40)
  %51 = call i32 @cq_template_and_i32_hl(i32 %8, i32 1)
  %52 = call i32 @cq_template_icmp_eq_i32_hl(i32 %51, i32 0)
  %53 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 0)
  %54 = call i32 @cq_template_select_i64_ll(i32 %53, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_xor_i1(i32 %52, i32 %55)
  %56 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  br label %58

58:                                               ; preds = %63, %50
  %59 = phi i32 [ 0, %50 ], [ %74, %63 ]
  %60 = phi i32 [ %55, %50 ], [ %72, %63 ]
  %61 = phi i32 [ %57, %50 ], [ %73, %63 ]
  %62 = icmp ult i32 %59, %56
  br i1 %62, label %63, label %75

63:                                               ; preds = %58
  %64 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %59)
  %65 = ptrtoint ptr %64 to i64
  %66 = call i32 @cq_template_icmp_eq_i64_hl(i32 %54, i64 %65)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %66, i32 %67)
  %68 = call ptr @__cq_clone_resolve(ptr %64, i32 1)
  %69 = call i32 %68(i32 %67, i32 %7, i32 %3)
  %70 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %69, i32 %70)
  %71 = call ptr @__cq_clone_resolve(ptr %64, i32 3)
  call void %71(i32 %67, i32 %69, i32 %7, i32 %3)
  call void @cqrt_and_i1(i32 %55, i32 %66, i32 %67)
  call void @cqrt_free(i32 %67)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %66)
  call void @cqrt_and_i1(i32 %60, i32 %66, i32 %72)
  call void @cqrt_not_i1(i32 %66)
  call void @cqrt_push(i32 %60)
  %73 = call i32 @cq_template_select_i32(i32 %66, i32 %70, i32 %61)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %66)
  %74 = add i32 %59, 1
  br label %58

75:                                               ; preds = %58
  %76 = call i32 @cqrt_tape_write_i64_controlled(i32 %60, i32 %6, i32 %54)
  %77 = call i32 @cqrt_tape_write_i32_controlled(i32 %60, i32 %6, i32 %7)
  %78 = call i32 @cqrt_tape_effect_i32_controlled(i32 %60, i32 %6, ptr null)
  %79 = call i32 @cq_template_select_i32(i32 %60, i32 %78, i32 %61)
  %80 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %79, i32 %80)
  call void @cq_template_select_i32_unc(i32 %79, i32 %60, i32 %78, i32 %61)
  call void @cqrt_free(i32 %79)
  br label %81

81:                                               ; preds = %86, %75
  %82 = phi i32 [ %56, %75 ], [ %87, %86 ]
  %83 = phi i32 [ %60, %75 ], [ %91, %86 ]
  %84 = phi i32 [ %61, %75 ], [ %90, %86 ]
  %85 = icmp eq i32 %82, 0
  br i1 %85, label %94, label %86

86:                                               ; preds = %81
  %87 = add i32 %82, -1
  %88 = call i32 @cqrt_pop()
  %89 = call i32 @cqrt_pop()
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %84, i32 %88, i32 %89, i32 %90)
  call void @cqrt_free(i32 %84)
  call void @cqrt_not_i1(i32 %88)
  call void @cqrt_and_i1(i32 %91, i32 %88, i32 %83)
  call void @cqrt_not_i1(i32 %88)
  call void @cqrt_free(i32 %83)
  %92 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %87)
  %93 = ptrtoint ptr %92 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %88, i32 %54, i64 %93)
  call void @cqrt_free(i32 %88)
  br label %81

94:                                               ; preds = %81
  call void @cq_template_select_i64_ll_unc(i32 %11, i32 %10, i64 ptrtoint (ptr @fa to i64), i64 ptrtoint (ptr @abs to i64))
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 1)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %84)
  call void @cqrt_xor_i1(i32 %52, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cq_template_select_i64_ll_unc(i32 %54, i32 %53, i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64))
  call void @cqrt_free(i32 %54)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %53, i32 %2, i32 0)
  call void @cqrt_free(i32 %53)
  %95 = call i32 @cq_template_select_i32_lh(i32 %52, i32 0, i32 %80)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %52, i32 %51, i32 0)
  call void @cqrt_free(i32 %52)
  call void @cq_template_and_i32_hl_unc(i32 %51, i32 %8, i32 1)
  call void @cqrt_free(i32 %51)
  %96 = call i32 @cqrt_measure_i32(i32 %36), !cq.measure !6
  %97 = call i32 @cqrt_measure_i32(i32 %95), !cq.measure !6
  %98 = mul nsw i32 %97, 3
  %99 = add nsw i32 %98, %96
  %100 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64))
  %101 = call i32 @cqrt_measure_i32(i32 %100), !cq.measure !6
  %102 = mul nsw i32 %101, 5
  %103 = add nsw i32 %99, %102
  %104 = call i32 @cqrt_alloc_i32(i32 %103)
  ret i32 %104
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @fa, ptr @.cq.sig, ptr @__cq_q_fa_1_t, ptr @__cq_q_fa_1_t_ctl, ptr @__cq_q_fa_1_t_unc, ptr @__cq_q_fa_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_fa_1_t_unc(i32 %0, i32 %1, i32 %2) {
  ret void
}

define internal void @__cq_q_fa_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_fa, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_fa, align 4
  %7 = load i32, ptr @__cq_act_fa, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_fa, align 4
  ret void
}

define internal void @__cq_q_f_111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = call i32 @cqrt_pop()
  br label %7

7:                                                ; preds = %10, %5
  %8 = phi i32 [ %6, %5 ], [ %12, %10 ]
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %13, label %10

10:                                               ; preds = %7
  %11 = call i32 @cqrt_pop()
  %12 = sub i32 %8, 1
  br label %7

13:                                               ; preds = %7
  ret void
}

define internal void @__cq_q_f_111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = call i32 @cqrt_pop()
  br label %12

12:                                               ; preds = %15, %6
  %13 = phi i32 [ %11, %6 ], [ %17, %15 ]
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %18, label %15

15:                                               ; preds = %12
  %16 = call i32 @cqrt_pop()
  %17 = sub i32 %13, 1
  br label %12

18:                                               ; preds = %12
  ret void
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
