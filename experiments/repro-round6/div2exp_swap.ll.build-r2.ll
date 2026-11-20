; ModuleID = '<stdin>'
source_filename = "div2exp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@limbs = local_unnamed_addr global [4 x i64] [i64 0, i64 0, i64 5, i64 8], align 16
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [23 x i8] c"i32 (i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %arg, i32 noundef %arg1, double noundef %arg2) local_unnamed_addr #0 {
  %1 = call i32 @__cq_mem()
  %2 = call i32 @cqrt_alloc_i32(i32 %arg)
  call void @cqrt_ry_i32(i32 %2, double %arg2)
  %3 = call i32 @cqrt_alloc_i32(i32 %arg1)
  call void @cqrt_ry_i32(i32 %3, double %arg2)
  %4 = call i32 @cq_template_lshr_i32_hl(i32 %3, i32 2)
  %5 = call i32 @cq_template_abs_i32(i32 %2)
  %6 = call i32 @cq_template_icmp_ult_i32(i32 %4, i32 %5)
  %7 = call i32 @cq_template_icmp_ult_i32_hl(i32 %3, i32 4)
  br label %8

8:                                                ; preds = %0
  %9 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %6, i32 %9)
  call void @cqrt_and_i1(i32 %6, i32 %7, i32 %9)
  %10 = call i32 @cqrt_alloc_i1(i1 false)
  %11 = and i32 0, 3
  %12 = zext i32 %11 to i64
  %13 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %12
  %14 = ptrtoint ptr %13 to i64
  %15 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %9, i32 %1, i64 %14)
  %16 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 0)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %9, i32 %18, i32 %19)
  %20 = call i32 @cq_template_select_i1(i32 %19, i32 %17, i32 %10)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %9, i32 %16, i32 %21)
  br label %22

22:                                               ; preds = %52, %8
  %from = phi i32 [ 0, %52 ], [ 1, %8 ]
  %23 = phi i32 [ 0, %8 ], [ %48, %52 ]
  %24 = phi i32 [ %21, %8 ], [ %63, %52 ]
  %25 = phi i32 [ 0, %8 ], [ %28, %52 ]
  %26 = phi i32 [ %16, %8 ], [ %58, %52 ]
  %27 = phi i32 [ %20, %8 ], [ %62, %52 ]
  call void @cqrt_push(i32 %from)
  %28 = add i32 %25, 1
  %29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 %28)
  %30 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)
  %31 = call i32 @cq_template_zext_i32_to_i64(i32 %30)
  %32 = call i32 @cq_template_mul_i64_hl(i32 %31, i64 8)
  %33 = call i32 @cq_template_add_i64_hl(i32 %32, i64 ptrtoint (ptr @limbs to i64))
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %26, i32 %34)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %34, i32 %35)
  %36 = call i32 @cqrt_qram_load_i64_controlled(i32 %35, i32 %1, i32 %33)
  %37 = call i32 @cq_template_and_i32_hl(i32 %3, i32 3)
  %38 = call i32 @cq_template_zext_i32_to_i64(i32 %37)
  %39 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %38)
  %40 = call i32 @cq_template_xor_i64_hl(i32 %39, i64 -1)
  %41 = call i32 @cq_template_and_i64(i32 %36, i32 %40)
  %42 = call i32 @cq_template_icmp_eq_i64_hl(i32 %41, i64 0)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %26, i32 %43)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %43, i32 %44)
  %45 = call i32 @cq_template_select_i1(i32 %44, i32 %42, i32 %27)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %26, i32 %46)
  call void @cqrt_and_i1(i32 %26, i32 %29, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %46, i32 %47)
  %48 = add i32 %23, 1
  %49 = icmp ult i32 %48, 4
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %28)
  br i1 %49, label %52, label %50

50:                                               ; preds = %22
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %47, i32 %51)
  br label %67

52:                                               ; preds = %22
  %53 = and i32 %28, 3
  %54 = zext i32 %53 to i64
  %55 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %54
  %56 = ptrtoint ptr %55 to i64
  %57 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %47, i32 %1, i64 %56)
  %58 = call i32 @cq_template_icmp_eq_i64_hl(i32 %57, i64 0)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %60)
  call void @cqrt_xor_i1(i32 %58, i32 %60)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %60, i32 %61)
  %62 = call i32 @cq_template_select_i1(i32 %61, i32 %59, i32 %45)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %58, i32 %63)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %57)
  %64 = trunc i64 %56 to i32
  call void @cqrt_push(i32 %64)
  %65 = lshr i64 %56, 32
  %66 = trunc i64 %65 to i32
  call void @cqrt_push(i32 %66)
  br label %22

67:                                               ; preds = %50
  %68 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)
  %69 = call i32 @cq_template_zext_i32_to_i64(i32 %68)
  %70 = call i32 @cq_template_mul_i64_hl(i32 %69, i64 8)
  %71 = call i32 @cq_template_add_i64_hl(i32 %70, i64 ptrtoint (ptr @limbs to i64))
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %7, i32 %6, i32 %72)
  %73 = call i32 @cqrt_qram_load_i64_controlled(i32 %72, i32 %1, i32 %71)
  %74 = call i32 @cq_template_and_i32_hl(i32 %3, i32 3)
  %75 = call i32 @cq_template_zext_i32_to_i64(i32 %74)
  %76 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %75)
  %77 = call i32 @cq_template_xor_i64_hl(i32 %76, i64 -1)
  %78 = call i32 @cq_template_and_i64(i32 %73, i32 %77)
  %79 = call i32 @cq_template_icmp_eq_i64_hl(i32 %78, i64 0)
  %80 = call i32 @cq_template_icmp_eq_i32_hl(i32 %2, i32 0)
  %81 = call i32 @cq_template_select_i1(i32 %7, i32 %79, i32 %45)
  %82 = call i32 @cq_template_select_i1(i32 %6, i32 %81, i32 %80)
  %83 = call i32 @cq_template_zext_i1_to_i32(i32 %82)
  call void @cq_template_select_i1_unc(i32 %82, i32 %6, i32 %81, i32 %80)
  call void @cqrt_free(i32 %82)
  call void @cq_template_select_i1_unc(i32 %81, i32 %7, i32 %79, i32 %45)
  call void @cqrt_free(i32 %81)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %80, i32 %2, i32 0)
  call void @cqrt_free(i32 %80)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %79, i32 %78, i64 0)
  call void @cqrt_free(i32 %79)
  call void @cq_template_and_i64_unc(i32 %78, i32 %73, i32 %77)
  call void @cqrt_free(i32 %78)
  call void @cq_template_xor_i64_hl_unc(i32 %77, i32 %76, i64 -1)
  call void @cqrt_free(i32 %77)
  call void @cq_template_shl_i64_lh_unc(i32 %76, i64 -1, i32 %75)
  call void @cqrt_free(i32 %76)
  call void @cq_template_zext_i32_to_i64_unc(i32 %75, i32 %74)
  call void @cqrt_free(i32 %75)
  call void @cq_template_and_i32_hl_unc(i32 %74, i32 %3, i32 3)
  call void @cqrt_free(i32 %74)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %73, i32 %72, i32 %1, i32 %71)
  call void @cqrt_free(i32 %73)
  call void @cqrt_and_i1(i32 %7, i32 %6, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cq_template_add_i64_hl_unc(i32 %71, i32 %70, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %71)
  call void @cq_template_mul_i64_hl_unc(i32 %70, i32 %69, i64 8)
  call void @cqrt_free(i32 %70)
  call void @cq_template_zext_i32_to_i64_unc(i32 %69, i32 %68)
  call void @cqrt_free(i32 %69)
  call void @cq_template_and_i32_hl_unc(i32 %68, i32 %4, i32 3)
  call void @cqrt_free(i32 %68)
  br label %86

84:                                               ; preds = %85
  call void @cqrt_and_i1(i32 %9, i32 %16, i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cq_template_select_i1_unc(i32 %20, i32 %19, i32 %17, i32 %10)
  call void @cqrt_free(i32 %20)
  call void @cqrt_and_i1(i32 %9, i32 %18, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %16, i32 %15, i64 0)
  call void @cqrt_free(i32 %16)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %15, i32 %9, i32 %1, i64 %14)
  call void @cqrt_free(i32 %15)
  call void @cqrt_free(i32 %10)
  call void @cqrt_and_i1(i32 %6, i32 %7, i32 %9)
  call void @cqrt_xor_i1(i32 %6, i32 %9)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %7, i32 %3, i32 4)
  call void @cqrt_free(i32 %7)
  call void @cq_template_icmp_ult_i32_unc(i32 %6, i32 %4, i32 %5)
  call void @cqrt_free(i32 %6)
  call void @cq_template_abs_i32_unc(i32 %5, i32 %2)
  call void @cqrt_free(i32 %5)
  call void @cq_template_lshr_i32_hl_unc(i32 %4, i32 %3, i32 2)
  call void @cqrt_free(i32 %4)
  ret i32 %83

