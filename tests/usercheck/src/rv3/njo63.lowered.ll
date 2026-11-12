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
  %6 = icmp ugt i32 %5, 64
  %7 = select i1 %6, i32 -1, i32 0, !cq.deferred.result !6
  %8 = sext i32 %5 to i64
  %9 = getelementptr inbounds [65 x i64], ptr @__cq_sig, i64 0, i64 %8
  %10 = ptrtoint ptr %9 to i64
  %11 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %10)
  %12 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %13 = call i32 @cqrt_alloc_i1(i1 true)
  br label %14

14:                                               ; preds = %18, %2
  %15 = phi i32 [ 0, %2 ], [ %26, %18 ]
  %16 = phi i32 [ %13, %2 ], [ %25, %18 ]
  %17 = icmp ult i32 %15, %12
  br i1 %17, label %18, label %27

18:                                               ; preds = %14
  %19 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %15)
  %20 = ptrtoint ptr %19 to i64
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %20)
  %22 = call i32 @cqrt_alloc_i32(i32 %5)
  %23 = call ptr @__cq_clone_resolve(ptr %19, i32 1)
  call void %23(i32 %21, i32 %22, i32 4)
  %24 = call ptr @__cq_clone_resolve(ptr %19, i32 3)
  call void %24(i32 %21, i32 %22, i32 4)
  call void @cqrt_free(i32 %22)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %25)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %21)
  %26 = add i32 %15, 1
  br label %14

27:                                               ; preds = %14
  call void @cqrt_tape_write_i32_lit(i32 %3, i32 %5)
  call void @cqrt_tape_effect_controlled(i32 %16, i32 %3, ptr @.cq.effect.raise, i32 1)
  br label %28

28:                                               ; preds = %32, %27
  %29 = phi i32 [ %12, %27 ], [ %33, %32 ]
  %30 = phi i32 [ %16, %27 ], [ %35, %32 ]
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
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %34, i32 %11, i64 %37)
  call void @cqrt_free(i32 %34)
  br label %28

38:                                               ; preds = %28
  call void @cqrt_free(i32 %30)
  %39 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %39, double %1)
  %40 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %39, i32 1)
  %41 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %40, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %42 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %43

43:                                               ; preds = %47, %38
  %44 = phi i32 [ 0, %38 ], [ %56, %47 ]
  %45 = phi i32 [ %40, %38 ], [ %55, %47 ]
  %46 = icmp ult i32 %44, %42
  br i1 %46, label %47, label %57

47:                                               ; preds = %43
  %48 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %44)
  %49 = ptrtoint ptr %48 to i64
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %41, i64 %49)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %50, i32 %51)
  %52 = call i32 @cqrt_alloc_i32(i32 15)
  %53 = call ptr @__cq_clone_resolve(ptr %48, i32 1)
  call void %53(i32 %51, i32 %52, i32 4)
  %54 = call ptr @__cq_clone_resolve(ptr %48, i32 3)
  call void %54(i32 %51, i32 %52, i32 4)
  call void @cqrt_free(i32 %52)
  call void @cqrt_and_i1(i32 %40, i32 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_and_i1(i32 %45, i32 %50, i32 %55)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %50)
  %56 = add i32 %44, 1
  br label %43

57:                                               ; preds = %43
  call void @cqrt_tape_write_i32_lit(i32 %3, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %45, i32 %3, ptr @.cq.effect.raise, i32 1)
  br label %58

58:                                               ; preds = %62, %57
  %59 = phi i32 [ %42, %57 ], [ %63, %62 ]
  %60 = phi i32 [ %45, %57 ], [ %65, %62 ]
  %61 = icmp eq i32 %59, 0
  br i1 %61, label %68, label %62

62:                                               ; preds = %58
  %63 = add i32 %59, -1
  %64 = call i32 @cqrt_pop()
  %65 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %64)
  call void @cqrt_and_i1(i32 %65, i32 %64, i32 %60)
  call void @cqrt_not_i1(i32 %64)
  call void @cqrt_free(i32 %60)
  %66 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %63)
  %67 = ptrtoint ptr %66 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %64, i32 %41, i64 %67)
  call void @cqrt_free(i32 %64)
  br label %58

