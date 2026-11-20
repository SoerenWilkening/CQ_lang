; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/rejoin1c.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@out2 = local_unnamed_addr global [8 x i64] zeroinitializer, align 16
@out = local_unnamed_addr global [8 x i64] zeroinitializer, align 16
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
  br label %13

10:                                               ; preds = %40, %4
  %11 = phi i32 [ %6, %4 ], [ %15, %40 ]
  %12 = zext i32 %11 to i64
  ret i64 %12

13:                                               ; preds = %8
  br label %16

14:                                               ; preds = %28
  %15 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %29, i32 %15)
  br label %58

16:                                               ; preds = %28, %13
  %from1 = phi i32 [ 0, %28 ], [ 1, %13 ]
  %17 = phi i32 [ %6, %13 ], [ %29, %28 ]
  %18 = phi i32 [ 0, %13 ], [ %30, %28 ]
  call void @cqrt_push(i32 %from1)
  %19 = call i32 @cq_template_icmp_slt_i64_hl(i32 %17, i64 1)
  %20 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %17, i64 2)
  %21 = icmp ult i32 %18, 2
  %22 = call i32 @cq_template_and_i1_hl(i32 %20, i1 %21)
  %23 = call i32 @cq_template_select_i64_lh(i32 %22, i64 3, i32 %17)
  %24 = call i32 @cq_template_sub_i64(i32 %17, i32 %23)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_xor_i1(i32 %19, i32 %25)
  call fastcc void @__cq_q_put_01_ctl(i32 %25, i32 %18, i32 %23)
  call void @cqrt_xor_i1(i32 %19, i32 %25)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_free(i32 %25)
  %26 = call i32 @cq_template_select_i64(i32 %19, i32 %17, i32 %24)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %20)
  %27 = zext i1 %21 to i32
  call void @cqrt_push(i32 %27)
  br i1 %9, label %28, label %32

28:                                               ; preds = %32, %16
  %from = phi i32 [ 0, %32 ], [ 1, %16 ]
  %29 = phi i32 [ %39, %32 ], [ %26, %16 ]
  call void @cqrt_push(i32 %from)
  %30 = add nuw nsw i32 %18, 1
  %31 = icmp eq i32 %30, %0
  br i1 %31, label %14, label %16

32:                                               ; preds = %16
  %33 = and i32 %18, 7
  %34 = zext nneg i32 %33 to i64
  %35 = getelementptr inbounds [8 x i64], ptr @out2, i64 0, i64 %34
  %36 = ptrtoint ptr %35 to i64
  %37 = call i32 @cqrt_alloc_i64(i64 %1)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %19, i32 %38)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %38, i32 %5, i64 %36, i32 %37)
  %39 = call i32 @cq_template_select_i64(i32 %19, i32 %17, i32 %24)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %24)
  br label %28

40:                                               ; preds = %41
  br label %10

41:                                               ; preds = %53, %58
  %42 = call i32 @cqrt_pop()
  %43 = or i32 0, %42
  %44 = trunc i32 %43 to i1
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  %48 = call i32 @cqrt_pop()
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %51, i32 %50, i32 %49, i32 %48)
  call void @cqrt_free(i32 %51)
  call void @cq_template_sub_i64_unc(i32 %48, i32 %49, i32 %47)
  call void @cqrt_free(i32 %48)
  call void @cq_template_select_i64_lh_unc(i32 %47, i32 %46, i64 3, i32 %49)
  call void @cqrt_free(i32 %47)
  call void @cq_template_and_i1_hl_unc(i32 %46, i32 %45, i1 %44)
  call void @cqrt_free(i32 %46)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %45, i32 %49, i64 2)
  call void @cqrt_free(i32 %45)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %50, i32 %49, i64 1)
  call void @cqrt_free(i32 %50)
  %52 = call i32 @cqrt_pop()
  switch i32 %52, label %58 [
    i32 1, label %40
  ]

53:                                               ; preds = %58
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %57, i32 %56, i32 %55, i32 %54)
  call void @cqrt_free(i32 %57)
  br label %41

58:                                               ; preds = %14, %41
  %59 = call i32 @cqrt_pop()
  switch i32 %59, label %53 [
    i32 1, label %41
  ]
}

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cq_template_icmp_slt_i64_hl(i32, i64)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @cq_template_and_i1_hl(i32, i1)

declare i32 @cq_template_select_i64_lh(i32, i64, i32)

declare i32 @cq_template_sub_i64(i32, i32)

define internal fastcc void @__cq_q_put_01_ctl(i32 %0, i32 %1, i32 %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = and i32 %1, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i64], ptr @out, i64 0, i64 %6
  %8 = ptrtoint ptr %7 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %4, i64 %8, i32 %2)
  ret void
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cq_template_sub_i64_unc(i32, i32, i32)

declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)

declare void @cq_template_and_i1_hl_unc(i32, i32, i1)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_slt_i64_hl_unc(i32, i32, i64)

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
  br i1 %18, label %19, label %47

