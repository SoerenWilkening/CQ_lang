; ModuleID = '<stdin>'
source_filename = "2in7d.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@__cq_act_l = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1
@__cq_act_f = internal global i32 0, align 4
@.cq.sig.1 = private unnamed_addr constant [15 x i8] c"i32 (i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: noinline nounwind ssp uwtable
define i32 @l(i32 noundef %0) #0 {
  %2 = call i32 @__cq_mem()
  %3 = and i32 %0, 63
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %21, %1
  %6 = phi i32 [ %9, %21 ], [ poison, %1 ]
  %cq.run = phi i1 [ true, %21 ], [ false, %1 ]
  %7 = phi i32 [ %16, %21 ], [ 0, %1 ]
  br i1 %cq.run, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %5
  call void @cqrt_qram_load_i32_hl_unc(i32 %6, i32 %2, i64 ptrtoint (ptr @g to i64))
  br label %.cq.after

.cq.after:                                        ; preds = %5, %.cq.arm
  ret i32 %7

8:                                                ; preds = %1
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64))
  br label %10

10:                                               ; preds = %8
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %9, i32 %11)
  br label %13

12:                                               ; preds = %13
  br label %22

13:                                               ; preds = %13, %10
  %from = phi i32 [ 0, %13 ], [ 1, %10 ]
  %14 = phi i32 [ 0, %10 ], [ %16, %13 ]
  %15 = phi i32 [ %11, %10 ], [ %17, %13 ]
  call void @cqrt_push(i32 %from)
  %16 = add nuw nsw i32 %14, 1
  %17 = call i32 @cq_template_xor_i32_hl(i32 %15, i32 %16)
  %18 = call i32 @cq_template_xor_i32_hl(i32 %17, i32 %16)
  call void @cqrt_copy_i32(i32 %18, i32 %15)
  call void @cq_template_xor_i32_hl_unc(i32 %18, i32 %17, i32 %16)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %15)
  %19 = mul nuw nsw i32 %16, %16
  %20 = icmp ult i32 %19, %3
  br i1 %20, label %13, label %12

21:                                               ; preds = %22
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %17)
  br label %5

22:                                               ; preds = %12, %22
  %23 = call i32 @cqrt_pop()
  switch i32 %23, label %22 [
    i32 1, label %21
  ]
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 8, i64 8)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %6, double 1.000000e+00)
  %7 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = ptrtoint ptr %5 to i64
  %9 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @l to i64))
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %9)
  %10 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %8)
  %11 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %12 = call i32 @cqrt_alloc_i1(i1 true)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  br label %14

14:                                               ; preds = %19, %2
  %15 = phi i32 [ 0, %2 ], [ %29, %19 ]
  %16 = phi i32 [ %12, %2 ], [ %27, %19 ]
  %17 = phi i32 [ %13, %2 ], [ %28, %19 ]
  %18 = icmp ult i32 %15, %11
  br i1 %18, label %19, label %30

19:                                               ; preds = %14
  %20 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %15)
  %21 = ptrtoint ptr %20 to i64
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %10, i64 %21)
  %23 = call ptr @__cq_clone_resolve(ptr %20, i32 1)
  %24 = call i32 %23(i32 %22, i32 %6, i32 4)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %24, i32 %25)
  %26 = call ptr @__cq_clone_resolve(ptr %20, i32 3)
  call void %26(i32 %22, i32 %24, i32 %6, i32 4)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_and_i1(i32 %16, i32 %22, i32 %27)
  call void @cqrt_not_i1(i32 %22)
  call void @cqrt_push(i32 %16)
  %28 = call i32 @cq_template_select_i32(i32 %22, i32 %25, i32 %17)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %22)
  %29 = add i32 %15, 1
  br label %14

30:                                               ; preds = %14
  %31 = call i32 @cqrt_tape_write_i64_controlled(i32 %16, i32 %3, i32 %10)
  %32 = call i32 @cqrt_tape_write_i32_controlled(i32 %16, i32 %3, i32 %6)
  %33 = call i32 @cqrt_tape_effect_i32_controlled(i32 %16, i32 %3, ptr null)
  %34 = call i32 @cq_template_select_i32(i32 %16, i32 %33, i32 %17)
  %35 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %34, i32 %35)
  call void @cq_template_select_i32_unc(i32 %34, i32 %16, i32 %33, i32 %17)
  call void @cqrt_free(i32 %34)
  br label %36

36:                                               ; preds = %41, %30
  %37 = phi i32 [ %11, %30 ], [ %42, %41 ]
  %38 = phi i32 [ %16, %30 ], [ %46, %41 ]
  %39 = phi i32 [ %17, %30 ], [ %45, %41 ]
  %40 = icmp eq i32 %37, 0
  br i1 %40, label %49, label %41

41:                                               ; preds = %36
  %42 = add i32 %37, -1
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %39, i32 %43, i32 %44, i32 %45)
  call void @cqrt_free(i32 %39)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_and_i1(i32 %46, i32 %43, i32 %38)
  call void @cqrt_not_i1(i32 %43)
  call void @cqrt_free(i32 %38)
  %47 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %42)
  %48 = ptrtoint ptr %47 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %43, i32 %10, i64 %48)
  call void @cqrt_free(i32 %43)
  br label %36

49:                                               ; preds = %36
  call void @cqrt_free(i32 %38)
  call void @cqrt_free(i32 %39)
  %50 = call i32 @cq_template_and_i32_hl(i32 %7, i32 2)
  %51 = call i32 @cq_template_icmp_eq_i32_hl(i32 %50, i32 0)
  %52 = ptrtoint ptr %5 to i64
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_xor_i1(i32 %51, i32 %53)
  %54 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %53, i32 %4, i64 %52)
  %55 = call i32 @cq_template_ashr_i32_hl(i32 %6, i32 1)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_xor_i1(i32 %51, i32 %56)
  %57 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %58 = call i32 @cqrt_alloc_i32(i32 0)
  br label %59

59:                                               ; preds = %64, %49
  %60 = phi i32 [ 0, %49 ], [ %75, %64 ]
  %61 = phi i32 [ %56, %49 ], [ %73, %64 ]
  %62 = phi i32 [ %58, %49 ], [ %74, %64 ]
  %63 = icmp ult i32 %60, %57
  br i1 %63, label %64, label %76

