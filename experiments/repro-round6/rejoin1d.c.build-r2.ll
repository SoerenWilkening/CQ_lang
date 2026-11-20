; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/rejoin1d.c"
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
  br i1 %7, label %8, label %9

8:                                                ; preds = %4
  br label %15

9:                                                ; preds = %4, %34
  %ran = phi i1 [ false, %4 ], [ true, %34 ]
  %10 = phi i32 [ %6, %4 ], [ %30, %34 ]
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %10, i32 %11)
  br i1 %ran, label %36, label %48

12:                                               ; preds = %48
  %13 = zext i32 %11 to i64
  ret i64 %13

14:                                               ; preds = %15
  br label %34

15:                                               ; preds = %15, %8
  %from = phi i32 [ 0, %15 ], [ 1, %8 ]
  %16 = phi i32 [ %6, %8 ], [ %30, %15 ]
  %17 = phi i32 [ 0, %8 ], [ %31, %15 ]
  call void @cqrt_push(i32 %from)
  %18 = call i32 @cq_template_icmp_slt_i64_hl(i32 %16, i64 1)
  %19 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 2)
  %20 = icmp ult i32 %17, 2
  %21 = call i32 @cq_template_and_i1_hl(i32 %19, i1 %20)
  %22 = call i32 @cq_template_select_i64_lh(i32 %21, i64 3, i32 %16)
  %23 = call i32 @cq_template_sub_i64(i32 %16, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_xor_i1(i32 %18, i32 %24)
  call fastcc void @__cq_q_put_01_ctl(i32 %24, i32 %17, i32 %22)
  call void @cqrt_xor_i1(i32 %18, i32 %24)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_free(i32 %24)
  %25 = and i32 %17, 7
  %26 = zext nneg i32 %25 to i64
  %27 = getelementptr inbounds [8 x i64], ptr @out2, i64 0, i64 %26
  %28 = ptrtoint ptr %27 to i64
  %29 = call i32 @cqrt_alloc_i64(i64 %1)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %18, i32 %5, i64 %28, i32 %29)
  %30 = call i32 @cq_template_select_i64(i32 %18, i32 %16, i32 %23)
  %31 = add nuw nsw i32 %17, 1
  %32 = icmp eq i32 %31, %0
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %19)
  %33 = zext i1 %20 to i32
  call void @cqrt_push(i32 %33)
  br i1 %32, label %14, label %15

34:                                               ; preds = %14
  br label %9

35:                                               ; preds = %36
  br label %48

36:                                               ; preds = %9, %36
  %37 = call i32 @cqrt_pop()
  %38 = or i32 0, %37
  %39 = trunc i32 %38 to i1
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %46, i32 %45, i32 %44, i32 %43)
  call void @cqrt_free(i32 %46)
  call void @cq_template_sub_i64_unc(i32 %43, i32 %44, i32 %42)
  call void @cqrt_free(i32 %43)
  call void @cq_template_select_i64_lh_unc(i32 %42, i32 %41, i64 3, i32 %44)
  call void @cqrt_free(i32 %42)
  call void @cq_template_and_i1_hl_unc(i32 %41, i32 %40, i1 %39)
  call void @cqrt_free(i32 %41)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %40, i32 %44, i64 2)
  call void @cqrt_free(i32 %40)
  %47 = call i32 @cqrt_pop()
  switch i32 %47, label %36 [
    i32 1, label %35
  ]

48:                                               ; preds = %35, %9
  br label %12
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

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cq_template_sub_i64_unc(i32, i32, i32)

declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)

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
  br label %14

14:                                               ; preds = %5
  %15 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %16 = icmp ult i32 %4, 2147483647
  %17 = icmp ult i32 0, %15
  br i1 %17, label %18, label %45