85:                                               ; preds = %86
  br label %84

86:                                               ; preds = %67, %111
  %87 = call i32 @cqrt_pop()
  %88 = call i32 @cqrt_pop()
  %89 = call i32 @cqrt_pop()
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  %93 = call i32 @cqrt_pop()
  %94 = call i32 @cqrt_pop()
  %95 = call i32 @cqrt_pop()
  %96 = call i32 @cqrt_pop()
  %97 = call i32 @cqrt_pop()
  %98 = call i32 @cqrt_pop()
  %99 = call i32 @cqrt_pop()
  %100 = call i32 @cqrt_pop()
  %101 = call i32 @cqrt_pop()
  %102 = call i32 @cqrt_pop()
  %103 = call i32 @cqrt_pop()
  %104 = call i32 @cqrt_pop()
  %105 = call i32 @cqrt_pop()
  %106 = call i32 @cqrt_pop()
  %107 = call i32 @cqrt_pop()
  %108 = call i32 @cqrt_pop()
  %109 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %109, i32 %108, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %106, i32 %105, i32 %108)
  call void @cqrt_xor_i1(i32 %106, i32 %108)
  call void @cqrt_free(i32 %108)
  call void @cq_template_select_i1_unc(i32 %104, i32 %103, i32 %102, i32 %101)
  call void @cqrt_free(i32 %104)
  call void @cqrt_and_i1(i32 %109, i32 %100, i32 %103)
  call void @cqrt_free(i32 %103)
  call void @cqrt_and_i1(i32 %105, i32 %106, i32 %100)
  call void @cqrt_free(i32 %100)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %102, i32 %99, i64 0)
  call void @cqrt_free(i32 %102)
  call void @cq_template_and_i64_unc(i32 %99, i32 %98, i32 %97)
  call void @cqrt_free(i32 %99)
  call void @cq_template_xor_i64_hl_unc(i32 %97, i32 %96, i64 -1)
  call void @cqrt_free(i32 %97)
  call void @cq_template_shl_i64_lh_unc(i32 %96, i64 -1, i32 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_zext_i32_to_i64_unc(i32 %95, i32 %94)
  call void @cqrt_free(i32 %95)
  call void @cq_template_and_i32_hl_unc(i32 %94, i32 %3, i32 3)
  call void @cqrt_free(i32 %94)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %98, i32 %93, i32 %1, i32 %92)
  call void @cqrt_free(i32 %98)
  call void @cqrt_and_i1(i32 %109, i32 %91, i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cqrt_and_i1(i32 %105, i32 %106, i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cq_template_add_i64_hl_unc(i32 %92, i32 %90, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %92)
  call void @cq_template_mul_i64_hl_unc(i32 %90, i32 %89, i64 8)
  call void @cqrt_free(i32 %90)
  call void @cq_template_zext_i32_to_i64_unc(i32 %89, i32 %88)
  call void @cqrt_free(i32 %89)
  call void @cq_template_and_i32_hl_unc(i32 %88, i32 %4, i32 3)
  call void @cqrt_free(i32 %88)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %105, i32 %4, i32 %87)
  call void @cqrt_free(i32 %105)
  %110 = call i32 @cqrt_pop()
  switch i32 %110, label %111 [
    i32 1, label %85
  ]

111:                                              ; preds = %86
  %112 = call i32 @cqrt_pop()
  %113 = zext i32 %112 to i64
  %114 = shl i64 %113, 32
  %115 = or i64 0, %114
  %116 = call i32 @cqrt_pop()
  %117 = zext i32 %116 to i64
  %118 = or i64 %115, %117
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  %123 = call i32 @cqrt_pop()
  %124 = call i32 @cqrt_pop()
  %125 = call i32 @cqrt_pop()
  %126 = call i32 @cqrt_pop()
  %127 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %127, i32 %126, i32 %125)
  call void @cqrt_free(i32 %125)
  call void @cq_template_select_i1_unc(i32 %124, i32 %123, i32 %122, i32 %121)
  call void @cqrt_free(i32 %124)
  call void @cqrt_and_i1(i32 %127, i32 %120, i32 %123)
  call void @cqrt_free(i32 %123)
  call void @cqrt_xor_i1(i32 %126, i32 %120)
  call void @cqrt_not_i1(i32 %120)
  call void @cqrt_free(i32 %120)
  call void @cqrt_free(i32 %122)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %126, i32 %119, i64 0)
  call void @cqrt_free(i32 %126)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %119, i32 %127, i32 %1, i64 %118)
  call void @cqrt_free(i32 %119)
  br label %86
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #1

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_abs_i32(i32)

declare i32 @cq_template_icmp_ult_i32(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare void @cqrt_not_i1(i32)

declare i32 @cq_template_select_i1(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare i32 @cq_template_shl_i64_lh(i64, i32)

declare i32 @cq_template_xor_i64_hl(i32, i64)

declare i32 @cq_template_and_i64(i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare void @cq_template_select_i1_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_and_i64_unc(i32, i32, i32)

declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)

declare void @cq_template_shl_i64_lh_unc(i32, i64, i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ult_i32_unc(i32, i32, i32)

declare void @cq_template_abs_i32_unc(i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_111_t(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @__cq_mem()
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %7)
  call void @cqrt_ry_i32_qangle(i32 %7, i32 %2)
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %8)
  call void @cqrt_ry_i32_qangle(i32 %8, i32 %2)
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 2)
  %10 = call i32 @cq_template_abs_i32(i32 %7)
  %11 = call i32 @cq_template_icmp_ult_i32(i32 %9, i32 %10)
  %12 = call i32 @cq_template_icmp_ult_i32_hl(i32 %8, i32 4)
  br label %13

13:                                               ; preds = %4
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %11, i32 %14)
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %14)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = and i32 0, 3
  %17 = zext i32 %16 to i64
  %18 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %17
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %14, i32 %6, i64 %19)
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_xor_i1(i32 %21, i32 %23)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %23, i32 %24)
  %25 = call i32 @cq_template_select_i1(i32 %24, i32 %22, i32 %15)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %21, i32 %26)
  %27 = call i32 @llvm.umin.i32(i32 %3, i32 1073741823)
  %28 = icmp ult i32 %3, 1073741823
  %29 = icmp ult i32 0, %27
  br i1 %29, label %30, label %58

30:                                               ; preds = %64, %13
  %from = phi i32 [ 0, %64 ], [ 1, %13 ]
  %31 = phi i32 [ 0, %13 ], [ %56, %64 ]
  %32 = phi i32 [ %26, %13 ], [ %75, %64 ]
  %33 = phi i32 [ 0, %13 ], [ %36, %64 ]
  %34 = phi i32 [ %21, %13 ], [ %70, %64 ]
  %35 = phi i32 [ %25, %13 ], [ %74, %64 ]
  call void @cqrt_push(i32 %from)
  %36 = add i32 %33, 1
  %37 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %36)
  %38 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)
  %39 = call i32 @cq_template_zext_i32_to_i64(i32 %38)
  %40 = call i32 @cq_template_mul_i64_hl(i32 %39, i64 8)
  %41 = call i32 @cq_template_add_i64_hl(i32 %40, i64 ptrtoint (ptr @limbs to i64))
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %37, i32 %34, i32 %42)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %42, i32 %43)
  %44 = call i32 @cqrt_qram_load_i64_controlled(i32 %43, i32 %6, i32 %41)
  %45 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)
  %46 = call i32 @cq_template_zext_i32_to_i64(i32 %45)
  %47 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %46)
  %48 = call i32 @cq_template_xor_i64_hl(i32 %47, i64 -1)
  %49 = call i32 @cq_template_and_i64(i32 %44, i32 %48)
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %49, i64 0)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %37, i32 %34, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i1(i32 %52, i32 %50, i32 %35)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %34, i32 %54)
  call void @cqrt_and_i1(i32 %34, i32 %37, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %54, i32 %55)
  %56 = add i32 %31, 1
  %57 = icmp ult i32 %56, %27
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %36)
  br i1 %57, label %64, label %58

58:                                               ; preds = %30, %13
  %59 = phi i32 [ 0, %13 ], [ 1, %30 ]
  %60 = phi i32 [ 0, %13 ], [ %36, %30 ]
  %61 = phi i32 [ %21, %13 ], [ %34, %30 ]
  %62 = phi i32 [ %25, %13 ], [ %53, %30 ]
  %63 = phi i32 [ %26, %13 ], [ %55, %30 ]
  br i1 %28, label %79, label %81