68:                                               ; preds = %58
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %41, i32 %40, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %40, i32 %39, i32 1)
  call void @cqrt_free(i32 %40)
  call void @cqrt_qram_load_i64_hl_unc(i32 %11, i32 %4, i64 %10)
  %69 = call i32 @cqrt_measure_i32(i32 %39), !cq.measure !6
  %70 = add nsw i32 %69, %7
  ret i32 %70
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

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

declare i32 @cqrt_pop()

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_add_i32_hl(i32 %0, i32 400)
  %7 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %6, i32 64)
  %8 = call i32 @cq_template_select_i32_ll(i32 %7, i32 -1, i32 0)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %7, i32 %6, i32 64)
  call void @cqrt_free(i32 %7)
  %9 = call i32 @cq_template_sext_i32_to_i64(i32 %6)
  %10 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 8)
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 ptrtoint (ptr @__cq_sig to i64))
  %12 = call i32 @cqrt_qram_load_i64(i32 %5, i32 %11)
  %13 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %14 = call i32 @cqrt_alloc_i1(i1 true)
  br label %15

15:                                               ; preds = %19, %3
  %16 = phi i32 [ 0, %3 ], [ %26, %19 ]
  %17 = phi i32 [ %14, %3 ], [ %25, %19 ]
  %18 = icmp ult i32 %16, %13
  br i1 %18, label %19, label %27

19:                                               ; preds = %15
  %20 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %16)
  %21 = ptrtoint ptr %20 to i64
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 %21)
  %23 = call ptr @__cq_clone_resolve(ptr %20, i32 1)
  call void %23(i32 %22, i32 %6, i32 %2)
  %24 = call ptr @__cq_clone_resolve(ptr %20, i32 3)
  call void %24(i32 %22, i32 %6, i32 %2)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_and_i1(i32 %17, i32 %22, i32 %25)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %22)
  %26 = add i32 %16, 1
  br label %15

27:                                               ; preds = %15
  %28 = call i32 @cqrt_tape_write_i32_controlled(i32 %17, i32 %4, i32 %6)
  call void @cqrt_tape_effect_controlled(i32 %17, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %29

29:                                               ; preds = %33, %27
  %30 = phi i32 [ %13, %27 ], [ %34, %33 ]
  %31 = phi i32 [ %17, %27 ], [ %36, %33 ]
  %32 = icmp eq i32 %30, 0
  br i1 %32, label %39, label %33

33:                                               ; preds = %29
  %34 = add i32 %30, -1
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_and_i1(i32 %36, i32 %35, i32 %31)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %31)
  %37 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %34)
  %38 = ptrtoint ptr %37 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %12, i64 %38)
  call void @cqrt_free(i32 %35)
  br label %29

39:                                               ; preds = %29
  call void @cqrt_free(i32 %31)
  %40 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %40)
  call void @cqrt_ry_i32_qangle(i32 %40, i32 %1)
  %41 = alloca { i32, ptr }, align 8
  %42 = getelementptr inbounds { i32, ptr }, ptr %41, i32 0, i32 0
  store i32 %40, ptr %42, align 4
  %43 = load ptr, ptr %cq.mints, align 8
  %44 = getelementptr inbounds { i32, ptr }, ptr %41, i32 0, i32 1
  store ptr %43, ptr %44, align 8
  store ptr %41, ptr %cq.mints, align 8
  %45 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %40, i32 1)
  %46 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %45, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %47 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %48

48:                                               ; preds = %52, %39
  %49 = phi i32 [ 0, %39 ], [ %61, %52 ]
  %50 = phi i32 [ %45, %39 ], [ %60, %52 ]
  %51 = icmp ult i32 %49, %47
  br i1 %51, label %52, label %62