64:                                               ; preds = %59
  %65 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %60)
  %66 = ptrtoint ptr %65 to i64
  %67 = call i32 @cq_template_icmp_eq_i64_hl(i32 %54, i64 %66)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %68)
  %69 = call ptr @__cq_clone_resolve(ptr %65, i32 1)
  %70 = call i32 %69(i32 %68, i32 %55, i32 4)
  %71 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %70, i32 %71)
  %72 = call ptr @__cq_clone_resolve(ptr %65, i32 3)
  call void %72(i32 %68, i32 %70, i32 %55, i32 4)
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %68)
  call void @cqrt_free(i32 %68)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_and_i1(i32 %61, i32 %67, i32 %73)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_push(i32 %61)
  %74 = call i32 @cq_template_select_i32(i32 %67, i32 %71, i32 %62)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %67)
  %75 = add i32 %60, 1
  br label %59

76:                                               ; preds = %59
  %77 = call i32 @cqrt_tape_write_i64_controlled(i32 %61, i32 %3, i32 %54)
  %78 = call i32 @cqrt_tape_write_i32_controlled(i32 %61, i32 %3, i32 %55)
  %79 = call i32 @cqrt_tape_effect_i32_controlled(i32 %61, i32 %3, ptr null)
  %80 = call i32 @cq_template_select_i32(i32 %61, i32 %79, i32 %62)
  %81 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %80, i32 %81)
  call void @cq_template_select_i32_unc(i32 %80, i32 %61, i32 %79, i32 %62)
  call void @cqrt_free(i32 %80)
  br label %82

82:                                               ; preds = %87, %76
  %83 = phi i32 [ %57, %76 ], [ %88, %87 ]
  %84 = phi i32 [ %61, %76 ], [ %92, %87 ]
  %85 = phi i32 [ %62, %76 ], [ %91, %87 ]
  %86 = icmp eq i32 %83, 0
  br i1 %86, label %95, label %87

87:                                               ; preds = %82
  %88 = add i32 %83, -1
  %89 = call i32 @cqrt_pop()
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %85, i32 %89, i32 %90, i32 %91)
  call void @cqrt_free(i32 %85)
  call void @cqrt_not_i1(i32 %89)
  call void @cqrt_and_i1(i32 %92, i32 %89, i32 %84)
  call void @cqrt_not_i1(i32 %89)
  call void @cqrt_free(i32 %84)
  %93 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %88)
  %94 = ptrtoint ptr %93 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %89, i32 %54, i64 %94)
  call void @cqrt_free(i32 %89)
  br label %82

95:                                               ; preds = %82
  call void @cqrt_qram_load_i64_hl_unc(i32 %10, i32 %4, i64 %8)
  call void @cqrt_free(i32 %85)
  call void @cqrt_xor_i1(i32 %51, i32 %56)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cq_template_ashr_i32_hl_unc(i32 %55, i32 %6, i32 1)
  call void @cqrt_free(i32 %55)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %54, i32 %53, i32 %4, i64 %52)
  call void @cqrt_xor_i1(i32 %51, i32 %53)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_free(i32 %53)
  %96 = call i32 @cq_template_add_i32(i32 %81, i32 %35)
  %97 = call i32 @cq_template_select_i32(i32 %51, i32 %35, i32 %96)
  call void @cq_template_add_i32_unc(i32 %96, i32 %81, i32 %35)
  call void @cqrt_free(i32 %96)
  %98 = call i32 @cq_template_sub_i32(i32 %97, i32 %81)
  %99 = call i32 @cq_template_select_i32(i32 %51, i32 %97, i32 %98)
  call void @cqrt_copy_i32(i32 %99, i32 %35)
  call void @cq_template_select_i32_unc(i32 %99, i32 %51, i32 %97, i32 %98)
  call void @cqrt_free(i32 %99)
  call void @cqrt_free(i32 %35)
  call void @cq_template_sub_i32_unc(i32 %98, i32 %97, i32 %81)
  call void @cqrt_free(i32 %98)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %51, i32 %50, i32 0)
  call void @cqrt_free(i32 %51)
  call void @cq_template_and_i32_hl_unc(i32 %50, i32 %7, i32 2)
  call void @cqrt_free(i32 %50)
  %100 = call i32 @cqrt_measure_i32(i32 %97), !cq.measure !6
  %101 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @g to i64))
  %102 = call i32 @cqrt_measure_i32(i32 %101), !cq.measure !6
  %103 = shl nsw i32 %102, 6
  %104 = add nsw i32 %103, %100
  ret i32 %104
}

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_l_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cq_template_and_i32_hl(i32 %0, i32 63)
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)
  %6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  %7 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %6, i32 %3, i64 ptrtoint (ptr @g to i64))
  br label %8

