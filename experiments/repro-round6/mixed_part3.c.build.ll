; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/mixed_part3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@out = local_unnamed_addr global [8 x i32] zeroinitializer, align 16
@cnt = local_unnamed_addr global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [28 x i8] c"i32 (ptr, i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @f(ptr noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %6, double %3)
  %7 = icmp sgt i32 %1, 1
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %7, label %9, label %16

9:                                                ; preds = %4
  %10 = icmp eq ptr %0, null
  %11 = call i32 @cq_template_and_i32_hl(i32 %6, i32 8)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 0)
  %13 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 2)
  %14 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %15 = icmp eq i32 %1, 2
  br label %18

16:                                               ; preds = %134, %4
  %cq.run9 = phi i1 [ false, %4 ], [ true, %134 ]
  %17 = phi i32 [ %8, %4 ], [ %84, %134 ]
  br i1 %cq.run9, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %16
  call void @cqrt_free(i32 %8)
  br label %.cq.after

.cq.after:                                        ; preds = %16, %.cq.arm
  ret i32 %17

18:                                               ; preds = %9
  %19 = call i32 @cqrt_alloc_i32(i32 0)
  br label %21

20:                                               ; preds = %67
  br label %132

21:                                               ; preds = %67, %18
  %from2 = phi i32 [ 0, %67 ], [ 1, %18 ]
  %22 = phi i32 [ 1, %18 ], [ %86, %67 ]
  %23 = phi i32 [ %19, %18 ], [ %84, %67 ]
  call void @cqrt_push(i32 %from2)
  %24 = shl nuw i32 1, %22
  %25 = call i32 @cq_template_and_i32_hl(i32 %6, i32 %24)
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %25, i32 0)
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %28 = call i32 @cq_template_select_i32_ll(i32 %27, i32 6, i32 7)
  %29 = call i32 @cq_template_select_i32_hl(i32 %26, i32 %28, i32 1)
  %30 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %24)
  br i1 %10, label %49, label %31

31:                                               ; preds = %21
  %32 = ptrtoint ptr %0 to i64
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %34)
  call void @cqrt_xor_i1(i32 %26, i32 %34)
  call void @cqrt_xor_i1(i32 %34, i32 %33)
  call void @cqrt_and_i1(i32 %34, i32 %12, i32 %33)
  %35 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %33, i32 %5, i64 %32)
  %36 = call i32 @cq_template_add_i32_hl(i32 %35, i32 2)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %38)
  call void @cqrt_xor_i1(i32 %26, i32 %38)
  call void @cqrt_xor_i1(i32 %38, i32 %37)
  call void @cqrt_and_i1(i32 %38, i32 %12, i32 %37)
  %39 = call fastcc i32 @__cq_q_putA_1_ctl(i32 %37, i32 %36)
  call void @cqrt_and_i1(i32 %38, i32 %12, i32 %37)
  call void @cqrt_xor_i1(i32 %38, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_xor_i1(i32 %26, i32 %38)
  call void @cqrt_not_i1(i32 %38)
  call void @cqrt_free(i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_xor_i1(i32 %26, i32 %41)
  call void @cqrt_and_i1(i32 %12, i32 %41, i32 %40)
  call fastcc void @__cq_q_putB_v_ctl(i32 %40)
  call void @cqrt_and_i1(i32 %12, i32 %41, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cqrt_xor_i1(i32 %26, i32 %41)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_free(i32 %41)
  %42 = call i32 @cq_template_select_i32_lh(i32 %12, i32 3, i32 %36)
  %43 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %44 = call i32 @cq_template_select_i32_ll(i32 %43, i32 6, i32 7)
  %45 = call i32 @cq_template_select_i32(i32 %26, i32 %44, i32 %42)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %33)
  %46 = trunc i64 %32 to i32
  call void @cqrt_push(i32 %46)
  %47 = lshr i64 %32, 32
  %48 = trunc i64 %47 to i32
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %34)
  br label %49

49:                                               ; preds = %21, %31
  %from1 = phi i32 [ 0, %21 ], [ 1, %31 ]
  %50 = phi i32 [ %30, %21 ], [ %36, %31 ]
  %51 = phi i32 [ %29, %21 ], [ %45, %31 ]
  call void @cqrt_push(i32 %from1)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  call void @cqrt_and_i1(i32 %53, i32 %26, i32 %52)
  call fastcc void @__cq_q_putD_v_ctl(i32 %52)
  call void @cqrt_and_i1(i32 %53, i32 %26, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %53, i32 %14, i32 1)
  call void @cqrt_free(i32 %53)
  %54 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %55 = call i32 @cq_template_select_i32_ll(i32 %54, i32 4, i32 7)
  %56 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %57 = call i32 @cq_template_select_i32_lh(i32 %56, i32 6, i32 %55)
  %58 = call i32 @cq_template_select_i32(i32 %26, i32 %57, i32 %51)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %54)
  br i1 %15, label %67, label %59