64:                                               ; preds = %30
  %65 = and i32 %36, 3
  %66 = zext i32 %65 to i64
  %67 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %66
  %68 = ptrtoint ptr %67 to i64
  %69 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %55, i32 %6, i64 %68)
  %70 = call i32 @cq_template_icmp_eq_i64_hl(i32 %69, i64 0)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %72)
  call void @cqrt_xor_i1(i32 %70, i32 %72)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %72, i32 %73)
  %74 = call i32 @cq_template_select_i1(i32 %73, i32 %71, i32 %53)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %70, i32 %75)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %69)
  %76 = trunc i64 %68 to i32
  call void @cqrt_push(i32 %76)
  %77 = lshr i64 %68, 32
  %78 = trunc i64 %77 to i32
  call void @cqrt_push(i32 %78)
  br label %30

79:                                               ; preds = %58
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %63, i32 %80)
  br label %82

81:                                               ; preds = %58
  br label %82

82:                                               ; preds = %79, %81
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %62, i32 %83)
  br label %84

84:                                               ; preds = %82
  %85 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)
  %86 = call i32 @cq_template_zext_i32_to_i64(i32 %85)
  %87 = call i32 @cq_template_mul_i64_hl(i32 %86, i64 8)
  %88 = call i32 @cq_template_add_i64_hl(i32 %87, i64 ptrtoint (ptr @limbs to i64))
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %12, i32 %11, i32 %89)
  %90 = call i32 @cqrt_qram_load_i64_controlled(i32 %89, i32 %6, i32 %88)
  %91 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)
  %92 = call i32 @cq_template_zext_i32_to_i64(i32 %91)
  %93 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %92)
  %94 = call i32 @cq_template_xor_i64_hl(i32 %93, i64 -1)
  %95 = call i32 @cq_template_and_i64(i32 %90, i32 %94)
  %96 = call i32 @cq_template_icmp_eq_i64_hl(i32 %95, i64 0)
  %97 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %98 = call i32 @cq_template_select_i1(i32 %12, i32 %96, i32 %83)
  %99 = call i32 @cq_template_select_i1(i32 %11, i32 %98, i32 %97)
  %100 = call i32 @cq_template_zext_i1_to_i32(i32 %99)
  call void @cqrt_push(i32 %7)
  call void @cqrt_push(i32 %8)
  %101 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %100, i32 %101)
  call void @cq_template_zext_i1_to_i32_unc(i32 %100, i32 %99)
  call void @cqrt_free(i32 %100)
  call void @cq_template_select_i1_unc(i32 %99, i32 %11, i32 %98, i32 %97)
  call void @cqrt_free(i32 %99)
  call void @cq_template_select_i1_unc(i32 %98, i32 %12, i32 %96, i32 %83)
  call void @cqrt_free(i32 %98)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %97, i32 %7, i32 0)
  call void @cqrt_free(i32 %97)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %96, i32 %95, i64 0)
  call void @cqrt_free(i32 %96)
  call void @cq_template_and_i64_unc(i32 %95, i32 %90, i32 %94)
  call void @cqrt_free(i32 %95)
  call void @cq_template_xor_i64_hl_unc(i32 %94, i32 %93, i64 -1)
  call void @cqrt_free(i32 %94)
  call void @cq_template_shl_i64_lh_unc(i32 %93, i64 -1, i32 %92)
  call void @cqrt_free(i32 %93)
  call void @cq_template_zext_i32_to_i64_unc(i32 %92, i32 %91)
  call void @cqrt_free(i32 %92)
  call void @cq_template_and_i32_hl_unc(i32 %91, i32 %8, i32 3)
  call void @cqrt_free(i32 %91)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %90, i32 %89, i32 %6, i32 %88)
  call void @cqrt_free(i32 %90)
  call void @cqrt_and_i1(i32 %12, i32 %11, i32 %89)
  call void @cqrt_free(i32 %89)
  call void @cq_template_add_i64_hl_unc(i32 %88, i32 %87, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %88)
  call void @cq_template_mul_i64_hl_unc(i32 %87, i32 %86, i64 8)
  call void @cqrt_free(i32 %87)
  call void @cq_template_zext_i32_to_i64_unc(i32 %86, i32 %85)
  call void @cqrt_free(i32 %86)
  call void @cq_template_and_i32_hl_unc(i32 %85, i32 %9, i32 3)
  call void @cqrt_free(i32 %85)
  br label %146

102:                                              ; preds = %103
  call void @cqrt_and_i1(i32 %14, i32 %21, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_select_i1_unc(i32 %25, i32 %24, i32 %22, i32 %15)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %14, i32 %23, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_xor_i1(i32 %21, i32 %23)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %21, i32 %20, i64 0)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %14, i32 %6, i64 %19)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %15)
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %14)
  call void @cqrt_xor_i1(i32 %11, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %12, i32 %8, i32 4)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i32_unc(i32 %11, i32 %9, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_abs_i32_unc(i32 %10, i32 %7)
  call void @cqrt_free(i32 %10)
  call void @cq_template_lshr_i32_hl_unc(i32 %9, i32 %8, i32 2)
  call void @cqrt_free(i32 %9)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %101

103:                                              ; preds = %147, %104
  br label %102

104:                                              ; preds = %147, %129
  %105 = call i32 @cqrt_pop()
  %106 = call i32 @cqrt_pop()
  %107 = call i32 @cqrt_pop()
  %108 = call i32 @cqrt_pop()
  %109 = call i32 @cqrt_pop()
  %110 = call i32 @cqrt_pop()
  %111 = call i32 @cqrt_pop()
  %112 = call i32 @cqrt_pop()
  %113 = call i32 @cqrt_pop()
  %114 = call i32 @cqrt_pop()
  %115 = call i32 @cqrt_pop()
  %116 = call i32 @cqrt_pop()
  %117 = call i32 @cqrt_pop()
  %118 = call i32 @cqrt_pop()
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  %123 = call i32 @cqrt_pop()
  %124 = call i32 @cqrt_pop()
  %125 = call i32 @cqrt_pop()
  %126 = call i32 @cqrt_pop()
  %127 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %127, i32 %126, i32 %125)
  call void @cqrt_free(i32 %125)
  call void @cqrt_and_i1(i32 %124, i32 %123, i32 %126)
  call void @cqrt_xor_i1(i32 %124, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cq_template_select_i1_unc(i32 %122, i32 %121, i32 %120, i32 %119)
  call void @cqrt_free(i32 %122)
  call void @cqrt_and_i1(i32 %127, i32 %118, i32 %121)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %123, i32 %124, i32 %118)
  call void @cqrt_free(i32 %118)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %120, i32 %117, i64 0)
  call void @cqrt_free(i32 %120)
  call void @cq_template_and_i64_unc(i32 %117, i32 %116, i32 %115)
  call void @cqrt_free(i32 %117)
  call void @cq_template_xor_i64_hl_unc(i32 %115, i32 %114, i64 -1)
  call void @cqrt_free(i32 %115)
  call void @cq_template_shl_i64_lh_unc(i32 %114, i64 -1, i32 %113)
  call void @cqrt_free(i32 %114)
  call void @cq_template_zext_i32_to_i64_unc(i32 %113, i32 %112)
  call void @cqrt_free(i32 %113)
  call void @cq_template_and_i32_hl_unc(i32 %112, i32 %8, i32 3)
  call void @cqrt_free(i32 %112)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %116, i32 %111, i32 %6, i32 %110)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %127, i32 %109, i32 %111)
  call void @cqrt_free(i32 %111)
  call void @cqrt_and_i1(i32 %123, i32 %124, i32 %109)
  call void @cqrt_free(i32 %109)
  call void @cq_template_add_i64_hl_unc(i32 %110, i32 %108, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %110)
  call void @cq_template_mul_i64_hl_unc(i32 %108, i32 %107, i64 8)
  call void @cqrt_free(i32 %108)
  call void @cq_template_zext_i32_to_i64_unc(i32 %107, i32 %106)
  call void @cqrt_free(i32 %107)
  call void @cq_template_and_i32_hl_unc(i32 %106, i32 %9, i32 3)
  call void @cqrt_free(i32 %106)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %123, i32 %9, i32 %105)
  call void @cqrt_free(i32 %123)
  %128 = call i32 @cqrt_pop()
  switch i32 %128, label %129 [
    i32 1, label %103
  ]

