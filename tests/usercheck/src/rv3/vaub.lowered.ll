; ModuleID = 'vaub.c'
source_filename = "vaub.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_sum = internal global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [15 x i8] c"i32 (i32, ...)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [23 x i8] c"i32 (i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @sum(i32 noundef %0, ...) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call ptr @__cq_alloc(i64 24, i64 16)
  call void @llvm.va_start.p0(ptr nonnull %3)
  %4 = icmp sgt i32 %0, 0
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %4, label %6, label %15

6:                                                ; preds = %1
  %7 = ptrtoint ptr %3 to i64
  %8 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 %7)
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  %10 = getelementptr inbounds i8, ptr %3, i64 16
  %11 = ptrtoint ptr %10 to i64
  %12 = call i32 @cqrt_qram_load_i64_hl(i32 %2, i64 %11)
  %13 = ptrtoint ptr %9 to i64
  %14 = call i32 @cqrt_qram_load_i64_hl(i32 %2, i64 %13)
  br label %23

15:                                               ; preds = %49, %1
  %16 = phi i64 [ %13, %49 ], [ poison, %1 ]
  %17 = phi i32 [ %14, %49 ], [ poison, %1 ]
  %18 = phi i64 [ %11, %49 ], [ poison, %1 ]
  %19 = phi i32 [ %12, %49 ], [ poison, %1 ]
  %20 = phi i64 [ %7, %49 ], [ poison, %1 ]
  %21 = phi i32 [ %8, %49 ], [ poison, %1 ]
  %cq.run12 = phi i1 [ true, %49 ], [ false, %1 ]
  %cq.run8 = phi i1 [ true, %49 ], [ false, %1 ]
  %cq.run = phi i1 [ true, %49 ], [ false, %1 ]
  %cq.run4 = phi i1 [ false, %1 ], [ true, %49 ]
  %22 = phi i32 [ %5, %1 ], [ %42, %49 ]
  br i1 %cq.run4, label %.cq.arm22, label %.cq.after21

.cq.arm22:                                        ; preds = %15
  call void @cqrt_free(i32 %5)
  br label %.cq.after21

.cq.after21:                                      ; preds = %15, %.cq.arm22
  br i1 %cq.run, label %.cq.arm20, label %.cq.after19

.cq.arm20:                                        ; preds = %.cq.after21
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %2, i64 %16)
  br label %.cq.after19

.cq.after19:                                      ; preds = %.cq.after21, %.cq.arm20
  br i1 %cq.run8, label %.cq.arm18, label %.cq.after17

.cq.arm18:                                        ; preds = %.cq.after19
  call void @cqrt_qram_load_i64_hl_unc(i32 %19, i32 %2, i64 %18)
  br label %.cq.after17

.cq.after17:                                      ; preds = %.cq.after19, %.cq.arm18
  br i1 %cq.run12, label %.cq.arm16, label %.cq.after

.cq.arm16:                                        ; preds = %.cq.after17
  call void @cqrt_qram_load_i32_hl_unc(i32 %21, i32 %2, i64 %20)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after17, %.cq.arm16
  call void @llvm.va_end.p0(ptr %3)
  ret i32 %22

23:                                               ; preds = %6
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  br label %26

25:                                               ; preds = %48
  br label %50

26:                                               ; preds = %48, %23
  %from = phi i32 [ 0, %48 ], [ 1, %23 ]
  %27 = phi i32 [ %14, %23 ], [ %38, %48 ]
  %28 = phi i32 [ 0, %23 ], [ %44, %48 ]
  %29 = phi i32 [ %24, %23 ], [ %42, %48 ]
  %30 = phi i32 [ %8, %23 ], [ %39, %48 ]
  %nfirst = phi i1 [ false, %23 ], [ true, %48 ]
  %31 = call i32 @cq_template_icmp_ult_i32_hl(i32 %30, i32 41)
  %32 = call i32 @cq_template_add_i64_hl(i32 %27, i64 8)
  %33 = ptrtoint ptr %9 to i64
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %31, i32 %2, i64 %33, i32 %32)
  call void @cqrt_not_i1(i32 %31)
  %34 = call i32 @cq_template_zext_i32_to_i64(i32 %30)
  %35 = call i32 @cq_template_add_i64(i32 %12, i32 %34)
  %36 = call i32 @cq_template_add_i32_hl(i32 %30, i32 8)
  %37 = ptrtoint ptr %3 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %31, i32 %2, i64 %37, i32 %36)
  %38 = call i32 @cq_template_select_i64(i32 %31, i32 %27, i32 %32)
  %39 = call i32 @cq_template_select_i32(i32 %31, i32 %36, i32 %30)
  %40 = call i32 @cq_template_select_i64(i32 %31, i32 %35, i32 %27)
  %41 = call i32 @cqrt_qram_load_i32(i32 %2, i32 %40)
  %42 = call i32 @cq_template_add_i32(i32 %41, i32 %29)
  %43 = call i32 @cq_template_sub_i32(i32 %42, i32 %41)
  call void @cqrt_copy_i32(i32 %43, i32 %29)
  call void @cq_template_sub_i32_unc(i32 %43, i32 %42, i32 %41)
  call void @cqrt_free(i32 %43)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_i32_unc(i32 %41, i32 %2, i32 %40)
  call void @cqrt_free(i32 %41)
  call void @cq_template_select_i64_unc(i32 %40, i32 %31, i32 %35, i32 %27)
  call void @cqrt_free(i32 %40)
  call void @cq_template_add_i64_unc(i32 %35, i32 %12, i32 %34)
  call void @cqrt_free(i32 %35)
  call void @cq_template_zext_i32_to_i64_unc(i32 %34, i32 %30)
  call void @cqrt_free(i32 %34)
  %44 = add nuw nsw i32 %28, 1
  %45 = icmp eq i32 %44, %0
  %46 = call i32 @cq_template_sub_i64_hl(i32 %38, i64 8)
  %cq.r6.plain = xor i1 %nfirst, true
  br i1 %nfirst, label %.cq.arm, label %48

.cq.arm:                                          ; preds = %26
  %47 = call i32 @cq_template_select_i64(i32 %31, i32 %38, i32 %46)
  call void @cqrt_copy_i64(i32 %47, i32 %27)
  call void @cq_template_select_i64_unc(i32 %47, i32 %31, i32 %38, i32 %46)
  call void @cqrt_free(i32 %47)
  call void @cqrt_free(i32 %27)
  br label %48

48:                                               ; preds = %.cq.arm, %26
  call void @cqrt_push(i32 %from)
  call void @cq_template_sub_i64_hl_unc(i32 %46, i32 %38, i64 8)
  call void @cqrt_free(i32 %46)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %30)
  br i1 %45, label %25, label %26

49:                                               ; preds = %50
  br label %15

