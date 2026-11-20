; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/base1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

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

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %1, i32 %6)
  call void @cqrt_ry_i64_qangle(i32 %6, i32 %2)
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  br label %8

8:                                                ; preds = %4
  %9 = call i32 @llvm.umin.i32(i32 %3, i32 2147483647)
  %10 = icmp ult i32 %3, 2147483647
  %11 = icmp ult i32 0, %9
  br i1 %11, label %12, label %27

12:                                               ; preds = %12, %8
  %from = phi i32 [ 0, %12 ], [ 1, %8 ]
  %13 = phi i32 [ 0, %8 ], [ %25, %12 ]
  %14 = phi i32 [ %7, %8 ], [ %23, %12 ]
  %15 = phi i32 [ 0, %8 ], [ %20, %12 ]
  %16 = phi i32 [ %6, %8 ], [ %24, %12 ]
  call void @cqrt_push(i32 %from)
  %17 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 0)
  %18 = call i32 @cq_template_add_i64_hl(i32 %16, i64 -3)
  %19 = call i32 @cq_template_select_i64(i32 %17, i32 %18, i32 %16)
  %20 = add i32 %15, 1
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %20)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %21, i32 %22)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %22, i32 %23)
  %24 = call i32 @cq_template_select_i64(i32 %14, i32 %19, i32 %16)
  %25 = add i32 %13, 1
  %26 = icmp ult i32 %25, %9
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  br i1 %26, label %12, label %27

27:                                               ; preds = %12, %8
  %28 = phi i32 [ 0, %8 ], [ 1, %12 ]
  %29 = phi i32 [ 0, %8 ], [ %20, %12 ]
  %30 = phi i32 [ %6, %8 ], [ %24, %12 ]
  %31 = phi i32 [ %7, %8 ], [ %23, %12 ]
  br i1 %10, label %32, label %34

32:                                               ; preds = %27
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %31, i32 %33)
  br label %35

34:                                               ; preds = %27
  br label %35

35:                                               ; preds = %32, %34
  %36 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %30, i32 %36)
  br label %37

37:                                               ; preds = %35
  call void @cqrt_push(i32 %6)
  %38 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %36, i32 %38)
  br label %53

39:                                               ; preds = %40
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %0, i32 0)
  call void @cqrt_free(i32 %7)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %38

40:                                               ; preds = %54, %41
  br label %39

41:                                               ; preds = %54, %41
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  %48 = call i32 @cqrt_pop()
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %51, i32 %50, i32 %49, i32 %48)
  call void @cqrt_free(i32 %51)
  call void @cqrt_and_i1(i32 %50, i32 %47, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_xor_i1(i32 %45, i32 %47)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %45, i32 %0, i32 %44)
  call void @cqrt_free(i32 %45)
  call void @cq_template_select_i64_unc(i32 %49, i32 %43, i32 %42, i32 %48)
  call void @cqrt_free(i32 %49)
  call void @cq_template_add_i64_hl_unc(i32 %42, i32 %48, i64 -3)
  call void @cqrt_free(i32 %42)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %43, i32 %48, i64 0)
  call void @cqrt_free(i32 %43)
  %52 = call i32 @cqrt_pop()
  switch i32 %52, label %41 [
    i32 1, label %40
  ]

53:                                               ; preds = %37
  call void @cqrt_copy_i64(i32 %30, i32 %36)
  call void @cqrt_free(i32 %36)
  br label %54

54:                                               ; preds = %53
  switch i32 %28, label %40 [
    i32 1, label %41
  ]
}

declare void @cqrt_ry_i64_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %63

10:                                               ; preds = %5
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %2, i32 %11)
  call void @cqrt_ry_i64_qangle_controlled(i32 %0, i32 %11, i32 %3)
  %12 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  br label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %14)
  %15 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %16 = icmp ult i32 %4, 2147483647
  %17 = icmp ult i32 0, %15
  br i1 %17, label %18, label %33

18:                                               ; preds = %18, %13
  %from = phi i32 [ 0, %18 ], [ 1, %13 ]
  %19 = phi i32 [ 0, %13 ], [ %31, %18 ]
  %20 = phi i32 [ %14, %13 ], [ %29, %18 ]
  %21 = phi i32 [ 0, %13 ], [ %26, %18 ]
  %22 = phi i32 [ %11, %13 ], [ %30, %18 ]
  call void @cqrt_push(i32 %from)
  %23 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %22, i64 0)
  %24 = call i32 @cq_template_add_i64_hl(i32 %22, i64 -3)
  %25 = call i32 @cq_template_select_i64(i32 %23, i32 %24, i32 %22)
  %26 = add i32 %21, 1
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %26)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %27, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %28, i32 %29)
  %30 = call i32 @cq_template_select_i64(i32 %20, i32 %25, i32 %22)
  %31 = add i32 %19, 1
  %32 = icmp ult i32 %31, %15
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  br i1 %32, label %18, label %33