8:                                                ; preds = %2
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_xor_i1(i32 %5, i32 %9)
  %10 = call i32 @cqrt_alloc_i32(i32 0)
  %11 = add i32 0, 1
  %12 = call i32 @cq_template_xor_i32_hl(i32 %7, i32 %11)
  %13 = mul i32 %11, %11
  %14 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %13)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %9, i32 %14, i32 %15)
  %16 = sub i32 %11, 0
  %17 = call i32 @cq_template_add_i32_hl(i32 %10, i32 %16)
  %18 = call i32 @cq_template_select_i32(i32 %9, i32 %17, i32 %10)
  %19 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %7)
  %20 = add i32 %11, 1
  %21 = call i32 @cq_template_xor_i32_hl(i32 %19, i32 %20)
  %22 = mul i32 %20, %20
  %23 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %23, i32 %24)
  %25 = sub i32 %20, %11
  %26 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %25)
  %27 = call i32 @cq_template_select_i32(i32 %15, i32 %26, i32 %18)
  %28 = call i32 @cq_template_select_i32(i32 %15, i32 %21, i32 %19)
  %29 = add i32 %20, 1
  %30 = call i32 @cq_template_xor_i32_hl(i32 %28, i32 %29)
  %31 = mul i32 %29, %29
  %32 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  %34 = sub i32 %29, %20
  %35 = call i32 @cq_template_add_i32_hl(i32 %27, i32 %34)
  %36 = call i32 @cq_template_select_i32(i32 %24, i32 %35, i32 %27)
  %37 = call i32 @cq_template_select_i32(i32 %24, i32 %30, i32 %28)
  %38 = add i32 %29, 1
  %39 = call i32 @cq_template_xor_i32_hl(i32 %37, i32 %38)
  %40 = mul i32 %38, %38
  %41 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %4, i32 %40)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %41, i32 %42)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %41, i32 %4, i32 %40)
  call void @cqrt_free(i32 %41)
  %43 = sub i32 %38, %29
  %44 = call i32 @cq_template_add_i32_hl(i32 %36, i32 %43)
  %45 = call i32 @cq_template_select_i32(i32 %33, i32 %44, i32 %36)
  %46 = call i32 @cq_template_select_i32(i32 %33, i32 %39, i32 %37)
  call void @cq_template_xor_i32_hl_unc(i32 %39, i32 %37, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i32_unc(i32 %37, i32 %24, i32 %30, i32 %28)
  call void @cqrt_free(i32 %37)
  call void @cq_template_xor_i32_hl_unc(i32 %30, i32 %28, i32 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_select_i32_unc(i32 %28, i32 %15, i32 %21, i32 %19)
  call void @cqrt_free(i32 %28)
  call void @cq_template_xor_i32_hl_unc(i32 %21, i32 %19, i32 %20)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i32_unc(i32 %19, i32 %9, i32 %12, i32 %7)
  call void @cqrt_free(i32 %19)
  call void @cq_template_xor_i32_hl_unc(i32 %12, i32 %7, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %7, i32 %6, i32 %3, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %7)
  call void @cqrt_xor_i1(i32 %5, i32 %6)
  call void @cqrt_not_i1(i32 %6)
  call void @cqrt_free(i32 %6)
  call void @cqrt_not_i1(i32 %5)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %5, i32 %3, i64 ptrtoint (ptr @g to i64), i32 %46)
  call void @cqrt_not_i1(i32 %5)
  %47 = call i32 @cq_template_select_i32_lh(i32 %5, i32 0, i32 %45)
  %48 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %47, i32 %48)
  call void @cq_template_select_i32_lh_unc(i32 %47, i32 %5, i32 0, i32 %45)
  call void @cqrt_free(i32 %47)
  call void @cq_template_select_i32_unc(i32 %45, i32 %33, i32 %44, i32 %36)
  call void @cqrt_free(i32 %45)
  call void @cq_template_add_i32_hl_unc(i32 %44, i32 %36, i32 %43)
  call void @cqrt_free(i32 %44)
  call void @cq_template_select_i32_unc(i32 %36, i32 %24, i32 %35, i32 %27)
  call void @cqrt_free(i32 %36)
  call void @cq_template_add_i32_hl_unc(i32 %35, i32 %27, i32 %34)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %32, i32 %4, i32 %31)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i32_unc(i32 %27, i32 %15, i32 %26, i32 %18)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i32_hl_unc(i32 %26, i32 %18, i32 %25)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %15, i32 %23, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %23, i32 %4, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cq_template_select_i32_unc(i32 %18, i32 %9, i32 %17, i32 %10)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %10, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %9, i32 %14, i32 %15)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %14, i32 %4, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_free(i32 %10)
  call void @cqrt_xor_i1(i32 %5, i32 %9)
  call void @cqrt_not_i1(i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %0, i32 63)
  call void @cqrt_free(i32 %4)
  ret i32 %48
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_l_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_l, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_l, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %60

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_and_i32_hl(i32 %1, i32 63)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)
  %11 = call i32 @cqrt_alloc_i1(i1 false)
  %12 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %11)
  %13 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %11, i32 %8, i64 ptrtoint (ptr @g to i64))
  br label %14

14:                                               ; preds = %7
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_xor_i1(i32 %10, i32 %16)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %15)
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  %18 = add i32 0, 1
  %19 = call i32 @cq_template_xor_i32_hl(i32 %13, i32 %18)
  %20 = mul i32 %18, %18
  %21 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %20)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  %23 = sub i32 %18, 0
  %24 = call i32 @cq_template_add_i32_hl(i32 %17, i32 %23)
  %25 = call i32 @cq_template_select_i32(i32 %15, i32 %24, i32 %17)
  %26 = call i32 @cq_template_select_i32(i32 %15, i32 %19, i32 %13)
  %27 = add i32 %18, 1
  %28 = call i32 @cq_template_xor_i32_hl(i32 %26, i32 %27)
  %29 = mul i32 %27, %27
  %30 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %29)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %31)
  %32 = sub i32 %27, %18
  %33 = call i32 @cq_template_add_i32_hl(i32 %25, i32 %32)
  %34 = call i32 @cq_template_select_i32(i32 %22, i32 %33, i32 %25)
  %35 = call i32 @cq_template_select_i32(i32 %22, i32 %28, i32 %26)
  %36 = add i32 %27, 1
  %37 = call i32 @cq_template_xor_i32_hl(i32 %35, i32 %36)
  %38 = mul i32 %36, %36
  %39 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %39, i32 %40)
  %41 = sub i32 %36, %27
  %42 = call i32 @cq_template_add_i32_hl(i32 %34, i32 %41)
  %43 = call i32 @cq_template_select_i32(i32 %31, i32 %42, i32 %34)
  %44 = call i32 @cq_template_select_i32(i32 %31, i32 %37, i32 %35)
  %45 = add i32 %36, 1
  %46 = call i32 @cq_template_xor_i32_hl(i32 %44, i32 %45)
  %47 = mul i32 %45, %45
  %48 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %47)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %48, i32 %49)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %48, i32 %9, i32 %47)
  call void @cqrt_free(i32 %48)
  %50 = sub i32 %45, %36
  %51 = call i32 @cq_template_add_i32_hl(i32 %43, i32 %50)
  %52 = call i32 @cq_template_select_i32(i32 %40, i32 %51, i32 %43)
  %53 = call i32 @cq_template_select_i32(i32 %40, i32 %46, i32 %44)
  call void @cq_template_xor_i32_hl_unc(i32 %46, i32 %44, i32 %45)
  call void @cqrt_free(i32 %46)
  call void @cq_template_select_i32_unc(i32 %44, i32 %31, i32 %37, i32 %35)
  call void @cqrt_free(i32 %44)
  call void @cq_template_xor_i32_hl_unc(i32 %37, i32 %35, i32 %36)
  call void @cqrt_free(i32 %37)
  call void @cq_template_select_i32_unc(i32 %35, i32 %22, i32 %28, i32 %26)
  call void @cqrt_free(i32 %35)
  call void @cq_template_xor_i32_hl_unc(i32 %28, i32 %26, i32 %27)
  call void @cqrt_free(i32 %28)
  call void @cq_template_select_i32_unc(i32 %26, i32 %15, i32 %19, i32 %13)
  call void @cqrt_free(i32 %26)
  call void @cq_template_xor_i32_hl_unc(i32 %19, i32 %13, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %13, i32 %11, i32 %8, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %13)
  call void @cqrt_and_i1(i32 %0, i32 %12, i32 %11)
  call void @cqrt_free(i32 %11)
  call void @cqrt_xor_i1(i32 %10, i32 %12)
  call void @cqrt_not_i1(i32 %12)
  call void @cqrt_free(i32 %12)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_xor_i1(i32 %10, i32 %55)
  call void @cqrt_and_i1(i32 %0, i32 %55, i32 %54)
  call void @cqrt_xor_i1(i32 %10, i32 %55)
  call void @cqrt_not_i1(i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %54, i32 %8, i64 ptrtoint (ptr @g to i64), i32 %53)
  %56 = call i32 @cq_template_select_i32_lh(i32 %10, i32 0, i32 %52)
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %56, i32 %57)
  call void @cq_template_select_i32_lh_unc(i32 %56, i32 %10, i32 0, i32 %52)
  call void @cqrt_free(i32 %56)
  call void @cq_template_select_i32_unc(i32 %52, i32 %40, i32 %51, i32 %43)
  call void @cqrt_free(i32 %52)
  call void @cq_template_add_i32_hl_unc(i32 %51, i32 %43, i32 %50)
  call void @cqrt_free(i32 %51)
  call void @cq_template_select_i32_unc(i32 %43, i32 %31, i32 %42, i32 %34)
  call void @cqrt_free(i32 %43)
  call void @cq_template_add_i32_hl_unc(i32 %42, i32 %34, i32 %41)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %31, i32 %39, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %39, i32 %9, i32 %38)
  call void @cqrt_free(i32 %39)
  call void @cq_template_select_i32_unc(i32 %34, i32 %22, i32 %33, i32 %25)
  call void @cqrt_free(i32 %34)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %25, i32 %32)
  call void @cqrt_free(i32 %33)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %30, i32 %9, i32 %29)
  call void @cqrt_free(i32 %30)
  call void @cq_template_select_i32_unc(i32 %25, i32 %15, i32 %24, i32 %17)
  call void @cqrt_free(i32 %25)
  call void @cq_template_add_i32_hl_unc(i32 %24, i32 %17, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %21, i32 %9, i32 %20)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %15)
  call void @cqrt_free(i32 %15)
  call void @cqrt_xor_i1(i32 %10, i32 %16)
  call void @cqrt_not_i1(i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %1, i32 63)
  call void @cqrt_free(i32 %9)
  %58 = load i32, ptr @__cq_act_l, align 4
  %59 = add i32 %58, -1
  store i32 %59, ptr @__cq_act_l, align 4
  ret i32 %57