50:                                               ; preds = %25, %50
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %54, i32 %53, i32 %52, i32 %51)
  call void @cqrt_free(i32 %54)
  %55 = call i32 @cqrt_pop()
  switch i32 %55, label %50 [
    i32 1, label %49
  ]
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #3 {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %5, double %2)
  %6 = call ptr @__cq_alloc(i64 16, i64 16)
  %7 = ptrtoint ptr %6 to i64
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %7, i32 %5)
  %8 = add i64 %7, 8
  %9 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %8, i32 %9)
  %10 = call i32 @__cq_q_sum_00(i32 4, ptr %6)
  %11 = call i32 @cqrt_measure_i32(i32 %10), !cq.measure !6
  ret i32 %11
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_not_i1(i32)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_add_i64(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_sub_i64_hl(i32, i64)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_qram_load_i32_unc(i32, i32, i32)

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_sum_10_t(i32 %0, ptr %1, i32 %2) {
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 24, i64 16)
  %6 = ptrtoint ptr %5 to i64
  %7 = ptrtoint ptr %1 to i64
  %8 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %8)
  %9 = add i64 %6, 4
  %10 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %10)
  %11 = add i64 %6, 8
  %12 = call i32 @cqrt_alloc_i64(i64 %7)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %11, i32 %12)
  %13 = add i64 %6, 16
  %14 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %13, i32 %14)
  %15 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 0)
  %16 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %15, i32 %4, i64 %6)
  %17 = getelementptr inbounds i8, ptr %5, i64 8
  %18 = getelementptr inbounds i8, ptr %5, i64 16
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %15, i32 %4, i64 %19)
  %21 = ptrtoint ptr %17 to i64
  %22 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %15, i32 %4, i64 %21)
  br label %23

