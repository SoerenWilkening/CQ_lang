; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/rejoin2.c"
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
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = icmp eq i64 %1, -1
  br label %15

10:                                               ; preds = %4, %38
  %ran = phi i1 [ false, %4 ], [ true, %38 ]
  %11 = phi i32 [ %6, %4 ], [ %34, %38 ]
  %12 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %11, i32 %12)
  br i1 %ran, label %45, label %57

13:                                               ; preds = %57
  %14 = zext i32 %12 to i64
  ret i64 %14

15:                                               ; preds = %8
  br label %17

16:                                               ; preds = %28
  br label %38

17:                                               ; preds = %28, %15
  %from1 = phi i32 [ 0, %28 ], [ 1, %15 ]
  %18 = phi i32 [ %6, %15 ], [ %34, %28 ]
  %19 = phi i32 [ 0, %15 ], [ %35, %28 ]
  call void @cqrt_push(i32 %from1)
  %20 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %18, i64 0)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %18)
  br i1 %9, label %28, label %21

21:                                               ; preds = %17
  %22 = and i32 %19, 7
  %23 = zext nneg i32 %22 to i64
  %24 = getelementptr inbounds [8 x i64], ptr @out2, i64 0, i64 %23
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_alloc_i64(i64 %1)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %20, i32 %27)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %27, i32 %5, i64 %25, i32 %26)
  call void @cqrt_not_i1(i32 %27)
  br label %28

28:                                               ; preds = %17, %21
  %from = phi i32 [ 0, %17 ], [ 1, %21 ]
  call void @cqrt_push(i32 %from)
  %29 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %18, i64 2)
  %30 = icmp ult i32 %19, 2
  %31 = call i32 @cq_template_and_i1_hl(i32 %29, i1 %30)
  %32 = call i32 @cq_template_add_i64_hl(i32 %18, i64 -3)
  %33 = call i32 @cq_template_select_i64_hl(i32 %31, i32 %32, i64 0)
  %34 = call i32 @cq_template_select_i64(i32 %20, i32 %33, i32 %18)
  %35 = add nuw nsw i32 %19, 1
  %36 = icmp eq i32 %35, %0
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %29)
  %37 = zext i1 %30 to i32
  call void @cqrt_push(i32 %37)
  br i1 %36, label %16, label %17

38:                                               ; preds = %16
  br label %10

39:                                               ; preds = %40
  br label %57

40:                                               ; preds = %44, %45
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %42, i32 %41, i64 0)
  call void @cqrt_free(i32 %42)
  %43 = call i32 @cqrt_pop()
  switch i32 %43, label %45 [
    i32 1, label %39
  ]

44:                                               ; preds = %45
  br label %40

45:                                               ; preds = %10, %40
  %46 = call i32 @cqrt_pop()
  %47 = or i32 0, %46
  %48 = trunc i32 %47 to i1
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %55, i32 %54, i32 %53, i32 %52)
  call void @cqrt_free(i32 %55)
  call void @cq_template_select_i64_hl_unc(i32 %53, i32 %51, i32 %50, i64 0)
  call void @cqrt_free(i32 %53)
  call void @cq_template_add_i64_hl_unc(i32 %50, i32 %52, i64 -3)
  call void @cqrt_free(i32 %50)
  call void @cq_template_and_i1_hl_unc(i32 %51, i32 %49, i1 %48)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %49, i32 %52, i64 2)
  call void @cqrt_free(i32 %49)
  %56 = call i32 @cqrt_pop()
  switch i32 %56, label %40 [
    i32 1, label %44
  ]

57:                                               ; preds = %39, %10
  br label %13
}

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @__cq_mem()

declare void @cqrt_not_i1(i32)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_and_i1_hl(i32, i1)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cq_template_select_i64_hl(i32, i32, i64)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_select_i64_hl_unc(i32, i32, i32, i64)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_and_i1_hl_unc(i32, i32, i1)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

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
  %14 = call i32 @cq_template_icmp_eq_i64_hl(i32 %1, i64 -1)
  br label %15

15:                                               ; preds = %5
  %16 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %17 = icmp ult i32 %4, 2147483647
  %18 = icmp ult i32 0, %16
  br i1 %18, label %19, label %46