129:                                              ; preds = %104
  %130 = call i32 @cqrt_pop()
  %131 = zext i32 %130 to i64
  %132 = shl i64 %131, 32
  %133 = or i64 0, %132
  %134 = call i32 @cqrt_pop()
  %135 = zext i32 %134 to i64
  %136 = or i64 %133, %135
  %137 = call i32 @cqrt_pop()
  %138 = call i32 @cqrt_pop()
  %139 = call i32 @cqrt_pop()
  %140 = call i32 @cqrt_pop()
  %141 = call i32 @cqrt_pop()
  %142 = call i32 @cqrt_pop()
  %143 = call i32 @cqrt_pop()
  %144 = call i32 @cqrt_pop()
  %145 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %145, i32 %144, i32 %143)
  call void @cqrt_free(i32 %143)
  call void @cq_template_select_i1_unc(i32 %142, i32 %141, i32 %140, i32 %139)
  call void @cqrt_free(i32 %142)
  call void @cqrt_and_i1(i32 %145, i32 %138, i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cqrt_xor_i1(i32 %144, i32 %138)
  call void @cqrt_not_i1(i32 %138)
  call void @cqrt_free(i32 %138)
  call void @cqrt_free(i32 %140)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %144, i32 %137, i64 0)
  call void @cqrt_free(i32 %144)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %137, i32 %145, i32 %6, i64 %136)
  call void @cqrt_free(i32 %137)
  br label %104

146:                                              ; preds = %84
  call void @cqrt_copy_i1(i32 %62, i32 %83)
  call void @cqrt_free(i32 %83)
  br label %147

147:                                              ; preds = %146
  switch i32 %59, label %103 [
    i32 1, label %104
  ]
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32_qangle(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %161

10:                                               ; preds = %5
  %11 = call i32 @__cq_mem()
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %12, i32 %3)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %13)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %13, i32 %3)
  %14 = call i32 @cq_template_lshr_i32_hl(i32 %13, i32 2)
  %15 = call i32 @cq_template_abs_i32(i32 %12)
  %16 = call i32 @cq_template_icmp_ult_i32(i32 %14, i32 %15)
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %13, i32 4)
  br label %18

18:                                               ; preds = %10
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_and_i1(i32 %16, i32 %17, i32 %20)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  %22 = and i32 0, 3
  %23 = zext i32 %22 to i64
  %24 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %23
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %19, i32 %11, i64 %25)
  %27 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_xor_i1(i32 %27, i32 %29)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %29, i32 %30)
  %31 = call i32 @cq_template_select_i1(i32 %30, i32 %28, i32 %21)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %27, i32 %32)
  %33 = call i32 @llvm.umin.i32(i32 %4, i32 1073741823)
  %34 = icmp ult i32 %4, 1073741823
  %35 = icmp ult i32 0, %33
  br i1 %35, label %36, label %64

36:                                               ; preds = %70, %18
  %from = phi i32 [ 0, %70 ], [ 1, %18 ]
  %37 = phi i32 [ 0, %18 ], [ %62, %70 ]
  %38 = phi i32 [ %32, %18 ], [ %81, %70 ]
  %39 = phi i32 [ 0, %18 ], [ %42, %70 ]
  %40 = phi i32 [ %27, %18 ], [ %76, %70 ]
  %41 = phi i32 [ %31, %18 ], [ %80, %70 ]
  call void @cqrt_push(i32 %from)
  %42 = add i32 %39, 1
  %43 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %42)
  %44 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)
  %45 = call i32 @cq_template_zext_i32_to_i64(i32 %44)
  %46 = call i32 @cq_template_mul_i64_hl(i32 %45, i64 8)
  %47 = call i32 @cq_template_add_i64_hl(i32 %46, i64 ptrtoint (ptr @limbs to i64))
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %40, i32 %48)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %48, i32 %49)
  %50 = call i32 @cqrt_qram_load_i64_controlled(i32 %49, i32 %11, i32 %47)
  %51 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %52 = call i32 @cq_template_zext_i32_to_i64(i32 %51)
  %53 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %52)
  %54 = call i32 @cq_template_xor_i64_hl(i32 %53, i64 -1)
  %55 = call i32 @cq_template_and_i64(i32 %50, i32 %54)
  %56 = call i32 @cq_template_icmp_eq_i64_hl(i32 %55, i64 0)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %40, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %57, i32 %58)
  %59 = call i32 @cq_template_select_i1(i32 %58, i32 %56, i32 %41)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %40, i32 %60)
  call void @cqrt_and_i1(i32 %40, i32 %43, i32 %60)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %60, i32 %61)
  %62 = add i32 %37, 1
  %63 = icmp ult i32 %62, %33
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  br i1 %63, label %70, label %64

64:                                               ; preds = %36, %18
  %65 = phi i32 [ 0, %18 ], [ 1, %36 ]
  %66 = phi i32 [ 0, %18 ], [ %42, %36 ]
  %67 = phi i32 [ %27, %18 ], [ %40, %36 ]
  %68 = phi i32 [ %31, %18 ], [ %59, %36 ]
  %69 = phi i32 [ %32, %18 ], [ %61, %36 ]
  br i1 %34, label %85, label %87

70:                                               ; preds = %36
  %71 = and i32 %42, 3
  %72 = zext i32 %71 to i64
  %73 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %72
  %74 = ptrtoint ptr %73 to i64
  %75 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %61, i32 %11, i64 %74)
  %76 = call i32 @cq_template_icmp_eq_i64_hl(i32 %75, i64 0)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %78)
  call void @cqrt_xor_i1(i32 %76, i32 %78)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %61, i32 %78, i32 %79)
  %80 = call i32 @cq_template_select_i1(i32 %79, i32 %77, i32 %59)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %61, i32 %76, i32 %81)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %75)
  %82 = trunc i64 %74 to i32
  call void @cqrt_push(i32 %82)
  %83 = lshr i64 %74, 32
  %84 = trunc i64 %83 to i32
  call void @cqrt_push(i32 %84)
  br label %36

85:                                               ; preds = %64
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %69, i32 %86)
  br label %88

87:                                               ; preds = %64
  br label %88

88:                                               ; preds = %85, %87
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %68, i32 %89)
  br label %90

90:                                               ; preds = %88
  %91 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)
  %92 = call i32 @cq_template_zext_i32_to_i64(i32 %91)
  %93 = call i32 @cq_template_mul_i64_hl(i32 %92, i64 8)
  %94 = call i32 @cq_template_add_i64_hl(i32 %93, i64 ptrtoint (ptr @limbs to i64))
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  %96 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %96)
  call void @cqrt_and_i1(i32 %0, i32 %96, i32 %95)
  %97 = call i32 @cqrt_qram_load_i64_controlled(i32 %95, i32 %11, i32 %94)
  %98 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %99 = call i32 @cq_template_zext_i32_to_i64(i32 %98)
  %100 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %99)
  %101 = call i32 @cq_template_xor_i64_hl(i32 %100, i64 -1)
  %102 = call i32 @cq_template_and_i64(i32 %97, i32 %101)
  %103 = call i32 @cq_template_icmp_eq_i64_hl(i32 %102, i64 0)
  %104 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  %106 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %106)
  call void @cqrt_and_i1(i32 %0, i32 %106, i32 %105)
  %107 = call i32 @cq_template_select_i1(i32 %105, i32 %103, i32 %89)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  %109 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %109)
  call void @cqrt_xor_i1(i32 %16, i32 %109)
  call void @cqrt_and_i1(i32 %0, i32 %109, i32 %108)
  %110 = call i32 @cq_template_select_i1(i32 %108, i32 %104, i32 %107)
  %111 = call i32 @cq_template_zext_i1_to_i32(i32 %110)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  %112 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %111, i32 %112)
  call void @cq_template_zext_i1_to_i32_unc(i32 %111, i32 %110)
  call void @cqrt_free(i32 %111)
  call void @cq_template_select_i1_unc(i32 %110, i32 %108, i32 %104, i32 %107)
  call void @cqrt_free(i32 %110)
  call void @cqrt_and_i1(i32 %0, i32 %109, i32 %108)
  call void @cqrt_free(i32 %108)
  call void @cqrt_xor_i1(i32 %16, i32 %109)
  call void @cqrt_not_i1(i32 %109)
  call void @cqrt_free(i32 %109)
  call void @cq_template_select_i1_unc(i32 %107, i32 %105, i32 %103, i32 %89)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %0, i32 %106, i32 %105)
  call void @cqrt_free(i32 %105)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %106)
  call void @cqrt_free(i32 %106)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %104, i32 %12, i32 0)
  call void @cqrt_free(i32 %104)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %103, i32 %102, i64 0)
  call void @cqrt_free(i32 %103)
  call void @cq_template_and_i64_unc(i32 %102, i32 %97, i32 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_xor_i64_hl_unc(i32 %101, i32 %100, i64 -1)
  call void @cqrt_free(i32 %101)
  call void @cq_template_shl_i64_lh_unc(i32 %100, i64 -1, i32 %99)
  call void @cqrt_free(i32 %100)
  call void @cq_template_zext_i32_to_i64_unc(i32 %99, i32 %98)
  call void @cqrt_free(i32 %99)
  call void @cq_template_and_i32_hl_unc(i32 %98, i32 %13, i32 3)
  call void @cqrt_free(i32 %98)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %97, i32 %95, i32 %11, i32 %94)
  call void @cqrt_free(i32 %97)
  call void @cqrt_and_i1(i32 %0, i32 %96, i32 %95)
  call void @cqrt_free(i32 %95)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %96)
  call void @cqrt_free(i32 %96)
  call void @cq_template_add_i64_hl_unc(i32 %94, i32 %93, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %94)
  call void @cq_template_mul_i64_hl_unc(i32 %93, i32 %92, i64 8)
  call void @cqrt_free(i32 %93)
  call void @cq_template_zext_i32_to_i64_unc(i32 %92, i32 %91)
  call void @cqrt_free(i32 %92)
  call void @cq_template_and_i32_hl_unc(i32 %91, i32 %14, i32 3)
  call void @cqrt_free(i32 %91)
  br label %159

