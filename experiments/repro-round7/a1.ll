; ModuleID = '<stdin>'
source_filename = "abortloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_bump = internal global i32 0, align 4
@__cq_act_walk = internal global i32 0, align 4
@__cq_act_main = internal global i32 0, align 4
@__cq_k = internal global i32 -1, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i64 (ptr)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [15 x i8] c"i64 (ptr, i32)\00", align 1
@.cq.sig.2 = private unnamed_addr constant [7 x i8] c"i32 ()\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i64 @bump(ptr noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = ptrtoint ptr %0 to i64
  %4 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_hl(i32 %2, i64 %3, i32 %4)
  %5 = call i32 @cq_template_add_i64_hl(i32 %4, i64 1)
  %6 = call i32 @cq_template_sub_i64_hl(i32 %5, i64 1)
  call void @cqrt_copy_i64(i32 %6, i32 %4)
  call void @cq_template_sub_i64_hl_unc(i32 %6, i32 %5, i64 1)
  call void @cqrt_free(i32 %6)
  call void @cqrt_free(i32 %4)
  call void @cqrt_qram_swap_i64_hl(i32 %2, i64 %3, i32 %5)
  call void @cqrt_free(i32 %5)
  %7 = getelementptr inbounds i8, ptr %0, i64 8
  %8 = ptrtoint ptr %7 to i64
  %9 = call i32 @cqrt_qram_load_i64_hl(i32 %2, i64 %8)
  %10 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %9, i64 5)
  %11 = call i32 @cq_template_zext_i1_to_i64(i32 %10)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %10, i32 %9, i64 5)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i64_hl_unc(i32 %9, i32 %2, i64 %8)
  call void @cqrt_free(i32 %9)
  %12 = zext i32 %11 to i64
  ret i64 %12
}

; Function Attrs: noinline nounwind ssp uwtable
define i64 @walk(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = icmp sgt i32 %1, 0
  %5 = call i32 @cqrt_alloc_i64(i64 0)
  br i1 %4, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  br label %16

8:                                                ; preds = %2, %40
  %9 = phi i32 [ poison, %2 ], [ %17, %40 ]
  %10 = phi i32 [ poison, %2 ], [ %18, %40 ]
  %11 = phi i32 [ poison, %2 ], [ %19, %40 ]
  %ran = phi i1 [ false, %2 ], [ true, %40 ]
  %12 = phi i32 [ %5, %2 ], [ %36, %40 ]
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %12, i32 %13)
  call void @cqrt_free(i32 %5)
  br i1 %ran, label %42, label %62

14:                                               ; preds = %62
  %15 = zext i32 %13 to i64
  ret i64 %15

16:                                               ; preds = %6
  %17 = call i32 @cqrt_alloc_i1(i1 true)
  %18 = call i32 @cqrt_alloc_i64(i64 0)
  %19 = call i32 @cqrt_alloc_i64(i64 0)
  br label %21

20:                                               ; preds = %21
  br label %40

21:                                               ; preds = %21, %16
  %from = phi i32 [ 0, %21 ], [ 1, %16 ]
  %22 = phi i64 [ 0, %16 ], [ %33, %21 ]
  %23 = phi i32 [ %18, %16 ], [ %35, %21 ]
  %trip = phi i32 [ %17, %16 ], [ %27, %21 ]
  %xcap = phi i32 [ %19, %16 ], [ %xcap, %21 ]
  call void @cqrt_push(i32 %from)
  %24 = getelementptr inbounds i64, ptr %0, i64 %22
  %25 = call i32 @__cq_q_bump_0_ctl(i32 %trip, ptr %24)
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %25, i64 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %28, i32 %29)
  call void @cqrt_and_i1(i32 %trip, i32 %28, i32 %27)
  call void @cqrt_abort_i1(i32 %29)
  %30 = ptrtoint ptr %24 to i64
  %31 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %trip, i32 %3, i64 %30)
  %32 = call i32 @cq_template_add_i64(i32 %31, i32 %23)
  %33 = add nuw nsw i64 %22, 1
  %34 = icmp eq i64 %33, %7
  %35 = call i32 @cq_template_select_i64(i32 %27, i32 %32, i32 %23)
  %36 = call i32 @cq_template_select_i64(i32 %27, i32 %32, i32 %xcap)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %trip)
  %37 = trunc i64 %30 to i32
  call void @cqrt_push(i32 %37)
  %38 = lshr i64 %30, 32
  %39 = trunc i64 %38 to i32
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %25)
  br i1 %34, label %20, label %21

40:                                               ; preds = %20
  br label %8

41:                                               ; preds = %42
  call void @cqrt_free(i32 %11)
  call void @cqrt_free(i32 %10)
  call void @cqrt_free(i32 %9)
  br label %62

42:                                               ; preds = %8, %42
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = zext i32 %46 to i64
  %48 = shl i64 %47, 32
  %49 = or i64 0, %48
  %50 = call i32 @cqrt_pop()
  %51 = zext i32 %50 to i64
  %52 = or i64 %49, %51
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %60, i32 %59, i32 %58, i32 %57)
  call void @cqrt_free(i32 %60)
  call void @cq_template_select_i64_unc(i32 %56, i32 %59, i32 %58, i32 %55)
  call void @cqrt_free(i32 %56)
  call void @cq_template_add_i64_unc(i32 %58, i32 %54, i32 %55)
  call void @cqrt_free(i32 %58)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %54, i32 %53, i32 %3, i64 %52)
  call void @cqrt_and_i1(i32 %53, i32 %45, i32 %59)
  call void @cqrt_xor_i1(i32 %53, i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cqrt_xor_i1(i32 %44, i32 %45)
  call void @cqrt_not_i1(i32 %45)
  call void @cqrt_free(i32 %45)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %44, i32 %43, i64 0)
  call void @cqrt_free(i32 %44)
  %61 = call i32 @cqrt_pop()
  switch i32 %61, label %42 [
    i32 1, label %41
  ]

62:                                               ; preds = %41, %8
  br label %14
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = call i32 @__cq_mem()
  %2 = call ptr @__cq_alloc(i64 48, i64 16)
  %3 = ptrtoint ptr %2 to i64
  %4 = call i32 @cqrt_alloc_i8(i8 0)
  br label %5

5:                                                ; preds = %5, %0
  %6 = phi i64 [ 0, %0 ], [ %8, %5 ]
  %7 = add i64 %3, %6
  call void @cqrt_qram_store_i8_hl(i32 %1, i64 %7, i32 %4)
  %8 = add nuw i64 %6, 1
  %9 = icmp eq i64 %8, 48
  br i1 %9, label %10, label %5

10:                                               ; preds = %5
  %11 = ptrtoint ptr %2 to i64
  %12 = call i32 @cqrt_alloc_i64(i64 1)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %11, i32 %12)
  %13 = getelementptr inbounds i8, ptr %2, i64 8
  %14 = ptrtoint ptr %13 to i64
  %15 = call i32 @cqrt_alloc_i64(i64 2)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %14, i32 %15)
  %16 = getelementptr inbounds i8, ptr %2, i64 16
  %17 = ptrtoint ptr %16 to i64
  %18 = call i32 @cqrt_alloc_i64(i64 3)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %17, i32 %18)
  %19 = getelementptr inbounds i8, ptr %2, i64 24
  %20 = ptrtoint ptr %19 to i64
  %21 = call i32 @cqrt_alloc_i64(i64 4)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %20, i32 %21)
  %22 = getelementptr inbounds i8, ptr %2, i64 32
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cqrt_alloc_i64(i64 5)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %23, i32 %24)
  %25 = getelementptr inbounds i8, ptr %2, i64 40
  %26 = ptrtoint ptr %25 to i64
  %27 = call i32 @cqrt_alloc_i64(i64 6)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %26, i32 %27)
  %28 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %28, double 0x3FF921FB54442D18)
  %29 = call i32 @cq_template_and_i8_hl(i32 %28, i8 7)
  %30 = call i32 @cq_template_add_i8_hl(i32 %29, i8 3)
  %31 = call i32 @cq_template_zext_i8_to_i64(i32 %30)
  call void @cq_template_add_i8_hl_unc(i32 %30, i32 %29, i8 3)
  call void @cqrt_free(i32 %30)
  call void @cq_template_and_i8_hl_unc(i32 %29, i32 %28, i8 7)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_store_i64_hl(i32 %1, i64 %17, i32 %31)
  %32 = call i64 @walk(ptr noundef %2, i32 noundef 4)
  %33 = trunc i64 %32 to i32
  %34 = call i32 @cq_template_trunc_i64_to_i32(i32 %33)
  %35 = call i32 @cqrt_measure_i32(i32 %34), !cq.measure !6
  ret i32 %35
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

