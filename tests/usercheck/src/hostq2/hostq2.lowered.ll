; ModuleID = '<stdin>'
source_filename = "tests/usercheck/src/hostq2/hostq2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.f.s = private unnamed_addr constant [9 x i8] c"ab/cd/ef\00", align 1
@.cq.effect.strlen = private unnamed_addr constant [7 x i8] c"strlen\00", align 1
@.cq.effect.strchr = private unnamed_addr constant [7 x i8] c"strchr\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i64 (i32)\00", align 1
@__cq_k = internal global i32 -1, align 4
@llvm.global_ctors = appending global [2 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }, { i32, ptr, ptr } { i32 65535, ptr @__cq_objects, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i64 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call ptr @__cq_alloc(i64 9, i64 1)
  %4 = ptrtoint ptr %3 to i64
  br label %5

5:                                                ; preds = %5, %1
  %6 = phi i64 [ 0, %1 ], [ %9, %5 ]
  %7 = add i64 ptrtoint (ptr @__const.f.s to i64), %6
  %8 = call i32 @cqrt_qram_load_i8_hl(i32 %2, i64 %7)
  call void @cqrt_push(i32 %8)
  %9 = add nuw i64 %6, 1
  %10 = icmp eq i64 %9, 9
  br i1 %10, label %11, label %5

11:                                               ; preds = %5
  br label %12

12:                                               ; preds = %11
  br label %13

13:                                               ; preds = %13, %12
  %14 = phi i64 [ 8, %12 ], [ %17, %13 ]
  %15 = call i32 @cqrt_pop()
  %16 = add i64 %4, %14
  call void @cqrt_qram_store_i8_hl(i32 %2, i64 %16, i32 %15)
  %17 = add nsw i64 %14, -1
  %18 = icmp eq i64 %14, 0
  br i1 %18, label %19, label %13

19:                                               ; preds = %13
  %20 = and i32 %0, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %28

22:                                               ; preds = %28, %19
  %23 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %3) #4
  %24 = call ptr @strchr(ptr noundef nonnull dereferenceable(1) %3, i32 noundef 47) #4
  %25 = icmp eq ptr %24, null
  %26 = select i1 %25, i64 0, i64 100
  %27 = add nsw i64 %26, %23
  ret i64 %27

28:                                               ; preds = %19
  %29 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %29, double 5.000000e-01)
  %30 = call i32 @cq_template_and_i8_hl(i32 %29, i8 1)
  %31 = call i32 @cq_template_icmp_eq_i8_hl(i32 %30, i8 0)
  %32 = call i32 @cq_template_select_i8_ll(i32 %31, i8 120, i8 0)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %31, i32 %30, i8 0)
  call void @cqrt_free(i32 %31)
  call void @cq_template_and_i8_hl_unc(i32 %30, i32 %29, i8 1)
  call void @cqrt_free(i32 %30)
  %33 = lshr i32 %0, 1
  %34 = and i32 %33, 7
  %35 = zext nneg i32 %34 to i64
  %36 = getelementptr inbounds [9 x i8], ptr %3, i64 0, i64 %35
  %37 = ptrtoint ptr %36 to i64
  call void @cqrt_qram_store_i8_hl(i32 %2, i64 %37, i32 %32)
  br label %22
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: read)
declare ptr @strchr(ptr noundef, i32 noundef) local_unnamed_addr #3

declare ptr @__cq_alloc(i64, i64)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_and_i8_hl(i32, i8)

declare i32 @cq_template_icmp_eq_i8_hl(i32, i8)

declare i32 @cq_template_select_i8_ll(i32, i8, i8)

declare void @cq_template_icmp_eq_i8_hl_unc(i32, i32, i8)

declare void @cqrt_free(i32)

declare void @cq_template_and_i8_hl_unc(i32, i32, i8)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 9, i64 1)
  %7 = ptrtoint ptr %6 to i64
  br label %8