19:                                               ; preds = %19, %15
  %from = phi i32 [ 0, %19 ], [ 1, %15 ]
  %20 = phi i32 [ 0, %15 ], [ %43, %19 ]
  %21 = phi i32 [ %13, %15 ], [ %41, %19 ]
  %22 = phi i32 [ %8, %15 ], [ %42, %19 ]
  %23 = phi i32 [ 0, %15 ], [ %38, %19 ]
  call void @cqrt_push(i32 %from)
  %24 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %22, i64 0)
  %25 = and i32 %23, 7
  %26 = zext i32 %25 to i64
  %27 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %26
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_xor_i1(i32 %24, i32 %29)
  call void @cqrt_xor_i1(i32 %29, i32 %28)
  call void @cqrt_and_i1(i32 %29, i32 %14, i32 %28)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %28, i32 %30)
  call void @cqrt_and_i1(i32 %29, i32 %14, i32 %28)
  call void @cqrt_xor_i1(i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_xor_i1(i32 %24, i32 %29)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_free(i32 %29)
  %31 = ptrtoint ptr %27 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %30, i32 %7, i64 %31, i32 %1)
  %32 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %22, i64 2)
  %33 = icmp ult i32 %23, 2
  %34 = call i32 @cq_template_and_i1_hl(i32 %32, i1 %33)
  %35 = call i32 @cq_template_add_i64_hl(i32 %22, i64 -3)
  %36 = call i32 @cq_template_select_i64_hl(i32 %34, i32 %35, i64 0)
  %37 = call i32 @cq_template_select_i64(i32 %24, i32 %36, i32 %22)
  %38 = add i32 %23, 1
  %39 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %40)
  call void @cqrt_xor_i1(i32 %39, i32 %40)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %40, i32 %41)
  %42 = call i32 @cq_template_select_i64(i32 %21, i32 %37, i32 %22)
  %43 = add i32 %20, 1
  %44 = icmp ult i32 %43, %16
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %32)
  %45 = zext i1 %33 to i32
  call void @cqrt_push(i32 %45)
  br i1 %44, label %19, label %46

46:                                               ; preds = %19, %15
  %47 = phi i32 [ 0, %15 ], [ 1, %19 ]
  %48 = phi i32 [ %8, %15 ], [ %42, %19 ]
  %49 = phi i32 [ 0, %15 ], [ %38, %19 ]
  %50 = phi i32 [ %13, %15 ], [ %41, %19 ]
  br i1 %17, label %51, label %53

51:                                               ; preds = %46
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %50, i32 %52)
  br label %54

53:                                               ; preds = %46
  br label %54

54:                                               ; preds = %51, %53
  %55 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %48, i32 %55)
  br label %56

56:                                               ; preds = %54
  %57 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %57)
  %58 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %55, i32 %58)
  br label %79

59:                                               ; preds = %60
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %14, i32 %1, i64 -1)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %0, i32 0)
  call void @cqrt_free(i32 %13)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %58

60:                                               ; preds = %80, %61
  br label %59

61:                                               ; preds = %80, %61
  %62 = call i32 @cqrt_pop()
  %63 = or i32 0, %62
  %64 = trunc i32 %63 to i1
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
  %75 = call i32 @cqrt_pop()
  %76 = call i32 @cqrt_pop()
  %77 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %77, i32 %76, i32 %75, i32 %74)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %76, i32 %73, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cqrt_xor_i1(i32 %71, i32 %73)
  call void @cqrt_not_i1(i32 %73)
  call void @cqrt_free(i32 %73)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %71, i32 %0, i32 %70)
  call void @cqrt_free(i32 %71)
  call void @cq_template_select_i64_unc(i32 %75, i32 %69, i32 %68, i32 %74)
  call void @cqrt_free(i32 %75)
  call void @cq_template_select_i64_hl_unc(i32 %68, i32 %67, i32 %66, i64 0)
  call void @cqrt_free(i32 %68)
  call void @cq_template_add_i64_hl_unc(i32 %66, i32 %74, i64 -3)
  call void @cqrt_free(i32 %66)
  call void @cq_template_and_i1_hl_unc(i32 %67, i32 %65, i1 %64)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %65, i32 %74, i64 2)
  call void @cqrt_free(i32 %65)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %69, i32 %74, i64 0)
  call void @cqrt_free(i32 %69)
  %78 = call i32 @cqrt_pop()
  switch i32 %78, label %61 [
    i32 1, label %60
  ]

79:                                               ; preds = %56
  call void @cqrt_copy_i64(i32 %48, i32 %55)
  call void @cqrt_free(i32 %55)
  br label %80

80:                                               ; preds = %79
  switch i32 %47, label %60 [
    i32 1, label %61
  ]
}

declare void @cqrt_ry_i64_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

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

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %89

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
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %2, i64 -1)
  br label %20

20:                                               ; preds = %11
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %21)
  %22 = call i32 @llvm.umin.i32(i32 %5, i32 2147483647)
  %23 = icmp ult i32 %5, 2147483647
  %24 = icmp ult i32 0, %22
  br i1 %24, label %25, label %52

