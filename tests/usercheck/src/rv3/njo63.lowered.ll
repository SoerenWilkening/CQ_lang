; ModuleID = 'src/rv3/njo63.O1.ll'
source_filename = "src/rv3/njo63.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_sig = external global [65 x i64]
@.cq.sig = private unnamed_addr constant [11 x i8] c"void (i32)\00", align 1
@.cq.effect.raise = private unnamed_addr constant [6 x i8] c"raise\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig.1 = private unnamed_addr constant [18 x i8] c"i32 (i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = add nsw i32 %0, 400
  %6 = sext i32 %5 to i64
  %7 = getelementptr inbounds [65 x i64], ptr @__cq_sig, i64 0, i64 %6
  %8 = ptrtoint ptr %7 to i64
  %9 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %8)
  %10 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %11 = call i32 @cqrt_alloc_i1(i1 true)
  br label %12

12:                                               ; preds = %16, %2
  %13 = phi i32 [ 0, %2 ], [ %24, %16 ]
  %14 = phi i32 [ %11, %2 ], [ %23, %16 ]
  %15 = icmp ult i32 %13, %10
  br i1 %15, label %16, label %25

16:                                               ; preds = %12
  %17 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %13)
  %18 = ptrtoint ptr %17 to i64
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %9, i64 %18)
  %20 = call i32 @cqrt_alloc_i32(i32 %5)
  %21 = call ptr @__cq_clone_resolve(ptr %17, i32 1)
  call void %21(i32 %19, i32 %20, i32 4)
  %22 = call ptr @__cq_clone_resolve(ptr %17, i32 3)
  call void %22(i32 %19, i32 %20, i32 4)
  call void @cqrt_free(i32 %20)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %19)
  call void @cqrt_and_i1(i32 %14, i32 %19, i32 %23)
  call void @cqrt_not_i1(i32 %19)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %19)
  %24 = add i32 %13, 1
  br label %12

25:                                               ; preds = %12
  call void @cqrt_tape_write_i32_lit(i32 %3, i32 %5)
  %26 = call i32 @cqrt_tape_effect_i32_controlled(i32 %14, i32 %3, ptr @.cq.effect.raise, i32 1)
  br label %27

27:                                               ; preds = %31, %25
  %28 = phi i32 [ %10, %25 ], [ %32, %31 ]
  %29 = phi i32 [ %14, %25 ], [ %34, %31 ]
  %30 = icmp eq i32 %28, 0
  br i1 %30, label %37, label %31

31:                                               ; preds = %27
  %32 = add i32 %28, -1
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_and_i1(i32 %34, i32 %33, i32 %29)
  call void @cqrt_not_i1(i32 %33)
  call void @cqrt_free(i32 %29)
  %35 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %32)
  %36 = ptrtoint ptr %35 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %33, i32 %9, i64 %36)
  call void @cqrt_free(i32 %33)
  br label %27

37:                                               ; preds = %27
  call void @cqrt_free(i32 %29)
  %38 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %38, double %1)
  %39 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %38, i32 1)
  %40 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %39, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %41 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %42

42:                                               ; preds = %46, %37
  %43 = phi i32 [ 0, %37 ], [ %55, %46 ]
  %44 = phi i32 [ %39, %37 ], [ %54, %46 ]
  %45 = icmp ult i32 %43, %41
  br i1 %45, label %46, label %56

46:                                               ; preds = %42
  %47 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %43)
  %48 = ptrtoint ptr %47 to i64
  %49 = call i32 @cq_template_icmp_eq_i64_hl(i32 %40, i64 %48)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %49, i32 %50)
  %51 = call i32 @cqrt_alloc_i32(i32 15)
  %52 = call ptr @__cq_clone_resolve(ptr %47, i32 1)
  call void %52(i32 %50, i32 %51, i32 4)
  %53 = call ptr @__cq_clone_resolve(ptr %47, i32 3)
  call void %53(i32 %50, i32 %51, i32 4)
  call void @cqrt_free(i32 %51)
  call void @cqrt_and_i1(i32 %39, i32 %49, i32 %50)
  call void @cqrt_free(i32 %50)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_and_i1(i32 %44, i32 %49, i32 %54)
  call void @cqrt_not_i1(i32 %49)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %49)
  %55 = add i32 %43, 1
  br label %42

