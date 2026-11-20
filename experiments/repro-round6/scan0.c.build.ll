; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/scan0.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@limbs = local_unnamed_addr global [6 x i64] [i64 0, i64 65280, i64 -1, i64 -1, i64 65536, i64 0], align 16
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [23 x i8] c"i64 (i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i64 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %5, double %2)
  %6 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %6, double %2)
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 -1)
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %7)
  %10 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 8)
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 ptrtoint (ptr @limbs to i64))
  %12 = call i32 @cqrt_qram_load_i64(i32 %4, i32 %11)
  %13 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 -1)
  %14 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  br label %16

16:                                               ; preds = %3
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %17)
  %18 = call i32 @cqrt_alloc_i64(i64 0)
  %19 = call i32 @cq_template_add_i64_hl(i32 %15, i64 1)
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 5)
  %21 = call i32 @cqrt_alloc_i64(i64 320)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %20, i32 %22)
  %23 = call i32 @cq_template_select_i64(i32 %22, i32 %21, i32 %18)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_xor_i1(i32 %20, i32 %24)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %17, i32 %24, i32 %25)
  br label %26

26:                                               ; preds = %93, %16
  %from8 = phi i32 [ 0, %93 ], [ 1, %16 ]
  %27 = phi i32 [ 0, %16 ], [ %86, %93 ]
  %28 = phi i32 [ %25, %16 ], [ %100, %93 ]
  %29 = phi i32 [ %15, %16 ], [ %85, %93 ]
  %30 = phi i64 [ 0, %16 ], [ %84, %93 ]
  %31 = phi i32 [ %19, %16 ], [ %94, %93 ]
  %32 = phi i32 [ %20, %16 ], [ %95, %93 ]
  %33 = phi i32 [ %23, %16 ], [ %98, %93 ]
  call void @cqrt_push(i32 %from8)
  %34 = call i32 @cq_template_mul_i64_hl(i32 %31, i64 8)
  %35 = call i32 @cq_template_add_i64_hl(i32 %34, i64 ptrtoint (ptr @limbs to i64))
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %36)
  call void @cqrt_xor_i1(i32 %32, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %36, i32 %37)
  %38 = call i32 @cqrt_qram_load_i64_controlled(i32 %37, i32 %4, i32 %35)
  %39 = call i32 @cq_template_icmp_eq_i64_hl(i32 %38, i64 -1)
  %40 = call i32 @cq_template_trunc_i64_to_i32(i32 %31)
  %41 = call i32 @cq_template_xor_i64_hl(i32 %38, i64 -1)
  %42 = call i32 @cq_template_and_i64_hl(i32 %41, i64 255)
  %43 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 0)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %46)
  call void @cqrt_xor_i1(i32 %32, i32 %46)
  call void @cqrt_and_i1(i32 %43, i32 %46, i32 %45)
  call void @cqrt_xor_i1(i32 %45, i32 %44)
  call void @cqrt_and_i1(i32 %45, i32 %39, i32 %44)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %44, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %50)
  call void @cqrt_xor_i1(i32 %50, i32 %49)
  call void @cqrt_and_i1(i32 %50, i32 %32, i32 %49)
  call void @cqrt_and_i1(i32 %43, i32 %49, i32 %48)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %47, i32 %48, i32 %51)
  %52 = call i32 @cqrt_alloc_i32(i32 0)
  %53 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %34)
  br label %55

54:                                               ; preds = %55
  br label %68

55:                                               ; preds = %55, %26
  %from7 = phi i32 [ 0, %55 ], [ 1, %26 ]
  %56 = phi i32 [ 0, %26 ], [ %59, %55 ]
  %57 = phi i32 [ %41, %26 ], [ %63, %55 ]
  %trip = phi i32 [ %51, %26 ], [ %67, %55 ]
  %cap = phi i32 [ %52, %26 ], [ %64, %55 ]
  %cap1 = phi i32 [ %53, %26 ], [ %65, %55 ]
  call void @cqrt_push(i32 %from7)
  %58 = call i32 @cq_template_lshr_i64_hl(i32 %57, i64 8)
  %59 = add nuw nsw i32 %56, 8
  %60 = call i32 @cq_template_and_i64_hl(i32 %58, i64 255)
  %61 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 0)
  %62 = icmp ult i32 %56, 48
  %63 = call i32 @cq_template_select_i64(i32 %trip, i32 %58, i32 %57)
  %64 = call i32 @cq_template_select_i32_lh(i32 %trip, i32 %59, i32 %cap)
  %65 = call i32 @cq_template_select_i64(i32 %trip, i32 %60, i32 %cap1)
  %66 = xor i1 %62, true
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %61, i32 %67)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %cap1)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %cap)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %57)
  br i1 %66, label %54, label %55

68:                                               ; preds = %54
  br label %69

69:                                               ; preds = %68
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  %71 = call i32 @cq_template_select_i32_hl(i32 %43, i32 %64, i32 0)
  %72 = call i32 @cq_template_select_i64(i32 %43, i32 %65, i32 %42)
  %73 = call i32 @cq_template_shl_i32_hl(i32 %40, i32 6)
  %74 = call i32 @cq_template_add_i32(i32 %71, i32 %73)
  %75 = call i32 @cq_template_zext_i32_to_i64(i32 %74)
  %76 = call i32 @cq_template_add_i64(i32 %72, i32 %75)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %78)
  call void @cqrt_xor_i1(i32 %32, i32 %78)
  call void @cqrt_xor_i1(i32 %78, i32 %77)
  call void @cqrt_and_i1(i32 %78, i32 %39, i32 %77)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %77, i32 %79)
  %80 = call i32 @cq_template_select_i64(i32 %79, i32 %76, i32 %33)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %82)
  call void @cqrt_xor_i1(i32 %32, i32 %82)
  call void @cqrt_and_i1(i32 %39, i32 %82, i32 %81)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %81, i32 %83)
  %84 = add i64 %30, 1
  %85 = call i32 @cq_template_add_i64_hl(i32 %15, i64 %84)
  %86 = add i32 %27, 1
  %87 = icmp ult i32 %86, 4
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %85)
  %88 = trunc i64 %84 to i32
  call void @cqrt_push(i32 %88)
  %89 = lshr i64 %84, 32
  %90 = trunc i64 %89 to i32
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %70)
  br i1 %87, label %93, label %91

91:                                               ; preds = %69
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %83, i32 %92)
  br label %101

93:                                               ; preds = %69
  %94 = call i32 @cq_template_add_i64_hl(i32 %85, i64 1)
  %95 = call i32 @cq_template_icmp_eq_i64_hl(i32 %94, i64 5)
  %96 = call i32 @cqrt_alloc_i64(i64 320)
  %97 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %83, i32 %95, i32 %97)
  %98 = call i32 @cq_template_select_i64(i32 %97, i32 %96, i32 %80)
  %99 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %99)
  call void @cqrt_xor_i1(i32 %95, i32 %99)
  %100 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %83, i32 %99, i32 %100)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %100)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %85)
  br label %26

101:                                              ; preds = %91
  %102 = call i32 @cq_template_xor_i64_hl(i32 %12, i64 -1)
  %103 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 2)
  %104 = call i32 @cq_template_zext_i32_to_i64(i32 %103)
  %105 = call i32 @cq_template_and_i64(i32 %12, i32 %104)
  %106 = call i32 @cq_template_icmp_eq_i64_hl(i32 %105, i64 0)
  %107 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %108 = call i32 @cq_template_zext_i32_to_i64(i32 %107)
  br label %109

109:                                              ; preds = %101
  %110 = call i32 @cqrt_alloc_i1(i1 false)
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %111)
  call void @cqrt_xor_i1(i32 %8, i32 %111)
  call void @cqrt_and_i1(i32 %106, i32 %111, i32 %110)
  %112 = call i32 @cqrt_alloc_i32(i32 0)
  %113 = call i32 @cq_template_icmp_eq_i64_hl(i32 %108, i64 4)
  %114 = call i32 @cqrt_alloc_i32(i32 4)
  %115 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %110, i32 %113, i32 %115)
  %116 = call i32 @cq_template_select_i32(i32 %115, i32 %114, i32 %112)
  %117 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %117)
  call void @cqrt_xor_i1(i32 %113, i32 %117)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %110, i32 %117, i32 %118)
  br label %119

119:                                              ; preds = %150, %109
  %from5 = phi i32 [ 0, %150 ], [ 1, %109 ]
  %120 = phi i32 [ 0, %109 ], [ %143, %150 ]
  %121 = phi i32 [ %118, %109 ], [ %156, %150 ]
  %122 = phi i32 [ %108, %109 ], [ %142, %150 ]
  %123 = phi i64 [ 0, %109 ], [ %141, %150 ]
  %124 = phi i32 [ %113, %109 ], [ %151, %150 ]
  %125 = phi i32 [ %116, %109 ], [ %154, %150 ]
  call void @cqrt_push(i32 %from5)
  %126 = call i32 @cq_template_add_i64_hl(i32 %122, i64 1)
  %127 = call i32 @cq_template_mul_i64_hl(i32 %126, i64 8)
  %128 = call i32 @cq_template_add_i64_hl(i32 %127, i64 ptrtoint (ptr @limbs to i64))
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %129)
  call void @cqrt_xor_i1(i32 %124, i32 %129)
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %121, i32 %129, i32 %130)
  %131 = call i32 @cqrt_qram_load_i64_controlled(i32 %130, i32 %4, i32 %128)
  %132 = call i32 @cq_template_icmp_eq_i64_hl(i32 %131, i64 0)
  %133 = call i32 @cq_template_trunc_i64_to_i32(i32 %122)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %135)
  call void @cqrt_xor_i1(i32 %124, i32 %135)
  call void @cqrt_xor_i1(i32 %135, i32 %134)
  call void @cqrt_and_i1(i32 %135, i32 %132, i32 %134)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %121, i32 %134, i32 %136)
  %137 = call i32 @cq_template_select_i32(i32 %136, i32 %133, i32 %125)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %139)
  call void @cqrt_xor_i1(i32 %124, i32 %139)
  call void @cqrt_and_i1(i32 %132, i32 %139, i32 %138)
  %140 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %121, i32 %138, i32 %140)
  %141 = add i64 %123, 1
  %142 = call i32 @cq_template_add_i64_hl(i32 %108, i64 %141)
  %143 = add i32 %120, 1
  %144 = icmp ult i32 %143, 4
  call void @cqrt_push(i32 %142)
  %145 = trunc i64 %141 to i32
  call void @cqrt_push(i32 %145)
  %146 = lshr i64 %141, 32
  %147 = trunc i64 %146 to i32
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %138)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %132)
  call void @cqrt_push(i32 %139)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %137)
  call void @cqrt_push(i32 %136)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %134)
  call void @cqrt_push(i32 %135)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %128)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %127)
  call void @cqrt_push(i32 %126)
  br i1 %144, label %150, label %148

148:                                              ; preds = %119
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %140, i32 %149)
  br label %157

150:                                              ; preds = %119
  %151 = call i32 @cq_template_icmp_eq_i64_hl(i32 %142, i64 4)
  %152 = call i32 @cqrt_alloc_i32(i32 4)
  %153 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %151, i32 %153)
  %154 = call i32 @cq_template_select_i32(i32 %153, i32 %152, i32 %137)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %155)
  call void @cqrt_xor_i1(i32 %151, i32 %155)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %155, i32 %156)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %155)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %154)
  call void @cqrt_push(i32 %153)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %137)
  call void @cqrt_push(i32 %142)
  br label %119

157:                                              ; preds = %148
  %158 = call i32 @cq_template_add_i32_hl(i32 %137, i32 1)
  %159 = call i32 @cq_template_zext_i32_to_i64(i32 %158)
  %160 = call i32 @cq_template_mul_i64_hl(i32 %159, i64 8)
  %161 = call i32 @cq_template_add_i64_hl(i32 %160, i64 ptrtoint (ptr @limbs to i64))
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %163)
  call void @cqrt_xor_i1(i32 %8, i32 %163)
  call void @cqrt_and_i1(i32 %106, i32 %163, i32 %162)
  %164 = call i32 @cqrt_qram_load_i64_controlled(i32 %162, i32 %4, i32 %161)
  %165 = call i32 @cq_template_icmp_eq_i64_hl(i32 %164, i64 0)
  %166 = call i32 @cq_template_select_i64(i32 %106, i32 %164, i32 %105)
  %167 = call i32 @cq_template_select_i64(i32 %8, i32 %102, i32 %166)
  %168 = call i32 @cq_template_select_i32(i32 %106, i32 %137, i32 %7)
  %169 = call i32 @cq_template_select_i32(i32 %8, i32 %7, i32 %168)
  %170 = call i32 @cq_template_and_i64_hl(i32 %167, i64 255)
  %171 = call i32 @cq_template_icmp_eq_i64_hl(i32 %170, i64 0)
  br label %172

172:                                              ; preds = %157
  %173 = call i32 @cqrt_alloc_i1(i1 false)
  %174 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %174)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %174)
  %175 = call i32 @cqrt_alloc_i1(i1 false)
  %176 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %176)
  call void @cqrt_xor_i1(i32 %8, i32 %176)
  call void @cqrt_and_i1(i32 %106, i32 %176, i32 %175)
  call void @cqrt_and_i1(i32 %165, i32 %175, i32 %174)
  call void @cqrt_and_i1(i32 %171, i32 %174, i32 %173)
  %177 = call i32 @cqrt_alloc_i32(i32 0)
  %178 = call i32 @cqrt_alloc_i64(i64 0)
  br label %180

179:                                              ; preds = %180
  br label %193

180:                                              ; preds = %180, %172
  %from = phi i32 [ 0, %180 ], [ 1, %172 ]
  %181 = phi i32 [ 0, %172 ], [ %184, %180 ]
  %182 = phi i32 [ %167, %172 ], [ %188, %180 ]
  %trip2 = phi i32 [ %173, %172 ], [ %192, %180 ]
  %cap3 = phi i32 [ %177, %172 ], [ %189, %180 ]
  %cap4 = phi i32 [ %178, %172 ], [ %190, %180 ]
  call void @cqrt_push(i32 %from)
  %183 = call i32 @cq_template_lshr_i64_hl(i32 %182, i64 8)
  %184 = add nuw nsw i32 %181, 8
  %185 = call i32 @cq_template_and_i64_hl(i32 %183, i64 255)
  %186 = call i32 @cq_template_icmp_eq_i64_hl(i32 %185, i64 0)
  %187 = icmp ult i32 %181, 48
  %188 = call i32 @cq_template_select_i64(i32 %trip2, i32 %183, i32 %182)
  %189 = call i32 @cq_template_select_i32_lh(i32 %trip2, i32 %184, i32 %cap3)
  %190 = call i32 @cq_template_select_i64(i32 %trip2, i32 %185, i32 %cap4)
  %191 = xor i1 %187, true
  %192 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip2, i32 %186, i32 %192)
  call void @cqrt_push(i32 %trip2)
  call void @cqrt_push(i32 %186)
  call void @cqrt_push(i32 %192)
  call void @cqrt_push(i32 %190)
  call void @cqrt_push(i32 %185)
  call void @cqrt_push(i32 %cap4)
  call void @cqrt_push(i32 %189)
  call void @cqrt_push(i32 %184)
  call void @cqrt_push(i32 %cap3)
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %183)
  call void @cqrt_push(i32 %182)
  br i1 %191, label %179, label %180

193:                                              ; preds = %179
  %194 = call i32 @cq_template_select_i32_hl(i32 %171, i32 %189, i32 0)
  %195 = call i32 @cq_template_select_i64(i32 %171, i32 %190, i32 %170)
  %196 = call i32 @cq_template_shl_i32_hl(i32 %169, i32 6)
  %197 = call i32 @cq_template_add_i32(i32 %194, i32 %196)
  %198 = call i32 @cq_template_zext_i32_to_i64(i32 %197)
  %199 = call i32 @cq_template_add_i64(i32 %195, i32 %198)
  %200 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %200)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %200)
  %201 = call i32 @cq_template_select_i64(i32 %200, i32 %199, i32 %80)
  %202 = call i32 @cqrt_alloc_i1(i1 false)
  %203 = call i32 @cqrt_alloc_i1(i1 false)
  %204 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %204)
  call void @cqrt_xor_i1(i32 %8, i32 %204)
  call void @cqrt_and_i1(i32 %106, i32 %204, i32 %203)
  call void @cqrt_and_i1(i32 %165, i32 %203, i32 %202)
  %205 = call i32 @cq_template_select_i64_lh(i32 %202, i64 -1, i32 %201)
  call void @cqrt_and_i1(i32 %165, i32 %203, i32 %202)
  call void @cqrt_free(i32 %202)
  call void @cqrt_and_i1(i32 %106, i32 %204, i32 %203)
  call void @cqrt_free(i32 %203)
  call void @cqrt_xor_i1(i32 %8, i32 %204)
  call void @cqrt_not_i1(i32 %204)
  call void @cqrt_free(i32 %204)
  call void @cq_template_select_i64_unc(i32 %201, i32 %200, i32 %199, i32 %80)
  call void @cqrt_free(i32 %201)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %200)
  call void @cqrt_not_i1(i32 %200)
  call void @cqrt_free(i32 %200)
  call void @cq_template_add_i64_unc(i32 %199, i32 %195, i32 %198)
  call void @cqrt_free(i32 %199)
  call void @cq_template_zext_i32_to_i64_unc(i32 %198, i32 %197)
  call void @cqrt_free(i32 %198)
  call void @cq_template_add_i32_unc(i32 %197, i32 %194, i32 %196)
  call void @cqrt_free(i32 %197)
  call void @cq_template_shl_i32_hl_unc(i32 %196, i32 %169, i32 6)
  call void @cqrt_free(i32 %196)
  call void @cq_template_select_i64_unc(i32 %195, i32 %171, i32 %190, i32 %170)
  call void @cqrt_free(i32 %195)
  call void @cq_template_select_i32_hl_unc(i32 %194, i32 %171, i32 %189, i32 0)
  call void @cqrt_free(i32 %194)
  br label %211

206:                                              ; preds = %210
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %171, i32 %170, i64 0)
  call void @cqrt_free(i32 %171)
  call void @cq_template_and_i64_hl_unc(i32 %170, i32 %167, i64 255)
  call void @cqrt_free(i32 %170)
  call void @cq_template_select_i32_unc(i32 %169, i32 %8, i32 %7, i32 %168)
  call void @cqrt_free(i32 %169)
  call void @cq_template_select_i32_unc(i32 %168, i32 %106, i32 %137, i32 %7)
  call void @cqrt_free(i32 %168)
  call void @cq_template_select_i64_unc(i32 %167, i32 %8, i32 %102, i32 %166)
  call void @cqrt_free(i32 %167)
  call void @cq_template_select_i64_unc(i32 %166, i32 %106, i32 %164, i32 %105)
  call void @cqrt_free(i32 %166)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %165, i32 %164, i64 0)
  call void @cqrt_free(i32 %165)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %164, i32 %162, i32 %4, i32 %161)
  call void @cqrt_free(i32 %164)
  call void @cqrt_and_i1(i32 %106, i32 %163, i32 %162)
  call void @cqrt_free(i32 %162)
  call void @cqrt_xor_i1(i32 %8, i32 %163)
  call void @cqrt_not_i1(i32 %163)
  call void @cqrt_free(i32 %163)
  call void @cq_template_add_i64_hl_unc(i32 %161, i32 %160, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %161)
  call void @cq_template_mul_i64_hl_unc(i32 %160, i32 %159, i64 8)
  call void @cqrt_free(i32 %160)
  call void @cq_template_zext_i32_to_i64_unc(i32 %159, i32 %158)
  call void @cqrt_free(i32 %159)
  call void @cq_template_add_i32_hl_unc(i32 %158, i32 %137, i32 1)
  call void @cqrt_free(i32 %158)
  br label %226

207:                                              ; preds = %225
  call void @cqrt_and_i1(i32 %110, i32 %117, i32 %118)
  call void @cqrt_free(i32 %118)
  call void @cqrt_xor_i1(i32 %113, i32 %117)
  call void @cqrt_not_i1(i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cq_template_select_i32_unc(i32 %116, i32 %115, i32 %114, i32 %112)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %110, i32 %113, i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cqrt_free(i32 %114)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %113, i32 %108, i64 4)
  call void @cqrt_free(i32 %113)
  call void @cqrt_free(i32 %112)
  call void @cqrt_and_i1(i32 %106, i32 %111, i32 %110)
  call void @cqrt_free(i32 %110)
  call void @cqrt_xor_i1(i32 %8, i32 %111)
  call void @cqrt_not_i1(i32 %111)
  call void @cqrt_free(i32 %111)
  call void @cq_template_zext_i32_to_i64_unc(i32 %108, i32 %107)
  call void @cqrt_free(i32 %108)
  call void @cq_template_and_i32_hl_unc(i32 %107, i32 %6, i32 3)
  call void @cqrt_free(i32 %107)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %106, i32 %105, i64 0)
  call void @cqrt_free(i32 %106)
  call void @cq_template_and_i64_unc(i32 %105, i32 %12, i32 %104)
  call void @cqrt_free(i32 %105)
  call void @cq_template_zext_i32_to_i64_unc(i32 %104, i32 %103)
  call void @cqrt_free(i32 %104)
  call void @cq_template_lshr_i32_hl_unc(i32 %103, i32 %6, i32 2)
  call void @cqrt_free(i32 %103)
  call void @cq_template_xor_i64_hl_unc(i32 %102, i32 %12, i64 -1)
  call void @cqrt_free(i32 %102)
  br label %285

208:                                              ; preds = %265
  call void @cqrt_and_i1(i32 %17, i32 %24, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cqrt_xor_i1(i32 %20, i32 %24)
  call void @cqrt_not_i1(i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_select_i64_unc(i32 %23, i32 %22, i32 %21, i32 %18)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %17, i32 %20, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %20, i32 %19, i64 5)
  call void @cqrt_free(i32 %20)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %15, i64 1)
  call void @cqrt_free(i32 %19)
  call void @cqrt_free(i32 %18)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %6, i32 3)
  call void @cqrt_free(i32 %14)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %13, i32 %12, i64 -1)
  call void @cqrt_free(i32 %13)
  call void @cqrt_qram_load_i64_unc(i32 %12, i32 %4, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %11)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %9, i64 8)
  call void @cqrt_free(i32 %10)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %7)
  call void @cqrt_free(i32 %9)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %5, i32 -1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 3)
  call void @cqrt_free(i32 %7)
  %209 = zext i32 %205 to i64
  ret i64 %209

210:                                              ; preds = %211
  call void @cqrt_free(i32 %178)
  call void @cqrt_free(i32 %177)
  call void @cqrt_and_i1(i32 %171, i32 %174, i32 %173)
  call void @cqrt_free(i32 %173)
  call void @cqrt_and_i1(i32 %165, i32 %175, i32 %174)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %174)
  call void @cqrt_not_i1(i32 %174)
  call void @cqrt_free(i32 %174)
  call void @cqrt_and_i1(i32 %106, i32 %176, i32 %175)
  call void @cqrt_free(i32 %175)
  call void @cqrt_xor_i1(i32 %8, i32 %176)
  call void @cqrt_not_i1(i32 %176)
  call void @cqrt_free(i32 %176)
  br label %206

211:                                              ; preds = %193, %211
  %212 = call i32 @cqrt_pop()
  %213 = call i32 @cqrt_pop()
  %214 = call i32 @cqrt_pop()
  %215 = call i32 @cqrt_pop()
  %216 = call i32 @cqrt_pop()
  %217 = call i32 @cqrt_pop()
  %218 = call i32 @cqrt_pop()
  %219 = call i32 @cqrt_pop()
  %220 = call i32 @cqrt_pop()
  %221 = call i32 @cqrt_pop()
  %222 = call i32 @cqrt_pop()
  %223 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %223, i32 %222, i32 %221)
  call void @cqrt_free(i32 %221)
  call void @cq_template_select_i64_unc(i32 %220, i32 %223, i32 %219, i32 %218)
  call void @cqrt_free(i32 %220)
  call void @cq_template_select_i32_lh_unc(i32 %217, i32 %223, i32 %216, i32 %215)
  call void @cqrt_free(i32 %217)
  call void @cq_template_select_i64_unc(i32 %214, i32 %223, i32 %213, i32 %212)
  call void @cqrt_free(i32 %214)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %222, i32 %219, i64 0)
  call void @cqrt_free(i32 %222)
  call void @cq_template_and_i64_hl_unc(i32 %219, i32 %213, i64 255)
  call void @cqrt_free(i32 %219)
  call void @cq_template_lshr_i64_hl_unc(i32 %213, i32 %212, i64 8)
  call void @cqrt_free(i32 %213)
  %224 = call i32 @cqrt_pop()
  switch i32 %224, label %211 [
    i32 1, label %210
  ]

225:                                              ; preds = %226
  br label %207