declare i32 @cqrt_alloc_i64(i64)

declare i32 @__cq_mem()

declare void @cqrt_qram_swap_i64_hl(i32, i64, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cq_template_sub_i64_hl(i32, i64)

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)

declare void @cqrt_free(i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)

declare i32 @cq_template_zext_i1_to_i64(i32)

declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_bump_1_t(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64(i32 %4, i32 %0, i32 %5)
  %6 = call i32 @cq_template_add_i64_hl(i32 %5, i64 1)
  %7 = call i32 @cq_template_sub_i64_hl(i32 %6, i64 1)
  call void @cqrt_copy_i64(i32 %7, i32 %5)
  call void @cq_template_sub_i64_hl_unc(i32 %7, i32 %6, i64 1)
  call void @cqrt_free(i32 %7)
  call void @cqrt_free(i32 %5)
  call void @cqrt_qram_swap_i64(i32 %4, i32 %0, i32 %6)
  call void @cqrt_free(i32 %6)
  %8 = call i32 @cq_template_add_i64_hl(i32 %0, i64 8)
  %9 = call i32 @cqrt_qram_load_i64(i32 %4, i32 %8)
  %10 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %9, i64 5)
  %11 = call i32 @cq_template_zext_i1_to_i64(i32 %10)
  %12 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %11, i32 %12)
  call void @cq_template_zext_i1_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %10, i32 %9, i64 5)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i64_unc(i32 %9, i32 %4, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i64_hl_unc(i32 %8, i32 %0, i64 8)
  call void @cqrt_free(i32 %8)
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %12
}

declare void @cqrt_qram_swap_i64(i32, i32, i32)

declare i32 @cqrt_qram_load_i64(i32, i32)

declare void @cq_template_zext_i1_to_i64_unc(i32, i32)

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_bump_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_bump, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_bump, align 4
  %7 = icmp ult i32 %5, %2
  br i1 %7, label %8, label %22

8:                                                ; preds = %3
  %9 = call i32 @__cq_mem()
  %10 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %0, i32 %9, i32 %1, i32 %10)
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 1)
  %12 = call i32 @cq_template_select_i64(i32 %0, i32 %11, i32 %10)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 1)
  call void @cqrt_free(i32 %11)
  %13 = call i32 @cq_template_sub_i64_hl(i32 %12, i64 1)
  %14 = call i32 @cq_template_select_i64(i32 %0, i32 %13, i32 %12)
  call void @cqrt_copy_i64(i32 %14, i32 %10)
  call void @cq_template_select_i64_unc(i32 %14, i32 %0, i32 %13, i32 %12)
  call void @cqrt_free(i32 %14)
  call void @cq_template_sub_i64_hl_unc(i32 %13, i32 %12, i64 1)
  call void @cqrt_free(i32 %13)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_swap_i64_controlled(i32 %0, i32 %9, i32 %1, i32 %12)
  call void @cqrt_free(i32 %12)
  %15 = call i32 @cq_template_add_i64_hl(i32 %1, i64 8)
  %16 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %9, i32 %15)
  %17 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 5)
  %18 = call i32 @cq_template_zext_i1_to_i64(i32 %17)
  %19 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %18, i32 %19)
  call void @cq_template_zext_i1_to_i64_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %17, i32 %16, i64 5)
  call void @cqrt_free(i32 %17)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %16, i32 %0, i32 %9, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_add_i64_hl_unc(i32 %15, i32 %1, i64 8)
  call void @cqrt_free(i32 %15)
  %20 = load i32, ptr @__cq_act_bump, align 4
  %21 = add i32 %20, -1
  store i32 %21, ptr @__cq_act_bump, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %19

22:                                               ; preds = %3
  %23 = call i32 @cqrt_alloc_i64(i64 0)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %24)
  %25 = load i32, ptr @__cq_act_bump, align 4
  %26 = add i32 %25, -1
  store i32 %26, ptr @__cq_act_bump, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %23
}

declare void @cqrt_qram_swap_i64_controlled(i32, i32, i32, i32)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

define i32 @__cq_q_bump_0_ctl(i32 %0, ptr %1) local_unnamed_addr {
  %3 = load i32, ptr @__cq_k, align 4
  %4 = icmp eq i32 %3, -1
  %5 = select i1 %4, i32 4, i32 %3
  %6 = load i32, ptr @__cq_act_bump, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_bump, align 4
  %8 = icmp ult i32 %6, %5
  br i1 %8, label %9, label %25

9:                                                ; preds = %2
  %10 = call i32 @__cq_mem()
  %11 = ptrtoint ptr %1 to i64
  %12 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_hl_controlled(i32 %0, i32 %10, i64 %11, i32 %12)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 1)
  %14 = call i32 @cq_template_select_i64(i32 %0, i32 %13, i32 %12)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 1)
  call void @cqrt_free(i32 %13)
  %15 = call i32 @cq_template_sub_i64_hl(i32 %14, i64 1)
  %16 = call i32 @cq_template_select_i64(i32 %0, i32 %15, i32 %14)
  call void @cqrt_copy_i64(i32 %16, i32 %12)
  call void @cq_template_select_i64_unc(i32 %16, i32 %0, i32 %15, i32 %14)
  call void @cqrt_free(i32 %16)
  call void @cq_template_sub_i64_hl_unc(i32 %15, i32 %14, i64 1)
  call void @cqrt_free(i32 %15)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_swap_i64_hl_controlled(i32 %0, i32 %10, i64 %11, i32 %14)
  call void @cqrt_free(i32 %14)
  %17 = getelementptr inbounds i8, ptr %1, i64 8
  %18 = ptrtoint ptr %17 to i64
  %19 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %10, i64 %18)
  %20 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %19, i64 5)
  %21 = call i32 @cq_template_zext_i1_to_i64(i32 %20)
  %22 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %21, i32 %22)
  call void @cq_template_zext_i1_to_i64_unc(i32 %21, i32 %20)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %20, i32 %19, i64 5)
  call void @cqrt_free(i32 %20)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %19, i32 %0, i32 %10, i64 %18)
  call void @cqrt_free(i32 %19)
  %23 = load i32, ptr @__cq_act_bump, align 4
  %24 = add i32 %23, -1
  store i32 %24, ptr @__cq_act_bump, align 4
  ret i32 %22