60:                                               ; preds = %3
  %61 = call i32 @cqrt_alloc_i32(i32 0)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %62)
  %63 = load i32, ptr @__cq_act_l, align 4
  %64 = add i32 %63, -1
  store i32 %64, ptr @__cq_act_l, align 4
  ret i32 %61
}

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare ptr @__cq_alloc(i64, i64)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare i32 @__cq_clone_count(ptr)

declare ptr @__cq_clone_at(ptr, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare ptr @__cq_clone_resolve(ptr, i32)

declare i32 @cqrt_tape_alloc()

declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cq_template_ashr_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_f_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %6 = call ptr @__cq_alloc(i64 8, i64 8)
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = alloca { i32, ptr }, align 8
  %9 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 0
  store i32 %7, ptr %9, align 4
  %10 = load ptr, ptr %cq.mints, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %8, i32 0, i32 1
  store ptr %10, ptr %11, align 8
  store ptr %8, ptr %cq.mints, align 8
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32(i32 %12, double 1.000000e+00)
  %13 = alloca { i32, ptr }, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 0
  store i32 %12, ptr %14, align 4
  %15 = load ptr, ptr %cq.mints, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 1
  store ptr %15, ptr %16, align 8
  store ptr %13, ptr %cq.mints, align 8
  %17 = ptrtoint ptr %6 to i64
  %18 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @l to i64))
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %17, i32 %18)
  %19 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %17)
  %20 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %21 = call i32 @cqrt_alloc_i1(i1 true)
  %22 = call i32 @cqrt_alloc_i32(i32 0)
  br label %23

23:                                               ; preds = %28, %3
  %24 = phi i32 [ 0, %3 ], [ %38, %28 ]
  %25 = phi i32 [ %21, %3 ], [ %36, %28 ]
  %26 = phi i32 [ %22, %3 ], [ %37, %28 ]
  %27 = icmp ult i32 %24, %20
  br i1 %27, label %28, label %39

28:                                               ; preds = %23
  %29 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %24)
  %30 = ptrtoint ptr %29 to i64
  %31 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 %30)
  %32 = call ptr @__cq_clone_resolve(ptr %29, i32 1)
  %33 = call i32 %32(i32 %31, i32 %7, i32 %2)
  %34 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %33, i32 %34)
  %35 = call ptr @__cq_clone_resolve(ptr %29, i32 3)
  call void %35(i32 %31, i32 %33, i32 %7, i32 %2)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_and_i1(i32 %25, i32 %31, i32 %36)
  call void @cqrt_not_i1(i32 %31)
  call void @cqrt_push(i32 %25)
  %37 = call i32 @cq_template_select_i32(i32 %31, i32 %34, i32 %26)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %31)
  %38 = add i32 %24, 1
  br label %23

39:                                               ; preds = %23
  %40 = call i32 @cqrt_tape_write_i64_controlled(i32 %25, i32 %4, i32 %19)
  %41 = call i32 @cqrt_tape_write_i32_controlled(i32 %25, i32 %4, i32 %7)
  %42 = call i32 @cqrt_tape_effect_i32_controlled(i32 %25, i32 %4, ptr null)
  %43 = call i32 @cq_template_select_i32(i32 %25, i32 %42, i32 %26)
  %44 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %43, i32 %44)
  call void @cq_template_select_i32_unc(i32 %43, i32 %25, i32 %42, i32 %26)
  call void @cqrt_free(i32 %43)
  br label %45

45:                                               ; preds = %50, %39
  %46 = phi i32 [ %20, %39 ], [ %51, %50 ]
  %47 = phi i32 [ %25, %39 ], [ %55, %50 ]
  %48 = phi i32 [ %26, %39 ], [ %54, %50 ]
  %49 = icmp eq i32 %46, 0
  br i1 %49, label %58, label %50

50:                                               ; preds = %45
  %51 = add i32 %46, -1
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %48, i32 %52, i32 %53, i32 %54)
  call void @cqrt_free(i32 %48)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_and_i1(i32 %55, i32 %52, i32 %47)
  call void @cqrt_not_i1(i32 %52)
  call void @cqrt_free(i32 %47)
  %56 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %51)
  %57 = ptrtoint ptr %56 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %52, i32 %19, i64 %57)
  call void @cqrt_free(i32 %52)
  br label %45