56:                                               ; preds = %42
  call void @cqrt_tape_write_i32_lit(i32 %3, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %44, i32 %3, ptr @.cq.effect.raise, i32 1)
  br label %57

57:                                               ; preds = %61, %56
  %58 = phi i32 [ %41, %56 ], [ %62, %61 ]
  %59 = phi i32 [ %44, %56 ], [ %64, %61 ]
  %60 = icmp eq i32 %58, 0
  br i1 %60, label %67, label %61

61:                                               ; preds = %57
  %62 = add i32 %58, -1
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_and_i1(i32 %64, i32 %63, i32 %59)
  call void @cqrt_not_i1(i32 %63)
  call void @cqrt_free(i32 %59)
  %65 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %62)
  %66 = ptrtoint ptr %65 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %63, i32 %40, i64 %66)
  call void @cqrt_free(i32 %63)
  br label %57

67:                                               ; preds = %57
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %40, i32 %39, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %39, i32 %38, i32 1)
  call void @cqrt_free(i32 %39)
  call void @cqrt_qram_load_i64_hl_unc(i32 %9, i32 %4, i64 %8)
  %68 = call i32 @cqrt_measure_i32(i32 %38), !cq.measure !6
  %69 = call i32 @cq_template_add_i32_hl(i32 %26, i32 %68)
  ret i32 %69
}

declare i32 @raise(i32 noundef) local_unnamed_addr #1

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @__cq_clone_count(ptr)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_push(i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare ptr @__cq_clone_at(ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i32(i32)

declare ptr @__cq_clone_resolve(ptr, i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i32_lit(i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)

declare i32 @cqrt_pop()

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_add_i32_hl(i32 %0, i32 400)
  %7 = call i32 @cq_template_sext_i32_to_i64(i32 %6)
  %8 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 8)
  %9 = call i32 @cq_template_add_i64_hl(i32 %8, i64 ptrtoint (ptr @__cq_sig to i64))
  %10 = call i32 @cqrt_qram_load_i64(i32 %5, i32 %9)
  %11 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %12 = call i32 @cqrt_alloc_i1(i1 true)
  br label %13

13:                                               ; preds = %17, %3
  %14 = phi i32 [ 0, %3 ], [ %24, %17 ]
  %15 = phi i32 [ %12, %3 ], [ %23, %17 ]
  %16 = icmp ult i32 %14, %11
  br i1 %16, label %17, label %25

17:                                               ; preds = %13
  %18 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %14)
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %10, i64 %19)
  %21 = call ptr @__cq_clone_resolve(ptr %18, i32 1)
  call void %21(i32 %20, i32 %6, i32 %2)
  %22 = call ptr @__cq_clone_resolve(ptr %18, i32 3)
  call void %22(i32 %20, i32 %6, i32 %2)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_and_i1(i32 %15, i32 %20, i32 %23)
  call void @cqrt_not_i1(i32 %20)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %20)
  %24 = add i32 %14, 1
  br label %13

25:                                               ; preds = %13
  %26 = call i32 @cqrt_tape_write_i32_controlled(i32 %15, i32 %4, i32 %6)
  %27 = call i32 @cqrt_tape_effect_i32_controlled(i32 %15, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %28

28:                                               ; preds = %32, %25
  %29 = phi i32 [ %11, %25 ], [ %33, %32 ]
  %30 = phi i32 [ %15, %25 ], [ %35, %32 ]
  %31 = icmp eq i32 %29, 0
  br i1 %31, label %38, label %32

32:                                               ; preds = %28
  %33 = add i32 %29, -1
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_and_i1(i32 %35, i32 %34, i32 %30)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_free(i32 %30)
  %36 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %33)
  %37 = ptrtoint ptr %36 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %34, i32 %10, i64 %37)
  call void @cqrt_free(i32 %34)
  br label %28