226:                                              ; preds = %206, %255
  %227 = call i32 @cqrt_pop()
  %228 = call i32 @cqrt_pop()
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  %233 = call i32 @cqrt_pop()
  %234 = call i32 @cqrt_pop()
  %235 = call i32 @cqrt_pop()
  %236 = call i32 @cqrt_pop()
  %237 = call i32 @cqrt_pop()
  %238 = call i32 @cqrt_pop()
  %239 = call i32 @cqrt_pop()
  %240 = call i32 @cqrt_pop()
  %241 = call i32 @cqrt_pop()
  %242 = call i32 @cqrt_pop()
  %243 = call i32 @cqrt_pop()
  %244 = call i32 @cqrt_pop()
  %245 = call i32 @cqrt_pop()
  %246 = call i32 @cqrt_pop()
  %247 = zext i32 %246 to i64
  %248 = shl i64 %247, 32
  %249 = or i64 0, %248
  %250 = call i32 @cqrt_pop()
  %251 = zext i32 %250 to i64
  %252 = or i64 %249, %251
  %253 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %253, i32 %108, i64 %252)
  call void @cqrt_free(i32 %253)
  call void @cqrt_and_i1(i32 %245, i32 %244, i32 %243)
  call void @cqrt_free(i32 %243)
  call void @cqrt_and_i1(i32 %242, i32 %241, i32 %244)
  call void @cqrt_free(i32 %244)
  call void @cqrt_xor_i1(i32 %240, i32 %241)
  call void @cqrt_not_i1(i32 %241)
  call void @cqrt_free(i32 %241)
  call void @cq_template_select_i32_unc(i32 %239, i32 %238, i32 %237, i32 %236)
  call void @cqrt_free(i32 %239)
  call void @cqrt_and_i1(i32 %245, i32 %235, i32 %238)
  call void @cqrt_free(i32 %238)
  call void @cqrt_and_i1(i32 %234, i32 %242, i32 %235)
  call void @cqrt_xor_i1(i32 %234, i32 %235)
  call void @cqrt_free(i32 %235)
  call void @cqrt_xor_i1(i32 %240, i32 %234)
  call void @cqrt_not_i1(i32 %234)
  call void @cqrt_free(i32 %234)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %237, i32 %233)
  call void @cqrt_free(i32 %237)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %242, i32 %232, i64 0)
  call void @cqrt_free(i32 %242)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %232, i32 %231, i32 %4, i32 %230)
  call void @cqrt_free(i32 %232)
  call void @cqrt_and_i1(i32 %245, i32 %229, i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cqrt_xor_i1(i32 %240, i32 %229)
  call void @cqrt_not_i1(i32 %229)
  call void @cqrt_free(i32 %229)
  call void @cq_template_add_i64_hl_unc(i32 %230, i32 %228, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %230)
  call void @cq_template_mul_i64_hl_unc(i32 %228, i32 %227, i64 8)
  call void @cqrt_free(i32 %228)
  call void @cq_template_add_i64_hl_unc(i32 %227, i32 %233, i64 1)
  call void @cqrt_free(i32 %227)
  %254 = call i32 @cqrt_pop()
  switch i32 %254, label %255 [
    i32 1, label %225
  ]

255:                                              ; preds = %226
  %256 = call i32 @cqrt_pop()
  %257 = call i32 @cqrt_pop()
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = call i32 @cqrt_pop()
  %263 = call i32 @cqrt_pop()
  %264 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %264, i32 %263, i32 %262)
  call void @cqrt_free(i32 %262)
  call void @cqrt_xor_i1(i32 %261, i32 %263)
  call void @cqrt_not_i1(i32 %263)
  call void @cqrt_free(i32 %263)
  call void @cq_template_select_i32_unc(i32 %260, i32 %259, i32 %258, i32 %257)
  call void @cqrt_free(i32 %260)
  call void @cqrt_and_i1(i32 %264, i32 %261, i32 %259)
  call void @cqrt_free(i32 %259)
  call void @cqrt_free(i32 %258)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %261, i32 %256, i64 4)
  call void @cqrt_free(i32 %261)
  br label %226

265:                                              ; preds = %266
  br label %208

266:                                              ; preds = %335
  %267 = call i32 @cqrt_pop()
  %268 = call i32 @cqrt_pop()
  %269 = call i32 @cqrt_pop()
  %270 = call i32 @cqrt_pop()
  %271 = call i32 @cqrt_pop()
  %272 = call i32 @cqrt_pop()
  %273 = call i32 @cqrt_pop()
  %274 = call i32 @cqrt_pop()
  %275 = call i32 @cqrt_pop()
  %276 = call i32 @cqrt_pop()
  %277 = call i32 @cqrt_pop()
  %278 = call i32 @cqrt_pop()
  %279 = call i32 @cqrt_pop()
  %280 = call i32 @cqrt_pop()
  %281 = call i32 @cqrt_pop()
  %282 = call i32 @cqrt_pop()
  %283 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %283, i32 %282, i32 %281)
  call void @cqrt_free(i32 %281)
  call void @cqrt_and_i1(i32 %280, i32 %279, i32 %282)
  call void @cqrt_xor_i1(i32 %280, i32 %282)
  call void @cqrt_free(i32 %282)
  call void @cqrt_and_i1(i32 %278, i32 %277, i32 %280)
  call void @cqrt_free(i32 %280)
  call void @cqrt_xor_i1(i32 %276, i32 %277)
  call void @cqrt_not_i1(i32 %277)
  call void @cqrt_free(i32 %277)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %278, i32 %275, i64 0)
  call void @cqrt_free(i32 %278)
  call void @cq_template_and_i64_hl_unc(i32 %275, i32 %274, i64 255)
  call void @cqrt_free(i32 %275)
  call void @cq_template_xor_i64_hl_unc(i32 %274, i32 %273, i64 -1)
  call void @cqrt_free(i32 %274)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %272, i32 %271)
  call void @cqrt_free(i32 %272)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %279, i32 %273, i64 -1)
  call void @cqrt_free(i32 %279)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %273, i32 %270, i32 %4, i32 %269)
  call void @cqrt_free(i32 %273)
  call void @cqrt_and_i1(i32 %283, i32 %268, i32 %270)
  call void @cqrt_free(i32 %270)
  call void @cqrt_xor_i1(i32 %276, i32 %268)
  call void @cqrt_not_i1(i32 %268)
  call void @cqrt_free(i32 %268)
  call void @cq_template_add_i64_hl_unc(i32 %269, i32 %267, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %269)
  call void @cq_template_mul_i64_hl_unc(i32 %267, i32 %271, i64 8)
  call void @cqrt_free(i32 %267)
  %284 = call i32 @cqrt_pop()
  switch i32 %284, label %324 [
    i32 1, label %265
  ]

285:                                              ; preds = %207, %324
  %286 = call i32 @cqrt_pop()
  %287 = call i32 @cqrt_pop()
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = call i32 @cqrt_pop()
  %291 = call i32 @cqrt_pop()
  %292 = call i32 @cqrt_pop()
  %293 = call i32 @cqrt_pop()
  %294 = call i32 @cqrt_pop()
  %295 = call i32 @cqrt_pop()
  %296 = zext i32 %295 to i64
  %297 = shl i64 %296, 32
  %298 = or i64 0, %297
  %299 = call i32 @cqrt_pop()
  %300 = zext i32 %299 to i64
  %301 = or i64 %298, %300
  %302 = call i32 @cqrt_pop()
  %303 = call i32 @cqrt_pop()
  %304 = call i32 @cqrt_pop()
  %305 = call i32 @cqrt_pop()
  %306 = call i32 @cqrt_pop()
  %307 = call i32 @cqrt_pop()
  %308 = call i32 @cqrt_pop()
  %309 = call i32 @cqrt_pop()
  %310 = call i32 @cqrt_pop()
  %311 = call i32 @cqrt_pop()
  %312 = call i32 @cqrt_pop()
  %313 = call i32 @cqrt_pop()
  %314 = call i32 @cqrt_pop()
  %315 = call i32 @cqrt_pop()
  %316 = call i32 @cqrt_pop()
  %317 = call i32 @cqrt_pop()
  %318 = call i32 @cqrt_pop()
  %319 = call i32 @cqrt_pop()
  %320 = call i32 @cqrt_pop()
  %321 = call i32 @cqrt_pop()
  %322 = call i32 @cqrt_pop()
  %323 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %323, i32 %322, i32 %321, i32 %320)
  call void @cqrt_free(i32 %323)
  call void @cq_template_add_i64_unc(i32 %321, i32 %319, i32 %318)
  call void @cqrt_free(i32 %321)
  call void @cq_template_select_i64_unc(i32 %319, i32 %317, i32 %316, i32 %315)
  call void @cqrt_free(i32 %319)
  call void @cq_template_zext_i32_to_i64_unc(i32 %318, i32 %314)
  call void @cqrt_free(i32 %318)
  call void @cq_template_add_i32_unc(i32 %314, i32 %313, i32 %312)
  call void @cqrt_free(i32 %314)
  call void @cq_template_select_i32_hl_unc(i32 %313, i32 %317, i32 %311, i32 0)
  call void @cqrt_free(i32 %313)
  br label %336

324:                                              ; preds = %266
  %325 = call i32 @cqrt_pop()
  %326 = call i32 @cqrt_pop()
  %327 = call i32 @cqrt_pop()
  %328 = call i32 @cqrt_pop()
  %329 = call i32 @cqrt_pop()
  %330 = call i32 @cqrt_pop()
  %331 = call i32 @cqrt_pop()
  %332 = call i32 @cqrt_pop()
  %333 = call i32 @cqrt_pop()
  %334 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %334, i32 %333, i32 %332)
  call void @cqrt_free(i32 %332)
  call void @cqrt_xor_i1(i32 %331, i32 %333)
  call void @cqrt_not_i1(i32 %333)
  call void @cqrt_free(i32 %333)
  call void @cq_template_select_i64_unc(i32 %330, i32 %329, i32 %328, i32 %327)
  call void @cqrt_free(i32 %330)
  call void @cqrt_and_i1(i32 %334, i32 %331, i32 %329)
  call void @cqrt_free(i32 %329)
  call void @cqrt_free(i32 %328)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %331, i32 %326, i64 5)
  call void @cqrt_free(i32 %331)
  call void @cq_template_add_i64_hl_unc(i32 %326, i32 %325, i64 1)
  call void @cqrt_free(i32 %326)
  br label %285

335:                                              ; preds = %336
  call void @cqrt_free(i32 %310)
  call void @cqrt_free(i32 %309)
  call void @cqrt_and_i1(i32 %308, i32 %307, i32 %306)
  call void @cqrt_free(i32 %306)
  call void @cqrt_and_i1(i32 %317, i32 %305, i32 %307)
  call void @cqrt_free(i32 %307)
  call void @cqrt_and_i1(i32 %304, i32 %303, i32 %305)
  call void @cqrt_xor_i1(i32 %304, i32 %305)
  call void @cqrt_free(i32 %305)
  call void @cqrt_and_i1(i32 %13, i32 %8, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cq_template_add_i64_hl_unc(i32 %302, i32 %15, i64 %301)
  call void @cqrt_free(i32 %302)
  call void @cqrt_and_i1(i32 %294, i32 %293, i32 %292)
  call void @cqrt_free(i32 %292)
  call void @cqrt_and_i1(i32 %291, i32 %290, i32 %293)
  call void @cqrt_free(i32 %293)
  call void @cqrt_xor_i1(i32 %303, i32 %290)
  call void @cqrt_not_i1(i32 %290)
  call void @cqrt_free(i32 %290)
  call void @cqrt_and_i1(i32 %294, i32 %289, i32 %322)
  call void @cqrt_free(i32 %322)
  call void @cqrt_and_i1(i32 %288, i32 %291, i32 %289)
  call void @cqrt_xor_i1(i32 %288, i32 %289)
  call void @cqrt_free(i32 %289)
  call void @cqrt_xor_i1(i32 %303, i32 %288)
  call void @cqrt_not_i1(i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cq_template_shl_i32_hl_unc(i32 %312, i32 %287, i32 6)
  call void @cqrt_free(i32 %312)
  call void @cqrt_free(i32 %286)
  br label %266

336:                                              ; preds = %285, %336
  %337 = call i32 @cqrt_pop()
  %338 = call i32 @cqrt_pop()
  %339 = call i32 @cqrt_pop()
  %340 = call i32 @cqrt_pop()
  %341 = call i32 @cqrt_pop()
  %342 = call i32 @cqrt_pop()
  %343 = call i32 @cqrt_pop()
  %344 = call i32 @cqrt_pop()
  %345 = call i32 @cqrt_pop()
  %346 = call i32 @cqrt_pop()
  %347 = call i32 @cqrt_pop()
  %348 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %348, i32 %347, i32 %346)
  call void @cqrt_free(i32 %346)
  call void @cq_template_select_i64_unc(i32 %345, i32 %348, i32 %344, i32 %343)
  call void @cqrt_free(i32 %345)
  call void @cq_template_select_i32_lh_unc(i32 %342, i32 %348, i32 %341, i32 %340)
  call void @cqrt_free(i32 %342)
  call void @cq_template_select_i64_unc(i32 %339, i32 %348, i32 %338, i32 %337)
  call void @cqrt_free(i32 %339)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %347, i32 %344, i64 0)
  call void @cqrt_free(i32 %347)
  call void @cq_template_and_i64_hl_unc(i32 %344, i32 %338, i64 255)
  call void @cqrt_free(i32 %344)
  call void @cq_template_lshr_i64_hl_unc(i32 %338, i32 %337, i64 8)
  call void @cqrt_free(i32 %338)
  %349 = call i32 @cqrt_pop()
  switch i32 %349, label %336 [
    i32 1, label %335
  ]
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i64(i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_alloc_i64(i64)

declare i32 @cq_template_select_i64(i32, i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cq_template_xor_i64_hl(i32, i64)

declare i32 @cq_template_and_i64_hl(i32, i64)

declare i32 @cq_template_lshr_i64_hl(i32, i64)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i64(i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_select_i64_lh(i32, i64, i32)

declare void @cqrt_free(i32)

declare void @cq_template_select_i64_unc(i32, i32, i32, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_and_i64_hl_unc(i32, i32, i64)

declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i64_unc(i32, i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_unc(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

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
  %9 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 -1)
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %12 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 ptrtoint (ptr @limbs to i64))
  %14 = call i32 @cqrt_qram_load_i64(i32 %6, i32 %13)
  %15 = call i32 @cq_template_icmp_eq_i64_hl(i32 %14, i64 -1)
  %16 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  br label %18

18:                                               ; preds = %4
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %19)
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  %21 = call i32 @cq_template_add_i64_hl(i32 %17, i64 1)
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %21, i64 5)
  %23 = call i32 @cqrt_alloc_i64(i64 320)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %22, i32 %24)
  %25 = call i32 @cq_template_select_i64(i32 %24, i32 %23, i32 %20)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_xor_i1(i32 %22, i32 %26)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %26, i32 %27)
  %28 = call i32 @llvm.umin.i32(i32 %3, i32 5)
  %29 = icmp ult i32 %3, 5
  %30 = icmp ult i32 0, %28
  br i1 %30, label %31, label %59

31:                                               ; preds = %104, %18
  %from11 = phi i32 [ 0, %104 ], [ 1, %18 ]
  %32 = phi i32 [ 0, %18 ], [ %99, %104 ]
  %33 = phi i32 [ %27, %18 ], [ %111, %104 ]
  %34 = phi i32 [ %17, %18 ], [ %98, %104 ]
  %35 = phi i64 [ 0, %18 ], [ %97, %104 ]
  %36 = phi i32 [ %21, %18 ], [ %105, %104 ]
  %37 = phi i32 [ %22, %18 ], [ %106, %104 ]
  %38 = phi i32 [ %25, %18 ], [ %109, %104 ]
  call void @cqrt_push(i32 %from11)
  %39 = call i32 @cq_template_mul_i64_hl(i32 %36, i64 8)
  %40 = call i32 @cq_template_add_i64_hl(i32 %39, i64 ptrtoint (ptr @limbs to i64))
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %41)
  call void @cqrt_xor_i1(i32 %37, i32 %41)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %41, i32 %42)
  %43 = call i32 @cqrt_qram_load_i64_controlled(i32 %42, i32 %6, i32 %40)
  %44 = call i32 @cq_template_icmp_eq_i64_hl(i32 %43, i64 -1)
  %45 = call i32 @cq_template_trunc_i64_to_i32(i32 %36)
  %46 = call i32 @cq_template_xor_i64_hl(i32 %43, i64 -1)
  %47 = call i32 @cq_template_and_i64_hl(i32 %46, i64 255)
  %48 = call i32 @cq_template_icmp_eq_i64_hl(i32 %47, i64 0)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %51)
  call void @cqrt_xor_i1(i32 %37, i32 %51)
  call void @cqrt_and_i1(i32 %48, i32 %51, i32 %50)
  call void @cqrt_xor_i1(i32 %50, i32 %49)
  call void @cqrt_and_i1(i32 %50, i32 %44, i32 %49)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %49, i32 %52)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %55)
  call void @cqrt_xor_i1(i32 %55, i32 %54)
  call void @cqrt_and_i1(i32 %55, i32 %37, i32 %54)
  call void @cqrt_and_i1(i32 %48, i32 %54, i32 %53)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %52, i32 %53, i32 %56)
  %57 = call i32 @cqrt_alloc_i32(i32 0)
  %58 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %39)
  br label %68

59:                                               ; preds = %82, %18
  %60 = phi i32 [ 0, %18 ], [ 1, %82 ]
  %61 = phi i32 [ %17, %18 ], [ %98, %82 ]
  %62 = phi i64 [ 0, %18 ], [ %97, %82 ]
  %63 = phi i32 [ %21, %18 ], [ %36, %82 ]
  %64 = phi i32 [ %22, %18 ], [ %37, %82 ]
  %65 = phi i32 [ %25, %18 ], [ %93, %82 ]
  %66 = phi i32 [ %27, %18 ], [ %96, %82 ]
  br i1 %29, label %112, label %114

67:                                               ; preds = %68
  br label %81

68:                                               ; preds = %68, %31
  %from10 = phi i32 [ 0, %68 ], [ 1, %31 ]
  %69 = phi i32 [ 0, %31 ], [ %72, %68 ]
  %70 = phi i32 [ %46, %31 ], [ %76, %68 ]
  %trip = phi i32 [ %56, %31 ], [ %80, %68 ]
  %cap = phi i32 [ %57, %31 ], [ %77, %68 ]
  %cap1 = phi i32 [ %58, %31 ], [ %78, %68 ]
  call void @cqrt_push(i32 %from10)
  %71 = call i32 @cq_template_lshr_i64_hl(i32 %70, i64 8)
  %72 = add nuw nsw i32 %69, 8
  %73 = call i32 @cq_template_and_i64_hl(i32 %71, i64 255)
  %74 = call i32 @cq_template_icmp_eq_i64_hl(i32 %73, i64 0)
  %75 = icmp ult i32 %69, 48
  %76 = call i32 @cq_template_select_i64(i32 %trip, i32 %71, i32 %70)
  %77 = call i32 @cq_template_select_i32_lh(i32 %trip, i32 %72, i32 %cap)
  %78 = call i32 @cq_template_select_i64(i32 %trip, i32 %73, i32 %cap1)
  %79 = xor i1 %75, true
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %74, i32 %80)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %cap1)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %cap)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %70)
  br i1 %79, label %67, label %68

81:                                               ; preds = %67
  br label %82

82:                                               ; preds = %81
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  %84 = call i32 @cq_template_select_i32_hl(i32 %48, i32 %77, i32 0)
  %85 = call i32 @cq_template_select_i64(i32 %48, i32 %78, i32 %47)
  %86 = call i32 @cq_template_shl_i32_hl(i32 %45, i32 6)
  %87 = call i32 @cq_template_add_i32(i32 %84, i32 %86)
  %88 = call i32 @cq_template_zext_i32_to_i64(i32 %87)
  %89 = call i32 @cq_template_add_i64(i32 %85, i32 %88)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %91)
  call void @cqrt_xor_i1(i32 %37, i32 %91)
  call void @cqrt_xor_i1(i32 %91, i32 %90)
  call void @cqrt_and_i1(i32 %91, i32 %44, i32 %90)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %90, i32 %92)
  %93 = call i32 @cq_template_select_i64(i32 %92, i32 %89, i32 %38)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %95)
  call void @cqrt_xor_i1(i32 %37, i32 %95)
  call void @cqrt_and_i1(i32 %44, i32 %95, i32 %94)
  %96 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %94, i32 %96)
  %97 = add i64 %35, 1
  %98 = call i32 @cq_template_add_i64_hl(i32 %17, i64 %97)
  %99 = add i32 %32, 1
  %100 = icmp ult i32 %99, %28
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %98)
  %101 = trunc i64 %97 to i32
  call void @cqrt_push(i32 %101)
  %102 = lshr i64 %97, 32
  %103 = trunc i64 %102 to i32
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %83)
  br i1 %100, label %104, label %59

104:                                              ; preds = %82
  %105 = call i32 @cq_template_add_i64_hl(i32 %98, i64 1)
  %106 = call i32 @cq_template_icmp_eq_i64_hl(i32 %105, i64 5)
  %107 = call i32 @cqrt_alloc_i64(i64 320)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %96, i32 %106, i32 %108)
  %109 = call i32 @cq_template_select_i64(i32 %108, i32 %107, i32 %93)
  %110 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %110)
  call void @cqrt_xor_i1(i32 %106, i32 %110)
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %96, i32 %110, i32 %111)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %111)
  call void @cqrt_push(i32 %106)
  call void @cqrt_push(i32 %109)
  call void @cqrt_push(i32 %108)
  call void @cqrt_push(i32 %107)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %105)
  call void @cqrt_push(i32 %98)
  br label %31

112:                                              ; preds = %59
  %113 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %66, i32 %113)
  br label %115

114:                                              ; preds = %59
  br label %115

115:                                              ; preds = %112, %114
  %116 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %65, i32 %116)
  br label %117

117:                                              ; preds = %115
  %118 = call i32 @cq_template_xor_i64_hl(i32 %14, i64 -1)
  %119 = call i32 @cq_template_lshr_i32_hl(i32 %8, i32 2)
  %120 = call i32 @cq_template_zext_i32_to_i64(i32 %119)
  %121 = call i32 @cq_template_and_i64(i32 %14, i32 %120)
  %122 = call i32 @cq_template_icmp_eq_i64_hl(i32 %121, i64 0)
  %123 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)
  %124 = call i32 @cq_template_zext_i32_to_i64(i32 %123)
  br label %125

125:                                              ; preds = %117
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %127)
  call void @cqrt_xor_i1(i32 %10, i32 %127)
  call void @cqrt_and_i1(i32 %122, i32 %127, i32 %126)
  %128 = call i32 @cqrt_alloc_i32(i32 0)
  %129 = call i32 @cq_template_icmp_eq_i64_hl(i32 %124, i64 4)
  %130 = call i32 @cqrt_alloc_i32(i32 4)
  %131 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %126, i32 %129, i32 %131)
  %132 = call i32 @cq_template_select_i32(i32 %131, i32 %130, i32 %128)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %133)
  call void @cqrt_xor_i1(i32 %129, i32 %133)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %126, i32 %133, i32 %134)
  %135 = call i32 @llvm.umin.i32(i32 %3, i32 5)
  %136 = icmp ult i32 %3, 5
  %137 = icmp ult i32 0, %135
  br i1 %137, label %138, label %167

138:                                              ; preds = %174, %125
  %from5 = phi i32 [ 0, %174 ], [ 1, %125 ]
  %139 = phi i32 [ 0, %125 ], [ %162, %174 ]
  %140 = phi i32 [ %134, %125 ], [ %180, %174 ]
  %141 = phi i32 [ %124, %125 ], [ %161, %174 ]
  %142 = phi i64 [ 0, %125 ], [ %160, %174 ]
  %143 = phi i32 [ %129, %125 ], [ %175, %174 ]
  %144 = phi i32 [ %132, %125 ], [ %178, %174 ]
  call void @cqrt_push(i32 %from5)
  %145 = call i32 @cq_template_add_i64_hl(i32 %141, i64 1)
  %146 = call i32 @cq_template_mul_i64_hl(i32 %145, i64 8)
  %147 = call i32 @cq_template_add_i64_hl(i32 %146, i64 ptrtoint (ptr @limbs to i64))
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %148)
  call void @cqrt_xor_i1(i32 %143, i32 %148)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %148, i32 %149)
  %150 = call i32 @cqrt_qram_load_i64_controlled(i32 %149, i32 %6, i32 %147)
  %151 = call i32 @cq_template_icmp_eq_i64_hl(i32 %150, i64 0)
  %152 = call i32 @cq_template_trunc_i64_to_i32(i32 %141)
  %153 = call i32 @cqrt_alloc_i1(i1 false)
  %154 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %154)
  call void @cqrt_xor_i1(i32 %143, i32 %154)
  call void @cqrt_xor_i1(i32 %154, i32 %153)
  call void @cqrt_and_i1(i32 %154, i32 %151, i32 %153)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %153, i32 %155)
  %156 = call i32 @cq_template_select_i32(i32 %155, i32 %152, i32 %144)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %158)
  call void @cqrt_xor_i1(i32 %143, i32 %158)
  call void @cqrt_and_i1(i32 %151, i32 %158, i32 %157)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %140, i32 %157, i32 %159)
  %160 = add i64 %142, 1
  %161 = call i32 @cq_template_add_i64_hl(i32 %124, i64 %160)
  %162 = add i32 %139, 1
  %163 = icmp ult i32 %162, %135
  call void @cqrt_push(i32 %161)
  %164 = trunc i64 %160 to i32
  call void @cqrt_push(i32 %164)
  %165 = lshr i64 %160, 32
  %166 = trunc i64 %165 to i32
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %157)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %158)
  call void @cqrt_push(i32 %143)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %155)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %144)
  call void @cqrt_push(i32 %153)
  call void @cqrt_push(i32 %154)
  call void @cqrt_push(i32 %141)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %146)
  call void @cqrt_push(i32 %145)
  br i1 %163, label %174, label %167

167:                                              ; preds = %138, %125
  %168 = phi i32 [ 0, %125 ], [ 1, %138 ]
  %169 = phi i32 [ %124, %125 ], [ %161, %138 ]
  %170 = phi i64 [ 0, %125 ], [ %160, %138 ]
  %171 = phi i32 [ %129, %125 ], [ %143, %138 ]
  %172 = phi i32 [ %132, %125 ], [ %156, %138 ]
  %173 = phi i32 [ %134, %125 ], [ %159, %138 ]
  br i1 %136, label %181, label %183

