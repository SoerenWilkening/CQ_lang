; ModuleID = 'tests/usercheck/src/leak/m1.O1.ll'
source_filename = "m1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_m1 = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [49 x i8] c"i32 (i32, double, i32, i32, double, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @m1(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 4, i64 4)
  %10 = call ptr @__cq_alloc(i64 4, i64 4)
  %11 = ptrtoint ptr %9 to i64
  %12 = call i32 @cqrt_alloc_i32(i32 %3)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %11, i32 %12)
  %13 = ptrtoint ptr %10 to i64
  %14 = sub i64 %13, %11
  %15 = icmp uge i64 %14, 4
  %16 = sub i64 %11, %13
  %17 = icmp uge i64 %16, 4
  %18 = and i1 %15, %17
  br i1 %18, label %21, label %19

19:                                               ; preds = %7
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %11)
  br label %21

21:                                               ; preds = %19, %7
  %22 = phi i32 [ poison, %7 ], [ %20, %19 ]
  %23 = ptrtoint ptr %10 to i64
  %24 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %23, i32 %24)
  %25 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %25, double %1)
  %26 = ptrtoint ptr %9 to i64
  %27 = sub i64 %26, %23
  %28 = icmp uge i64 %27, 4
  %29 = sub i64 %23, %26
  %30 = icmp uge i64 %29, 4
  %31 = and i1 %28, %30
  br i1 %31, label %34, label %32

32:                                               ; preds = %21
  %33 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %23)
  br label %34

34:                                               ; preds = %32, %21
  %35 = phi i32 [ poison, %21 ], [ %33, %32 ]
  br i1 %18, label %36, label %40

36:                                               ; preds = %34
  %37 = ptrtoint ptr %9 to i64
  %38 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %37, i32 %38)
  call void @cqrt_ry_i32(i32 %38, double %4)
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %37, i32 %38)
  call void @cqrt_free(i32 %38)
  %39 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %37)
  br label %41

40:                                               ; preds = %34
  call void @cqrt_ry_i32(i32 %22, double %4)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %11, i32 %22)
  br label %41

41:                                               ; preds = %40, %36
  %42 = phi i64 [ poison, %40 ], [ %37, %36 ]
  %43 = phi i32 [ poison, %40 ], [ %39, %36 ]
  %cq.run5 = phi i1 [ false, %40 ], [ true, %36 ]
  %44 = phi i32 [ %39, %36 ], [ %22, %40 ]
  br i1 %31, label %45, label %49

45:                                               ; preds = %41
  %46 = ptrtoint ptr %10 to i64
  %47 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %46, i32 %47)
  call void @cqrt_ry_i32(i32 %47, double %6)
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %46, i32 %47)
  call void @cqrt_free(i32 %47)
  %48 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %46)
  br label %50

49:                                               ; preds = %41
  call void @cqrt_ry_i32(i32 %35, double %6)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %23, i32 %35)
  br label %50

50:                                               ; preds = %49, %45
  %51 = phi i64 [ poison, %49 ], [ %46, %45 ]
  %52 = phi i32 [ poison, %49 ], [ %48, %45 ]
  %cq.run4 = phi i1 [ %cq.run5, %49 ], [ %cq.run5, %45 ]
  %cq.run = phi i1 [ false, %49 ], [ true, %45 ]
  %53 = phi i32 [ %48, %45 ], [ %35, %49 ]
  %54 = call i32 @cq_template_mul_i32_hl(i32 %44, i32 5)
  br i1 %cq.run4, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %50
  call void @cqrt_qram_load_i32_hl_unc(i32 %43, i32 %8, i64 %42)
  br label %.cq.after

.cq.after:                                        ; preds = %50, %.cq.arm
  %55 = call i32 @cq_template_add_i32(i32 %53, i32 %54)
  %56 = call i32 @cq_template_sub_i32(i32 %55, i32 %53)
  call void @cqrt_copy_i32(i32 %56, i32 %54)
  call void @cq_template_sub_i32_unc(i32 %56, i32 %55, i32 %53)
  call void @cqrt_free(i32 %56)
  call void @cqrt_free(i32 %54)
  br i1 %cq.run, label %.cq.after.cq.arm, label %.cq.after.cq.after

.cq.after.cq.arm:                                 ; preds = %.cq.after
  call void @cqrt_qram_load_i32_hl_unc(i32 %52, i32 %8, i64 %51)
  call void @cqrt_free(i32 %52)
  br label %.cq.after.cq.after