58:                                               ; preds = %45
  call void @cqrt_free(i32 %47)
  call void @cqrt_free(i32 %48)
  %59 = call i32 @cq_template_and_i32_hl(i32 %12, i32 2)
  %60 = call i32 @cq_template_icmp_eq_i32_hl(i32 %59, i32 0)
  %61 = ptrtoint ptr %6 to i64
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_xor_i1(i32 %60, i32 %62)
  %63 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %62, i32 %5, i64 %61)
  %64 = call i32 @cq_template_ashr_i32_hl(i32 %7, i32 1)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_xor_i1(i32 %60, i32 %65)
  %66 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %67 = call i32 @cqrt_alloc_i32(i32 0)
  br label %68

68:                                               ; preds = %73, %58
  %69 = phi i32 [ 0, %58 ], [ %84, %73 ]
  %70 = phi i32 [ %65, %58 ], [ %82, %73 ]
  %71 = phi i32 [ %67, %58 ], [ %83, %73 ]
  %72 = icmp ult i32 %69, %66
  br i1 %72, label %73, label %85

73:                                               ; preds = %68
  %74 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %69)
  %75 = ptrtoint ptr %74 to i64
  %76 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 %75)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %65, i32 %76, i32 %77)
  %78 = call ptr @__cq_clone_resolve(ptr %74, i32 1)
  %79 = call i32 %78(i32 %77, i32 %64, i32 %2)
  %80 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %79, i32 %80)
  %81 = call ptr @__cq_clone_resolve(ptr %74, i32 3)
  call void %81(i32 %77, i32 %79, i32 %64, i32 %2)
  call void @cqrt_and_i1(i32 %65, i32 %76, i32 %77)
  call void @cqrt_free(i32 %77)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %76)
  call void @cqrt_and_i1(i32 %70, i32 %76, i32 %82)
  call void @cqrt_not_i1(i32 %76)
  call void @cqrt_push(i32 %70)
  %83 = call i32 @cq_template_select_i32(i32 %76, i32 %80, i32 %71)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %76)
  %84 = add i32 %69, 1
  br label %68

85:                                               ; preds = %68
  %86 = call i32 @cqrt_tape_write_i64_controlled(i32 %70, i32 %4, i32 %63)
  %87 = call i32 @cqrt_tape_write_i32_controlled(i32 %70, i32 %4, i32 %64)
  %88 = call i32 @cqrt_tape_effect_i32_controlled(i32 %70, i32 %4, ptr null)
  %89 = call i32 @cq_template_select_i32(i32 %70, i32 %88, i32 %71)
  %90 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %89, i32 %90)
  call void @cq_template_select_i32_unc(i32 %89, i32 %70, i32 %88, i32 %71)
  call void @cqrt_free(i32 %89)
  br label %91

91:                                               ; preds = %96, %85
  %92 = phi i32 [ %66, %85 ], [ %97, %96 ]
  %93 = phi i32 [ %70, %85 ], [ %101, %96 ]
  %94 = phi i32 [ %71, %85 ], [ %100, %96 ]
  %95 = icmp eq i32 %92, 0
  br i1 %95, label %104, label %96

96:                                               ; preds = %91
  %97 = add i32 %92, -1
  %98 = call i32 @cqrt_pop()
  %99 = call i32 @cqrt_pop()
  %100 = call i32 @cqrt_pop()
  %101 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %94, i32 %98, i32 %99, i32 %100)
  call void @cqrt_free(i32 %94)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_and_i1(i32 %101, i32 %98, i32 %93)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_free(i32 %93)
  %102 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %97)
  %103 = ptrtoint ptr %102 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %98, i32 %63, i64 %103)
  call void @cqrt_free(i32 %98)
  br label %91

104:                                              ; preds = %91
  call void @cqrt_qram_load_i64_hl_unc(i32 %19, i32 %5, i64 %17)
  call void @cqrt_free(i32 %94)
  call void @cqrt_xor_i1(i32 %60, i32 %65)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cq_template_ashr_i32_hl_unc(i32 %64, i32 %7, i32 1)
  call void @cqrt_free(i32 %64)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %63, i32 %62, i32 %5, i64 %61)
  call void @cqrt_xor_i1(i32 %60, i32 %62)
  call void @cqrt_not_i1(i32 %62)
  call void @cqrt_free(i32 %62)
  %105 = call i32 @cq_template_add_i32(i32 %90, i32 %44)
  %106 = call i32 @cq_template_select_i32(i32 %60, i32 %44, i32 %105)
  call void @cq_template_add_i32_unc(i32 %105, i32 %90, i32 %44)
  call void @cqrt_free(i32 %105)
  %107 = call i32 @cq_template_sub_i32(i32 %106, i32 %90)
  %108 = call i32 @cq_template_select_i32(i32 %60, i32 %106, i32 %107)
  call void @cqrt_copy_i32(i32 %108, i32 %44)
  call void @cq_template_select_i32_unc(i32 %108, i32 %60, i32 %106, i32 %107)
  call void @cqrt_free(i32 %108)
  call void @cqrt_free(i32 %44)
  call void @cq_template_sub_i32_unc(i32 %107, i32 %106, i32 %90)
  call void @cqrt_free(i32 %107)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %60, i32 %59, i32 0)
  call void @cqrt_free(i32 %60)
  call void @cq_template_and_i32_hl_unc(i32 %59, i32 %12, i32 2)
  call void @cqrt_free(i32 %59)
  %109 = call i32 @cqrt_measure_i32(i32 %106), !cq.measure !6
  %110 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64))
  %111 = call i32 @cqrt_measure_i32(i32 %110), !cq.measure !6
  %112 = shl nsw i32 %111, 6
  %113 = add nsw i32 %112, %109
  %114 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %114)
  %115 = call i32 @cqrt_alloc_i32(i32 %113)
  ret i32 %115
}

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

define internal i32 @__cq_q_f_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_f, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_f, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %126

8:                                                ; preds = %4
  %9 = call i32 @cqrt_tape_alloc()
  %10 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %11 = call ptr @__cq_alloc(i64 8, i64 8)
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %12, double 1.000000e+00)
  %13 = alloca { i32, ptr }, align 8
  %14 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 0
  store i32 %12, ptr %14, align 4
  %15 = load ptr, ptr %cq.mints, align 8
  %16 = getelementptr inbounds { i32, ptr }, ptr %13, i32 0, i32 1
  store ptr %15, ptr %16, align 8
  store ptr %13, ptr %cq.mints, align 8
  %17 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %17)
  call void @cqrt_ry_i32_controlled(i32 %0, i32 %17, double 1.000000e+00)
  %18 = alloca { i32, ptr }, align 8
  %19 = getelementptr inbounds { i32, ptr }, ptr %18, i32 0, i32 0
  store i32 %17, ptr %19, align 4
  %20 = load ptr, ptr %cq.mints, align 8
  %21 = getelementptr inbounds { i32, ptr }, ptr %18, i32 0, i32 1
  store ptr %20, ptr %21, align 8
  store ptr %18, ptr %cq.mints, align 8
  %22 = ptrtoint ptr %11 to i64
  %23 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @l to i64))
  call void @cqrt_qram_store_i64_hl_controlled(i32 %0, i32 %10, i64 %22, i32 %23)
  %24 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %0, i32 %10, i64 %22)
  %25 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  br label %27