174:                                              ; preds = %138
  %175 = call i32 @cq_template_icmp_eq_i64_hl(i32 %161, i64 4)
  %176 = call i32 @cqrt_alloc_i32(i32 4)
  %177 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %159, i32 %175, i32 %177)
  %178 = call i32 @cq_template_select_i32(i32 %177, i32 %176, i32 %156)
  %179 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %179)
  call void @cqrt_xor_i1(i32 %175, i32 %179)
  %180 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %159, i32 %179, i32 %180)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %179)
  call void @cqrt_push(i32 %180)
  call void @cqrt_push(i32 %175)
  call void @cqrt_push(i32 %178)
  call void @cqrt_push(i32 %177)
  call void @cqrt_push(i32 %176)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %161)
  br label %138

181:                                              ; preds = %167
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %173, i32 %182)
  br label %184

183:                                              ; preds = %167
  br label %184

184:                                              ; preds = %181, %183
  %185 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %172, i32 %185)
  br label %186

186:                                              ; preds = %184
  %187 = call i32 @cq_template_add_i32_hl(i32 %185, i32 1)
  %188 = call i32 @cq_template_zext_i32_to_i64(i32 %187)
  %189 = call i32 @cq_template_mul_i64_hl(i32 %188, i64 8)
  %190 = call i32 @cq_template_add_i64_hl(i32 %189, i64 ptrtoint (ptr @limbs to i64))
  %191 = call i32 @cqrt_alloc_i1(i1 false)
  %192 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %192)
  call void @cqrt_xor_i1(i32 %10, i32 %192)
  call void @cqrt_and_i1(i32 %122, i32 %192, i32 %191)
  %193 = call i32 @cqrt_qram_load_i64_controlled(i32 %191, i32 %6, i32 %190)
  %194 = call i32 @cq_template_icmp_eq_i64_hl(i32 %193, i64 0)
  %195 = call i32 @cq_template_select_i64(i32 %122, i32 %193, i32 %121)
  %196 = call i32 @cq_template_select_i64(i32 %10, i32 %118, i32 %195)
  %197 = call i32 @cq_template_select_i32(i32 %122, i32 %185, i32 %9)
  %198 = call i32 @cq_template_select_i32(i32 %10, i32 %9, i32 %197)
  %199 = call i32 @cq_template_and_i64_hl(i32 %196, i64 255)
  %200 = call i32 @cq_template_icmp_eq_i64_hl(i32 %199, i64 0)
  br label %201

201:                                              ; preds = %186
  %202 = call i32 @cqrt_alloc_i1(i1 false)
  %203 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %203)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %203)
  %204 = call i32 @cqrt_alloc_i1(i1 false)
  %205 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %205)
  call void @cqrt_xor_i1(i32 %10, i32 %205)
  call void @cqrt_and_i1(i32 %122, i32 %205, i32 %204)
  call void @cqrt_and_i1(i32 %194, i32 %204, i32 %203)
  call void @cqrt_and_i1(i32 %200, i32 %203, i32 %202)
  %206 = call i32 @cqrt_alloc_i32(i32 0)
  %207 = call i32 @cqrt_alloc_i64(i64 0)
  br label %209

208:                                              ; preds = %209
  br label %222

209:                                              ; preds = %209, %201
  %from = phi i32 [ 0, %209 ], [ 1, %201 ]
  %210 = phi i32 [ 0, %201 ], [ %213, %209 ]
  %211 = phi i32 [ %196, %201 ], [ %217, %209 ]
  %trip2 = phi i32 [ %202, %201 ], [ %221, %209 ]
  %cap3 = phi i32 [ %206, %201 ], [ %218, %209 ]
  %cap4 = phi i32 [ %207, %201 ], [ %219, %209 ]
  call void @cqrt_push(i32 %from)
  %212 = call i32 @cq_template_lshr_i64_hl(i32 %211, i64 8)
  %213 = add nuw nsw i32 %210, 8
  %214 = call i32 @cq_template_and_i64_hl(i32 %212, i64 255)
  %215 = call i32 @cq_template_icmp_eq_i64_hl(i32 %214, i64 0)
  %216 = icmp ult i32 %210, 48
  %217 = call i32 @cq_template_select_i64(i32 %trip2, i32 %212, i32 %211)
  %218 = call i32 @cq_template_select_i32_lh(i32 %trip2, i32 %213, i32 %cap3)
  %219 = call i32 @cq_template_select_i64(i32 %trip2, i32 %214, i32 %cap4)
  %220 = xor i1 %216, true
  %221 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip2, i32 %215, i32 %221)
  call void @cqrt_push(i32 %trip2)
  call void @cqrt_push(i32 %215)
  call void @cqrt_push(i32 %221)
  call void @cqrt_push(i32 %219)
  call void @cqrt_push(i32 %214)
  call void @cqrt_push(i32 %cap4)
  call void @cqrt_push(i32 %218)
  call void @cqrt_push(i32 %213)
  call void @cqrt_push(i32 %cap3)
  call void @cqrt_push(i32 %217)
  call void @cqrt_push(i32 %212)
  call void @cqrt_push(i32 %211)
  br i1 %220, label %208, label %209

222:                                              ; preds = %208
  %223 = call i32 @cq_template_select_i32_hl(i32 %200, i32 %218, i32 0)
  %224 = call i32 @cq_template_select_i64(i32 %200, i32 %219, i32 %199)
  %225 = call i32 @cq_template_shl_i32_hl(i32 %198, i32 6)
  %226 = call i32 @cq_template_add_i32(i32 %223, i32 %225)
  %227 = call i32 @cq_template_zext_i32_to_i64(i32 %226)
  %228 = call i32 @cq_template_add_i64(i32 %224, i32 %227)
  %229 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %229)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %229)
  %230 = call i32 @cq_template_select_i64(i32 %229, i32 %228, i32 %116)
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  %232 = call i32 @cqrt_alloc_i1(i1 false)
  %233 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %233)
  call void @cqrt_xor_i1(i32 %10, i32 %233)
  call void @cqrt_and_i1(i32 %122, i32 %233, i32 %232)
  call void @cqrt_and_i1(i32 %194, i32 %232, i32 %231)
  %234 = call i32 @cq_template_select_i64_lh(i32 %231, i64 -1, i32 %230)
  call void @cqrt_push(i32 %7)
  call void @cqrt_push(i32 %8)
  %235 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %234, i32 %235)
  call void @cq_template_select_i64_lh_unc(i32 %234, i32 %231, i64 -1, i32 %230)
  call void @cqrt_free(i32 %234)
  call void @cqrt_and_i1(i32 %194, i32 %232, i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cqrt_and_i1(i32 %122, i32 %233, i32 %232)
  call void @cqrt_free(i32 %232)
  call void @cqrt_xor_i1(i32 %10, i32 %233)
  call void @cqrt_not_i1(i32 %233)
  call void @cqrt_free(i32 %233)
  call void @cq_template_select_i64_unc(i32 %230, i32 %229, i32 %228, i32 %116)
  call void @cqrt_free(i32 %230)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %229)
  call void @cqrt_not_i1(i32 %229)
  call void @cqrt_free(i32 %229)
  call void @cq_template_add_i64_unc(i32 %228, i32 %224, i32 %227)
  call void @cqrt_free(i32 %228)
  call void @cq_template_zext_i32_to_i64_unc(i32 %227, i32 %226)
  call void @cqrt_free(i32 %227)
  call void @cq_template_add_i32_unc(i32 %226, i32 %223, i32 %225)
  call void @cqrt_free(i32 %226)
  call void @cq_template_shl_i32_hl_unc(i32 %225, i32 %198, i32 6)
  call void @cqrt_free(i32 %225)
  call void @cq_template_select_i64_unc(i32 %224, i32 %200, i32 %219, i32 %199)
  call void @cqrt_free(i32 %224)
  call void @cq_template_select_i32_hl_unc(i32 %223, i32 %200, i32 %218, i32 0)
  call void @cqrt_free(i32 %223)
  br label %240

236:                                              ; preds = %239
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %200, i32 %199, i64 0)
  call void @cqrt_free(i32 %200)
  call void @cq_template_and_i64_hl_unc(i32 %199, i32 %196, i64 255)
  call void @cqrt_free(i32 %199)
  call void @cq_template_select_i32_unc(i32 %198, i32 %10, i32 %9, i32 %197)
  call void @cqrt_free(i32 %198)
  call void @cq_template_select_i32_unc(i32 %197, i32 %122, i32 %185, i32 %9)
  call void @cqrt_free(i32 %197)
  call void @cq_template_select_i64_unc(i32 %196, i32 %10, i32 %118, i32 %195)
  call void @cqrt_free(i32 %196)
  call void @cq_template_select_i64_unc(i32 %195, i32 %122, i32 %193, i32 %121)
  call void @cqrt_free(i32 %195)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %194, i32 %193, i64 0)
  call void @cqrt_free(i32 %194)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %193, i32 %191, i32 %6, i32 %190)
  call void @cqrt_free(i32 %193)
  call void @cqrt_and_i1(i32 %122, i32 %192, i32 %191)
  call void @cqrt_free(i32 %191)
  call void @cqrt_xor_i1(i32 %10, i32 %192)
  call void @cqrt_not_i1(i32 %192)
  call void @cqrt_free(i32 %192)
  call void @cq_template_add_i64_hl_unc(i32 %190, i32 %189, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %190)
  call void @cq_template_mul_i64_hl_unc(i32 %189, i32 %188, i64 8)
  call void @cqrt_free(i32 %189)
  call void @cq_template_zext_i32_to_i64_unc(i32 %188, i32 %187)
  call void @cqrt_free(i32 %188)
  call void @cq_template_add_i32_hl_unc(i32 %187, i32 %185, i32 1)
  call void @cqrt_free(i32 %187)
  br label %294

237:                                              ; preds = %254
  call void @cqrt_and_i1(i32 %126, i32 %133, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_xor_i1(i32 %129, i32 %133)
  call void @cqrt_not_i1(i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cq_template_select_i32_unc(i32 %132, i32 %131, i32 %130, i32 %128)
  call void @cqrt_free(i32 %132)
  call void @cqrt_and_i1(i32 %126, i32 %129, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cqrt_free(i32 %130)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %129, i32 %124, i64 4)
  call void @cqrt_free(i32 %129)
  call void @cqrt_free(i32 %128)
  call void @cqrt_and_i1(i32 %122, i32 %127, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cqrt_xor_i1(i32 %10, i32 %127)
  call void @cqrt_not_i1(i32 %127)
  call void @cqrt_free(i32 %127)
  call void @cq_template_zext_i32_to_i64_unc(i32 %124, i32 %123)
  call void @cqrt_free(i32 %124)
  call void @cq_template_and_i32_hl_unc(i32 %123, i32 %8, i32 3)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %122, i32 %121, i64 0)
  call void @cqrt_free(i32 %122)
  call void @cq_template_and_i64_unc(i32 %121, i32 %14, i32 %120)
  call void @cqrt_free(i32 %121)
  call void @cq_template_zext_i32_to_i64_unc(i32 %120, i32 %119)
  call void @cqrt_free(i32 %120)
  call void @cq_template_lshr_i32_hl_unc(i32 %119, i32 %8, i32 2)
  call void @cqrt_free(i32 %119)
  call void @cq_template_xor_i64_hl_unc(i32 %118, i32 %14, i64 -1)
  call void @cqrt_free(i32 %118)
  br label %366

238:                                              ; preds = %296
  call void @cqrt_and_i1(i32 %19, i32 %26, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_xor_i1(i32 %22, i32 %26)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_select_i64_unc(i32 %25, i32 %24, i32 %23, i32 %20)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %19, i32 %22, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %22, i32 %21, i64 5)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %17, i64 1)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %20)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %8, i32 3)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %15, i32 %14, i64 -1)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i64_unc(i32 %14, i32 %6, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %11, i64 8)
  call void @cqrt_free(i32 %12)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %9)
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %7, i32 -1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %8, i32 3)
  call void @cqrt_free(i32 %9)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %235

239:                                              ; preds = %240
  call void @cqrt_free(i32 %207)
  call void @cqrt_free(i32 %206)
  call void @cqrt_and_i1(i32 %200, i32 %203, i32 %202)
  call void @cqrt_free(i32 %202)
  call void @cqrt_and_i1(i32 %194, i32 %204, i32 %203)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %203)
  call void @cqrt_not_i1(i32 %203)
  call void @cqrt_free(i32 %203)
  call void @cqrt_and_i1(i32 %122, i32 %205, i32 %204)
  call void @cqrt_free(i32 %204)
  call void @cqrt_xor_i1(i32 %10, i32 %205)
  call void @cqrt_not_i1(i32 %205)
  call void @cqrt_free(i32 %205)
  br label %236

240:                                              ; preds = %222, %240
  %241 = call i32 @cqrt_pop()
  %242 = call i32 @cqrt_pop()
  %243 = call i32 @cqrt_pop()
  %244 = call i32 @cqrt_pop()
  %245 = call i32 @cqrt_pop()
  %246 = call i32 @cqrt_pop()
  %247 = call i32 @cqrt_pop()
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = call i32 @cqrt_pop()
  %251 = call i32 @cqrt_pop()
  %252 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %252, i32 %251, i32 %250)
  call void @cqrt_free(i32 %250)
  call void @cq_template_select_i64_unc(i32 %249, i32 %252, i32 %248, i32 %247)
  call void @cqrt_free(i32 %249)
  call void @cq_template_select_i32_lh_unc(i32 %246, i32 %252, i32 %245, i32 %244)
  call void @cqrt_free(i32 %246)
  call void @cq_template_select_i64_unc(i32 %243, i32 %252, i32 %242, i32 %241)
  call void @cqrt_free(i32 %243)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %251, i32 %248, i64 0)
  call void @cqrt_free(i32 %251)
  call void @cq_template_and_i64_hl_unc(i32 %248, i32 %242, i64 255)
  call void @cqrt_free(i32 %248)
  call void @cq_template_lshr_i64_hl_unc(i32 %242, i32 %241, i64 8)
  call void @cqrt_free(i32 %242)
  %253 = call i32 @cqrt_pop()
  switch i32 %253, label %240 [
    i32 1, label %239
  ]

254:                                              ; preds = %295, %255
  br label %237

255:                                              ; preds = %295, %284
  %256 = call i32 @cqrt_pop()
  %257 = call i32 @cqrt_pop()
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = call i32 @cqrt_pop()
  %263 = call i32 @cqrt_pop()
  %264 = call i32 @cqrt_pop()
  %265 = call i32 @cqrt_pop()
  %266 = call i32 @cqrt_pop()
  %267 = call i32 @cqrt_pop()
  %268 = call i32 @cqrt_pop()
  %269 = call i32 @cqrt_pop()
  %270 = call i32 @cqrt_pop()
  %271 = call i32 @cqrt_pop()
  %272 = call i32 @cqrt_pop()
  %273 = call i32 @cqrt_pop()
  %274 = call i32 @cqrt_pop()
  %275 = call i32 @cqrt_pop()
  %276 = zext i32 %275 to i64
  %277 = shl i64 %276, 32
  %278 = or i64 0, %277
  %279 = call i32 @cqrt_pop()
  %280 = zext i32 %279 to i64
  %281 = or i64 %278, %280
  %282 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %282, i32 %124, i64 %281)
  call void @cqrt_free(i32 %282)
  call void @cqrt_and_i1(i32 %274, i32 %273, i32 %272)
  call void @cqrt_free(i32 %272)
  call void @cqrt_and_i1(i32 %271, i32 %270, i32 %273)
  call void @cqrt_free(i32 %273)
  call void @cqrt_xor_i1(i32 %269, i32 %270)
  call void @cqrt_not_i1(i32 %270)
  call void @cqrt_free(i32 %270)
  call void @cq_template_select_i32_unc(i32 %268, i32 %267, i32 %266, i32 %265)
  call void @cqrt_free(i32 %268)
  call void @cqrt_and_i1(i32 %274, i32 %264, i32 %267)
  call void @cqrt_free(i32 %267)
  call void @cqrt_and_i1(i32 %263, i32 %271, i32 %264)
  call void @cqrt_xor_i1(i32 %263, i32 %264)
  call void @cqrt_free(i32 %264)
  call void @cqrt_xor_i1(i32 %269, i32 %263)
  call void @cqrt_not_i1(i32 %263)
  call void @cqrt_free(i32 %263)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %266, i32 %262)
  call void @cqrt_free(i32 %266)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %271, i32 %261, i64 0)
  call void @cqrt_free(i32 %271)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %261, i32 %260, i32 %6, i32 %259)
  call void @cqrt_free(i32 %261)
  call void @cqrt_and_i1(i32 %274, i32 %258, i32 %260)
  call void @cqrt_free(i32 %260)
  call void @cqrt_xor_i1(i32 %269, i32 %258)
  call void @cqrt_not_i1(i32 %258)
  call void @cqrt_free(i32 %258)
  call void @cq_template_add_i64_hl_unc(i32 %259, i32 %257, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %259)
  call void @cq_template_mul_i64_hl_unc(i32 %257, i32 %256, i64 8)
  call void @cqrt_free(i32 %257)
  call void @cq_template_add_i64_hl_unc(i32 %256, i32 %262, i64 1)
  call void @cqrt_free(i32 %256)
  %283 = call i32 @cqrt_pop()
  switch i32 %283, label %284 [
    i32 1, label %254
  ]

284:                                              ; preds = %255
  %285 = call i32 @cqrt_pop()
  %286 = call i32 @cqrt_pop()
  %287 = call i32 @cqrt_pop()
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = call i32 @cqrt_pop()
  %291 = call i32 @cqrt_pop()
  %292 = call i32 @cqrt_pop()
  %293 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %293, i32 %292, i32 %291)
  call void @cqrt_free(i32 %291)
  call void @cqrt_xor_i1(i32 %290, i32 %292)
  call void @cqrt_not_i1(i32 %292)
  call void @cqrt_free(i32 %292)
  call void @cq_template_select_i32_unc(i32 %289, i32 %288, i32 %287, i32 %286)
  call void @cqrt_free(i32 %289)
  call void @cqrt_and_i1(i32 %293, i32 %290, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_free(i32 %287)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %290, i32 %285, i64 4)
  call void @cqrt_free(i32 %290)
  br label %255

294:                                              ; preds = %236
  call void @cqrt_copy_i32(i32 %172, i32 %185)
  call void @cqrt_free(i32 %185)
  br label %295

295:                                              ; preds = %294
  switch i32 %168, label %254 [
    i32 1, label %255
  ]

296:                                              ; preds = %382, %297
  br label %238

297:                                              ; preds = %367
  %298 = call i32 @cqrt_pop()
  %299 = call i32 @cqrt_pop()
  %300 = call i32 @cqrt_pop()
  %301 = call i32 @cqrt_pop()
  %302 = call i32 @cqrt_pop()
  %303 = call i32 @cqrt_pop()
  %304 = call i32 @cqrt_pop()
  %305 = call i32 @cqrt_pop()
  %306 = call i32 @cqrt_pop()
  %307 = call i32 @cqrt_pop()
  %308 = call i32 @cqrt_pop()
  %309 = call i32 @cqrt_pop()
  %310 = call i32 @cqrt_pop()
  %311 = call i32 @cqrt_pop()
  %312 = call i32 @cqrt_pop()
  %313 = call i32 @cqrt_pop()
  %314 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %314, i32 %313, i32 %312)
  call void @cqrt_free(i32 %312)
  call void @cqrt_and_i1(i32 %311, i32 %310, i32 %313)
  call void @cqrt_xor_i1(i32 %311, i32 %313)
  call void @cqrt_free(i32 %313)
  call void @cqrt_and_i1(i32 %309, i32 %308, i32 %311)
  call void @cqrt_free(i32 %311)
  call void @cqrt_xor_i1(i32 %307, i32 %308)
  call void @cqrt_not_i1(i32 %308)
  call void @cqrt_free(i32 %308)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %309, i32 %306, i64 0)
  call void @cqrt_free(i32 %309)
  call void @cq_template_and_i64_hl_unc(i32 %306, i32 %305, i64 255)
  call void @cqrt_free(i32 %306)
  call void @cq_template_xor_i64_hl_unc(i32 %305, i32 %304, i64 -1)
  call void @cqrt_free(i32 %305)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %303, i32 %302)
  call void @cqrt_free(i32 %303)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %310, i32 %304, i64 -1)
  call void @cqrt_free(i32 %310)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %304, i32 %301, i32 %6, i32 %300)
  call void @cqrt_free(i32 %304)
  call void @cqrt_and_i1(i32 %314, i32 %299, i32 %301)
  call void @cqrt_free(i32 %301)
  call void @cqrt_xor_i1(i32 %307, i32 %299)
  call void @cqrt_not_i1(i32 %299)
  call void @cqrt_free(i32 %299)
  call void @cq_template_add_i64_hl_unc(i32 %300, i32 %298, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %300)
  call void @cq_template_mul_i64_hl_unc(i32 %298, i32 %302, i64 8)
  call void @cqrt_free(i32 %298)
  %315 = call i32 @cqrt_pop()
  switch i32 %315, label %355 [
    i32 1, label %296
  ]

316:                                              ; preds = %382, %355
  %317 = call i32 @cqrt_pop()
  %318 = call i32 @cqrt_pop()
  %319 = call i32 @cqrt_pop()
  %320 = call i32 @cqrt_pop()
  %321 = call i32 @cqrt_pop()
  %322 = call i32 @cqrt_pop()
  %323 = call i32 @cqrt_pop()
  %324 = call i32 @cqrt_pop()
  %325 = call i32 @cqrt_pop()
  %326 = call i32 @cqrt_pop()
  %327 = zext i32 %326 to i64
  %328 = shl i64 %327, 32
  %329 = or i64 0, %328
  %330 = call i32 @cqrt_pop()
  %331 = zext i32 %330 to i64
  %332 = or i64 %329, %331
  %333 = call i32 @cqrt_pop()
  %334 = call i32 @cqrt_pop()
  %335 = call i32 @cqrt_pop()
  %336 = call i32 @cqrt_pop()
  %337 = call i32 @cqrt_pop()
  %338 = call i32 @cqrt_pop()
  %339 = call i32 @cqrt_pop()
  %340 = call i32 @cqrt_pop()
  %341 = call i32 @cqrt_pop()
  %342 = call i32 @cqrt_pop()
  %343 = call i32 @cqrt_pop()
  %344 = call i32 @cqrt_pop()
  %345 = call i32 @cqrt_pop()
  %346 = call i32 @cqrt_pop()
  %347 = call i32 @cqrt_pop()
  %348 = call i32 @cqrt_pop()
  %349 = call i32 @cqrt_pop()
  %350 = call i32 @cqrt_pop()
  %351 = call i32 @cqrt_pop()
  %352 = call i32 @cqrt_pop()
  %353 = call i32 @cqrt_pop()
  %354 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %354, i32 %353, i32 %352, i32 %351)
  call void @cqrt_free(i32 %354)
  call void @cq_template_add_i64_unc(i32 %352, i32 %350, i32 %349)
  call void @cqrt_free(i32 %352)
  call void @cq_template_select_i64_unc(i32 %350, i32 %348, i32 %347, i32 %346)
  call void @cqrt_free(i32 %350)
  call void @cq_template_zext_i32_to_i64_unc(i32 %349, i32 %345)
  call void @cqrt_free(i32 %349)
  call void @cq_template_add_i32_unc(i32 %345, i32 %344, i32 %343)
  call void @cqrt_free(i32 %345)
  call void @cq_template_select_i32_hl_unc(i32 %344, i32 %348, i32 %342, i32 0)
  call void @cqrt_free(i32 %344)
  br label %368

355:                                              ; preds = %297
  %356 = call i32 @cqrt_pop()
  %357 = call i32 @cqrt_pop()
  %358 = call i32 @cqrt_pop()
  %359 = call i32 @cqrt_pop()
  %360 = call i32 @cqrt_pop()
  %361 = call i32 @cqrt_pop()
  %362 = call i32 @cqrt_pop()
  %363 = call i32 @cqrt_pop()
  %364 = call i32 @cqrt_pop()
  %365 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %365, i32 %364, i32 %363)
  call void @cqrt_free(i32 %363)
  call void @cqrt_xor_i1(i32 %362, i32 %364)
  call void @cqrt_not_i1(i32 %364)
  call void @cqrt_free(i32 %364)
  call void @cq_template_select_i64_unc(i32 %361, i32 %360, i32 %359, i32 %358)
  call void @cqrt_free(i32 %361)
  call void @cqrt_and_i1(i32 %365, i32 %362, i32 %360)
  call void @cqrt_free(i32 %360)
  call void @cqrt_free(i32 %359)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %362, i32 %357, i64 5)
  call void @cqrt_free(i32 %362)
  call void @cq_template_add_i64_hl_unc(i32 %357, i32 %356, i64 1)
  call void @cqrt_free(i32 %357)
  br label %316

366:                                              ; preds = %237
  call void @cqrt_copy_i64(i32 %65, i32 %116)
  call void @cqrt_free(i32 %116)
  br label %382

367:                                              ; preds = %368
  call void @cqrt_free(i32 %341)
  call void @cqrt_free(i32 %340)
  call void @cqrt_and_i1(i32 %339, i32 %338, i32 %337)
  call void @cqrt_free(i32 %337)
  call void @cqrt_and_i1(i32 %348, i32 %336, i32 %338)
  call void @cqrt_free(i32 %338)
  call void @cqrt_and_i1(i32 %335, i32 %334, i32 %336)
  call void @cqrt_xor_i1(i32 %335, i32 %336)
  call void @cqrt_free(i32 %336)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %335)
  call void @cqrt_free(i32 %335)
  call void @cq_template_add_i64_hl_unc(i32 %333, i32 %17, i64 %332)
  call void @cqrt_free(i32 %333)
  call void @cqrt_and_i1(i32 %325, i32 %324, i32 %323)
  call void @cqrt_free(i32 %323)
  call void @cqrt_and_i1(i32 %322, i32 %321, i32 %324)
  call void @cqrt_free(i32 %324)
  call void @cqrt_xor_i1(i32 %334, i32 %321)
  call void @cqrt_not_i1(i32 %321)
  call void @cqrt_free(i32 %321)
  call void @cqrt_and_i1(i32 %325, i32 %320, i32 %353)
  call void @cqrt_free(i32 %353)
  call void @cqrt_and_i1(i32 %319, i32 %322, i32 %320)
  call void @cqrt_xor_i1(i32 %319, i32 %320)
  call void @cqrt_free(i32 %320)
  call void @cqrt_xor_i1(i32 %334, i32 %319)
  call void @cqrt_not_i1(i32 %319)
  call void @cqrt_free(i32 %319)
  call void @cq_template_shl_i32_hl_unc(i32 %343, i32 %318, i32 6)
  call void @cqrt_free(i32 %343)
  call void @cqrt_free(i32 %317)
  br label %297