23:                                               ; preds = %3
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  %25 = call i32 @cq_template_icmp_ult_i32_hl(i32 %16, i32 41)
  %26 = call i32 @cq_template_add_i64_hl(i32 %22, i64 8)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %25, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %27, i32 %28)
  call void @cqrt_xor_i1(i32 %25, i32 %27)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_free(i32 %27)
  %29 = ptrtoint ptr %17 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %28, i32 %4, i64 %29, i32 %26)
  %30 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  %31 = call i32 @cq_template_add_i64(i32 %20, i32 %30)
  %32 = call i32 @cq_template_add_i32_hl(i32 %16, i32 8)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %25, i32 %33)
  %34 = ptrtoint ptr %5 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %33, i32 %4, i64 %34, i32 %32)
  %35 = call i32 @cq_template_select_i64(i32 %25, i32 %22, i32 %26)
  %36 = call i32 @cq_template_select_i32(i32 %25, i32 %32, i32 %16)
  %37 = call i32 @cq_template_select_i64(i32 %25, i32 %31, i32 %22)
  %38 = call i32 @cqrt_qram_load_i32_controlled(i32 %15, i32 %4, i32 %37)
  %39 = call i32 @cq_template_add_i32(i32 %38, i32 %24)
  %40 = add i32 0, 1
  %41 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %40)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_xor_i1(i32 %41, i32 %42)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %42, i32 %43)
  %44 = call i32 @cq_template_select_i64(i32 %15, i32 %35, i32 %22)
  %45 = call i32 @cq_template_select_i32(i32 %15, i32 %39, i32 %24)
  call void @cq_template_add_i32_unc(i32 %39, i32 %38, i32 %24)
  call void @cqrt_free(i32 %39)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %38, i32 %15, i32 %4, i32 %37)
  call void @cqrt_free(i32 %38)
  call void @cq_template_select_i64_unc(i32 %37, i32 %25, i32 %31, i32 %22)
  call void @cqrt_free(i32 %37)
  call void @cq_template_add_i64_unc(i32 %31, i32 %20, i32 %30)
  call void @cqrt_free(i32 %31)
  call void @cq_template_zext_i32_to_i64_unc(i32 %30, i32 %16)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %24)
  %46 = call i32 @cq_template_select_i32(i32 %15, i32 %36, i32 %16)
  %47 = call i32 @cq_template_icmp_ult_i32_hl(i32 %46, i32 41)
  %48 = call i32 @cq_template_add_i64_hl(i32 %44, i64 8)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_xor_i1(i32 %47, i32 %49)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %49, i32 %50)
  call void @cqrt_xor_i1(i32 %47, i32 %49)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_free(i32 %49)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %50, i32 %4, i64 %29, i32 %48)
  %51 = call i32 @cq_template_zext_i32_to_i64(i32 %46)
  %52 = call i32 @cq_template_add_i64(i32 %20, i32 %51)
  %53 = call i32 @cq_template_add_i32_hl(i32 %46, i32 8)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %47, i32 %54)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %54, i32 %4, i64 %34, i32 %53)
  %55 = call i32 @cq_template_select_i64(i32 %47, i32 %44, i32 %48)
  %56 = call i32 @cq_template_select_i32(i32 %47, i32 %53, i32 %46)
  %57 = call i32 @cq_template_select_i64(i32 %47, i32 %52, i32 %44)
  %58 = call i32 @cqrt_qram_load_i32_controlled(i32 %43, i32 %4, i32 %57)
  %59 = call i32 @cq_template_add_i32(i32 %58, i32 %45)
  %60 = add i32 %40, 1
  %61 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %60)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_xor_i1(i32 %61, i32 %62)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %62, i32 %63)
  %64 = call i32 @cq_template_select_i64(i32 %43, i32 %55, i32 %44)
  %65 = call i32 @cq_template_select_i32(i32 %43, i32 %59, i32 %45)
  call void @cq_template_add_i32_unc(i32 %59, i32 %58, i32 %45)
  call void @cqrt_free(i32 %59)
  %66 = call i32 @cq_template_sub_i32(i32 %65, i32 %58)
  %67 = call i32 @cq_template_select_i32(i32 %43, i32 %66, i32 %65)
  call void @cqrt_copy_i32(i32 %67, i32 %45)
  call void @cq_template_select_i32_unc(i32 %67, i32 %43, i32 %66, i32 %65)
  call void @cqrt_free(i32 %67)
  call void @cqrt_free(i32 %45)
  call void @cq_template_sub_i32_unc(i32 %66, i32 %65, i32 %58)
  call void @cqrt_free(i32 %66)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %58, i32 %43, i32 %4, i32 %57)
  call void @cqrt_free(i32 %58)
  call void @cq_template_select_i64_unc(i32 %57, i32 %47, i32 %52, i32 %44)
  call void @cqrt_free(i32 %57)
  call void @cq_template_add_i64_unc(i32 %52, i32 %20, i32 %51)
  call void @cqrt_free(i32 %52)
  call void @cq_template_zext_i32_to_i64_unc(i32 %51, i32 %46)
  call void @cqrt_free(i32 %51)
  %68 = call i32 @cq_template_select_i32(i32 %43, i32 %56, i32 %46)
  %69 = call i32 @cq_template_icmp_ult_i32_hl(i32 %68, i32 41)
  %70 = call i32 @cq_template_add_i64_hl(i32 %64, i64 8)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %71)
  call void @cqrt_xor_i1(i32 %69, i32 %71)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %63, i32 %71, i32 %72)
  call void @cqrt_xor_i1(i32 %69, i32 %71)
  call void @cqrt_not_i1(i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %72, i32 %4, i64 %29, i32 %70)
  %73 = call i32 @cq_template_zext_i32_to_i64(i32 %68)
  %74 = call i32 @cq_template_add_i64(i32 %20, i32 %73)
  %75 = call i32 @cq_template_add_i32_hl(i32 %68, i32 8)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %63, i32 %69, i32 %76)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %76, i32 %4, i64 %34, i32 %75)
  %77 = call i32 @cq_template_select_i64(i32 %69, i32 %64, i32 %70)
  %78 = call i32 @cq_template_select_i32(i32 %69, i32 %75, i32 %68)
  %79 = call i32 @cq_template_select_i64(i32 %69, i32 %74, i32 %64)
  %80 = call i32 @cqrt_qram_load_i32_controlled(i32 %63, i32 %4, i32 %79)
  %81 = call i32 @cq_template_add_i32(i32 %80, i32 %65)
  %82 = add i32 %60, 1
  %83 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %82)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %84)
  call void @cqrt_xor_i1(i32 %83, i32 %84)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %63, i32 %84, i32 %85)
  %86 = call i32 @cq_template_select_i64(i32 %63, i32 %77, i32 %64)
  %87 = call i32 @cq_template_select_i32(i32 %63, i32 %81, i32 %65)
  call void @cq_template_add_i32_unc(i32 %81, i32 %80, i32 %65)
  call void @cqrt_free(i32 %81)
  %88 = call i32 @cq_template_sub_i32(i32 %87, i32 %80)
  %89 = call i32 @cq_template_select_i32(i32 %63, i32 %88, i32 %87)
  call void @cqrt_copy_i32(i32 %89, i32 %65)
  call void @cq_template_select_i32_unc(i32 %89, i32 %63, i32 %88, i32 %87)
  call void @cqrt_free(i32 %89)
  call void @cqrt_free(i32 %65)
  call void @cq_template_sub_i32_unc(i32 %88, i32 %87, i32 %80)
  call void @cqrt_free(i32 %88)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %80, i32 %63, i32 %4, i32 %79)
  call void @cqrt_free(i32 %80)
  call void @cq_template_select_i64_unc(i32 %79, i32 %69, i32 %74, i32 %64)
  call void @cqrt_free(i32 %79)
  call void @cq_template_add_i64_unc(i32 %74, i32 %20, i32 %73)
  call void @cqrt_free(i32 %74)
  call void @cq_template_zext_i32_to_i64_unc(i32 %73, i32 %68)
  call void @cqrt_free(i32 %73)
  %90 = call i32 @cq_template_select_i32(i32 %63, i32 %78, i32 %68)
  %91 = call i32 @cq_template_icmp_ult_i32_hl(i32 %90, i32 41)
  %92 = call i32 @cq_template_add_i64_hl(i32 %86, i64 8)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_xor_i1(i32 %91, i32 %93)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %93, i32 %94)
  call void @cqrt_xor_i1(i32 %91, i32 %93)
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %94, i32 %4, i64 %29, i32 %92)
  %95 = call i32 @cq_template_zext_i32_to_i64(i32 %90)
  %96 = call i32 @cq_template_add_i64(i32 %20, i32 %95)
  %97 = call i32 @cq_template_add_i32_hl(i32 %90, i32 8)
  %98 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %91, i32 %98)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %98, i32 %4, i64 %34, i32 %97)
  %99 = call i32 @cq_template_select_i64(i32 %91, i32 %86, i32 %92)
  %100 = call i32 @cq_template_select_i32(i32 %91, i32 %97, i32 %90)
  %101 = call i32 @cq_template_select_i64(i32 %91, i32 %96, i32 %86)
  %102 = call i32 @cqrt_qram_load_i32_controlled(i32 %85, i32 %4, i32 %101)
  %103 = call i32 @cq_template_add_i32(i32 %102, i32 %87)
  %104 = add i32 %82, 1
  %105 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 %104)
  %106 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %106)
  call void @cqrt_xor_i1(i32 %105, i32 %106)
  %107 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %85, i32 %106, i32 %107)
  call void @cqrt_xor_i1(i32 %105, i32 %106)
  call void @cqrt_not_i1(i32 %106)
  call void @cqrt_free(i32 %106)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %105, i32 %0, i32 %104)
  call void @cqrt_free(i32 %105)
  %108 = call i32 @cq_template_select_i64(i32 %85, i32 %99, i32 %86)
  call void @cq_template_select_i64_unc(i32 %108, i32 %85, i32 %99, i32 %86)
  call void @cqrt_free(i32 %108)
  call void @cq_template_select_i64_unc(i32 %99, i32 %91, i32 %86, i32 %92)
  call void @cqrt_free(i32 %99)
  %109 = call i32 @cq_template_select_i32(i32 %85, i32 %103, i32 %87)
  call void @cq_template_add_i32_unc(i32 %103, i32 %102, i32 %87)
  call void @cqrt_free(i32 %103)
  %110 = call i32 @cq_template_sub_i32(i32 %109, i32 %102)
  %111 = call i32 @cq_template_select_i32(i32 %85, i32 %110, i32 %109)
  call void @cqrt_copy_i32(i32 %111, i32 %87)
  call void @cq_template_select_i32_unc(i32 %111, i32 %85, i32 %110, i32 %109)
  call void @cqrt_free(i32 %111)
  call void @cqrt_free(i32 %87)
  call void @cq_template_sub_i32_unc(i32 %110, i32 %109, i32 %102)
  call void @cqrt_free(i32 %110)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %102, i32 %85, i32 %4, i32 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_select_i64_unc(i32 %101, i32 %91, i32 %96, i32 %86)
  call void @cqrt_free(i32 %101)
  call void @cq_template_add_i64_unc(i32 %96, i32 %20, i32 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_zext_i32_to_i64_unc(i32 %95, i32 %90)
  call void @cqrt_free(i32 %95)
  call void @cq_template_select_i64_unc(i32 %86, i32 %63, i32 %77, i32 %64)
  call void @cqrt_free(i32 %86)
  call void @cq_template_select_i64_unc(i32 %77, i32 %69, i32 %64, i32 %70)
  call void @cqrt_free(i32 %77)
  call void @cq_template_select_i64_unc(i32 %64, i32 %43, i32 %55, i32 %44)
  call void @cqrt_free(i32 %64)
  call void @cq_template_select_i64_unc(i32 %55, i32 %47, i32 %44, i32 %48)
  call void @cqrt_free(i32 %55)
  call void @cq_template_select_i64_unc(i32 %44, i32 %15, i32 %35, i32 %22)
  call void @cqrt_free(i32 %44)
  call void @cq_template_select_i64_unc(i32 %35, i32 %25, i32 %22, i32 %26)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %22, i32 %15, i32 %4, i64 %21)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %15, i32 %4, i64 %19)
  %112 = call i32 @cq_template_select_i32(i32 %85, i32 %100, i32 %90)
  call void @cq_template_select_i32_unc(i32 %112, i32 %85, i32 %100, i32 %90)
  call void @cqrt_free(i32 %112)
  call void @cq_template_select_i32_unc(i32 %100, i32 %91, i32 %97, i32 %90)
  call void @cqrt_free(i32 %100)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %91, i32 %90, i32 41)
  call void @cqrt_free(i32 %91)
  call void @cq_template_select_i32_unc(i32 %90, i32 %63, i32 %78, i32 %68)
  call void @cqrt_free(i32 %90)
  call void @cqrt_and_i1(i32 %63, i32 %84, i32 %85)
  call void @cqrt_free(i32 %85)
  call void @cqrt_xor_i1(i32 %83, i32 %84)
  call void @cqrt_not_i1(i32 %84)
  call void @cqrt_free(i32 %84)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %83, i32 %0, i32 %82)
  call void @cqrt_free(i32 %83)
  call void @cq_template_select_i32_unc(i32 %78, i32 %69, i32 %75, i32 %68)
  call void @cqrt_free(i32 %78)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %69, i32 %68, i32 41)
  call void @cqrt_free(i32 %69)
  call void @cq_template_select_i32_unc(i32 %68, i32 %43, i32 %56, i32 %46)
  call void @cqrt_free(i32 %68)
  call void @cqrt_and_i1(i32 %43, i32 %62, i32 %63)
  call void @cqrt_free(i32 %63)
  call void @cqrt_xor_i1(i32 %61, i32 %62)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_free(i32 %62)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %61, i32 %0, i32 %60)
  call void @cqrt_free(i32 %61)
  call void @cq_template_select_i32_unc(i32 %56, i32 %47, i32 %53, i32 %46)
  call void @cqrt_free(i32 %56)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %47, i32 %46, i32 41)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i32_unc(i32 %46, i32 %15, i32 %36, i32 %16)
  call void @cqrt_free(i32 %46)
  call void @cqrt_and_i1(i32 %15, i32 %42, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cqrt_xor_i1(i32 %41, i32 %42)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %41, i32 %0, i32 %40)
  call void @cqrt_free(i32 %41)
  call void @cq_template_select_i32_unc(i32 %36, i32 %25, i32 %32, i32 %16)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %25, i32 %16, i32 41)
  call void @cqrt_free(i32 %25)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %16, i32 %15, i32 %4, i64 %6)
  %113 = call i32 @cq_template_select_i32_hl(i32 %15, i32 %109, i32 0)
  %114 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %113, i32 %114)
  call void @cq_template_select_i32_hl_unc(i32 %113, i32 %15, i32 %109, i32 0)
  call void @cqrt_free(i32 %113)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %15, i32 %0, i32 0)
  call void @cqrt_free(i32 %15)
  ret i32 %114
}

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_sum_10_t_ctl(i32 %0, i32 %1, ptr %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_sum, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_sum, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %126

8:                                                ; preds = %4
  %9 = call i32 @__cq_mem()
  %10 = call ptr @__cq_alloc(i64 24, i64 16)
  %11 = ptrtoint ptr %10 to i64
  %12 = ptrtoint ptr %2 to i64
  %13 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %11, i32 %13)
  %14 = add i64 %11, 4
  %15 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %9, i64 %14, i32 %15)
  %16 = add i64 %11, 8
  %17 = call i32 @cqrt_alloc_i64(i64 %12)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %16, i32 %17)
  %18 = add i64 %11, 16
  %19 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %9, i64 %18, i32 %19)
  %20 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %21)
  %22 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %21, i32 %9, i64 %11)
  %23 = getelementptr inbounds i8, ptr %10, i64 8
  %24 = getelementptr inbounds i8, ptr %10, i64 16
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %26)
  %27 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %26, i32 %9, i64 %25)
  %28 = ptrtoint ptr %23 to i64
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %29)
  %30 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %29, i32 %9, i64 %28)
  br label %31

