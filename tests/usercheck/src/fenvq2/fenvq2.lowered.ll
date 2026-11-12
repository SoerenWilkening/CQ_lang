; ModuleID = 'tests/usercheck/src/fenvq2/fenvq2.O1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define noundef i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = call i32 @__cq_mem()
  %3 = call ptr @__cq_alloc(i64 32, i64 4)
  %4 = call ptr @__cq_alloc(i64 2, i64 2)
  %5 = ptrtoint ptr %4 to i64
  %6 = call i32 @cqrt_alloc_i16(i16 16)
  call void @cqrt_qram_store_i16_hl(i32 %2, i64 %5, i32 %6)
  %7 = ptrtoint ptr %3 to i64
  %8 = call i32 @cqrt_alloc_i8(i8 0)
  br label %9

9:                                                ; preds = %9, %1
  %10 = phi i64 [ 0, %1 ], [ %12, %9 ]
  %11 = add i64 %7, %10
  call void @cqrt_qram_store_i8_hl(i32 %2, i64 %11, i32 %8)
  %12 = add nuw i64 %10, 1
  %13 = icmp eq i64 %12, 32
  br i1 %13, label %14, label %9

14:                                               ; preds = %9
  %15 = and i32 %0, 1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %26

17:                                               ; preds = %26, %14
  %18 = ptrtoint ptr %3 to i64
  %19 = call i32 @fegetenv(ptr %3)
  %20 = ptrtoint ptr %4 to i64
  %21 = call i32 @fegetexceptflag(ptr %4, i32 61)
  %22 = call i32 @cqrt_qram_load_i8_hl(i32 %2, i64 %18)
  %23 = call i8 @cqrt_measure_i8(i32 %22), !cq.measure !6
  %24 = call i32 @cqrt_qram_load_i8_hl(i32 %2, i64 %20)
  %25 = call i8 @cqrt_measure_i8(i32 %24), !cq.measure !6
  ret i32 0

26:                                               ; preds = %14
  %27 = ptrtoint ptr %3 to i64
  %28 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl(i32 %2, i64 %27, i32 %28)
  call void @cqrt_ry_i8(i32 %28, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl(i32 %2, i64 %27, i32 %28)
  call void @cqrt_free(i32 %28)
  %29 = ptrtoint ptr %4 to i64
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl(i32 %2, i64 %29, i32 %30)
  call void @cqrt_ry_i8(i32 %30, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl(i32 %2, i64 %29, i32 %30)
  call void @cqrt_free(i32 %30)
  br label %17
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @fetestexcept(i32 noundef %0) local_unnamed_addr #3 {
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define noundef i32 @fegetexceptflag(ptr nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #4 {
  store i16 0, ptr %0, align 2, !tbaa !7
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @fegetenv(ptr nocapture noundef readnone %0) local_unnamed_addr #3 {
  ret i32 0
}

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i16(i16)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i16_hl(i32, i64, i32)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare void @cqrt_qram_swap_i8_hl(i32, i64, i32)

declare void @cqrt_ry_i8(i32, double)

declare void @cqrt_free(i32)

declare i32 @cqrt_qram_load_i8_hl(i32, i64)

declare i8 @cqrt_measure_i8(i32)

define internal i32 @__cq_q_f_1_t(i32 %0, i32 %1) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 32, i64 4)
  %5 = call ptr @__cq_alloc(i64 2, i64 2)
  %6 = ptrtoint ptr %5 to i64
  %7 = call i32 @cqrt_alloc_i16(i16 16)
  call void @cqrt_qram_store_i16_hl(i32 %3, i64 %6, i32 %7)
  %8 = ptrtoint ptr %4 to i64
  %9 = call i32 @cqrt_alloc_i8(i8 0)
  br label %10

10:                                               ; preds = %10, %2
  %11 = phi i64 [ 0, %2 ], [ %13, %10 ]
  %12 = add i64 %8, %11
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %12, i32 %9)
  %13 = add nuw i64 %11, 1
  %14 = icmp eq i64 %13, 32
  br i1 %14, label %15, label %10