59:                                               ; preds = %49
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  %61 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  call void @cqrt_and_i1(i32 %61, i32 %26, i32 %60)
  call fastcc void @__cq_q_putC_v_ctl(i32 %60)
  call void @cqrt_and_i1(i32 %61, i32 %26, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %61, i32 %14, i32 0)
  call void @cqrt_free(i32 %61)
  %62 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %63 = call i32 @cq_template_select_i32_ll(i32 %62, i32 5, i32 7)
  %64 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %65 = call i32 @cq_template_select_i32_lh(i32 %64, i32 6, i32 %63)
  %66 = call i32 @cq_template_select_i32(i32 %26, i32 %65, i32 %51)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %62)
  br label %67

67:                                               ; preds = %49, %59
  %from = phi i32 [ 0, %49 ], [ 1, %59 ]
  %68 = phi i32 [ %58, %49 ], [ %66, %59 ]
  call void @cqrt_push(i32 %from)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  %70 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  %72 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  call void @cqrt_xor_i1(i32 %26, i32 %71)
  call void @cqrt_and_i1(i32 %26, i32 %72, i32 %71)
  call void @cqrt_xor_i1(i32 %71, i32 %69)
  call void @cqrt_and_i1(i32 %71, i32 %70, i32 %69)
  call fastcc void @__cq_q_putE_v_ctl(i32 %69)
  call void @cqrt_and_i1(i32 %71, i32 %70, i32 %69)
  call void @cqrt_xor_i1(i32 %71, i32 %69)
  call void @cqrt_free(i32 %69)
  call void @cqrt_and_i1(i32 %26, i32 %72, i32 %71)
  call void @cqrt_xor_i1(i32 %26, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %72, i32 %14, i32 0)
  call void @cqrt_free(i32 %72)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %70, i32 %14, i32 1)
  call void @cqrt_free(i32 %70)
  %73 = call i32 @cq_template_select_i32_lh(i32 %12, i32 3, i32 %50)
  %74 = call i32 @cqrt_alloc_i1(i1 %10)
  %75 = call i32 @cq_template_select_i32_lh(i32 %74, i32 1, i32 %73)
  %76 = xor i1 %15, true
  %77 = call i32 @cqrt_alloc_i1(i1 %76)
  %78 = call i32 @cq_template_select_i32_ll(i32 %77, i32 5, i32 4)
  %79 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %80 = call i32 @cq_template_select_i32_hl(i32 %79, i32 %78, i32 7)
  %81 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)
  %82 = call i32 @cq_template_select_i32_lh(i32 %81, i32 6, i32 %80)
  %83 = call i32 @cq_template_select_i32(i32 %26, i32 %82, i32 %75)
  %84 = call i32 @cq_template_add_i32(i32 %83, i32 %23)
  %85 = call i32 @cq_template_sub_i32(i32 %84, i32 %83)
  call void @cqrt_copy_i32(i32 %85, i32 %23)
  call void @cq_template_sub_i32_unc(i32 %85, i32 %84, i32 %83)
  call void @cqrt_free(i32 %85)
  call void @cqrt_free(i32 %23)
  call void @cq_template_select_i32_unc(i32 %83, i32 %26, i32 %82, i32 %75)
  call void @cqrt_free(i32 %83)
  call void @cq_template_select_i32_lh_unc(i32 %82, i32 %81, i32 6, i32 %80)
  call void @cqrt_free(i32 %82)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %81, i32 %14, i32 1)
  call void @cqrt_free(i32 %81)
  call void @cq_template_select_i32_hl_unc(i32 %80, i32 %79, i32 %78, i32 7)
  call void @cqrt_free(i32 %80)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %79, i32 %14, i32 0)
  call void @cqrt_free(i32 %79)
  call void @cq_template_select_i32_ll_unc(i32 %78, i32 %77, i32 5, i32 4)
  call void @cqrt_free(i32 %78)
  call void @cqrt_free(i32 %77)
  call void @cq_template_select_i32_lh_unc(i32 %75, i32 %74, i32 1, i32 %73)
  call void @cqrt_free(i32 %75)
  call void @cqrt_free(i32 %74)
  call void @cq_template_select_i32_lh_unc(i32 %73, i32 %12, i32 3, i32 %50)
  call void @cqrt_free(i32 %73)
  %86 = add nuw nsw i32 %22, 1
  %87 = icmp eq i32 %86, %1
  br i1 %87, label %20, label %21

88:                                               ; preds = %89
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %13, i32 3)
  call void @cqrt_free(i32 %14)
  call void @cq_template_lshr_i32_hl_unc(i32 %13, i32 %6, i32 2)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %11, i32 0)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %6, i32 8)
  call void @cqrt_free(i32 %11)
  br label %134

89:                                               ; preds = %98, %115
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  %93 = call i32 @cqrt_pop()
  %94 = call i32 @cqrt_pop()
  %95 = call i32 @cqrt_pop()
  %96 = call i32 @cqrt_pop()
  call void @cqrt_free(i32 %96)
  call void @cq_template_select_i32_hl_unc(i32 %95, i32 %94, i32 %93, i32 1)
  call void @cqrt_free(i32 %95)
  call void @cq_template_select_i32_ll_unc(i32 %93, i32 %92, i32 6, i32 7)
  call void @cqrt_free(i32 %93)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %92, i32 %14, i32 1)
  call void @cqrt_free(i32 %92)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %94, i32 %91, i32 0)
  call void @cqrt_free(i32 %94)
  call void @cq_template_and_i32_hl_unc(i32 %91, i32 %6, i32 %90)
  call void @cqrt_free(i32 %91)
  %97 = call i32 @cqrt_pop()
  switch i32 %97, label %132 [
    i32 1, label %88
  ]