31:                                               ; preds = %8
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %32)
  %33 = call i32 @cqrt_alloc_i32(i32 0)
  %34 = call i32 @cq_template_icmp_ult_i32_hl(i32 %22, i32 41)
  %35 = call i32 @cq_template_add_i64_hl(i32 %30, i64 8)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_xor_i1(i32 %34, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %36, i32 %37)
  call void @cqrt_xor_i1(i32 %34, i32 %36)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_free(i32 %36)
  %38 = ptrtoint ptr %23 to i64
  call void @cqrt_qram_store_i64_hl_controlled(i32 %37, i32 %9, i64 %38, i32 %35)
  %39 = call i32 @cq_template_zext_i32_to_i64(i32 %22)
  %40 = call i32 @cq_template_add_i64(i32 %27, i32 %39)
  %41 = call i32 @cq_template_add_i32_hl(i32 %22, i32 8)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %34, i32 %42)
  %43 = ptrtoint ptr %10 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %42, i32 %9, i64 %43, i32 %41)
  %44 = call i32 @cq_template_select_i64(i32 %34, i32 %30, i32 %35)
  %45 = call i32 @cq_template_select_i32(i32 %34, i32 %41, i32 %22)
  %46 = call i32 @cq_template_select_i64(i32 %34, i32 %40, i32 %30)
  %47 = call i32 @cqrt_qram_load_i32_controlled(i32 %32, i32 %9, i32 %46)
  %48 = call i32 @cq_template_add_i32(i32 %47, i32 %33)
  %49 = add i32 0, 1
  %50 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %49)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_xor_i1(i32 %50, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i64(i32 %32, i32 %44, i32 %30)
  %54 = call i32 @cq_template_select_i32(i32 %32, i32 %48, i32 %33)
  call void @cq_template_add_i32_unc(i32 %48, i32 %47, i32 %33)
  call void @cqrt_free(i32 %48)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %47, i32 %32, i32 %9, i32 %46)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i64_unc(i32 %46, i32 %34, i32 %40, i32 %30)
  call void @cqrt_free(i32 %46)
  call void @cq_template_add_i64_unc(i32 %40, i32 %27, i32 %39)
  call void @cqrt_free(i32 %40)
  call void @cq_template_zext_i32_to_i64_unc(i32 %39, i32 %22)
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %33)
  %55 = call i32 @cq_template_select_i32(i32 %32, i32 %45, i32 %22)
  %56 = call i32 @cq_template_icmp_ult_i32_hl(i32 %55, i32 41)
  %57 = call i32 @cq_template_add_i64_hl(i32 %53, i64 8)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %58)
  call void @cqrt_xor_i1(i32 %56, i32 %58)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %52, i32 %58, i32 %59)
  call void @cqrt_xor_i1(i32 %56, i32 %58)
  call void @cqrt_not_i1(i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %59, i32 %9, i64 %38, i32 %57)
  %60 = call i32 @cq_template_zext_i32_to_i64(i32 %55)
  %61 = call i32 @cq_template_add_i64(i32 %27, i32 %60)
  %62 = call i32 @cq_template_add_i32_hl(i32 %55, i32 8)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %52, i32 %56, i32 %63)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %63, i32 %9, i64 %43, i32 %62)
  %64 = call i32 @cq_template_select_i64(i32 %56, i32 %53, i32 %57)
  %65 = call i32 @cq_template_select_i32(i32 %56, i32 %62, i32 %55)
  %66 = call i32 @cq_template_select_i64(i32 %56, i32 %61, i32 %53)
  %67 = call i32 @cqrt_qram_load_i32_controlled(i32 %52, i32 %9, i32 %66)
  %68 = call i32 @cq_template_add_i32(i32 %67, i32 %54)
  %69 = add i32 %49, 1
  %70 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %69)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %71)
  call void @cqrt_xor_i1(i32 %70, i32 %71)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %52, i32 %71, i32 %72)
  %73 = call i32 @cq_template_select_i64(i32 %52, i32 %64, i32 %53)
  %74 = call i32 @cq_template_select_i32(i32 %52, i32 %68, i32 %54)
  call void @cq_template_add_i32_unc(i32 %68, i32 %67, i32 %54)
  call void @cqrt_free(i32 %68)
  %75 = call i32 @cq_template_sub_i32(i32 %74, i32 %67)
  %76 = call i32 @cq_template_select_i32(i32 %52, i32 %75, i32 %74)
  call void @cqrt_copy_i32(i32 %76, i32 %54)
  call void @cq_template_select_i32_unc(i32 %76, i32 %52, i32 %75, i32 %74)
  call void @cqrt_free(i32 %76)
  call void @cqrt_free(i32 %54)
  call void @cq_template_sub_i32_unc(i32 %75, i32 %74, i32 %67)
  call void @cqrt_free(i32 %75)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %67, i32 %52, i32 %9, i32 %66)
  call void @cqrt_free(i32 %67)
  call void @cq_template_select_i64_unc(i32 %66, i32 %56, i32 %61, i32 %53)
  call void @cqrt_free(i32 %66)
  call void @cq_template_add_i64_unc(i32 %61, i32 %27, i32 %60)
  call void @cqrt_free(i32 %61)
  call void @cq_template_zext_i32_to_i64_unc(i32 %60, i32 %55)
  call void @cqrt_free(i32 %60)
  %77 = call i32 @cq_template_select_i32(i32 %52, i32 %65, i32 %55)
  %78 = call i32 @cq_template_icmp_ult_i32_hl(i32 %77, i32 41)
  %79 = call i32 @cq_template_add_i64_hl(i32 %73, i64 8)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %80)
  call void @cqrt_xor_i1(i32 %78, i32 %80)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %80, i32 %81)
  call void @cqrt_xor_i1(i32 %78, i32 %80)
  call void @cqrt_not_i1(i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %81, i32 %9, i64 %38, i32 %79)
  %82 = call i32 @cq_template_zext_i32_to_i64(i32 %77)
  %83 = call i32 @cq_template_add_i64(i32 %27, i32 %82)
  %84 = call i32 @cq_template_add_i32_hl(i32 %77, i32 8)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %78, i32 %85)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %85, i32 %9, i64 %43, i32 %84)
  %86 = call i32 @cq_template_select_i64(i32 %78, i32 %73, i32 %79)
  %87 = call i32 @cq_template_select_i32(i32 %78, i32 %84, i32 %77)
  %88 = call i32 @cq_template_select_i64(i32 %78, i32 %83, i32 %73)
  %89 = call i32 @cqrt_qram_load_i32_controlled(i32 %72, i32 %9, i32 %88)
  %90 = call i32 @cq_template_add_i32(i32 %89, i32 %74)
  %91 = add i32 %69, 1
  %92 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %91)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_xor_i1(i32 %92, i32 %93)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %72, i32 %93, i32 %94)
  %95 = call i32 @cq_template_select_i64(i32 %72, i32 %86, i32 %73)
  %96 = call i32 @cq_template_select_i32(i32 %72, i32 %90, i32 %74)
  call void @cq_template_add_i32_unc(i32 %90, i32 %89, i32 %74)
  call void @cqrt_free(i32 %90)
  %97 = call i32 @cq_template_sub_i32(i32 %96, i32 %89)
  %98 = call i32 @cq_template_select_i32(i32 %72, i32 %97, i32 %96)
  call void @cqrt_copy_i32(i32 %98, i32 %74)
  call void @cq_template_select_i32_unc(i32 %98, i32 %72, i32 %97, i32 %96)
  call void @cqrt_free(i32 %98)
  call void @cqrt_free(i32 %74)
  call void @cq_template_sub_i32_unc(i32 %97, i32 %96, i32 %89)
  call void @cqrt_free(i32 %97)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %89, i32 %72, i32 %9, i32 %88)
  call void @cqrt_free(i32 %89)
  call void @cq_template_select_i64_unc(i32 %88, i32 %78, i32 %83, i32 %73)
  call void @cqrt_free(i32 %88)
  call void @cq_template_add_i64_unc(i32 %83, i32 %27, i32 %82)
  call void @cqrt_free(i32 %83)
  call void @cq_template_zext_i32_to_i64_unc(i32 %82, i32 %77)
  call void @cqrt_free(i32 %82)
  %99 = call i32 @cq_template_select_i32(i32 %72, i32 %87, i32 %77)
  %100 = call i32 @cq_template_icmp_ult_i32_hl(i32 %99, i32 41)
  %101 = call i32 @cq_template_add_i64_hl(i32 %95, i64 8)
  %102 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %102)
  call void @cqrt_xor_i1(i32 %100, i32 %102)
  %103 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %102, i32 %103)
  call void @cqrt_xor_i1(i32 %100, i32 %102)
  call void @cqrt_not_i1(i32 %102)
  call void @cqrt_free(i32 %102)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %103, i32 %9, i64 %38, i32 %101)
  %104 = call i32 @cq_template_zext_i32_to_i64(i32 %99)
  %105 = call i32 @cq_template_add_i64(i32 %27, i32 %104)
  %106 = call i32 @cq_template_add_i32_hl(i32 %99, i32 8)
  %107 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %100, i32 %107)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %107, i32 %9, i64 %43, i32 %106)
  %108 = call i32 @cq_template_select_i64(i32 %100, i32 %95, i32 %101)
  %109 = call i32 @cq_template_select_i32(i32 %100, i32 %106, i32 %99)
  %110 = call i32 @cq_template_select_i64(i32 %100, i32 %105, i32 %95)
  %111 = call i32 @cqrt_qram_load_i32_controlled(i32 %94, i32 %9, i32 %110)
  %112 = call i32 @cq_template_add_i32(i32 %111, i32 %96)
  %113 = add i32 %91, 1
  %114 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %113)
  %115 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %115)
  call void @cqrt_xor_i1(i32 %114, i32 %115)
  %116 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %94, i32 %115, i32 %116)
  call void @cqrt_xor_i1(i32 %114, i32 %115)
  call void @cqrt_not_i1(i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %114, i32 %1, i32 %113)
  call void @cqrt_free(i32 %114)
  %117 = call i32 @cq_template_select_i64(i32 %94, i32 %108, i32 %95)
  call void @cq_template_select_i64_unc(i32 %117, i32 %94, i32 %108, i32 %95)
  call void @cqrt_free(i32 %117)
  call void @cq_template_select_i64_unc(i32 %108, i32 %100, i32 %95, i32 %101)
  call void @cqrt_free(i32 %108)
  %118 = call i32 @cq_template_select_i32(i32 %94, i32 %112, i32 %96)
  call void @cq_template_add_i32_unc(i32 %112, i32 %111, i32 %96)
  call void @cqrt_free(i32 %112)
  %119 = call i32 @cq_template_sub_i32(i32 %118, i32 %111)
  %120 = call i32 @cq_template_select_i32(i32 %94, i32 %119, i32 %118)
  call void @cqrt_copy_i32(i32 %120, i32 %96)
  call void @cq_template_select_i32_unc(i32 %120, i32 %94, i32 %119, i32 %118)
  call void @cqrt_free(i32 %120)
  call void @cqrt_free(i32 %96)
  call void @cq_template_sub_i32_unc(i32 %119, i32 %118, i32 %111)
  call void @cqrt_free(i32 %119)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %111, i32 %94, i32 %9, i32 %110)
  call void @cqrt_free(i32 %111)
  call void @cq_template_select_i64_unc(i32 %110, i32 %100, i32 %105, i32 %95)
  call void @cqrt_free(i32 %110)
  call void @cq_template_add_i64_unc(i32 %105, i32 %27, i32 %104)
  call void @cqrt_free(i32 %105)
  call void @cq_template_zext_i32_to_i64_unc(i32 %104, i32 %99)
  call void @cqrt_free(i32 %104)
  call void @cq_template_select_i64_unc(i32 %95, i32 %72, i32 %86, i32 %73)
  call void @cqrt_free(i32 %95)
  call void @cq_template_select_i64_unc(i32 %86, i32 %78, i32 %73, i32 %79)
  call void @cqrt_free(i32 %86)
  call void @cq_template_select_i64_unc(i32 %73, i32 %52, i32 %64, i32 %53)
  call void @cqrt_free(i32 %73)
  call void @cq_template_select_i64_unc(i32 %64, i32 %56, i32 %53, i32 %57)
  call void @cqrt_free(i32 %64)
  call void @cq_template_select_i64_unc(i32 %53, i32 %32, i32 %44, i32 %30)
  call void @cqrt_free(i32 %53)
  call void @cq_template_select_i64_unc(i32 %44, i32 %34, i32 %30, i32 %35)
  call void @cqrt_free(i32 %44)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %30, i32 %29, i32 %9, i64 %28)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %27, i32 %26, i32 %9, i64 %25)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %26)
  call void @cqrt_free(i32 %26)
  %121 = call i32 @cq_template_select_i32(i32 %94, i32 %109, i32 %99)
  call void @cq_template_select_i32_unc(i32 %121, i32 %94, i32 %109, i32 %99)
  call void @cqrt_free(i32 %121)
  call void @cq_template_select_i32_unc(i32 %109, i32 %100, i32 %106, i32 %99)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %100, i32 %99, i32 41)
  call void @cqrt_free(i32 %100)
  call void @cq_template_select_i32_unc(i32 %99, i32 %72, i32 %87, i32 %77)
  call void @cqrt_free(i32 %99)
  call void @cqrt_and_i1(i32 %72, i32 %93, i32 %94)
  call void @cqrt_free(i32 %94)
  call void @cqrt_xor_i1(i32 %92, i32 %93)
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %92, i32 %1, i32 %91)
  call void @cqrt_free(i32 %92)
  call void @cq_template_select_i32_unc(i32 %87, i32 %78, i32 %84, i32 %77)
  call void @cqrt_free(i32 %87)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %78, i32 %77, i32 41)
  call void @cqrt_free(i32 %78)
  call void @cq_template_select_i32_unc(i32 %77, i32 %52, i32 %65, i32 %55)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %52, i32 %71, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cqrt_xor_i1(i32 %70, i32 %71)
  call void @cqrt_not_i1(i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %70, i32 %1, i32 %69)
  call void @cqrt_free(i32 %70)
  call void @cq_template_select_i32_unc(i32 %65, i32 %56, i32 %62, i32 %55)
  call void @cqrt_free(i32 %65)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %56, i32 %55, i32 41)
  call void @cqrt_free(i32 %56)
  call void @cq_template_select_i32_unc(i32 %55, i32 %32, i32 %45, i32 %22)
  call void @cqrt_free(i32 %55)
  call void @cqrt_and_i1(i32 %32, i32 %51, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_xor_i1(i32 %50, i32 %51)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %50, i32 %1, i32 %49)
  call void @cqrt_free(i32 %50)
  call void @cq_template_select_i32_unc(i32 %45, i32 %34, i32 %41, i32 %22)
  call void @cqrt_free(i32 %45)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %34, i32 %22, i32 41)
  call void @cqrt_free(i32 %34)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %22, i32 %21, i32 %9, i64 %11)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %21)
  call void @cqrt_free(i32 %21)
  %122 = call i32 @cq_template_select_i32_hl(i32 %20, i32 %118, i32 0)
  %123 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %122, i32 %123)
  call void @cq_template_select_i32_hl_unc(i32 %122, i32 %20, i32 %118, i32 0)
  call void @cqrt_free(i32 %122)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %20, i32 %1, i32 0)
  call void @cqrt_free(i32 %20)
  %124 = load i32, ptr @__cq_act_sum, align 4
  %125 = add i32 %124, -1
  store i32 %125, ptr @__cq_act_sum, align 4
  ret i32 %123