25:                                               ; preds = %25, %20
  %from = phi i32 [ 0, %25 ], [ 1, %20 ]
  %26 = phi i32 [ 0, %20 ], [ %49, %25 ]
  %27 = phi i32 [ %21, %20 ], [ %47, %25 ]
  %28 = phi i32 [ %13, %20 ], [ %48, %25 ]
  %29 = phi i32 [ 0, %20 ], [ %44, %25 ]
  call void @cqrt_push(i32 %from)
  %30 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %28, i64 0)
  %31 = and i32 %29, 7
  %32 = zext i32 %31 to i64
  %33 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %32
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_xor_i1(i32 %30, i32 %35)
  call void @cqrt_xor_i1(i32 %35, i32 %34)
  call void @cqrt_and_i1(i32 %35, i32 %19, i32 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %34, i32 %36)
  call void @cqrt_and_i1(i32 %35, i32 %19, i32 %34)
  call void @cqrt_xor_i1(i32 %35, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %30, i32 %35)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %35)
  %37 = ptrtoint ptr %33 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %36, i32 %12, i64 %37, i32 %2)
  %38 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %28, i64 2)
  %39 = icmp ult i32 %29, 2
  %40 = call i32 @cq_template_and_i1_hl(i32 %38, i1 %39)
  %41 = call i32 @cq_template_add_i64_hl(i32 %28, i64 -3)
  %42 = call i32 @cq_template_select_i64_hl(i32 %40, i32 %41, i64 0)
  %43 = call i32 @cq_template_select_i64(i32 %30, i32 %42, i32 %28)
  %44 = add i32 %29, 1
  %45 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %44)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %46)
  call void @cqrt_xor_i1(i32 %45, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %46, i32 %47)
  %48 = call i32 @cq_template_select_i64(i32 %27, i32 %43, i32 %28)
  %49 = add i32 %26, 1
  %50 = icmp ult i32 %49, %22
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %38)
  %51 = zext i1 %39 to i32
  call void @cqrt_push(i32 %51)
  br i1 %50, label %25, label %52

52:                                               ; preds = %25, %20
  %53 = phi i32 [ 0, %20 ], [ 1, %25 ]
  %54 = phi i32 [ %13, %20 ], [ %48, %25 ]
  %55 = phi i32 [ 0, %20 ], [ %44, %25 ]
  %56 = phi i32 [ %21, %20 ], [ %47, %25 ]
  br i1 %23, label %57, label %59

57:                                               ; preds = %52
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %56, i32 %58)
  br label %60

59:                                               ; preds = %52
  br label %60

60:                                               ; preds = %57, %59
  %61 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %54, i32 %61)
  br label %62

62:                                               ; preds = %60
  %63 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %63)
  %64 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %61, i32 %64)
  br label %87

65:                                               ; preds = %68
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %2, i64 -1)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %1, i32 0)
  call void @cqrt_free(i32 %18)
  %66 = load i32, ptr @__cq_act_f, align 4
  %67 = add i32 %66, -1
  store i32 %67, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %64

68:                                               ; preds = %88, %69
  br label %65

69:                                               ; preds = %88, %69
  %70 = call i32 @cqrt_pop()
  %71 = or i32 0, %70
  %72 = trunc i32 %71 to i1
  %73 = call i32 @cqrt_pop()
  %74 = call i32 @cqrt_pop()
  %75 = call i32 @cqrt_pop()
  %76 = call i32 @cqrt_pop()
  %77 = call i32 @cqrt_pop()
  %78 = call i32 @cqrt_pop()
  %79 = call i32 @cqrt_pop()
  %80 = call i32 @cqrt_pop()
  %81 = call i32 @cqrt_pop()
  %82 = call i32 @cqrt_pop()
  %83 = call i32 @cqrt_pop()
  %84 = call i32 @cqrt_pop()
  %85 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %85, i32 %84, i32 %83, i32 %82)
  call void @cqrt_free(i32 %85)
  call void @cqrt_and_i1(i32 %84, i32 %81, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_xor_i1(i32 %79, i32 %81)
  call void @cqrt_not_i1(i32 %81)
  call void @cqrt_free(i32 %81)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %79, i32 %1, i32 %78)
  call void @cqrt_free(i32 %79)
  call void @cq_template_select_i64_unc(i32 %83, i32 %77, i32 %76, i32 %82)
  call void @cqrt_free(i32 %83)
  call void @cq_template_select_i64_hl_unc(i32 %76, i32 %75, i32 %74, i64 0)
  call void @cqrt_free(i32 %76)
  call void @cq_template_add_i64_hl_unc(i32 %74, i32 %82, i64 -3)
  call void @cqrt_free(i32 %74)
  call void @cq_template_and_i1_hl_unc(i32 %75, i32 %73, i1 %72)
  call void @cqrt_free(i32 %75)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %73, i32 %82, i64 2)
  call void @cqrt_free(i32 %73)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %77, i32 %82, i64 0)
  call void @cqrt_free(i32 %77)
  %86 = call i32 @cqrt_pop()
  switch i32 %86, label %69 [
    i32 1, label %68
  ]

87:                                               ; preds = %62
  call void @cqrt_copy_i64(i32 %54, i32 %61)
  call void @cqrt_free(i32 %61)
  br label %88

88:                                               ; preds = %87
  switch i32 %53, label %68 [
    i32 1, label %69
  ]

89:                                               ; preds = %6
  %90 = call i32 @cqrt_alloc_i64(i64 0)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %91)
  call void @cqrt_push(i32 0)
  %92 = load i32, ptr @__cq_act_f, align 4
  %93 = add i32 %92, -1
  store i32 %93, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %90
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