98:                                               ; preds = %115
  %99 = call i32 @cqrt_pop()
  %100 = call i32 @cqrt_pop()
  %101 = zext i32 %100 to i64
  %102 = shl i64 %101, 32
  %103 = or i64 0, %102
  %104 = call i32 @cqrt_pop()
  %105 = zext i32 %104 to i64
  %106 = or i64 %103, %105
  %107 = call i32 @cqrt_pop()
  %108 = call i32 @cqrt_pop()
  %109 = call i32 @cqrt_pop()
  %110 = call i32 @cqrt_pop()
  %111 = call i32 @cqrt_pop()
  %112 = call i32 @cqrt_pop()
  %113 = call i32 @cqrt_pop()
  %114 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %114, i32 %113, i32 %112, i32 %111)
  call void @cqrt_free(i32 %114)
  call void @cq_template_select_i32_ll_unc(i32 %112, i32 %110, i32 6, i32 7)
  call void @cqrt_free(i32 %112)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %110, i32 %14, i32 1)
  call void @cqrt_free(i32 %110)
  call void @cq_template_select_i32_lh_unc(i32 %111, i32 %12, i32 3, i32 %109)
  call void @cqrt_free(i32 %111)
  call void @cq_template_add_i32_hl_unc(i32 %109, i32 %108, i32 2)
  call void @cqrt_free(i32 %109)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %108, i32 %107, i32 %5, i64 %106)
  call void @cqrt_and_i1(i32 %99, i32 %12, i32 %107)
  call void @cqrt_xor_i1(i32 %99, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_xor_i1(i32 %113, i32 %99)
  call void @cqrt_not_i1(i32 %99)
  call void @cqrt_free(i32 %99)
  br label %89

115:                                              ; preds = %124, %132
  %116 = call i32 @cqrt_pop()
  %117 = call i32 @cqrt_pop()
  %118 = call i32 @cqrt_pop()
  %119 = call i32 @cqrt_pop()
  %120 = call i32 @cqrt_pop()
  %121 = call i32 @cqrt_pop()
  %122 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %122, i32 %121, i32 %120, i32 %119)
  call void @cqrt_free(i32 %122)
  call void @cq_template_select_i32_lh_unc(i32 %120, i32 %118, i32 6, i32 %117)
  call void @cqrt_free(i32 %120)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %118, i32 %14, i32 1)
  call void @cqrt_free(i32 %118)
  call void @cq_template_select_i32_ll_unc(i32 %117, i32 %116, i32 4, i32 7)
  call void @cqrt_free(i32 %117)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %116, i32 %14, i32 0)
  call void @cqrt_free(i32 %116)
  %123 = call i32 @cqrt_pop()
  switch i32 %123, label %89 [
    i32 1, label %98
  ]

124:                                              ; preds = %132
  %125 = call i32 @cqrt_pop()
  %126 = call i32 @cqrt_pop()
  %127 = call i32 @cqrt_pop()
  %128 = call i32 @cqrt_pop()
  %129 = call i32 @cqrt_pop()
  %130 = call i32 @cqrt_pop()
  %131 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %131, i32 %130, i32 %129, i32 %128)
  call void @cqrt_free(i32 %131)
  call void @cq_template_select_i32_lh_unc(i32 %129, i32 %127, i32 6, i32 %126)
  call void @cqrt_free(i32 %129)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %127, i32 %14, i32 1)
  call void @cqrt_free(i32 %127)
  call void @cq_template_select_i32_ll_unc(i32 %126, i32 %125, i32 5, i32 7)
  call void @cqrt_free(i32 %126)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %125, i32 %14, i32 0)
  call void @cqrt_free(i32 %125)
  br label %115

132:                                              ; preds = %20, %89
  %133 = call i32 @cqrt_pop()
  switch i32 %133, label %115 [
    i32 1, label %124
  ]

134:                                              ; preds = %88
  br label %16
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare i32 @__cq_mem()

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)

declare i32 @cq_template_add_i32_hl(i32, i32)

define internal fastcc i32 @__cq_q_putA_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @cnt to i64))
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @cnt to i64), i32 %5)
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_select_i32(i32 %0, i32 %6, i32 %5)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  %8 = call i32 @cq_template_sub_i32_hl(i32 %7, i32 1)
  %9 = call i32 @cq_template_select_i32(i32 %0, i32 %8, i32 %7)
  call void @cqrt_copy_i32(i32 %9, i32 %5)
  call void @cq_template_select_i32_unc(i32 %9, i32 %0, i32 %8, i32 %7)
  call void @cqrt_free(i32 %9)
  call void @cq_template_sub_i32_hl_unc(i32 %8, i32 %7, i32 1)
  call void @cqrt_free(i32 %8)
  call void @cqrt_free(i32 %5)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @cnt to i64), i32 %7)
  call void @cqrt_free(i32 %7)
  %10 = call i32 @cq_template_and_i32_hl(i32 %4, i32 7)
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)
  %12 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 4)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_qram_store_i32_controlled(i32 %0, i32 %3, i32 %13, i32 %1)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %11, i64 4)
  call void @cqrt_free(i32 %12)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %4, i32 7)
  call void @cqrt_free(i32 %10)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %4, i32 %0, i32 %3, i64 ptrtoint (ptr @cnt to i64))
  %14 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %14)
  ret i32 %14
}