27:                                               ; preds = %32, %8
  %28 = phi i32 [ 0, %8 ], [ %43, %32 ]
  %29 = phi i32 [ %0, %8 ], [ %41, %32 ]
  %30 = phi i32 [ %26, %8 ], [ %42, %32 ]
  %31 = icmp ult i32 %28, %25
  br i1 %31, label %32, label %44

32:                                               ; preds = %27
  %33 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %28)
  %34 = ptrtoint ptr %33 to i64
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %24, i64 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %36)
  %37 = call ptr @__cq_clone_resolve(ptr %33, i32 1)
  %38 = call i32 %37(i32 %36, i32 %12, i32 %3)
  %39 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %38, i32 %39)
  %40 = call ptr @__cq_clone_resolve(ptr %33, i32 3)
  call void %40(i32 %36, i32 %38, i32 %12, i32 %3)
  call void @cqrt_and_i1(i32 %0, i32 %35, i32 %36)
  call void @cqrt_free(i32 %36)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_and_i1(i32 %29, i32 %35, i32 %41)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_push(i32 %29)
  %42 = call i32 @cq_template_select_i32(i32 %35, i32 %39, i32 %30)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %35)
  %43 = add i32 %28, 1
  br label %27

44:                                               ; preds = %27
  %45 = call i32 @cqrt_tape_write_i64_controlled(i32 %29, i32 %9, i32 %24)
  %46 = call i32 @cqrt_tape_write_i32_controlled(i32 %29, i32 %9, i32 %12)
  %47 = call i32 @cqrt_tape_effect_i32_controlled(i32 %29, i32 %9, ptr null)
  %48 = call i32 @cq_template_select_i32(i32 %29, i32 %47, i32 %30)
  %49 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %48, i32 %49)
  call void @cq_template_select_i32_unc(i32 %48, i32 %29, i32 %47, i32 %30)
  call void @cqrt_free(i32 %48)
  br label %50

50:                                               ; preds = %55, %44
  %51 = phi i32 [ %25, %44 ], [ %56, %55 ]
  %52 = phi i32 [ %29, %44 ], [ %60, %55 ]
  %53 = phi i32 [ %30, %44 ], [ %59, %55 ]
  %54 = icmp eq i32 %51, 0
  br i1 %54, label %63, label %55

55:                                               ; preds = %50
  %56 = add i32 %51, -1
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %53, i32 %57, i32 %58, i32 %59)
  call void @cqrt_free(i32 %53)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_and_i1(i32 %60, i32 %57, i32 %52)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %52)
  %61 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %56)
  %62 = ptrtoint ptr %61 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %57, i32 %24, i64 %62)
  call void @cqrt_free(i32 %57)
  br label %50

63:                                               ; preds = %50
  call void @cqrt_free(i32 %53)
  %64 = call i32 @cq_template_and_i32_hl(i32 %17, i32 2)
  %65 = call i32 @cq_template_icmp_eq_i32_hl(i32 %64, i32 0)
  %66 = ptrtoint ptr %11 to i64
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_xor_i1(i32 %65, i32 %68)
  call void @cqrt_and_i1(i32 %0, i32 %68, i32 %67)
  %69 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %67, i32 %10, i64 %66)
  %70 = call i32 @cq_template_ashr_i32_hl(i32 %12, i32 1)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %72)
  call void @cqrt_xor_i1(i32 %65, i32 %72)
  call void @cqrt_and_i1(i32 %0, i32 %72, i32 %71)
  %73 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %74 = call i32 @cqrt_alloc_i32(i32 0)
  br label %75

75:                                               ; preds = %80, %63
  %76 = phi i32 [ 0, %63 ], [ %91, %80 ]
  %77 = phi i32 [ %71, %63 ], [ %89, %80 ]
  %78 = phi i32 [ %74, %63 ], [ %90, %80 ]
  %79 = icmp ult i32 %76, %73
  br i1 %79, label %80, label %92

80:                                               ; preds = %75
  %81 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %76)
  %82 = ptrtoint ptr %81 to i64
  %83 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 %82)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %71, i32 %83, i32 %84)
  %85 = call ptr @__cq_clone_resolve(ptr %81, i32 1)
  %86 = call i32 %85(i32 %84, i32 %70, i32 %3)
  %87 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %86, i32 %87)
  %88 = call ptr @__cq_clone_resolve(ptr %81, i32 3)
  call void %88(i32 %84, i32 %86, i32 %70, i32 %3)
  call void @cqrt_and_i1(i32 %71, i32 %83, i32 %84)
  call void @cqrt_free(i32 %84)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %83)
  call void @cqrt_and_i1(i32 %77, i32 %83, i32 %89)
  call void @cqrt_not_i1(i32 %83)
  call void @cqrt_push(i32 %77)
  %90 = call i32 @cq_template_select_i32(i32 %83, i32 %87, i32 %78)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %83)
  %91 = add i32 %76, 1
  br label %75

92:                                               ; preds = %75
  %93 = call i32 @cqrt_tape_write_i64_controlled(i32 %77, i32 %9, i32 %69)
  %94 = call i32 @cqrt_tape_write_i32_controlled(i32 %77, i32 %9, i32 %70)
  %95 = call i32 @cqrt_tape_effect_i32_controlled(i32 %77, i32 %9, ptr null)
  %96 = call i32 @cq_template_select_i32(i32 %77, i32 %95, i32 %78)
  %97 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %96, i32 %97)
  call void @cq_template_select_i32_unc(i32 %96, i32 %77, i32 %95, i32 %78)
  call void @cqrt_free(i32 %96)
  br label %98

98:                                               ; preds = %103, %92
  %99 = phi i32 [ %73, %92 ], [ %104, %103 ]
  %100 = phi i32 [ %77, %92 ], [ %108, %103 ]
  %101 = phi i32 [ %78, %92 ], [ %107, %103 ]
  %102 = icmp eq i32 %99, 0
  br i1 %102, label %111, label %103