25:                                               ; preds = %2
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %27)
  %28 = load i32, ptr @__cq_act_bump, align 4
  %29 = add i32 %28, -1
  store i32 %29, ptr @__cq_act_bump, align 4
  ret i32 %26
}

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_abort_i1(i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_walk_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  %7 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  br label %8

8:                                                ; preds = %3
  %9 = call i32 @cqrt_alloc_i64(i64 0)
  %10 = call i32 @llvm.umin.i32(i32 %2, i32 2147483647)
  %11 = icmp ult i32 %2, 2147483647
  %12 = icmp ult i32 0, %10
  br i1 %12, label %13, label %41

13:                                               ; preds = %13, %8
  %from = phi i32 [ 0, %13 ], [ 1, %8 ]
  %14 = phi i32 [ 0, %8 ], [ %36, %13 ]
  %15 = phi i32 [ %6, %8 ], [ %32, %13 ]
  %16 = phi i64 [ 0, %8 ], [ %25, %13 ]
  %17 = phi i32 [ %9, %8 ], [ %33, %13 ]
  call void @cqrt_push(i32 %from)
  %18 = mul i64 %16, 8
  %19 = call i32 @cq_template_add_i64_hl(i32 %0, i64 %18)
  %20 = call i32 @__cq_q_bump_1_ctl(i32 %15, i32 %19)
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  %23 = call i32 @cqrt_qram_load_i64_controlled(i32 %22, i32 %5, i32 %19)
  %24 = call i32 @cq_template_add_i64(i32 %23, i32 %17)
  %25 = add i64 %16, 1
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %7, i64 %25)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %21, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %27, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %6, i32 %29)
  call void @cqrt_and_i1(i32 %6, i32 %21, i32 %29)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %29, i32 %30)
  call void @cqrt_and_i1(i32 %6, i32 %21, i32 %29)
  call void @cqrt_xor_i1(i32 %6, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_and_i1(i32 %15, i32 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_xor_i1(i32 %21, i32 %27)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_abort_i1(i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %21, i32 %31)
  call void @cqrt_and_i1(i32 %21, i32 %26, i32 %31)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %31, i32 %32)
  %33 = call i32 @cq_template_select_i64(i32 %15, i32 %24, i32 %17)
  call void @cq_template_add_i64_unc(i32 %24, i32 %23, i32 %17)
  call void @cqrt_free(i32 %24)
  %34 = call i32 @cq_template_sub_i64(i32 %33, i32 %23)
  %35 = call i32 @cq_template_select_i64(i32 %15, i32 %34, i32 %33)
  call void @cqrt_copy_i64(i32 %35, i32 %17)
  call void @cq_template_select_i64_unc(i32 %35, i32 %15, i32 %34, i32 %33)
  call void @cqrt_free(i32 %35)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sub_i64_unc(i32 %34, i32 %33, i32 %23)
  call void @cqrt_free(i32 %34)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %23, i32 %22, i32 %5, i32 %19)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %0, i64 %18)
  call void @cqrt_free(i32 %19)
  %36 = add i32 %14, 1
  %37 = icmp ult i32 %36, %10
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %26)
  %38 = trunc i64 %25 to i32
  call void @cqrt_push(i32 %38)
  %39 = lshr i64 %25, 32
  %40 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %20)
  br i1 %37, label %13, label %41

41:                                               ; preds = %13, %8
  %42 = phi i32 [ 0, %8 ], [ 1, %13 ]
  %43 = phi i64 [ 0, %8 ], [ %25, %13 ]
  %44 = phi i32 [ %9, %8 ], [ %33, %13 ]
  %45 = phi i32 [ %6, %8 ], [ %32, %13 ]
  br i1 %11, label %46, label %48

46:                                               ; preds = %41
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %45, i32 %47)
  br label %49

48:                                               ; preds = %41
  br label %49

49:                                               ; preds = %46, %48
  br label %68

50:                                               ; preds = %68, %53
  call void @cq_template_zext_i32_to_i64_unc(i32 %7, i32 %1)
  call void @cqrt_free(i32 %7)
  %51 = call i32 @cq_template_select_i64_hl(i32 %6, i32 %44, i64 0)
  %52 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %51, i32 %52)
  call void @cq_template_select_i64_hl_unc(i32 %51, i32 %6, i32 %44, i64 0)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %1, i32 0)
  call void @cqrt_free(i32 %6)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %52

53:                                               ; preds = %68, %53
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = zext i32 %55 to i64
  %57 = shl i64 %56, 32
  %58 = or i64 0, %57
  %59 = call i32 @cqrt_pop()
  %60 = zext i32 %59 to i64
  %61 = or i64 %58, %60
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %66, i32 %65, i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cqrt_and_i1(i32 %63, i32 %62, i32 %65)
  call void @cqrt_xor_i1(i32 %63, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %62, i32 %7, i64 %61)
  call void @cqrt_free(i32 %62)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %63, i32 %54, i64 0)
  call void @cqrt_free(i32 %63)
  %67 = call i32 @cqrt_pop()
  switch i32 %67, label %53 [
    i32 1, label %50
  ]

68:                                               ; preds = %49
  switch i32 %42, label %50 [
    i32 1, label %53
  ]
}

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #5

define i32 @__cq_q_bump_1_ctl(i32 %0, i32 %1) local_unnamed_addr {
  %3 = load i32, ptr @__cq_k, align 4
  %4 = icmp eq i32 %3, -1
  %5 = select i1 %4, i32 4, i32 %3
  %6 = load i32, ptr @__cq_act_bump, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_bump, align 4
  %8 = icmp ult i32 %6, %5
  br i1 %8, label %9, label %23

9:                                                ; preds = %2
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_qram_swap_i64_controlled(i32 %0, i32 %10, i32 %1, i32 %11)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 1)
  %13 = call i32 @cq_template_select_i64(i32 %0, i32 %12, i32 %11)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 1)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_sub_i64_hl(i32 %13, i64 1)
  %15 = call i32 @cq_template_select_i64(i32 %0, i32 %14, i32 %13)
  call void @cqrt_copy_i64(i32 %15, i32 %11)
  call void @cq_template_select_i64_unc(i32 %15, i32 %0, i32 %14, i32 %13)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sub_i64_hl_unc(i32 %14, i32 %13, i64 1)
  call void @cqrt_free(i32 %14)
  call void @cqrt_free(i32 %11)
  call void @cqrt_qram_swap_i64_controlled(i32 %0, i32 %10, i32 %1, i32 %13)
  call void @cqrt_free(i32 %13)
  %16 = call i32 @cq_template_add_i64_hl(i32 %1, i64 8)
  %17 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %10, i32 %16)
  %18 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %17, i64 5)
  %19 = call i32 @cq_template_zext_i1_to_i64(i32 %18)
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %19, i32 %20)
  call void @cq_template_zext_i1_to_i64_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %18, i32 %17, i64 5)
  call void @cqrt_free(i32 %18)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %17, i32 %0, i32 %10, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %1, i64 8)
  call void @cqrt_free(i32 %16)
  %21 = load i32, ptr @__cq_act_bump, align 4
  %22 = add i32 %21, -1
  store i32 %22, ptr @__cq_act_bump, align 4
  ret i32 %20

23:                                               ; preds = %2
  %24 = call i32 @cqrt_alloc_i64(i64 0)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %25)
  %26 = load i32, ptr @__cq_act_bump, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_bump, align 4
  ret i32 %24
}

declare i32 @cq_template_sub_i64(i32, i32)

declare void @cq_template_sub_i64_unc(i32, i32, i32)

declare i32 @cq_template_select_i64_hl(i32, i32, i64)

declare void @cq_template_select_i64_hl_unc(i32, i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_walk_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_walk, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_walk, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %78

9:                                                ; preds = %4
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 0)
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %2)
  br label %13

13:                                               ; preds = %9
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %14)
  %15 = call i32 @cqrt_alloc_i64(i64 0)
  %16 = call i32 @llvm.umin.i32(i32 %3, i32 2147483647)
  %17 = icmp ult i32 %3, 2147483647
  %18 = icmp ult i32 0, %16
  br i1 %18, label %19, label %48