8:                                                ; preds = %8, %2
  %9 = phi i64 [ 0, %2 ], [ %12, %8 ]
  %10 = add i64 ptrtoint (ptr @__const.f.s to i64), %9
  %11 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %10)
  call void @cqrt_push(i32 %11)
  %12 = add nuw i64 %9, 1
  %13 = icmp eq i64 %12, 9
  br i1 %13, label %14, label %8

14:                                               ; preds = %8
  br label %15

15:                                               ; preds = %14
  br label %16

16:                                               ; preds = %16, %15
  %17 = phi i64 [ 8, %15 ], [ %20, %16 ]
  %18 = call i32 @cqrt_pop()
  %19 = add i64 %7, %17
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %19, i32 %18)
  %20 = add nsw i64 %17, -1
  %21 = icmp eq i64 %17, 0
  br i1 %21, label %22, label %16

22:                                               ; preds = %16
  %23 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 0)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %0, i32 1)
  call void @cqrt_free(i32 %23)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_xor_i1(i32 %24, i32 %25)
  %26 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %25, i32 %26, double 5.000000e-01)
  call void @cqrt_xor_i1(i32 %24, i32 %25)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_free(i32 %25)
  %27 = alloca { i32, ptr }, align 8
  %28 = getelementptr inbounds { i32, ptr }, ptr %27, i32 0, i32 0
  store i32 %26, ptr %28, align 4
  %29 = load ptr, ptr %cq.mints, align 8
  %30 = getelementptr inbounds { i32, ptr }, ptr %27, i32 0, i32 1
  store ptr %29, ptr %30, align 8
  store ptr %27, ptr %cq.mints, align 8
  %31 = call i32 @cq_template_and_i8_hl(i32 %26, i8 1)
  %32 = call i32 @cq_template_icmp_eq_i8_hl(i32 %31, i8 0)
  %33 = call i32 @cq_template_select_i8_ll(i32 %32, i8 120, i8 0)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %32, i32 %31, i8 0)
  call void @cqrt_free(i32 %32)
  call void @cq_template_and_i8_hl_unc(i32 %31, i32 %26, i8 1)
  call void @cqrt_free(i32 %31)
  %34 = call i32 @cq_template_lshr_i32_hl(i32 %0, i32 1)
  %35 = call i32 @cq_template_and_i32_hl(i32 %34, i32 7)
  %36 = call i32 @cq_template_zext_i32_to_i64(i32 %35)
  %37 = ptrtoint ptr %6 to i64
  %38 = call i32 @cq_template_add_i64_hl(i32 %36, i64 %37)
  call void @__cq_data(i32 %33)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_qram_store_i8_controlled(i32 %24, i32 %5, i32 %38, i32 %33)
  call void @cqrt_not_i1(i32 %24)
  call void @cq_template_add_i64_hl_unc(i32 %38, i32 %36, i64 %37)
  call void @cqrt_free(i32 %38)
  call void @cq_template_zext_i32_to_i64_unc(i32 %36, i32 %35)
  call void @cqrt_free(i32 %36)
  call void @cq_template_and_i32_hl_unc(i32 %35, i32 %34, i32 7)
  call void @cqrt_free(i32 %35)
  call void @cq_template_lshr_i32_hl_unc(i32 %34, i32 %0, i32 1)
  call void @cqrt_free(i32 %34)
  %39 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 %37)
  %40 = call i32 @cqrt_tape_effect_i64_controlled(i32 %39, i32 %4, ptr @.cq.effect.strlen, i32 1)
  call void @cqrt_free(i32 %39)
  %41 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 %37)
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 47)
  %42 = call i32 @cqrt_tape_effect_i64_controlled(i32 %41, i32 %4, ptr @.cq.effect.strchr, i32 2)
  call void @cqrt_free(i32 %41)
  %43 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 0)
  %44 = call i32 @cq_template_select_i64_ll(i32 %43, i64 0, i64 100)
  %45 = call i32 @cq_template_add_i64(i32 %44, i32 %40)
  %46 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %45, i32 %46)
  call void @cq_template_add_i64_unc(i32 %45, i32 %44, i32 %40)
  call void @cqrt_free(i32 %45)
  call void @cq_template_select_i64_ll_unc(i32 %44, i32 %43, i64 0, i64 100)
  call void @cqrt_free(i32 %44)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %42, i64 0)
  call void @cqrt_free(i32 %43)
  %47 = call i64 @cqrt_measure_i64(i32 %46), !cq.measure !6
  %48 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %48)
  %49 = call i32 @cqrt_alloc_i64(i64 %47)
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %49
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @__cq_data(i32)