113:                                              ; preds = %116
  call void @cqrt_and_i1(i32 %19, i32 %27, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i1_unc(i32 %31, i32 %30, i32 %28, i32 %21)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %19, i32 %29, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_xor_i1(i32 %27, i32 %29)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_free(i32 %28)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %27, i32 %26, i64 0)
  call void @cqrt_free(i32 %27)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %26, i32 %19, i32 %11, i64 %25)
  call void @cqrt_free(i32 %26)
  call void @cqrt_free(i32 %21)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_and_i1(i32 %16, i32 %17, i32 %20)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %17, i32 %13, i32 4)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_ult_i32_unc(i32 %16, i32 %14, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_abs_i32_unc(i32 %15, i32 %12)
  call void @cqrt_free(i32 %15)
  call void @cq_template_lshr_i32_hl_unc(i32 %14, i32 %13, i32 2)
  call void @cqrt_free(i32 %14)
  %114 = load i32, ptr @__cq_act_f, align 4
  %115 = add i32 %114, -1
  store i32 %115, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %112

116:                                              ; preds = %160, %117
  br label %113

117:                                              ; preds = %160, %142
  %118 = call i32 @cqrt_pop()
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  %123 = call i32 @cqrt_pop()
  %124 = call i32 @cqrt_pop()
  %125 = call i32 @cqrt_pop()
  %126 = call i32 @cqrt_pop()
  %127 = call i32 @cqrt_pop()
  %128 = call i32 @cqrt_pop()
  %129 = call i32 @cqrt_pop()
  %130 = call i32 @cqrt_pop()
  %131 = call i32 @cqrt_pop()
  %132 = call i32 @cqrt_pop()
  %133 = call i32 @cqrt_pop()
  %134 = call i32 @cqrt_pop()
  %135 = call i32 @cqrt_pop()
  %136 = call i32 @cqrt_pop()
  %137 = call i32 @cqrt_pop()
  %138 = call i32 @cqrt_pop()
  %139 = call i32 @cqrt_pop()
  %140 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %140, i32 %139, i32 %138)
  call void @cqrt_free(i32 %138)
  call void @cqrt_and_i1(i32 %137, i32 %136, i32 %139)
  call void @cqrt_xor_i1(i32 %137, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cq_template_select_i1_unc(i32 %135, i32 %134, i32 %133, i32 %132)
  call void @cqrt_free(i32 %135)
  call void @cqrt_and_i1(i32 %140, i32 %131, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_and_i1(i32 %136, i32 %137, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %133, i32 %130, i64 0)
  call void @cqrt_free(i32 %133)
  call void @cq_template_and_i64_unc(i32 %130, i32 %129, i32 %128)
  call void @cqrt_free(i32 %130)
  call void @cq_template_xor_i64_hl_unc(i32 %128, i32 %127, i64 -1)
  call void @cqrt_free(i32 %128)
  call void @cq_template_shl_i64_lh_unc(i32 %127, i64 -1, i32 %126)
  call void @cqrt_free(i32 %127)
  call void @cq_template_zext_i32_to_i64_unc(i32 %126, i32 %125)
  call void @cqrt_free(i32 %126)
  call void @cq_template_and_i32_hl_unc(i32 %125, i32 %13, i32 3)
  call void @cqrt_free(i32 %125)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %129, i32 %124, i32 %11, i32 %123)
  call void @cqrt_free(i32 %129)
  call void @cqrt_and_i1(i32 %140, i32 %122, i32 %124)
  call void @cqrt_free(i32 %124)
  call void @cqrt_and_i1(i32 %136, i32 %137, i32 %122)
  call void @cqrt_free(i32 %122)
  call void @cq_template_add_i64_hl_unc(i32 %123, i32 %121, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %123)
  call void @cq_template_mul_i64_hl_unc(i32 %121, i32 %120, i64 8)
  call void @cqrt_free(i32 %121)
  call void @cq_template_zext_i32_to_i64_unc(i32 %120, i32 %119)
  call void @cqrt_free(i32 %120)
  call void @cq_template_and_i32_hl_unc(i32 %119, i32 %14, i32 3)
  call void @cqrt_free(i32 %119)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %136, i32 %14, i32 %118)
  call void @cqrt_free(i32 %136)
  %141 = call i32 @cqrt_pop()
  switch i32 %141, label %142 [
    i32 1, label %116
  ]

142:                                              ; preds = %117
  %143 = call i32 @cqrt_pop()
  %144 = zext i32 %143 to i64
  %145 = shl i64 %144, 32
  %146 = or i64 0, %145
  %147 = call i32 @cqrt_pop()
  %148 = zext i32 %147 to i64
  %149 = or i64 %146, %148
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  %153 = call i32 @cqrt_pop()
  %154 = call i32 @cqrt_pop()
  %155 = call i32 @cqrt_pop()
  %156 = call i32 @cqrt_pop()
  %157 = call i32 @cqrt_pop()
  %158 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %158, i32 %157, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cq_template_select_i1_unc(i32 %155, i32 %154, i32 %153, i32 %152)
  call void @cqrt_free(i32 %155)
  call void @cqrt_and_i1(i32 %158, i32 %151, i32 %154)
  call void @cqrt_free(i32 %154)
  call void @cqrt_xor_i1(i32 %157, i32 %151)
  call void @cqrt_not_i1(i32 %151)
  call void @cqrt_free(i32 %151)
  call void @cqrt_free(i32 %153)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %157, i32 %150, i64 0)
  call void @cqrt_free(i32 %157)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %150, i32 %158, i32 %11, i64 %149)
  call void @cqrt_free(i32 %150)
  br label %117

159:                                              ; preds = %90
  call void @cqrt_copy_i1(i32 %68, i32 %89)
  call void @cqrt_free(i32 %89)
  br label %160

160:                                              ; preds = %159
  switch i32 %65, label %116 [
    i32 1, label %117
  ]

161:                                              ; preds = %5
  %162 = call i32 @cqrt_alloc_i32(i32 0)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %163)
  call void @cqrt_push(i32 0)
  call void @cqrt_push(i32 0)
  %164 = load i32, ptr @__cq_act_f, align 4
  %165 = add i32 %164, -1
  store i32 %165, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %162
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_111_t_unc(i32 %out, i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  %7 = call i32 @cqrt_pop()
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 2)
  %10 = call i32 @cq_template_abs_i32(i32 %7)
  %11 = call i32 @cq_template_icmp_ult_i32(i32 %9, i32 %10)
  %12 = call i32 @cq_template_icmp_ult_i32_hl(i32 %6, i32 4)
  br label %13

13:                                               ; preds = %4
  %14 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %11, i32 %14)
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %14)
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = and i32 0, 3
  %17 = zext i32 %16 to i64
  %18 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %17
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %14, i32 %8, i64 %19)
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 0)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_xor_i1(i32 %21, i32 %23)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %23, i32 %24)
  %25 = call i32 @cq_template_select_i1(i32 %24, i32 %22, i32 %15)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %21, i32 %26)
  %27 = call i32 @llvm.umin.i32(i32 %3, i32 1073741823)
  %28 = icmp ult i32 %3, 1073741823
  %29 = icmp ult i32 0, %27
  br i1 %29, label %30, label %58