368:                                              ; preds = %316, %368
  %369 = call i32 @cqrt_pop()
  %370 = call i32 @cqrt_pop()
  %371 = call i32 @cqrt_pop()
  %372 = call i32 @cqrt_pop()
  %373 = call i32 @cqrt_pop()
  %374 = call i32 @cqrt_pop()
  %375 = call i32 @cqrt_pop()
  %376 = call i32 @cqrt_pop()
  %377 = call i32 @cqrt_pop()
  %378 = call i32 @cqrt_pop()
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %380, i32 %379, i32 %378)
  call void @cqrt_free(i32 %378)
  call void @cq_template_select_i64_unc(i32 %377, i32 %380, i32 %376, i32 %375)
  call void @cqrt_free(i32 %377)
  call void @cq_template_select_i32_lh_unc(i32 %374, i32 %380, i32 %373, i32 %372)
  call void @cqrt_free(i32 %374)
  call void @cq_template_select_i64_unc(i32 %371, i32 %380, i32 %370, i32 %369)
  call void @cqrt_free(i32 %371)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %379, i32 %376, i64 0)
  call void @cqrt_free(i32 %379)
  call void @cq_template_and_i64_hl_unc(i32 %376, i32 %370, i64 255)
  call void @cqrt_free(i32 %376)
  call void @cq_template_lshr_i64_hl_unc(i32 %370, i32 %369, i64 8)
  call void @cqrt_free(i32 %370)
  %381 = call i32 @cqrt_pop()
  switch i32 %381, label %368 [
    i32 1, label %367
  ]

382:                                              ; preds = %366
  switch i32 %60, label %296 [
    i32 1, label %316
  ]
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32_qangle(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %400

10:                                               ; preds = %5
  %11 = call i32 @__cq_mem()
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %12, i32 %3)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %13)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %13, i32 %3)
  %14 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %15 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %12, i32 -1)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %17 = call i32 @cq_template_mul_i64_hl(i32 %16, i64 8)
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 ptrtoint (ptr @limbs to i64))
  %19 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %11, i32 %18)
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 -1)
  %21 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)
  br label %23

23:                                               ; preds = %10
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %25)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  %27 = call i32 @cq_template_add_i64_hl(i32 %22, i64 1)
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %27, i64 5)
  %29 = call i32 @cqrt_alloc_i64(i64 320)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %28, i32 %30)
  %31 = call i32 @cq_template_select_i64(i32 %30, i32 %29, i32 %26)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_xor_i1(i32 %28, i32 %32)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  %34 = call i32 @llvm.umin.i32(i32 %4, i32 5)
  %35 = icmp ult i32 %4, 5
  %36 = icmp ult i32 0, %34
  br i1 %36, label %37, label %66

37:                                               ; preds = %111, %23
  %from11 = phi i32 [ 0, %111 ], [ 1, %23 ]
  %38 = phi i32 [ 0, %23 ], [ %106, %111 ]
  %39 = phi i32 [ %33, %23 ], [ %118, %111 ]
  %40 = phi i32 [ %22, %23 ], [ %105, %111 ]
  %41 = phi i64 [ 0, %23 ], [ %104, %111 ]
  %42 = phi i32 [ %27, %23 ], [ %112, %111 ]
  %43 = phi i32 [ %28, %23 ], [ %113, %111 ]
  %44 = phi i32 [ %31, %23 ], [ %116, %111 ]
  call void @cqrt_push(i32 %from11)
  %45 = call i32 @cq_template_mul_i64_hl(i32 %42, i64 8)
  %46 = call i32 @cq_template_add_i64_hl(i32 %45, i64 ptrtoint (ptr @limbs to i64))
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_xor_i1(i32 %43, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %47, i32 %48)
  %49 = call i32 @cqrt_qram_load_i64_controlled(i32 %48, i32 %11, i32 %46)
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %49, i64 -1)
  %51 = call i32 @cq_template_trunc_i64_to_i32(i32 %42)
  %52 = call i32 @cq_template_xor_i64_hl(i32 %49, i64 -1)
  %53 = call i32 @cq_template_and_i64_hl(i32 %52, i64 255)
  %54 = call i32 @cq_template_icmp_eq_i64_hl(i32 %53, i64 0)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_xor_i1(i32 %43, i32 %57)
  call void @cqrt_and_i1(i32 %54, i32 %57, i32 %56)
  call void @cqrt_xor_i1(i32 %56, i32 %55)
  call void @cqrt_and_i1(i32 %56, i32 %50, i32 %55)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %55, i32 %58)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %62)
  call void @cqrt_xor_i1(i32 %62, i32 %61)
  call void @cqrt_and_i1(i32 %62, i32 %43, i32 %61)
  call void @cqrt_and_i1(i32 %54, i32 %61, i32 %60)
  call void @cqrt_and_i1(i32 %0, i32 %60, i32 %59)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %58, i32 %59, i32 %63)
  %64 = call i32 @cqrt_alloc_i32(i32 0)
  %65 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  br label %75

66:                                               ; preds = %89, %23
  %67 = phi i32 [ 0, %23 ], [ 1, %89 ]
  %68 = phi i32 [ %22, %23 ], [ %105, %89 ]
  %69 = phi i64 [ 0, %23 ], [ %104, %89 ]
  %70 = phi i32 [ %27, %23 ], [ %42, %89 ]
  %71 = phi i32 [ %28, %23 ], [ %43, %89 ]
  %72 = phi i32 [ %31, %23 ], [ %100, %89 ]
  %73 = phi i32 [ %33, %23 ], [ %103, %89 ]
  br i1 %35, label %119, label %121

74:                                               ; preds = %75
  br label %88

75:                                               ; preds = %75, %37
  %from10 = phi i32 [ 0, %75 ], [ 1, %37 ]
  %76 = phi i32 [ 0, %37 ], [ %79, %75 ]
  %77 = phi i32 [ %52, %37 ], [ %83, %75 ]
  %trip = phi i32 [ %63, %37 ], [ %87, %75 ]
  %cap = phi i32 [ %64, %37 ], [ %84, %75 ]
  %cap1 = phi i32 [ %65, %37 ], [ %85, %75 ]
  call void @cqrt_push(i32 %from10)
  %78 = call i32 @cq_template_lshr_i64_hl(i32 %77, i64 8)
  %79 = add nuw nsw i32 %76, 8
  %80 = call i32 @cq_template_and_i64_hl(i32 %78, i64 255)
  %81 = call i32 @cq_template_icmp_eq_i64_hl(i32 %80, i64 0)
  %82 = icmp ult i32 %76, 48
  %83 = call i32 @cq_template_select_i64(i32 %trip, i32 %78, i32 %77)
  %84 = call i32 @cq_template_select_i32_lh(i32 %trip, i32 %79, i32 %cap)
  %85 = call i32 @cq_template_select_i64(i32 %trip, i32 %80, i32 %cap1)
  %86 = xor i1 %82, true
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %81, i32 %87)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %cap1)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %cap)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %77)
  br i1 %86, label %74, label %75

88:                                               ; preds = %74
  br label %89

89:                                               ; preds = %88
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cq_template_select_i32_hl(i32 %54, i32 %84, i32 0)
  %92 = call i32 @cq_template_select_i64(i32 %54, i32 %85, i32 %53)
  %93 = call i32 @cq_template_shl_i32_hl(i32 %51, i32 6)
  %94 = call i32 @cq_template_add_i32(i32 %91, i32 %93)
  %95 = call i32 @cq_template_zext_i32_to_i64(i32 %94)
  %96 = call i32 @cq_template_add_i64(i32 %92, i32 %95)
  %97 = call i32 @cqrt_alloc_i1(i1 false)
  %98 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_xor_i1(i32 %43, i32 %98)
  call void @cqrt_xor_i1(i32 %98, i32 %97)
  call void @cqrt_and_i1(i32 %98, i32 %50, i32 %97)
  %99 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %97, i32 %99)
  %100 = call i32 @cq_template_select_i64(i32 %99, i32 %96, i32 %44)
  %101 = call i32 @cqrt_alloc_i1(i1 false)
  %102 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %102)
  call void @cqrt_xor_i1(i32 %43, i32 %102)
  call void @cqrt_and_i1(i32 %50, i32 %102, i32 %101)
  %103 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %101, i32 %103)
  %104 = add i64 %41, 1
  %105 = call i32 @cq_template_add_i64_hl(i32 %22, i64 %104)
  %106 = add i32 %38, 1
  %107 = icmp ult i32 %106, %34
  call void @cqrt_push(i32 %100)
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %105)
  %108 = trunc i64 %104 to i32
  call void @cqrt_push(i32 %108)
  %109 = lshr i64 %104, 32
  %110 = trunc i64 %109 to i32
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %101)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %102)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %90)
  br i1 %107, label %111, label %66

111:                                              ; preds = %89
  %112 = call i32 @cq_template_add_i64_hl(i32 %105, i64 1)
  %113 = call i32 @cq_template_icmp_eq_i64_hl(i32 %112, i64 5)
  %114 = call i32 @cqrt_alloc_i64(i64 320)
  %115 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %103, i32 %113, i32 %115)
  %116 = call i32 @cq_template_select_i64(i32 %115, i32 %114, i32 %100)
  %117 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %117)
  call void @cqrt_xor_i1(i32 %113, i32 %117)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %103, i32 %117, i32 %118)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %114)
  call void @cqrt_push(i32 %100)
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %105)
  br label %37

119:                                              ; preds = %66
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %73, i32 %120)
  br label %122

121:                                              ; preds = %66
  br label %122

122:                                              ; preds = %119, %121
  %123 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %72, i32 %123)
  br label %124

124:                                              ; preds = %122
  %125 = call i32 @cq_template_xor_i64_hl(i32 %19, i64 -1)
  %126 = call i32 @cq_template_lshr_i32_hl(i32 %13, i32 2)
  %127 = call i32 @cq_template_zext_i32_to_i64(i32 %126)
  %128 = call i32 @cq_template_and_i64(i32 %19, i32 %127)
  %129 = call i32 @cq_template_icmp_eq_i64_hl(i32 %128, i64 0)
  %130 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)
  %131 = call i32 @cq_template_zext_i32_to_i64(i32 %130)
  br label %132

132:                                              ; preds = %124
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %135)
  call void @cqrt_xor_i1(i32 %15, i32 %135)
  call void @cqrt_and_i1(i32 %129, i32 %135, i32 %134)
  call void @cqrt_and_i1(i32 %0, i32 %134, i32 %133)
  %136 = call i32 @cqrt_alloc_i32(i32 0)
  %137 = call i32 @cq_template_icmp_eq_i64_hl(i32 %131, i64 4)
  %138 = call i32 @cqrt_alloc_i32(i32 4)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %137, i32 %139)
  %140 = call i32 @cq_template_select_i32(i32 %139, i32 %138, i32 %136)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %141)
  call void @cqrt_xor_i1(i32 %137, i32 %141)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %141, i32 %142)
  %143 = call i32 @llvm.umin.i32(i32 %4, i32 5)
  %144 = icmp ult i32 %4, 5
  %145 = icmp ult i32 0, %143
  br i1 %145, label %146, label %175

146:                                              ; preds = %182, %132
  %from5 = phi i32 [ 0, %182 ], [ 1, %132 ]
  %147 = phi i32 [ 0, %132 ], [ %170, %182 ]
  %148 = phi i32 [ %142, %132 ], [ %188, %182 ]
  %149 = phi i32 [ %131, %132 ], [ %169, %182 ]
  %150 = phi i64 [ 0, %132 ], [ %168, %182 ]
  %151 = phi i32 [ %137, %132 ], [ %183, %182 ]
  %152 = phi i32 [ %140, %132 ], [ %186, %182 ]
  call void @cqrt_push(i32 %from5)
  %153 = call i32 @cq_template_add_i64_hl(i32 %149, i64 1)
  %154 = call i32 @cq_template_mul_i64_hl(i32 %153, i64 8)
  %155 = call i32 @cq_template_add_i64_hl(i32 %154, i64 ptrtoint (ptr @limbs to i64))
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %156)
  call void @cqrt_xor_i1(i32 %151, i32 %156)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %148, i32 %156, i32 %157)
  %158 = call i32 @cqrt_qram_load_i64_controlled(i32 %157, i32 %11, i32 %155)
  %159 = call i32 @cq_template_icmp_eq_i64_hl(i32 %158, i64 0)
  %160 = call i32 @cq_template_trunc_i64_to_i32(i32 %149)
  %161 = call i32 @cqrt_alloc_i1(i1 false)
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %162)
  call void @cqrt_xor_i1(i32 %151, i32 %162)
  call void @cqrt_xor_i1(i32 %162, i32 %161)
  call void @cqrt_and_i1(i32 %162, i32 %159, i32 %161)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %148, i32 %161, i32 %163)
  %164 = call i32 @cq_template_select_i32(i32 %163, i32 %160, i32 %152)
  %165 = call i32 @cqrt_alloc_i1(i1 false)
  %166 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %166)
  call void @cqrt_xor_i1(i32 %151, i32 %166)
  call void @cqrt_and_i1(i32 %159, i32 %166, i32 %165)
  %167 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %148, i32 %165, i32 %167)
  %168 = add i64 %150, 1
  %169 = call i32 @cq_template_add_i64_hl(i32 %131, i64 %168)
  %170 = add i32 %147, 1
  %171 = icmp ult i32 %170, %143
  call void @cqrt_push(i32 %169)
  %172 = trunc i64 %168 to i32
  call void @cqrt_push(i32 %172)
  %173 = lshr i64 %168, 32
  %174 = trunc i64 %173 to i32
  call void @cqrt_push(i32 %174)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %165)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %164)
  call void @cqrt_push(i32 %163)
  call void @cqrt_push(i32 %160)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %161)
  call void @cqrt_push(i32 %162)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %158)
  call void @cqrt_push(i32 %157)
  call void @cqrt_push(i32 %155)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %154)
  call void @cqrt_push(i32 %153)
  br i1 %171, label %182, label %175

175:                                              ; preds = %146, %132
  %176 = phi i32 [ 0, %132 ], [ 1, %146 ]
  %177 = phi i32 [ %131, %132 ], [ %169, %146 ]
  %178 = phi i64 [ 0, %132 ], [ %168, %146 ]
  %179 = phi i32 [ %137, %132 ], [ %151, %146 ]
  %180 = phi i32 [ %140, %132 ], [ %164, %146 ]
  %181 = phi i32 [ %142, %132 ], [ %167, %146 ]
  br i1 %144, label %189, label %191

182:                                              ; preds = %146
  %183 = call i32 @cq_template_icmp_eq_i64_hl(i32 %169, i64 4)
  %184 = call i32 @cqrt_alloc_i32(i32 4)
  %185 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %167, i32 %183, i32 %185)
  %186 = call i32 @cq_template_select_i32(i32 %185, i32 %184, i32 %164)
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %187)
  call void @cqrt_xor_i1(i32 %183, i32 %187)
  %188 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %167, i32 %187, i32 %188)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %187)
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %183)
  call void @cqrt_push(i32 %186)
  call void @cqrt_push(i32 %185)
  call void @cqrt_push(i32 %184)
  call void @cqrt_push(i32 %164)
  call void @cqrt_push(i32 %169)
  br label %146

189:                                              ; preds = %175
  %190 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %181, i32 %190)
  br label %192

191:                                              ; preds = %175
  br label %192

192:                                              ; preds = %189, %191
  %193 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %180, i32 %193)
  br label %194

194:                                              ; preds = %192
  %195 = call i32 @cq_template_add_i32_hl(i32 %193, i32 1)
  %196 = call i32 @cq_template_zext_i32_to_i64(i32 %195)
  %197 = call i32 @cq_template_mul_i64_hl(i32 %196, i64 8)
  %198 = call i32 @cq_template_add_i64_hl(i32 %197, i64 ptrtoint (ptr @limbs to i64))
  %199 = call i32 @cqrt_alloc_i1(i1 false)
  %200 = call i32 @cqrt_alloc_i1(i1 false)
  %201 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_xor_i1(i32 %15, i32 %201)
  call void @cqrt_and_i1(i32 %129, i32 %201, i32 %200)
  call void @cqrt_and_i1(i32 %0, i32 %200, i32 %199)
  %202 = call i32 @cqrt_qram_load_i64_controlled(i32 %199, i32 %11, i32 %198)
  %203 = call i32 @cq_template_icmp_eq_i64_hl(i32 %202, i64 0)
  %204 = call i32 @cq_template_select_i64(i32 %129, i32 %202, i32 %128)
  %205 = call i32 @cq_template_select_i64(i32 %15, i32 %125, i32 %204)
  %206 = call i32 @cq_template_select_i32(i32 %129, i32 %193, i32 %14)
  %207 = call i32 @cq_template_select_i32(i32 %15, i32 %14, i32 %206)
  %208 = call i32 @cq_template_and_i64_hl(i32 %205, i64 255)
  %209 = call i32 @cq_template_icmp_eq_i64_hl(i32 %208, i64 0)
  br label %210

210:                                              ; preds = %194
  %211 = call i32 @cqrt_alloc_i1(i1 false)
  %212 = call i32 @cqrt_alloc_i1(i1 false)
  %213 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %213)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %213)
  %214 = call i32 @cqrt_alloc_i1(i1 false)
  %215 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %215)
  call void @cqrt_xor_i1(i32 %15, i32 %215)
  call void @cqrt_and_i1(i32 %129, i32 %215, i32 %214)
  call void @cqrt_and_i1(i32 %203, i32 %214, i32 %213)
  call void @cqrt_and_i1(i32 %209, i32 %213, i32 %212)
  call void @cqrt_and_i1(i32 %0, i32 %212, i32 %211)
  %216 = call i32 @cqrt_alloc_i32(i32 0)
  %217 = call i32 @cqrt_alloc_i64(i64 0)
  br label %219

218:                                              ; preds = %219
  br label %232

219:                                              ; preds = %219, %210
  %from = phi i32 [ 0, %219 ], [ 1, %210 ]
  %220 = phi i32 [ 0, %210 ], [ %223, %219 ]
  %221 = phi i32 [ %205, %210 ], [ %227, %219 ]
  %trip2 = phi i32 [ %211, %210 ], [ %231, %219 ]
  %cap3 = phi i32 [ %216, %210 ], [ %228, %219 ]
  %cap4 = phi i32 [ %217, %210 ], [ %229, %219 ]
  call void @cqrt_push(i32 %from)
  %222 = call i32 @cq_template_lshr_i64_hl(i32 %221, i64 8)
  %223 = add nuw nsw i32 %220, 8
  %224 = call i32 @cq_template_and_i64_hl(i32 %222, i64 255)
  %225 = call i32 @cq_template_icmp_eq_i64_hl(i32 %224, i64 0)
  %226 = icmp ult i32 %220, 48
  %227 = call i32 @cq_template_select_i64(i32 %trip2, i32 %222, i32 %221)
  %228 = call i32 @cq_template_select_i32_lh(i32 %trip2, i32 %223, i32 %cap3)
  %229 = call i32 @cq_template_select_i64(i32 %trip2, i32 %224, i32 %cap4)
  %230 = xor i1 %226, true
  %231 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip2, i32 %225, i32 %231)
  call void @cqrt_push(i32 %trip2)
  call void @cqrt_push(i32 %225)
  call void @cqrt_push(i32 %231)
  call void @cqrt_push(i32 %229)
  call void @cqrt_push(i32 %224)
  call void @cqrt_push(i32 %cap4)
  call void @cqrt_push(i32 %228)
  call void @cqrt_push(i32 %223)
  call void @cqrt_push(i32 %cap3)
  call void @cqrt_push(i32 %227)
  call void @cqrt_push(i32 %222)
  call void @cqrt_push(i32 %221)
  br i1 %230, label %218, label %219

232:                                              ; preds = %218
  %233 = call i32 @cq_template_select_i32_hl(i32 %209, i32 %228, i32 0)
  %234 = call i32 @cq_template_select_i64(i32 %209, i32 %229, i32 %208)
  %235 = call i32 @cq_template_shl_i32_hl(i32 %207, i32 6)
  %236 = call i32 @cq_template_add_i32(i32 %233, i32 %235)
  %237 = call i32 @cq_template_zext_i32_to_i64(i32 %236)
  %238 = call i32 @cq_template_add_i64(i32 %234, i32 %237)
  %239 = call i32 @cqrt_alloc_i1(i1 false)
  %240 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %240)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %240)
  %241 = call i32 @cqrt_alloc_i1(i1 false)
  %242 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %242)
  call void @cqrt_xor_i1(i32 %15, i32 %242)
  call void @cqrt_and_i1(i32 %129, i32 %242, i32 %241)
  call void @cqrt_and_i1(i32 %203, i32 %241, i32 %240)
  call void @cqrt_and_i1(i32 %0, i32 %240, i32 %239)
  %243 = call i32 @cq_template_select_i64(i32 %239, i32 %238, i32 %123)
  %244 = call i32 @cqrt_alloc_i1(i1 false)
  %245 = call i32 @cqrt_alloc_i1(i1 false)
  %246 = call i32 @cqrt_alloc_i1(i1 false)
  %247 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %247)
  call void @cqrt_xor_i1(i32 %15, i32 %247)
  call void @cqrt_and_i1(i32 %129, i32 %247, i32 %246)
  call void @cqrt_and_i1(i32 %203, i32 %246, i32 %245)
  call void @cqrt_and_i1(i32 %0, i32 %245, i32 %244)
  %248 = call i32 @cq_template_select_i64_lh(i32 %244, i64 -1, i32 %243)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  %249 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %248, i32 %249)
  call void @cq_template_select_i64_lh_unc(i32 %248, i32 %244, i64 -1, i32 %243)
  call void @cqrt_free(i32 %248)
  call void @cqrt_and_i1(i32 %0, i32 %245, i32 %244)
  call void @cqrt_free(i32 %244)
  call void @cqrt_and_i1(i32 %203, i32 %246, i32 %245)
  call void @cqrt_free(i32 %245)
  call void @cqrt_and_i1(i32 %129, i32 %247, i32 %246)
  call void @cqrt_free(i32 %246)
  call void @cqrt_xor_i1(i32 %15, i32 %247)
  call void @cqrt_not_i1(i32 %247)
  call void @cqrt_free(i32 %247)
  call void @cq_template_select_i64_unc(i32 %243, i32 %239, i32 %238, i32 %123)
  call void @cqrt_free(i32 %243)
  call void @cqrt_and_i1(i32 %0, i32 %240, i32 %239)
  call void @cqrt_free(i32 %239)
  call void @cqrt_and_i1(i32 %203, i32 %241, i32 %240)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %240)
  call void @cqrt_not_i1(i32 %240)
  call void @cqrt_free(i32 %240)
  call void @cqrt_and_i1(i32 %129, i32 %242, i32 %241)
  call void @cqrt_free(i32 %241)
  call void @cqrt_xor_i1(i32 %15, i32 %242)
  call void @cqrt_not_i1(i32 %242)
  call void @cqrt_free(i32 %242)
  call void @cq_template_add_i64_unc(i32 %238, i32 %234, i32 %237)
  call void @cqrt_free(i32 %238)
  call void @cq_template_zext_i32_to_i64_unc(i32 %237, i32 %236)
  call void @cqrt_free(i32 %237)
  call void @cq_template_add_i32_unc(i32 %236, i32 %233, i32 %235)
  call void @cqrt_free(i32 %236)
  call void @cq_template_shl_i32_hl_unc(i32 %235, i32 %207, i32 6)
  call void @cqrt_free(i32 %235)
  call void @cq_template_select_i64_unc(i32 %234, i32 %209, i32 %229, i32 %208)
  call void @cqrt_free(i32 %234)
  call void @cq_template_select_i32_hl_unc(i32 %233, i32 %209, i32 %228, i32 0)
  call void @cqrt_free(i32 %233)
  br label %256

250:                                              ; preds = %255
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %209, i32 %208, i64 0)
  call void @cqrt_free(i32 %209)
  call void @cq_template_and_i64_hl_unc(i32 %208, i32 %205, i64 255)
  call void @cqrt_free(i32 %208)
  call void @cq_template_select_i32_unc(i32 %207, i32 %15, i32 %14, i32 %206)
  call void @cqrt_free(i32 %207)
  call void @cq_template_select_i32_unc(i32 %206, i32 %129, i32 %193, i32 %14)
  call void @cqrt_free(i32 %206)
  call void @cq_template_select_i64_unc(i32 %205, i32 %15, i32 %125, i32 %204)
  call void @cqrt_free(i32 %205)
  call void @cq_template_select_i64_unc(i32 %204, i32 %129, i32 %202, i32 %128)
  call void @cqrt_free(i32 %204)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %203, i32 %202, i64 0)
  call void @cqrt_free(i32 %203)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %202, i32 %199, i32 %11, i32 %198)
  call void @cqrt_free(i32 %202)
  call void @cqrt_and_i1(i32 %0, i32 %200, i32 %199)
  call void @cqrt_free(i32 %199)
  call void @cqrt_and_i1(i32 %129, i32 %201, i32 %200)
  call void @cqrt_free(i32 %200)
  call void @cqrt_xor_i1(i32 %15, i32 %201)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_free(i32 %201)
  call void @cq_template_add_i64_hl_unc(i32 %198, i32 %197, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %198)
  call void @cq_template_mul_i64_hl_unc(i32 %197, i32 %196, i64 8)
  call void @cqrt_free(i32 %197)
  call void @cq_template_zext_i32_to_i64_unc(i32 %196, i32 %195)
  call void @cqrt_free(i32 %196)
  call void @cq_template_add_i32_hl_unc(i32 %195, i32 %193, i32 1)
  call void @cqrt_free(i32 %195)
  br label %310