declare void @cqrt_qram_store_i8_controlled(i32, i32, i32, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare i32 @cqrt_tape_effect_i64_controlled(i32, i32, ptr, i32)

declare void @cqrt_tape_write_i32_lit(i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cq_template_select_i64_ll(i32, i64, i64)

declare i32 @cq_template_add_i64(i32, i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_copy_i64(i32, i32)

declare i64 @cqrt_measure_i64(i32)

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

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %55

8:                                                ; preds = %3
  %9 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %10 = call i32 @__cq_mem()
  %11 = call ptr @__cq_alloc(i64 9, i64 1)
  %12 = ptrtoint ptr %11 to i64
  br label %13

13:                                               ; preds = %13, %8
  %14 = phi i64 [ 0, %8 ], [ %17, %13 ]
  %15 = add i64 ptrtoint (ptr @__const.f.s to i64), %14
  %16 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %10, i64 %15)
  call void @cqrt_push(i32 %16)
  %17 = add nuw i64 %14, 1
  %18 = icmp eq i64 %17, 9
  br i1 %18, label %19, label %13

19:                                               ; preds = %13
  br label %20

20:                                               ; preds = %19
  br label %21

21:                                               ; preds = %21, %20
  %22 = phi i64 [ 8, %20 ], [ %25, %21 ]
  %23 = call i32 @cqrt_pop()
  %24 = add i64 %12, %22
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %10, i64 %24, i32 %23)
  %25 = add nsw i64 %22, -1
  %26 = icmp eq i64 %22, 0
  br i1 %26, label %27, label %21

27:                                               ; preds = %21
  %28 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %28, i32 0)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_xor_i1(i32 %29, i32 %31)
  call void @cqrt_and_i1(i32 %0, i32 %31, i32 %30)
  call void @cqrt_xor_i1(i32 %29, i32 %31)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %29, i32 %28, i32 0)
  call void @cqrt_free(i32 %29)
  call void @cq_template_and_i32_hl_unc(i32 %28, i32 %1, i32 1)
  call void @cqrt_free(i32 %28)
  %32 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %30, i32 %32, double 5.000000e-01)
  %33 = alloca { i32, ptr }, align 8
  %34 = getelementptr inbounds { i32, ptr }, ptr %33, i32 0, i32 0
  store i32 %32, ptr %34, align 4
  %35 = load ptr, ptr %cq.mints, align 8
  %36 = getelementptr inbounds { i32, ptr }, ptr %33, i32 0, i32 1
  store ptr %35, ptr %36, align 8
  store ptr %33, ptr %cq.mints, align 8
  %37 = call i32 @cq_template_and_i8_hl(i32 %32, i8 1)
  %38 = call i32 @cq_template_icmp_eq_i8_hl(i32 %37, i8 0)
  %39 = call i32 @cq_template_select_i8_ll(i32 %38, i8 120, i8 0)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %38, i32 %37, i8 0)
  call void @cqrt_free(i32 %38)
  call void @cq_template_and_i8_hl_unc(i32 %37, i32 %32, i8 1)
  call void @cqrt_free(i32 %37)
  %40 = call i32 @cq_template_lshr_i32_hl(i32 %1, i32 1)
  %41 = call i32 @cq_template_and_i32_hl(i32 %40, i32 7)
  %42 = call i32 @cq_template_zext_i32_to_i64(i32 %41)
  %43 = ptrtoint ptr %11 to i64
  %44 = call i32 @cq_template_add_i64_hl(i32 %42, i64 %43)
  call void @__cq_data(i32 %39)
  call void @cqrt_qram_store_i8_controlled(i32 %30, i32 %10, i32 %44, i32 %39)
  call void @cq_template_add_i64_hl_unc(i32 %44, i32 %42, i64 %43)
  call void @cqrt_free(i32 %44)
  call void @cq_template_zext_i32_to_i64_unc(i32 %42, i32 %41)
  call void @cqrt_free(i32 %42)
  call void @cq_template_and_i32_hl_unc(i32 %41, i32 %40, i32 7)
  call void @cqrt_free(i32 %41)
  call void @cq_template_lshr_i32_hl_unc(i32 %40, i32 %1, i32 1)
  call void @cqrt_free(i32 %40)
  call void @cqrt_tape_write_i64_lit(i32 %9, i64 %43)
  %45 = call i32 @cqrt_tape_effect_i64_controlled(i32 %0, i32 %9, ptr @.cq.effect.strlen, i32 1)
  call void @cqrt_tape_write_i64_lit(i32 %9, i64 %43)
  call void @cqrt_tape_write_i32_lit(i32 %9, i32 47)
  %46 = call i32 @cqrt_tape_effect_i64_controlled(i32 %0, i32 %9, ptr @.cq.effect.strchr, i32 2)
  %47 = call i32 @cq_template_icmp_eq_i64_hl(i32 %46, i64 0)
  %48 = call i32 @cq_template_select_i64_ll(i32 %47, i64 0, i64 100)
  %49 = call i32 @cq_template_add_i64(i32 %48, i32 %45)
  %50 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64_controlled(i32 %0, i32 %49, i32 %50)
  call void @cq_template_add_i64_unc(i32 %49, i32 %48, i32 %45)
  call void @cqrt_free(i32 %49)
  call void @cq_template_select_i64_ll_unc(i32 %48, i32 %47, i64 0, i64 100)
  call void @cqrt_free(i32 %48)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %47, i32 %46, i64 0)
  call void @cqrt_free(i32 %47)
  %51 = call i64 @cqrt_measure_i64(i32 %50), !cq.measure !6
  %52 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %52)
  %53 = load i32, ptr @__cq_act_f, align 4
  %54 = add i32 %53, -1
  store i32 %54, ptr @__cq_act_f, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %50

55:                                               ; preds = %3
  %56 = call i32 @cqrt_alloc_i64(i64 0)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %57)
  call void @cqrt_push(i32 0)
  %58 = load i32, ptr @__cq_act_f, align 4
  %59 = add i32 %58, -1
  store i32 %59, ptr @__cq_act_f, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %56
}

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i64_controlled(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @cqrt_pop()
  br label %6

6:                                                ; preds = %9, %3
  %7 = phi i32 [ %5, %3 ], [ %11, %9 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %6
  %10 = call i32 @cqrt_pop()
  %11 = sub i32 %7, 1
  br label %6

12:                                               ; preds = %6
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = call i32 @cqrt_pop()
  br label %11

11:                                               ; preds = %14, %4
  %12 = phi i32 [ %10, %4 ], [ %16, %14 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %17, label %14

14:                                               ; preds = %11
  %15 = call i32 @cqrt_pop()
  %16 = sub i32 %12, 1
  br label %11

17:                                               ; preds = %11
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_objects() {
  call void @__cq_object(i64 ptrtoint (ptr @__const.f.s to i64), i64 9)
  ret void
}

declare void @__cq_object(i64, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(argmem: read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
