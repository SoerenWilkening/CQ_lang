; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/base2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@out2 = local_unnamed_addr global [8 x i64] zeroinitializer, align 16
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [28 x i8] c"i64 (i32, i64, i64, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i64 @f(i32 noundef %0, i64 noundef %1, i64 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cqrt_alloc_i64(i64 %2)
  call void @cqrt_ry_i64(i32 %6, double %3)
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %8, label %9

8:                                                ; preds = %4
  br label %15

9:                                                ; preds = %4, %28
  %ran = phi i1 [ false, %4 ], [ true, %28 ]
  %10 = phi i32 [ %6, %4 ], [ %25, %28 ]
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %10, i32 %11)
  br i1 %ran, label %30, label %36

12:                                               ; preds = %36
  %13 = zext i32 %11 to i64
  ret i64 %13

14:                                               ; preds = %15
  br label %28

15:                                               ; preds = %15, %8
  %from = phi i32 [ 0, %15 ], [ 1, %8 ]
  %16 = phi i32 [ 0, %8 ], [ %26, %15 ]
  %17 = phi i32 [ %6, %8 ], [ %25, %15 ]
  call void @cqrt_push(i32 %from)
  %18 = call i32 @cq_template_icmp_slt_i64_hl(i32 %17, i64 1)
  %19 = call i32 @cq_template_add_i64_hl(i32 %17, i64 -3)
  %20 = and i32 %16, 7
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [8 x i64], ptr @out2, i64 0, i64 %21
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cqrt_alloc_i64(i64 %1)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %18, i32 %5, i64 %23, i32 %24)
  %25 = call i32 @cq_template_select_i64(i32 %18, i32 %17, i32 %19)
  %26 = add nuw nsw i32 %16, 1
  %27 = icmp eq i32 %26, %0
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %19)
  br i1 %27, label %14, label %15

28:                                               ; preds = %14
  br label %9

29:                                               ; preds = %30
  br label %36

30:                                               ; preds = %9, %30
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %34, i32 %33, i32 %32, i32 %31)
  call void @cqrt_free(i32 %34)
  call void @cq_template_add_i64_hl_unc(i32 %31, i32 %32, i64 -3)
  call void @cqrt_free(i32 %31)
  %35 = call i32 @cqrt_pop()
  switch i32 %35, label %30 [
    i32 1, label %29
  ]

36:                                               ; preds = %29, %9
  br label %12
}

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cq_template_icmp_slt_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_1111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %2, i32 %8)
  call void @cqrt_ry_i64_qangle(i32 %8, i32 %3)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  br label %14

14:                                               ; preds = %5
  %15 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %16 = icmp ult i32 %4, 2147483647
  %17 = icmp ult i32 0, %15
  br i1 %17, label %18, label %38

18:                                               ; preds = %18, %14
  %from = phi i32 [ 0, %18 ], [ 1, %14 ]
  %19 = phi i32 [ 0, %14 ], [ %36, %18 ]
  %20 = phi i32 [ %13, %14 ], [ %34, %18 ]
  %21 = phi i32 [ 0, %14 ], [ %31, %18 ]
  %22 = phi i32 [ %8, %14 ], [ %35, %18 ]
  call void @cqrt_push(i32 %from)
  %23 = call i32 @cq_template_icmp_slt_i64_hl(i32 %22, i64 1)
  %24 = call i32 @cq_template_add_i64_hl(i32 %22, i64 -3)
  %25 = and i32 %21, 7
  %26 = zext i32 %25 to i64
  %27 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %26
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %28)
  %29 = ptrtoint ptr %27 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %28, i32 %7, i64 %29, i32 %1)
  %30 = call i32 @cq_template_select_i64(i32 %23, i32 %22, i32 %24)
  %31 = add i32 %21, 1
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_xor_i1(i32 %32, i32 %33)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %33, i32 %34)
  %35 = call i32 @cq_template_select_i64(i32 %20, i32 %30, i32 %22)
  %36 = add i32 %19, 1
  %37 = icmp ult i32 %36, %15
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  br i1 %37, label %18, label %38