define internal fastcc void @__cq_q_putB_v_ctl(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 4)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @out to i64))
  %13 = call i32 @cqrt_alloc_i32(i32 4)
  call void @cqrt_qram_store_i32_controlled(i32 %0, i32 %2, i32 %12, i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 4)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %3, i32 7)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %3, i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  ret void
}

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

define internal fastcc void @__cq_q_putD_v_ctl(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 4)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @out to i64))
  %13 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_qram_store_i32_controlled(i32 %0, i32 %2, i32 %12, i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 4)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %3, i32 7)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %3, i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  ret void
}

define internal fastcc void @__cq_q_putC_v_ctl(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 4)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @out to i64))
  %13 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32_controlled(i32 %0, i32 %2, i32 %12, i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 4)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %3, i32 7)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %3, i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  ret void
}

define internal fastcc void @__cq_q_putE_v_ctl(i32 %0) unnamed_addr {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 4)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @out to i64))
  %13 = call i32 @cqrt_alloc_i32(i32 11)
  call void @cqrt_qram_store_i32_controlled(i32 %0, i32 %2, i32 %12, i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @out to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 4)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %3, i32 7)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %3, i32 %0, i32 %2, i64 ptrtoint (ptr @cnt to i64))
  ret void
}

declare i32 @cq_template_add_i32(i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %8)
  call void @cqrt_ry_i32_qangle(i32 %8, i32 %3)
  %9 = alloca { i32, ptr }, align 8
  %10 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 0
  store i32 %8, ptr %10, align 4
  %11 = load ptr, ptr %cq.mints, align 8
  %12 = getelementptr inbounds { i32, ptr }, ptr %9, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  store ptr %9, ptr %cq.mints, align 8
  %13 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 1)
  %14 = call i32 @cq_template_icmp_eq_i64_hl(i32 %0, i64 0)
  %15 = call i32 @cq_template_and_i32_hl(i32 %8, i32 8)
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %17 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 2)
  %18 = call i32 @cq_template_and_i32_hl(i32 %17, i32 3)
  %19 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 2)
  br label %20

20:                                               ; preds = %5
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  %22 = call i32 @llvm.umin.i32(i32 %4, i32 2147483646)
  %23 = icmp ult i32 %4, 2147483646
  %24 = icmp ult i32 0, %22
  br i1 %24, label %25, label %74