19:                                               ; preds = %19, %15
  %from = phi i32 [ 0, %19 ], [ 1, %15 ]
  %20 = phi i32 [ 0, %15 ], [ %44, %19 ]
  %21 = phi i32 [ %13, %15 ], [ %42, %19 ]
  %22 = phi i32 [ %8, %15 ], [ %43, %19 ]
  %23 = phi i32 [ 0, %15 ], [ %39, %19 ]
  call void @cqrt_push(i32 %from)
  %24 = call i32 @cq_template_icmp_slt_i64_hl(i32 %22, i64 1)
  %25 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %22, i64 2)
  %26 = icmp ult i32 %23, 2
  %27 = call i32 @cq_template_and_i1_hl(i32 %25, i1 %26)
  %28 = call i32 @cq_template_select_i64_lh(i32 %27, i64 3, i32 %22)
  %29 = call i32 @cq_template_sub_i64(i32 %22, i32 %28)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %24, i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %30, i32 %31)
  call fastcc void @__cq_q_put_01_ctl(i32 %31, i32 %23, i32 %28)
  call void @cqrt_and_i1(i32 %21, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_xor_i1(i32 %24, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  %32 = and i32 %23, 7
  %33 = zext i32 %32 to i64
  %34 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %33
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %24, i32 %35)
  call void @cqrt_and_i1(i32 %24, i32 %14, i32 %35)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %35, i32 %36)
  call void @cqrt_and_i1(i32 %24, i32 %14, i32 %35)
  call void @cqrt_xor_i1(i32 %24, i32 %35)
  call void @cqrt_free(i32 %35)
  %37 = ptrtoint ptr %34 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %36, i32 %7, i64 %37, i32 %1)
  %38 = call i32 @cq_template_select_i64(i32 %24, i32 %22, i32 %29)
  %39 = add i32 %23, 1
  %40 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %39)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_xor_i1(i32 %40, i32 %41)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %41, i32 %42)
  %43 = call i32 @cq_template_select_i64(i32 %21, i32 %38, i32 %22)
  %44 = add i32 %20, 1
  %45 = icmp ult i32 %44, %16
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %25)
  %46 = zext i1 %26 to i32
  call void @cqrt_push(i32 %46)
  br i1 %45, label %19, label %47

47:                                               ; preds = %19, %15
  %48 = phi i32 [ 0, %15 ], [ 1, %19 ]
  %49 = phi i32 [ %8, %15 ], [ %43, %19 ]
  %50 = phi i32 [ 0, %15 ], [ %39, %19 ]
  %51 = phi i32 [ %13, %15 ], [ %42, %19 ]
  br i1 %17, label %52, label %54

52:                                               ; preds = %47
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %51, i32 %53)
  br label %55

54:                                               ; preds = %47
  br label %55

55:                                               ; preds = %52, %54
  %56 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %49, i32 %56)
  br label %57

57:                                               ; preds = %55
  %58 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %58)
  %59 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %56, i32 %59)
  br label %80

60:                                               ; preds = %61
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %14, i32 %1, i64 -1)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %0, i32 0)
  call void @cqrt_free(i32 %13)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %59

61:                                               ; preds = %81, %62
  br label %60

62:                                               ; preds = %81, %62
  %63 = call i32 @cqrt_pop()
  %64 = or i32 0, %63
  %65 = trunc i32 %64 to i1
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
  %78 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %78, i32 %77, i32 %76, i32 %75)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %77, i32 %74, i32 %73)
  call void @cqrt_free(i32 %73)
  call void @cqrt_xor_i1(i32 %72, i32 %74)
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %72, i32 %0, i32 %71)
  call void @cqrt_free(i32 %72)
  call void @cq_template_select_i64_unc(i32 %76, i32 %70, i32 %75, i32 %69)
  call void @cqrt_free(i32 %76)
  call void @cq_template_sub_i64_unc(i32 %69, i32 %75, i32 %68)
  call void @cqrt_free(i32 %69)
  call void @cq_template_select_i64_lh_unc(i32 %68, i32 %67, i64 3, i32 %75)
  call void @cqrt_free(i32 %68)
  call void @cq_template_and_i1_hl_unc(i32 %67, i32 %66, i1 %65)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %66, i32 %75, i64 2)
  call void @cqrt_free(i32 %66)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %70, i32 %75, i64 1)
  call void @cqrt_free(i32 %70)
  %79 = call i32 @cqrt_pop()
  switch i32 %79, label %62 [
    i32 1, label %61
  ]

80:                                               ; preds = %57
  call void @cqrt_copy_i64(i32 %49, i32 %56)
  call void @cqrt_free(i32 %56)
  br label %81

81:                                               ; preds = %80
  switch i32 %48, label %61 [
    i32 1, label %62
  ]
}

declare void @cqrt_ry_i64_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

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
  br i1 %10, label %11, label %90

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
  br i1 %24, label %25, label %53