19:                                               ; preds = %19, %13
  %from = phi i32 [ 0, %19 ], [ 1, %13 ]
  %20 = phi i32 [ 0, %13 ], [ %43, %19 ]
  %21 = phi i32 [ %14, %13 ], [ %39, %19 ]
  %22 = phi i64 [ 0, %13 ], [ %31, %19 ]
  %23 = phi i32 [ %15, %13 ], [ %40, %19 ]
  call void @cqrt_push(i32 %from)
  %24 = mul i64 %22, 8
  %25 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %24)
  %26 = call i32 @__cq_q_bump_1_ctl(i32 %21, i32 %25)
  %27 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %27, i32 %28)
  %29 = call i32 @cqrt_qram_load_i64_controlled(i32 %28, i32 %10, i32 %25)
  %30 = call i32 @cq_template_add_i64(i32 %29, i32 %23)
  %31 = add i64 %22, 1
  %32 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_xor_i1(i32 %27, i32 %33)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %33, i32 %34)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %11, i32 %36)
  call void @cqrt_and_i1(i32 %11, i32 %27, i32 %36)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %35, i32 %37)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %11, i32 %27, i32 %36)
  call void @cqrt_xor_i1(i32 %11, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_and_i1(i32 %21, i32 %33, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %27, i32 %33)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cqrt_abort_i1(i32 %37)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %27, i32 %38)
  call void @cqrt_and_i1(i32 %27, i32 %32, i32 %38)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %38, i32 %39)
  %40 = call i32 @cq_template_select_i64(i32 %21, i32 %30, i32 %23)
  call void @cq_template_add_i64_unc(i32 %30, i32 %29, i32 %23)
  call void @cqrt_free(i32 %30)
  %41 = call i32 @cq_template_sub_i64(i32 %40, i32 %29)
  %42 = call i32 @cq_template_select_i64(i32 %21, i32 %41, i32 %40)
  call void @cqrt_copy_i64(i32 %42, i32 %23)
  call void @cq_template_select_i64_unc(i32 %42, i32 %21, i32 %41, i32 %40)
  call void @cqrt_free(i32 %42)
  call void @cqrt_free(i32 %23)
  call void @cq_template_sub_i64_unc(i32 %41, i32 %40, i32 %29)
  call void @cqrt_free(i32 %41)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %29, i32 %28, i32 %10, i32 %25)
  call void @cqrt_free(i32 %29)
  call void @cqrt_and_i1(i32 %21, i32 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i64_hl_unc(i32 %25, i32 %1, i64 %24)
  call void @cqrt_free(i32 %25)
  %43 = add i32 %20, 1
  %44 = icmp ult i32 %43, %16
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %32)
  %45 = trunc i64 %31 to i32
  call void @cqrt_push(i32 %45)
  %46 = lshr i64 %31, 32
  %47 = trunc i64 %46 to i32
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %26)
  br i1 %44, label %19, label %48

48:                                               ; preds = %19, %13
  %49 = phi i32 [ 0, %13 ], [ 1, %19 ]
  %50 = phi i64 [ 0, %13 ], [ %31, %19 ]
  %51 = phi i32 [ %15, %13 ], [ %40, %19 ]
  %52 = phi i32 [ %14, %13 ], [ %39, %19 ]
  br i1 %17, label %53, label %55

53:                                               ; preds = %48
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %52, i32 %54)
  br label %56

55:                                               ; preds = %48
  br label %56

56:                                               ; preds = %53, %55
  br label %77

57:                                               ; preds = %77, %62
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %2)
  call void @cqrt_free(i32 %12)
  %58 = call i32 @cq_template_select_i64_hl(i32 %11, i32 %51, i64 0)
  %59 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %58, i32 %59)
  call void @cq_template_select_i64_hl_unc(i32 %58, i32 %11, i32 %51, i64 0)
  call void @cqrt_free(i32 %58)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %2, i32 0)
  call void @cqrt_free(i32 %11)
  %60 = load i32, ptr @__cq_act_walk, align 4
  %61 = add i32 %60, -1
  store i32 %61, ptr @__cq_act_walk, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %59

62:                                               ; preds = %77, %62
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  %65 = zext i32 %64 to i64
  %66 = shl i64 %65, 32
  %67 = or i64 0, %66
  %68 = call i32 @cqrt_pop()
  %69 = zext i32 %68 to i64
  %70 = or i64 %67, %69
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  %73 = call i32 @cqrt_pop()
  %74 = call i32 @cqrt_pop()
  %75 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %75, i32 %74, i32 %73)
  call void @cqrt_free(i32 %73)
  call void @cqrt_and_i1(i32 %72, i32 %71, i32 %74)
  call void @cqrt_xor_i1(i32 %72, i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %71, i32 %12, i64 %70)
  call void @cqrt_free(i32 %71)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %72, i32 %63, i64 0)
  call void @cqrt_free(i32 %72)
  %76 = call i32 @cqrt_pop()
  switch i32 %76, label %62 [
    i32 1, label %57
  ]

77:                                               ; preds = %56
  switch i32 %49, label %57 [
    i32 1, label %62
  ]

78:                                               ; preds = %4
  %79 = call i32 @cqrt_alloc_i64(i64 0)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %80)
  %81 = load i32, ptr @__cq_act_walk, align 4
  %82 = add i32 %81, -1
  store i32 %82, ptr @__cq_act_walk, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %79
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_and_i8_hl(i32, i8)

declare i32 @cq_template_add_i8_hl(i32, i8)

declare i32 @cq_template_zext_i8_to_i64(i32)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i8_hl_unc(i32, i32, i8)

declare void @cq_template_and_i8_hl_unc(i32, i32, i8)

define internal i32 @__cq_q_main_v_t(i32 %0) {
  %cq.mints = alloca ptr, align 8
  %2 = load i32, ptr @__cq_k, align 4
  store i32 %0, ptr @__cq_k, align 4
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 48, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = call i32 @cqrt_alloc_i8(i8 0)
  br label %7

7:                                                ; preds = %7, %1
  %8 = phi i64 [ 0, %1 ], [ %10, %7 ]
  %9 = add i64 %5, %8
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %9, i32 %6)
  %10 = add nuw i64 %8, 1
  %11 = icmp eq i64 %10, 48
  br i1 %11, label %12, label %7

12:                                               ; preds = %7
  %13 = ptrtoint ptr %4 to i64
  %14 = call i32 @cqrt_alloc_i64(i64 1)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %13, i32 %14)
  %15 = getelementptr inbounds i8, ptr %4, i64 8
  %16 = ptrtoint ptr %15 to i64
  %17 = call i32 @cqrt_alloc_i64(i64 2)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %16, i32 %17)
  %18 = getelementptr inbounds i8, ptr %4, i64 16
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_alloc_i64(i64 3)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %19, i32 %20)
  %21 = getelementptr inbounds i8, ptr %4, i64 24
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cqrt_alloc_i64(i64 4)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %22, i32 %23)
  %24 = getelementptr inbounds i8, ptr %4, i64 32
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_alloc_i64(i64 5)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %25, i32 %26)
  %27 = getelementptr inbounds i8, ptr %4, i64 40
  %28 = ptrtoint ptr %27 to i64
  %29 = call i32 @cqrt_alloc_i64(i64 6)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %28, i32 %29)
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %30, double 0x3FF921FB54442D18)
  %31 = alloca { i32, ptr }, align 8
  %32 = getelementptr inbounds { i32, ptr }, ptr %31, i32 0, i32 0
  store i32 %30, ptr %32, align 4
  %33 = load ptr, ptr %cq.mints, align 8
  %34 = getelementptr inbounds { i32, ptr }, ptr %31, i32 0, i32 1
  store ptr %33, ptr %34, align 8
  store ptr %31, ptr %cq.mints, align 8
  %35 = call i32 @cq_template_and_i8_hl(i32 %30, i8 7)
  %36 = call i32 @cq_template_add_i8_hl(i32 %35, i8 3)
  %37 = call i32 @cq_template_zext_i8_to_i64(i32 %36)
  call void @cq_template_add_i8_hl_unc(i32 %36, i32 %35, i8 3)
  call void @cqrt_free(i32 %36)
  call void @cq_template_and_i8_hl_unc(i32 %35, i32 %30, i8 7)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %19, i32 %37)
  %38 = call i64 @walk(ptr noundef %4, i32 noundef 4)
  %39 = trunc i64 %38 to i32
  %40 = call i32 @cq_template_trunc_i64_to_i32(i32 %39)
  %41 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %40, i32 %41)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %40, i32 %39)
  call void @cqrt_free(i32 %40)
  %42 = call i32 @cqrt_measure_i32(i32 %41), !cq.measure !6
  %43 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %43)
  %44 = call i32 @cqrt_alloc_i32(i32 %42)
  store i32 %2, ptr @__cq_k, align 4
  ret i32 %44
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

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

declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)

define internal i32 @__cq_q_main_v_t_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = load i32, ptr @__cq_act_main, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_main, align 4
  %6 = icmp ult i32 %4, %1
  br i1 %6, label %7, label %50

7:                                                ; preds = %2
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 48, i64 16)
  %10 = ptrtoint ptr %9 to i64
  %11 = call i32 @cqrt_alloc_i8(i8 0)
  br label %12

12:                                               ; preds = %12, %7
  %13 = phi i64 [ 0, %7 ], [ %15, %12 ]
  %14 = add i64 %10, %13
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %14, i32 %11)
  %15 = add nuw i64 %13, 1
  %16 = icmp eq i64 %15, 48
  br i1 %16, label %17, label %12