25:                                               ; preds = %25, %20
  %from = phi i32 [ 0, %25 ], [ 1, %20 ]
  %26 = phi i32 [ 0, %20 ], [ %72, %25 ]
  %27 = phi i32 [ %13, %20 ], [ %68, %25 ]
  %28 = phi i32 [ 1, %20 ], [ %65, %25 ]
  %29 = phi i32 [ %21, %20 ], [ %69, %25 ]
  call void @cqrt_push(i32 %from)
  %30 = shl i32 1, %28
  %31 = call i32 @cq_template_and_i32_hl(i32 %8, i32 %30)
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %31, i32 0)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  %34 = call i32 @cqrt_alloc_i1(i1 false)
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_xor_i1(i32 %32, i32 %35)
  call void @cqrt_xor_i1(i32 %35, i32 %34)
  call void @cqrt_and_i1(i32 %35, i32 %14, i32 %34)
  call void @cqrt_xor_i1(i32 %34, i32 %33)
  call void @cqrt_and_i1(i32 %34, i32 %16, i32 %33)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %33, i32 %36)
  %37 = call i32 @cqrt_qram_load_i32_controlled(i32 %36, i32 %7, i32 %0)
  %38 = call i32 @cq_template_add_i32_hl(i32 %37, i32 2)
  %39 = call fastcc i32 @__cq_q_putA_1_ctl(i32 %36, i32 %38)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_xor_i1(i32 %32, i32 %42)
  call void @cqrt_xor_i1(i32 %42, i32 %41)
  call void @cqrt_and_i1(i32 %42, i32 %14, i32 %41)
  call void @cqrt_and_i1(i32 %16, i32 %41, i32 %40)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %40, i32 %43)
  call fastcc void @__cq_q_putB_v_ctl(i32 %43)
  call void @cqrt_and_i1(i32 %27, i32 %40, i32 %43)
  call void @cqrt_free(i32 %43)
  call void @cqrt_and_i1(i32 %16, i32 %41, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cqrt_and_i1(i32 %42, i32 %14, i32 %41)
  call void @cqrt_xor_i1(i32 %42, i32 %41)
  call void @cqrt_free(i32 %41)
  call void @cqrt_xor_i1(i32 %32, i32 %42)
  call void @cqrt_not_i1(i32 %42)
  call void @cqrt_free(i32 %42)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  %45 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 1)
  call void @cqrt_and_i1(i32 %45, i32 %32, i32 %44)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %44, i32 %46)
  call fastcc void @__cq_q_putD_v_ctl(i32 %46)
  call void @cqrt_and_i1(i32 %27, i32 %44, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_and_i1(i32 %45, i32 %32, i32 %44)
  call void @cqrt_free(i32 %44)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %45, i32 %18, i32 1)
  call void @cqrt_free(i32 %45)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  %49 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 0)
  call void @cqrt_and_i1(i32 %49, i32 %32, i32 %48)
  call void @cqrt_xor_i1(i32 %48, i32 %47)
  call void @cqrt_and_i1(i32 %48, i32 %19, i32 %47)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %47, i32 %50)
  call fastcc void @__cq_q_putC_v_ctl(i32 %50)
  call void @cqrt_and_i1(i32 %27, i32 %47, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cqrt_and_i1(i32 %48, i32 %19, i32 %47)
  call void @cqrt_xor_i1(i32 %48, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_and_i1(i32 %49, i32 %32, i32 %48)
  call void @cqrt_free(i32 %48)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %49, i32 %18, i32 0)
  call void @cqrt_free(i32 %49)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  %52 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 1)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 0)
  call void @cqrt_xor_i1(i32 %32, i32 %53)
  call void @cqrt_and_i1(i32 %32, i32 %54, i32 %53)
  call void @cqrt_xor_i1(i32 %53, i32 %51)
  call void @cqrt_and_i1(i32 %53, i32 %52, i32 %51)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %51, i32 %55)
  call fastcc void @__cq_q_putE_v_ctl(i32 %55)
  call void @cqrt_and_i1(i32 %27, i32 %51, i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_and_i1(i32 %53, i32 %52, i32 %51)
  call void @cqrt_xor_i1(i32 %53, i32 %51)
  call void @cqrt_free(i32 %51)
  call void @cqrt_and_i1(i32 %32, i32 %54, i32 %53)
  call void @cqrt_xor_i1(i32 %32, i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %54, i32 %18, i32 0)
  call void @cqrt_free(i32 %54)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %52, i32 %18, i32 1)
  call void @cqrt_free(i32 %52)
  %56 = call i32 @cq_template_select_i32_lh(i32 %16, i32 3, i32 %38)
  %57 = call i32 @cq_template_select_i32_lh(i32 %14, i32 1, i32 %56)
  %58 = call i32 @cq_template_select_i32_ll(i32 %19, i32 4, i32 5)
  %59 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 0)
  %60 = call i32 @cq_template_select_i32_hl(i32 %59, i32 %58, i32 7)
  %61 = call i32 @cq_template_icmp_eq_i32_hl(i32 %18, i32 1)
  %62 = call i32 @cq_template_select_i32_lh(i32 %61, i32 6, i32 %60)
  %63 = call i32 @cq_template_select_i32(i32 %32, i32 %62, i32 %57)
  %64 = call i32 @cq_template_add_i32(i32 %63, i32 %29)
  %65 = add i32 %28, 1
  %66 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 %65)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_xor_i1(i32 %66, i32 %67)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %27, i32 %67, i32 %68)
  %69 = call i32 @cq_template_select_i32(i32 %27, i32 %64, i32 %29)
  call void @cq_template_add_i32_unc(i32 %64, i32 %63, i32 %29)
  call void @cqrt_free(i32 %64)
  %70 = call i32 @cq_template_sub_i32(i32 %69, i32 %63)
  %71 = call i32 @cq_template_select_i32(i32 %27, i32 %70, i32 %69)
  call void @cqrt_copy_i32(i32 %71, i32 %29)
  call void @cq_template_select_i32_unc(i32 %71, i32 %27, i32 %70, i32 %69)
  call void @cqrt_free(i32 %71)
  call void @cqrt_free(i32 %29)
  call void @cq_template_sub_i32_unc(i32 %70, i32 %69, i32 %63)
  call void @cqrt_free(i32 %70)
  call void @cq_template_select_i32_unc(i32 %63, i32 %32, i32 %62, i32 %57)
  call void @cqrt_free(i32 %63)
  call void @cq_template_select_i32_lh_unc(i32 %62, i32 %61, i32 6, i32 %60)
  call void @cqrt_free(i32 %62)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %61, i32 %18, i32 1)
  call void @cqrt_free(i32 %61)
  call void @cq_template_select_i32_hl_unc(i32 %60, i32 %59, i32 %58, i32 7)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %59, i32 %18, i32 0)
  call void @cqrt_free(i32 %59)
  call void @cq_template_select_i32_ll_unc(i32 %58, i32 %19, i32 4, i32 5)
  call void @cqrt_free(i32 %58)
  call void @cq_template_select_i32_lh_unc(i32 %57, i32 %14, i32 1, i32 %56)
  call void @cqrt_free(i32 %57)
  call void @cq_template_select_i32_lh_unc(i32 %56, i32 %16, i32 3, i32 %38)
  call void @cqrt_free(i32 %56)
  call void @cq_template_add_i32_hl_unc(i32 %38, i32 %37, i32 2)
  call void @cqrt_free(i32 %38)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %37, i32 %36, i32 %7, i32 %0)
  call void @cqrt_and_i1(i32 %27, i32 %33, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_and_i1(i32 %34, i32 %16, i32 %33)
  call void @cqrt_xor_i1(i32 %34, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cqrt_and_i1(i32 %35, i32 %14, i32 %34)
  call void @cqrt_xor_i1(i32 %35, i32 %34)
  call void @cqrt_free(i32 %34)
  call void @cqrt_xor_i1(i32 %32, i32 %35)
  call void @cqrt_not_i1(i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %32, i32 %31, i32 0)
  call void @cqrt_free(i32 %32)
  call void @cq_template_and_i32_hl_unc(i32 %31, i32 %8, i32 %30)
  call void @cqrt_free(i32 %31)
  %72 = add i32 %26, 1
  %73 = icmp ult i32 %72, %22
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %65)
  br i1 %73, label %25, label %74

74:                                               ; preds = %25, %20
  %75 = phi i32 [ 0, %20 ], [ 1, %25 ]
  %76 = phi i32 [ 1, %20 ], [ %65, %25 ]
  %77 = phi i32 [ %21, %20 ], [ %69, %25 ]
  %78 = phi i32 [ %13, %20 ], [ %68, %25 ]
  br i1 %23, label %79, label %81

79:                                               ; preds = %74
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %78, i32 %80)
  br label %82