18:                                               ; preds = %18, %14
  %from = phi i32 [ 0, %18 ], [ 1, %14 ]
  %19 = phi i32 [ 0, %14 ], [ %42, %18 ]
  %20 = phi i32 [ %13, %14 ], [ %40, %18 ]
  %21 = phi i32 [ %8, %14 ], [ %41, %18 ]
  %22 = phi i32 [ 0, %14 ], [ %37, %18 ]
  call void @cqrt_push(i32 %from)
  %23 = call i32 @cq_template_icmp_slt_i64_hl(i32 %21, i64 1)
  %24 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %21, i64 2)
  %25 = icmp ult i32 %22, 2
  %26 = call i32 @cq_template_and_i1_hl(i32 %24, i1 %25)
  %27 = call i32 @cq_template_select_i64_lh(i32 %26, i64 3, i32 %21)
  %28 = call i32 @cq_template_sub_i64(i32 %21, i32 %27)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_xor_i1(i32 %23, i32 %29)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %29, i32 %30)
  call fastcc void @__cq_q_put_01_ctl(i32 %30, i32 %22, i32 %27)
  call void @cqrt_and_i1(i32 %20, i32 %29, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_xor_i1(i32 %23, i32 %29)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_free(i32 %29)
  %31 = and i32 %22, 7
  %32 = zext i32 %31 to i64
  %33 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %32
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %34)
  %35 = ptrtoint ptr %33 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %34, i32 %7, i64 %35, i32 %1)
  %36 = call i32 @cq_template_select_i64(i32 %23, i32 %21, i32 %28)
  %37 = add i32 %22, 1
  %38 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %37)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_xor_i1(i32 %38, i32 %39)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %39, i32 %40)
  %41 = call i32 @cq_template_select_i64(i32 %20, i32 %36, i32 %21)
  %42 = add i32 %19, 1
  %43 = icmp ult i32 %42, %15
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %24)
  %44 = zext i1 %25 to i32
  call void @cqrt_push(i32 %44)
  br i1 %43, label %18, label %45

45:                                               ; preds = %18, %14
  %46 = phi i32 [ 0, %14 ], [ 1, %18 ]
  %47 = phi i32 [ %8, %14 ], [ %41, %18 ]
  %48 = phi i32 [ 0, %14 ], [ %37, %18 ]
  %49 = phi i32 [ %13, %14 ], [ %40, %18 ]
  br i1 %16, label %50, label %52

50:                                               ; preds = %45
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %49, i32 %51)
  br label %53

52:                                               ; preds = %45
  br label %53

53:                                               ; preds = %50, %52
  %54 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %47, i32 %54)
  br label %55

55:                                               ; preds = %53
  %56 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %56)
  %57 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %54, i32 %57)
  br label %78

58:                                               ; preds = %59
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %0, i32 0)
  call void @cqrt_free(i32 %13)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %57

59:                                               ; preds = %79, %60
  br label %58

60:                                               ; preds = %79, %60
  %61 = call i32 @cqrt_pop()
  %62 = or i32 0, %61
  %63 = trunc i32 %62 to i1
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
  %75 = call i32 @cqrt_pop()
  %76 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %76, i32 %75, i32 %74, i32 %73)
  call void @cqrt_free(i32 %76)
  call void @cqrt_and_i1(i32 %75, i32 %72, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_xor_i1(i32 %70, i32 %72)
  call void @cqrt_not_i1(i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %70, i32 %0, i32 %69)
  call void @cqrt_free(i32 %70)
  call void @cq_template_select_i64_unc(i32 %74, i32 %68, i32 %73, i32 %67)
  call void @cqrt_free(i32 %74)
  call void @cq_template_sub_i64_unc(i32 %67, i32 %73, i32 %66)
  call void @cqrt_free(i32 %67)
  call void @cq_template_select_i64_lh_unc(i32 %66, i32 %65, i64 3, i32 %73)
  call void @cqrt_free(i32 %66)
  call void @cq_template_and_i1_hl_unc(i32 %65, i32 %64, i1 %63)
  call void @cqrt_free(i32 %65)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %64, i32 %73, i64 2)
  call void @cqrt_free(i32 %64)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %68, i32 %73, i64 1)
  call void @cqrt_free(i32 %68)
  %77 = call i32 @cqrt_pop()
  switch i32 %77, label %60 [
    i32 1, label %59
  ]

78:                                               ; preds = %55
  call void @cqrt_copy_i64(i32 %47, i32 %54)
  call void @cqrt_free(i32 %54)
  br label %79

79:                                               ; preds = %78
  switch i32 %46, label %59 [
    i32 1, label %60
  ]
}

declare void @cqrt_ry_i64_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

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
  br i1 %10, label %11, label %88

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
  br i1 %23, label %24, label %51