38:                                               ; preds = %28
  call void @cqrt_free(i32 %30)
  %39 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %39)
  call void @cqrt_ry_i32_qangle(i32 %39, i32 %1)
  %40 = alloca { i32, ptr }, align 8
  %41 = getelementptr inbounds { i32, ptr }, ptr %40, i32 0, i32 0
  store i32 %39, ptr %41, align 4
  %42 = load ptr, ptr %cq.mints, align 8
  %43 = getelementptr inbounds { i32, ptr }, ptr %40, i32 0, i32 1
  store ptr %42, ptr %43, align 8
  store ptr %40, ptr %cq.mints, align 8
  %44 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %39, i32 1)
  %45 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %44, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %46 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %47

47:                                               ; preds = %51, %38
  %48 = phi i32 [ 0, %38 ], [ %60, %51 ]
  %49 = phi i32 [ %44, %38 ], [ %59, %51 ]
  %50 = icmp ult i32 %48, %46
  br i1 %50, label %51, label %61

51:                                               ; preds = %47
  %52 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %48)
  %53 = ptrtoint ptr %52 to i64
  %54 = call i32 @cq_template_icmp_eq_i64_hl(i32 %45, i64 %53)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %54, i32 %55)
  %56 = call i32 @cqrt_alloc_i32(i32 15)
  %57 = call ptr @__cq_clone_resolve(ptr %52, i32 1)
  call void %57(i32 %55, i32 %56, i32 %2)
  %58 = call ptr @__cq_clone_resolve(ptr %52, i32 3)
  call void %58(i32 %55, i32 %56, i32 %2)
  call void @cqrt_free(i32 %56)
  call void @cqrt_and_i1(i32 %44, i32 %54, i32 %55)
  call void @cqrt_free(i32 %55)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_and_i1(i32 %49, i32 %54, i32 %59)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %54)
  %60 = add i32 %48, 1
  br label %47

61:                                               ; preds = %47
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %49, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %62

62:                                               ; preds = %66, %61
  %63 = phi i32 [ %46, %61 ], [ %67, %66 ]
  %64 = phi i32 [ %49, %61 ], [ %69, %66 ]
  %65 = icmp eq i32 %63, 0
  br i1 %65, label %72, label %66

66:                                               ; preds = %62
  %67 = add i32 %63, -1
  %68 = call i32 @cqrt_pop()
  %69 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_and_i1(i32 %69, i32 %68, i32 %64)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_free(i32 %64)
  %70 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %67)
  %71 = ptrtoint ptr %70 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %68, i32 %45, i64 %71)
  call void @cqrt_free(i32 %68)
  br label %62

72:                                               ; preds = %62
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %45, i32 %44, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %44, i32 %39, i32 1)
  call void @cqrt_free(i32 %44)
  call void @cqrt_qram_load_i64_unc(i32 %10, i32 %5, i32 %9)
  call void @cq_template_add_i64_hl_unc(i32 %9, i32 %8, i64 ptrtoint (ptr @__cq_sig to i64))
  call void @cqrt_free(i32 %9)
  call void @cq_template_mul_i64_hl_unc(i32 %8, i32 %7, i64 8)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sext_i32_to_i64_unc(i32 %7, i32 %6)
  call void @cqrt_free(i32 %7)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %0, i32 400)
  call void @cqrt_free(i32 %6)
  %73 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %39, i32 %73)
  %74 = call i32 @cqrt_measure_i32(i32 %73), !cq.measure !6
  %75 = call i32 @cq_template_add_i32_hl(i32 %27, i32 %74)
  %76 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %76)
  %77 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %75, i32 %77)
  call void @cq_template_add_i32_hl_unc(i32 %75, i32 %27, i32 %74)
  call void @cqrt_free(i32 %75)
  ret i32 %77
}