17:                                               ; preds = %12
  %18 = ptrtoint ptr %9 to i64
  %19 = call i32 @cqrt_alloc_i64(i64 1)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %18, i32 %19)
  %20 = getelementptr inbounds i8, ptr %9, i64 8
  %21 = ptrtoint ptr %20 to i64
  %22 = call i32 @cqrt_alloc_i64(i64 2)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %21, i32 %22)
  %23 = getelementptr inbounds i8, ptr %9, i64 16
  %24 = ptrtoint ptr %23 to i64
  %25 = call i32 @cqrt_alloc_i64(i64 3)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %24, i32 %25)
  %26 = getelementptr inbounds i8, ptr %9, i64 24
  %27 = ptrtoint ptr %26 to i64
  %28 = call i32 @cqrt_alloc_i64(i64 4)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %27, i32 %28)
  %29 = getelementptr inbounds i8, ptr %9, i64 32
  %30 = ptrtoint ptr %29 to i64
  %31 = call i32 @cqrt_alloc_i64(i64 5)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %30, i32 %31)
  %32 = getelementptr inbounds i8, ptr %9, i64 40
  %33 = ptrtoint ptr %32 to i64
  %34 = call i32 @cqrt_alloc_i64(i64 6)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %33, i32 %34)
  %35 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %35, double 0x3FF921FB54442D18)
  %36 = alloca { i32, ptr }, align 8
  %37 = getelementptr inbounds { i32, ptr }, ptr %36, i32 0, i32 0
  store i32 %35, ptr %37, align 4
  %38 = load ptr, ptr %cq.mints, align 8
  %39 = getelementptr inbounds { i32, ptr }, ptr %36, i32 0, i32 1
  store ptr %38, ptr %39, align 8
  store ptr %36, ptr %cq.mints, align 8
  %40 = call i32 @cq_template_and_i8_hl(i32 %35, i8 7)
  %41 = call i32 @cq_template_add_i8_hl(i32 %40, i8 3)
  %42 = call i32 @cq_template_zext_i8_to_i64(i32 %41)
  call void @cq_template_add_i8_hl_unc(i32 %41, i32 %40, i8 3)
  call void @cqrt_free(i32 %41)
  call void @cq_template_and_i8_hl_unc(i32 %40, i32 %35, i8 7)
  call void @cqrt_free(i32 %40)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %8, i64 %24, i32 %42)
  %43 = call i32 @__cq_q_walk_00_ctl(i32 %0, ptr %9, i32 4)
  %44 = call i32 @cq_template_trunc_i64_to_i32(i32 %43)
  %45 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %44, i32 %45)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %44, i32 %43)
  call void @cqrt_free(i32 %44)
  %46 = call i32 @cqrt_measure_i32(i32 %45), !cq.measure !6
  %47 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %47)
  %48 = load i32, ptr @__cq_act_main, align 4
  %49 = add i32 %48, -1
  store i32 %49, ptr @__cq_act_main, align 4
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %45

50:                                               ; preds = %2
  %51 = call i32 @cqrt_alloc_i32(i32 0)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %52)
  call void @cqrt_push(i32 0)
  %53 = load i32, ptr @__cq_act_main, align 4
  %54 = add i32 %53, -1
  store i32 %54, ptr @__cq_act_main, align 4
  store i32 %3, ptr @__cq_k, align 4
  ret i32 %51
}

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_i8_controlled(i32, i32, double)

define i32 @__cq_q_walk_00_ctl(i32 %0, ptr %1, i32 %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_k, align 4
  %5 = icmp eq i32 %4, -1
  %6 = select i1 %5, i32 4, i32 %4
  %7 = load i32, ptr @__cq_act_walk, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_walk, align 4
  %9 = icmp ult i32 %7, %6
  br i1 %9, label %10, label %75

10:                                               ; preds = %3
  %11 = call i32 @__cq_mem()
  %12 = icmp sgt i32 %2, 0
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  br i1 %12, label %14, label %16

14:                                               ; preds = %10
  %15 = zext nneg i32 %2 to i64
  br label %24

16:                                               ; preds = %10, %50
  %17 = phi i32 [ poison, %10 ], [ %25, %50 ]
  %18 = phi i32 [ poison, %10 ], [ %26, %50 ]
  %ran = phi i1 [ false, %10 ], [ true, %50 ]
  %19 = phi i32 [ %13, %10 ], [ %46, %50 ]
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %19, i32 %20)
  call void @cqrt_free(i32 %13)
  br i1 %ran, label %52, label %74

21:                                               ; preds = %74
  %22 = load i32, ptr @__cq_act_walk, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_walk, align 4
  ret i32 %20

24:                                               ; preds = %14
  %25 = call i32 @cqrt_alloc_i64(i64 0)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  br label %28

27:                                               ; preds = %28
  br label %50

28:                                               ; preds = %28, %24
  %from = phi i32 [ 0, %28 ], [ 1, %24 ]
  %29 = phi i64 [ 0, %24 ], [ %43, %28 ]
  %30 = phi i32 [ %25, %24 ], [ %45, %28 ]
  %trip = phi i32 [ %0, %24 ], [ %35, %28 ]
  %xcap = phi i32 [ %26, %24 ], [ %xcap, %28 ]
  call void @cqrt_push(i32 %from)
  %31 = getelementptr inbounds i64, ptr %1, i64 %29
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %32)
  %33 = call i32 @__cq_q_bump_0_ctl(i32 %32, ptr %31)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %32)
  call void @cqrt_free(i32 %32)
  %34 = call i32 @cq_template_icmp_eq_i64_hl(i32 %33, i64 0)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %35)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %34, i32 %37)
  call void @cqrt_and_i1(i32 %0, i32 %37, i32 %36)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %36, i32 %38)
  call void @cqrt_and_i1(i32 %trip, i32 %36, i32 %35)
  call void @cqrt_abort_i1(i32 %38)
  %39 = ptrtoint ptr %31 to i64
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %40)
  %41 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %40, i32 %11, i64 %39)
  %42 = call i32 @cq_template_add_i64(i32 %41, i32 %30)
  %43 = add nuw nsw i64 %29, 1
  %44 = icmp eq i64 %43, %15
  %45 = call i32 @cq_template_select_i64(i32 %35, i32 %42, i32 %30)
  %46 = call i32 @cq_template_select_i64(i32 %35, i32 %42, i32 %xcap)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %40)
  %47 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %47)
  %48 = lshr i64 %39, 32
  %49 = trunc i64 %48 to i32
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  br i1 %44, label %27, label %28

50:                                               ; preds = %27
  br label %16

51:                                               ; preds = %52
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  br label %74