15:                                               ; preds = %10
  %16 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)
  %17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %16, i32 0)
  %18 = ptrtoint ptr %4 to i64
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %19)
  call void @cqrt_xor_i1(i32 %17, i32 %19)
  %20 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %19, i32 %3, i64 %18, i32 %20)
  call void @cqrt_ry_i8_controlled(i32 %19, i32 %20, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %19, i32 %3, i64 %18, i32 %20)
  call void @cqrt_xor_i1(i32 %17, i32 %19)
  call void @cqrt_not_i1(i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_free(i32 %20)
  %21 = ptrtoint ptr %5 to i64
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_xor_i1(i32 %17, i32 %22)
  %23 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %22, i32 %3, i64 %21, i32 %23)
  call void @cqrt_ry_i8_controlled(i32 %22, i32 %23, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %22, i32 %3, i64 %21, i32 %23)
  call void @cqrt_xor_i1(i32 %17, i32 %22)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %17, i32 %16, i32 0)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %0, i32 1)
  call void @cqrt_free(i32 %16)
  call void @cqrt_free(i32 %23)
  %24 = call i32 @fegetenv(ptr %4)
  %25 = call i32 @fegetexceptflag(ptr %5, i32 61)
  %26 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %18)
  %27 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %26, i32 %27)
  call void @cqrt_qram_load_i8_hl_unc(i32 %26, i32 %3, i64 %18)
  call void @cqrt_free(i32 %26)
  %28 = call i8 @cqrt_measure_i8(i32 %27), !cq.measure !6
  %29 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %21)
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %29, i32 %30)
  call void @cqrt_qram_load_i8_hl_unc(i32 %29, i32 %3, i64 %21)
  call void @cqrt_free(i32 %29)
  %31 = call i8 @cqrt_measure_i8(i32 %30), !cq.measure !6
  %32 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %32)
  %33 = call i32 @cqrt_alloc_i32(i32 0)
  ret i32 %33
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_qram_swap_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_copy_i8(i32, i32)

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

declare void @cqrt_push(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_f, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_f, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %80

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 32, i64 4)
  %10 = call ptr @__cq_alloc(i64 2, i64 2)
  %11 = ptrtoint ptr %10 to i64
  %12 = call i32 @cqrt_alloc_i16(i16 16)
  call void @cqrt_qram_store_i16_hl_controlled(i32 %0, i32 %8, i64 %11, i32 %12)
  %13 = ptrtoint ptr %9 to i64
  %14 = call i32 @cqrt_alloc_i8(i8 0)
  br label %15

15:                                               ; preds = %15, %7
  %16 = phi i64 [ 0, %7 ], [ %18, %15 ]
  %17 = add i64 %13, %16
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %17, i32 %14)
  %18 = add nuw i64 %16, 1
  %19 = icmp eq i64 %18, 32
  br i1 %19, label %20, label %15

20:                                               ; preds = %15
  %21 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %21, i32 0)
  %23 = ptrtoint ptr %9 to i64
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_xor_i1(i32 %22, i32 %25)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  %26 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %24, i32 %8, i64 %23, i32 %26)
  call void @cqrt_ry_i8_controlled(i32 %24, i32 %26, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %24, i32 %8, i64 %23, i32 %26)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_xor_i1(i32 %22, i32 %25)
  call void @cqrt_not_i1(i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cqrt_free(i32 %26)
  %27 = ptrtoint ptr %10 to i64
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_xor_i1(i32 %22, i32 %29)
  call void @cqrt_and_i1(i32 %0, i32 %29, i32 %28)
  %30 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %28, i32 %8, i64 %27, i32 %30)
  call void @cqrt_ry_i8_controlled(i32 %28, i32 %30, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %28, i32 %8, i64 %27, i32 %30)
  call void @cqrt_and_i1(i32 %0, i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_xor_i1(i32 %22, i32 %29)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %21, i32 0)
  call void @cqrt_free(i32 %22)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %1, i32 1)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %30)
  %31 = call ptr @__cq_alloc(i64 16, i64 16)
  %32 = call i32 @fegetenv(ptr %31)
  %33 = ptrtoint ptr %31 to i64
  br label %34