126:                                              ; preds = %4
  %127 = call i32 @cqrt_alloc_i32(i32 0)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %128)
  %129 = load i32, ptr @__cq_act_sum, align 4
  %130 = add i32 %129, -1
  store i32 %130, ptr @__cq_act_sum, align 4
  ret i32 %127
}

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_i32(i32, double)

define i32 @__cq_q_sum_00(i32 %0, ptr %1) local_unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 24, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = ptrtoint ptr %1 to i64
  %7 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %7)
  %8 = add i64 %5, 4
  %9 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)
  %10 = add i64 %5, 8
  %11 = call i32 @cqrt_alloc_i64(i64 %6)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %10, i32 %11)
  %12 = add i64 %5, 16
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %12, i32 %13)
  %14 = icmp sgt i32 %0, 0
  br i1 %14, label %15, label %24

15:                                               ; preds = %2
  %16 = ptrtoint ptr %4 to i64
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %16)
  %18 = getelementptr inbounds i8, ptr %4, i64 8
  %19 = getelementptr inbounds i8, ptr %4, i64 16
  %20 = ptrtoint ptr %19 to i64
  %21 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %20)
  %22 = ptrtoint ptr %18 to i64
  %23 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %22)
  br label %34

24:                                               ; preds = %2
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  br label %26