81:                                               ; preds = %74
  br label %82

82:                                               ; preds = %79, %81
  br label %93

83:                                               ; preds = %93, %86
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %19, i32 %1, i32 2)
  call void @cqrt_free(i32 %19)
  call void @cq_template_and_i32_hl_unc(i32 %18, i32 %17, i32 3)
  call void @cqrt_free(i32 %18)
  call void @cq_template_lshr_i32_hl_unc(i32 %17, i32 %8, i32 2)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %8, i32 8)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %14, i32 %0, i64 0)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %1, i32 1)
  call void @cqrt_free(i32 %13)
  %84 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %84)
  %85 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %77, i32 %85)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %85

86:                                               ; preds = %93, %86
  %87 = call i32 @cqrt_pop()
  %88 = call i32 @cqrt_pop()
  %89 = call i32 @cqrt_pop()
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %91, i32 %90, i32 %89)
  call void @cqrt_free(i32 %89)
  call void @cqrt_xor_i1(i32 %88, i32 %90)
  call void @cqrt_not_i1(i32 %90)
  call void @cqrt_free(i32 %90)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %88, i32 %1, i32 %87)
  call void @cqrt_free(i32 %88)
  %92 = call i32 @cqrt_pop()
  switch i32 %92, label %86 [
    i32 1, label %83
  ]

93:                                               ; preds = %82
  switch i32 %75, label %83 [
    i32 1, label %86
  ]
}

declare void @cqrt_ry_i32_qangle(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

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

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

define internal i32 @__cq_q_f_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %102

11:                                               ; preds = %6
  %12 = call i32 @__cq_mem()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %13)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %13, i32 %4)
  %14 = alloca { i32, ptr }, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 0
  store i32 %13, ptr %15, align 4
  %16 = load ptr, ptr %cq.mints, align 8
  %17 = getelementptr inbounds { i32, ptr }, ptr %14, i32 0, i32 1
  store ptr %16, ptr %17, align 8
  store ptr %14, ptr %cq.mints, align 8
  %18 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 1)
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %1, i64 0)
  %20 = call i32 @cq_template_and_i32_hl(i32 %13, i32 8)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 0)
  %22 = call i32 @cq_template_lshr_i32_hl(i32 %13, i32 2)
  %23 = call i32 @cq_template_and_i32_hl(i32 %22, i32 3)
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %2, i32 2)
  br label %25

25:                                               ; preds = %11
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %26)
  %27 = call i32 @cqrt_alloc_i32(i32 0)
  %28 = call i32 @llvm.umin.i32(i32 %5, i32 2147483646)
  %29 = icmp ult i32 %5, 2147483646
  %30 = icmp ult i32 0, %28
  br i1 %30, label %31, label %80

