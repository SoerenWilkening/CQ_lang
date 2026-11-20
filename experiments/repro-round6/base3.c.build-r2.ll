; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/base3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@out = local_unnamed_addr global [8 x i64] zeroinitializer, align 16
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [23 x i8] c"i64 (i32, i64, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i64 @f(i32 noundef %0, i64 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i64(i64 %1)
  call void @cqrt_ry_i64(i32 %4, double %2)
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %7

6:                                                ; preds = %3
  br label %13

7:                                                ; preds = %3, %21
  %ran = phi i1 [ false, %3 ], [ true, %21 ]
  %8 = phi i32 [ %4, %3 ], [ %18, %21 ]
  %9 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %8, i32 %9)
  br i1 %ran, label %23, label %29

10:                                               ; preds = %29
  %11 = zext i32 %9 to i64
  ret i64 %11

12:                                               ; preds = %13
  br label %21

13:                                               ; preds = %13, %6
  %from = phi i32 [ 0, %13 ], [ 1, %6 ]
  %14 = phi i32 [ 0, %6 ], [ %19, %13 ]
  %15 = phi i32 [ %4, %6 ], [ %18, %13 ]
  call void @cqrt_push(i32 %from)
  %16 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %15, i64 0)
  %17 = call i32 @cq_template_add_i64_hl(i32 %15, i64 -3)
  call fastcc void @__cq_q_put_01_ctl(i32 %16, i32 %14, i32 %17)
  %18 = call i32 @cq_template_select_i64(i32 %16, i32 %17, i32 %15)
  %19 = add nuw nsw i32 %14, 1
  %20 = icmp eq i32 %19, %0
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %15)
  br i1 %20, label %12, label %13

21:                                               ; preds = %12
  br label %7

22:                                               ; preds = %23
  br label %29

23:                                               ; preds = %7, %23
  %24 = call i32 @cqrt_pop()
  %25 = call i32 @cqrt_pop()
  %26 = call i32 @cqrt_pop()
  %27 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %27, i32 %26, i32 %25, i32 %24)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i64_hl_unc(i32 %25, i32 %24, i64 -3)
  call void @cqrt_free(i32 %25)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %26, i32 %24, i64 0)
  call void @cqrt_free(i32 %26)
  %28 = call i32 @cqrt_pop()
  switch i32 %28, label %23 [
    i32 1, label %22
  ]

29:                                               ; preds = %22, %7
  br label %10
}

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

define internal fastcc void @__cq_q_put_01_ctl(i32 %0, i32 %1, i32 %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = and i32 %1, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i64], ptr @out, i64 0, i64 %6
  %8 = ptrtoint ptr %7 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %4, i64 %8, i32 %2)
  ret void
}

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %cq.mints = alloca ptr, align 8
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  store ptr null, ptr %cq.mints, align 8
  %6 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %1, i32 %6)
  call void @cqrt_ry_i64_qangle(i32 %6, i32 %2)
  %7 = alloca { i32, ptr }, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 0
  store i32 %6, ptr %8, align 4
  %9 = load ptr, ptr %cq.mints, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 1
  store ptr %9, ptr %10, align 8
  store ptr %7, ptr %cq.mints, align 8
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  br label %12

12:                                               ; preds = %4
  %13 = call i32 @llvm.umin.i32(i32 %3, i32 2147483647)
  %14 = icmp ult i32 %3, 2147483647
  %15 = icmp ult i32 0, %13
  br i1 %15, label %16, label %32

16:                                               ; preds = %16, %12
  %from = phi i32 [ 0, %16 ], [ 1, %12 ]
  %17 = phi i32 [ 0, %12 ], [ %30, %16 ]
  %18 = phi i32 [ %11, %12 ], [ %28, %16 ]
  %19 = phi i32 [ 0, %12 ], [ %25, %16 ]
  %20 = phi i32 [ %6, %12 ], [ %29, %16 ]
  call void @cqrt_push(i32 %from)
  %21 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %20, i64 0)
  %22 = call i32 @cq_template_add_i64_hl(i32 %20, i64 -3)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %18, i32 %21, i32 %23)
  call fastcc void @__cq_q_put_01_ctl(i32 %23, i32 %19, i32 %22)
  call void @cqrt_and_i1(i32 %18, i32 %21, i32 %23)
  call void @cqrt_free(i32 %23)
  %24 = call i32 @cq_template_select_i64(i32 %21, i32 %22, i32 %20)
  %25 = add i32 %19, 1
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %25)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %26, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %18, i32 %27, i32 %28)
  %29 = call i32 @cq_template_select_i64(i32 %18, i32 %24, i32 %20)
  %30 = add i32 %17, 1
  %31 = icmp ult i32 %30, %13
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  br i1 %31, label %16, label %32

32:                                               ; preds = %16, %12
  %33 = phi i32 [ 0, %12 ], [ 1, %16 ]
  %34 = phi i32 [ 0, %12 ], [ %25, %16 ]
  %35 = phi i32 [ %6, %12 ], [ %29, %16 ]
  %36 = phi i32 [ %11, %12 ], [ %28, %16 ]
  br i1 %14, label %37, label %39

37:                                               ; preds = %32
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %36, i32 %38)
  br label %40

39:                                               ; preds = %32
  br label %40

40:                                               ; preds = %37, %39
  %41 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %35, i32 %41)
  br label %42

42:                                               ; preds = %40
  %43 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %43)
  %44 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %41, i32 %44)
  br label %59

45:                                               ; preds = %46
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %0, i32 0)
  call void @cqrt_free(i32 %11)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %44

46:                                               ; preds = %60, %47
  br label %45