38:                                               ; preds = %18, %14
  %39 = phi i32 [ 0, %14 ], [ 1, %18 ]
  %40 = phi i32 [ 0, %14 ], [ %31, %18 ]
  %41 = phi i32 [ %8, %14 ], [ %35, %18 ]
  %42 = phi i32 [ %13, %14 ], [ %34, %18 ]
  br i1 %16, label %43, label %45

43:                                               ; preds = %38
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %42, i32 %44)
  br label %46

45:                                               ; preds = %38
  br label %46

46:                                               ; preds = %43, %45
  %47 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %41, i32 %47)
  br label %48

48:                                               ; preds = %46
  %49 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %49)
  %50 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %47, i32 %50)
  br label %65

51:                                               ; preds = %52
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %0, i32 0)
  call void @cqrt_free(i32 %13)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %50

52:                                               ; preds = %66, %53
  br label %51

53:                                               ; preds = %66, %53
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
  call void @cq_template_select_i64_unc(i32 %63, i32 %62, i32 %61, i32 %60)
  call void @cqrt_free(i32 %63)
  call void @cqrt_and_i1(i32 %62, i32 %59, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_xor_i1(i32 %57, i32 %59)
  call void @cqrt_not_i1(i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %57, i32 %0, i32 %56)
  call void @cqrt_free(i32 %57)
  call void @cq_template_select_i64_unc(i32 %61, i32 %55, i32 %60, i32 %54)
  call void @cqrt_free(i32 %61)
  call void @cq_template_add_i64_hl_unc(i32 %54, i32 %60, i64 -3)
  call void @cqrt_free(i32 %54)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %55, i32 %60, i64 1)
  call void @cqrt_free(i32 %55)
  %64 = call i32 @cqrt_pop()
  switch i32 %64, label %53 [
    i32 1, label %52
  ]

65:                                               ; preds = %48
  call void @cqrt_copy_i64(i32 %41, i32 %47)
  call void @cqrt_free(i32 %47)
  br label %66

66:                                               ; preds = %65
  switch i32 %39, label %52 [
    i32 1, label %53
  ]
}

declare void @cqrt_ry_i64_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_copy_i1(i32, i32)

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

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_slt_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %75

11:                                               ; preds = %6
  %12 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %3, i32 %13)
  call void @cqrt_ry_i64_qangle_controlled(i32 %0, i32 %13, i32 %4)
  %14 = alloca { i32, ptr }, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 0
  store i32 %13, ptr %15, align 4
  %16 = load ptr, ptr %cq.mints, align 8
  %17 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 1
  store ptr %16, ptr %17, align 8
  store ptr %14, ptr %cq.mints, align 8
  %18 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  br label %19

19:                                               ; preds = %11
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %20)
  %21 = call i32 @llvm.umin.i32(i32 %5, i32 2147483647)
  %22 = icmp ult i32 %5, 2147483647
  %23 = icmp ult i32 0, %21
  br i1 %23, label %24, label %44

24:                                               ; preds = %24, %19
  %from = phi i32 [ 0, %24 ], [ 1, %19 ]
  %25 = phi i32 [ 0, %19 ], [ %42, %24 ]
  %26 = phi i32 [ %20, %19 ], [ %40, %24 ]
  %27 = phi i32 [ 0, %19 ], [ %37, %24 ]
  %28 = phi i32 [ %13, %19 ], [ %41, %24 ]
  call void @cqrt_push(i32 %from)
  %29 = call i32 @cq_template_icmp_slt_i64_hl(i32 %28, i64 1)
  %30 = call i32 @cq_template_add_i64_hl(i32 %28, i64 -3)
  %31 = and i32 %27, 7
  %32 = zext i32 %31 to i64
  %33 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %32
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %26, i32 %29, i32 %34)
  %35 = ptrtoint ptr %33 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %34, i32 %12, i64 %35, i32 %2)
  %36 = call i32 @cq_template_select_i64(i32 %29, i32 %28, i32 %30)
  %37 = add i32 %27, 1
  %38 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %37)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_xor_i1(i32 %38, i32 %39)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %26, i32 %39, i32 %40)
  %41 = call i32 @cq_template_select_i64(i32 %26, i32 %36, i32 %28)
  %42 = add i32 %25, 1
  %43 = icmp ult i32 %42, %21
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %30)
  br i1 %43, label %24, label %44