251:                                              ; preds = %270
  call void @cqrt_and_i1(i32 %133, i32 %141, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_xor_i1(i32 %137, i32 %141)
  call void @cqrt_not_i1(i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cq_template_select_i32_unc(i32 %140, i32 %139, i32 %138, i32 %136)
  call void @cqrt_free(i32 %140)
  call void @cqrt_and_i1(i32 %133, i32 %137, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_free(i32 %138)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %137, i32 %131, i64 4)
  call void @cqrt_free(i32 %137)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %0, i32 %134, i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_and_i1(i32 %129, i32 %135, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_xor_i1(i32 %15, i32 %135)
  call void @cqrt_not_i1(i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cq_template_zext_i32_to_i64_unc(i32 %131, i32 %130)
  call void @cqrt_free(i32 %131)
  call void @cq_template_and_i32_hl_unc(i32 %130, i32 %13, i32 3)
  call void @cqrt_free(i32 %130)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %129, i32 %128, i64 0)
  call void @cqrt_free(i32 %129)
  call void @cq_template_and_i64_unc(i32 %128, i32 %19, i32 %127)
  call void @cqrt_free(i32 %128)
  call void @cq_template_zext_i32_to_i64_unc(i32 %127, i32 %126)
  call void @cqrt_free(i32 %127)
  call void @cq_template_lshr_i32_hl_unc(i32 %126, i32 %13, i32 2)
  call void @cqrt_free(i32 %126)
  call void @cq_template_xor_i64_hl_unc(i32 %125, i32 %19, i64 -1)
  call void @cqrt_free(i32 %125)
  br label %383

252:                                              ; preds = %312
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cqrt_xor_i1(i32 %28, i32 %32)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i64_unc(i32 %31, i32 %30, i32 %29, i32 %26)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %24, i32 %28, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %28, i32 %27, i64 5)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %22, i64 1)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %13, i32 3)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %20, i32 %19, i64 -1)
  call void @cqrt_free(i32 %20)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %19, i32 %0, i32 %11, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %18)
  call void @cq_template_mul_i64_hl_unc(i32 %17, i32 %16, i64 8)
  call void @cqrt_free(i32 %17)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %14)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %15, i32 %12, i32 -1)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %13, i32 3)
  call void @cqrt_free(i32 %14)
  %253 = load i32, ptr @__cq_act_f, align 4
  %254 = add i32 %253, -1
  store i32 %254, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %249

255:                                              ; preds = %256
  call void @cqrt_free(i32 %217)
  call void @cqrt_free(i32 %216)
  call void @cqrt_and_i1(i32 %0, i32 %212, i32 %211)
  call void @cqrt_free(i32 %211)
  call void @cqrt_and_i1(i32 %209, i32 %213, i32 %212)
  call void @cqrt_free(i32 %212)
  call void @cqrt_and_i1(i32 %203, i32 %214, i32 %213)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %213)
  call void @cqrt_not_i1(i32 %213)
  call void @cqrt_free(i32 %213)
  call void @cqrt_and_i1(i32 %129, i32 %215, i32 %214)
  call void @cqrt_free(i32 %214)
  call void @cqrt_xor_i1(i32 %15, i32 %215)
  call void @cqrt_not_i1(i32 %215)
  call void @cqrt_free(i32 %215)
  br label %250

256:                                              ; preds = %232, %256
  %257 = call i32 @cqrt_pop()
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = call i32 @cqrt_pop()
  %263 = call i32 @cqrt_pop()
  %264 = call i32 @cqrt_pop()
  %265 = call i32 @cqrt_pop()
  %266 = call i32 @cqrt_pop()
  %267 = call i32 @cqrt_pop()
  %268 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %268, i32 %267, i32 %266)
  call void @cqrt_free(i32 %266)
  call void @cq_template_select_i64_unc(i32 %265, i32 %268, i32 %264, i32 %263)
  call void @cqrt_free(i32 %265)
  call void @cq_template_select_i32_lh_unc(i32 %262, i32 %268, i32 %261, i32 %260)
  call void @cqrt_free(i32 %262)
  call void @cq_template_select_i64_unc(i32 %259, i32 %268, i32 %258, i32 %257)
  call void @cqrt_free(i32 %259)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %267, i32 %264, i64 0)
  call void @cqrt_free(i32 %267)
  call void @cq_template_and_i64_hl_unc(i32 %264, i32 %258, i64 255)
  call void @cqrt_free(i32 %264)
  call void @cq_template_lshr_i64_hl_unc(i32 %258, i32 %257, i64 8)
  call void @cqrt_free(i32 %258)
  %269 = call i32 @cqrt_pop()
  switch i32 %269, label %256 [
    i32 1, label %255
  ]

270:                                              ; preds = %311, %271
  br label %251

271:                                              ; preds = %311, %300
  %272 = call i32 @cqrt_pop()
  %273 = call i32 @cqrt_pop()
  %274 = call i32 @cqrt_pop()
  %275 = call i32 @cqrt_pop()
  %276 = call i32 @cqrt_pop()
  %277 = call i32 @cqrt_pop()
  %278 = call i32 @cqrt_pop()
  %279 = call i32 @cqrt_pop()
  %280 = call i32 @cqrt_pop()
  %281 = call i32 @cqrt_pop()
  %282 = call i32 @cqrt_pop()
  %283 = call i32 @cqrt_pop()
  %284 = call i32 @cqrt_pop()
  %285 = call i32 @cqrt_pop()
  %286 = call i32 @cqrt_pop()
  %287 = call i32 @cqrt_pop()
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = call i32 @cqrt_pop()
  %291 = call i32 @cqrt_pop()
  %292 = zext i32 %291 to i64
  %293 = shl i64 %292, 32
  %294 = or i64 0, %293
  %295 = call i32 @cqrt_pop()
  %296 = zext i32 %295 to i64
  %297 = or i64 %294, %296
  %298 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %298, i32 %131, i64 %297)
  call void @cqrt_free(i32 %298)
  call void @cqrt_and_i1(i32 %290, i32 %289, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_and_i1(i32 %287, i32 %286, i32 %289)
  call void @cqrt_free(i32 %289)
  call void @cqrt_xor_i1(i32 %285, i32 %286)
  call void @cqrt_not_i1(i32 %286)
  call void @cqrt_free(i32 %286)
  call void @cq_template_select_i32_unc(i32 %284, i32 %283, i32 %282, i32 %281)
  call void @cqrt_free(i32 %284)
  call void @cqrt_and_i1(i32 %290, i32 %280, i32 %283)
  call void @cqrt_free(i32 %283)
  call void @cqrt_and_i1(i32 %279, i32 %287, i32 %280)
  call void @cqrt_xor_i1(i32 %279, i32 %280)
  call void @cqrt_free(i32 %280)
  call void @cqrt_xor_i1(i32 %285, i32 %279)
  call void @cqrt_not_i1(i32 %279)
  call void @cqrt_free(i32 %279)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %282, i32 %278)
  call void @cqrt_free(i32 %282)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %287, i32 %277, i64 0)
  call void @cqrt_free(i32 %287)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %277, i32 %276, i32 %11, i32 %275)
  call void @cqrt_free(i32 %277)
  call void @cqrt_and_i1(i32 %290, i32 %274, i32 %276)
  call void @cqrt_free(i32 %276)
  call void @cqrt_xor_i1(i32 %285, i32 %274)
  call void @cqrt_not_i1(i32 %274)
  call void @cqrt_free(i32 %274)
  call void @cq_template_add_i64_hl_unc(i32 %275, i32 %273, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %275)
  call void @cq_template_mul_i64_hl_unc(i32 %273, i32 %272, i64 8)
  call void @cqrt_free(i32 %273)
  call void @cq_template_add_i64_hl_unc(i32 %272, i32 %278, i64 1)
  call void @cqrt_free(i32 %272)
  %299 = call i32 @cqrt_pop()
  switch i32 %299, label %300 [
    i32 1, label %270
  ]

300:                                              ; preds = %271
  %301 = call i32 @cqrt_pop()
  %302 = call i32 @cqrt_pop()
  %303 = call i32 @cqrt_pop()
  %304 = call i32 @cqrt_pop()
  %305 = call i32 @cqrt_pop()
  %306 = call i32 @cqrt_pop()
  %307 = call i32 @cqrt_pop()
  %308 = call i32 @cqrt_pop()
  %309 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %309, i32 %308, i32 %307)
  call void @cqrt_free(i32 %307)
  call void @cqrt_xor_i1(i32 %306, i32 %308)
  call void @cqrt_not_i1(i32 %308)
  call void @cqrt_free(i32 %308)
  call void @cq_template_select_i32_unc(i32 %305, i32 %304, i32 %303, i32 %302)
  call void @cqrt_free(i32 %305)
  call void @cqrt_and_i1(i32 %309, i32 %306, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cqrt_free(i32 %303)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %306, i32 %301, i64 4)
  call void @cqrt_free(i32 %306)
  br label %271

310:                                              ; preds = %250
  call void @cqrt_copy_i32(i32 %180, i32 %193)
  call void @cqrt_free(i32 %193)
  br label %311

311:                                              ; preds = %310
  switch i32 %176, label %270 [
    i32 1, label %271
  ]

312:                                              ; preds = %399, %313
  br label %252

313:                                              ; preds = %384
  %314 = call i32 @cqrt_pop()
  %315 = call i32 @cqrt_pop()
  %316 = call i32 @cqrt_pop()
  %317 = call i32 @cqrt_pop()
  %318 = call i32 @cqrt_pop()
  %319 = call i32 @cqrt_pop()
  %320 = call i32 @cqrt_pop()
  %321 = call i32 @cqrt_pop()
  %322 = call i32 @cqrt_pop()
  %323 = call i32 @cqrt_pop()
  %324 = call i32 @cqrt_pop()
  %325 = call i32 @cqrt_pop()
  %326 = call i32 @cqrt_pop()
  %327 = call i32 @cqrt_pop()
  %328 = call i32 @cqrt_pop()
  %329 = call i32 @cqrt_pop()
  %330 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %330, i32 %329, i32 %328)
  call void @cqrt_free(i32 %328)
  call void @cqrt_and_i1(i32 %327, i32 %326, i32 %329)
  call void @cqrt_xor_i1(i32 %327, i32 %329)
  call void @cqrt_free(i32 %329)
  call void @cqrt_and_i1(i32 %325, i32 %324, i32 %327)
  call void @cqrt_free(i32 %327)
  call void @cqrt_xor_i1(i32 %323, i32 %324)
  call void @cqrt_not_i1(i32 %324)
  call void @cqrt_free(i32 %324)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %325, i32 %322, i64 0)
  call void @cqrt_free(i32 %325)
  call void @cq_template_and_i64_hl_unc(i32 %322, i32 %321, i64 255)
  call void @cqrt_free(i32 %322)
  call void @cq_template_xor_i64_hl_unc(i32 %321, i32 %320, i64 -1)
  call void @cqrt_free(i32 %321)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %319, i32 %318)
  call void @cqrt_free(i32 %319)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %326, i32 %320, i64 -1)
  call void @cqrt_free(i32 %326)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %320, i32 %317, i32 %11, i32 %316)
  call void @cqrt_free(i32 %320)
  call void @cqrt_and_i1(i32 %330, i32 %315, i32 %317)
  call void @cqrt_free(i32 %317)
  call void @cqrt_xor_i1(i32 %323, i32 %315)
  call void @cqrt_not_i1(i32 %315)
  call void @cqrt_free(i32 %315)
  call void @cq_template_add_i64_hl_unc(i32 %316, i32 %314, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %316)
  call void @cq_template_mul_i64_hl_unc(i32 %314, i32 %318, i64 8)
  call void @cqrt_free(i32 %314)
  %331 = call i32 @cqrt_pop()
  switch i32 %331, label %372 [
    i32 1, label %312
  ]

332:                                              ; preds = %399, %372
  %333 = call i32 @cqrt_pop()
  %334 = call i32 @cqrt_pop()
  %335 = call i32 @cqrt_pop()
  %336 = call i32 @cqrt_pop()
  %337 = call i32 @cqrt_pop()
  %338 = call i32 @cqrt_pop()
  %339 = call i32 @cqrt_pop()
  %340 = call i32 @cqrt_pop()
  %341 = call i32 @cqrt_pop()
  %342 = call i32 @cqrt_pop()
  %343 = zext i32 %342 to i64
  %344 = shl i64 %343, 32
  %345 = or i64 0, %344
  %346 = call i32 @cqrt_pop()
  %347 = zext i32 %346 to i64
  %348 = or i64 %345, %347
  %349 = call i32 @cqrt_pop()
  %350 = call i32 @cqrt_pop()
  %351 = call i32 @cqrt_pop()
  %352 = call i32 @cqrt_pop()
  %353 = call i32 @cqrt_pop()
  %354 = call i32 @cqrt_pop()
  %355 = call i32 @cqrt_pop()
  %356 = call i32 @cqrt_pop()
  %357 = call i32 @cqrt_pop()
  %358 = call i32 @cqrt_pop()
  %359 = call i32 @cqrt_pop()
  %360 = call i32 @cqrt_pop()
  %361 = call i32 @cqrt_pop()
  %362 = call i32 @cqrt_pop()
  %363 = call i32 @cqrt_pop()
  %364 = call i32 @cqrt_pop()
  %365 = call i32 @cqrt_pop()
  %366 = call i32 @cqrt_pop()
  %367 = call i32 @cqrt_pop()
  %368 = call i32 @cqrt_pop()
  %369 = call i32 @cqrt_pop()
  %370 = call i32 @cqrt_pop()
  %371 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %371, i32 %370, i32 %369, i32 %368)
  call void @cqrt_free(i32 %371)
  call void @cq_template_add_i64_unc(i32 %369, i32 %367, i32 %366)
  call void @cqrt_free(i32 %369)
  call void @cq_template_select_i64_unc(i32 %367, i32 %365, i32 %364, i32 %363)
  call void @cqrt_free(i32 %367)
  call void @cq_template_zext_i32_to_i64_unc(i32 %366, i32 %362)
  call void @cqrt_free(i32 %366)
  call void @cq_template_add_i32_unc(i32 %362, i32 %361, i32 %360)
  call void @cqrt_free(i32 %362)
  call void @cq_template_select_i32_hl_unc(i32 %361, i32 %365, i32 %359, i32 0)
  call void @cqrt_free(i32 %361)
  br label %385

372:                                              ; preds = %313
  %373 = call i32 @cqrt_pop()
  %374 = call i32 @cqrt_pop()
  %375 = call i32 @cqrt_pop()
  %376 = call i32 @cqrt_pop()
  %377 = call i32 @cqrt_pop()
  %378 = call i32 @cqrt_pop()
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  %381 = call i32 @cqrt_pop()
  %382 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %382, i32 %381, i32 %380)
  call void @cqrt_free(i32 %380)
  call void @cqrt_xor_i1(i32 %379, i32 %381)
  call void @cqrt_not_i1(i32 %381)
  call void @cqrt_free(i32 %381)
  call void @cq_template_select_i64_unc(i32 %378, i32 %377, i32 %376, i32 %375)
  call void @cqrt_free(i32 %378)
  call void @cqrt_and_i1(i32 %382, i32 %379, i32 %377)
  call void @cqrt_free(i32 %377)
  call void @cqrt_free(i32 %376)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %379, i32 %374, i64 5)
  call void @cqrt_free(i32 %379)
  call void @cq_template_add_i64_hl_unc(i32 %374, i32 %373, i64 1)
  call void @cqrt_free(i32 %374)
  br label %332

383:                                              ; preds = %251
  call void @cqrt_copy_i64(i32 %72, i32 %123)
  call void @cqrt_free(i32 %123)
  br label %399

384:                                              ; preds = %385
  call void @cqrt_free(i32 %358)
  call void @cqrt_free(i32 %357)
  call void @cqrt_and_i1(i32 %356, i32 %355, i32 %354)
  call void @cqrt_free(i32 %354)
  call void @cqrt_and_i1(i32 %0, i32 %353, i32 %355)
  call void @cqrt_free(i32 %355)
  call void @cqrt_and_i1(i32 %365, i32 %352, i32 %353)
  call void @cqrt_free(i32 %353)
  call void @cqrt_and_i1(i32 %351, i32 %350, i32 %352)
  call void @cqrt_xor_i1(i32 %351, i32 %352)
  call void @cqrt_free(i32 %352)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %351)
  call void @cqrt_free(i32 %351)
  call void @cq_template_add_i64_hl_unc(i32 %349, i32 %22, i64 %348)
  call void @cqrt_free(i32 %349)
  call void @cqrt_and_i1(i32 %341, i32 %340, i32 %339)
  call void @cqrt_free(i32 %339)
  call void @cqrt_and_i1(i32 %338, i32 %337, i32 %340)
  call void @cqrt_free(i32 %340)
  call void @cqrt_xor_i1(i32 %350, i32 %337)
  call void @cqrt_not_i1(i32 %337)
  call void @cqrt_free(i32 %337)
  call void @cqrt_and_i1(i32 %341, i32 %336, i32 %370)
  call void @cqrt_free(i32 %370)
  call void @cqrt_and_i1(i32 %335, i32 %338, i32 %336)
  call void @cqrt_xor_i1(i32 %335, i32 %336)
  call void @cqrt_free(i32 %336)
  call void @cqrt_xor_i1(i32 %350, i32 %335)
  call void @cqrt_not_i1(i32 %335)
  call void @cqrt_free(i32 %335)
  call void @cq_template_shl_i32_hl_unc(i32 %360, i32 %334, i32 6)
  call void @cqrt_free(i32 %360)
  call void @cqrt_free(i32 %333)
  br label %313

385:                                              ; preds = %332, %385
  %386 = call i32 @cqrt_pop()
  %387 = call i32 @cqrt_pop()
  %388 = call i32 @cqrt_pop()
  %389 = call i32 @cqrt_pop()
  %390 = call i32 @cqrt_pop()
  %391 = call i32 @cqrt_pop()
  %392 = call i32 @cqrt_pop()
  %393 = call i32 @cqrt_pop()
  %394 = call i32 @cqrt_pop()
  %395 = call i32 @cqrt_pop()
  %396 = call i32 @cqrt_pop()
  %397 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %397, i32 %396, i32 %395)
  call void @cqrt_free(i32 %395)
  call void @cq_template_select_i64_unc(i32 %394, i32 %397, i32 %393, i32 %392)
  call void @cqrt_free(i32 %394)
  call void @cq_template_select_i32_lh_unc(i32 %391, i32 %397, i32 %390, i32 %389)
  call void @cqrt_free(i32 %391)
  call void @cq_template_select_i64_unc(i32 %388, i32 %397, i32 %387, i32 %386)
  call void @cqrt_free(i32 %388)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %396, i32 %393, i64 0)
  call void @cqrt_free(i32 %396)
  call void @cq_template_and_i64_hl_unc(i32 %393, i32 %387, i64 255)
  call void @cqrt_free(i32 %393)
  call void @cq_template_lshr_i64_hl_unc(i32 %387, i32 %386, i64 8)
  call void @cqrt_free(i32 %387)
  %398 = call i32 @cqrt_pop()
  switch i32 %398, label %385 [
    i32 1, label %384
  ]

399:                                              ; preds = %383
  switch i32 %67, label %312 [
    i32 1, label %332
  ]

400:                                              ; preds = %5
  %401 = call i32 @cqrt_alloc_i64(i64 0)
  %402 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %402)
  call void @cqrt_push(i32 0)
  call void @cqrt_push(i32 0)
  %403 = load i32, ptr @__cq_act_f, align 4
  %404 = add i32 %403, -1
  store i32 %404, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %401
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
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 -1)
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %12 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 ptrtoint (ptr @limbs to i64))
  %14 = call i32 @cqrt_qram_load_i64(i32 %8, i32 %13)
  %15 = call i32 @cq_template_icmp_eq_i64_hl(i32 %14, i64 -1)
  %16 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  br label %18

18:                                               ; preds = %4
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %19)
  %20 = call i32 @cqrt_alloc_i64(i64 0)
  %21 = call i32 @cq_template_add_i64_hl(i32 %17, i64 1)
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %21, i64 5)
  %23 = call i32 @cqrt_alloc_i64(i64 320)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %22, i32 %24)
  %25 = call i32 @cq_template_select_i64(i32 %24, i32 %23, i32 %20)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_xor_i1(i32 %22, i32 %26)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %19, i32 %26, i32 %27)
  %28 = call i32 @llvm.umin.i32(i32 %3, i32 5)
  %29 = icmp ult i32 %3, 5
  %30 = icmp ult i32 0, %28
  br i1 %30, label %31, label %58

31:                                               ; preds = %98, %18
  %from11 = phi i32 [ 0, %98 ], [ 1, %18 ]
  %32 = phi i32 [ 0, %18 ], [ %93, %98 ]
  %33 = phi i32 [ %27, %18 ], [ %105, %98 ]
  %34 = phi i64 [ 0, %18 ], [ %91, %98 ]
  %35 = phi i32 [ %21, %18 ], [ %99, %98 ]
  %36 = phi i32 [ %22, %18 ], [ %100, %98 ]
  %37 = phi i32 [ %25, %18 ], [ %103, %98 ]
  call void @cqrt_push(i32 %from11)
  %38 = call i32 @cq_template_mul_i64_hl(i32 %35, i64 8)
  %39 = call i32 @cq_template_add_i64_hl(i32 %38, i64 ptrtoint (ptr @limbs to i64))
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %40)
  call void @cqrt_xor_i1(i32 %36, i32 %40)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %40, i32 %41)
  %42 = call i32 @cqrt_qram_load_i64_controlled(i32 %41, i32 %8, i32 %39)
  %43 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 -1)
  %44 = call i32 @cq_template_trunc_i64_to_i32(i32 %35)
  %45 = call i32 @cq_template_xor_i64_hl(i32 %42, i64 -1)
  %46 = call i32 @cq_template_and_i64_hl(i32 %45, i64 255)
  %47 = call i32 @cq_template_icmp_eq_i64_hl(i32 %46, i64 0)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %50)
  call void @cqrt_xor_i1(i32 %36, i32 %50)
  call void @cqrt_and_i1(i32 %47, i32 %50, i32 %49)
  call void @cqrt_xor_i1(i32 %49, i32 %48)
  call void @cqrt_and_i1(i32 %49, i32 %43, i32 %48)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %48, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %54)
  call void @cqrt_xor_i1(i32 %54, i32 %53)
  call void @cqrt_and_i1(i32 %54, i32 %36, i32 %53)
  call void @cqrt_and_i1(i32 %47, i32 %53, i32 %52)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %52, i32 %55)
  %56 = call i32 @cqrt_alloc_i32(i32 0)
  %57 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %38)
  br label %62

58:                                               ; preds = %76, %18
  %59 = phi i32 [ 0, %18 ], [ 1, %76 ]
  %60 = phi i32 [ %25, %18 ], [ %87, %76 ]
  br i1 %29, label %106, label %107

61:                                               ; preds = %62
  br label %75

62:                                               ; preds = %62, %31
  %from10 = phi i32 [ 0, %62 ], [ 1, %31 ]
  %63 = phi i32 [ 0, %31 ], [ %66, %62 ]
  %64 = phi i32 [ %45, %31 ], [ %70, %62 ]
  %trip = phi i32 [ %55, %31 ], [ %74, %62 ]
  %cap = phi i32 [ %56, %31 ], [ %71, %62 ]
  %cap1 = phi i32 [ %57, %31 ], [ %72, %62 ]
  call void @cqrt_push(i32 %from10)
  %65 = call i32 @cq_template_lshr_i64_hl(i32 %64, i64 8)
  %66 = add nuw nsw i32 %63, 8
  %67 = call i32 @cq_template_and_i64_hl(i32 %65, i64 255)
  %68 = call i32 @cq_template_icmp_eq_i64_hl(i32 %67, i64 0)
  %69 = icmp ult i32 %63, 48
  %70 = call i32 @cq_template_select_i64(i32 %trip, i32 %65, i32 %64)
  %71 = call i32 @cq_template_select_i32_lh(i32 %trip, i32 %66, i32 %cap)
  %72 = call i32 @cq_template_select_i64(i32 %trip, i32 %67, i32 %cap1)
  %73 = xor i1 %69, true
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %68, i32 %74)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %cap1)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %cap)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %64)
  br i1 %73, label %61, label %62

75:                                               ; preds = %61
  br label %76

76:                                               ; preds = %75
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cq_template_select_i32_hl(i32 %47, i32 %71, i32 0)
  %79 = call i32 @cq_template_select_i64(i32 %47, i32 %72, i32 %46)
  %80 = call i32 @cq_template_shl_i32_hl(i32 %44, i32 6)
  %81 = call i32 @cq_template_add_i32(i32 %78, i32 %80)
  %82 = call i32 @cq_template_zext_i32_to_i64(i32 %81)
  %83 = call i32 @cq_template_add_i64(i32 %79, i32 %82)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %85)
  call void @cqrt_xor_i1(i32 %36, i32 %85)
  call void @cqrt_xor_i1(i32 %85, i32 %84)
  call void @cqrt_and_i1(i32 %85, i32 %43, i32 %84)
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %84, i32 %86)
  %87 = call i32 @cq_template_select_i64(i32 %86, i32 %83, i32 %37)
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %89)
  call void @cqrt_xor_i1(i32 %36, i32 %89)
  call void @cqrt_and_i1(i32 %43, i32 %89, i32 %88)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %88, i32 %90)
  %91 = add i64 %34, 1
  %92 = call i32 @cq_template_add_i64_hl(i32 %17, i64 %91)
  %93 = add i32 %32, 1
  %94 = icmp ult i32 %93, %28
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %92)
  %95 = trunc i64 %91 to i32
  call void @cqrt_push(i32 %95)
  %96 = lshr i64 %91, 32
  %97 = trunc i64 %96 to i32
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %77)
  br i1 %94, label %98, label %58