.cq.after.cq.after:                               ; preds = %.cq.after, %.cq.after.cq.arm
  %57 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %25, i32 %2)
  %58 = ptrtoint ptr %9 to i64
  %59 = ptrtoint ptr %10 to i64
  %60 = call i32 @cq_template_select_i64_ll(i32 %57, i64 %58, i64 %59)
  %61 = call i32 @cqrt_qram_load_i32(i32 %8, i32 %60)
  %62 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32(i32 %8, i32 %60, i32 %62)
  %63 = call i32 @cq_template_add_i32_hl(i32 %62, i32 7)
  %64 = call i32 @cq_template_sub_i32_hl(i32 %63, i32 7)
  call void @cqrt_copy_i32(i32 %64, i32 %62)
  call void @cq_template_sub_i32_hl_unc(i32 %64, i32 %63, i32 7)
  call void @cqrt_free(i32 %64)
  call void @cqrt_free(i32 %62)
  call void @cqrt_qram_swap_i32(i32 %8, i32 %60, i32 %63)
  call void @cqrt_free(i32 %63)
  call fastcc void @__cq_q_bump_1(i32 %60)
  %65 = call i32 @cq_template_mul_i32_hl(i32 %61, i32 3)
  %66 = call i32 @cq_template_add_i32(i32 %55, i32 %65)
  %67 = call i32 @cq_template_sub_i32(i32 %66, i32 %65)
  call void @cqrt_copy_i32(i32 %67, i32 %55)
  call void @cq_template_sub_i32_unc(i32 %67, i32 %66, i32 %65)
  call void @cqrt_free(i32 %67)
  call void @cqrt_free(i32 %55)
  call void @cqrt_qram_load_i32_unc(i32 %61, i32 %8, i32 %60)
  call void @cq_template_select_i64_ll_unc(i32 %60, i32 %57, i64 %58, i64 %59)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %57, i32 %25, i32 %2)
  call void @cqrt_free(i32 %57)
  %68 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %58)
  %69 = call i32 @cqrt_measure_i32(i32 %68), !cq.measure !6
  %70 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %59)
  %71 = call i32 @cqrt_measure_i32(i32 %70), !cq.measure !6
  %72 = add nsw i32 %71, %69
  %73 = call i32 @cqrt_measure_i32(i32 %66), !cq.measure !6
  %74 = add nsw i32 %72, %73
  ret i32 %74
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_select_i64_ll(i32, i64, i64)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare void @cqrt_qram_swap_i32(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

define internal fastcc void @__cq_q_bump_1(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32(i32 %2, i32 %0, i32 %3)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 1)
  %5 = call i32 @cq_template_sub_i32_hl(i32 %4, i32 1)
  call void @cqrt_copy_i32(i32 %5, i32 %3)
  call void @cq_template_sub_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cqrt_free(i32 %3)
  call void @cqrt_qram_swap_i32(i32 %2, i32 %0, i32 %4)
  call void @cqrt_free(i32 %4)
  ret void
}

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_unc(i32, i32, i32)

declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_m1_1111111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @__cq_mem()
  %10 = call ptr @__cq_alloc(i64 4, i64 4)
  %11 = call ptr @__cq_alloc(i64 4, i64 4)
  %12 = ptrtoint ptr %10 to i64
  call void @cqrt_qram_store_i32_hl(i32 %9, i64 %12, i32 %3)
  %13 = ptrtoint ptr %11 to i64
  %14 = sub i64 %13, %12
  %15 = icmp uge i64 %14, 4
  %16 = sub i64 %12, %13
  %17 = icmp uge i64 %16, 4
  %18 = and i1 %15, %17
  br i1 %18, label %21, label %19

19:                                               ; preds = %8
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %12)
  br label %21

21:                                               ; preds = %19, %8
  %22 = phi i32 [ poison, %8 ], [ %20, %19 ]
  %23 = ptrtoint ptr %11 to i64
  call void @cqrt_qram_store_i32_hl(i32 %9, i64 %23, i32 %5)
  %24 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %24)
  call void @cqrt_ry_i32_qangle(i32 %24, i32 %1)
  %25 = alloca { i32, ptr }, align 8
  %26 = getelementptr inbounds { i32, ptr }, ptr %25, i32 0, i32 0
  store i32 %24, ptr %26, align 4
  %27 = load ptr, ptr %cq.mints, align 8
  %28 = getelementptr inbounds { i32, ptr }, ptr %25, i32 0, i32 1
  store ptr %27, ptr %28, align 8
  store ptr %25, ptr %cq.mints, align 8
  %29 = ptrtoint ptr %10 to i64
  %30 = sub i64 %29, %23
  %31 = icmp uge i64 %30, 4
  %32 = sub i64 %23, %29
  %33 = icmp uge i64 %32, 4
  %34 = and i1 %31, %33
  br i1 %34, label %37, label %35