30:                                               ; preds = %61, %13
  %from = phi i32 [ 0, %61 ], [ 1, %13 ]
  %31 = phi i32 [ 0, %13 ], [ %56, %61 ]
  %32 = phi i32 [ %26, %13 ], [ %72, %61 ]
  %33 = phi i32 [ 0, %13 ], [ %36, %61 ]
  %34 = phi i32 [ %21, %13 ], [ %67, %61 ]
  %35 = phi i32 [ %25, %13 ], [ %71, %61 ]
  call void @cqrt_push(i32 %from)
  %36 = add i32 %33, 1
  %37 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %36)
  %38 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)
  %39 = call i32 @cq_template_zext_i32_to_i64(i32 %38)
  %40 = call i32 @cq_template_mul_i64_hl(i32 %39, i64 8)
  %41 = call i32 @cq_template_add_i64_hl(i32 %40, i64 ptrtoint (ptr @limbs to i64))
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %37, i32 %34, i32 %42)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %42, i32 %43)
  %44 = call i32 @cqrt_qram_load_i64_controlled(i32 %43, i32 %8, i32 %41)
  %45 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %46 = call i32 @cq_template_zext_i32_to_i64(i32 %45)
  %47 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %46)
  %48 = call i32 @cq_template_xor_i64_hl(i32 %47, i64 -1)
  %49 = call i32 @cq_template_and_i64(i32 %44, i32 %48)
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %49, i64 0)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %37, i32 %34, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i1(i32 %52, i32 %50, i32 %35)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %34, i32 %54)
  call void @cqrt_and_i1(i32 %34, i32 %37, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %32, i32 %54, i32 %55)
  %56 = add i32 %31, 1
  %57 = icmp ult i32 %56, %27
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %36)
  br i1 %57, label %61, label %58

58:                                               ; preds = %30, %13
  %59 = phi i32 [ 0, %13 ], [ 1, %30 ]
  %60 = phi i32 [ %25, %13 ], [ %53, %30 ]
  br i1 %28, label %76, label %77

61:                                               ; preds = %30
  %62 = and i32 %36, 3
  %63 = zext i32 %62 to i64
  %64 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %63
  %65 = ptrtoint ptr %64 to i64
  %66 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %55, i32 %8, i64 %65)
  %67 = call i32 @cq_template_icmp_eq_i64_hl(i32 %66, i64 0)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %69)
  call void @cqrt_xor_i1(i32 %67, i32 %69)
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %69, i32 %70)
  %71 = call i32 @cq_template_select_i1(i32 %70, i32 %68, i32 %53)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %67, i32 %72)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %66)
  %73 = trunc i64 %65 to i32
  call void @cqrt_push(i32 %73)
  %74 = lshr i64 %65, 32
  %75 = trunc i64 %74 to i32
  call void @cqrt_push(i32 %75)
  br label %30

76:                                               ; preds = %58
  br label %78

77:                                               ; preds = %58
  br label %78

78:                                               ; preds = %77, %76
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %60, i32 %79)
  br label %80

80:                                               ; preds = %78
  %81 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)
  %82 = call i32 @cq_template_zext_i32_to_i64(i32 %81)
  %83 = call i32 @cq_template_mul_i64_hl(i32 %82, i64 8)
  %84 = call i32 @cq_template_add_i64_hl(i32 %83, i64 ptrtoint (ptr @limbs to i64))
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %12, i32 %11, i32 %85)
  %86 = call i32 @cqrt_qram_load_i64_controlled(i32 %85, i32 %8, i32 %84)
  %87 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %88 = call i32 @cq_template_zext_i32_to_i64(i32 %87)
  %89 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %88)
  %90 = call i32 @cq_template_xor_i64_hl(i32 %89, i64 -1)
  %91 = call i32 @cq_template_and_i64(i32 %86, i32 %90)
  %92 = call i32 @cq_template_icmp_eq_i64_hl(i32 %91, i64 0)
  %93 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %94 = call i32 @cq_template_select_i1(i32 %12, i32 %92, i32 %79)
  %95 = call i32 @cq_template_select_i1(i32 %11, i32 %94, i32 %93)
  %96 = call i32 @cq_template_zext_i1_to_i32(i32 %95)
  call void @cqrt_copy_i32(i32 %96, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %96, i32 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_select_i1_unc(i32 %95, i32 %11, i32 %94, i32 %93)
  call void @cqrt_free(i32 %95)
  call void @cq_template_select_i1_unc(i32 %94, i32 %12, i32 %92, i32 %79)
  call void @cqrt_free(i32 %94)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %93, i32 %7, i32 0)
  call void @cqrt_free(i32 %93)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %92, i32 %91, i64 0)
  call void @cqrt_free(i32 %92)
  call void @cq_template_and_i64_unc(i32 %91, i32 %86, i32 %90)
  call void @cqrt_free(i32 %91)
  call void @cq_template_xor_i64_hl_unc(i32 %90, i32 %89, i64 -1)
  call void @cqrt_free(i32 %90)
  call void @cq_template_shl_i64_lh_unc(i32 %89, i64 -1, i32 %88)
  call void @cqrt_free(i32 %89)
  call void @cq_template_zext_i32_to_i64_unc(i32 %88, i32 %87)
  call void @cqrt_free(i32 %88)
  call void @cq_template_and_i32_hl_unc(i32 %87, i32 %6, i32 3)
  call void @cqrt_free(i32 %87)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %86, i32 %85, i32 %8, i32 %84)
  call void @cqrt_free(i32 %86)
  call void @cqrt_and_i1(i32 %12, i32 %11, i32 %85)
  call void @cqrt_free(i32 %85)
  call void @cq_template_add_i64_hl_unc(i32 %84, i32 %83, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %84)
  call void @cq_template_mul_i64_hl_unc(i32 %83, i32 %82, i64 8)
  call void @cqrt_free(i32 %83)
  call void @cq_template_zext_i32_to_i64_unc(i32 %82, i32 %81)
  call void @cqrt_free(i32 %82)
  call void @cq_template_and_i32_hl_unc(i32 %81, i32 %9, i32 3)
  call void @cqrt_free(i32 %81)
  br label %141