98:                                               ; preds = %76
  %99 = call i32 @cq_template_add_i64_hl(i32 %92, i64 1)
  %100 = call i32 @cq_template_icmp_eq_i64_hl(i32 %99, i64 5)
  %101 = call i32 @cqrt_alloc_i64(i64 320)
  %102 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %90, i32 %100, i32 %102)
  %103 = call i32 @cq_template_select_i64(i32 %102, i32 %101, i32 %87)
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %104)
  call void @cqrt_xor_i1(i32 %100, i32 %104)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %90, i32 %104, i32 %105)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %104)
  call void @cqrt_push(i32 %105)
  call void @cqrt_push(i32 %100)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %102)
  call void @cqrt_push(i32 %101)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %92)
  br label %31

106:                                              ; preds = %58
  br label %108

107:                                              ; preds = %58
  br label %108

108:                                              ; preds = %107, %106
  %109 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %60, i32 %109)
  br label %110

110:                                              ; preds = %108
  %111 = call i32 @cq_template_xor_i64_hl(i32 %14, i64 -1)
  %112 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 2)
  %113 = call i32 @cq_template_zext_i32_to_i64(i32 %112)
  %114 = call i32 @cq_template_and_i64(i32 %14, i32 %113)
  %115 = call i32 @cq_template_icmp_eq_i64_hl(i32 %114, i64 0)
  %116 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)
  %117 = call i32 @cq_template_zext_i32_to_i64(i32 %116)
  br label %118

118:                                              ; preds = %110
  %119 = call i32 @cqrt_alloc_i1(i1 false)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %120)
  call void @cqrt_xor_i1(i32 %10, i32 %120)
  call void @cqrt_and_i1(i32 %115, i32 %120, i32 %119)
  %121 = call i32 @cqrt_alloc_i32(i32 0)
  %122 = call i32 @cq_template_icmp_eq_i64_hl(i32 %117, i64 4)
  %123 = call i32 @cqrt_alloc_i32(i32 4)
  %124 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %119, i32 %122, i32 %124)
  %125 = call i32 @cq_template_select_i32(i32 %124, i32 %123, i32 %121)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_xor_i1(i32 %122, i32 %126)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %119, i32 %126, i32 %127)
  %128 = call i32 @llvm.umin.i32(i32 %3, i32 5)
  %129 = icmp ult i32 %3, 5
  %130 = icmp ult i32 0, %128
  br i1 %130, label %131, label %160

131:                                              ; preds = %163, %118
  %from5 = phi i32 [ 0, %163 ], [ 1, %118 ]
  %132 = phi i32 [ 0, %118 ], [ %155, %163 ]
  %133 = phi i32 [ %127, %118 ], [ %169, %163 ]
  %134 = phi i32 [ %117, %118 ], [ %154, %163 ]
  %135 = phi i64 [ 0, %118 ], [ %153, %163 ]
  %136 = phi i32 [ %122, %118 ], [ %164, %163 ]
  %137 = phi i32 [ %125, %118 ], [ %167, %163 ]
  call void @cqrt_push(i32 %from5)
  %138 = call i32 @cq_template_add_i64_hl(i32 %134, i64 1)
  %139 = call i32 @cq_template_mul_i64_hl(i32 %138, i64 8)
  %140 = call i32 @cq_template_add_i64_hl(i32 %139, i64 ptrtoint (ptr @limbs to i64))
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %141)
  call void @cqrt_xor_i1(i32 %136, i32 %141)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %141, i32 %142)
  %143 = call i32 @cqrt_qram_load_i64_controlled(i32 %142, i32 %8, i32 %140)
  %144 = call i32 @cq_template_icmp_eq_i64_hl(i32 %143, i64 0)
  %145 = call i32 @cq_template_trunc_i64_to_i32(i32 %134)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %147)
  call void @cqrt_xor_i1(i32 %136, i32 %147)
  call void @cqrt_xor_i1(i32 %147, i32 %146)
  call void @cqrt_and_i1(i32 %147, i32 %144, i32 %146)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %146, i32 %148)
  %149 = call i32 @cq_template_select_i32(i32 %148, i32 %145, i32 %137)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  %151 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %151)
  call void @cqrt_xor_i1(i32 %136, i32 %151)
  call void @cqrt_and_i1(i32 %144, i32 %151, i32 %150)
  %152 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %133, i32 %150, i32 %152)
  %153 = add i64 %135, 1
  %154 = call i32 @cq_template_add_i64_hl(i32 %117, i64 %153)
  %155 = add i32 %132, 1
  %156 = icmp ult i32 %155, %128
  call void @cqrt_push(i32 %154)
  %157 = trunc i64 %153 to i32
  call void @cqrt_push(i32 %157)
  %158 = lshr i64 %153, 32
  %159 = trunc i64 %158 to i32
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %144)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %136)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %137)
  call void @cqrt_push(i32 %146)
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %134)
  call void @cqrt_push(i32 %143)
  call void @cqrt_push(i32 %142)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %141)
  call void @cqrt_push(i32 %139)
  call void @cqrt_push(i32 %138)
  br i1 %156, label %163, label %160

160:                                              ; preds = %131, %118
  %161 = phi i32 [ 0, %118 ], [ 1, %131 ]
  %162 = phi i32 [ %125, %118 ], [ %149, %131 ]
  br i1 %129, label %170, label %171

163:                                              ; preds = %131
  %164 = call i32 @cq_template_icmp_eq_i64_hl(i32 %154, i64 4)
  %165 = call i32 @cqrt_alloc_i32(i32 4)
  %166 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %152, i32 %164, i32 %166)
  %167 = call i32 @cq_template_select_i32(i32 %166, i32 %165, i32 %149)
  %168 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %168)
  call void @cqrt_xor_i1(i32 %164, i32 %168)
  %169 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %152, i32 %168, i32 %169)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %168)
  call void @cqrt_push(i32 %169)
  call void @cqrt_push(i32 %164)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %165)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %154)
  br label %131

170:                                              ; preds = %160
  br label %172

171:                                              ; preds = %160
  br label %172

172:                                              ; preds = %171, %170
  %173 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %162, i32 %173)
  br label %174

174:                                              ; preds = %172
  %175 = call i32 @cq_template_add_i32_hl(i32 %173, i32 1)
  %176 = call i32 @cq_template_zext_i32_to_i64(i32 %175)
  %177 = call i32 @cq_template_mul_i64_hl(i32 %176, i64 8)
  %178 = call i32 @cq_template_add_i64_hl(i32 %177, i64 ptrtoint (ptr @limbs to i64))
  %179 = call i32 @cqrt_alloc_i1(i1 false)
  %180 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %180)
  call void @cqrt_xor_i1(i32 %10, i32 %180)
  call void @cqrt_and_i1(i32 %115, i32 %180, i32 %179)
  %181 = call i32 @cqrt_qram_load_i64_controlled(i32 %179, i32 %8, i32 %178)
  %182 = call i32 @cq_template_icmp_eq_i64_hl(i32 %181, i64 0)
  %183 = call i32 @cq_template_select_i64(i32 %115, i32 %181, i32 %114)
  %184 = call i32 @cq_template_select_i64(i32 %10, i32 %111, i32 %183)
  %185 = call i32 @cq_template_select_i32(i32 %115, i32 %173, i32 %9)
  %186 = call i32 @cq_template_select_i32(i32 %10, i32 %9, i32 %185)
  %187 = call i32 @cq_template_and_i64_hl(i32 %184, i64 255)
  %188 = call i32 @cq_template_icmp_eq_i64_hl(i32 %187, i64 0)
  br label %189

189:                                              ; preds = %174
  %190 = call i32 @cqrt_alloc_i1(i1 false)
  %191 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %191)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %191)
  %192 = call i32 @cqrt_alloc_i1(i1 false)
  %193 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %193)
  call void @cqrt_xor_i1(i32 %10, i32 %193)
  call void @cqrt_and_i1(i32 %115, i32 %193, i32 %192)
  call void @cqrt_and_i1(i32 %182, i32 %192, i32 %191)
  call void @cqrt_and_i1(i32 %188, i32 %191, i32 %190)
  %194 = call i32 @cqrt_alloc_i32(i32 0)
  %195 = call i32 @cqrt_alloc_i64(i64 0)
  br label %197

196:                                              ; preds = %197
  br label %210

197:                                              ; preds = %197, %189
  %from = phi i32 [ 0, %197 ], [ 1, %189 ]
  %198 = phi i32 [ 0, %189 ], [ %201, %197 ]
  %199 = phi i32 [ %184, %189 ], [ %205, %197 ]
  %trip2 = phi i32 [ %190, %189 ], [ %209, %197 ]
  %cap3 = phi i32 [ %194, %189 ], [ %206, %197 ]
  %cap4 = phi i32 [ %195, %189 ], [ %207, %197 ]
  call void @cqrt_push(i32 %from)
  %200 = call i32 @cq_template_lshr_i64_hl(i32 %199, i64 8)
  %201 = add nuw nsw i32 %198, 8
  %202 = call i32 @cq_template_and_i64_hl(i32 %200, i64 255)
  %203 = call i32 @cq_template_icmp_eq_i64_hl(i32 %202, i64 0)
  %204 = icmp ult i32 %198, 48
  %205 = call i32 @cq_template_select_i64(i32 %trip2, i32 %200, i32 %199)
  %206 = call i32 @cq_template_select_i32_lh(i32 %trip2, i32 %201, i32 %cap3)
  %207 = call i32 @cq_template_select_i64(i32 %trip2, i32 %202, i32 %cap4)
  %208 = xor i1 %204, true
  %209 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip2, i32 %203, i32 %209)
  call void @cqrt_push(i32 %trip2)
  call void @cqrt_push(i32 %203)
  call void @cqrt_push(i32 %209)
  call void @cqrt_push(i32 %207)
  call void @cqrt_push(i32 %202)
  call void @cqrt_push(i32 %cap4)
  call void @cqrt_push(i32 %206)
  call void @cqrt_push(i32 %201)
  call void @cqrt_push(i32 %cap3)
  call void @cqrt_push(i32 %205)
  call void @cqrt_push(i32 %200)
  call void @cqrt_push(i32 %199)
  br i1 %208, label %196, label %197

210:                                              ; preds = %196
  %211 = call i32 @cq_template_select_i32_hl(i32 %188, i32 %206, i32 0)
  %212 = call i32 @cq_template_select_i64(i32 %188, i32 %207, i32 %187)
  %213 = call i32 @cq_template_shl_i32_hl(i32 %186, i32 6)
  %214 = call i32 @cq_template_add_i32(i32 %211, i32 %213)
  %215 = call i32 @cq_template_zext_i32_to_i64(i32 %214)
  %216 = call i32 @cq_template_add_i64(i32 %212, i32 %215)
  %217 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %217)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %217)
  %218 = call i32 @cq_template_select_i64(i32 %217, i32 %216, i32 %109)
  %219 = call i32 @cqrt_alloc_i1(i1 false)
  %220 = call i32 @cqrt_alloc_i1(i1 false)
  %221 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %221)
  call void @cqrt_xor_i1(i32 %10, i32 %221)
  call void @cqrt_and_i1(i32 %115, i32 %221, i32 %220)
  call void @cqrt_and_i1(i32 %182, i32 %220, i32 %219)
  %222 = call i32 @cq_template_select_i64_lh(i32 %219, i64 -1, i32 %218)
  call void @cqrt_copy_i64(i32 %222, i32 %out)
  call void @cq_template_select_i64_lh_unc(i32 %222, i32 %219, i64 -1, i32 %218)
  call void @cqrt_free(i32 %222)
  call void @cqrt_and_i1(i32 %182, i32 %220, i32 %219)
  call void @cqrt_free(i32 %219)
  call void @cqrt_and_i1(i32 %115, i32 %221, i32 %220)
  call void @cqrt_free(i32 %220)
  call void @cqrt_xor_i1(i32 %10, i32 %221)
  call void @cqrt_not_i1(i32 %221)
  call void @cqrt_free(i32 %221)
  call void @cq_template_select_i64_unc(i32 %218, i32 %217, i32 %216, i32 %109)
  call void @cqrt_free(i32 %218)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %217)
  call void @cqrt_not_i1(i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cq_template_add_i64_unc(i32 %216, i32 %212, i32 %215)
  call void @cqrt_free(i32 %216)
  call void @cq_template_zext_i32_to_i64_unc(i32 %215, i32 %214)
  call void @cqrt_free(i32 %215)
  call void @cq_template_add_i32_unc(i32 %214, i32 %211, i32 %213)
  call void @cqrt_free(i32 %214)
  call void @cq_template_shl_i32_hl_unc(i32 %213, i32 %186, i32 6)
  call void @cqrt_free(i32 %213)
  call void @cq_template_select_i64_unc(i32 %212, i32 %188, i32 %207, i32 %187)
  call void @cqrt_free(i32 %212)
  call void @cq_template_select_i32_hl_unc(i32 %211, i32 %188, i32 %206, i32 0)
  call void @cqrt_free(i32 %211)
  br label %227

223:                                              ; preds = %226
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %188, i32 %187, i64 0)
  call void @cqrt_free(i32 %188)
  call void @cq_template_and_i64_hl_unc(i32 %187, i32 %184, i64 255)
  call void @cqrt_free(i32 %187)
  call void @cq_template_select_i32_unc(i32 %186, i32 %10, i32 %9, i32 %185)
  call void @cqrt_free(i32 %186)
  call void @cq_template_select_i32_unc(i32 %185, i32 %115, i32 %173, i32 %9)
  call void @cqrt_free(i32 %185)
  call void @cq_template_select_i64_unc(i32 %184, i32 %10, i32 %111, i32 %183)
  call void @cqrt_free(i32 %184)
  call void @cq_template_select_i64_unc(i32 %183, i32 %115, i32 %181, i32 %114)
  call void @cqrt_free(i32 %183)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %182, i32 %181, i64 0)
  call void @cqrt_free(i32 %182)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %181, i32 %179, i32 %8, i32 %178)
  call void @cqrt_free(i32 %181)
  call void @cqrt_and_i1(i32 %115, i32 %180, i32 %179)
  call void @cqrt_free(i32 %179)
  call void @cqrt_xor_i1(i32 %10, i32 %180)
  call void @cqrt_not_i1(i32 %180)
  call void @cqrt_free(i32 %180)
  call void @cq_template_add_i64_hl_unc(i32 %178, i32 %177, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %178)
  call void @cq_template_mul_i64_hl_unc(i32 %177, i32 %176, i64 8)
  call void @cqrt_free(i32 %177)
  call void @cq_template_zext_i32_to_i64_unc(i32 %176, i32 %175)
  call void @cqrt_free(i32 %176)
  call void @cq_template_add_i32_hl_unc(i32 %175, i32 %173, i32 1)
  call void @cqrt_free(i32 %175)
  br label %281

224:                                              ; preds = %241
  call void @cqrt_and_i1(i32 %119, i32 %126, i32 %127)
  call void @cqrt_free(i32 %127)
  call void @cqrt_xor_i1(i32 %122, i32 %126)
  call void @cqrt_not_i1(i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cq_template_select_i32_unc(i32 %125, i32 %124, i32 %123, i32 %121)
  call void @cqrt_free(i32 %125)
  call void @cqrt_and_i1(i32 %119, i32 %122, i32 %124)
  call void @cqrt_free(i32 %124)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %122, i32 %117, i64 4)
  call void @cqrt_free(i32 %122)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %115, i32 %120, i32 %119)
  call void @cqrt_free(i32 %119)
  call void @cqrt_xor_i1(i32 %10, i32 %120)
  call void @cqrt_not_i1(i32 %120)
  call void @cqrt_free(i32 %120)
  call void @cq_template_zext_i32_to_i64_unc(i32 %117, i32 %116)
  call void @cqrt_free(i32 %117)
  call void @cq_template_and_i32_hl_unc(i32 %116, i32 %6, i32 3)
  call void @cqrt_free(i32 %116)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %115, i32 %114, i64 0)
  call void @cqrt_free(i32 %115)
  call void @cq_template_and_i64_unc(i32 %114, i32 %14, i32 %113)
  call void @cqrt_free(i32 %114)
  call void @cq_template_zext_i32_to_i64_unc(i32 %113, i32 %112)
  call void @cqrt_free(i32 %113)
  call void @cq_template_lshr_i32_hl_unc(i32 %112, i32 %6, i32 2)
  call void @cqrt_free(i32 %112)
  call void @cq_template_xor_i64_hl_unc(i32 %111, i32 %14, i64 -1)
  call void @cqrt_free(i32 %111)
  br label %353

225:                                              ; preds = %283
  call void @cqrt_and_i1(i32 %19, i32 %26, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_xor_i1(i32 %22, i32 %26)
  call void @cqrt_not_i1(i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cq_template_select_i64_unc(i32 %25, i32 %24, i32 %23, i32 %20)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %19, i32 %22, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %22, i32 %21, i64 5)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %17, i64 1)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %20)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %6, i32 3)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %15, i32 %14, i64 -1)
  call void @cqrt_free(i32 %15)
  call void @cqrt_qram_load_i64_unc(i32 %14, i32 %8, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %13)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %11, i64 8)
  call void @cqrt_free(i32 %12)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %9)
  call void @cqrt_free(i32 %11)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %7, i32 -1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 3)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

226:                                              ; preds = %227
  call void @cqrt_free(i32 %195)
  call void @cqrt_free(i32 %194)
  call void @cqrt_and_i1(i32 %188, i32 %191, i32 %190)
  call void @cqrt_free(i32 %190)
  call void @cqrt_and_i1(i32 %182, i32 %192, i32 %191)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %191)
  call void @cqrt_not_i1(i32 %191)
  call void @cqrt_free(i32 %191)
  call void @cqrt_and_i1(i32 %115, i32 %193, i32 %192)
  call void @cqrt_free(i32 %192)
  call void @cqrt_xor_i1(i32 %10, i32 %193)
  call void @cqrt_not_i1(i32 %193)
  call void @cqrt_free(i32 %193)
  br label %223

227:                                              ; preds = %227, %210
  %228 = call i32 @cqrt_pop()
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  %233 = call i32 @cqrt_pop()
  %234 = call i32 @cqrt_pop()
  %235 = call i32 @cqrt_pop()
  %236 = call i32 @cqrt_pop()
  %237 = call i32 @cqrt_pop()
  %238 = call i32 @cqrt_pop()
  %239 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %239, i32 %238, i32 %237)
  call void @cqrt_free(i32 %237)
  call void @cq_template_select_i64_unc(i32 %236, i32 %239, i32 %235, i32 %234)
  call void @cqrt_free(i32 %236)
  call void @cq_template_select_i32_lh_unc(i32 %233, i32 %239, i32 %232, i32 %231)
  call void @cqrt_free(i32 %233)
  call void @cq_template_select_i64_unc(i32 %230, i32 %239, i32 %229, i32 %228)
  call void @cqrt_free(i32 %230)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %238, i32 %235, i64 0)
  call void @cqrt_free(i32 %238)
  call void @cq_template_and_i64_hl_unc(i32 %235, i32 %229, i64 255)
  call void @cqrt_free(i32 %235)
  call void @cq_template_lshr_i64_hl_unc(i32 %229, i32 %228, i64 8)
  call void @cqrt_free(i32 %229)
  %240 = call i32 @cqrt_pop()
  switch i32 %240, label %227 [
    i32 1, label %226
  ]

241:                                              ; preds = %282, %242
  br label %224

242:                                              ; preds = %282, %271
  %243 = call i32 @cqrt_pop()
  %244 = call i32 @cqrt_pop()
  %245 = call i32 @cqrt_pop()
  %246 = call i32 @cqrt_pop()
  %247 = call i32 @cqrt_pop()
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = call i32 @cqrt_pop()
  %251 = call i32 @cqrt_pop()
  %252 = call i32 @cqrt_pop()
  %253 = call i32 @cqrt_pop()
  %254 = call i32 @cqrt_pop()
  %255 = call i32 @cqrt_pop()
  %256 = call i32 @cqrt_pop()
  %257 = call i32 @cqrt_pop()
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = call i32 @cqrt_pop()
  %263 = zext i32 %262 to i64
  %264 = shl i64 %263, 32
  %265 = or i64 0, %264
  %266 = call i32 @cqrt_pop()
  %267 = zext i32 %266 to i64
  %268 = or i64 %265, %267
  %269 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %269, i32 %117, i64 %268)
  call void @cqrt_free(i32 %269)
  call void @cqrt_and_i1(i32 %261, i32 %260, i32 %259)
  call void @cqrt_free(i32 %259)
  call void @cqrt_and_i1(i32 %258, i32 %257, i32 %260)
  call void @cqrt_free(i32 %260)
  call void @cqrt_xor_i1(i32 %256, i32 %257)
  call void @cqrt_not_i1(i32 %257)
  call void @cqrt_free(i32 %257)
  call void @cq_template_select_i32_unc(i32 %255, i32 %254, i32 %253, i32 %252)
  call void @cqrt_free(i32 %255)
  call void @cqrt_and_i1(i32 %261, i32 %251, i32 %254)
  call void @cqrt_free(i32 %254)
  call void @cqrt_and_i1(i32 %250, i32 %258, i32 %251)
  call void @cqrt_xor_i1(i32 %250, i32 %251)
  call void @cqrt_free(i32 %251)
  call void @cqrt_xor_i1(i32 %256, i32 %250)
  call void @cqrt_not_i1(i32 %250)
  call void @cqrt_free(i32 %250)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %253, i32 %249)
  call void @cqrt_free(i32 %253)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %258, i32 %248, i64 0)
  call void @cqrt_free(i32 %258)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %248, i32 %247, i32 %8, i32 %246)
  call void @cqrt_free(i32 %248)
  call void @cqrt_and_i1(i32 %261, i32 %245, i32 %247)
  call void @cqrt_free(i32 %247)
  call void @cqrt_xor_i1(i32 %256, i32 %245)
  call void @cqrt_not_i1(i32 %245)
  call void @cqrt_free(i32 %245)
  call void @cq_template_add_i64_hl_unc(i32 %246, i32 %244, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %246)
  call void @cq_template_mul_i64_hl_unc(i32 %244, i32 %243, i64 8)
  call void @cqrt_free(i32 %244)
  call void @cq_template_add_i64_hl_unc(i32 %243, i32 %249, i64 1)
  call void @cqrt_free(i32 %243)
  %270 = call i32 @cqrt_pop()
  switch i32 %270, label %271 [
    i32 1, label %241
  ]

271:                                              ; preds = %242
  %272 = call i32 @cqrt_pop()
  %273 = call i32 @cqrt_pop()
  %274 = call i32 @cqrt_pop()
  %275 = call i32 @cqrt_pop()
  %276 = call i32 @cqrt_pop()
  %277 = call i32 @cqrt_pop()
  %278 = call i32 @cqrt_pop()
  %279 = call i32 @cqrt_pop()
  %280 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %280, i32 %279, i32 %278)
  call void @cqrt_free(i32 %278)
  call void @cqrt_xor_i1(i32 %277, i32 %279)
  call void @cqrt_not_i1(i32 %279)
  call void @cqrt_free(i32 %279)
  call void @cq_template_select_i32_unc(i32 %276, i32 %275, i32 %274, i32 %273)
  call void @cqrt_free(i32 %276)
  call void @cqrt_and_i1(i32 %280, i32 %277, i32 %275)
  call void @cqrt_free(i32 %275)
  call void @cqrt_free(i32 %274)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %277, i32 %272, i64 4)
  call void @cqrt_free(i32 %277)
  br label %242

281:                                              ; preds = %223
  call void @cqrt_copy_i32(i32 %162, i32 %173)
  call void @cqrt_free(i32 %173)
  br label %282

282:                                              ; preds = %281
  switch i32 %161, label %241 [
    i32 1, label %242
  ]

283:                                              ; preds = %369, %284
  br label %225