35:                                               ; preds = %21
  %36 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %23)
  br label %37

37:                                               ; preds = %35, %21
  %38 = phi i32 [ poison, %21 ], [ %36, %35 ]
  br i1 %18, label %39, label %43

39:                                               ; preds = %37
  %40 = ptrtoint ptr %10 to i64
  %41 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %9, i64 %40, i32 %41)
  call void @cqrt_ry_i32_qangle(i32 %41, i32 %4)
  call void @cqrt_qram_swap_i32_hl(i32 %9, i64 %40, i32 %41)
  call void @cqrt_free(i32 %41)
  %42 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %40)
  br label %44

43:                                               ; preds = %37
  call void @cqrt_ry_i32_qangle(i32 %22, i32 %4)
  call void @cqrt_qram_store_i32_hl(i32 %9, i64 %12, i32 %22)
  br label %44

44:                                               ; preds = %43, %39
  %45 = phi i64 [ poison, %43 ], [ %40, %39 ]
  %46 = phi i32 [ poison, %43 ], [ %42, %39 ]
  %cq.run5 = phi i1 [ false, %43 ], [ true, %39 ]
  %47 = phi i32 [ %42, %39 ], [ %22, %43 ]
  br i1 %34, label %48, label %52

48:                                               ; preds = %44
  %49 = ptrtoint ptr %11 to i64
  %50 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl(i32 %9, i64 %49, i32 %50)
  call void @cqrt_ry_i32_qangle(i32 %50, i32 %6)
  call void @cqrt_qram_swap_i32_hl(i32 %9, i64 %49, i32 %50)
  call void @cqrt_free(i32 %50)
  %51 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %49)
  br label %53

52:                                               ; preds = %44
  call void @cqrt_ry_i32_qangle(i32 %38, i32 %6)
  call void @cqrt_qram_store_i32_hl(i32 %9, i64 %23, i32 %38)
  br label %53

53:                                               ; preds = %52, %48
  %54 = phi i64 [ poison, %52 ], [ %49, %48 ]
  %55 = phi i32 [ poison, %52 ], [ %51, %48 ]
  %cq.run4 = phi i1 [ %cq.run5, %52 ], [ %cq.run5, %48 ]
  %cq.run = phi i1 [ false, %52 ], [ true, %48 ]
  %56 = phi i32 [ %51, %48 ], [ %38, %52 ]
  %57 = call i32 @cq_template_mul_i32_hl(i32 %47, i32 5)
  br i1 %cq.run4, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %53
  call void @cqrt_qram_load_i32_hl_unc(i32 %46, i32 %9, i64 %45)
  br label %.cq.after

.cq.after:                                        ; preds = %53, %.cq.arm
  %58 = call i32 @cq_template_add_i32(i32 %56, i32 %57)
  %59 = call i32 @cq_template_sub_i32(i32 %58, i32 %56)
  call void @cqrt_copy_i32(i32 %59, i32 %57)
  call void @cq_template_sub_i32_unc(i32 %59, i32 %58, i32 %56)
  call void @cqrt_free(i32 %59)
  call void @cqrt_free(i32 %57)
  br i1 %cq.run, label %.cq.after.cq.arm, label %.cq.after.cq.after

.cq.after.cq.arm:                                 ; preds = %.cq.after
  call void @cqrt_qram_load_i32_hl_unc(i32 %55, i32 %9, i64 %54)
  call void @cqrt_free(i32 %55)
  br label %.cq.after.cq.after