52:                                               ; preds = %16, %52
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = zext i32 %58 to i64
  %60 = shl i64 %59, 32
  %61 = or i64 0, %60
  %62 = call i32 @cqrt_pop()
  %63 = zext i32 %62 to i64
  %64 = or i64 %61, %63
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  %67 = call i32 @cqrt_pop()
  %68 = call i32 @cqrt_pop()
  %69 = call i32 @cqrt_pop()
  %70 = call i32 @cqrt_pop()
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %72, i32 %71, i32 %70, i32 %69)
  call void @cqrt_free(i32 %72)
  call void @cq_template_select_i64_unc(i32 %68, i32 %71, i32 %70, i32 %67)
  call void @cqrt_free(i32 %68)
  call void @cq_template_add_i64_unc(i32 %70, i32 %66, i32 %67)
  call void @cqrt_free(i32 %70)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %66, i32 %65, i32 %11, i64 %64)
  call void @cqrt_and_i1(i32 %57, i32 %0, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %57, i32 %56, i32 %71)
  call void @cqrt_xor_i1(i32 %57, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %0, i32 %55, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_xor_i1(i32 %54, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %54, i32 %53, i64 0)
  call void @cqrt_free(i32 %54)
  %73 = call i32 @cqrt_pop()
  switch i32 %73, label %52 [
    i32 1, label %51
  ]

74:                                               ; preds = %51, %16
  br label %21

75:                                               ; preds = %3
  %76 = call i32 @cqrt_alloc_i64(i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %77)
  %78 = load i32, ptr @__cq_act_walk, align 4
  %79 = add i32 %78, -1
  store i32 %79, ptr @__cq_act_walk, align 4
  ret i32 %76
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_swap_i64_hl_controlled(i32, i32, i64, i32)

define i32 @__cq_q_walk_00_ctl_pure(i32 %0, ptr %1, i32 %2) local_unnamed_addr {
  %4 = load i32, ptr @__cq_k, align 4
  %5 = icmp eq i32 %4, -1
  %6 = select i1 %5, i32 4, i32 %4
  %7 = load i32, ptr @__cq_act_walk, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_walk, align 4
  %9 = icmp ult i32 %7, %6
  br i1 %9, label %10, label %75

10:                                               ; preds = %3
  %11 = call i32 @__cq_mem()
  %12 = icmp sgt i32 %2, 0
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  br i1 %12, label %14, label %16

14:                                               ; preds = %10
  %15 = zext nneg i32 %2 to i64
  br label %24

16:                                               ; preds = %10, %50
  %17 = phi i32 [ poison, %10 ], [ %25, %50 ]
  %18 = phi i32 [ poison, %10 ], [ %26, %50 ]
  %ran = phi i1 [ false, %10 ], [ true, %50 ]
  %19 = phi i32 [ %13, %10 ], [ %46, %50 ]
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %19, i32 %20)
  call void @cqrt_free(i32 %13)
  br i1 %ran, label %52, label %74

21:                                               ; preds = %74
  %22 = load i32, ptr @__cq_act_walk, align 4
  %23 = add i32 %22, -1
  store i32 %23, ptr @__cq_act_walk, align 4
  ret i32 %20

24:                                               ; preds = %14
  %25 = call i32 @cqrt_alloc_i64(i64 0)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  br label %28

27:                                               ; preds = %28
  br label %50

28:                                               ; preds = %28, %24
  %from = phi i32 [ 0, %28 ], [ 1, %24 ]
  %29 = phi i64 [ 0, %24 ], [ %43, %28 ]
  %30 = phi i32 [ %25, %24 ], [ %45, %28 ]
  %trip = phi i32 [ %0, %24 ], [ %35, %28 ]
  %xcap = phi i32 [ %26, %24 ], [ %xcap, %28 ]
  call void @cqrt_push(i32 %from)
  %31 = getelementptr inbounds i64, ptr %1, i64 %29
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %32)
  %33 = call i32 @__cq_q_bump_0_ctl(i32 %32, ptr %31)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %32)
  call void @cqrt_free(i32 %32)
  %34 = call i32 @cq_template_icmp_eq_i64_hl(i32 %33, i64 0)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %35)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %34, i32 %37)
  call void @cqrt_and_i1(i32 %0, i32 %37, i32 %36)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %36, i32 %38)
  call void @cqrt_and_i1(i32 %trip, i32 %36, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_and_i1(i32 %trip, i32 %36, i32 %35)
  %39 = ptrtoint ptr %31 to i64
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %0, i32 %40)
  %41 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %40, i32 %11, i64 %39)
  %42 = call i32 @cq_template_add_i64(i32 %41, i32 %30)
  %43 = add nuw nsw i64 %29, 1
  %44 = icmp eq i64 %43, %15
  %45 = call i32 @cq_template_select_i64(i32 %35, i32 %42, i32 %30)
  %46 = call i32 @cq_template_select_i64(i32 %35, i32 %42, i32 %xcap)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %40)
  %47 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %47)
  %48 = lshr i64 %39, 32
  %49 = trunc i64 %48 to i32
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %33)
  br i1 %44, label %27, label %28

50:                                               ; preds = %27
  br label %16

51:                                               ; preds = %52
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  br label %74

52:                                               ; preds = %16, %52
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  %56 = call i32 @cqrt_pop()
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = zext i32 %58 to i64
  %60 = shl i64 %59, 32
  %61 = or i64 0, %60
  %62 = call i32 @cqrt_pop()
  %63 = zext i32 %62 to i64
  %64 = or i64 %61, %63
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  %67 = call i32 @cqrt_pop()
  %68 = call i32 @cqrt_pop()
  %69 = call i32 @cqrt_pop()
  %70 = call i32 @cqrt_pop()
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %72, i32 %71, i32 %70, i32 %69)
  call void @cqrt_free(i32 %72)
  call void @cq_template_select_i64_unc(i32 %68, i32 %71, i32 %70, i32 %67)
  call void @cqrt_free(i32 %68)
  call void @cq_template_add_i64_unc(i32 %70, i32 %66, i32 %67)
  call void @cqrt_free(i32 %70)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %66, i32 %65, i32 %11, i64 %64)
  call void @cqrt_and_i1(i32 %57, i32 %0, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %57, i32 %56, i32 %71)
  call void @cqrt_xor_i1(i32 %57, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %0, i32 %55, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_xor_i1(i32 %54, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %54, i32 %53, i64 0)
  call void @cqrt_free(i32 %54)
  %73 = call i32 @cqrt_pop()
  switch i32 %73, label %52 [
    i32 1, label %51
  ]

74:                                               ; preds = %51, %16
  br label %21

75:                                               ; preds = %3
  %76 = call i32 @cqrt_alloc_i64(i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %77)
  %78 = load i32, ptr @__cq_act_walk, align 4
  %79 = add i32 %78, -1
  store i32 %79, ptr @__cq_act_walk, align 4
  ret i32 %76
}

define i32 @__cq_q_walk_00_pure(ptr %0, i32 %1) local_unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = icmp sgt i32 %1, 0
  %5 = call i32 @cqrt_alloc_i64(i64 0)
  br i1 %4, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  br label %15

8:                                                ; preds = %2, %39
  %9 = phi i32 [ poison, %2 ], [ %16, %39 ]
  %10 = phi i32 [ poison, %2 ], [ %17, %39 ]
  %11 = phi i32 [ poison, %2 ], [ %18, %39 ]
  %ran = phi i1 [ false, %2 ], [ true, %39 ]
  %12 = phi i32 [ %5, %2 ], [ %35, %39 ]
  %13 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %12, i32 %13)
  call void @cqrt_free(i32 %5)
  br i1 %ran, label %41, label %61

14:                                               ; preds = %61
  ret i32 %13

15:                                               ; preds = %6
  %16 = call i32 @cqrt_alloc_i1(i1 true)
  %17 = call i32 @cqrt_alloc_i64(i64 0)
  %18 = call i32 @cqrt_alloc_i64(i64 0)
  br label %20

19:                                               ; preds = %20
  br label %39

20:                                               ; preds = %20, %15
  %from = phi i32 [ 0, %20 ], [ 1, %15 ]
  %21 = phi i64 [ 0, %15 ], [ %32, %20 ]
  %22 = phi i32 [ %17, %15 ], [ %34, %20 ]
  %trip = phi i32 [ %16, %15 ], [ %26, %20 ]
  %xcap = phi i32 [ %18, %15 ], [ %xcap, %20 ]
  call void @cqrt_push(i32 %from)
  %23 = getelementptr inbounds i64, ptr %0, i64 %21
  %24 = call i32 @__cq_q_bump_0_ctl(i32 %trip, ptr %23)
  %25 = call i32 @cq_template_icmp_eq_i64_hl(i32 %24, i64 0)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %26)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %25, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %27, i32 %28)
  call void @cqrt_and_i1(i32 %trip, i32 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %trip, i32 %27, i32 %26)
  %29 = ptrtoint ptr %23 to i64
  %30 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %trip, i32 %3, i64 %29)
  %31 = call i32 @cq_template_add_i64(i32 %30, i32 %22)
  %32 = add nuw nsw i64 %21, 1
  %33 = icmp eq i64 %32, %7
  %34 = call i32 @cq_template_select_i64(i32 %26, i32 %31, i32 %22)
  %35 = call i32 @cq_template_select_i64(i32 %26, i32 %31, i32 %xcap)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %trip)
  %36 = trunc i64 %29 to i32
  call void @cqrt_push(i32 %36)
  %37 = lshr i64 %29, 32
  %38 = trunc i64 %37 to i32
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %24)
  br i1 %33, label %19, label %20