26:                                               ; preds = %24, %60
  %27 = phi i64 [ poison, %24 ], [ %22, %60 ]
  %28 = phi i32 [ poison, %24 ], [ %23, %60 ]
  %29 = phi i64 [ poison, %24 ], [ %20, %60 ]
  %30 = phi i32 [ poison, %24 ], [ %21, %60 ]
  %31 = phi i64 [ poison, %24 ], [ %16, %60 ]
  %32 = phi i32 [ poison, %24 ], [ %17, %60 ]
  %cq.run8 = phi i1 [ false, %24 ], [ true, %60 ]
  %cq.run4 = phi i1 [ false, %24 ], [ true, %60 ]
  %cq.run = phi i1 [ false, %24 ], [ true, %60 ]
  %33 = phi i32 [ %25, %24 ], [ %61, %60 ]
  br i1 %cq.run, label %.cq.arm16, label %.cq.after15

.cq.arm16:                                        ; preds = %26
  call void @cqrt_qram_load_i64_hl_unc(i32 %28, i32 %3, i64 %27)
  br label %.cq.after15

.cq.after15:                                      ; preds = %26, %.cq.arm16
  br i1 %cq.run4, label %.cq.arm14, label %.cq.after13

.cq.arm14:                                        ; preds = %.cq.after15
  call void @cqrt_qram_load_i64_hl_unc(i32 %30, i32 %3, i64 %29)
  br label %.cq.after13

.cq.after13:                                      ; preds = %.cq.after15, %.cq.arm14
  br i1 %cq.run8, label %.cq.arm12, label %.cq.after