31:                                               ; preds = %31, %25
  %from = phi i32 [ 0, %31 ], [ 1, %25 ]
  %32 = phi i32 [ 0, %25 ], [ %78, %31 ]
  %33 = phi i32 [ %26, %25 ], [ %74, %31 ]
  %34 = phi i32 [ 1, %25 ], [ %71, %31 ]
  %35 = phi i32 [ %27, %25 ], [ %75, %31 ]
  call void @cqrt_push(i32 %from)
  %36 = shl i32 1, %34
  %37 = call i32 @cq_template_and_i32_hl(i32 %13, i32 %36)
  %38 = call i32 @cq_template_icmp_eq_i32_hl(i32 %37, i32 0)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_xor_i1(i32 %38, i32 %41)
  call void @cqrt_xor_i1(i32 %41, i32 %40)
  call void @cqrt_and_i1(i32 %41, i32 %19, i32 %40)
  call void @cqrt_xor_i1(i32 %40, i32 %39)
  call void @cqrt_and_i1(i32 %40, i32 %21, i32 %39)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %39, i32 %42)
  %43 = call i32 @cqrt_qram_load_i32_controlled(i32 %42, i32 %12, i32 %1)
  %44 = call i32 @cq_template_add_i32_hl(i32 %43, i32 2)
  %45 = call fastcc i32 @__cq_q_putA_1_ctl(i32 %42, i32 %44)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_xor_i1(i32 %38, i32 %48)
  call void @cqrt_xor_i1(i32 %48, i32 %47)
  call void @cqrt_and_i1(i32 %48, i32 %19, i32 %47)
  call void @cqrt_and_i1(i32 %21, i32 %47, i32 %46)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %46, i32 %49)
  call fastcc void @__cq_q_putB_v_ctl(i32 %49)
  call void @cqrt_and_i1(i32 %33, i32 %46, i32 %49)
  call void @cqrt_free(i32 %49)
  call void @cqrt_and_i1(i32 %21, i32 %47, i32 %46)
  call void @cqrt_free(i32 %46)
  call void @cqrt_and_i1(i32 %48, i32 %19, i32 %47)
  call void @cqrt_xor_i1(i32 %48, i32 %47)
  call void @cqrt_free(i32 %47)
  call void @cqrt_xor_i1(i32 %38, i32 %48)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_free(i32 %48)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  %51 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 1)
  call void @cqrt_and_i1(i32 %51, i32 %38, i32 %50)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %50, i32 %52)
  call fastcc void @__cq_q_putD_v_ctl(i32 %52)
  call void @cqrt_and_i1(i32 %33, i32 %50, i32 %52)
  call void @cqrt_free(i32 %52)
  call void @cqrt_and_i1(i32 %51, i32 %38, i32 %50)
  call void @cqrt_free(i32 %50)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %51, i32 %23, i32 1)
  call void @cqrt_free(i32 %51)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  %55 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 0)
  call void @cqrt_and_i1(i32 %55, i32 %38, i32 %54)
  call void @cqrt_xor_i1(i32 %54, i32 %53)
  call void @cqrt_and_i1(i32 %54, i32 %24, i32 %53)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %53, i32 %56)
  call fastcc void @__cq_q_putC_v_ctl(i32 %56)
  call void @cqrt_and_i1(i32 %33, i32 %53, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_and_i1(i32 %54, i32 %24, i32 %53)
  call void @cqrt_xor_i1(i32 %54, i32 %53)
  call void @cqrt_free(i32 %53)
  call void @cqrt_and_i1(i32 %55, i32 %38, i32 %54)
  call void @cqrt_free(i32 %54)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %55, i32 %23, i32 0)
  call void @cqrt_free(i32 %55)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  %58 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 1)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  %60 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 0)
  call void @cqrt_xor_i1(i32 %38, i32 %59)
  call void @cqrt_and_i1(i32 %38, i32 %60, i32 %59)
  call void @cqrt_xor_i1(i32 %59, i32 %57)
  call void @cqrt_and_i1(i32 %59, i32 %58, i32 %57)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %57, i32 %61)
  call fastcc void @__cq_q_putE_v_ctl(i32 %61)
  call void @cqrt_and_i1(i32 %33, i32 %57, i32 %61)
  call void @cqrt_free(i32 %61)
  call void @cqrt_and_i1(i32 %59, i32 %58, i32 %57)
  call void @cqrt_xor_i1(i32 %59, i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %38, i32 %60, i32 %59)
  call void @cqrt_xor_i1(i32 %38, i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %60, i32 %23, i32 0)
  call void @cqrt_free(i32 %60)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %58, i32 %23, i32 1)
  call void @cqrt_free(i32 %58)
  %62 = call i32 @cq_template_select_i32_lh(i32 %21, i32 3, i32 %44)
  %63 = call i32 @cq_template_select_i32_lh(i32 %19, i32 1, i32 %62)
  %64 = call i32 @cq_template_select_i32_ll(i32 %24, i32 4, i32 5)
  %65 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 0)
  %66 = call i32 @cq_template_select_i32_hl(i32 %65, i32 %64, i32 7)
  %67 = call i32 @cq_template_icmp_eq_i32_hl(i32 %23, i32 1)
  %68 = call i32 @cq_template_select_i32_lh(i32 %67, i32 6, i32 %66)
  %69 = call i32 @cq_template_select_i32(i32 %38, i32 %68, i32 %63)
  %70 = call i32 @cq_template_add_i32(i32 %69, i32 %35)
  %71 = add i32 %34, 1
  %72 = call i32 @cq_template_icmp_eq_i32_hl(i32 %2, i32 %71)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %73)
  call void @cqrt_xor_i1(i32 %72, i32 %73)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %73, i32 %74)
  %75 = call i32 @cq_template_select_i32(i32 %33, i32 %70, i32 %35)
  call void @cq_template_add_i32_unc(i32 %70, i32 %69, i32 %35)
  call void @cqrt_free(i32 %70)
  %76 = call i32 @cq_template_sub_i32(i32 %75, i32 %69)
  %77 = call i32 @cq_template_select_i32(i32 %33, i32 %76, i32 %75)
  call void @cqrt_copy_i32(i32 %77, i32 %35)
  call void @cq_template_select_i32_unc(i32 %77, i32 %33, i32 %76, i32 %75)
  call void @cqrt_free(i32 %77)
  call void @cqrt_free(i32 %35)
  call void @cq_template_sub_i32_unc(i32 %76, i32 %75, i32 %69)
  call void @cqrt_free(i32 %76)
  call void @cq_template_select_i32_unc(i32 %69, i32 %38, i32 %68, i32 %63)
  call void @cqrt_free(i32 %69)
  call void @cq_template_select_i32_lh_unc(i32 %68, i32 %67, i32 6, i32 %66)
  call void @cqrt_free(i32 %68)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %67, i32 %23, i32 1)
  call void @cqrt_free(i32 %67)
  call void @cq_template_select_i32_hl_unc(i32 %66, i32 %65, i32 %64, i32 7)
  call void @cqrt_free(i32 %66)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %65, i32 %23, i32 0)
  call void @cqrt_free(i32 %65)
  call void @cq_template_select_i32_ll_unc(i32 %64, i32 %24, i32 4, i32 5)
  call void @cqrt_free(i32 %64)
  call void @cq_template_select_i32_lh_unc(i32 %63, i32 %19, i32 1, i32 %62)
  call void @cqrt_free(i32 %63)
  call void @cq_template_select_i32_lh_unc(i32 %62, i32 %21, i32 3, i32 %44)
  call void @cqrt_free(i32 %62)
  call void @cq_template_add_i32_hl_unc(i32 %44, i32 %43, i32 2)
  call void @cqrt_free(i32 %44)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %43, i32 %42, i32 %12, i32 %1)
  call void @cqrt_and_i1(i32 %33, i32 %39, i32 %42)
  call void @cqrt_free(i32 %42)
  call void @cqrt_and_i1(i32 %40, i32 %21, i32 %39)
  call void @cqrt_xor_i1(i32 %40, i32 %39)
  call void @cqrt_free(i32 %39)
  call void @cqrt_and_i1(i32 %41, i32 %19, i32 %40)
  call void @cqrt_xor_i1(i32 %41, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cqrt_xor_i1(i32 %38, i32 %41)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_free(i32 %41)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %38, i32 %37, i32 0)
  call void @cqrt_free(i32 %38)
  call void @cq_template_and_i32_hl_unc(i32 %37, i32 %13, i32 %36)
  call void @cqrt_free(i32 %37)
  %78 = add i32 %32, 1
  %79 = icmp ult i32 %78, %28
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %71)
  br i1 %79, label %31, label %80