44:                                               ; preds = %24, %19
  %45 = phi i32 [ 0, %19 ], [ 1, %24 ]
  %46 = phi i32 [ 0, %19 ], [ %37, %24 ]
  %47 = phi i32 [ %13, %19 ], [ %41, %24 ]
  %48 = phi i32 [ %20, %19 ], [ %40, %24 ]
  br i1 %22, label %49, label %51

49:                                               ; preds = %44
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %48, i32 %50)
  br label %52

51:                                               ; preds = %44
  br label %52

52:                                               ; preds = %49, %51
  %53 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %47, i32 %53)
  br label %54

54:                                               ; preds = %52
  %55 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %55)
  %56 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %53, i32 %56)
  br label %73

57:                                               ; preds = %60
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %1, i32 0)
  call void @cqrt_free(i32 %18)
  %58 = load i32, ptr @__cq_act_f, align 4
  %59 = add i32 %58, -1
  store i32 %59, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %56

60:                                               ; preds = %74, %61
  br label %57

61:                                               ; preds = %74, %61
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
  call void @cq_template_select_i64_unc(i32 %71, i32 %70, i32 %69, i32 %68)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %70, i32 %67, i32 %66)
  call void @cqrt_free(i32 %66)
  call void @cqrt_xor_i1(i32 %65, i32 %67)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %65, i32 %1, i32 %64)
  call void @cqrt_free(i32 %65)
  call void @cq_template_select_i64_unc(i32 %69, i32 %63, i32 %68, i32 %62)
  call void @cqrt_free(i32 %69)
  call void @cq_template_add_i64_hl_unc(i32 %62, i32 %68, i64 -3)
  call void @cqrt_free(i32 %62)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %63, i32 %68, i64 1)
  call void @cqrt_free(i32 %63)
  %72 = call i32 @cqrt_pop()
  switch i32 %72, label %61 [
    i32 1, label %60
  ]

73:                                               ; preds = %54
  call void @cqrt_copy_i64(i32 %47, i32 %53)
  call void @cqrt_free(i32 %53)
  br label %74

74:                                               ; preds = %73
  switch i32 %45, label %60 [
    i32 1, label %61
  ]

75:                                               ; preds = %6
  %76 = call i32 @cqrt_alloc_i64(i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %77)
  call void @cqrt_push(i32 0)
  %78 = load i32, ptr @__cq_act_f, align 4
  %79 = add i32 %78, -1
  store i32 %79, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %76
}

declare void @cqrt_ry_i64_qangle_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1111_t, ptr @__cq_q_f_1111_t_ctl, ptr @__cq_q_f_1111_t_unc, ptr @__cq_q_f_1111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = call i32 @cqrt_pop()
  br label %9

9:                                                ; preds = %12, %6
  %10 = phi i32 [ %8, %6 ], [ %14, %12 ]
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %9
  %13 = call i32 @cqrt_pop()
  %14 = sub i32 %10, 1
  br label %9

15:                                               ; preds = %9
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_1111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6) {
  %8 = load i32, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = load i32, ptr @__cq_act_f, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_f, align 4
  %13 = call i32 @cqrt_pop()
  br label %14

14:                                               ; preds = %17, %7
  %15 = phi i32 [ %13, %7 ], [ %19, %17 ]
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %20, label %17

17:                                               ; preds = %14
  %18 = call i32 @cqrt_pop()
  %19 = sub i32 %15, 1
  br label %14

20:                                               ; preds = %14
  store i32 %8, ptr @__cq_k, align 4
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