52:                                               ; preds = %48
  %53 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %49)
  %54 = ptrtoint ptr %53 to i64
  %55 = call i32 @cq_template_icmp_eq_i64_hl(i32 %46, i64 %54)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %45, i32 %55, i32 %56)
  %57 = call i32 @cqrt_alloc_i32(i32 15)
  %58 = call ptr @__cq_clone_resolve(ptr %53, i32 1)
  call void %58(i32 %56, i32 %57, i32 %2)
  %59 = call ptr @__cq_clone_resolve(ptr %53, i32 3)
  call void %59(i32 %56, i32 %57, i32 %2)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %45, i32 %55, i32 %56)
  call void @cqrt_free(i32 %56)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_and_i1(i32 %50, i32 %55, i32 %60)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %55)
  %61 = add i32 %49, 1
  br label %48

62:                                               ; preds = %48
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %50, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %63

63:                                               ; preds = %67, %62
  %64 = phi i32 [ %47, %62 ], [ %68, %67 ]
  %65 = phi i32 [ %50, %62 ], [ %70, %67 ]
  %66 = icmp eq i32 %64, 0
  br i1 %66, label %73, label %67

67:                                               ; preds = %63
  %68 = add i32 %64, -1
  %69 = call i32 @cqrt_pop()
  %70 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %69)
  call void @cqrt_and_i1(i32 %70, i32 %69, i32 %65)
  call void @cqrt_not_i1(i32 %69)
  call void @cqrt_free(i32 %65)
  %71 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %68)
  %72 = ptrtoint ptr %71 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %69, i32 %46, i64 %72)
  call void @cqrt_free(i32 %69)
  br label %63

73:                                               ; preds = %63
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %46, i32 %45, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %45, i32 %40, i32 1)
  call void @cqrt_free(i32 %45)
  call void @cqrt_qram_load_i64_unc(i32 %12, i32 %5, i32 %11)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 ptrtoint (ptr @__cq_sig to i64))
  call void @cqrt_free(i32 %11)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %9, i64 8)
  call void @cqrt_free(i32 %10)
  call void @cq_template_sext_i32_to_i64_unc(i32 %9, i32 %6)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %0, i32 400)
  call void @cqrt_free(i32 %6)
  %74 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %40, i32 %74)
  %75 = call i32 @cqrt_measure_i32(i32 %74), !cq.measure !6
  %76 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %75)
  %77 = call i32 @cq_template_sub_i32_hl(i32 %76, i32 %75)
  call void @cqrt_copy_i32(i32 %77, i32 %8)
  call void @cq_template_sub_i32_hl_unc(i32 %77, i32 %76, i32 %75)
  call void @cqrt_free(i32 %77)
  call void @cqrt_free(i32 %8)
  %78 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %78)
  ret i32 %76
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

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

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_sext_i32_to_i64_unc(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %88

8:                                                ; preds = %4
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_tape_alloc()
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_add_i32_hl(i32 %1, i32 400)
  %12 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %11, i32 64)
  %13 = call i32 @cq_template_select_i32_ll(i32 %12, i32 -1, i32 0)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %12, i32 %11, i32 64)
  call void @cqrt_free(i32 %12)
  %14 = call i32 @cq_template_sext_i32_to_i64(i32 %11)
  %15 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 8)
  %16 = call i32 @cq_template_add_i64_hl(i32 %15, i64 ptrtoint (ptr @__cq_sig to i64))
  %17 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %10, i32 %16)
  %18 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %19

19:                                               ; preds = %23, %8
  %20 = phi i32 [ 0, %8 ], [ %31, %23 ]
  %21 = phi i32 [ %0, %8 ], [ %30, %23 ]
  %22 = icmp ult i32 %20, %18
  br i1 %22, label %23, label %32