25:                                               ; preds = %25, %20
  %from = phi i32 [ 0, %25 ], [ 1, %20 ]
  %26 = phi i32 [ 0, %20 ], [ %50, %25 ]
  %27 = phi i32 [ %21, %20 ], [ %48, %25 ]
  %28 = phi i32 [ %13, %20 ], [ %49, %25 ]
  %29 = phi i32 [ 0, %20 ], [ %45, %25 ]
  call void @cqrt_push(i32 %from)
  %30 = call i32 @cq_template_icmp_slt_i64_hl(i32 %28, i64 1)
  %31 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %28, i64 2)
  %32 = icmp ult i32 %29, 2
  %33 = call i32 @cq_template_and_i1_hl(i32 %31, i1 %32)
  %34 = call i32 @cq_template_select_i64_lh(i32 %33, i64 3, i32 %28)
  %35 = call i32 @cq_template_sub_i64(i32 %28, i32 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_xor_i1(i32 %30, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %36, i32 %37)
  call fastcc void @__cq_q_put_01_ctl(i32 %37, i32 %29, i32 %34)
  call void @cqrt_and_i1(i32 %27, i32 %36, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_xor_i1(i32 %30, i32 %36)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_free(i32 %36)
  %38 = and i32 %29, 7
  %39 = zext i32 %38 to i64
  %40 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %39
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %30, i32 %41)
  call void @cqrt_and_i1(i32 %30, i32 %19, i32 %41)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %41, i32 %42)
  call void @cqrt_and_i1(i32 %30, i32 %19, i32 %41)
  call void @cqrt_xor_i1(i32 %30, i32 %41)
  call void @cqrt_free(i32 %41)
  %43 = ptrtoint ptr %40 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %42, i32 %12, i64 %43, i32 %2)
  %44 = call i32 @cq_template_select_i64(i32 %30, i32 %28, i32 %35)
  %45 = add i32 %29, 1
  %46 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %45)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_xor_i1(i32 %46, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %47, i32 %48)
  %49 = call i32 @cq_template_select_i64(i32 %27, i32 %44, i32 %28)
  %50 = add i32 %26, 1
  %51 = icmp ult i32 %50, %22
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %31)
  %52 = zext i1 %32 to i32
  call void @cqrt_push(i32 %52)
  br i1 %51, label %25, label %53

53:                                               ; preds = %25, %20
  %54 = phi i32 [ 0, %20 ], [ 1, %25 ]
  %55 = phi i32 [ %13, %20 ], [ %49, %25 ]
  %56 = phi i32 [ 0, %20 ], [ %45, %25 ]
  %57 = phi i32 [ %21, %20 ], [ %48, %25 ]
  br i1 %23, label %58, label %60

58:                                               ; preds = %53
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %57, i32 %59)
  br label %61

60:                                               ; preds = %53
  br label %61

61:                                               ; preds = %58, %60
  %62 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %55, i32 %62)
  br label %63

63:                                               ; preds = %61
  %64 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %64)
  %65 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %62, i32 %65)
  br label %88

66:                                               ; preds = %69
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %2, i64 -1)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %1, i32 0)
  call void @cqrt_free(i32 %18)
  %67 = load i32, ptr @__cq_act_f, align 4
  %68 = add i32 %67, -1
  store i32 %68, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %65

69:                                               ; preds = %89, %70
  br label %66

70:                                               ; preds = %89, %70
  %71 = call i32 @cqrt_pop()
  %72 = or i32 0, %71
  %73 = trunc i32 %72 to i1
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
  %86 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %86, i32 %85, i32 %84, i32 %83)
  call void @cqrt_free(i32 %86)
  call void @cqrt_and_i1(i32 %85, i32 %82, i32 %81)
  call void @cqrt_free(i32 %81)
  call void @cqrt_xor_i1(i32 %80, i32 %82)
  call void @cqrt_not_i1(i32 %82)
  call void @cqrt_free(i32 %82)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %80, i32 %1, i32 %79)
  call void @cqrt_free(i32 %80)
  call void @cq_template_select_i64_unc(i32 %84, i32 %78, i32 %83, i32 %77)
  call void @cqrt_free(i32 %84)
  call void @cq_template_sub_i64_unc(i32 %77, i32 %83, i32 %76)
  call void @cqrt_free(i32 %77)
  call void @cq_template_select_i64_lh_unc(i32 %76, i32 %75, i64 3, i32 %83)
  call void @cqrt_free(i32 %76)
  call void @cq_template_and_i1_hl_unc(i32 %75, i32 %74, i1 %73)
  call void @cqrt_free(i32 %75)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %74, i32 %83, i64 2)
  call void @cqrt_free(i32 %74)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %78, i32 %83, i64 1)
  call void @cqrt_free(i32 %78)
  %87 = call i32 @cqrt_pop()
  switch i32 %87, label %70 [
    i32 1, label %69
  ]

88:                                               ; preds = %63
  call void @cqrt_copy_i64(i32 %55, i32 %62)
  call void @cqrt_free(i32 %62)
  br label %89

89:                                               ; preds = %88
  switch i32 %54, label %69 [
    i32 1, label %70
  ]

90:                                               ; preds = %6
  %91 = call i32 @cqrt_alloc_i64(i64 0)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %92)
  call void @cqrt_push(i32 0)
  %93 = load i32, ptr @__cq_act_f, align 4
  %94 = add i32 %93, -1
  store i32 %94, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %91
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