47:                                               ; preds = %60, %47
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
  call void @cq_template_select_i64_unc(i32 %57, i32 %56, i32 %55, i32 %54)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %56, i32 %53, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_xor_i1(i32 %51, i32 %53)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %51, i32 %0, i32 %50)
  call void @cqrt_free(i32 %51)
  call void @cq_template_select_i64_unc(i32 %55, i32 %49, i32 %48, i32 %54)
  call void @cqrt_free(i32 %55)
  call void @cq_template_add_i64_hl_unc(i32 %48, i32 %54, i64 -3)
  call void @cqrt_free(i32 %48)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %49, i32 %54, i64 0)
  call void @cqrt_free(i32 %49)
  %58 = call i32 @cqrt_pop()
  switch i32 %58, label %47 [
    i32 1, label %46
  ]

59:                                               ; preds = %42
  call void @cqrt_copy_i64(i32 %35, i32 %41)
  call void @cqrt_free(i32 %41)
  br label %60

60:                                               ; preds = %59
  switch i32 %33, label %46 [
    i32 1, label %47
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

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %69

10:                                               ; preds = %5
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %2, i32 %11)
  call void @cqrt_ry_i64_qangle_controlled(i32 %0, i32 %11, i32 %3)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  br label %17

17:                                               ; preds = %10
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  %19 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %20 = icmp ult i32 %4, 2147483647
  %21 = icmp ult i32 0, %19
  br i1 %21, label %22, label %38

22:                                               ; preds = %22, %17
  %from = phi i32 [ 0, %22 ], [ 1, %17 ]
  %23 = phi i32 [ 0, %17 ], [ %36, %22 ]
  %24 = phi i32 [ %18, %17 ], [ %34, %22 ]
  %25 = phi i32 [ 0, %17 ], [ %31, %22 ]
  %26 = phi i32 [ %11, %17 ], [ %35, %22 ]
  call void @cqrt_push(i32 %from)
  %27 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %26, i64 0)
  %28 = call i32 @cq_template_add_i64_hl(i32 %26, i64 -3)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %27, i32 %29)
  call fastcc void @__cq_q_put_01_ctl(i32 %29, i32 %25, i32 %28)
  call void @cqrt_and_i1(i32 %24, i32 %27, i32 %29)
  call void @cqrt_free(i32 %29)
  %30 = call i32 @cq_template_select_i64(i32 %27, i32 %28, i32 %26)
  %31 = add i32 %25, 1
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_xor_i1(i32 %32, i32 %33)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %33, i32 %34)
  %35 = call i32 @cq_template_select_i64(i32 %24, i32 %30, i32 %26)
  %36 = add i32 %23, 1
  %37 = icmp ult i32 %36, %19
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %28)
  br i1 %37, label %22, label %38

38:                                               ; preds = %22, %17
  %39 = phi i32 [ 0, %17 ], [ 1, %22 ]
  %40 = phi i32 [ 0, %17 ], [ %31, %22 ]
  %41 = phi i32 [ %11, %17 ], [ %35, %22 ]
  %42 = phi i32 [ %18, %17 ], [ %34, %22 ]
  br i1 %20, label %43, label %45

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
  br label %67

51:                                               ; preds = %54
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %16, i32 %1, i32 0)
  call void @cqrt_free(i32 %16)
  %52 = load i32, ptr @__cq_act_f, align 4
  %53 = add i32 %52, -1
  store i32 %53, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %50

54:                                               ; preds = %68, %55
  br label %51

55:                                               ; preds = %68, %55
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
  call void @cq_template_select_i64_unc(i32 %65, i32 %64, i32 %63, i32 %62)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %64, i32 %61, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cqrt_xor_i1(i32 %59, i32 %61)
  call void @cqrt_not_i1(i32 %61)
  call void @cqrt_free(i32 %61)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %59, i32 %1, i32 %58)
  call void @cqrt_free(i32 %59)
  call void @cq_template_select_i64_unc(i32 %63, i32 %57, i32 %56, i32 %62)
  call void @cqrt_free(i32 %63)
  call void @cq_template_add_i64_hl_unc(i32 %56, i32 %62, i64 -3)
  call void @cqrt_free(i32 %56)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %57, i32 %62, i64 0)
  call void @cqrt_free(i32 %57)
  %66 = call i32 @cqrt_pop()
  switch i32 %66, label %55 [
    i32 1, label %54
  ]

67:                                               ; preds = %48
  call void @cqrt_copy_i64(i32 %41, i32 %47)
  call void @cqrt_free(i32 %47)
  br label %68

68:                                               ; preds = %67
  switch i32 %39, label %54 [
    i32 1, label %55
  ]

69:                                               ; preds = %5
  %70 = call i32 @cqrt_alloc_i64(i64 0)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %71)
  call void @cqrt_push(i32 0)
  %72 = load i32, ptr @__cq_act_f, align 4
  %73 = add i32 %72, -1
  store i32 %73, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %70
}

declare void @cqrt_ry_i64_qangle_controlled(i32, i32, i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @cqrt_pop()
  br label %8

8:                                                ; preds = %11, %5
  %9 = phi i32 [ %7, %5 ], [ %13, %11 ]
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %14, label %11

11:                                               ; preds = %8
  %12 = call i32 @cqrt_pop()
  %13 = sub i32 %9, 1
  br label %8

14:                                               ; preds = %8
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = load i32, ptr @__cq_act_f, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_f, align 4
  %12 = call i32 @cqrt_pop()
  br label %13

13:                                               ; preds = %16, %6
  %14 = phi i32 [ %12, %6 ], [ %18, %16 ]
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %19, label %16

16:                                               ; preds = %13
  %17 = call i32 @cqrt_pop()
  %18 = sub i32 %14, 1
  br label %13

19:                                               ; preds = %13
  store i32 %7, ptr @__cq_k, align 4
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