103:                                              ; preds = %98
  %104 = add i32 %99, -1
  %105 = call i32 @cqrt_pop()
  %106 = call i32 @cqrt_pop()
  %107 = call i32 @cqrt_pop()
  %108 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %101, i32 %105, i32 %106, i32 %107)
  call void @cqrt_free(i32 %101)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_and_i1(i32 %108, i32 %105, i32 %100)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_free(i32 %100)
  %109 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %104)
  %110 = ptrtoint ptr %109 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %105, i32 %69, i64 %110)
  call void @cqrt_free(i32 %105)
  br label %98

111:                                              ; preds = %98
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %24, i32 %0, i32 %10, i64 %22)
  call void @cqrt_free(i32 %101)
  call void @cqrt_and_i1(i32 %0, i32 %72, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_xor_i1(i32 %65, i32 %72)
  call void @cqrt_not_i1(i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cq_template_ashr_i32_hl_unc(i32 %70, i32 %12, i32 1)
  call void @cqrt_free(i32 %70)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %69, i32 %67, i32 %10, i64 %66)
  call void @cqrt_and_i1(i32 %0, i32 %68, i32 %67)
  call void @cqrt_free(i32 %67)
  call void @cqrt_xor_i1(i32 %65, i32 %68)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_free(i32 %68)
  %112 = call i32 @cq_template_add_i32(i32 %97, i32 %49)
  %113 = call i32 @cq_template_select_i32(i32 %65, i32 %49, i32 %112)
  %114 = call i32 @cq_template_sub_i32(i32 %113, i32 %97)
  call void @cq_template_sub_i32_unc(i32 %114, i32 %113, i32 %97)
  call void @cqrt_free(i32 %114)
  %115 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %113, i32 %115)
  call void @cq_template_select_i32_unc(i32 %113, i32 %65, i32 %49, i32 %112)
  call void @cqrt_free(i32 %113)
  call void @cq_template_add_i32_unc(i32 %112, i32 %97, i32 %49)
  call void @cqrt_free(i32 %112)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %65, i32 %64, i32 0)
  call void @cqrt_free(i32 %65)
  call void @cq_template_and_i32_hl_unc(i32 %64, i32 %17, i32 2)
  call void @cqrt_free(i32 %64)
  %116 = call i32 @cqrt_measure_i32(i32 %115), !cq.measure !6
  %117 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %10, i64 ptrtoint (ptr @g to i64))
  %118 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %117, i32 %118)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %117, i32 %0, i32 %10, i64 ptrtoint (ptr @g to i64))
  call void @cqrt_free(i32 %117)
  %119 = call i32 @cqrt_measure_i32(i32 %118), !cq.measure !6
  %120 = call i32 @cq_template_shl_i32_hl(i32 %118, i32 6)
  %121 = call i32 @cq_template_add_i32(i32 %120, i32 %115)
  %122 = call i32 @cq_template_sub_i32(i32 %121, i32 %115)
  call void @cqrt_copy_i32(i32 %122, i32 %120)
  call void @cq_template_sub_i32_unc(i32 %122, i32 %121, i32 %115)
  call void @cqrt_free(i32 %122)
  call void @cqrt_free(i32 %120)
  %123 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %123)
  %124 = load i32, ptr @__cq_act_f, align 4
  %125 = add i32 %124, -1
  store i32 %125, ptr @__cq_act_f, align 4
  ret i32 %121

126:                                              ; preds = %4
  %127 = call i32 @cqrt_alloc_i32(i32 0)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %128)
  call void @cqrt_push(i32 0)
  %129 = load i32, ptr @__cq_act_f, align 4
  %130 = add i32 %129, -1
  store i32 %130, ptr @__cq_act_f, align 4
  ret i32 %127
}

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

define internal i32 @__cq_q_f_11_t_pure(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_tape_alloc()
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 8, i64 8)
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32(i32 %7, double 1.000000e+00)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %8)
  call void @cqrt_ry_i32(i32 %8, double 1.000000e+00)
  %9 = ptrtoint ptr %6 to i64
  %10 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @l to i64))
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %9, i32 %10)
  %11 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %9)
  %12 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %13 = call i32 @cqrt_alloc_i1(i1 true)
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  br label %15

15:                                               ; preds = %20, %3
  %16 = phi i32 [ 0, %3 ], [ %30, %20 ]
  %17 = phi i32 [ %13, %3 ], [ %28, %20 ]
  %18 = phi i32 [ %14, %3 ], [ %29, %20 ]
  %19 = icmp ult i32 %16, %12
  br i1 %19, label %20, label %31

20:                                               ; preds = %15
  %21 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %16)
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %22)
  %24 = call ptr @__cq_clone_resolve(ptr %21, i32 1)
  %25 = call i32 %24(i32 %23, i32 %7, i32 %2)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %25, i32 %26)
  %27 = call ptr @__cq_clone_resolve(ptr %21, i32 3)
  call void %27(i32 %23, i32 %25, i32 %7, i32 %2)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_and_i1(i32 %17, i32 %23, i32 %28)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_push(i32 %17)
  %29 = call i32 @cq_template_select_i32(i32 %23, i32 %26, i32 %18)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %23)
  %30 = add i32 %16, 1
  br label %15

31:                                               ; preds = %15
  %32 = call i32 @cqrt_tape_write_i64_controlled(i32 %17, i32 %4, i32 %11)
  %33 = call i32 @cqrt_tape_write_i32_controlled(i32 %17, i32 %4, i32 %7)
  %34 = call i32 @cqrt_tape_effect_i32_controlled(i32 %17, i32 %4, ptr null)
  %35 = call i32 @cq_template_select_i32(i32 %17, i32 %34, i32 %18)
  %36 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %35, i32 %36)
  call void @cq_template_select_i32_unc(i32 %35, i32 %17, i32 %34, i32 %18)
  call void @cqrt_free(i32 %35)
  br label %37

37:                                               ; preds = %42, %31
  %38 = phi i32 [ %12, %31 ], [ %43, %42 ]
  %39 = phi i32 [ %17, %31 ], [ %47, %42 ]
  %40 = phi i32 [ %18, %31 ], [ %46, %42 ]
  %41 = icmp eq i32 %38, 0
  br i1 %41, label %50, label %42

42:                                               ; preds = %37
  %43 = add i32 %38, -1
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %40, i32 %44, i32 %45, i32 %46)
  call void @cqrt_free(i32 %40)
  call void @cqrt_not_i1(i32 %44)
  call void @cqrt_and_i1(i32 %47, i32 %44, i32 %39)
  call void @cqrt_not_i1(i32 %44)
  call void @cqrt_free(i32 %39)
  %48 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %43)
  %49 = ptrtoint ptr %48 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %44, i32 %11, i64 %49)
  call void @cqrt_free(i32 %44)
  br label %37