97:                                               ; preds = %98
  call void @cqrt_and_i1(i32 %14, i32 %21, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_select_i1_unc(i32 %25, i32 %24, i32 %22, i32 %15)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %14, i32 %23, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_xor_i1(i32 %21, i32 %23)
  call void @cqrt_not_i1(i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %21, i32 %20, i64 0)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %14, i32 %8, i64 %19)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %15)
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %14)
  call void @cqrt_xor_i1(i32 %11, i32 %14)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %12, i32 %6, i32 4)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i32_unc(i32 %11, i32 %9, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_abs_i32_unc(i32 %10, i32 %7)
  call void @cqrt_free(i32 %10)
  call void @cq_template_lshr_i32_hl_unc(i32 %9, i32 %6, i32 2)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

98:                                               ; preds = %142, %99
  br label %97

99:                                               ; preds = %142, %124
  %100 = call i32 @cqrt_pop()
  %101 = call i32 @cqrt_pop()
  %102 = call i32 @cqrt_pop()
  %103 = call i32 @cqrt_pop()
  %104 = call i32 @cqrt_pop()
  %105 = call i32 @cqrt_pop()
  %106 = call i32 @cqrt_pop()
  %107 = call i32 @cqrt_pop()
  %108 = call i32 @cqrt_pop()
  %109 = call i32 @cqrt_pop()
  %110 = call i32 @cqrt_pop()
  %111 = call i32 @cqrt_pop()
  %112 = call i32 @cqrt_pop()
  %113 = call i32 @cqrt_pop()
  %114 = call i32 @cqrt_pop()
  %115 = call i32 @cqrt_pop()
  %116 = call i32 @cqrt_pop()
  %117 = call i32 @cqrt_pop()
  %118 = call i32 @cqrt_pop()
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %122, i32 %121, i32 %120)
  call void @cqrt_free(i32 %120)
  call void @cqrt_and_i1(i32 %119, i32 %118, i32 %121)
  call void @cqrt_xor_i1(i32 %119, i32 %121)
  call void @cqrt_free(i32 %121)
  call void @cq_template_select_i1_unc(i32 %117, i32 %116, i32 %115, i32 %114)
  call void @cqrt_free(i32 %117)
  call void @cqrt_and_i1(i32 %122, i32 %113, i32 %116)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %118, i32 %119, i32 %113)
  call void @cqrt_free(i32 %113)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %115, i32 %112, i64 0)
  call void @cqrt_free(i32 %115)
  call void @cq_template_and_i64_unc(i32 %112, i32 %111, i32 %110)
  call void @cqrt_free(i32 %112)
  call void @cq_template_xor_i64_hl_unc(i32 %110, i32 %109, i64 -1)
  call void @cqrt_free(i32 %110)
  call void @cq_template_shl_i64_lh_unc(i32 %109, i64 -1, i32 %108)
  call void @cqrt_free(i32 %109)
  call void @cq_template_zext_i32_to_i64_unc(i32 %108, i32 %107)
  call void @cqrt_free(i32 %108)
  call void @cq_template_and_i32_hl_unc(i32 %107, i32 %6, i32 3)
  call void @cqrt_free(i32 %107)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %111, i32 %106, i32 %8, i32 %105)
  call void @cqrt_free(i32 %111)
  call void @cqrt_and_i1(i32 %122, i32 %104, i32 %106)
  call void @cqrt_free(i32 %106)
  call void @cqrt_and_i1(i32 %118, i32 %119, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cq_template_add_i64_hl_unc(i32 %105, i32 %103, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %105)
  call void @cq_template_mul_i64_hl_unc(i32 %103, i32 %102, i64 8)
  call void @cqrt_free(i32 %103)
  call void @cq_template_zext_i32_to_i64_unc(i32 %102, i32 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_and_i32_hl_unc(i32 %101, i32 %9, i32 3)
  call void @cqrt_free(i32 %101)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %118, i32 %9, i32 %100)
  call void @cqrt_free(i32 %118)
  %123 = call i32 @cqrt_pop()
  switch i32 %123, label %124 [
    i32 1, label %98
  ]

124:                                              ; preds = %99
  %125 = call i32 @cqrt_pop()
  %126 = zext i32 %125 to i64
  %127 = shl i64 %126, 32
  %128 = or i64 0, %127
  %129 = call i32 @cqrt_pop()
  %130 = zext i32 %129 to i64
  %131 = or i64 %128, %130
  %132 = call i32 @cqrt_pop()
  %133 = call i32 @cqrt_pop()
  %134 = call i32 @cqrt_pop()
  %135 = call i32 @cqrt_pop()
  %136 = call i32 @cqrt_pop()
  %137 = call i32 @cqrt_pop()
  %138 = call i32 @cqrt_pop()
  %139 = call i32 @cqrt_pop()
  %140 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %140, i32 %139, i32 %138)
  call void @cqrt_free(i32 %138)
  call void @cq_template_select_i1_unc(i32 %137, i32 %136, i32 %135, i32 %134)
  call void @cqrt_free(i32 %137)
  call void @cqrt_and_i1(i32 %140, i32 %133, i32 %136)
  call void @cqrt_free(i32 %136)
  call void @cqrt_xor_i1(i32 %139, i32 %133)
  call void @cqrt_not_i1(i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_free(i32 %135)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %139, i32 %132, i64 0)
  call void @cqrt_free(i32 %139)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %132, i32 %140, i32 %8, i64 %131)
  call void @cqrt_free(i32 %132)
  br label %99

141:                                              ; preds = %80
  call void @cqrt_copy_i1(i32 %60, i32 %79)
  call void @cqrt_free(i32 %79)
  br label %142

142:                                              ; preds = %141
  switch i32 %59, label %98 [
    i32 1, label %99
  ]
}

define internal void @__cq_q_f_111_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @cqrt_pop()
  %8 = call i32 @cqrt_pop()
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = icmp ult i32 %9, %4
  br i1 %11, label %12, label %156

12:                                               ; preds = %5
  %13 = call i32 @__cq_mem()
  %14 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 2)
  %15 = call i32 @cq_template_abs_i32(i32 %8)
  %16 = call i32 @cq_template_icmp_ult_i32(i32 %14, i32 %15)
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %7, i32 4)
  br label %18

18:                                               ; preds = %12
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_and_i1(i32 %16, i32 %17, i32 %20)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  %22 = and i32 0, 3
  %23 = zext i32 %22 to i64
  %24 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %23
  %25 = ptrtoint ptr %24 to i64
  %26 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %19, i32 %13, i64 %25)
  %27 = call i32 @cq_template_icmp_eq_i64_hl(i32 %26, i64 0)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_xor_i1(i32 %27, i32 %29)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %29, i32 %30)
  %31 = call i32 @cq_template_select_i1(i32 %30, i32 %28, i32 %21)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %27, i32 %32)
  %33 = call i32 @llvm.umin.i32(i32 %4, i32 1073741823)
  %34 = icmp ult i32 %4, 1073741823
  %35 = icmp ult i32 0, %33
  br i1 %35, label %36, label %64

36:                                               ; preds = %67, %18
  %from = phi i32 [ 0, %67 ], [ 1, %18 ]
  %37 = phi i32 [ 0, %18 ], [ %62, %67 ]
  %38 = phi i32 [ %32, %18 ], [ %78, %67 ]
  %39 = phi i32 [ 0, %18 ], [ %42, %67 ]
  %40 = phi i32 [ %27, %18 ], [ %73, %67 ]
  %41 = phi i32 [ %31, %18 ], [ %77, %67 ]
  call void @cqrt_push(i32 %from)
  %42 = add i32 %39, 1
  %43 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 %42)
  %44 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)
  %45 = call i32 @cq_template_zext_i32_to_i64(i32 %44)
  %46 = call i32 @cq_template_mul_i64_hl(i32 %45, i64 8)
  %47 = call i32 @cq_template_add_i64_hl(i32 %46, i64 ptrtoint (ptr @limbs to i64))
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %40, i32 %48)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %48, i32 %49)
  %50 = call i32 @cqrt_qram_load_i64_controlled(i32 %49, i32 %13, i32 %47)
  %51 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)
  %52 = call i32 @cq_template_zext_i32_to_i64(i32 %51)
  %53 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %52)
  %54 = call i32 @cq_template_xor_i64_hl(i32 %53, i64 -1)
  %55 = call i32 @cq_template_and_i64(i32 %50, i32 %54)
  %56 = call i32 @cq_template_icmp_eq_i64_hl(i32 %55, i64 0)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %43, i32 %40, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %57, i32 %58)
  %59 = call i32 @cq_template_select_i1(i32 %58, i32 %56, i32 %41)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %40, i32 %60)
  call void @cqrt_and_i1(i32 %40, i32 %43, i32 %60)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %38, i32 %60, i32 %61)
  %62 = add i32 %37, 1
  %63 = icmp ult i32 %62, %33
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  br i1 %63, label %67, label %64

64:                                               ; preds = %36, %18
  %65 = phi i32 [ 0, %18 ], [ 1, %36 ]
  %66 = phi i32 [ %31, %18 ], [ %59, %36 ]
  br i1 %34, label %82, label %83

67:                                               ; preds = %36
  %68 = and i32 %42, 3
  %69 = zext i32 %68 to i64
  %70 = getelementptr [4 x i64], ptr @limbs, i64 0, i64 %69
  %71 = ptrtoint ptr %70 to i64
  %72 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %61, i32 %13, i64 %71)
  %73 = call i32 @cq_template_icmp_eq_i64_hl(i32 %72, i64 0)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_xor_i1(i32 %73, i32 %75)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %61, i32 %75, i32 %76)
  %77 = call i32 @cq_template_select_i1(i32 %76, i32 %74, i32 %59)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %61, i32 %73, i32 %78)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %72)
  %79 = trunc i64 %71 to i32
  call void @cqrt_push(i32 %79)
  %80 = lshr i64 %71, 32
  %81 = trunc i64 %80 to i32
  call void @cqrt_push(i32 %81)
  br label %36

82:                                               ; preds = %64
  br label %84

83:                                               ; preds = %64
  br label %84

84:                                               ; preds = %83, %82
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %66, i32 %85)
  br label %86