39:                                               ; preds = %19
  br label %8

40:                                               ; preds = %41
  call void @cqrt_free(i32 %11)
  call void @cqrt_free(i32 %10)
  call void @cqrt_free(i32 %9)
  br label %61

41:                                               ; preds = %8, %41
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = zext i32 %45 to i64
  %47 = shl i64 %46, 32
  %48 = or i64 0, %47
  %49 = call i32 @cqrt_pop()
  %50 = zext i32 %49 to i64
  %51 = or i64 %48, %50
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
  call void @cq_template_select_i64_unc(i32 %55, i32 %58, i32 %57, i32 %54)
  call void @cqrt_free(i32 %55)
  call void @cq_template_add_i64_unc(i32 %57, i32 %53, i32 %54)
  call void @cqrt_free(i32 %57)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %53, i32 %52, i32 %3, i64 %51)
  call void @cqrt_and_i1(i32 %52, i32 %44, i32 %58)
  call void @cqrt_xor_i1(i32 %52, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_xor_i1(i32 %43, i32 %44)
  call void @cqrt_not_i1(i32 %44)
  call void @cqrt_free(i32 %44)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %42, i64 0)
  call void @cqrt_free(i32 %43)
  %60 = call i32 @cqrt_pop()
  switch i32 %60, label %41 [
    i32 1, label %40
  ]

61:                                               ; preds = %40, %8
  br label %14
}

define internal i32 @__cq_q_main_v_t_pure(i32 %0) {
  %2 = load i32, ptr @__cq_k, align 4
  store i32 %0, ptr @__cq_k, align 4
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 48, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = call i32 @cqrt_alloc_i8(i8 0)
  br label %7

7:                                                ; preds = %7, %1
  %8 = phi i64 [ 0, %1 ], [ %10, %7 ]
  %9 = add i64 %5, %8
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %9, i32 %6)
  %10 = add nuw i64 %8, 1
  %11 = icmp eq i64 %10, 48
  br i1 %11, label %12, label %7

12:                                               ; preds = %7
  %13 = ptrtoint ptr %4 to i64
  %14 = call i32 @cqrt_alloc_i64(i64 1)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %13, i32 %14)
  %15 = getelementptr inbounds i8, ptr %4, i64 8
  %16 = ptrtoint ptr %15 to i64
  %17 = call i32 @cqrt_alloc_i64(i64 2)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %16, i32 %17)
  %18 = getelementptr inbounds i8, ptr %4, i64 16
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_alloc_i64(i64 3)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %19, i32 %20)
  %21 = getelementptr inbounds i8, ptr %4, i64 24
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cqrt_alloc_i64(i64 4)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %22, i32 %23)
  %24 = getelementptr inbounds i8, ptr %4, i64 32
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_alloc_i64(i64 5)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %25, i32 %26)
  %27 = getelementptr inbounds i8, ptr %4, i64 40
  %28 = ptrtoint ptr %27 to i64
  %29 = call i32 @cqrt_alloc_i64(i64 6)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %28, i32 %29)
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8(i32 %30, double 0x3FF921FB54442D18)
  %31 = call i32 @cq_template_and_i8_hl(i32 %30, i8 7)
  %32 = call i32 @cq_template_add_i8_hl(i32 %31, i8 3)
  %33 = call i32 @cq_template_zext_i8_to_i64(i32 %32)
  call void @cq_template_add_i8_hl_unc(i32 %32, i32 %31, i8 3)
  call void @cqrt_free(i32 %32)
  call void @cq_template_and_i8_hl_unc(i32 %31, i32 %30, i8 7)
  call void @cqrt_free(i32 %31)
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %19, i32 %33)
  %34 = call i32 @__cq_q_walk_00_pure(ptr %4, i32 4)
  %35 = call i32 @cq_template_trunc_i64_to_i32(i32 %34)
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %35, i32 %36)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %35, i32 %34)
  call void @cqrt_free(i32 %35)
  %37 = call i32 @cqrt_measure_i32(i32 %36), !cq.measure !6
  %38 = call i32 @cqrt_alloc_i32(i32 %37)
  store i32 %2, ptr @__cq_k, align 4
  ret i32 %38
}

define internal i32 @__cq_q_walk_11_t_ctl_pure(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_walk, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_walk, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %75

9:                                                ; preds = %4
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 0)
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %2)
  br label %13

13:                                               ; preds = %9
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %14)
  %15 = call i32 @cqrt_alloc_i64(i64 0)
  %16 = call i32 @llvm.umin.i32(i32 %3, i32 2147483647)
  %17 = icmp ult i32 %3, 2147483647
  %18 = icmp ult i32 0, %16
  br i1 %18, label %19, label %45

19:                                               ; preds = %19, %13
  %from = phi i32 [ 0, %19 ], [ 1, %13 ]
  %20 = phi i32 [ 0, %13 ], [ %40, %19 ]
  %21 = phi i32 [ %14, %13 ], [ %36, %19 ]
  %22 = phi i64 [ 0, %13 ], [ %31, %19 ]
  %23 = phi i32 [ %15, %13 ], [ %37, %19 ]
  call void @cqrt_push(i32 %from)
  %24 = mul i64 %22, 8
  %25 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %24)
  %26 = call i32 @__cq_q_bump_1_ctl(i32 %21, i32 %25)
  %27 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %27, i32 %28)
  %29 = call i32 @cqrt_qram_load_i64_controlled(i32 %28, i32 %10, i32 %25)
  %30 = call i32 @cq_template_add_i64(i32 %29, i32 %23)
  %31 = add i64 %22, 1
  %32 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_xor_i1(i32 %27, i32 %33)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %33, i32 %34)
  call void @cqrt_and_i1(i32 %21, i32 %33, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %27, i32 %33)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_free(i32 %33)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %27, i32 %35)
  call void @cqrt_and_i1(i32 %27, i32 %32, i32 %35)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %35, i32 %36)
  %37 = call i32 @cq_template_select_i64(i32 %21, i32 %30, i32 %23)
  call void @cq_template_add_i64_unc(i32 %30, i32 %29, i32 %23)
  call void @cqrt_free(i32 %30)
  %38 = call i32 @cq_template_sub_i64(i32 %37, i32 %29)
  %39 = call i32 @cq_template_select_i64(i32 %21, i32 %38, i32 %37)
  call void @cqrt_copy_i64(i32 %39, i32 %23)
  call void @cq_template_select_i64_unc(i32 %39, i32 %21, i32 %38, i32 %37)
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %23)
  call void @cq_template_sub_i64_unc(i32 %38, i32 %37, i32 %29)
  call void @cqrt_free(i32 %38)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %29, i32 %28, i32 %10, i32 %25)
  call void @cqrt_free(i32 %29)
  call void @cqrt_and_i1(i32 %21, i32 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i64_hl_unc(i32 %25, i32 %1, i64 %24)
  call void @cqrt_free(i32 %25)
  %40 = add i32 %20, 1
  %41 = icmp ult i32 %40, %16
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %32)
  %42 = trunc i64 %31 to i32
  call void @cqrt_push(i32 %42)
  %43 = lshr i64 %31, 32
  %44 = trunc i64 %43 to i32
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %26)
  br i1 %41, label %19, label %45

45:                                               ; preds = %19, %13
  %46 = phi i32 [ 0, %13 ], [ 1, %19 ]
  %47 = phi i64 [ 0, %13 ], [ %31, %19 ]
  %48 = phi i32 [ %15, %13 ], [ %37, %19 ]
  %49 = phi i32 [ %14, %13 ], [ %36, %19 ]
  br i1 %17, label %50, label %52

50:                                               ; preds = %45
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %49, i32 %51)
  br label %53

52:                                               ; preds = %45
  br label %53

53:                                               ; preds = %50, %52
  br label %74

54:                                               ; preds = %74, %59
  call void @cqrt_and_i1(i32 %0, i32 %11, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %2)
  call void @cqrt_free(i32 %12)
  %55 = call i32 @cq_template_select_i64_hl(i32 %11, i32 %48, i64 0)
  %56 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %55, i32 %56)
  call void @cq_template_select_i64_hl_unc(i32 %55, i32 %11, i32 %48, i64 0)
  call void @cqrt_free(i32 %55)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %2, i32 0)
  call void @cqrt_free(i32 %11)
  %57 = load i32, ptr @__cq_act_walk, align 4
  %58 = add i32 %57, -1
  store i32 %58, ptr @__cq_act_walk, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %56