.cq.after.cq.after:                               ; preds = %.cq.after, %.cq.after.cq.arm
  %60 = call i32 @cq_template_icmp_sgt_i32(i32 %24, i32 %2)
  %61 = ptrtoint ptr %10 to i64
  %62 = ptrtoint ptr %11 to i64
  %63 = call i32 @cq_template_select_i64_ll(i32 %60, i64 %61, i64 %62)
  %64 = call i32 @cqrt_qram_load_i32(i32 %9, i32 %63)
  %65 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32(i32 %9, i32 %63, i32 %65)
  %66 = call i32 @cq_template_add_i32_hl(i32 %65, i32 7)
  %67 = call i32 @cq_template_sub_i32_hl(i32 %66, i32 7)
  call void @cqrt_copy_i32(i32 %67, i32 %65)
  call void @cq_template_sub_i32_hl_unc(i32 %67, i32 %66, i32 7)
  call void @cqrt_free(i32 %67)
  call void @cqrt_free(i32 %65)
  call void @cqrt_qram_swap_i32(i32 %9, i32 %63, i32 %66)
  call void @cqrt_free(i32 %66)
  call fastcc void @__cq_q_bump_1(i32 %63)
  %68 = call i32 @cq_template_mul_i32_hl(i32 %64, i32 3)
  %69 = call i32 @cq_template_add_i32(i32 %58, i32 %68)
  %70 = call i32 @cq_template_sub_i32(i32 %69, i32 %68)
  call void @cqrt_copy_i32(i32 %70, i32 %58)
  call void @cq_template_sub_i32_unc(i32 %70, i32 %69, i32 %68)
  call void @cqrt_free(i32 %70)
  call void @cqrt_free(i32 %58)
  call void @cq_template_mul_i32_hl_unc(i32 %68, i32 %64, i32 3)
  call void @cqrt_free(i32 %68)
  call void @cqrt_qram_load_i32_unc(i32 %64, i32 %9, i32 %63)
  call void @cq_template_select_i64_ll_unc(i32 %63, i32 %60, i64 %61, i64 %62)
  call void @cqrt_free(i32 %63)
  call void @cq_template_icmp_sgt_i32_unc(i32 %60, i32 %24, i32 %2)
  call void @cqrt_free(i32 %60)
  %71 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %61)
  %72 = call i32 @cqrt_measure_i32(i32 %71), !cq.measure !6
  %73 = call i32 @cqrt_qram_load_i32_hl(i32 %9, i64 %62)
  %74 = call i32 @cqrt_measure_i32(i32 %73), !cq.measure !6
  %75 = add nsw i32 %74, %72
  %76 = call i32 @cqrt_measure_i32(i32 %69), !cq.measure !6
  %77 = add nsw i32 %75, %76
  %78 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %78)
  %79 = call i32 @cqrt_alloc_i32(i32 %77)
  ret i32 %79
}

declare void @cqrt_ry_i32_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32(i32, i32)

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

declare void @cq_template_icmp_sgt_i32_unc(i32, i32, i32)

define internal i32 @__cq_q_m1_1111111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8) {
  %10 = load i32, ptr @__cq_act_m1, align 4
  %11 = add i32 %10, 1
  store i32 %11, ptr @__cq_act_m1, align 4
  %12 = icmp ult i32 %10, %8
  br i1 %12, label %13, label %90

13:                                               ; preds = %9
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %14 = call i32 @__cq_mem()
  %15 = call ptr @__cq_alloc(i64 4, i64 4)
  %16 = call ptr @__cq_alloc(i64 4, i64 4)
  %17 = ptrtoint ptr %15 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %14, i64 %17, i32 %4)
  %18 = ptrtoint ptr %16 to i64
  %19 = sub i64 %18, %17
  %20 = icmp uge i64 %19, 4
  %21 = sub i64 %17, %18
  %22 = icmp uge i64 %21, 4
  %23 = and i1 %20, %22
  br i1 %23, label %26, label %24

24:                                               ; preds = %13
  %25 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %17)
  br label %26

26:                                               ; preds = %24, %13
  %27 = phi i32 [ poison, %13 ], [ %25, %24 ]
  %28 = ptrtoint ptr %16 to i64
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %14, i64 %28, i32 %6)
  %29 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %29)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %29, i32 %2)
  %30 = alloca { i32, ptr }, align 8
  %31 = getelementptr inbounds { i32, ptr }, ptr %30, i32 0, i32 0
  store i32 %29, ptr %31, align 4
  %32 = load ptr, ptr %cq.mints, align 8
  %33 = getelementptr inbounds { i32, ptr }, ptr %30, i32 0, i32 1
  store ptr %32, ptr %33, align 8
  store ptr %30, ptr %cq.mints, align 8
  %34 = ptrtoint ptr %15 to i64
  %35 = sub i64 %34, %28
  %36 = icmp uge i64 %35, 4
  %37 = sub i64 %28, %34
  %38 = icmp uge i64 %37, 4
  %39 = and i1 %36, %38
  br i1 %39, label %42, label %40

40:                                               ; preds = %26
  %41 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %28)
  br label %42

42:                                               ; preds = %40, %26
  %43 = phi i32 [ poison, %26 ], [ %41, %40 ]
  br i1 %23, label %44, label %48