declare i32 @cq_template_sext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cqrt_qram_load_i64(i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

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

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_sext_i32_to_i64_unc(i32, i32)

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %87

8:                                                ; preds = %4
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_tape_alloc()
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_add_i32_hl(i32 %1, i32 400)
  %12 = call i32 @cq_template_sext_i32_to_i64(i32 %11)
  %13 = call i32 @cq_template_mul_i64_hl(i32 %12, i64 8)
  %14 = call i32 @cq_template_add_i64_hl(i32 %13, i64 ptrtoint (ptr @__cq_sig to i64))
  %15 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %10, i32 %14)
  %16 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %17

17:                                               ; preds = %21, %8
  %18 = phi i32 [ 0, %8 ], [ %29, %21 ]
  %19 = phi i32 [ %0, %8 ], [ %28, %21 ]
  %20 = icmp ult i32 %18, %16
  br i1 %20, label %21, label %30

21:                                               ; preds = %17
  %22 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %18)
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 %23)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %25)
  %26 = call ptr @__cq_clone_resolve(ptr %22, i32 1)
  call void %26(i32 %25, i32 %11, i32 %3)
  %27 = call ptr @__cq_clone_resolve(ptr %22, i32 3)
  call void %27(i32 %25, i32 %11, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %25)
  call void @cqrt_free(i32 %25)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_and_i1(i32 %19, i32 %24, i32 %28)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %24)
  %29 = add i32 %18, 1
  br label %17

30:                                               ; preds = %17
  %31 = call i32 @cqrt_tape_write_i32_controlled(i32 %19, i32 %9, i32 %11)
  %32 = call i32 @cqrt_tape_effect_i32_controlled(i32 %19, i32 %9, ptr @.cq.effect.raise, i32 1)
  br label %33

33:                                               ; preds = %37, %30
  %34 = phi i32 [ %16, %30 ], [ %38, %37 ]
  %35 = phi i32 [ %19, %30 ], [ %40, %37 ]
  %36 = icmp eq i32 %34, 0
  br i1 %36, label %43, label %37

37:                                               ; preds = %33
  %38 = add i32 %34, -1
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_and_i1(i32 %40, i32 %39, i32 %35)
  call void @cqrt_not_i1(i32 %39)
  call void @cqrt_free(i32 %35)
  %41 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %38)
  %42 = ptrtoint ptr %41 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %39, i32 %15, i64 %42)
  call void @cqrt_free(i32 %39)
  br label %33

43:                                               ; preds = %33
  %44 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %44)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %44, i32 %2)
  %45 = alloca { i32, ptr }, align 8
  %46 = getelementptr inbounds { i32, ptr }, ptr %45, i32 0, i32 0
  store i32 %44, ptr %46, align 4
  %47 = load ptr, ptr %cq.mints, align 8
  %48 = getelementptr inbounds { i32, ptr }, ptr %45, i32 0, i32 1
  store ptr %47, ptr %48, align 8
  store ptr %45, ptr %cq.mints, align 8
  %49 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %44, i32 1)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %49, i32 %50)
  %51 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %50, i32 %10, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %49, i32 %52)
  %53 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %54

54:                                               ; preds = %58, %43
  %55 = phi i32 [ 0, %43 ], [ %67, %58 ]
  %56 = phi i32 [ %52, %43 ], [ %66, %58 ]
  %57 = icmp ult i32 %55, %53
  br i1 %57, label %58, label %68