284:                                              ; preds = %354
  %285 = call i32 @cqrt_pop()
  %286 = call i32 @cqrt_pop()
  %287 = call i32 @cqrt_pop()
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = call i32 @cqrt_pop()
  %291 = call i32 @cqrt_pop()
  %292 = call i32 @cqrt_pop()
  %293 = call i32 @cqrt_pop()
  %294 = call i32 @cqrt_pop()
  %295 = call i32 @cqrt_pop()
  %296 = call i32 @cqrt_pop()
  %297 = call i32 @cqrt_pop()
  %298 = call i32 @cqrt_pop()
  %299 = call i32 @cqrt_pop()
  %300 = call i32 @cqrt_pop()
  %301 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %301, i32 %300, i32 %299)
  call void @cqrt_free(i32 %299)
  call void @cqrt_and_i1(i32 %298, i32 %297, i32 %300)
  call void @cqrt_xor_i1(i32 %298, i32 %300)
  call void @cqrt_free(i32 %300)
  call void @cqrt_and_i1(i32 %296, i32 %295, i32 %298)
  call void @cqrt_free(i32 %298)
  call void @cqrt_xor_i1(i32 %294, i32 %295)
  call void @cqrt_not_i1(i32 %295)
  call void @cqrt_free(i32 %295)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %296, i32 %293, i64 0)
  call void @cqrt_free(i32 %296)
  call void @cq_template_and_i64_hl_unc(i32 %293, i32 %292, i64 255)
  call void @cqrt_free(i32 %293)
  call void @cq_template_xor_i64_hl_unc(i32 %292, i32 %291, i64 -1)
  call void @cqrt_free(i32 %292)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %290, i32 %289)
  call void @cqrt_free(i32 %290)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %297, i32 %291, i64 -1)
  call void @cqrt_free(i32 %297)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %291, i32 %288, i32 %8, i32 %287)
  call void @cqrt_free(i32 %291)
  call void @cqrt_and_i1(i32 %301, i32 %286, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_xor_i1(i32 %294, i32 %286)
  call void @cqrt_not_i1(i32 %286)
  call void @cqrt_free(i32 %286)
  call void @cq_template_add_i64_hl_unc(i32 %287, i32 %285, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %287)
  call void @cq_template_mul_i64_hl_unc(i32 %285, i32 %289, i64 8)
  call void @cqrt_free(i32 %285)
  %302 = call i32 @cqrt_pop()
  switch i32 %302, label %342 [
    i32 1, label %283
  ]

303:                                              ; preds = %369, %342
  %304 = call i32 @cqrt_pop()
  %305 = call i32 @cqrt_pop()
  %306 = call i32 @cqrt_pop()
  %307 = call i32 @cqrt_pop()
  %308 = call i32 @cqrt_pop()
  %309 = call i32 @cqrt_pop()
  %310 = call i32 @cqrt_pop()
  %311 = call i32 @cqrt_pop()
  %312 = call i32 @cqrt_pop()
  %313 = call i32 @cqrt_pop()
  %314 = zext i32 %313 to i64
  %315 = shl i64 %314, 32
  %316 = or i64 0, %315
  %317 = call i32 @cqrt_pop()
  %318 = zext i32 %317 to i64
  %319 = or i64 %316, %318
  %320 = call i32 @cqrt_pop()
  %321 = call i32 @cqrt_pop()
  %322 = call i32 @cqrt_pop()
  %323 = call i32 @cqrt_pop()
  %324 = call i32 @cqrt_pop()
  %325 = call i32 @cqrt_pop()
  %326 = call i32 @cqrt_pop()
  %327 = call i32 @cqrt_pop()
  %328 = call i32 @cqrt_pop()
  %329 = call i32 @cqrt_pop()
  %330 = call i32 @cqrt_pop()
  %331 = call i32 @cqrt_pop()
  %332 = call i32 @cqrt_pop()
  %333 = call i32 @cqrt_pop()
  %334 = call i32 @cqrt_pop()
  %335 = call i32 @cqrt_pop()
  %336 = call i32 @cqrt_pop()
  %337 = call i32 @cqrt_pop()
  %338 = call i32 @cqrt_pop()
  %339 = call i32 @cqrt_pop()
  %340 = call i32 @cqrt_pop()
  %341 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %341, i32 %340, i32 %339, i32 %338)
  call void @cqrt_free(i32 %341)
  call void @cq_template_add_i64_unc(i32 %339, i32 %337, i32 %336)
  call void @cqrt_free(i32 %339)
  call void @cq_template_select_i64_unc(i32 %337, i32 %335, i32 %334, i32 %333)
  call void @cqrt_free(i32 %337)
  call void @cq_template_zext_i32_to_i64_unc(i32 %336, i32 %332)
  call void @cqrt_free(i32 %336)
  call void @cq_template_add_i32_unc(i32 %332, i32 %331, i32 %330)
  call void @cqrt_free(i32 %332)
  call void @cq_template_select_i32_hl_unc(i32 %331, i32 %335, i32 %329, i32 0)
  call void @cqrt_free(i32 %331)
  br label %355

342:                                              ; preds = %284
  %343 = call i32 @cqrt_pop()
  %344 = call i32 @cqrt_pop()
  %345 = call i32 @cqrt_pop()
  %346 = call i32 @cqrt_pop()
  %347 = call i32 @cqrt_pop()
  %348 = call i32 @cqrt_pop()
  %349 = call i32 @cqrt_pop()
  %350 = call i32 @cqrt_pop()
  %351 = call i32 @cqrt_pop()
  %352 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %352, i32 %351, i32 %350)
  call void @cqrt_free(i32 %350)
  call void @cqrt_xor_i1(i32 %349, i32 %351)
  call void @cqrt_not_i1(i32 %351)
  call void @cqrt_free(i32 %351)
  call void @cq_template_select_i64_unc(i32 %348, i32 %347, i32 %346, i32 %345)
  call void @cqrt_free(i32 %348)
  call void @cqrt_and_i1(i32 %352, i32 %349, i32 %347)
  call void @cqrt_free(i32 %347)
  call void @cqrt_free(i32 %346)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %349, i32 %344, i64 5)
  call void @cqrt_free(i32 %349)
  call void @cq_template_add_i64_hl_unc(i32 %344, i32 %343, i64 1)
  call void @cqrt_free(i32 %344)
  br label %303

353:                                              ; preds = %224
  call void @cqrt_copy_i64(i32 %60, i32 %109)
  call void @cqrt_free(i32 %109)
  br label %369

354:                                              ; preds = %355
  call void @cqrt_free(i32 %328)
  call void @cqrt_free(i32 %327)
  call void @cqrt_and_i1(i32 %326, i32 %325, i32 %324)
  call void @cqrt_free(i32 %324)
  call void @cqrt_and_i1(i32 %335, i32 %323, i32 %325)
  call void @cqrt_free(i32 %325)
  call void @cqrt_and_i1(i32 %322, i32 %321, i32 %323)
  call void @cqrt_xor_i1(i32 %322, i32 %323)
  call void @cqrt_free(i32 %323)
  call void @cqrt_and_i1(i32 %15, i32 %10, i32 %322)
  call void @cqrt_free(i32 %322)
  call void @cq_template_add_i64_hl_unc(i32 %320, i32 %17, i64 %319)
  call void @cqrt_free(i32 %320)
  call void @cqrt_and_i1(i32 %312, i32 %311, i32 %310)
  call void @cqrt_free(i32 %310)
  call void @cqrt_and_i1(i32 %309, i32 %308, i32 %311)
  call void @cqrt_free(i32 %311)
  call void @cqrt_xor_i1(i32 %321, i32 %308)
  call void @cqrt_not_i1(i32 %308)
  call void @cqrt_free(i32 %308)
  call void @cqrt_and_i1(i32 %312, i32 %307, i32 %340)
  call void @cqrt_free(i32 %340)
  call void @cqrt_and_i1(i32 %306, i32 %309, i32 %307)
  call void @cqrt_xor_i1(i32 %306, i32 %307)
  call void @cqrt_free(i32 %307)
  call void @cqrt_xor_i1(i32 %321, i32 %306)
  call void @cqrt_not_i1(i32 %306)
  call void @cqrt_free(i32 %306)
  call void @cq_template_shl_i32_hl_unc(i32 %330, i32 %305, i32 6)
  call void @cqrt_free(i32 %330)
  call void @cqrt_free(i32 %304)
  br label %284

355:                                              ; preds = %355, %303
  %356 = call i32 @cqrt_pop()
  %357 = call i32 @cqrt_pop()
  %358 = call i32 @cqrt_pop()
  %359 = call i32 @cqrt_pop()
  %360 = call i32 @cqrt_pop()
  %361 = call i32 @cqrt_pop()
  %362 = call i32 @cqrt_pop()
  %363 = call i32 @cqrt_pop()
  %364 = call i32 @cqrt_pop()
  %365 = call i32 @cqrt_pop()
  %366 = call i32 @cqrt_pop()
  %367 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %367, i32 %366, i32 %365)
  call void @cqrt_free(i32 %365)
  call void @cq_template_select_i64_unc(i32 %364, i32 %367, i32 %363, i32 %362)
  call void @cqrt_free(i32 %364)
  call void @cq_template_select_i32_lh_unc(i32 %361, i32 %367, i32 %360, i32 %359)
  call void @cqrt_free(i32 %361)
  call void @cq_template_select_i64_unc(i32 %358, i32 %367, i32 %357, i32 %356)
  call void @cqrt_free(i32 %358)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %366, i32 %363, i64 0)
  call void @cqrt_free(i32 %366)
  call void @cq_template_and_i64_hl_unc(i32 %363, i32 %357, i64 255)
  call void @cqrt_free(i32 %363)
  call void @cq_template_lshr_i64_hl_unc(i32 %357, i32 %356, i64 8)
  call void @cqrt_free(i32 %357)
  %368 = call i32 @cqrt_pop()
  switch i32 %368, label %355 [
    i32 1, label %354
  ]

369:                                              ; preds = %353
  switch i32 %59, label %283 [
    i32 1, label %303
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
  br i1 %11, label %12, label %387

12:                                               ; preds = %5
  %13 = call i32 @__cq_mem()
  %14 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)
  %15 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 -1)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %17 = call i32 @cq_template_mul_i64_hl(i32 %16, i64 8)
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 ptrtoint (ptr @limbs to i64))
  %19 = call i32 @cqrt_qram_load_i64_controlled(i32 %0, i32 %13, i32 %18)
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 -1)
  %21 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)
  br label %23

23:                                               ; preds = %12
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %25)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  %26 = call i32 @cqrt_alloc_i64(i64 0)
  %27 = call i32 @cq_template_add_i64_hl(i32 %22, i64 1)
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %27, i64 5)
  %29 = call i32 @cqrt_alloc_i64(i64 320)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %28, i32 %30)
  %31 = call i32 @cq_template_select_i64(i32 %30, i32 %29, i32 %26)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_xor_i1(i32 %28, i32 %32)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  %34 = call i32 @llvm.umin.i32(i32 %4, i32 5)
  %35 = icmp ult i32 %4, 5
  %36 = icmp ult i32 0, %34
  br i1 %36, label %37, label %65

37:                                               ; preds = %105, %23
  %from11 = phi i32 [ 0, %105 ], [ 1, %23 ]
  %38 = phi i32 [ 0, %23 ], [ %100, %105 ]
  %39 = phi i32 [ %33, %23 ], [ %112, %105 ]
  %40 = phi i64 [ 0, %23 ], [ %98, %105 ]
  %41 = phi i32 [ %27, %23 ], [ %106, %105 ]
  %42 = phi i32 [ %28, %23 ], [ %107, %105 ]
  %43 = phi i32 [ %31, %23 ], [ %110, %105 ]
  call void @cqrt_push(i32 %from11)
  %44 = call i32 @cq_template_mul_i64_hl(i32 %41, i64 8)
  %45 = call i32 @cq_template_add_i64_hl(i32 %44, i64 ptrtoint (ptr @limbs to i64))
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %46)
  call void @cqrt_xor_i1(i32 %42, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %46, i32 %47)
  %48 = call i32 @cqrt_qram_load_i64_controlled(i32 %47, i32 %13, i32 %45)
  %49 = call i32 @cq_template_icmp_eq_i64_hl(i32 %48, i64 -1)
  %50 = call i32 @cq_template_trunc_i64_to_i32(i32 %41)
  %51 = call i32 @cq_template_xor_i64_hl(i32 %48, i64 -1)
  %52 = call i32 @cq_template_and_i64_hl(i32 %51, i64 255)
  %53 = call i32 @cq_template_icmp_eq_i64_hl(i32 %52, i64 0)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %56)
  call void @cqrt_xor_i1(i32 %42, i32 %56)
  call void @cqrt_and_i1(i32 %53, i32 %56, i32 %55)
  call void @cqrt_xor_i1(i32 %55, i32 %54)
  call void @cqrt_and_i1(i32 %55, i32 %49, i32 %54)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %54, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %61)
  call void @cqrt_xor_i1(i32 %61, i32 %60)
  call void @cqrt_and_i1(i32 %61, i32 %42, i32 %60)
  call void @cqrt_and_i1(i32 %53, i32 %60, i32 %59)
  call void @cqrt_and_i1(i32 %0, i32 %59, i32 %58)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %57, i32 %58, i32 %62)
  %63 = call i32 @cqrt_alloc_i32(i32 0)
  %64 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %44)
  br label %69

65:                                               ; preds = %83, %23
  %66 = phi i32 [ 0, %23 ], [ 1, %83 ]
  %67 = phi i32 [ %31, %23 ], [ %94, %83 ]
  br i1 %35, label %113, label %114

68:                                               ; preds = %69
  br label %82

69:                                               ; preds = %69, %37
  %from10 = phi i32 [ 0, %69 ], [ 1, %37 ]
  %70 = phi i32 [ 0, %37 ], [ %73, %69 ]
  %71 = phi i32 [ %51, %37 ], [ %77, %69 ]
  %trip = phi i32 [ %62, %37 ], [ %81, %69 ]
  %cap = phi i32 [ %63, %37 ], [ %78, %69 ]
  %cap1 = phi i32 [ %64, %37 ], [ %79, %69 ]
  call void @cqrt_push(i32 %from10)
  %72 = call i32 @cq_template_lshr_i64_hl(i32 %71, i64 8)
  %73 = add nuw nsw i32 %70, 8
  %74 = call i32 @cq_template_and_i64_hl(i32 %72, i64 255)
  %75 = call i32 @cq_template_icmp_eq_i64_hl(i32 %74, i64 0)
  %76 = icmp ult i32 %70, 48
  %77 = call i32 @cq_template_select_i64(i32 %trip, i32 %72, i32 %71)
  %78 = call i32 @cq_template_select_i32_lh(i32 %trip, i32 %73, i32 %cap)
  %79 = call i32 @cq_template_select_i64(i32 %trip, i32 %74, i32 %cap1)
  %80 = xor i1 %76, true
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %75, i32 %81)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %cap1)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %cap)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %71)
  br i1 %80, label %68, label %69

82:                                               ; preds = %68
  br label %83

83:                                               ; preds = %82
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  %85 = call i32 @cq_template_select_i32_hl(i32 %53, i32 %78, i32 0)
  %86 = call i32 @cq_template_select_i64(i32 %53, i32 %79, i32 %52)
  %87 = call i32 @cq_template_shl_i32_hl(i32 %50, i32 6)
  %88 = call i32 @cq_template_add_i32(i32 %85, i32 %87)
  %89 = call i32 @cq_template_zext_i32_to_i64(i32 %88)
  %90 = call i32 @cq_template_add_i64(i32 %86, i32 %89)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %92)
  call void @cqrt_xor_i1(i32 %42, i32 %92)
  call void @cqrt_xor_i1(i32 %92, i32 %91)
  call void @cqrt_and_i1(i32 %92, i32 %49, i32 %91)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %91, i32 %93)
  %94 = call i32 @cq_template_select_i64(i32 %93, i32 %90, i32 %43)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  %96 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %96)
  call void @cqrt_xor_i1(i32 %42, i32 %96)
  call void @cqrt_and_i1(i32 %49, i32 %96, i32 %95)
  %97 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %95, i32 %97)
  %98 = add i64 %40, 1
  %99 = call i32 @cq_template_add_i64_hl(i32 %22, i64 %98)
  %100 = add i32 %38, 1
  %101 = icmp ult i32 %100, %34
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %99)
  %102 = trunc i64 %98 to i32
  call void @cqrt_push(i32 %102)
  %103 = lshr i64 %98, 32
  %104 = trunc i64 %103 to i32
  call void @cqrt_push(i32 %104)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %84)
  br i1 %101, label %105, label %65

105:                                              ; preds = %83
  %106 = call i32 @cq_template_add_i64_hl(i32 %99, i64 1)
  %107 = call i32 @cq_template_icmp_eq_i64_hl(i32 %106, i64 5)
  %108 = call i32 @cqrt_alloc_i64(i64 320)
  %109 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %97, i32 %107, i32 %109)
  %110 = call i32 @cq_template_select_i64(i32 %109, i32 %108, i32 %94)
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %111)
  call void @cqrt_xor_i1(i32 %107, i32 %111)
  %112 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %97, i32 %111, i32 %112)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %111)
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %107)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %109)
  call void @cqrt_push(i32 %108)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %106)
  call void @cqrt_push(i32 %99)
  br label %37

113:                                              ; preds = %65
  br label %115

114:                                              ; preds = %65
  br label %115

115:                                              ; preds = %114, %113
  %116 = call i32 @cqrt_alloc_i64(i64 0)
  call void @cqrt_copy_i64(i32 %67, i32 %116)
  br label %117

117:                                              ; preds = %115
  %118 = call i32 @cq_template_xor_i64_hl(i32 %19, i64 -1)
  %119 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 2)
  %120 = call i32 @cq_template_zext_i32_to_i64(i32 %119)
  %121 = call i32 @cq_template_and_i64(i32 %19, i32 %120)
  %122 = call i32 @cq_template_icmp_eq_i64_hl(i32 %121, i64 0)
  %123 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)
  %124 = call i32 @cq_template_zext_i32_to_i64(i32 %123)
  br label %125

125:                                              ; preds = %117
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %128)
  call void @cqrt_xor_i1(i32 %15, i32 %128)
  call void @cqrt_and_i1(i32 %122, i32 %128, i32 %127)
  call void @cqrt_and_i1(i32 %0, i32 %127, i32 %126)
  %129 = call i32 @cqrt_alloc_i32(i32 0)
  %130 = call i32 @cq_template_icmp_eq_i64_hl(i32 %124, i64 4)
  %131 = call i32 @cqrt_alloc_i32(i32 4)
  %132 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %126, i32 %130, i32 %132)
  %133 = call i32 @cq_template_select_i32(i32 %132, i32 %131, i32 %129)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %134)
  call void @cqrt_xor_i1(i32 %130, i32 %134)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %126, i32 %134, i32 %135)
  %136 = call i32 @llvm.umin.i32(i32 %4, i32 5)
  %137 = icmp ult i32 %4, 5
  %138 = icmp ult i32 0, %136
  br i1 %138, label %139, label %168

139:                                              ; preds = %171, %125
  %from5 = phi i32 [ 0, %171 ], [ 1, %125 ]
  %140 = phi i32 [ 0, %125 ], [ %163, %171 ]
  %141 = phi i32 [ %135, %125 ], [ %177, %171 ]
  %142 = phi i32 [ %124, %125 ], [ %162, %171 ]
  %143 = phi i64 [ 0, %125 ], [ %161, %171 ]
  %144 = phi i32 [ %130, %125 ], [ %172, %171 ]
  %145 = phi i32 [ %133, %125 ], [ %175, %171 ]
  call void @cqrt_push(i32 %from5)
  %146 = call i32 @cq_template_add_i64_hl(i32 %142, i64 1)
  %147 = call i32 @cq_template_mul_i64_hl(i32 %146, i64 8)
  %148 = call i32 @cq_template_add_i64_hl(i32 %147, i64 ptrtoint (ptr @limbs to i64))
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %149)
  call void @cqrt_xor_i1(i32 %144, i32 %149)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %141, i32 %149, i32 %150)
  %151 = call i32 @cqrt_qram_load_i64_controlled(i32 %150, i32 %13, i32 %148)
  %152 = call i32 @cq_template_icmp_eq_i64_hl(i32 %151, i64 0)
  %153 = call i32 @cq_template_trunc_i64_to_i32(i32 %142)
  %154 = call i32 @cqrt_alloc_i1(i1 false)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %155)
  call void @cqrt_xor_i1(i32 %144, i32 %155)
  call void @cqrt_xor_i1(i32 %155, i32 %154)
  call void @cqrt_and_i1(i32 %155, i32 %152, i32 %154)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %141, i32 %154, i32 %156)
  %157 = call i32 @cq_template_select_i32(i32 %156, i32 %153, i32 %145)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %159)
  call void @cqrt_xor_i1(i32 %144, i32 %159)
  call void @cqrt_and_i1(i32 %152, i32 %159, i32 %158)
  %160 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %141, i32 %158, i32 %160)
  %161 = add i64 %143, 1
  %162 = call i32 @cq_template_add_i64_hl(i32 %124, i64 %161)
  %163 = add i32 %140, 1
  %164 = icmp ult i32 %163, %136
  call void @cqrt_push(i32 %162)
  %165 = trunc i64 %161 to i32
  call void @cqrt_push(i32 %165)
  %166 = lshr i64 %161, 32
  %167 = trunc i64 %166 to i32
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %141)
  call void @cqrt_push(i32 %158)
  call void @cqrt_push(i32 %160)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %144)
  call void @cqrt_push(i32 %157)
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %153)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %154)
  call void @cqrt_push(i32 %155)
  call void @cqrt_push(i32 %142)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %146)
  br i1 %164, label %171, label %168

168:                                              ; preds = %139, %125
  %169 = phi i32 [ 0, %125 ], [ 1, %139 ]
  %170 = phi i32 [ %133, %125 ], [ %157, %139 ]
  br i1 %137, label %178, label %179

171:                                              ; preds = %139
  %172 = call i32 @cq_template_icmp_eq_i64_hl(i32 %162, i64 4)
  %173 = call i32 @cqrt_alloc_i32(i32 4)
  %174 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %160, i32 %172, i32 %174)
  %175 = call i32 @cq_template_select_i32(i32 %174, i32 %173, i32 %157)
  %176 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %176)
  call void @cqrt_xor_i1(i32 %172, i32 %176)
  %177 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %160, i32 %176, i32 %177)
  call void @cqrt_push(i32 %160)
  call void @cqrt_push(i32 %176)
  call void @cqrt_push(i32 %177)
  call void @cqrt_push(i32 %172)
  call void @cqrt_push(i32 %175)
  call void @cqrt_push(i32 %174)
  call void @cqrt_push(i32 %173)
  call void @cqrt_push(i32 %157)
  call void @cqrt_push(i32 %162)
  br label %139

178:                                              ; preds = %168
  br label %180

179:                                              ; preds = %168
  br label %180

180:                                              ; preds = %179, %178
  %181 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %170, i32 %181)
  br label %182

182:                                              ; preds = %180
  %183 = call i32 @cq_template_add_i32_hl(i32 %181, i32 1)
  %184 = call i32 @cq_template_zext_i32_to_i64(i32 %183)
  %185 = call i32 @cq_template_mul_i64_hl(i32 %184, i64 8)
  %186 = call i32 @cq_template_add_i64_hl(i32 %185, i64 ptrtoint (ptr @limbs to i64))
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  %188 = call i32 @cqrt_alloc_i1(i1 false)
  %189 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %189)
  call void @cqrt_xor_i1(i32 %15, i32 %189)
  call void @cqrt_and_i1(i32 %122, i32 %189, i32 %188)
  call void @cqrt_and_i1(i32 %0, i32 %188, i32 %187)
  %190 = call i32 @cqrt_qram_load_i64_controlled(i32 %187, i32 %13, i32 %186)
  %191 = call i32 @cq_template_icmp_eq_i64_hl(i32 %190, i64 0)
  %192 = call i32 @cq_template_select_i64(i32 %122, i32 %190, i32 %121)
  %193 = call i32 @cq_template_select_i64(i32 %15, i32 %118, i32 %192)
  %194 = call i32 @cq_template_select_i32(i32 %122, i32 %181, i32 %14)
  %195 = call i32 @cq_template_select_i32(i32 %15, i32 %14, i32 %194)
  %196 = call i32 @cq_template_and_i64_hl(i32 %193, i64 255)
  %197 = call i32 @cq_template_icmp_eq_i64_hl(i32 %196, i64 0)
  br label %198

198:                                              ; preds = %182
  %199 = call i32 @cqrt_alloc_i1(i1 false)
  %200 = call i32 @cqrt_alloc_i1(i1 false)
  %201 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %201)
  %202 = call i32 @cqrt_alloc_i1(i1 false)
  %203 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %203)
  call void @cqrt_xor_i1(i32 %15, i32 %203)
  call void @cqrt_and_i1(i32 %122, i32 %203, i32 %202)
  call void @cqrt_and_i1(i32 %191, i32 %202, i32 %201)
  call void @cqrt_and_i1(i32 %197, i32 %201, i32 %200)
  call void @cqrt_and_i1(i32 %0, i32 %200, i32 %199)
  %204 = call i32 @cqrt_alloc_i32(i32 0)
  %205 = call i32 @cqrt_alloc_i64(i64 0)
  br label %207

206:                                              ; preds = %207
  br label %220

207:                                              ; preds = %207, %198
  %from = phi i32 [ 0, %207 ], [ 1, %198 ]
  %208 = phi i32 [ 0, %198 ], [ %211, %207 ]
  %209 = phi i32 [ %193, %198 ], [ %215, %207 ]
  %trip2 = phi i32 [ %199, %198 ], [ %219, %207 ]
  %cap3 = phi i32 [ %204, %198 ], [ %216, %207 ]
  %cap4 = phi i32 [ %205, %198 ], [ %217, %207 ]
  call void @cqrt_push(i32 %from)
  %210 = call i32 @cq_template_lshr_i64_hl(i32 %209, i64 8)
  %211 = add nuw nsw i32 %208, 8
  %212 = call i32 @cq_template_and_i64_hl(i32 %210, i64 255)
  %213 = call i32 @cq_template_icmp_eq_i64_hl(i32 %212, i64 0)
  %214 = icmp ult i32 %208, 48
  %215 = call i32 @cq_template_select_i64(i32 %trip2, i32 %210, i32 %209)
  %216 = call i32 @cq_template_select_i32_lh(i32 %trip2, i32 %211, i32 %cap3)
  %217 = call i32 @cq_template_select_i64(i32 %trip2, i32 %212, i32 %cap4)
  %218 = xor i1 %214, true
  %219 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip2, i32 %213, i32 %219)
  call void @cqrt_push(i32 %trip2)
  call void @cqrt_push(i32 %213)
  call void @cqrt_push(i32 %219)
  call void @cqrt_push(i32 %217)
  call void @cqrt_push(i32 %212)
  call void @cqrt_push(i32 %cap4)
  call void @cqrt_push(i32 %216)
  call void @cqrt_push(i32 %211)
  call void @cqrt_push(i32 %cap3)
  call void @cqrt_push(i32 %215)
  call void @cqrt_push(i32 %210)
  call void @cqrt_push(i32 %209)
  br i1 %218, label %206, label %207