.cq.arm12:                                        ; preds = %.cq.after13
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %3, i64 %31)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after13, %.cq.arm12
  ret i32 %33

34:                                               ; preds = %15
  %35 = call i32 @cqrt_alloc_i32(i32 0)
  br label %37

36:                                               ; preds = %59
  br label %62

37:                                               ; preds = %59, %34
  %from = phi i32 [ 0, %59 ], [ 1, %34 ]
  %38 = phi i32 [ %23, %34 ], [ %49, %59 ]
  %39 = phi i32 [ 0, %34 ], [ %55, %59 ]
  %40 = phi i32 [ %35, %34 ], [ %53, %59 ]
  %41 = phi i32 [ %17, %34 ], [ %50, %59 ]
  %nfirst = phi i1 [ false, %34 ], [ true, %59 ]
  %42 = call i32 @cq_template_icmp_ult_i32_hl(i32 %41, i32 41)
  %43 = call i32 @cq_template_add_i64_hl(i32 %38, i64 8)
  %44 = ptrtoint ptr %18 to i64
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %42, i32 %3, i64 %44, i32 %43)
  call void @cqrt_not_i1(i32 %42)
  %45 = call i32 @cq_template_zext_i32_to_i64(i32 %41)
  %46 = call i32 @cq_template_add_i64(i32 %21, i32 %45)
  %47 = call i32 @cq_template_add_i32_hl(i32 %41, i32 8)
  %48 = ptrtoint ptr %4 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %42, i32 %3, i64 %48, i32 %47)
  %49 = call i32 @cq_template_select_i64(i32 %42, i32 %38, i32 %43)
  %50 = call i32 @cq_template_select_i32(i32 %42, i32 %47, i32 %41)
  %51 = call i32 @cq_template_select_i64(i32 %42, i32 %46, i32 %38)
  %52 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %51)
  %53 = call i32 @cq_template_add_i32(i32 %52, i32 %40)
  %54 = call i32 @cq_template_sub_i32(i32 %53, i32 %52)
  call void @cqrt_copy_i32(i32 %54, i32 %40)
  call void @cq_template_sub_i32_unc(i32 %54, i32 %53, i32 %52)
  call void @cqrt_free(i32 %54)
  call void @cqrt_free(i32 %40)
  call void @cqrt_qram_load_i32_unc(i32 %52, i32 %3, i32 %51)
  call void @cqrt_free(i32 %52)
  call void @cq_template_select_i64_unc(i32 %51, i32 %42, i32 %46, i32 %38)
  call void @cqrt_free(i32 %51)
  call void @cq_template_add_i64_unc(i32 %46, i32 %21, i32 %45)
  call void @cqrt_free(i32 %46)
  call void @cq_template_zext_i32_to_i64_unc(i32 %45, i32 %41)
  call void @cqrt_free(i32 %45)
  %55 = add nuw nsw i32 %39, 1
  %56 = icmp eq i32 %55, %0
  %57 = call i32 @cq_template_sub_i64_hl(i32 %49, i64 8)
  %cq.r6.plain = xor i1 %nfirst, true
  br i1 %nfirst, label %.cq.arm, label %59

.cq.arm:                                          ; preds = %37
  %58 = call i32 @cq_template_select_i64(i32 %42, i32 %49, i32 %57)
  call void @cqrt_copy_i64(i32 %58, i32 %38)
  call void @cq_template_select_i64_unc(i32 %58, i32 %42, i32 %49, i32 %57)
  call void @cqrt_free(i32 %58)
  call void @cqrt_free(i32 %38)
  br label %59

59:                                               ; preds = %.cq.arm, %37
  call void @cqrt_push(i32 %from)
  call void @cq_template_sub_i64_hl_unc(i32 %57, i32 %49, i64 8)
  call void @cqrt_free(i32 %57)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %41)
  br i1 %56, label %36, label %37

60:                                               ; preds = %62
  %61 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %53, i32 %61)
  br label %26

62:                                               ; preds = %36, %62
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %66, i32 %65, i32 %64, i32 %63)
  call void @cqrt_free(i32 %66)
  %67 = call i32 @cqrt_pop()
  switch i32 %67, label %62 [
    i32 1, label %60
  ]
}

declare i32 @cqrt_measure_i32(i32)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %6)
  call void @cqrt_ry_i32_qangle(i32 %6, i32 %2)
  %7 = alloca { i32, ptr }, align 8
  %8 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 0
  store i32 %6, ptr %8, align 4
  %9 = load ptr, ptr %cq.mints, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %7, i32 0, i32 1
  store ptr %9, ptr %10, align 8
  store ptr %7, ptr %cq.mints, align 8
  %11 = call ptr @__cq_alloc(i64 16, i64 16)
  %12 = ptrtoint ptr %11 to i64
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %12, i32 %6)
  %13 = add i64 %12, 8
  %14 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %13, i32 %14)
  %15 = call i32 @__cq_q_sum_00(i32 4, ptr %11)
  %16 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %15, i32 %16)
  %17 = call i32 @cqrt_measure_i32(i32 %16), !cq.measure !6
  %18 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %18)
  %19 = call i32 @cqrt_alloc_i32(i32 %17)
  ret i32 %19
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

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = icmp ult i32 %6, %4
  br i1 %8, label %9, label %26

9:                                                ; preds = %5
  %10 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %11)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %11, i32 %3)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call ptr @__cq_alloc(i64 16, i64 16)
  %17 = ptrtoint ptr %16 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %10, i64 %17, i32 %11)
  %18 = add i64 %17, 8
  %19 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %10, i64 %18, i32 %19)
  %20 = call i32 @__cq_q_sum_00_ctl(i32 %0, i32 4, ptr %16)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %20, i32 %21)
  %22 = call i32 @cqrt_measure_i32(i32 %21), !cq.measure !6
  %23 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %23)
  %24 = load i32, ptr @__cq_act_f, align 4
  %25 = add i32 %24, -1
  store i32 %25, ptr @__cq_act_f, align 4
  ret i32 %21

26:                                               ; preds = %5
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %28)
  call void @cqrt_push(i32 0)
  %29 = load i32, ptr @__cq_act_f, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_f, align 4
  ret i32 %27
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

define i32 @__cq_q_sum_00_ctl(i32 %0, i32 %1, ptr %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_act_sum, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_sum, align 4
  %6 = icmp ult i32 %4, 4
  br i1 %6, label %7, label %87

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 24, i64 16)
  %10 = ptrtoint ptr %9 to i64
  %11 = ptrtoint ptr %2 to i64
  %12 = call i32 @cqrt_alloc_i32(i32 48)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 %10, i32 %12)
  %13 = add i64 %10, 4
  %14 = call i32 @cqrt_alloc_i32(i32 176)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %8, i64 %13, i32 %14)
  %15 = add i64 %10, 8
  %16 = call i32 @cqrt_alloc_i64(i64 %11)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %15, i32 %16)
  %17 = add i64 %10, 16
  %18 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %17, i32 %18)
  %19 = icmp sgt i32 %1, 0
  %20 = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %19, label %21, label %30

21:                                               ; preds = %7
  %22 = ptrtoint ptr %9 to i64
  %23 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %8, i64 %22)
  %24 = getelementptr inbounds i8, ptr %9, i64 8
  %25 = getelementptr inbounds i8, ptr %9, i64 16
  %26 = ptrtoint ptr %25 to i64
  %27 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %8, i64 %26)
  %28 = ptrtoint ptr %24 to i64
  %29 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %8, i64 %28)
  br label %44