44:                                               ; preds = %42
  %45 = ptrtoint ptr %15 to i64
  %46 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %14, i64 %45, i32 %46)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %46, i32 %5)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %14, i64 %45, i32 %46)
  call void @cqrt_free(i32 %46)
  %47 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %45)
  br label %49

48:                                               ; preds = %42
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %27, i32 %5)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %14, i64 %17, i32 %27)
  br label %49

49:                                               ; preds = %48, %44
  %50 = phi i64 [ poison, %48 ], [ %45, %44 ]
  %51 = phi i32 [ poison, %48 ], [ %47, %44 ]
  %cq.run5 = phi i1 [ false, %48 ], [ true, %44 ]
  %52 = phi i32 [ %47, %44 ], [ %27, %48 ]
  br i1 %39, label %53, label %57

53:                                               ; preds = %49
  %54 = ptrtoint ptr %16 to i64
  %55 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %14, i64 %54, i32 %55)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %55, i32 %7)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %14, i64 %54, i32 %55)
  call void @cqrt_free(i32 %55)
  %56 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %54)
  br label %58

57:                                               ; preds = %49
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %43, i32 %7)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %14, i64 %28, i32 %43)
  br label %58

58:                                               ; preds = %57, %53
  %59 = phi i64 [ poison, %57 ], [ %54, %53 ]
  %60 = phi i32 [ poison, %57 ], [ %56, %53 ]
  %cq.run4 = phi i1 [ %cq.run5, %57 ], [ %cq.run5, %53 ]
  %cq.run = phi i1 [ false, %57 ], [ true, %53 ]
  %61 = phi i32 [ %56, %53 ], [ %43, %57 ]
  %62 = call i32 @cq_template_mul_i32_hl(i32 %52, i32 5)
  %63 = call i32 @cq_template_add_i32(i32 %61, i32 %62)
  %64 = call i32 @cq_template_icmp_sgt_i32(i32 %29, i32 %3)
  %65 = ptrtoint ptr %15 to i64
  %66 = ptrtoint ptr %16 to i64
  %67 = call i32 @cq_template_select_i64_ll(i32 %64, i64 %65, i64 %66)
  %68 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %14, i32 %67)
  %69 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_controlled(i32 %0, i32 %14, i32 %67, i32 %69)
  %70 = call i32 @cq_template_add_i32_hl(i32 %69, i32 7)
  %71 = call i32 @cq_template_select_i32(i32 %0, i32 %70, i32 %69)
  call void @cq_template_add_i32_hl_unc(i32 %70, i32 %69, i32 7)
  call void @cqrt_free(i32 %70)
  %72 = call i32 @cq_template_sub_i32_hl(i32 %71, i32 7)
  %73 = call i32 @cq_template_select_i32(i32 %0, i32 %72, i32 %71)
  call void @cqrt_copy_i32(i32 %73, i32 %69)
  call void @cq_template_select_i32_unc(i32 %73, i32 %0, i32 %72, i32 %71)
  call void @cqrt_free(i32 %73)
  call void @cq_template_sub_i32_hl_unc(i32 %72, i32 %71, i32 7)
  call void @cqrt_free(i32 %72)
  call void @cqrt_free(i32 %69)
  call void @cqrt_qram_swap_i32_controlled(i32 %0, i32 %14, i32 %67, i32 %71)
  call void @cqrt_free(i32 %71)
  call fastcc void @__cq_q_bump_1_ctl(i32 %0, i32 %67)
  %74 = call i32 @cq_template_mul_i32_hl(i32 %68, i32 3)
  %75 = call i32 @cq_template_add_i32(i32 %63, i32 %74)
  %76 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %65)
  %77 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %76, i32 %77)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %76, i32 %0, i32 %14, i64 %65)
  call void @cqrt_free(i32 %76)
  %78 = call i32 @cqrt_measure_i32(i32 %77), !cq.measure !6
  %79 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %14, i64 %66)
  %80 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %79, i32 %80)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %79, i32 %0, i32 %14, i64 %66)
  call void @cqrt_free(i32 %79)
  %81 = call i32 @cqrt_measure_i32(i32 %80), !cq.measure !6
  %82 = call i32 @cq_template_add_i32(i32 %80, i32 %77)
  %83 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %75, i32 %83)
  call void @cq_template_add_i32_unc(i32 %75, i32 %63, i32 %74)
  call void @cqrt_free(i32 %75)
  call void @cq_template_mul_i32_hl_unc(i32 %74, i32 %68, i32 3)
  call void @cqrt_free(i32 %74)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %68, i32 %0, i32 %14, i32 %67)
  call void @cq_template_select_i64_ll_unc(i32 %67, i32 %64, i64 %65, i64 %66)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_sgt_i32_unc(i32 %64, i32 %29, i32 %3)
  call void @cqrt_free(i32 %64)
  call void @cq_template_add_i32_unc(i32 %63, i32 %61, i32 %62)
  call void @cqrt_free(i32 %63)
  call void @cq_template_mul_i32_hl_unc(i32 %62, i32 %52, i32 5)
  call void @cqrt_free(i32 %62)
  br i1 %cq.run, label %.cq.arm9, label %.cq.after8