220:                                              ; preds = %206
  %221 = call i32 @cq_template_select_i32_hl(i32 %197, i32 %216, i32 0)
  %222 = call i32 @cq_template_select_i64(i32 %197, i32 %217, i32 %196)
  %223 = call i32 @cq_template_shl_i32_hl(i32 %195, i32 6)
  %224 = call i32 @cq_template_add_i32(i32 %221, i32 %223)
  %225 = call i32 @cq_template_zext_i32_to_i64(i32 %224)
  %226 = call i32 @cq_template_add_i64(i32 %222, i32 %225)
  %227 = call i32 @cqrt_alloc_i1(i1 false)
  %228 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %228)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %228)
  %229 = call i32 @cqrt_alloc_i1(i1 false)
  %230 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %230)
  call void @cqrt_xor_i1(i32 %15, i32 %230)
  call void @cqrt_and_i1(i32 %122, i32 %230, i32 %229)
  call void @cqrt_and_i1(i32 %191, i32 %229, i32 %228)
  call void @cqrt_and_i1(i32 %0, i32 %228, i32 %227)
  %231 = call i32 @cq_template_select_i64(i32 %227, i32 %226, i32 %116)
  %232 = call i32 @cqrt_alloc_i1(i1 false)
  %233 = call i32 @cqrt_alloc_i1(i1 false)
  %234 = call i32 @cqrt_alloc_i1(i1 false)
  %235 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %235)
  call void @cqrt_xor_i1(i32 %15, i32 %235)
  call void @cqrt_and_i1(i32 %122, i32 %235, i32 %234)
  call void @cqrt_and_i1(i32 %191, i32 %234, i32 %233)
  call void @cqrt_and_i1(i32 %0, i32 %233, i32 %232)
  %236 = call i32 @cq_template_select_i64_lh(i32 %232, i64 -1, i32 %231)
  call void @cqrt_copy_i64(i32 %236, i32 %out)
  call void @cq_template_select_i64_lh_unc(i32 %236, i32 %232, i64 -1, i32 %231)
  call void @cqrt_free(i32 %236)
  call void @cqrt_and_i1(i32 %0, i32 %233, i32 %232)
  call void @cqrt_free(i32 %232)
  call void @cqrt_and_i1(i32 %191, i32 %234, i32 %233)
  call void @cqrt_free(i32 %233)
  call void @cqrt_and_i1(i32 %122, i32 %235, i32 %234)
  call void @cqrt_free(i32 %234)
  call void @cqrt_xor_i1(i32 %15, i32 %235)
  call void @cqrt_not_i1(i32 %235)
  call void @cqrt_free(i32 %235)
  call void @cq_template_select_i64_unc(i32 %231, i32 %227, i32 %226, i32 %116)
  call void @cqrt_free(i32 %231)
  call void @cqrt_and_i1(i32 %0, i32 %228, i32 %227)
  call void @cqrt_free(i32 %227)
  call void @cqrt_and_i1(i32 %191, i32 %229, i32 %228)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %228)
  call void @cqrt_not_i1(i32 %228)
  call void @cqrt_free(i32 %228)
  call void @cqrt_and_i1(i32 %122, i32 %230, i32 %229)
  call void @cqrt_free(i32 %229)
  call void @cqrt_xor_i1(i32 %15, i32 %230)
  call void @cqrt_not_i1(i32 %230)
  call void @cqrt_free(i32 %230)
  call void @cq_template_add_i64_unc(i32 %226, i32 %222, i32 %225)
  call void @cqrt_free(i32 %226)
  call void @cq_template_zext_i32_to_i64_unc(i32 %225, i32 %224)
  call void @cqrt_free(i32 %225)
  call void @cq_template_add_i32_unc(i32 %224, i32 %221, i32 %223)
  call void @cqrt_free(i32 %224)
  call void @cq_template_shl_i32_hl_unc(i32 %223, i32 %195, i32 6)
  call void @cqrt_free(i32 %223)
  call void @cq_template_select_i64_unc(i32 %222, i32 %197, i32 %217, i32 %196)
  call void @cqrt_free(i32 %222)
  call void @cq_template_select_i32_hl_unc(i32 %221, i32 %197, i32 %216, i32 0)
  call void @cqrt_free(i32 %221)
  br label %243

237:                                              ; preds = %242
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %197, i32 %196, i64 0)
  call void @cqrt_free(i32 %197)
  call void @cq_template_and_i64_hl_unc(i32 %196, i32 %193, i64 255)
  call void @cqrt_free(i32 %196)
  call void @cq_template_select_i32_unc(i32 %195, i32 %15, i32 %14, i32 %194)
  call void @cqrt_free(i32 %195)
  call void @cq_template_select_i32_unc(i32 %194, i32 %122, i32 %181, i32 %14)
  call void @cqrt_free(i32 %194)
  call void @cq_template_select_i64_unc(i32 %193, i32 %15, i32 %118, i32 %192)
  call void @cqrt_free(i32 %193)
  call void @cq_template_select_i64_unc(i32 %192, i32 %122, i32 %190, i32 %121)
  call void @cqrt_free(i32 %192)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %191, i32 %190, i64 0)
  call void @cqrt_free(i32 %191)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %190, i32 %187, i32 %13, i32 %186)
  call void @cqrt_free(i32 %190)
  call void @cqrt_and_i1(i32 %0, i32 %188, i32 %187)
  call void @cqrt_free(i32 %187)
  call void @cqrt_and_i1(i32 %122, i32 %189, i32 %188)
  call void @cqrt_free(i32 %188)
  call void @cqrt_xor_i1(i32 %15, i32 %189)
  call void @cqrt_not_i1(i32 %189)
  call void @cqrt_free(i32 %189)
  call void @cq_template_add_i64_hl_unc(i32 %186, i32 %185, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %186)
  call void @cq_template_mul_i64_hl_unc(i32 %185, i32 %184, i64 8)
  call void @cqrt_free(i32 %185)
  call void @cq_template_zext_i32_to_i64_unc(i32 %184, i32 %183)
  call void @cqrt_free(i32 %184)
  call void @cq_template_add_i32_hl_unc(i32 %183, i32 %181, i32 1)
  call void @cqrt_free(i32 %183)
  br label %297

238:                                              ; preds = %257
  call void @cqrt_and_i1(i32 %126, i32 %134, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cqrt_xor_i1(i32 %130, i32 %134)
  call void @cqrt_not_i1(i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cq_template_select_i32_unc(i32 %133, i32 %132, i32 %131, i32 %129)
  call void @cqrt_free(i32 %133)
  call void @cqrt_and_i1(i32 %126, i32 %130, i32 %132)
  call void @cqrt_free(i32 %132)
  call void @cqrt_free(i32 %131)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %130, i32 %124, i64 4)
  call void @cqrt_free(i32 %130)
  call void @cqrt_free(i32 %129)
  call void @cqrt_and_i1(i32 %0, i32 %127, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cqrt_and_i1(i32 %122, i32 %128, i32 %127)
  call void @cqrt_free(i32 %127)
  call void @cqrt_xor_i1(i32 %15, i32 %128)
  call void @cqrt_not_i1(i32 %128)
  call void @cqrt_free(i32 %128)
  call void @cq_template_zext_i32_to_i64_unc(i32 %124, i32 %123)
  call void @cqrt_free(i32 %124)
  call void @cq_template_and_i32_hl_unc(i32 %123, i32 %7, i32 3)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %122, i32 %121, i64 0)
  call void @cqrt_free(i32 %122)
  call void @cq_template_and_i64_unc(i32 %121, i32 %19, i32 %120)
  call void @cqrt_free(i32 %121)
  call void @cq_template_zext_i32_to_i64_unc(i32 %120, i32 %119)
  call void @cqrt_free(i32 %120)
  call void @cq_template_lshr_i32_hl_unc(i32 %119, i32 %7, i32 2)
  call void @cqrt_free(i32 %119)
  call void @cq_template_xor_i64_hl_unc(i32 %118, i32 %19, i64 -1)
  call void @cqrt_free(i32 %118)
  br label %370

239:                                              ; preds = %299
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cqrt_xor_i1(i32 %28, i32 %32)
  call void @cqrt_not_i1(i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_select_i64_unc(i32 %31, i32 %30, i32 %29, i32 %26)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %24, i32 %28, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %28, i32 %27, i64 5)
  call void @cqrt_free(i32 %28)
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %22, i64 1)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %7, i32 3)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %20, i32 %19, i64 -1)
  call void @cqrt_free(i32 %20)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %19, i32 %0, i32 %13, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %18)
  call void @cq_template_mul_i64_hl_unc(i32 %17, i32 %16, i64 8)
  call void @cqrt_free(i32 %17)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %14)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %15, i32 %8, i32 -1)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %7, i32 3)
  call void @cqrt_free(i32 %14)
  %240 = load i32, ptr @__cq_act_f, align 4
  %241 = add i32 %240, -1
  store i32 %241, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %6, ptr @__cq_k, align 4
  ret void

242:                                              ; preds = %243
  call void @cqrt_free(i32 %205)
  call void @cqrt_free(i32 %204)
  call void @cqrt_and_i1(i32 %0, i32 %200, i32 %199)
  call void @cqrt_free(i32 %199)
  call void @cqrt_and_i1(i32 %197, i32 %201, i32 %200)
  call void @cqrt_free(i32 %200)
  call void @cqrt_and_i1(i32 %191, i32 %202, i32 %201)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %201)
  call void @cqrt_not_i1(i32 %201)
  call void @cqrt_free(i32 %201)
  call void @cqrt_and_i1(i32 %122, i32 %203, i32 %202)
  call void @cqrt_free(i32 %202)
  call void @cqrt_xor_i1(i32 %15, i32 %203)
  call void @cqrt_not_i1(i32 %203)
  call void @cqrt_free(i32 %203)
  br label %237

243:                                              ; preds = %243, %220
  %244 = call i32 @cqrt_pop()
  %245 = call i32 @cqrt_pop()
  %246 = call i32 @cqrt_pop()
  %247 = call i32 @cqrt_pop()
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = call i32 @cqrt_pop()
  %251 = call i32 @cqrt_pop()
  %252 = call i32 @cqrt_pop()
  %253 = call i32 @cqrt_pop()
  %254 = call i32 @cqrt_pop()
  %255 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %255, i32 %254, i32 %253)
  call void @cqrt_free(i32 %253)
  call void @cq_template_select_i64_unc(i32 %252, i32 %255, i32 %251, i32 %250)
  call void @cqrt_free(i32 %252)
  call void @cq_template_select_i32_lh_unc(i32 %249, i32 %255, i32 %248, i32 %247)
  call void @cqrt_free(i32 %249)
  call void @cq_template_select_i64_unc(i32 %246, i32 %255, i32 %245, i32 %244)
  call void @cqrt_free(i32 %246)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %254, i32 %251, i64 0)
  call void @cqrt_free(i32 %254)
  call void @cq_template_and_i64_hl_unc(i32 %251, i32 %245, i64 255)
  call void @cqrt_free(i32 %251)
  call void @cq_template_lshr_i64_hl_unc(i32 %245, i32 %244, i64 8)
  call void @cqrt_free(i32 %245)
  %256 = call i32 @cqrt_pop()
  switch i32 %256, label %243 [
    i32 1, label %242
  ]

257:                                              ; preds = %298, %258
  br label %238

258:                                              ; preds = %298, %287
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = call i32 @cqrt_pop()
  %263 = call i32 @cqrt_pop()
  %264 = call i32 @cqrt_pop()
  %265 = call i32 @cqrt_pop()
  %266 = call i32 @cqrt_pop()
  %267 = call i32 @cqrt_pop()
  %268 = call i32 @cqrt_pop()
  %269 = call i32 @cqrt_pop()
  %270 = call i32 @cqrt_pop()
  %271 = call i32 @cqrt_pop()
  %272 = call i32 @cqrt_pop()
  %273 = call i32 @cqrt_pop()
  %274 = call i32 @cqrt_pop()
  %275 = call i32 @cqrt_pop()
  %276 = call i32 @cqrt_pop()
  %277 = call i32 @cqrt_pop()
  %278 = call i32 @cqrt_pop()
  %279 = zext i32 %278 to i64
  %280 = shl i64 %279, 32
  %281 = or i64 0, %280
  %282 = call i32 @cqrt_pop()
  %283 = zext i32 %282 to i64
  %284 = or i64 %281, %283
  %285 = call i32 @cqrt_pop()
  call void @cq_template_add_i64_hl_unc(i32 %285, i32 %124, i64 %284)
  call void @cqrt_free(i32 %285)
  call void @cqrt_and_i1(i32 %277, i32 %276, i32 %275)
  call void @cqrt_free(i32 %275)
  call void @cqrt_and_i1(i32 %274, i32 %273, i32 %276)
  call void @cqrt_free(i32 %276)
  call void @cqrt_xor_i1(i32 %272, i32 %273)
  call void @cqrt_not_i1(i32 %273)
  call void @cqrt_free(i32 %273)
  call void @cq_template_select_i32_unc(i32 %271, i32 %270, i32 %269, i32 %268)
  call void @cqrt_free(i32 %271)
  call void @cqrt_and_i1(i32 %277, i32 %267, i32 %270)
  call void @cqrt_free(i32 %270)
  call void @cqrt_and_i1(i32 %266, i32 %274, i32 %267)
  call void @cqrt_xor_i1(i32 %266, i32 %267)
  call void @cqrt_free(i32 %267)
  call void @cqrt_xor_i1(i32 %272, i32 %266)
  call void @cqrt_not_i1(i32 %266)
  call void @cqrt_free(i32 %266)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %269, i32 %265)
  call void @cqrt_free(i32 %269)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %274, i32 %264, i64 0)
  call void @cqrt_free(i32 %274)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %264, i32 %263, i32 %13, i32 %262)
  call void @cqrt_free(i32 %264)
  call void @cqrt_and_i1(i32 %277, i32 %261, i32 %263)
  call void @cqrt_free(i32 %263)
  call void @cqrt_xor_i1(i32 %272, i32 %261)
  call void @cqrt_not_i1(i32 %261)
  call void @cqrt_free(i32 %261)
  call void @cq_template_add_i64_hl_unc(i32 %262, i32 %260, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %262)
  call void @cq_template_mul_i64_hl_unc(i32 %260, i32 %259, i64 8)
  call void @cqrt_free(i32 %260)
  call void @cq_template_add_i64_hl_unc(i32 %259, i32 %265, i64 1)
  call void @cqrt_free(i32 %259)
  %286 = call i32 @cqrt_pop()
  switch i32 %286, label %287 [
    i32 1, label %257
  ]

287:                                              ; preds = %258
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = call i32 @cqrt_pop()
  %291 = call i32 @cqrt_pop()
  %292 = call i32 @cqrt_pop()
  %293 = call i32 @cqrt_pop()
  %294 = call i32 @cqrt_pop()
  %295 = call i32 @cqrt_pop()
  %296 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %296, i32 %295, i32 %294)
  call void @cqrt_free(i32 %294)
  call void @cqrt_xor_i1(i32 %293, i32 %295)
  call void @cqrt_not_i1(i32 %295)
  call void @cqrt_free(i32 %295)
  call void @cq_template_select_i32_unc(i32 %292, i32 %291, i32 %290, i32 %289)
  call void @cqrt_free(i32 %292)
  call void @cqrt_and_i1(i32 %296, i32 %293, i32 %291)
  call void @cqrt_free(i32 %291)
  call void @cqrt_free(i32 %290)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %293, i32 %288, i64 4)
  call void @cqrt_free(i32 %293)
  br label %258

297:                                              ; preds = %237
  call void @cqrt_copy_i32(i32 %170, i32 %181)
  call void @cqrt_free(i32 %181)
  br label %298

298:                                              ; preds = %297
  switch i32 %169, label %257 [
    i32 1, label %258
  ]

299:                                              ; preds = %386, %300
  br label %239

300:                                              ; preds = %371
  %301 = call i32 @cqrt_pop()
  %302 = call i32 @cqrt_pop()
  %303 = call i32 @cqrt_pop()
  %304 = call i32 @cqrt_pop()
  %305 = call i32 @cqrt_pop()
  %306 = call i32 @cqrt_pop()
  %307 = call i32 @cqrt_pop()
  %308 = call i32 @cqrt_pop()
  %309 = call i32 @cqrt_pop()
  %310 = call i32 @cqrt_pop()
  %311 = call i32 @cqrt_pop()
  %312 = call i32 @cqrt_pop()
  %313 = call i32 @cqrt_pop()
  %314 = call i32 @cqrt_pop()
  %315 = call i32 @cqrt_pop()
  %316 = call i32 @cqrt_pop()
  %317 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %317, i32 %316, i32 %315)
  call void @cqrt_free(i32 %315)
  call void @cqrt_and_i1(i32 %314, i32 %313, i32 %316)
  call void @cqrt_xor_i1(i32 %314, i32 %316)
  call void @cqrt_free(i32 %316)
  call void @cqrt_and_i1(i32 %312, i32 %311, i32 %314)
  call void @cqrt_free(i32 %314)
  call void @cqrt_xor_i1(i32 %310, i32 %311)
  call void @cqrt_not_i1(i32 %311)
  call void @cqrt_free(i32 %311)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %312, i32 %309, i64 0)
  call void @cqrt_free(i32 %312)
  call void @cq_template_and_i64_hl_unc(i32 %309, i32 %308, i64 255)
  call void @cqrt_free(i32 %309)
  call void @cq_template_xor_i64_hl_unc(i32 %308, i32 %307, i64 -1)
  call void @cqrt_free(i32 %308)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %306, i32 %305)
  call void @cqrt_free(i32 %306)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %313, i32 %307, i64 -1)
  call void @cqrt_free(i32 %313)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %307, i32 %304, i32 %13, i32 %303)
  call void @cqrt_free(i32 %307)
  call void @cqrt_and_i1(i32 %317, i32 %302, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cqrt_xor_i1(i32 %310, i32 %302)
  call void @cqrt_not_i1(i32 %302)
  call void @cqrt_free(i32 %302)
  call void @cq_template_add_i64_hl_unc(i32 %303, i32 %301, i64 ptrtoint (ptr @limbs to i64))
  call void @cqrt_free(i32 %303)
  call void @cq_template_mul_i64_hl_unc(i32 %301, i32 %305, i64 8)
  call void @cqrt_free(i32 %301)
  %318 = call i32 @cqrt_pop()
  switch i32 %318, label %359 [
    i32 1, label %299
  ]

319:                                              ; preds = %386, %359
  %320 = call i32 @cqrt_pop()
  %321 = call i32 @cqrt_pop()
  %322 = call i32 @cqrt_pop()
  %323 = call i32 @cqrt_pop()
  %324 = call i32 @cqrt_pop()
  %325 = call i32 @cqrt_pop()
  %326 = call i32 @cqrt_pop()
  %327 = call i32 @cqrt_pop()
  %328 = call i32 @cqrt_pop()
  %329 = call i32 @cqrt_pop()
  %330 = zext i32 %329 to i64
  %331 = shl i64 %330, 32
  %332 = or i64 0, %331
  %333 = call i32 @cqrt_pop()
  %334 = zext i32 %333 to i64
  %335 = or i64 %332, %334
  %336 = call i32 @cqrt_pop()
  %337 = call i32 @cqrt_pop()
  %338 = call i32 @cqrt_pop()
  %339 = call i32 @cqrt_pop()
  %340 = call i32 @cqrt_pop()
  %341 = call i32 @cqrt_pop()
  %342 = call i32 @cqrt_pop()
  %343 = call i32 @cqrt_pop()
  %344 = call i32 @cqrt_pop()
  %345 = call i32 @cqrt_pop()
  %346 = call i32 @cqrt_pop()
  %347 = call i32 @cqrt_pop()
  %348 = call i32 @cqrt_pop()
  %349 = call i32 @cqrt_pop()
  %350 = call i32 @cqrt_pop()
  %351 = call i32 @cqrt_pop()
  %352 = call i32 @cqrt_pop()
  %353 = call i32 @cqrt_pop()
  %354 = call i32 @cqrt_pop()
  %355 = call i32 @cqrt_pop()
  %356 = call i32 @cqrt_pop()
  %357 = call i32 @cqrt_pop()
  %358 = call i32 @cqrt_pop()
  call void @cq_template_select_i64_unc(i32 %358, i32 %357, i32 %356, i32 %355)
  call void @cqrt_free(i32 %358)
  call void @cq_template_add_i64_unc(i32 %356, i32 %354, i32 %353)
  call void @cqrt_free(i32 %356)
  call void @cq_template_select_i64_unc(i32 %354, i32 %352, i32 %351, i32 %350)
  call void @cqrt_free(i32 %354)
  call void @cq_template_zext_i32_to_i64_unc(i32 %353, i32 %349)
  call void @cqrt_free(i32 %353)
  call void @cq_template_add_i32_unc(i32 %349, i32 %348, i32 %347)
  call void @cqrt_free(i32 %349)
  call void @cq_template_select_i32_hl_unc(i32 %348, i32 %352, i32 %346, i32 0)
  call void @cqrt_free(i32 %348)
  br label %372

359:                                              ; preds = %300
  %360 = call i32 @cqrt_pop()
  %361 = call i32 @cqrt_pop()
  %362 = call i32 @cqrt_pop()
  %363 = call i32 @cqrt_pop()
  %364 = call i32 @cqrt_pop()
  %365 = call i32 @cqrt_pop()
  %366 = call i32 @cqrt_pop()
  %367 = call i32 @cqrt_pop()
  %368 = call i32 @cqrt_pop()
  %369 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %369, i32 %368, i32 %367)
  call void @cqrt_free(i32 %367)
  call void @cqrt_xor_i1(i32 %366, i32 %368)
  call void @cqrt_not_i1(i32 %368)
  call void @cqrt_free(i32 %368)
  call void @cq_template_select_i64_unc(i32 %365, i32 %364, i32 %363, i32 %362)
  call void @cqrt_free(i32 %365)
  call void @cqrt_and_i1(i32 %369, i32 %366, i32 %364)
  call void @cqrt_free(i32 %364)
  call void @cqrt_free(i32 %363)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %366, i32 %361, i64 5)
  call void @cqrt_free(i32 %366)
  call void @cq_template_add_i64_hl_unc(i32 %361, i32 %360, i64 1)
  call void @cqrt_free(i32 %361)
  br label %319

370:                                              ; preds = %238
  call void @cqrt_copy_i64(i32 %67, i32 %116)
  call void @cqrt_free(i32 %116)
  br label %386

371:                                              ; preds = %372
  call void @cqrt_free(i32 %345)
  call void @cqrt_free(i32 %344)
  call void @cqrt_and_i1(i32 %343, i32 %342, i32 %341)
  call void @cqrt_free(i32 %341)
  call void @cqrt_and_i1(i32 %0, i32 %340, i32 %342)
  call void @cqrt_free(i32 %342)
  call void @cqrt_and_i1(i32 %352, i32 %339, i32 %340)
  call void @cqrt_free(i32 %340)
  call void @cqrt_and_i1(i32 %338, i32 %337, i32 %339)
  call void @cqrt_xor_i1(i32 %338, i32 %339)
  call void @cqrt_free(i32 %339)
  call void @cqrt_and_i1(i32 %20, i32 %15, i32 %338)
  call void @cqrt_free(i32 %338)
  call void @cq_template_add_i64_hl_unc(i32 %336, i32 %22, i64 %335)
  call void @cqrt_free(i32 %336)
  call void @cqrt_and_i1(i32 %328, i32 %327, i32 %326)
  call void @cqrt_free(i32 %326)
  call void @cqrt_and_i1(i32 %325, i32 %324, i32 %327)
  call void @cqrt_free(i32 %327)
  call void @cqrt_xor_i1(i32 %337, i32 %324)
  call void @cqrt_not_i1(i32 %324)
  call void @cqrt_free(i32 %324)
  call void @cqrt_and_i1(i32 %328, i32 %323, i32 %357)
  call void @cqrt_free(i32 %357)
  call void @cqrt_and_i1(i32 %322, i32 %325, i32 %323)
  call void @cqrt_xor_i1(i32 %322, i32 %323)
  call void @cqrt_free(i32 %323)
  call void @cqrt_xor_i1(i32 %337, i32 %322)
  call void @cqrt_not_i1(i32 %322)
  call void @cqrt_free(i32 %322)
  call void @cq_template_shl_i32_hl_unc(i32 %347, i32 %321, i32 6)
  call void @cqrt_free(i32 %347)
  call void @cqrt_free(i32 %320)
  br label %300

372:                                              ; preds = %372, %319
  %373 = call i32 @cqrt_pop()
  %374 = call i32 @cqrt_pop()
  %375 = call i32 @cqrt_pop()
  %376 = call i32 @cqrt_pop()
  %377 = call i32 @cqrt_pop()
  %378 = call i32 @cqrt_pop()
  %379 = call i32 @cqrt_pop()
  %380 = call i32 @cqrt_pop()
  %381 = call i32 @cqrt_pop()
  %382 = call i32 @cqrt_pop()
  %383 = call i32 @cqrt_pop()
  %384 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %384, i32 %383, i32 %382)
  call void @cqrt_free(i32 %382)
  call void @cq_template_select_i64_unc(i32 %381, i32 %384, i32 %380, i32 %379)
  call void @cqrt_free(i32 %381)
  call void @cq_template_select_i32_lh_unc(i32 %378, i32 %384, i32 %377, i32 %376)
  call void @cqrt_free(i32 %378)
  call void @cq_template_select_i64_unc(i32 %375, i32 %384, i32 %374, i32 %373)
  call void @cqrt_free(i32 %375)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %383, i32 %380, i64 0)
  call void @cqrt_free(i32 %383)
  call void @cq_template_and_i64_hl_unc(i32 %380, i32 %374, i64 255)
  call void @cqrt_free(i32 %380)
  call void @cq_template_lshr_i64_hl_unc(i32 %374, i32 %373, i64 8)
  call void @cqrt_free(i32 %374)
  %385 = call i32 @cqrt_pop()
  switch i32 %385, label %372 [
    i32 1, label %371
  ]

386:                                              ; preds = %370
  switch i32 %66, label %299 [
    i32 1, label %319
  ]

387:                                              ; preds = %5
  %388 = load i32, ptr @__cq_act_f, align 4
  %389 = add i32 %388, -1
  store i32 %389, ptr @__cq_act_f, align 4
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