86:                                               ; preds = %84
  %87 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)
  %88 = call i32 @cq_template_zext_i32_to_i64(i32 %87)
  %89 = call i32 @cq_template_mul_i64_hl(i32 %88, i64 8)
  %90 = call i32 @cq_template_add_i64_hl(i32 %89, i64 ptrtoint (ptr @limbs to i64))
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %92)
  call void @cqrt_and_i1(i32 %0, i32 %92, i32 %91)
  %93 = call i32 @cqrt_qram_load_i64_controlled(i32 %91, i32 %13, i32 %90)
  %94 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)
  %95 = call i32 @cq_template_zext_i32_to_i64(i32 %94)
  %96 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %95)
  %97 = call i32 @cq_template_xor_i64_hl(i32 %96, i64 -1)
  %98 = call i32 @cq_template_and_i64(i32 %93, i32 %97)
  %99 = call i32 @cq_template_icmp_eq_i64_hl(i32 %98, i64 0)
  %100 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %101 = call i32 @cqrt_alloc_i1(i1 false)
  %102 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %102)
  call void @cqrt_and_i1(i32 %0, i32 %102, i32 %101)
  %103 = call i32 @cq_template_select_i1(i32 %101, i32 %99, i32 %85)
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_xor_i1(i32 %16, i32 %105)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %104)
  %106 = call i32 @cq_template_select_i1(i32 %104, i32 %100, i32 %103)
  %107 = call i32 @cq_template_zext_i1_to_i32(i32 %106)
  call void @cqrt_copy_i32(i32 %107, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %107, i32 %106)
  call void @cqrt_free(i32 %107)
  call void @cq_template_select_i1_unc(i32 %106, i32 %104, i32 %100, i32 %103)
  call void @cqrt_free(i32 %106)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cqrt_xor_i1(i32 %16, i32 %105)
  call void @cqrt_not_i1(i32 %105)
  call void @cqrt_free(i32 %105)
  call void @cq_template_select_i1_unc(i32 %103, i32 %101, i32 %99, i32 %85)
  call void @cqrt_free(i32 %103)
  call void @cqrt_and_i1(i32 %0, i32 %102, i32 %101)
  call void @cqrt_free(i32 %101)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %102)
  call void @cqrt_free(i32 %102)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %100, i32 %8, i32 0)
  call void @cqrt_free(i32 %100)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %99, i32 %98, i64 0)
  call void @cqrt_free(i32 %99)
  call void @cq_template_and_i64_unc(i32 %98, i32 %93, i32 %97)
  call void @cqrt_free(i32 %98)
  call void @cq_template_xor_i64_hl_unc(i32 %97, i32 %96, i64 -1)
  call void @cqrt_free(i32 %97)
  call void @cq_template_shl_i64_lh_unc(i32 %96, i64 -1, i32 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_zext_i32_to_i64_unc(i32 %95, i32 %94)
  call void @cqrt_free(i32 %95)
  call void @cq_template_and_i32_hl_unc(i32 %94, i32 %7, i32 3)
  call void @cqrt_free(i32 %94)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %93, i32 %91, i32 %13, i32 %90)
  call void @cqrt_free(i32 %93)
  call void @cqrt_and_i1(i32 %0, i32 %92, i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %92)
  call void @cqrt_free(i32 %92)
  call void @cq_template_add_i64_hl_unc(i32 %90, i32 %89, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %90)
  call void @cq_template_mul_i64_hl_unc(i32 %89, i32 %88, i64 8)
  call void @cqrt_free(i32 %89)
  call void @cq_template_zext_i32_to_i64_unc(i32 %88, i32 %87)
  call void @cqrt_free(i32 %88)
  call void @cq_template_and_i32_hl_unc(i32 %87, i32 %14, i32 3)
  call void @cqrt_free(i32 %87)
  br label %154

108:                                              ; preds = %111
  call void @cqrt_and_i1(i32 %19, i32 %27, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i1_unc(i32 %31, i32 %30, i32 %28, i32 %21)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %19, i32 %29, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_xor_i1(i32 %27, i32 %29)
  call void @cqrt_not_i1(i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_free(i32 %28)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %27, i32 %26, i64 0)
  call void @cqrt_free(i32 %27)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %26, i32 %19, i32 %13, i64 %25)
  call void @cqrt_free(i32 %26)
  call void @cqrt_free(i32 %21)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_and_i1(i32 %16, i32 %17, i32 %20)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %17, i32 %7, i32 4)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_ult_i32_unc(i32 %16, i32 %14, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_abs_i32_unc(i32 %15, i32 %8)
  call void @cqrt_free(i32 %15)
  call void @cq_template_lshr_i32_hl_unc(i32 %14, i32 %7, i32 2)
  call void @cqrt_free(i32 %14)
  %109 = load i32, ptr @__cq_act_f, align 4
  %110 = add i32 %109, -1
  store i32 %110, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %6, ptr @__cq_k, align 4
  ret void

111:                                              ; preds = %155, %112
  br label %108

112:                                              ; preds = %155, %137
  %113 = call i32 @cqrt_pop()
  %114 = call i32 @cqrt_pop()
  %115 = call i32 @cqrt_pop()
  %116 = call i32 @cqrt_pop()
  %117 = call i32 @cqrt_pop()
  %118 = call i32 @cqrt_pop()
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  %123 = call i32 @cqrt_pop()
  %124 = call i32 @cqrt_pop()
  %125 = call i32 @cqrt_pop()
  %126 = call i32 @cqrt_pop()
  %127 = call i32 @cqrt_pop()
  %128 = call i32 @cqrt_pop()
  %129 = call i32 @cqrt_pop()
  %130 = call i32 @cqrt_pop()
  %131 = call i32 @cqrt_pop()
  %132 = call i32 @cqrt_pop()
  %133 = call i32 @cqrt_pop()
  %134 = call i32 @cqrt_pop()
  %135 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %135, i32 %134, i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_and_i1(i32 %132, i32 %131, i32 %134)
  call void @cqrt_xor_i1(i32 %132, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cq_template_select_i1_unc(i32 %130, i32 %129, i32 %128, i32 %127)
  call void @cqrt_free(i32 %130)
  call void @cqrt_and_i1(i32 %135, i32 %126, i32 %129)
  call void @cqrt_free(i32 %129)
  call void @cqrt_and_i1(i32 %131, i32 %132, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %128, i32 %125, i64 0)
  call void @cqrt_free(i32 %128)
  call void @cq_template_and_i64_unc(i32 %125, i32 %124, i32 %123)
  call void @cqrt_free(i32 %125)
  call void @cq_template_xor_i64_hl_unc(i32 %123, i32 %122, i64 -1)
  call void @cqrt_free(i32 %123)
  call void @cq_template_shl_i64_lh_unc(i32 %122, i64 -1, i32 %121)
  call void @cqrt_free(i32 %122)
  call void @cq_template_zext_i32_to_i64_unc(i32 %121, i32 %120)
  call void @cqrt_free(i32 %121)
  call void @cq_template_and_i32_hl_unc(i32 %120, i32 %7, i32 3)
  call void @cqrt_free(i32 %120)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %124, i32 %119, i32 %13, i32 %118)
  call void @cqrt_free(i32 %124)
  call void @cqrt_and_i1(i32 %135, i32 %117, i32 %119)
  call void @cqrt_free(i32 %119)
  call void @cqrt_and_i1(i32 %131, i32 %132, i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cq_template_add_i64_hl_unc(i32 %118, i32 %116, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %118)
  call void @cq_template_mul_i64_hl_unc(i32 %116, i32 %115, i64 8)
  call void @cqrt_free(i32 %116)
  call void @cq_template_zext_i32_to_i64_unc(i32 %115, i32 %114)
  call void @cqrt_free(i32 %115)
  call void @cq_template_and_i32_hl_unc(i32 %114, i32 %14, i32 3)
  call void @cqrt_free(i32 %114)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %131, i32 %14, i32 %113)
  call void @cqrt_free(i32 %131)
  %136 = call i32 @cqrt_pop()
  switch i32 %136, label %137 [
    i32 1, label %111
  ]

137:                                              ; preds = %112
  %138 = call i32 @cqrt_pop()
  %139 = zext i32 %138 to i64
  %140 = shl i64 %139, 32
  %141 = or i64 0, %140
  %142 = call i32 @cqrt_pop()
  %143 = zext i32 %142 to i64
  %144 = or i64 %141, %143
  %145 = call i32 @cqrt_pop()
  %146 = call i32 @cqrt_pop()
  %147 = call i32 @cqrt_pop()
  %148 = call i32 @cqrt_pop()
  %149 = call i32 @cqrt_pop()
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  %153 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %153, i32 %152, i32 %151)
  call void @cqrt_free(i32 %151)
  call void @cq_template_select_i1_unc(i32 %150, i32 %149, i32 %148, i32 %147)
  call void @cqrt_free(i32 %150)
  call void @cqrt_and_i1(i32 %153, i32 %146, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cqrt_xor_i1(i32 %152, i32 %146)
  call void @cqrt_not_i1(i32 %146)
  call void @cqrt_free(i32 %146)
  call void @cqrt_free(i32 %148)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %152, i32 %145, i64 0)
  call void @cqrt_free(i32 %152)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %145, i32 %153, i32 %13, i64 %144)
  call void @cqrt_free(i32 %145)
  br label %112

154:                                              ; preds = %86
  call void @cqrt_copy_i1(i32 %66, i32 %85)
  call void @cqrt_free(i32 %85)
  br label %155

155:                                              ; preds = %154
  switch i32 %65, label %111 [
    i32 1, label %112
  ]

156:                                              ; preds = %5
  %157 = load i32, ptr @__cq_act_f, align 4
  %158 = add i32 %157, -1
  store i32 %158, ptr @__cq_act_f, align 4
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