.cq.arm9:                                         ; preds = %58
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %60, i32 %0, i32 %14, i64 %59)
  br label %.cq.after8

.cq.after8:                                       ; preds = %58, %.cq.arm9
  br i1 %cq.run4, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after8
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %51, i32 %0, i32 %14, i64 %50)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after8, %.cq.arm
  %84 = call i32 @cqrt_measure_i32(i32 %83), !cq.measure !6
  %85 = call i32 @cq_template_add_i32(i32 %82, i32 %83)
  %86 = call i32 @cq_template_sub_i32(i32 %85, i32 %83)
  call void @cqrt_copy_i32(i32 %86, i32 %82)
  call void @cq_template_sub_i32_unc(i32 %86, i32 %85, i32 %83)
  call void @cqrt_free(i32 %86)
  call void @cqrt_free(i32 %82)
  %87 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %87)
  %88 = load i32, ptr @__cq_act_m1, align 4
  %89 = add i32 %88, -1
  store i32 %89, ptr @__cq_act_m1, align 4
  ret i32 %85

90:                                               ; preds = %9
  %91 = call i32 @cqrt_alloc_i32(i32 0)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %92)
  call void @cqrt_push(i32 0)
  %93 = load i32, ptr @__cq_act_m1, align 4
  %94 = add i32 %93, -1
  store i32 %94, ptr @__cq_act_m1, align 4
  ret i32 %91
}

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_swap_i32_controlled(i32, i32, i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

define internal fastcc void @__cq_q_bump_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_controlled(i32 %0, i32 %3, i32 %1, i32 %4)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_select_i32(i32 %0, i32 %5, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  %7 = call i32 @cq_template_sub_i32_hl(i32 %6, i32 1)
  %8 = call i32 @cq_template_select_i32(i32 %0, i32 %7, i32 %6)
  call void @cqrt_copy_i32(i32 %8, i32 %4)
  call void @cq_template_select_i32_unc(i32 %8, i32 %0, i32 %7, i32 %6)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sub_i32_hl_unc(i32 %7, i32 %6, i32 1)
  call void @cqrt_free(i32 %7)
  call void @cqrt_free(i32 %4)
  call void @cqrt_qram_swap_i32_controlled(i32 %0, i32 %3, i32 %1, i32 %6)
  call void @cqrt_free(i32 %6)
  ret void
}

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @m1, ptr @.cq.sig, ptr @__cq_q_m1_1111111_t, ptr @__cq_q_m1_1111111_t_ctl, ptr @__cq_q_m1_1111111_t_unc, ptr @__cq_q_m1_1111111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_m1_1111111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8) {
  %10 = call i32 @cqrt_pop()
  br label %11

11:                                               ; preds = %14, %9
  %12 = phi i32 [ %10, %9 ], [ %16, %14 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %17, label %14

14:                                               ; preds = %11
  %15 = call i32 @cqrt_pop()
  %16 = sub i32 %12, 1
  br label %11

17:                                               ; preds = %11
  ret void
}

define internal void @__cq_q_m1_1111111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8, i32 %9) {
  %11 = load i32, ptr @__cq_act_m1, align 4
  %12 = add i32 %11, 1
  store i32 %12, ptr @__cq_act_m1, align 4
  %13 = load i32, ptr @__cq_act_m1, align 4
  %14 = add i32 %13, -1
  store i32 %14, ptr @__cq_act_m1, align 4
  %15 = call i32 @cqrt_pop()
  br label %16

16:                                               ; preds = %19, %10
  %17 = phi i32 [ %15, %10 ], [ %21, %19 ]
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %22, label %19

19:                                               ; preds = %16
  %20 = call i32 @cqrt_pop()
  %21 = sub i32 %17, 1
  br label %16

22:                                               ; preds = %16
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