30:                                               ; preds = %7, %69
  %31 = phi i64 [ poison, %7 ], [ %28, %69 ]
  %32 = phi i32 [ poison, %7 ], [ %29, %69 ]
  %33 = phi i64 [ poison, %7 ], [ %26, %69 ]
  %34 = phi i32 [ poison, %7 ], [ %27, %69 ]
  %35 = phi i64 [ poison, %7 ], [ %22, %69 ]
  %36 = phi i32 [ poison, %7 ], [ %23, %69 ]
  %cq.run10 = phi i1 [ false, %7 ], [ true, %69 ]
  %cq.run6 = phi i1 [ false, %7 ], [ true, %69 ]
  %cq.run2 = phi i1 [ false, %7 ], [ true, %69 ]
  %37 = phi i32 [ poison, %7 ], [ %45, %69 ]
  %38 = phi i32 [ poison, %7 ], [ %27, %69 ]
  %ran = phi i1 [ false, %7 ], [ true, %69 ]
  %39 = phi i32 [ %20, %7 ], [ %66, %69 ]
  %40 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %39, i32 %40)
  call void @cqrt_free(i32 %20)
  br i1 %ran, label %71, label %86

41:                                               ; preds = %86
  br i1 %cq.run, label %.cq.arm15, label %.cq.after14

.cq.arm15:                                        ; preds = %41
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %32, i32 %0, i32 %8, i64 %31)
  br label %.cq.after14

.cq.after14:                                      ; preds = %41, %.cq.arm15
  br i1 %cq.run4, label %.cq.arm13, label %.cq.after12

.cq.arm13:                                        ; preds = %.cq.after14
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %34, i32 %0, i32 %8, i64 %33)
  br label %.cq.after12

.cq.after12:                                      ; preds = %.cq.after14, %.cq.arm13
  br i1 %cq.run8, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after12
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %36, i32 %0, i32 %8, i64 %35)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after12, %.cq.arm
  %42 = load i32, ptr @__cq_act_sum, align 4
  %43 = add i32 %42, -1
  store i32 %43, ptr @__cq_act_sum, align 4
  ret i32 %40

44:                                               ; preds = %21
  %45 = call i32 @cqrt_alloc_i32(i32 0)
  br label %47

46:                                               ; preds = %47
  br label %69

47:                                               ; preds = %47, %44
  %from = phi i32 [ 0, %47 ], [ 1, %44 ]
  %48 = phi i32 [ %29, %44 ], [ %62, %47 ]
  %49 = phi i32 [ 0, %44 ], [ %67, %47 ]
  %50 = phi i32 [ %45, %44 ], [ %66, %47 ]
  %51 = phi i32 [ %23, %44 ], [ %63, %47 ]
  call void @cqrt_push(i32 %from)
  %52 = call i32 @cq_template_icmp_ult_i32_hl(i32 %51, i32 41)
  %53 = call i32 @cq_template_add_i64_hl(i32 %48, i64 8)
  %54 = ptrtoint ptr %24 to i64
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_xor_i1(i32 %52, i32 %56)
  call void @cqrt_and_i1(i32 %0, i32 %56, i32 %55)
  call void @cqrt_xor_i1(i32 %52, i32 %56)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %55, i32 %8, i64 %54, i32 %53)
  %57 = call i32 @cq_template_zext_i32_to_i64(i32 %51)
  %58 = call i32 @cq_template_add_i64(i32 %27, i32 %57)
  %59 = call i32 @cq_template_add_i32_hl(i32 %51, i32 8)
  %60 = ptrtoint ptr %9 to i64
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %52, i32 %61)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %61, i32 %8, i64 %60, i32 %59)
  %62 = call i32 @cq_template_select_i64(i32 %52, i32 %48, i32 %53)
  %63 = call i32 @cq_template_select_i32(i32 %52, i32 %59, i32 %51)
  %64 = call i32 @cq_template_select_i64(i32 %52, i32 %58, i32 %48)
  %65 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %8, i32 %64)
  %66 = call i32 @cq_template_add_i32(i32 %65, i32 %50)
  %67 = add nuw nsw i32 %49, 1
  %68 = icmp eq i32 %67, %1
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %57)
  br i1 %68, label %46, label %47

69:                                               ; preds = %46
  br label %30

70:                                               ; preds = %71
  call void @cqrt_free(i32 %37)
  br label %86

71:                                               ; preds = %30, %71
  %cq.run9 = phi i1 [ %cq.run10, %30 ], [ %cq.run9, %71 ]
  %cq.run5 = phi i1 [ %cq.run6, %30 ], [ %cq.run5, %71 ]
  %cq.run1 = phi i1 [ %cq.run2, %30 ], [ %cq.run1, %71 ]
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
  call void @cq_template_add_i32_unc(i32 %84, i32 %83, i32 %82)
  call void @cqrt_free(i32 %84)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %83, i32 %0, i32 %8, i32 %81)
  call void @cq_template_select_i64_unc(i32 %81, i32 %80, i32 %79, i32 %78)
  call void @cqrt_free(i32 %81)
  call void @cq_template_select_i32_unc(i32 %77, i32 %80, i32 %76, i32 %75)
  call void @cqrt_free(i32 %77)
  call void @cq_template_select_i64_unc(i32 %74, i32 %80, i32 %78, i32 %73)
  call void @cqrt_free(i32 %74)
  call void @cq_template_add_i64_unc(i32 %79, i32 %38, i32 %72)
  call void @cqrt_free(i32 %79)
  call void @cq_template_zext_i32_to_i64_unc(i32 %72, i32 %75)
  call void @cqrt_free(i32 %72)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %80, i32 %75, i32 41)
  call void @cqrt_free(i32 %80)
  %85 = call i32 @cqrt_pop()
  switch i32 %85, label %71 [
    i32 1, label %70
  ]

86:                                               ; preds = %70, %30
  %cq.run8 = phi i1 [ %cq.run9, %70 ], [ %cq.run10, %30 ]
  %cq.run4 = phi i1 [ %cq.run5, %70 ], [ %cq.run6, %30 ]
  %cq.run = phi i1 [ %cq.run1, %70 ], [ %cq.run2, %30 ]
  br label %41

87:                                               ; preds = %3
  %88 = call i32 @cqrt_alloc_i32(i32 0)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %89)
  %90 = load i32, ptr @__cq_act_sum, align 4
  %91 = add i32 %90, -1
  store i32 %91, ptr @__cq_act_sum, align 4
  ret i32 %88
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @sum, ptr @.cq.sig, ptr @__cq_q_sum_10_t, ptr @__cq_q_sum_10_t_ctl, ptr @__cq_q_sum_10_t_unc, ptr @__cq_q_sum_10_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_sum_10_t_unc(i32 %0, i32 %1, ptr %2, i32 %3) {
  ret void
}

define internal void @__cq_q_sum_10_t_ctl_unc(i32 %0, i32 %1, i32 %2, ptr %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_sum, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_sum, align 4
  %8 = load i32, ptr @__cq_act_sum, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_sum, align 4
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
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