58:                                               ; preds = %54
  %59 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %55)
  %60 = ptrtoint ptr %59 to i64
  %61 = call i32 @cq_template_icmp_eq_i64_hl(i32 %51, i64 %60)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %52, i32 %61, i32 %62)
  %63 = call i32 @cqrt_alloc_i32(i32 15)
  %64 = call ptr @__cq_clone_resolve(ptr %59, i32 1)
  call void %64(i32 %62, i32 %63, i32 %3)
  %65 = call ptr @__cq_clone_resolve(ptr %59, i32 3)
  call void %65(i32 %62, i32 %63, i32 %3)
  call void @cqrt_free(i32 %63)
  call void @cqrt_and_i1(i32 %52, i32 %61, i32 %62)
  call void @cqrt_free(i32 %62)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %61)
  call void @cqrt_and_i1(i32 %56, i32 %61, i32 %66)
  call void @cqrt_not_i1(i32 %61)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %61)
  %67 = add i32 %55, 1
  br label %54

68:                                               ; preds = %54
  call void @cqrt_tape_write_i32_lit(i32 %9, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %56, i32 %9, ptr @.cq.effect.raise, i32 1)
  br label %69

69:                                               ; preds = %73, %68
  %70 = phi i32 [ %53, %68 ], [ %74, %73 ]
  %71 = phi i32 [ %56, %68 ], [ %76, %73 ]
  %72 = icmp eq i32 %70, 0
  br i1 %72, label %79, label %73

73:                                               ; preds = %69
  %74 = add i32 %70, -1
  %75 = call i32 @cqrt_pop()
  %76 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_and_i1(i32 %76, i32 %75, i32 %71)
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_free(i32 %71)
  %77 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %74)
  %78 = ptrtoint ptr %77 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %75, i32 %51, i64 %78)
  call void @cqrt_free(i32 %75)
  br label %69

79:                                               ; preds = %69
  call void @cqrt_and_i1(i32 %0, i32 %49, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %51, i32 %50, i32 %10, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cqrt_and_i1(i32 %0, i32 %49, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %49, i32 %44, i32 1)
  call void @cqrt_free(i32 %49)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %15, i32 %0, i32 %10, i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %14, i32 %13, i64 ptrtoint (ptr @__cq_sig to i64))
  call void @cqrt_free(i32 %14)
  call void @cq_template_mul_i64_hl_unc(i32 %13, i32 %12, i64 8)
  call void @cqrt_free(i32 %13)
  call void @cq_template_sext_i32_to_i64_unc(i32 %12, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %1, i32 400)
  call void @cqrt_free(i32 %11)
  %80 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %44, i32 %80)
  %81 = call i32 @cqrt_measure_i32(i32 %80), !cq.measure !6
  %82 = call i32 @cq_template_add_i32(i32 %80, i32 %32)
  %83 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %83)
  %84 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %82, i32 %84)
  call void @cq_template_add_i32_unc(i32 %82, i32 %80, i32 %32)
  call void @cqrt_free(i32 %82)
  %85 = load i32, ptr @__cq_act_f, align 4
  %86 = add i32 %85, -1
  store i32 %86, ptr @__cq_act_f, align 4
  ret i32 %84

87:                                               ; preds = %4
  %88 = call i32 @cqrt_alloc_i32(i32 0)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %89)
  call void @cqrt_push(i32 0)
  %90 = load i32, ptr @__cq_act_f, align 4
  %91 = add i32 %90, -1
  store i32 %91, ptr @__cq_act_f, align 4
  ret i32 %88
}

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_11_t_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cqrt_pop()
  br label %6

6:                                                ; preds = %9, %4
  %7 = phi i32 [ %5, %4 ], [ %11, %9 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %6
  %10 = call i32 @cqrt_pop()
  %11 = sub i32 %7, 1
  br label %6

12:                                               ; preds = %6
  ret void
}

define internal void @__cq_q_f_11_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_act_f, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_f, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, -1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = call i32 @cqrt_pop()
  br label %11

11:                                               ; preds = %14, %5
  %12 = phi i32 [ %10, %5 ], [ %16, %14 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %17, label %14

14:                                               ; preds = %11
  %15 = call i32 @cqrt_pop()
  %16 = sub i32 %12, 1
  br label %11

17:                                               ; preds = %11
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