59:                                               ; preds = %74, %59
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = zext i32 %61 to i64
  %63 = shl i64 %62, 32
  %64 = or i64 0, %63
  %65 = call i32 @cqrt_pop()
  %66 = zext i32 %65 to i64
  %67 = or i64 %64, %66
  %68 = call i32 @cqrt_pop()
  %69 = call i32 @cqrt_pop()
  %70 = call i32 @cqrt_pop()
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %72, i32 %71, i32 %70)
  call void @cqrt_free(i32 %70)
  call void @cqrt_and_i1(i32 %69, i32 %68, i32 %71)
  call void @cqrt_xor_i1(i32 %69, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %68, i32 %12, i64 %67)
  call void @cqrt_free(i32 %68)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %69, i32 %60, i64 0)
  call void @cqrt_free(i32 %69)
  %73 = call i32 @cqrt_pop()
  switch i32 %73, label %59 [
    i32 1, label %54
  ]

74:                                               ; preds = %53
  switch i32 %46, label %54 [
    i32 1, label %59
  ]

75:                                               ; preds = %4
  %76 = call i32 @cqrt_alloc_i64(i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %77)
  %78 = load i32, ptr @__cq_act_walk, align 4
  %79 = add i32 %78, -1
  store i32 %79, ptr @__cq_act_walk, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %76
}

define internal i32 @__cq_q_walk_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 0)
  %7 = call i32 @cq_template_zext_i32_to_i64(i32 %1)
  br label %8

8:                                                ; preds = %3
  %9 = call i32 @cqrt_alloc_i64(i64 0)
  %10 = call i32 @llvm.umin.i32(i32 %2, i32 2147483647)
  %11 = icmp ult i32 %2, 2147483647
  %12 = icmp ult i32 0, %10
  br i1 %12, label %13, label %39

13:                                               ; preds = %13, %8
  %from = phi i32 [ 0, %13 ], [ 1, %8 ]
  %14 = phi i32 [ 0, %8 ], [ %34, %13 ]
  %15 = phi i32 [ %6, %8 ], [ %30, %13 ]
  %16 = phi i64 [ 0, %8 ], [ %25, %13 ]
  %17 = phi i32 [ %9, %8 ], [ %31, %13 ]
  call void @cqrt_push(i32 %from)
  %18 = mul i64 %16, 8
  %19 = call i32 @cq_template_add_i64_hl(i32 %0, i64 %18)
  %20 = call i32 @__cq_q_bump_1_ctl(i32 %15, i32 %19)
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  %23 = call i32 @cqrt_qram_load_i64_controlled(i32 %22, i32 %5, i32 %19)
  %24 = call i32 @cq_template_add_i64(i32 %23, i32 %17)
  %25 = add i64 %16, 1
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %7, i64 %25)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_xor_i1(i32 %21, i32 %27)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %27, i32 %28)
  call void @cqrt_and_i1(i32 %15, i32 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_xor_i1(i32 %21, i32 %27)
  call void @cqrt_not_i1(i32 %27)
  call void @cqrt_free(i32 %27)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %21, i32 %29)
  call void @cqrt_and_i1(i32 %21, i32 %26, i32 %29)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %29, i32 %30)
  %31 = call i32 @cq_template_select_i64(i32 %15, i32 %24, i32 %17)
  call void @cq_template_add_i64_unc(i32 %24, i32 %23, i32 %17)
  call void @cqrt_free(i32 %24)
  %32 = call i32 @cq_template_sub_i64(i32 %31, i32 %23)
  %33 = call i32 @cq_template_select_i64(i32 %15, i32 %32, i32 %31)
  call void @cqrt_copy_i64(i32 %33, i32 %17)
  call void @cq_template_select_i64_unc(i32 %33, i32 %15, i32 %32, i32 %31)
  call void @cqrt_free(i32 %33)
  call void @cqrt_free(i32 %17)
  call void @cq_template_sub_i64_unc(i32 %32, i32 %31, i32 %23)
  call void @cqrt_free(i32 %32)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %23, i32 %22, i32 %5, i32 %19)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %0, i64 %18)
  call void @cqrt_free(i32 %19)
  %34 = add i32 %14, 1
  %35 = icmp ult i32 %34, %10
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %26)
  %36 = trunc i64 %25 to i32
  call void @cqrt_push(i32 %36)
  %37 = lshr i64 %25, 32
  %38 = trunc i64 %37 to i32
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %20)
  br i1 %35, label %13, label %39

39:                                               ; preds = %13, %8
  %40 = phi i32 [ 0, %8 ], [ 1, %13 ]
  %41 = phi i64 [ 0, %8 ], [ %25, %13 ]
  %42 = phi i32 [ %9, %8 ], [ %31, %13 ]
  %43 = phi i32 [ %6, %8 ], [ %30, %13 ]
  br i1 %11, label %44, label %46

44:                                               ; preds = %39
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %43, i32 %45)
  br label %47

46:                                               ; preds = %39
  br label %47

47:                                               ; preds = %44, %46
  br label %66

48:                                               ; preds = %66, %51
  call void @cq_template_zext_i32_to_i64_unc(i32 %7, i32 %1)
  call void @cqrt_free(i32 %7)
  %49 = call i32 @cq_template_select_i64_hl(i32 %6, i32 %42, i64 0)
  %50 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %49, i32 %50)
  call void @cq_template_select_i64_hl_unc(i32 %49, i32 %6, i32 %42, i64 0)
  call void @cqrt_free(i32 %49)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %1, i32 0)
  call void @cqrt_free(i32 %6)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %50

51:                                               ; preds = %66, %51
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = zext i32 %53 to i64
  %55 = shl i64 %54, 32
  %56 = or i64 0, %55
  %57 = call i32 @cqrt_pop()
  %58 = zext i32 %57 to i64
  %59 = or i64 %56, %58
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %64, i32 %63, i32 %62)
  call void @cqrt_free(i32 %62)
  call void @cqrt_and_i1(i32 %61, i32 %60, i32 %63)
  call void @cqrt_xor_i1(i32 %61, i32 %63)
  call void @cqrt_free(i32 %63)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %60, i32 %7, i64 %59)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %61, i32 %52, i64 0)
  call void @cqrt_free(i32 %61)
  %65 = call i32 @cqrt_pop()
  switch i32 %65, label %51 [
    i32 1, label %48
  ]

66:                                               ; preds = %47
  switch i32 %40, label %48 [
    i32 1, label %51
  ]
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @bump, ptr @.cq.sig, ptr @__cq_q_bump_1_t, ptr @__cq_q_bump_1_t_ctl, ptr @__cq_q_bump_1_t_unc, ptr @__cq_q_bump_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @walk, ptr @.cq.sig.1, ptr @__cq_q_walk_11_t, ptr @__cq_q_walk_11_t_ctl, ptr @__cq_q_walk_11_t_unc, ptr @__cq_q_walk_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @main, ptr @.cq.sig.2, ptr @__cq_q_main_v_t, ptr @__cq_q_main_v_t_ctl, ptr @__cq_q_main_v_t_unc, ptr @__cq_q_main_v_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_bump_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_bump_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_bump, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_bump, align 4
  %8 = load i32, ptr @__cq_act_bump, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_bump, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_walk_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_walk_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_walk, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_walk, align 4
  %9 = load i32, ptr @__cq_act_walk, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_walk, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_main_v_t_unc(i32 %0, i32 %1) {
  %3 = load i32, ptr @__cq_k, align 4
  store i32 %1, ptr @__cq_k, align 4
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %2
  %6 = phi i32 [ %4, %2 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  store i32 %3, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_main_v_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = load i32, ptr @__cq_act_main, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_main, align 4
  %7 = load i32, ptr @__cq_act_main, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_main, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %3
  %11 = phi i32 [ %9, %3 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  store i32 %4, ptr @__cq_k, align 4
  ret void
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