80:                                               ; preds = %31, %25
  %81 = phi i32 [ 0, %25 ], [ 1, %31 ]
  %82 = phi i32 [ 1, %25 ], [ %71, %31 ]
  %83 = phi i32 [ %27, %25 ], [ %75, %31 ]
  %84 = phi i32 [ %26, %25 ], [ %74, %31 ]
  br i1 %29, label %85, label %87

85:                                               ; preds = %80
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %84, i32 %86)
  br label %88

87:                                               ; preds = %80
  br label %88

88:                                               ; preds = %85, %87
  br label %101

89:                                               ; preds = %101, %94
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %2, i32 2)
  call void @cqrt_free(i32 %24)
  call void @cq_template_and_i32_hl_unc(i32 %23, i32 %22, i32 3)
  call void @cqrt_free(i32 %23)
  call void @cq_template_lshr_i32_hl_unc(i32 %22, i32 %13, i32 2)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %20, i32 0)
  call void @cqrt_free(i32 %21)
  call void @cq_template_and_i32_hl_unc(i32 %20, i32 %13, i32 8)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %1, i64 0)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %2, i32 1)
  call void @cqrt_free(i32 %18)
  %90 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %90)
  %91 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %83, i32 %91)
  %92 = load i32, ptr @__cq_act_f, align 4
  %93 = add i32 %92, -1
  store i32 %93, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %91

94:                                               ; preds = %101, %94
  %95 = call i32 @cqrt_pop()
  %96 = call i32 @cqrt_pop()
  %97 = call i32 @cqrt_pop()
  %98 = call i32 @cqrt_pop()
  %99 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %99, i32 %98, i32 %97)
  call void @cqrt_free(i32 %97)
  call void @cqrt_xor_i1(i32 %96, i32 %98)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_free(i32 %98)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %96, i32 %2, i32 %95)
  call void @cqrt_free(i32 %96)
  %100 = call i32 @cqrt_pop()
  switch i32 %100, label %94 [
    i32 1, label %89
  ]

101:                                              ; preds = %88
  switch i32 %81, label %89 [
    i32 1, label %94
  ]

102:                                              ; preds = %6
  %103 = call i32 @cqrt_alloc_i32(i32 0)
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %104)
  call void @cqrt_push(i32 0)
  %105 = load i32, ptr @__cq_act_f, align 4
  %106 = add i32 %105, -1
  store i32 %106, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %103
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig, ptr @__cq_q_f_1111_t, ptr @__cq_q_f_1111_t_ctl, ptr @__cq_q_f_1111_t_unc, ptr @__cq_q_f_1111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_f_1111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = call i32 @cqrt_pop()
  br label %9

9:                                                ; preds = %12, %6
  %10 = phi i32 [ %8, %6 ], [ %14, %12 ]
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %9
  %13 = call i32 @cqrt_pop()
  %14 = sub i32 %10, 1
  br label %9

15:                                               ; preds = %9
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_1111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6) {
  %8 = load i32, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  %9 = load i32, ptr @__cq_act_f, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_f, align 4
  %11 = load i32, ptr @__cq_act_f, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_f, align 4
  %13 = call i32 @cqrt_pop()
  br label %14

14:                                               ; preds = %17, %7
  %15 = phi i32 [ %13, %7 ], [ %19, %17 ]
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %20, label %17

17:                                               ; preds = %14
  %18 = call i32 @cqrt_pop()
  %19 = sub i32 %15, 1
  br label %14

20:                                               ; preds = %14
  store i32 %8, ptr @__cq_k, align 4
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