23:                                               ; preds = %19
  %24 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %20)
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 %25)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %26, i32 %27)
  %28 = call ptr @__cq_clone_resolve(ptr %24, i32 1)
  call void %28(i32 %27, i32 %11, i32 %3)
  %29 = call ptr @__cq_clone_resolve(ptr %24, i32 3)
  call void %29(i32 %27, i32 %11, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %26, i32 %27)
  call void @cqrt_free(i32 %27)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_and_i1(i32 %21, i32 %26, i32 %30)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %26)
  %31 = add i32 %20, 1
  br label %19

32:                                               ; preds = %19
  %33 = call i32 @cqrt_tape_write_i32_controlled(i32 %21, i32 %9, i32 %11)
  call void @cqrt_tape_effect_controlled(i32 %21, i32 %9, ptr @.cq.effect.raise, i32 1)
  br label %34

34:                                               ; preds = %38, %32
  %35 = phi i32 [ %18, %32 ], [ %39, %38 ]
  %36 = phi i32 [ %21, %32 ], [ %41, %38 ]
  %37 = icmp eq i32 %35, 0
  br i1 %37, label %44, label %38

38:                                               ; preds = %34
  %39 = add i32 %35, -1
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %40)
  call void @cqrt_and_i1(i32 %41, i32 %40, i32 %36)
  call void @cqrt_not_i1(i32 %40)
  call void @cqrt_free(i32 %36)
  %42 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %39)
  %43 = ptrtoint ptr %42 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %40, i32 %17, i64 %43)
  call void @cqrt_free(i32 %40)
  br label %34

44:                                               ; preds = %34
  %45 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %45)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %45, i32 %2)
  %46 = alloca { i32, ptr }, align 8
  %47 = getelementptr inbounds { i32, ptr }, ptr %46, i32 0, i32 0
  store i32 %45, ptr %47, align 4
  %48 = load ptr, ptr %cq.mints, align 8
  %49 = getelementptr inbounds { i32, ptr }, ptr %46, i32 0, i32 1
  store ptr %48, ptr %49, align 8
  store ptr %46, ptr %cq.mints, align 8
  %50 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %45, i32 1)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %50, i32 %51)
  %52 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %51, i32 %10, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %50, i32 %53)
  %54 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %55

55:                                               ; preds = %59, %44
  %56 = phi i32 [ 0, %44 ], [ %68, %59 ]
  %57 = phi i32 [ %53, %44 ], [ %67, %59 ]
  %58 = icmp ult i32 %56, %54
  br i1 %58, label %59, label %69

59:                                               ; preds = %55
  %60 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %56)
  %61 = ptrtoint ptr %60 to i64
  %62 = call i32 @cq_template_icmp_eq_i64_hl(i32 %52, i64 %61)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %53, i32 %62, i32 %63)
  %64 = call i32 @cqrt_alloc_i32(i32 15)
  %65 = call ptr @__cq_clone_resolve(ptr %60, i32 1)
  call void %65(i32 %63, i32 %64, i32 %3)
  %66 = call ptr @__cq_clone_resolve(ptr %60, i32 3)
  call void %66(i32 %63, i32 %64, i32 %3)
  call void @cqrt_free(i32 %64)
  call void @cqrt_and_i1(i32 %53, i32 %62, i32 %63)
  call void @cqrt_free(i32 %63)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_and_i1(i32 %57, i32 %62, i32 %67)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %62)
  %68 = add i32 %56, 1
  br label %55

69:                                               ; preds = %55
  call void @cqrt_tape_write_i32_lit(i32 %9, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %57, i32 %9, ptr @.cq.effect.raise, i32 1)
  br label %70

70:                                               ; preds = %74, %69
  %71 = phi i32 [ %54, %69 ], [ %75, %74 ]
  %72 = phi i32 [ %57, %69 ], [ %77, %74 ]
  %73 = icmp eq i32 %71, 0
  br i1 %73, label %80, label %74