24:                                               ; preds = %24, %19
  %from = phi i32 [ 0, %24 ], [ 1, %19 ]
  %25 = phi i32 [ 0, %19 ], [ %48, %24 ]
  %26 = phi i32 [ %20, %19 ], [ %46, %24 ]
  %27 = phi i32 [ %13, %19 ], [ %47, %24 ]
  %28 = phi i32 [ 0, %19 ], [ %43, %24 ]
  call void @cqrt_push(i32 %from)
  %29 = call i32 @cq_template_icmp_slt_i64_hl(i32 %27, i64 1)
  %30 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %27, i64 2)
  %31 = icmp ult i32 %28, 2
  %32 = call i32 @cq_template_and_i1_hl(i32 %30, i1 %31)
  %33 = call i32 @cq_template_select_i64_lh(i32 %32, i64 3, i32 %27)
  %34 = call i32 @cq_template_sub_i64(i32 %27, i32 %33)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_xor_i1(i32 %29, i32 %35)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %26, i32 %35, i32 %36)
  call fastcc void @__cq_q_put_01_ctl(i32 %36, i32 %28, i32 %33)
  call void @cqrt_and_i1(i32 %26, i32 %35, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_xor_i1(i32 %29, i32 %35)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %35)
  %37 = and i32 %28, 7
  %38 = zext i32 %37 to i64
  %39 = getelementptr [8 x i64], ptr @out2, i64 0, i64 %38
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %26, i32 %29, i32 %40)
  %41 = ptrtoint ptr %39 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %40, i32 %12, i64 %41, i32 %2)
  %42 = call i32 @cq_template_select_i64(i32 %29, i32 %27, i32 %34)
  %43 = add i32 %28, 1
  %44 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %43)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_xor_i1(i32 %44, i32 %45)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %26, i32 %45, i32 %46)
  %47 = call i32 @cq_template_select_i64(i32 %26, i32 %42, i32 %27)
  %48 = add i32 %25, 1
  %49 = icmp ult i32 %48, %21
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %30)
  %50 = zext i1 %31 to i32
  call void @cqrt_push(i32 %50)
  br i1 %49, label %24, label %51

51:                                               ; preds = %24, %19
  %52 = phi i32 [ 0, %19 ], [ 1, %24 ]
  %53 = phi i32 [ %13, %19 ], [ %47, %24 ]
  %54 = phi i32 [ 0, %19 ], [ %43, %24 ]
  %55 = phi i32 [ %20, %19 ], [ %46, %24 ]
  br i1 %22, label %56, label %58

56:                                               ; preds = %51
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %55, i32 %57)
  br label %59

58:                                               ; preds = %51
  br label %59

59:                                               ; preds = %56, %58
  %60 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %53, i32 %60)
  br label %61

61:                                               ; preds = %59
  %62 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %62)
  %63 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %60, i32 %63)
  br label %86

64:                                               ; preds = %67
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %1, i32 0)
  call void @cqrt_free(i32 %18)
  %65 = load i32, ptr @__cq_act_f, align 4
  %66 = add i32 %65, -1
  store i32 %66, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %63

67:                                               ; preds = %87, %68
  br label %64

68:                                               ; preds = %87, %68
  %69 = call i32 @cqrt_pop()
  %70 = or i32 0, %69
  %71 = trunc i32 %70 to i1
  %72 = call i32 @cqrt_pop()
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
  call void @cq_template_select_i64_unc(i32 %84, i32 %83, i32 %82, i32 %81)
  call void @cqrt_free(i32 %84)
  call void @cqrt_and_i1(i32 %83, i32 %80, i32 %79)
  call void @cqrt_free(i32 %79)
  call void @cqrt_xor_i1(i32 %78, i32 %80)
  call void @cqrt_not_i1(i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %78, i32 %1, i32 %77)
  call void @cqrt_free(i32 %78)
  call void @cq_template_select_i64_unc(i32 %82, i32 %76, i32 %81, i32 %75)
  call void @cqrt_free(i32 %82)
  call void @cq_template_sub_i64_unc(i32 %75, i32 %81, i32 %74)
  call void @cqrt_free(i32 %75)
  call void @cq_template_select_i64_lh_unc(i32 %74, i32 %73, i64 3, i32 %81)
  call void @cqrt_free(i32 %74)
  call void @cq_template_and_i1_hl_unc(i32 %73, i32 %72, i1 %71)
  call void @cqrt_free(i32 %73)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %72, i32 %81, i64 2)
  call void @cqrt_free(i32 %72)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %76, i32 %81, i64 1)
  call void @cqrt_free(i32 %76)
  %85 = call i32 @cqrt_pop()
  switch i32 %85, label %68 [
    i32 1, label %67
  ]

86:                                               ; preds = %61
  call void @cqrt_copy_i64(i32 %53, i32 %60)
  call void @cqrt_free(i32 %60)
  br label %87

87:                                               ; preds = %86
  switch i32 %52, label %67 [
    i32 1, label %68
  ]

88:                                               ; preds = %6
  %89 = call i32 @cqrt_alloc_i64(i64 0)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %90)
  call void @cqrt_push(i32 0)
  %91 = load i32, ptr @__cq_act_f, align 4
  %92 = add i32 %91, -1
  store i32 %92, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %89
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