34:                                               ; preds = %34, %20
  %35 = phi i64 [ 0, %20 ], [ %38, %34 ]
  %36 = add i64 %33, %35
  %37 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %36)
  call void @cqrt_push(i32 %37)
  %38 = add nuw i64 %35, 1
  %39 = icmp eq i64 %38, 16
  br i1 %39, label %40, label %34

40:                                               ; preds = %34
  br label %41

41:                                               ; preds = %40
  br label %42

42:                                               ; preds = %42, %41
  %43 = phi i64 [ 15, %41 ], [ %46, %42 ]
  %44 = call i32 @cqrt_pop()
  %45 = add i64 %23, %43
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %45, i32 %44)
  %46 = add nsw i64 %43, -1
  %47 = icmp eq i64 %43, 0
  br i1 %47, label %48, label %42

48:                                               ; preds = %42
  %49 = ptrtoint ptr %10 to i64
  %50 = call ptr @__cq_alloc(i64 2, i64 16)
  %51 = call i32 @fegetexceptflag(ptr %50, i32 61)
  %52 = ptrtoint ptr %50 to i64
  br label %53

53:                                               ; preds = %53, %48
  %54 = phi i64 [ 0, %48 ], [ %57, %53 ]
  %55 = add i64 %52, %54
  %56 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %55)
  call void @cqrt_push(i32 %56)
  %57 = add nuw i64 %54, 1
  %58 = icmp eq i64 %57, 2
  br i1 %58, label %59, label %53

59:                                               ; preds = %53
  br label %60

60:                                               ; preds = %59
  br label %61

61:                                               ; preds = %61, %60
  %62 = phi i64 [ 1, %60 ], [ %65, %61 ]
  %63 = call i32 @cqrt_pop()
  %64 = add i64 %49, %62
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %64, i32 %63)
  %65 = add nsw i64 %62, -1
  %66 = icmp eq i64 %62, 0
  br i1 %66, label %67, label %61

67:                                               ; preds = %61
  %68 = ptrtoint ptr %9 to i64
  %69 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %68)
  %70 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8_controlled(i32 %0, i32 %69, i32 %70)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %69, i32 %0, i32 %8, i64 %68)
  call void @cqrt_free(i32 %69)
  %71 = call i8 @cqrt_measure_i8(i32 %70), !cq.measure !6
  %72 = ptrtoint ptr %10 to i64
  %73 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %8, i64 %72)
  %74 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8_controlled(i32 %0, i32 %73, i32 %74)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %73, i32 %0, i32 %8, i64 %72)
  call void @cqrt_free(i32 %73)
  %75 = call i8 @cqrt_measure_i8(i32 %74), !cq.measure !6
  %76 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %76)
  %77 = call i32 @cqrt_alloc_i32(i32 0)
  %78 = load i32, ptr @__cq_act_f, align 4
  %79 = add i32 %78, -1
  store i32 %79, ptr @__cq_act_f, align 4
  ret i32 %77

80:                                               ; preds = %3
  %81 = call i32 @cqrt_alloc_i32(i32 0)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %82)
  call void @cqrt_push(i32 0)
  %83 = load i32, ptr @__cq_act_f, align 4
  %84 = add i32 %83, -1
  store i32 %84, ptr @__cq_act_f, align 4
  ret i32 %81
}

declare void @cqrt_qram_store_i16_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)

declare i32 @cqrt_pop()

declare void @cqrt_copy_i8_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1_t, ptr @__cq_q_f_1_t_ctl, ptr @__cq_q_f_1_t_unc, ptr @__cq_q_f_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %3
  %6 = phi i32 [ %4, %3 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  ret void
}

define internal void @__cq_q_f_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %4
  %11 = phi i32 [ %9, %4 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{}
!7 = !{!8, !8, i64 0}
!8 = !{!"short", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