74:                                               ; preds = %70
  %75 = add i32 %71, -1
  %76 = call i32 @cqrt_pop()
  %77 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %76)
  call void @cqrt_and_i1(i32 %77, i32 %76, i32 %72)
  call void @cqrt_not_i1(i32 %76)
  call void @cqrt_free(i32 %72)
  %78 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %75)
  %79 = ptrtoint ptr %78 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %76, i32 %52, i64 %79)
  call void @cqrt_free(i32 %76)
  br label %70

80:                                               ; preds = %70
  call void @cqrt_and_i1(i32 %0, i32 %50, i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %52, i32 %51, i32 %10, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cqrt_and_i1(i32 %0, i32 %50, i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %50, i32 %45, i32 1)
  call void @cqrt_free(i32 %50)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %17, i32 %0, i32 %10, i32 %16)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %15, i64 ptrtoint (ptr @__cq_sig to i64))
  call void @cqrt_free(i32 %16)
  call void @cq_template_mul_i64_hl_unc(i32 %15, i32 %14, i64 8)
  call void @cqrt_free(i32 %15)
  call void @cq_template_sext_i32_to_i64_unc(i32 %14, i32 %11)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %1, i32 400)
  call void @cqrt_free(i32 %11)
  %81 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %45, i32 %81)
  %82 = call i32 @cqrt_measure_i32(i32 %81), !cq.measure !6
  %83 = call i32 @cq_template_add_i32(i32 %81, i32 %13)
  %84 = call i32 @cq_template_sub_i32(i32 %83, i32 %81)
  call void @cqrt_copy_i32(i32 %84, i32 %13)
  call void @cq_template_sub_i32_unc(i32 %84, i32 %83, i32 %81)
  call void @cqrt_free(i32 %84)
  call void @cqrt_free(i32 %13)
  %85 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %85)
  %86 = load i32, ptr @__cq_act_f, align 4
  %87 = add i32 %86, -1
  store i32 %87, ptr @__cq_act_f, align 4
  ret i32 %83

88:                                               ; preds = %4
  %89 = call i32 @cqrt_alloc_i32(i32 0)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %90)
  call void @cqrt_push(i32 0)
  %91 = load i32, ptr @__cq_act_f, align 4
  %92 = add i32 %91, -1
  store i32 %92, ptr @__cq_act_f, align 4
  ret i32 %89
}

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_add_i32_hl(i32 %0, i32 400)
  %7 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %6, i32 64)
  %8 = call i32 @cq_template_select_i32_ll(i32 %7, i32 -1, i32 0)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %7, i32 %6, i32 64)
  call void @cqrt_free(i32 %7)
  %9 = call i32 @cq_template_sext_i32_to_i64(i32 %6)
  %10 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 8)
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 ptrtoint (ptr @__cq_sig to i64))
  %12 = call i32 @cqrt_qram_load_i64(i32 %5, i32 %11)
  %13 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %14 = call i32 @cqrt_alloc_i1(i1 true)
  br label %15

15:                                               ; preds = %19, %3
  %16 = phi i32 [ 0, %3 ], [ %26, %19 ]
  %17 = phi i32 [ %14, %3 ], [ %25, %19 ]
  %18 = icmp ult i32 %16, %13
  br i1 %18, label %19, label %27

19:                                               ; preds = %15
  %20 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %16)
  %21 = ptrtoint ptr %20 to i64
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 %21)
  %23 = call ptr @__cq_clone_resolve(ptr %20, i32 1)
  call void %23(i32 %22, i32 %6, i32 %2)
  %24 = call ptr @__cq_clone_resolve(ptr %20, i32 3)
  call void %24(i32 %22, i32 %6, i32 %2)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_and_i1(i32 %17, i32 %22, i32 %25)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %22)
  %26 = add i32 %16, 1
  br label %15