50:                                               ; preds = %37
  call void @cqrt_free(i32 %39)
  call void @cqrt_free(i32 %40)
  %51 = call i32 @cq_template_and_i32_hl(i32 %8, i32 2)
  %52 = call i32 @cq_template_icmp_eq_i32_hl(i32 %51, i32 0)
  %53 = ptrtoint ptr %6 to i64
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_xor_i1(i32 %52, i32 %54)
  %55 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %54, i32 %5, i64 %53)
  %56 = call i32 @cq_template_ashr_i32_hl(i32 %7, i32 1)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_xor_i1(i32 %52, i32 %57)
  %58 = call i32 @__cq_clone_count(ptr @.cq.sig)
  %59 = call i32 @cqrt_alloc_i32(i32 0)
  br label %60

60:                                               ; preds = %65, %50
  %61 = phi i32 [ 0, %50 ], [ %76, %65 ]
  %62 = phi i32 [ %57, %50 ], [ %74, %65 ]
  %63 = phi i32 [ %59, %50 ], [ %75, %65 ]
  %64 = icmp ult i32 %61, %58
  br i1 %64, label %65, label %77

65:                                               ; preds = %60
  %66 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %61)
  %67 = ptrtoint ptr %66 to i64
  %68 = call i32 @cq_template_icmp_eq_i64_hl(i32 %55, i64 %67)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %68, i32 %69)
  %70 = call ptr @__cq_clone_resolve(ptr %66, i32 1)
  %71 = call i32 %70(i32 %69, i32 %56, i32 %2)
  %72 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %71, i32 %72)
  %73 = call ptr @__cq_clone_resolve(ptr %66, i32 3)
  call void %73(i32 %69, i32 %71, i32 %56, i32 %2)
  call void @cqrt_and_i1(i32 %57, i32 %68, i32 %69)
  call void @cqrt_free(i32 %69)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_and_i1(i32 %62, i32 %68, i32 %74)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_push(i32 %62)
  %75 = call i32 @cq_template_select_i32(i32 %68, i32 %72, i32 %63)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %68)
  %76 = add i32 %61, 1
  br label %60

77:                                               ; preds = %60
  %78 = call i32 @cqrt_tape_write_i64_controlled(i32 %62, i32 %4, i32 %55)
  %79 = call i32 @cqrt_tape_write_i32_controlled(i32 %62, i32 %4, i32 %56)
  %80 = call i32 @cqrt_tape_effect_i32_controlled(i32 %62, i32 %4, ptr null)
  %81 = call i32 @cq_template_select_i32(i32 %62, i32 %80, i32 %63)
  %82 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %81, i32 %82)
  call void @cq_template_select_i32_unc(i32 %81, i32 %62, i32 %80, i32 %63)
  call void @cqrt_free(i32 %81)
  br label %83

83:                                               ; preds = %88, %77
  %84 = phi i32 [ %58, %77 ], [ %89, %88 ]
  %85 = phi i32 [ %62, %77 ], [ %93, %88 ]
  %86 = phi i32 [ %63, %77 ], [ %92, %88 ]
  %87 = icmp eq i32 %84, 0
  br i1 %87, label %96, label %88

88:                                               ; preds = %83
  %89 = add i32 %84, -1
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  %93 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %86, i32 %90, i32 %91, i32 %92)
  call void @cqrt_free(i32 %86)
  call void @cqrt_not_i1(i32 %90)
  call void @cqrt_and_i1(i32 %93, i32 %90, i32 %85)
  call void @cqrt_not_i1(i32 %90)
  call void @cqrt_free(i32 %85)
  %94 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %89)
  %95 = ptrtoint ptr %94 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %90, i32 %55, i64 %95)
  call void @cqrt_free(i32 %90)
  br label %83

96:                                               ; preds = %83
  call void @cqrt_qram_load_i64_hl_unc(i32 %11, i32 %5, i64 %9)
  call void @cqrt_free(i32 %86)
  call void @cqrt_xor_i1(i32 %52, i32 %57)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cq_template_ashr_i32_hl_unc(i32 %56, i32 %7, i32 1)
  call void @cqrt_free(i32 %56)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %55, i32 %54, i32 %5, i64 %53)
  call void @cqrt_xor_i1(i32 %52, i32 %54)
  call void @cqrt_not_i1(i32 %54)
  call void @cqrt_free(i32 %54)
  %97 = call i32 @cq_template_add_i32(i32 %82, i32 %36)
  %98 = call i32 @cq_template_select_i32(i32 %52, i32 %36, i32 %97)
  call void @cq_template_add_i32_unc(i32 %97, i32 %82, i32 %36)
  call void @cqrt_free(i32 %97)
  %99 = call i32 @cq_template_sub_i32(i32 %98, i32 %82)
  %100 = call i32 @cq_template_select_i32(i32 %52, i32 %98, i32 %99)
  call void @cqrt_copy_i32(i32 %100, i32 %36)
  call void @cq_template_select_i32_unc(i32 %100, i32 %52, i32 %98, i32 %99)
  call void @cqrt_free(i32 %100)
  call void @cqrt_free(i32 %36)
  call void @cq_template_sub_i32_unc(i32 %99, i32 %98, i32 %82)
  call void @cqrt_free(i32 %99)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %52, i32 %51, i32 0)
  call void @cqrt_free(i32 %52)
  call void @cq_template_and_i32_hl_unc(i32 %51, i32 %8, i32 2)
  call void @cqrt_free(i32 %51)
  %101 = call i32 @cqrt_measure_i32(i32 %98), !cq.measure !6
  %102 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64))
  %103 = call i32 @cqrt_measure_i32(i32 %102), !cq.measure !6
  %104 = shl nsw i32 %103, 6
  %105 = add nsw i32 %104, %101
  %106 = call i32 @cqrt_alloc_i32(i32 %105)
  ret i32 %106
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @l, ptr @.cq.sig, ptr @__cq_q_l_1_t, ptr @__cq_q_l_1_t_ctl, ptr @__cq_q_l_1_t_unc, ptr @__cq_q_l_1_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_11_t, ptr @__cq_q_f_11_t_ctl, ptr @__cq_q_f_11_t_unc, ptr @__cq_q_f_11_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_l_1_t_unc(i32 %0, i32 %1, i32 %2) {
  ret void
}

define internal void @__cq_q_l_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_l, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_l, align 4
  %7 = load i32, ptr @__cq_act_l, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_l, align 4
  ret void
}

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

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