33:                                               ; preds = %18, %13
  %34 = phi i32 [ 0, %13 ], [ 1, %18 ]
  %35 = phi i32 [ 0, %13 ], [ %26, %18 ]
  %36 = phi i32 [ %11, %13 ], [ %30, %18 ]
  %37 = phi i32 [ %14, %13 ], [ %29, %18 ]
  br i1 %16, label %38, label %40

38:                                               ; preds = %33
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %37, i32 %39)
  br label %41

40:                                               ; preds = %33
  br label %41

41:                                               ; preds = %38, %40
  %42 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %36, i32 %42)
  br label %43

43:                                               ; preds = %41
  call void @cqrt_push(i32 %11)
  %44 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %42, i32 %44)
  br label %61

45:                                               ; preds = %48
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %12, i32 %1, i32 0)
  call void @cqrt_free(i32 %12)
  %46 = load i32, ptr @__cq_act_f, align 4
  %47 = add i32 %46, -1
  store i32 %47, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %44

48:                                               ; preds = %62, %49
  br label %45

49:                                               ; preds = %62, %49
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
  call void @cq_template_select_i64_unc(i32 %59, i32 %58, i32 %57, i32 %56)
  call void @cqrt_free(i32 %59)
  call void @cqrt_and_i1(i32 %58, i32 %55, i32 %54)
  call void @cqrt_free(i32 %54)
  call void @cqrt_xor_i1(i32 %53, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %53, i32 %1, i32 %52)
  call void @cqrt_free(i32 %53)
  call void @cq_template_select_i64_unc(i32 %57, i32 %51, i32 %50, i32 %56)
  call void @cqrt_free(i32 %57)
  call void @cq_template_add_i64_hl_unc(i32 %50, i32 %56, i64 -3)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %51, i32 %56, i64 0)
  call void @cqrt_free(i32 %51)
  %60 = call i32 @cqrt_pop()
  switch i32 %60, label %49 [
    i32 1, label %48
  ]

61:                                               ; preds = %43
  call void @cqrt_copy_i64(i32 %36, i32 %42)
  call void @cqrt_free(i32 %42)
  br label %62

62:                                               ; preds = %61
  switch i32 %34, label %48 [
    i32 1, label %49
  ]

63:                                               ; preds = %5
  %64 = call i32 @cqrt_alloc_i64(i64 0)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %65)
  call void @cqrt_push(i32 0)
  %66 = load i32, ptr @__cq_act_f, align 4
  %67 = add i32 %66, -1
  store i32 %67, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %64
}

declare void @cqrt_ry_i64_qangle_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_111_t_unc(i32 %out, i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  br label %8

8:                                                ; preds = %4
  %9 = call i32 @llvm.umin.i32(i32 %3, i32 2147483647)
  %10 = icmp ult i32 %3, 2147483647
  %11 = icmp ult i32 0, %9
  br i1 %11, label %12, label %27

12:                                               ; preds = %12, %8
  %from = phi i32 [ 0, %12 ], [ 1, %8 ]
  %13 = phi i32 [ 0, %8 ], [ %25, %12 ]
  %14 = phi i32 [ %7, %8 ], [ %23, %12 ]
  %15 = phi i32 [ 0, %8 ], [ %20, %12 ]
  %16 = phi i32 [ %6, %8 ], [ %24, %12 ]
  call void @cqrt_push(i32 %from)
  %17 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 0)
  %18 = call i32 @cq_template_add_i64_hl(i32 %16, i64 -3)
  %19 = call i32 @cq_template_select_i64(i32 %17, i32 %18, i32 %16)
  %20 = add i32 %15, 1
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %20)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %21, i32 %22)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %22, i32 %23)
  %24 = call i32 @cq_template_select_i64(i32 %14, i32 %19, i32 %16)
  %25 = add i32 %13, 1
  %26 = icmp ult i32 %25, %9
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  br i1 %26, label %12, label %27

27:                                               ; preds = %12, %8
  %28 = phi i32 [ 0, %8 ], [ 1, %12 ]
  %29 = phi i32 [ %6, %8 ], [ %24, %12 ]
  br i1 %10, label %30, label %31

30:                                               ; preds = %27
  br label %32

31:                                               ; preds = %27
  br label %32

32:                                               ; preds = %31, %30
  %33 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %29, i32 %33)
  br label %34

34:                                               ; preds = %32
  call void @cqrt_copy_i64(i32 %33, i32 %out)
  br label %49

35:                                               ; preds = %36
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %0, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

36:                                               ; preds = %50, %37
  br label %35