27:                                               ; preds = %15
  %28 = call i32 @cqrt_tape_write_i32_controlled(i32 %17, i32 %4, i32 %6)
  call void @cqrt_tape_effect_controlled(i32 %17, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %29

29:                                               ; preds = %33, %27
  %30 = phi i32 [ %13, %27 ], [ %34, %33 ]
  %31 = phi i32 [ %17, %27 ], [ %36, %33 ]
  %32 = icmp eq i32 %30, 0
  br i1 %32, label %39, label %33

33:                                               ; preds = %29
  %34 = add i32 %30, -1
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_and_i1(i32 %36, i32 %35, i32 %31)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %31)
  %37 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %34)
  %38 = ptrtoint ptr %37 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %12, i64 %38)
  call void @cqrt_free(i32 %35)
  br label %29

39:                                               ; preds = %29
  call void @cqrt_free(i32 %31)
  %40 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %40)
  call void @cqrt_ry_i32_qangle(i32 %40, i32 %1)
  %41 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %40, i32 1)
  %42 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %41, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  %43 = call i32 @__cq_clone_count(ptr @.cq.sig)
  br label %44

44:                                               ; preds = %48, %39
  %45 = phi i32 [ 0, %39 ], [ %57, %48 ]
  %46 = phi i32 [ %41, %39 ], [ %56, %48 ]
  %47 = icmp ult i32 %45, %43
  br i1 %47, label %48, label %58

48:                                               ; preds = %44
  %49 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %45)
  %50 = ptrtoint ptr %49 to i64
  %51 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 %50)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %41, i32 %51, i32 %52)
  %53 = call i32 @cqrt_alloc_i32(i32 15)
  %54 = call ptr @__cq_clone_resolve(ptr %49, i32 1)
  call void %54(i32 %52, i32 %53, i32 %2)
  %55 = call ptr @__cq_clone_resolve(ptr %49, i32 3)
  call void %55(i32 %52, i32 %53, i32 %2)
  call void @cqrt_free(i32 %53)
  call void @cqrt_and_i1(i32 %41, i32 %51, i32 %52)
  call void @cqrt_free(i32 %52)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_and_i1(i32 %46, i32 %51, i32 %56)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %51)
  %57 = add i32 %45, 1
  br label %44

58:                                               ; preds = %44
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 15)
  call void @cqrt_tape_effect_controlled(i32 %46, i32 %4, ptr @.cq.effect.raise, i32 1)
  br label %59

59:                                               ; preds = %63, %58
  %60 = phi i32 [ %43, %58 ], [ %64, %63 ]
  %61 = phi i32 [ %46, %58 ], [ %66, %63 ]
  %62 = icmp eq i32 %60, 0
  br i1 %62, label %69, label %63

63:                                               ; preds = %59
  %64 = add i32 %60, -1
  %65 = call i32 @cqrt_pop()
  %66 = call i32 @cqrt_pop()
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_and_i1(i32 %66, i32 %65, i32 %61)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_free(i32 %61)
  %67 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %64)
  %68 = ptrtoint ptr %67 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %65, i32 %42, i64 %68)
  call void @cqrt_free(i32 %65)
  br label %59

69:                                               ; preds = %59
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %42, i32 %41, i32 %5, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 15) to i64))
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %41, i32 %40, i32 1)
  call void @cqrt_free(i32 %41)
  call void @cqrt_qram_load_i64_unc(i32 %12, i32 %5, i32 %11)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 ptrtoint (ptr @__cq_sig to i64))
  call void @cqrt_free(i32 %11)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %9, i64 8)
  call void @cqrt_free(i32 %10)
  call void @cq_template_sext_i32_to_i64_unc(i32 %9, i32 %6)
  call void @cqrt_free(i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %0, i32 400)
  call void @cqrt_free(i32 %6)
  %70 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %40, i32 %70)
  %71 = call i32 @cqrt_measure_i32(i32 %70), !cq.measure !6
  %72 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %71)
  %73 = call i32 @cq_template_sub_i32_hl(i32 %72, i32 %71)
  call void @cqrt_copy_i32(i32 %73, i32 %8)
  call void @cq_template_sub_i32_hl_unc(i32 %73, i32 %72, i32 %71)
  call void @cqrt_free(i32 %73)
  call void @cqrt_free(i32 %8)
  ret i32 %72
}

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