37:                                               ; preds = %50, %37
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %47, i32 %46, i32 %45, i32 %44)
  call void @cqrt_free(i32 %47)
  call void @cqrt_and_i1(i32 %46, i32 %43, i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_xor_i1(i32 %41, i32 %43)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %41, i32 %0, i32 %40)
  call void @cqrt_free(i32 %41)
  call void @cq_template_select_i64_unc(i32 %45, i32 %39, i32 %38, i32 %44)
  call void @cqrt_free(i32 %45)
  call void @cq_template_add_i64_hl_unc(i32 %38, i32 %44, i64 -3)
  call void @cqrt_free(i32 %38)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %39, i32 %44, i64 0)
  call void @cqrt_free(i32 %39)
  %48 = call i32 @cqrt_pop()
  switch i32 %48, label %37 [
    i32 1, label %36
  ]

49:                                               ; preds = %34
  call void @cqrt_copy_i64(i32 %29, i32 %33)
  call void @cqrt_free(i32 %33)
  br label %50

50:                                               ; preds = %49
  switch i32 %28, label %36 [
    i32 1, label %37
  ]
}

define internal void @__cq_q_f_111_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @cqrt_pop()
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = icmp ult i32 %8, %4
  br i1 %10, label %11, label %59

11:                                               ; preds = %5
  %12 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  br label %13

13:                                               ; preds = %11
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %14)
  %15 = call i32 @llvm.umin.i32(i32 %4, i32 2147483647)
  %16 = icmp ult i32 %4, 2147483647
  %17 = icmp ult i32 0, %15
  br i1 %17, label %18, label %33

18:                                               ; preds = %18, %13
  %from = phi i32 [ 0, %18 ], [ 1, %13 ]
  %19 = phi i32 [ 0, %13 ], [ %31, %18 ]
  %20 = phi i32 [ %14, %13 ], [ %29, %18 ]
  %21 = phi i32 [ 0, %13 ], [ %26, %18 ]
  %22 = phi i32 [ %7, %13 ], [ %30, %18 ]
  call void @cqrt_push(i32 %from)
  %23 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %22, i64 0)
  %24 = call i32 @cq_template_add_i64_hl(i32 %22, i64 -3)
  %25 = call i32 @cq_template_select_i64(i32 %23, i32 %24, i32 %22)
  %26 = add i32 %21, 1
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %26)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %27, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %28, i32 %29)
  %30 = call i32 @cq_template_select_i64(i32 %20, i32 %25, i32 %22)
  %31 = add i32 %19, 1
  %32 = icmp ult i32 %31, %15
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  br i1 %32, label %18, label %33

33:                                               ; preds = %18, %13
  %34 = phi i32 [ 0, %13 ], [ 1, %18 ]
  %35 = phi i32 [ %7, %13 ], [ %30, %18 ]
  br i1 %16, label %36, label %37

36:                                               ; preds = %33
  br label %38

37:                                               ; preds = %33
  br label %38

38:                                               ; preds = %37, %36
  %39 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %35, i32 %39)
  br label %40

40:                                               ; preds = %38
  call void @cqrt_copy_i64(i32 %39, i32 %out)
  br label %57

41:                                               ; preds = %44
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %12, i32 %1, i32 0)
  call void @cqrt_free(i32 %12)
  %42 = load i32, ptr @__cq_act_f, align 4
  %43 = add i32 %42, -1
  store i32 %43, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %6, ptr @__cq_k, align 4
  ret void

44:                                               ; preds = %58, %45
  br label %41

45:                                               ; preds = %58, %45
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
  call void @cq_template_select_i64_unc(i32 %55, i32 %54, i32 %53, i32 %52)
  call void @cqrt_free(i32 %55)
  call void @cqrt_and_i1(i32 %54, i32 %51, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cqrt_xor_i1(i32 %49, i32 %51)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %49, i32 %1, i32 %48)
  call void @cqrt_free(i32 %49)
  call void @cq_template_select_i64_unc(i32 %53, i32 %47, i32 %46, i32 %52)
  call void @cqrt_free(i32 %53)
  call void @cq_template_add_i64_hl_unc(i32 %46, i32 %52, i64 -3)
  call void @cqrt_free(i32 %46)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %47, i32 %52, i64 0)
  call void @cqrt_free(i32 %47)
  %56 = call i32 @cqrt_pop()
  switch i32 %56, label %45 [
    i32 1, label %44
  ]

57:                                               ; preds = %40
  call void @cqrt_copy_i64(i32 %35, i32 %39)
  call void @cqrt_free(i32 %39)
  br label %58

58:                                               ; preds = %57
  switch i32 %34, label %44 [
    i32 1, label %45
  ]

59:                                               ; preds = %5
  %60 = load i32, ptr @__cq_act_f, align 4
  %61 = add i32 %60, -1
  store i32 %61, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %6, ptr @__cq_k, align 4
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
