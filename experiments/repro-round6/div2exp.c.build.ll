; ModuleID = '<stdin>'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r6-novalue/div2exp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.mpz = type { i32, i32, ptr }

@limbs = global [4 x i64] [i64 0, i64 0, i64 5, i64 8], align 16
@zs = local_unnamed_addr global [2 x %struct.mpz] [%struct.mpz { i32 4, i32 3, ptr @limbs }, %struct.mpz { i32 4, i32 -2, ptr getelementptr (i8, ptr @limbs, i64 8) }], align 16
@__cq_act_g = internal global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [15 x i8] c"i32 (ptr, i64)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [23 x i8] c"i32 (i32, i32, double)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]
@__cq_k = internal global i32 -1, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @g(ptr noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @__cq_mem()
  %4 = lshr i64 %1, 6
  %5 = getelementptr inbounds i8, ptr %0, i64 4
  %6 = ptrtoint ptr %5 to i64
  %7 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %6)
  %8 = call i32 @cq_template_abs_i32(i32 %7)
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)
  %10 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %9, i64 %4)
  %11 = getelementptr inbounds i8, ptr %0, i64 8
  %12 = ptrtoint ptr %11 to i64
  %13 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %10, i32 %3, i64 %12)
  %14 = icmp ult i64 %1, 64
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  br i1 %14, label %16, label %19

16:                                               ; preds = %55, %2
  %17 = phi i32 [ %20, %55 ], [ poison, %2 ]
  %ran1 = phi i1 [ true, %55 ], [ false, %2 ]
  %18 = phi i32 [ %15, %2 ], [ %32, %55 ]
  br i1 %14, label %56, label %65

19:                                               ; preds = %2
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  br label %39

21:                                               ; preds = %22
  br label %55

22:                                               ; preds = %39
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %46, i32 %23)
  %24 = mul i64 %4, 8
  %25 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %24)
  %26 = call i32 @cqrt_qram_load_i64_controlled(i32 %23, i32 %3, i32 %25)
  %27 = and i64 %1, 63
  %28 = shl nsw i64 -1, %27
  %29 = xor i64 %28, -1
  %30 = call i32 @cq_template_and_i64_hl(i32 %26, i64 %29)
  %31 = call i32 @cq_template_icmp_eq_i64_hl(i32 %30, i64 0)
  %32 = call i32 @cq_template_select_i1(i32 %23, i32 %31, i32 %51)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %26)
  %33 = trunc i64 %29 to i32
  call void @cqrt_push(i32 %33)
  %34 = lshr i64 %29, 32
  %35 = trunc i64 %34 to i32
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %25)
  %36 = trunc i64 %24 to i32
  call void @cqrt_push(i32 %36)
  %37 = lshr i64 %24, 32
  %38 = trunc i64 %37 to i32
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %46)
  br label %21

39:                                               ; preds = %39, %19
  %from = phi i32 [ 0, %39 ], [ 1, %19 ]
  %40 = phi i64 [ 0, %19 ], [ %49, %39 ]
  %trip = phi i32 [ %10, %19 ], [ %46, %39 ]
  %xcap = phi i32 [ %20, %19 ], [ %51, %39 ]
  call void @cqrt_push(i32 %from)
  %41 = mul i64 %40, 8
  %42 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %41)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %10, i32 %43)
  %44 = call i32 @cqrt_qram_load_i64_controlled(i32 %43, i32 %3, i32 %42)
  %45 = call i32 @cq_template_icmp_eq_i64_hl(i32 %44, i64 0)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %47)
  call void @cqrt_and_i1(i32 %10, i32 %45, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %47, i32 %48)
  call void @cqrt_and_i1(i32 %trip, i32 %47, i32 %46)
  %49 = add nuw nsw i64 %40, 1
  %50 = icmp eq i64 %49, %4
  %51 = call i32 @cq_template_select_i1_lh(i32 %48, i1 false, i32 %xcap)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %42)
  %52 = trunc i64 %41 to i32
  call void @cqrt_push(i32 %52)
  %53 = lshr i64 %41, 32
  %54 = trunc i64 %53 to i32
  call void @cqrt_push(i32 %54)
  br i1 %50, label %22, label %39

55:                                               ; preds = %21
  br label %16

56:                                               ; preds = %16
  %57 = mul i64 %4, 8
  %58 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %57)
  %59 = call i32 @cqrt_qram_load_i64_controlled(i32 %10, i32 %3, i32 %58)
  %60 = and i64 %1, 63
  %61 = shl nsw i64 -1, %60
  %62 = xor i64 %61, -1
  %63 = call i32 @cq_template_and_i64_hl(i32 %59, i64 %62)
  %64 = call i32 @cq_template_icmp_eq_i64_hl(i32 %63, i64 0)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %64, i32 %63, i64 0)
  call void @cqrt_free(i32 %64)
  call void @cq_template_and_i64_hl_unc(i32 %63, i32 %59, i64 %62)
  call void @cqrt_free(i32 %63)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %59, i32 %10, i32 %3, i32 %58)
  call void @cqrt_free(i32 %59)
  call void @cq_template_add_i64_hl_unc(i32 %58, i32 %13, i64 %57)
  call void @cqrt_free(i32 %58)
  br label %65

65:                                               ; preds = %16, %56
  %66 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)
  %67 = call i32 @cq_template_select_i1(i32 %10, i32 %18, i32 %66)
  %68 = call i32 @cq_template_zext_i1_to_i32(i32 %67)
  call void @cq_template_select_i1_unc(i32 %67, i32 %10, i32 %18, i32 %66)
  call void @cqrt_free(i32 %67)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %66, i32 %7, i32 0)
  call void @cqrt_free(i32 %66)
  call void @cqrt_free(i32 %15)
  br i1 %ran1, label %90, label %113

69:                                               ; preds = %113
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %13, i32 %10, i32 %3, i64 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %10, i32 %9, i64 %4)
  call void @cqrt_free(i32 %10)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cq_template_abs_i32_unc(i32 %8, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cqrt_qram_load_i32_hl_unc(i32 %7, i32 %3, i64 %6)
  call void @cqrt_free(i32 %7)
  ret i32 %68

70:                                               ; preds = %71
  call void @cqrt_free(i32 %17)
  br label %113

71:                                               ; preds = %71, %90
  %72 = call i32 @cqrt_pop()
  %73 = zext i32 %72 to i64
  %74 = shl i64 %73, 32
  %75 = or i64 0, %74
  %76 = call i32 @cqrt_pop()
  %77 = zext i32 %76 to i64
  %78 = or i64 %75, %77
  %79 = call i32 @cqrt_pop()
  %80 = call i32 @cqrt_pop()
  %81 = call i32 @cqrt_pop()
  %82 = call i32 @cqrt_pop()
  %83 = call i32 @cqrt_pop()
  %84 = call i32 @cqrt_pop()
  %85 = call i32 @cqrt_pop()
  %86 = call i32 @cqrt_pop()
  %87 = call i32 @cqrt_pop()
  %88 = call i32 @cqrt_pop()
  call void @cq_template_select_i1_lh_unc(i32 %88, i32 %87, i1 false, i32 %86)
  call void @cqrt_free(i32 %88)
  call void @cqrt_and_i1(i32 %85, i32 %84, i32 %87)
  call void @cqrt_free(i32 %87)
  call void @cqrt_and_i1(i32 %85, i32 %84, i32 %83)
  call void @cqrt_xor_i1(i32 %85, i32 %83)
  call void @cqrt_free(i32 %83)
  call void @cqrt_and_i1(i32 %10, i32 %82, i32 %84)
  call void @cqrt_xor_i1(i32 %10, i32 %84)
  call void @cqrt_free(i32 %84)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %82, i32 %81, i64 0)
  call void @cqrt_free(i32 %82)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %81, i32 %80, i32 %3, i32 %79)
  call void @cqrt_free(i32 %81)
  call void @cqrt_and_i1(i32 %85, i32 %10, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cq_template_add_i64_hl_unc(i32 %79, i32 %13, i64 %78)
  call void @cqrt_free(i32 %79)
  %89 = call i32 @cqrt_pop()
  switch i32 %89, label %71 [
    i32 1, label %70
  ]

90:                                               ; preds = %65
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  %93 = zext i32 %92 to i64
  %94 = shl i64 %93, 32
  %95 = or i64 0, %94
  %96 = call i32 @cqrt_pop()
  %97 = zext i32 %96 to i64
  %98 = or i64 %95, %97
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
  call void @cq_template_select_i1_unc(i32 %112, i32 %111, i32 %110, i32 %109)
  call void @cqrt_free(i32 %112)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %110, i32 %108, i64 0)
  call void @cqrt_free(i32 %110)
  call void @cq_template_and_i64_hl_unc(i32 %108, i32 %107, i64 %106)
  call void @cqrt_free(i32 %108)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %107, i32 %111, i32 %3, i32 %99)
  call void @cqrt_free(i32 %107)
  call void @cq_template_add_i64_hl_unc(i32 %99, i32 %13, i64 %98)
  call void @cqrt_free(i32 %99)
  call void @cqrt_xor_i1(i32 %91, i32 %111)
  call void @cqrt_free(i32 %111)
  br label %71

113:                                              ; preds = %70, %65
  br label %69
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %5, double %2)
  %6 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %6, double %2)
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 16)
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 ptrtoint (ptr @zs to i64))
  %11 = call i32 @cq_template_and_i32_hl(i32 %6, i32 255)
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)
  %13 = call i32 @cq_template_lshr_i64_hl(i32 %12, i64 6)
  %14 = call i32 @cq_template_add_i64_hl(i32 %10, i64 4)
  %15 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %14)
  %16 = call i32 @cq_template_abs_i32(i32 %15)
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)
  %18 = call i32 @cq_template_icmp_ult_i64(i32 %13, i32 %17)
  %19 = call i32 @cq_template_add_i64_hl(i32 %10, i64 8)
  %20 = call i32 @cqrt_qram_load_i64_controlled(i32 %18, i32 %4, i32 %19)
  %21 = call i32 @cq_template_icmp_ult_i32_hl(i32 %11, i32 64)
  br label %22

22:                                               ; preds = %3
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %18, i32 %23)
  call void @cqrt_and_i1(i32 %18, i32 %21, i32 %23)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_qram_load_i64_controlled(i32 %23, i32 %4, i32 %20)
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %25, i64 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %23, i32 %28, i32 %29)
  %30 = call i32 @cq_template_select_i1(i32 %29, i32 %27, i32 %24)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %23, i32 %26, i32 %31)
  br label %32

32:                                               ; preds = %61, %22
  %from = phi i32 [ 0, %61 ], [ 1, %22 ]
  %33 = phi i32 [ 0, %22 ], [ %55, %61 ]
  %34 = phi i32 [ %31, %22 ], [ %70, %61 ]
  %35 = phi i64 [ 0, %22 ], [ %38, %61 ]
  %36 = phi i32 [ %26, %22 ], [ %65, %61 ]
  %37 = phi i32 [ %30, %22 ], [ %69, %61 ]
  call void @cqrt_push(i32 %from)
  %38 = add i64 %35, 1
  %39 = call i32 @cq_template_icmp_eq_i64_hl(i32 %13, i64 %38)
  %40 = call i32 @cq_template_mul_i64_hl(i32 %13, i64 8)
  %41 = call i32 @cq_template_add_i64(i32 %20, i32 %40)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %36, i32 %42)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %42, i32 %43)
  %44 = call i32 @cqrt_qram_load_i64_controlled(i32 %43, i32 %4, i32 %41)
  %45 = call i32 @cq_template_and_i64_hl(i32 %12, i64 63)
  %46 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %45)
  %47 = call i32 @cq_template_xor_i64_hl(i32 %46, i64 -1)
  %48 = call i32 @cq_template_and_i64(i32 %44, i32 %47)
  %49 = call i32 @cq_template_icmp_eq_i64_hl(i32 %48, i64 0)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %36, i32 %50)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %50, i32 %51)
  %52 = call i32 @cq_template_select_i1(i32 %51, i32 %49, i32 %37)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %36, i32 %53)
  call void @cqrt_and_i1(i32 %36, i32 %39, i32 %53)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %34, i32 %53, i32 %54)
  %55 = add i32 %33, 1
  %56 = icmp ult i32 %55, 3
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %40)
  %57 = trunc i64 %38 to i32
  call void @cqrt_push(i32 %57)
  %58 = lshr i64 %38, 32
  %59 = trunc i64 %58 to i32
  call void @cqrt_push(i32 %59)
  br i1 %56, label %61, label %60

60:                                               ; preds = %32
  br label %74

61:                                               ; preds = %32
  %62 = mul i64 %38, 8
  %63 = call i32 @cq_template_add_i64_hl(i32 %20, i64 %62)
  %64 = call i32 @cqrt_qram_load_i64_controlled(i32 %54, i32 %4, i32 %63)
  %65 = call i32 @cq_template_icmp_eq_i64_hl(i32 %64, i64 0)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %67)
  call void @cqrt_xor_i1(i32 %65, i32 %67)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %54, i32 %67, i32 %68)
  %69 = call i32 @cq_template_select_i1(i32 %68, i32 %66, i32 %52)
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %54, i32 %65, i32 %70)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %63)
  %71 = trunc i64 %62 to i32
  call void @cqrt_push(i32 %71)
  %72 = lshr i64 %62, 32
  %73 = trunc i64 %72 to i32
  call void @cqrt_push(i32 %73)
  br label %32

74:                                               ; preds = %60
  %75 = call i32 @cq_template_mul_i64_hl(i32 %13, i64 8)
  %76 = call i32 @cq_template_add_i64(i32 %20, i32 %75)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %21, i32 %18, i32 %77)
  %78 = call i32 @cqrt_qram_load_i64_controlled(i32 %77, i32 %4, i32 %76)
  %79 = call i32 @cq_template_and_i64_hl(i32 %12, i64 63)
  %80 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %79)
  %81 = call i32 @cq_template_xor_i64_hl(i32 %80, i64 -1)
  %82 = call i32 @cq_template_and_i64(i32 %78, i32 %81)
  %83 = call i32 @cq_template_icmp_eq_i64_hl(i32 %82, i64 0)
  %84 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %85 = call i32 @cq_template_select_i1(i32 %21, i32 %83, i32 %52)
  %86 = call i32 @cq_template_select_i1(i32 %18, i32 %85, i32 %84)
  %87 = call i32 @cq_template_zext_i1_to_i32(i32 %86)
  call void @cq_template_select_i1_unc(i32 %86, i32 %18, i32 %85, i32 %84)
  call void @cqrt_free(i32 %86)
  call void @cq_template_select_i1_unc(i32 %85, i32 %21, i32 %83, i32 %52)
  call void @cqrt_free(i32 %85)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %84, i32 %15, i32 0)
  call void @cqrt_free(i32 %84)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %83, i32 %82, i64 0)
  call void @cqrt_free(i32 %83)
  call void @cq_template_and_i64_unc(i32 %82, i32 %78, i32 %81)
  call void @cqrt_free(i32 %82)
  call void @cq_template_xor_i64_hl_unc(i32 %81, i32 %80, i64 -1)
  call void @cqrt_free(i32 %81)
  call void @cq_template_shl_i64_lh_unc(i32 %80, i64 -1, i32 %79)
  call void @cqrt_free(i32 %80)
  call void @cq_template_and_i64_hl_unc(i32 %79, i32 %12, i64 63)
  call void @cqrt_free(i32 %79)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %78, i32 %77, i32 %4, i32 %76)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %21, i32 %18, i32 %77)
  call void @cqrt_free(i32 %77)
  call void @cq_template_add_i64_unc(i32 %76, i32 %20, i32 %75)
  call void @cqrt_free(i32 %76)
  call void @cq_template_mul_i64_hl_unc(i32 %75, i32 %13, i64 8)
  call void @cqrt_free(i32 %75)
  br label %90

88:                                               ; preds = %89
  call void @cqrt_and_i1(i32 %23, i32 %26, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_select_i1_unc(i32 %30, i32 %29, i32 %27, i32 %24)
  call void @cqrt_free(i32 %30)
  call void @cqrt_and_i1(i32 %23, i32 %28, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_free(i32 %27)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %26, i32 %25, i64 0)
  call void @cqrt_free(i32 %26)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %25, i32 %23, i32 %4, i32 %20)
  call void @cqrt_free(i32 %25)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %18, i32 %21, i32 %23)
  call void @cqrt_xor_i1(i32 %18, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %21, i32 %11, i32 64)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %20, i32 %18, i32 %4, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %10, i64 8)
  call void @cqrt_free(i32 %19)
  call void @cq_template_icmp_ult_i64_unc(i32 %18, i32 %13, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_abs_i32_unc(i32 %16, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cqrt_qram_load_i32_unc(i32 %15, i32 %4, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_add_i64_hl_unc(i32 %14, i32 %10, i64 4)
  call void @cqrt_free(i32 %14)
  call void @cq_template_lshr_i64_hl_unc(i32 %13, i32 %12, i64 6)
  call void @cqrt_free(i32 %13)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)
  call void @cqrt_free(i32 %12)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %6, i32 255)
  call void @cqrt_free(i32 %11)
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 ptrtoint (ptr @zs to i64))
  call void @cqrt_free(i32 %10)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 16)
  call void @cqrt_free(i32 %9)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 1)
  call void @cqrt_free(i32 %7)
  ret i32 %87

89:                                               ; preds = %90
  br label %88

90:                                               ; preds = %74, %118
  %91 = call i32 @cqrt_pop()
  %92 = zext i32 %91 to i64
  %93 = shl i64 %92, 32
  %94 = or i64 0, %93
  %95 = call i32 @cqrt_pop()
  %96 = zext i32 %95 to i64
  %97 = or i64 %94, %96
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
  %110 = call i32 @cqrt_pop()
  %111 = call i32 @cqrt_pop()
  %112 = call i32 @cqrt_pop()
  %113 = call i32 @cqrt_pop()
  %114 = call i32 @cqrt_pop()
  %115 = call i32 @cqrt_pop()
  %116 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %116, i32 %115, i32 %114)
  call void @cqrt_free(i32 %114)
  call void @cqrt_and_i1(i32 %113, i32 %112, i32 %115)
  call void @cqrt_xor_i1(i32 %113, i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cq_template_select_i1_unc(i32 %111, i32 %110, i32 %109, i32 %108)
  call void @cqrt_free(i32 %111)
  call void @cqrt_and_i1(i32 %116, i32 %107, i32 %110)
  call void @cqrt_free(i32 %110)
  call void @cqrt_and_i1(i32 %112, i32 %113, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %109, i32 %106, i64 0)
  call void @cqrt_free(i32 %109)
  call void @cq_template_and_i64_unc(i32 %106, i32 %105, i32 %104)
  call void @cqrt_free(i32 %106)
  call void @cq_template_xor_i64_hl_unc(i32 %104, i32 %103, i64 -1)
  call void @cqrt_free(i32 %104)
  call void @cq_template_shl_i64_lh_unc(i32 %103, i64 -1, i32 %102)
  call void @cqrt_free(i32 %103)
  call void @cq_template_and_i64_hl_unc(i32 %102, i32 %12, i64 63)
  call void @cqrt_free(i32 %102)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %105, i32 %101, i32 %4, i32 %100)
  call void @cqrt_free(i32 %105)
  call void @cqrt_and_i1(i32 %116, i32 %99, i32 %101)
  call void @cqrt_free(i32 %101)
  call void @cqrt_and_i1(i32 %112, i32 %113, i32 %99)
  call void @cqrt_free(i32 %99)
  call void @cq_template_add_i64_unc(i32 %100, i32 %20, i32 %98)
  call void @cqrt_free(i32 %100)
  call void @cq_template_mul_i64_hl_unc(i32 %98, i32 %13, i64 8)
  call void @cqrt_free(i32 %98)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %112, i32 %13, i64 %97)
  call void @cqrt_free(i32 %112)
  %117 = call i32 @cqrt_pop()
  switch i32 %117, label %118 [
    i32 1, label %89
  ]

118:                                              ; preds = %90
  %119 = call i32 @cqrt_pop()
  %120 = zext i32 %119 to i64
  %121 = shl i64 %120, 32
  %122 = or i64 0, %121
  %123 = call i32 @cqrt_pop()
  %124 = zext i32 %123 to i64
  %125 = or i64 %122, %124
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
  call void @cq_template_select_i1_unc(i32 %132, i32 %131, i32 %130, i32 %129)
  call void @cqrt_free(i32 %132)
  call void @cqrt_and_i1(i32 %135, i32 %128, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cqrt_xor_i1(i32 %134, i32 %128)
  call void @cqrt_not_i1(i32 %128)
  call void @cqrt_free(i32 %128)
  call void @cqrt_free(i32 %130)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %134, i32 %127, i64 0)
  call void @cqrt_free(i32 %134)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %127, i32 %135, i32 %4, i32 %126)
  call void @cqrt_free(i32 %127)
  call void @cq_template_add_i64_hl_unc(i32 %126, i32 %20, i64 %125)
  call void @cqrt_free(i32 %126)
  br label %90
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #1

declare i32 @__cq_mem()

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare i32 @cq_template_abs_i32(i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)

declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cq_template_select_i1_lh(i32, i1, i32)

declare i32 @cq_template_and_i64_hl(i32, i64)

declare i32 @cq_template_select_i1(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare void @cq_template_select_i1_unc(i32, i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_and_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_i1_lh_unc(i32, i32, i1, i32)

declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)

declare void @cq_template_icmp_ugt_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare void @cq_template_abs_i32_unc(i32, i32)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_g_11_t(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_lshr_i64_hl(i32 %1, i64 6)
  %7 = call i32 @cq_template_add_i64_hl(i32 %0, i64 4)
  %8 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %7)
  %9 = call i32 @cq_template_abs_i32(i32 %8)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_icmp_ult_i64(i32 %6, i32 %10)
  %12 = call i32 @cq_template_add_i64_hl(i32 %0, i64 8)
  %13 = call i32 @cqrt_qram_load_i64_controlled(i32 %11, i32 %5, i32 %12)
  %14 = call i32 @cq_template_icmp_ult_i64_hl(i32 %1, i64 64)
  br label %15

15:                                               ; preds = %3
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %11, i32 %16)
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %16)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_qram_load_i64_controlled(i32 %16, i32 %5, i32 %13)
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 0)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_xor_i1(i32 %19, i32 %21)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %22)
  %23 = call i32 @cq_template_select_i1(i32 %22, i32 %20, i32 %17)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %16, i32 %19, i32 %24)
  %25 = icmp ult i32 0, %2
  br i1 %25, label %26, label %54

26:                                               ; preds = %62, %15
  %from = phi i32 [ 0, %62 ], [ 1, %15 ]
  %27 = phi i32 [ 0, %15 ], [ %49, %62 ]
  %28 = phi i32 [ %24, %15 ], [ %71, %62 ]
  %29 = phi i64 [ 0, %15 ], [ %32, %62 ]
  %30 = phi i32 [ %19, %15 ], [ %66, %62 ]
  %31 = phi i32 [ %23, %15 ], [ %70, %62 ]
  call void @cqrt_push(i32 %from)
  %32 = add i64 %29, 1
  %33 = call i32 @cq_template_icmp_eq_i64_hl(i32 %6, i64 %32)
  %34 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %35 = call i32 @cq_template_add_i64(i32 %13, i32 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %30, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %36, i32 %37)
  %38 = call i32 @cqrt_qram_load_i64_controlled(i32 %37, i32 %5, i32 %35)
  %39 = call i32 @cq_template_and_i64_hl(i32 %1, i64 63)
  %40 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %39)
  %41 = call i32 @cq_template_xor_i64_hl(i32 %40, i64 -1)
  %42 = call i32 @cq_template_and_i64(i32 %38, i32 %41)
  %43 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 0)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %30, i32 %44)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %44, i32 %45)
  %46 = call i32 @cq_template_select_i1(i32 %45, i32 %43, i32 %31)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %30, i32 %47)
  call void @cqrt_and_i1(i32 %30, i32 %33, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %47, i32 %48)
  %49 = add i32 %27, 1
  %50 = icmp ult i32 %49, %2
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %34)
  %51 = trunc i64 %32 to i32
  call void @cqrt_push(i32 %51)
  %52 = lshr i64 %32, 32
  %53 = trunc i64 %52 to i32
  call void @cqrt_push(i32 %53)
  br i1 %50, label %62, label %54

54:                                               ; preds = %26, %15
  %55 = phi i32 [ 0, %15 ], [ 1, %26 ]
  %56 = phi i64 [ 0, %15 ], [ %32, %26 ]
  %57 = phi i32 [ %19, %15 ], [ %30, %26 ]
  %58 = phi i32 [ %23, %15 ], [ %46, %26 ]
  %59 = phi i32 [ %24, %15 ], [ %48, %26 ]
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %59, i32 %60)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %58, i32 %61)
  br label %75

62:                                               ; preds = %26
  %63 = mul i64 %32, 8
  %64 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %63)
  %65 = call i32 @cqrt_qram_load_i64_controlled(i32 %48, i32 %5, i32 %64)
  %66 = call i32 @cq_template_icmp_eq_i64_hl(i32 %65, i64 0)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %68)
  call void @cqrt_xor_i1(i32 %66, i32 %68)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %48, i32 %68, i32 %69)
  %70 = call i32 @cq_template_select_i1(i32 %69, i32 %67, i32 %46)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %48, i32 %66, i32 %71)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %64)
  %72 = trunc i64 %63 to i32
  call void @cqrt_push(i32 %72)
  %73 = lshr i64 %63, 32
  %74 = trunc i64 %73 to i32
  call void @cqrt_push(i32 %74)
  br label %26

75:                                               ; preds = %54
  %76 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %77 = call i32 @cq_template_add_i64(i32 %13, i32 %76)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %11, i32 %78)
  %79 = call i32 @cqrt_qram_load_i64_controlled(i32 %78, i32 %5, i32 %77)
  %80 = call i32 @cq_template_and_i64_hl(i32 %1, i64 63)
  %81 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %80)
  %82 = call i32 @cq_template_xor_i64_hl(i32 %81, i64 -1)
  %83 = call i32 @cq_template_and_i64(i32 %79, i32 %82)
  %84 = call i32 @cq_template_icmp_eq_i64_hl(i32 %83, i64 0)
  %85 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %86 = call i32 @cq_template_select_i1(i32 %14, i32 %84, i32 %61)
  %87 = call i32 @cq_template_select_i1(i32 %11, i32 %86, i32 %85)
  %88 = call i32 @cq_template_zext_i1_to_i32(i32 %87)
  %89 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %88, i32 %89)
  call void @cq_template_zext_i1_to_i32_unc(i32 %88, i32 %87)
  call void @cqrt_free(i32 %88)
  call void @cq_template_select_i1_unc(i32 %87, i32 %11, i32 %86, i32 %85)
  call void @cqrt_free(i32 %87)
  call void @cq_template_select_i1_unc(i32 %86, i32 %14, i32 %84, i32 %61)
  call void @cqrt_free(i32 %86)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %85, i32 %8, i32 0)
  call void @cqrt_free(i32 %85)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %84, i32 %83, i64 0)
  call void @cqrt_free(i32 %84)
  call void @cq_template_and_i64_unc(i32 %83, i32 %79, i32 %82)
  call void @cqrt_free(i32 %83)
  call void @cq_template_xor_i64_hl_unc(i32 %82, i32 %81, i64 -1)
  call void @cqrt_free(i32 %82)
  call void @cq_template_shl_i64_lh_unc(i32 %81, i64 -1, i32 %80)
  call void @cqrt_free(i32 %81)
  call void @cq_template_and_i64_hl_unc(i32 %80, i32 %1, i64 63)
  call void @cqrt_free(i32 %80)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %79, i32 %78, i32 %5, i32 %77)
  call void @cqrt_free(i32 %79)
  call void @cqrt_and_i1(i32 %14, i32 %11, i32 %78)
  call void @cqrt_free(i32 %78)
  call void @cq_template_add_i64_unc(i32 %77, i32 %13, i32 %76)
  call void @cqrt_free(i32 %77)
  call void @cq_template_mul_i64_hl_unc(i32 %76, i32 %6, i64 8)
  call void @cqrt_free(i32 %76)
  br label %138

90:                                               ; preds = %91
  call void @cqrt_and_i1(i32 %16, i32 %19, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_select_i1_unc(i32 %23, i32 %22, i32 %20, i32 %17)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cqrt_xor_i1(i32 %19, i32 %21)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %18, i64 0)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %18, i32 %16, i32 %5, i32 %13)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %16)
  call void @cqrt_xor_i1(i32 %11, i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %14, i32 %1, i64 64)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %13, i32 %11, i32 %5, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %0, i64 8)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i64_unc(i32 %11, i32 %6, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_abs_i32_unc(i32 %9, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_unc(i32 %8, i32 %5, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_add_i64_hl_unc(i32 %7, i32 %0, i64 4)
  call void @cqrt_free(i32 %7)
  call void @cq_template_lshr_i64_hl_unc(i32 %6, i32 %1, i64 6)
  call void @cqrt_free(i32 %6)
  store i32 %4, ptr @__cq_k, align 4
  ret i32 %89

91:                                               ; preds = %139, %92
  br label %90

92:                                               ; preds = %139, %120
  %93 = call i32 @cqrt_pop()
  %94 = zext i32 %93 to i64
  %95 = shl i64 %94, 32
  %96 = or i64 0, %95
  %97 = call i32 @cqrt_pop()
  %98 = zext i32 %97 to i64
  %99 = or i64 %96, %98
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
  call void @cqrt_and_i1(i32 %118, i32 %117, i32 %116)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %115, i32 %114, i32 %117)
  call void @cqrt_xor_i1(i32 %115, i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cq_template_select_i1_unc(i32 %113, i32 %112, i32 %111, i32 %110)
  call void @cqrt_free(i32 %113)
  call void @cqrt_and_i1(i32 %118, i32 %109, i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cqrt_and_i1(i32 %114, i32 %115, i32 %109)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %111, i32 %108, i64 0)
  call void @cqrt_free(i32 %111)
  call void @cq_template_and_i64_unc(i32 %108, i32 %107, i32 %106)
  call void @cqrt_free(i32 %108)
  call void @cq_template_xor_i64_hl_unc(i32 %106, i32 %105, i64 -1)
  call void @cqrt_free(i32 %106)
  call void @cq_template_shl_i64_lh_unc(i32 %105, i64 -1, i32 %104)
  call void @cqrt_free(i32 %105)
  call void @cq_template_and_i64_hl_unc(i32 %104, i32 %1, i64 63)
  call void @cqrt_free(i32 %104)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %107, i32 %103, i32 %5, i32 %102)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %118, i32 %101, i32 %103)
  call void @cqrt_free(i32 %103)
  call void @cqrt_and_i1(i32 %114, i32 %115, i32 %101)
  call void @cqrt_free(i32 %101)
  call void @cq_template_add_i64_unc(i32 %102, i32 %13, i32 %100)
  call void @cqrt_free(i32 %102)
  call void @cq_template_mul_i64_hl_unc(i32 %100, i32 %6, i64 8)
  call void @cqrt_free(i32 %100)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %114, i32 %6, i64 %99)
  call void @cqrt_free(i32 %114)
  %119 = call i32 @cqrt_pop()
  switch i32 %119, label %120 [
    i32 1, label %91
  ]

120:                                              ; preds = %92
  %121 = call i32 @cqrt_pop()
  %122 = zext i32 %121 to i64
  %123 = shl i64 %122, 32
  %124 = or i64 0, %123
  %125 = call i32 @cqrt_pop()
  %126 = zext i32 %125 to i64
  %127 = or i64 %124, %126
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
  call void @cqrt_and_i1(i32 %137, i32 %136, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cq_template_select_i1_unc(i32 %134, i32 %133, i32 %132, i32 %131)
  call void @cqrt_free(i32 %134)
  call void @cqrt_and_i1(i32 %137, i32 %130, i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_xor_i1(i32 %136, i32 %130)
  call void @cqrt_not_i1(i32 %130)
  call void @cqrt_free(i32 %130)
  call void @cqrt_free(i32 %132)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %136, i32 %129, i64 0)
  call void @cqrt_free(i32 %136)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %129, i32 %137, i32 %5, i32 %128)
  call void @cqrt_free(i32 %129)
  call void @cq_template_add_i64_hl_unc(i32 %128, i32 %13, i64 %127)
  call void @cqrt_free(i32 %128)
  br label %92

138:                                              ; preds = %75
  call void @cqrt_copy_i1(i32 %58, i32 %61)
  call void @cqrt_free(i32 %61)
  br label %139

139:                                              ; preds = %138
  switch i32 %55, label %91 [
    i32 1, label %92
  ]
}

declare i32 @cq_template_lshr_i64_hl(i32, i64)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare i32 @cq_template_icmp_ult_i64(i32, i32)

declare i32 @cq_template_icmp_ult_i64_hl(i32, i64)

declare void @cqrt_not_i1(i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64(i32, i32)

declare i32 @cq_template_shl_i64_lh(i64, i32)

declare i32 @cq_template_xor_i64_hl(i32, i64)

declare i32 @cq_template_and_i64(i32, i32)

declare void @cqrt_copy_i1(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

declare void @cq_template_and_i64_unc(i32, i32, i32)

declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)

declare void @cq_template_shl_i64_lh_unc(i32, i64, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_ult_i64_hl_unc(i32, i32, i64)

declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)

declare void @cqrt_qram_load_i32_unc(i32, i32, i32)

declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)

define internal i32 @__cq_q_g_11_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_g, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_g, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %154

9:                                                ; preds = %4
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_lshr_i64_hl(i32 %2, i64 6)
  %12 = call i32 @cq_template_add_i64_hl(i32 %1, i64 4)
  %13 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %10, i32 %12)
  %14 = call i32 @cq_template_abs_i32(i32 %13)
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %16 = call i32 @cq_template_icmp_ult_i64(i32 %11, i32 %15)
  %17 = call i32 @cq_template_add_i64_hl(i32 %1, i64 8)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  %19 = call i32 @cqrt_qram_load_i64_controlled(i32 %18, i32 %10, i32 %17)
  %20 = call i32 @cq_template_icmp_ult_i64_hl(i32 %2, i64 64)
  br label %21

21:                                               ; preds = %9
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %23)
  call void @cqrt_and_i1(i32 %16, i32 %20, i32 %23)
  call void @cqrt_and_i1(i32 %0, i32 %23, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_qram_load_i64_controlled(i32 %22, i32 %10, i32 %19)
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %25, i64 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %28, i32 %29)
  %30 = call i32 @cq_template_select_i1(i32 %29, i32 %27, i32 %24)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %31)
  %32 = icmp ult i32 0, %3
  br i1 %32, label %33, label %61

33:                                               ; preds = %69, %21
  %from = phi i32 [ 0, %69 ], [ 1, %21 ]
  %34 = phi i32 [ 0, %21 ], [ %56, %69 ]
  %35 = phi i32 [ %31, %21 ], [ %78, %69 ]
  %36 = phi i64 [ 0, %21 ], [ %39, %69 ]
  %37 = phi i32 [ %26, %21 ], [ %73, %69 ]
  %38 = phi i32 [ %30, %21 ], [ %77, %69 ]
  call void @cqrt_push(i32 %from)
  %39 = add i64 %36, 1
  %40 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %39)
  %41 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %42 = call i32 @cq_template_add_i64(i32 %19, i32 %41)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %37, i32 %43)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %43, i32 %44)
  %45 = call i32 @cqrt_qram_load_i64_controlled(i32 %44, i32 %10, i32 %42)
  %46 = call i32 @cq_template_and_i64_hl(i32 %2, i64 63)
  %47 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %46)
  %48 = call i32 @cq_template_xor_i64_hl(i32 %47, i64 -1)
  %49 = call i32 @cq_template_and_i64(i32 %45, i32 %48)
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %49, i64 0)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %37, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i1(i32 %52, i32 %50, i32 %38)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %37, i32 %54)
  call void @cqrt_and_i1(i32 %37, i32 %40, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %54, i32 %55)
  %56 = add i32 %34, 1
  %57 = icmp ult i32 %56, %3
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  %58 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %58)
  %59 = lshr i64 %39, 32
  %60 = trunc i64 %59 to i32
  call void @cqrt_push(i32 %60)
  br i1 %57, label %69, label %61

61:                                               ; preds = %33, %21
  %62 = phi i32 [ 0, %21 ], [ 1, %33 ]
  %63 = phi i64 [ 0, %21 ], [ %39, %33 ]
  %64 = phi i32 [ %26, %21 ], [ %37, %33 ]
  %65 = phi i32 [ %30, %21 ], [ %53, %33 ]
  %66 = phi i32 [ %31, %21 ], [ %55, %33 ]
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %66, i32 %67)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %65, i32 %68)
  br label %82

69:                                               ; preds = %33
  %70 = mul i64 %39, 8
  %71 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %70)
  %72 = call i32 @cqrt_qram_load_i64_controlled(i32 %55, i32 %10, i32 %71)
  %73 = call i32 @cq_template_icmp_eq_i64_hl(i32 %72, i64 0)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %75)
  call void @cqrt_xor_i1(i32 %73, i32 %75)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %75, i32 %76)
  %77 = call i32 @cq_template_select_i1(i32 %76, i32 %74, i32 %53)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %73, i32 %78)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %71)
  %79 = trunc i64 %70 to i32
  call void @cqrt_push(i32 %79)
  %80 = lshr i64 %70, 32
  %81 = trunc i64 %80 to i32
  call void @cqrt_push(i32 %81)
  br label %33

82:                                               ; preds = %61
  %83 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %84 = call i32 @cq_template_add_i64(i32 %19, i32 %83)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  %86 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %86)
  call void @cqrt_and_i1(i32 %0, i32 %86, i32 %85)
  %87 = call i32 @cqrt_qram_load_i64_controlled(i32 %85, i32 %10, i32 %84)
  %88 = call i32 @cq_template_and_i64_hl(i32 %2, i64 63)
  %89 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %88)
  %90 = call i32 @cq_template_xor_i64_hl(i32 %89, i64 -1)
  %91 = call i32 @cq_template_and_i64(i32 %87, i32 %90)
  %92 = call i32 @cq_template_icmp_eq_i64_hl(i32 %91, i64 0)
  %93 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %95)
  call void @cqrt_and_i1(i32 %0, i32 %95, i32 %94)
  %96 = call i32 @cq_template_select_i1(i32 %94, i32 %92, i32 %68)
  %97 = call i32 @cqrt_alloc_i1(i1 false)
  %98 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_xor_i1(i32 %16, i32 %98)
  call void @cqrt_and_i1(i32 %0, i32 %98, i32 %97)
  %99 = call i32 @cq_template_select_i1(i32 %97, i32 %93, i32 %96)
  %100 = call i32 @cq_template_zext_i1_to_i32(i32 %99)
  %101 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %100, i32 %101)
  call void @cq_template_zext_i1_to_i32_unc(i32 %100, i32 %99)
  call void @cqrt_free(i32 %100)
  call void @cq_template_select_i1_unc(i32 %99, i32 %97, i32 %93, i32 %96)
  call void @cqrt_free(i32 %99)
  call void @cqrt_and_i1(i32 %0, i32 %98, i32 %97)
  call void @cqrt_free(i32 %97)
  call void @cqrt_xor_i1(i32 %16, i32 %98)
  call void @cqrt_not_i1(i32 %98)
  call void @cqrt_free(i32 %98)
  call void @cq_template_select_i1_unc(i32 %96, i32 %94, i32 %92, i32 %68)
  call void @cqrt_free(i32 %96)
  call void @cqrt_and_i1(i32 %0, i32 %95, i32 %94)
  call void @cqrt_free(i32 %94)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %95)
  call void @cqrt_free(i32 %95)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %93, i32 %13, i32 0)
  call void @cqrt_free(i32 %93)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %92, i32 %91, i64 0)
  call void @cqrt_free(i32 %92)
  call void @cq_template_and_i64_unc(i32 %91, i32 %87, i32 %90)
  call void @cqrt_free(i32 %91)
  call void @cq_template_xor_i64_hl_unc(i32 %90, i32 %89, i64 -1)
  call void @cqrt_free(i32 %90)
  call void @cq_template_shl_i64_lh_unc(i32 %89, i64 -1, i32 %88)
  call void @cqrt_free(i32 %89)
  call void @cq_template_and_i64_hl_unc(i32 %88, i32 %2, i64 63)
  call void @cqrt_free(i32 %88)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %87, i32 %85, i32 %10, i32 %84)
  call void @cqrt_free(i32 %87)
  call void @cqrt_and_i1(i32 %0, i32 %86, i32 %85)
  call void @cqrt_free(i32 %85)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %86)
  call void @cqrt_free(i32 %86)
  call void @cq_template_add_i64_unc(i32 %84, i32 %19, i32 %83)
  call void @cqrt_free(i32 %84)
  call void @cq_template_mul_i64_hl_unc(i32 %83, i32 %11, i64 8)
  call void @cqrt_free(i32 %83)
  br label %152

102:                                              ; preds = %105
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_select_i1_unc(i32 %30, i32 %29, i32 %27, i32 %24)
  call void @cqrt_free(i32 %30)
  call void @cqrt_and_i1(i32 %22, i32 %28, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_free(i32 %27)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %26, i32 %25, i64 0)
  call void @cqrt_free(i32 %26)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %25, i32 %22, i32 %10, i32 %19)
  call void @cqrt_free(i32 %25)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %0, i32 %23, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cqrt_and_i1(i32 %16, i32 %20, i32 %23)
  call void @cqrt_xor_i1(i32 %16, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %20, i32 %2, i64 64)
  call void @cqrt_free(i32 %20)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %19, i32 %18, i32 %10, i32 %17)
  call void @cqrt_free(i32 %19)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i64_hl_unc(i32 %17, i32 %1, i64 8)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_ult_i64_unc(i32 %16, i32 %11, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_abs_i32_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %13, i32 %0, i32 %10, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %1, i64 4)
  call void @cqrt_free(i32 %12)
  call void @cq_template_lshr_i64_hl_unc(i32 %11, i32 %2, i64 6)
  call void @cqrt_free(i32 %11)
  %103 = load i32, ptr @__cq_act_g, align 4
  %104 = add i32 %103, -1
  store i32 %104, ptr @__cq_act_g, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %101

105:                                              ; preds = %153, %106
  br label %102

106:                                              ; preds = %153, %134
  %107 = call i32 @cqrt_pop()
  %108 = zext i32 %107 to i64
  %109 = shl i64 %108, 32
  %110 = or i64 0, %109
  %111 = call i32 @cqrt_pop()
  %112 = zext i32 %111 to i64
  %113 = or i64 %110, %112
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
  call void @cqrt_and_i1(i32 %132, i32 %131, i32 %130)
  call void @cqrt_free(i32 %130)
  call void @cqrt_and_i1(i32 %129, i32 %128, i32 %131)
  call void @cqrt_xor_i1(i32 %129, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cq_template_select_i1_unc(i32 %127, i32 %126, i32 %125, i32 %124)
  call void @cqrt_free(i32 %127)
  call void @cqrt_and_i1(i32 %132, i32 %123, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cqrt_and_i1(i32 %128, i32 %129, i32 %123)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %125, i32 %122, i64 0)
  call void @cqrt_free(i32 %125)
  call void @cq_template_and_i64_unc(i32 %122, i32 %121, i32 %120)
  call void @cqrt_free(i32 %122)
  call void @cq_template_xor_i64_hl_unc(i32 %120, i32 %119, i64 -1)
  call void @cqrt_free(i32 %120)
  call void @cq_template_shl_i64_lh_unc(i32 %119, i64 -1, i32 %118)
  call void @cqrt_free(i32 %119)
  call void @cq_template_and_i64_hl_unc(i32 %118, i32 %2, i64 63)
  call void @cqrt_free(i32 %118)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %121, i32 %117, i32 %10, i32 %116)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %132, i32 %115, i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cqrt_and_i1(i32 %128, i32 %129, i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cq_template_add_i64_unc(i32 %116, i32 %19, i32 %114)
  call void @cqrt_free(i32 %116)
  call void @cq_template_mul_i64_hl_unc(i32 %114, i32 %11, i64 8)
  call void @cqrt_free(i32 %114)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %128, i32 %11, i64 %113)
  call void @cqrt_free(i32 %128)
  %133 = call i32 @cqrt_pop()
  switch i32 %133, label %134 [
    i32 1, label %105
  ]

134:                                              ; preds = %106
  %135 = call i32 @cqrt_pop()
  %136 = zext i32 %135 to i64
  %137 = shl i64 %136, 32
  %138 = or i64 0, %137
  %139 = call i32 @cqrt_pop()
  %140 = zext i32 %139 to i64
  %141 = or i64 %138, %140
  %142 = call i32 @cqrt_pop()
  %143 = call i32 @cqrt_pop()
  %144 = call i32 @cqrt_pop()
  %145 = call i32 @cqrt_pop()
  %146 = call i32 @cqrt_pop()
  %147 = call i32 @cqrt_pop()
  %148 = call i32 @cqrt_pop()
  %149 = call i32 @cqrt_pop()
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %151, i32 %150, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cq_template_select_i1_unc(i32 %148, i32 %147, i32 %146, i32 %145)
  call void @cqrt_free(i32 %148)
  call void @cqrt_and_i1(i32 %151, i32 %144, i32 %147)
  call void @cqrt_free(i32 %147)
  call void @cqrt_xor_i1(i32 %150, i32 %144)
  call void @cqrt_not_i1(i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_free(i32 %146)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %150, i32 %143, i64 0)
  call void @cqrt_free(i32 %150)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %143, i32 %151, i32 %10, i32 %142)
  call void @cqrt_free(i32 %143)
  call void @cq_template_add_i64_hl_unc(i32 %142, i32 %19, i64 %141)
  call void @cqrt_free(i32 %142)
  br label %106

152:                                              ; preds = %82
  call void @cqrt_copy_i1(i32 %65, i32 %68)
  call void @cqrt_free(i32 %68)
  br label %153

153:                                              ; preds = %152
  switch i32 %62, label %105 [
    i32 1, label %106
  ]

154:                                              ; preds = %4
  %155 = call i32 @cqrt_alloc_i32(i32 0)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %156)
  %157 = load i32, ptr @__cq_act_g, align 4
  %158 = add i32 %157, -1
  store i32 %158, ptr @__cq_act_g, align 4
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %155
}

declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)

declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

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
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 16)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @zs to i64))
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 255)
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)
  %15 = call i32 @cq_template_lshr_i64_hl(i32 %14, i64 6)
  %16 = call i32 @cq_template_add_i64_hl(i32 %12, i64 4)
  %17 = call i32 @cqrt_qram_load_i32(i32 %6, i32 %16)
  %18 = call i32 @cq_template_abs_i32(i32 %17)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)
  %20 = call i32 @cq_template_icmp_ult_i64(i32 %15, i32 %19)
  %21 = call i32 @cq_template_add_i64_hl(i32 %12, i64 8)
  %22 = call i32 @cqrt_qram_load_i64_controlled(i32 %20, i32 %6, i32 %21)
  %23 = call i32 @cq_template_icmp_ult_i32_hl(i32 %13, i32 64)
  br label %24

24:                                               ; preds = %4
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %20, i32 %25)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %25)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  %27 = call i32 @cqrt_qram_load_i64_controlled(i32 %25, i32 %6, i32 %22)
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %27, i64 0)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %28, i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %25, i32 %30, i32 %31)
  %32 = call i32 @cq_template_select_i1(i32 %31, i32 %29, i32 %26)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %25, i32 %28, i32 %33)
  %34 = call i32 @llvm.umin.i32(i32 %3, i32 3)
  %35 = icmp ult i32 %3, 3
  %36 = icmp ult i32 0, %34
  br i1 %36, label %37, label %65

37:                                               ; preds = %71, %24
  %from = phi i32 [ 0, %71 ], [ 1, %24 ]
  %38 = phi i32 [ 0, %24 ], [ %60, %71 ]
  %39 = phi i32 [ %33, %24 ], [ %80, %71 ]
  %40 = phi i64 [ 0, %24 ], [ %43, %71 ]
  %41 = phi i32 [ %28, %24 ], [ %75, %71 ]
  %42 = phi i32 [ %32, %24 ], [ %79, %71 ]
  call void @cqrt_push(i32 %from)
  %43 = add i64 %40, 1
  %44 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 %43)
  %45 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 8)
  %46 = call i32 @cq_template_add_i64(i32 %22, i32 %45)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %41, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %47, i32 %48)
  %49 = call i32 @cqrt_qram_load_i64_controlled(i32 %48, i32 %6, i32 %46)
  %50 = call i32 @cq_template_and_i64_hl(i32 %14, i64 63)
  %51 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %50)
  %52 = call i32 @cq_template_xor_i64_hl(i32 %51, i64 -1)
  %53 = call i32 @cq_template_and_i64(i32 %49, i32 %52)
  %54 = call i32 @cq_template_icmp_eq_i64_hl(i32 %53, i64 0)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %41, i32 %55)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %55, i32 %56)
  %57 = call i32 @cq_template_select_i1(i32 %56, i32 %54, i32 %42)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %41, i32 %58)
  call void @cqrt_and_i1(i32 %41, i32 %44, i32 %58)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %58, i32 %59)
  %60 = add i32 %38, 1
  %61 = icmp ult i32 %60, %34
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  %62 = trunc i64 %43 to i32
  call void @cqrt_push(i32 %62)
  %63 = lshr i64 %43, 32
  %64 = trunc i64 %63 to i32
  call void @cqrt_push(i32 %64)
  br i1 %61, label %71, label %65

65:                                               ; preds = %37, %24
  %66 = phi i32 [ 0, %24 ], [ 1, %37 ]
  %67 = phi i64 [ 0, %24 ], [ %43, %37 ]
  %68 = phi i32 [ %28, %24 ], [ %41, %37 ]
  %69 = phi i32 [ %32, %24 ], [ %57, %37 ]
  %70 = phi i32 [ %33, %24 ], [ %59, %37 ]
  br i1 %35, label %84, label %86

71:                                               ; preds = %37
  %72 = mul i64 %43, 8
  %73 = call i32 @cq_template_add_i64_hl(i32 %22, i64 %72)
  %74 = call i32 @cqrt_qram_load_i64_controlled(i32 %59, i32 %6, i32 %73)
  %75 = call i32 @cq_template_icmp_eq_i64_hl(i32 %74, i64 0)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %77)
  call void @cqrt_xor_i1(i32 %75, i32 %77)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %59, i32 %77, i32 %78)
  %79 = call i32 @cq_template_select_i1(i32 %78, i32 %76, i32 %57)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %59, i32 %75, i32 %80)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %73)
  %81 = trunc i64 %72 to i32
  call void @cqrt_push(i32 %81)
  %82 = lshr i64 %72, 32
  %83 = trunc i64 %82 to i32
  call void @cqrt_push(i32 %83)
  br label %37

84:                                               ; preds = %65
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %70, i32 %85)
  br label %87

86:                                               ; preds = %65
  br label %87

87:                                               ; preds = %84, %86
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %69, i32 %88)
  br label %89

89:                                               ; preds = %87
  %90 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 8)
  %91 = call i32 @cq_template_add_i64(i32 %22, i32 %90)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %23, i32 %20, i32 %92)
  %93 = call i32 @cqrt_qram_load_i64_controlled(i32 %92, i32 %6, i32 %91)
  %94 = call i32 @cq_template_and_i64_hl(i32 %14, i64 63)
  %95 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %94)
  %96 = call i32 @cq_template_xor_i64_hl(i32 %95, i64 -1)
  %97 = call i32 @cq_template_and_i64(i32 %93, i32 %96)
  %98 = call i32 @cq_template_icmp_eq_i64_hl(i32 %97, i64 0)
  %99 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 0)
  %100 = call i32 @cq_template_select_i1(i32 %23, i32 %98, i32 %88)
  %101 = call i32 @cq_template_select_i1(i32 %20, i32 %100, i32 %99)
  %102 = call i32 @cq_template_zext_i1_to_i32(i32 %101)
  call void @cqrt_push(i32 %7)
  call void @cqrt_push(i32 %8)
  %103 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %102, i32 %103)
  call void @cq_template_zext_i1_to_i32_unc(i32 %102, i32 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_select_i1_unc(i32 %101, i32 %20, i32 %100, i32 %99)
  call void @cqrt_free(i32 %101)
  call void @cq_template_select_i1_unc(i32 %100, i32 %23, i32 %98, i32 %88)
  call void @cqrt_free(i32 %100)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %99, i32 %17, i32 0)
  call void @cqrt_free(i32 %99)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %98, i32 %97, i64 0)
  call void @cqrt_free(i32 %98)
  call void @cq_template_and_i64_unc(i32 %97, i32 %93, i32 %96)
  call void @cqrt_free(i32 %97)
  call void @cq_template_xor_i64_hl_unc(i32 %96, i32 %95, i64 -1)
  call void @cqrt_free(i32 %96)
  call void @cq_template_shl_i64_lh_unc(i32 %95, i64 -1, i32 %94)
  call void @cqrt_free(i32 %95)
  call void @cq_template_and_i64_hl_unc(i32 %94, i32 %14, i64 63)
  call void @cqrt_free(i32 %94)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %93, i32 %92, i32 %6, i32 %91)
  call void @cqrt_free(i32 %93)
  call void @cqrt_and_i1(i32 %23, i32 %20, i32 %92)
  call void @cqrt_free(i32 %92)
  call void @cq_template_add_i64_unc(i32 %91, i32 %22, i32 %90)
  call void @cqrt_free(i32 %91)
  call void @cq_template_mul_i64_hl_unc(i32 %90, i32 %15, i64 8)
  call void @cqrt_free(i32 %90)
  br label %152

104:                                              ; preds = %105
  call void @cqrt_and_i1(i32 %25, i32 %28, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cq_template_select_i1_unc(i32 %32, i32 %31, i32 %29, i32 %26)
  call void @cqrt_free(i32 %32)
  call void @cqrt_and_i1(i32 %25, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_xor_i1(i32 %28, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %28, i32 %27, i64 0)
  call void @cqrt_free(i32 %28)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %27, i32 %25, i32 %6, i32 %22)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %25)
  call void @cqrt_xor_i1(i32 %20, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %23, i32 %13, i32 64)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %22, i32 %20, i32 %6, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %12, i64 8)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_ult_i64_unc(i32 %20, i32 %15, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_abs_i32_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cqrt_qram_load_i32_unc(i32 %17, i32 %6, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %12, i64 4)
  call void @cqrt_free(i32 %16)
  call void @cq_template_lshr_i64_hl_unc(i32 %15, i32 %14, i64 6)
  call void @cqrt_free(i32 %15)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 255)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @zs to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 16)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 1)
  call void @cqrt_free(i32 %9)
  store i32 %5, ptr @__cq_k, align 4
  ret i32 %103

105:                                              ; preds = %153, %106
  br label %104

106:                                              ; preds = %153, %134
  %107 = call i32 @cqrt_pop()
  %108 = zext i32 %107 to i64
  %109 = shl i64 %108, 32
  %110 = or i64 0, %109
  %111 = call i32 @cqrt_pop()
  %112 = zext i32 %111 to i64
  %113 = or i64 %110, %112
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
  call void @cqrt_and_i1(i32 %132, i32 %131, i32 %130)
  call void @cqrt_free(i32 %130)
  call void @cqrt_and_i1(i32 %129, i32 %128, i32 %131)
  call void @cqrt_xor_i1(i32 %129, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cq_template_select_i1_unc(i32 %127, i32 %126, i32 %125, i32 %124)
  call void @cqrt_free(i32 %127)
  call void @cqrt_and_i1(i32 %132, i32 %123, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cqrt_and_i1(i32 %128, i32 %129, i32 %123)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %125, i32 %122, i64 0)
  call void @cqrt_free(i32 %125)
  call void @cq_template_and_i64_unc(i32 %122, i32 %121, i32 %120)
  call void @cqrt_free(i32 %122)
  call void @cq_template_xor_i64_hl_unc(i32 %120, i32 %119, i64 -1)
  call void @cqrt_free(i32 %120)
  call void @cq_template_shl_i64_lh_unc(i32 %119, i64 -1, i32 %118)
  call void @cqrt_free(i32 %119)
  call void @cq_template_and_i64_hl_unc(i32 %118, i32 %14, i64 63)
  call void @cqrt_free(i32 %118)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %121, i32 %117, i32 %6, i32 %116)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %132, i32 %115, i32 %117)
  call void @cqrt_free(i32 %117)
  call void @cqrt_and_i1(i32 %128, i32 %129, i32 %115)
  call void @cqrt_free(i32 %115)
  call void @cq_template_add_i64_unc(i32 %116, i32 %22, i32 %114)
  call void @cqrt_free(i32 %116)
  call void @cq_template_mul_i64_hl_unc(i32 %114, i32 %15, i64 8)
  call void @cqrt_free(i32 %114)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %128, i32 %15, i64 %113)
  call void @cqrt_free(i32 %128)
  %133 = call i32 @cqrt_pop()
  switch i32 %133, label %134 [
    i32 1, label %105
  ]

134:                                              ; preds = %106
  %135 = call i32 @cqrt_pop()
  %136 = zext i32 %135 to i64
  %137 = shl i64 %136, 32
  %138 = or i64 0, %137
  %139 = call i32 @cqrt_pop()
  %140 = zext i32 %139 to i64
  %141 = or i64 %138, %140
  %142 = call i32 @cqrt_pop()
  %143 = call i32 @cqrt_pop()
  %144 = call i32 @cqrt_pop()
  %145 = call i32 @cqrt_pop()
  %146 = call i32 @cqrt_pop()
  %147 = call i32 @cqrt_pop()
  %148 = call i32 @cqrt_pop()
  %149 = call i32 @cqrt_pop()
  %150 = call i32 @cqrt_pop()
  %151 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %151, i32 %150, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cq_template_select_i1_unc(i32 %148, i32 %147, i32 %146, i32 %145)
  call void @cqrt_free(i32 %148)
  call void @cqrt_and_i1(i32 %151, i32 %144, i32 %147)
  call void @cqrt_free(i32 %147)
  call void @cqrt_xor_i1(i32 %150, i32 %144)
  call void @cqrt_not_i1(i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_free(i32 %146)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %150, i32 %143, i64 0)
  call void @cqrt_free(i32 %150)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %143, i32 %151, i32 %6, i32 %142)
  call void @cqrt_free(i32 %143)
  call void @cq_template_add_i64_hl_unc(i32 %142, i32 %22, i64 %141)
  call void @cqrt_free(i32 %142)
  br label %106

152:                                              ; preds = %89
  call void @cqrt_copy_i1(i32 %69, i32 %88)
  call void @cqrt_free(i32 %88)
  br label %153

153:                                              ; preds = %152
  switch i32 %66, label %105 [
    i32 1, label %106
  ]
}

declare void @cqrt_ry_i32_qangle(i32, i32)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

define internal i32 @__cq_q_f_111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = load i32, ptr @__cq_act_f, align 4
  %8 = add i32 %7, 1
  store i32 %8, ptr @__cq_act_f, align 4
  %9 = icmp ult i32 %7, %4
  br i1 %9, label %10, label %168

10:                                               ; preds = %5
  %11 = call i32 @__cq_mem()
  %12 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %1, i32 %12)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %12, i32 %3)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %13)
  call void @cqrt_ry_i32_qangle_controlled(i32 %0, i32 %13, i32 %3)
  %14 = call i32 @cq_template_and_i32_hl(i32 %12, i32 1)
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %16 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 16)
  %17 = call i32 @cq_template_add_i64_hl(i32 %16, i64 ptrtoint (ptr @zs to i64))
  %18 = call i32 @cq_template_and_i32_hl(i32 %13, i32 255)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)
  %20 = call i32 @cq_template_lshr_i64_hl(i32 %19, i64 6)
  %21 = call i32 @cq_template_add_i64_hl(i32 %17, i64 4)
  %22 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %11, i32 %21)
  %23 = call i32 @cq_template_abs_i32(i32 %22)
  %24 = call i32 @cq_template_zext_i32_to_i64(i32 %23)
  %25 = call i32 @cq_template_icmp_ult_i64(i32 %20, i32 %24)
  %26 = call i32 @cq_template_add_i64_hl(i32 %17, i64 8)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %27)
  %28 = call i32 @cqrt_qram_load_i64_controlled(i32 %27, i32 %11, i32 %26)
  %29 = call i32 @cq_template_icmp_ult_i32_hl(i32 %18, i32 64)
  br label %30

30:                                               ; preds = %10
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %25, i32 %32)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %32)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  %34 = call i32 @cqrt_qram_load_i64_controlled(i32 %31, i32 %11, i32 %28)
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %34, i64 0)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %35, i32 %37)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %38)
  %39 = call i32 @cq_template_select_i1(i32 %38, i32 %36, i32 %33)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %35, i32 %40)
  %41 = call i32 @llvm.umin.i32(i32 %4, i32 3)
  %42 = icmp ult i32 %4, 3
  %43 = icmp ult i32 0, %41
  br i1 %43, label %44, label %72

44:                                               ; preds = %78, %30
  %from = phi i32 [ 0, %78 ], [ 1, %30 ]
  %45 = phi i32 [ 0, %30 ], [ %67, %78 ]
  %46 = phi i32 [ %40, %30 ], [ %87, %78 ]
  %47 = phi i64 [ 0, %30 ], [ %50, %78 ]
  %48 = phi i32 [ %35, %30 ], [ %82, %78 ]
  %49 = phi i32 [ %39, %30 ], [ %86, %78 ]
  call void @cqrt_push(i32 %from)
  %50 = add i64 %47, 1
  %51 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 %50)
  %52 = call i32 @cq_template_mul_i64_hl(i32 %20, i64 8)
  %53 = call i32 @cq_template_add_i64(i32 %28, i32 %52)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %48, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %54, i32 %55)
  %56 = call i32 @cqrt_qram_load_i64_controlled(i32 %55, i32 %11, i32 %53)
  %57 = call i32 @cq_template_and_i64_hl(i32 %19, i64 63)
  %58 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %57)
  %59 = call i32 @cq_template_xor_i64_hl(i32 %58, i64 -1)
  %60 = call i32 @cq_template_and_i64(i32 %56, i32 %59)
  %61 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 0)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %48, i32 %62)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %62, i32 %63)
  %64 = call i32 @cq_template_select_i1(i32 %63, i32 %61, i32 %49)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %48, i32 %65)
  call void @cqrt_and_i1(i32 %48, i32 %51, i32 %65)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %65, i32 %66)
  %67 = add i32 %45, 1
  %68 = icmp ult i32 %67, %41
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %52)
  %69 = trunc i64 %50 to i32
  call void @cqrt_push(i32 %69)
  %70 = lshr i64 %50, 32
  %71 = trunc i64 %70 to i32
  call void @cqrt_push(i32 %71)
  br i1 %68, label %78, label %72

72:                                               ; preds = %44, %30
  %73 = phi i32 [ 0, %30 ], [ 1, %44 ]
  %74 = phi i64 [ 0, %30 ], [ %50, %44 ]
  %75 = phi i32 [ %35, %30 ], [ %48, %44 ]
  %76 = phi i32 [ %39, %30 ], [ %64, %44 ]
  %77 = phi i32 [ %40, %30 ], [ %66, %44 ]
  br i1 %42, label %91, label %93

78:                                               ; preds = %44
  %79 = mul i64 %50, 8
  %80 = call i32 @cq_template_add_i64_hl(i32 %28, i64 %79)
  %81 = call i32 @cqrt_qram_load_i64_controlled(i32 %66, i32 %11, i32 %80)
  %82 = call i32 @cq_template_icmp_eq_i64_hl(i32 %81, i64 0)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %84)
  call void @cqrt_xor_i1(i32 %82, i32 %84)
  %85 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %84, i32 %85)
  %86 = call i32 @cq_template_select_i1(i32 %85, i32 %83, i32 %64)
  %87 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %82, i32 %87)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %80)
  %88 = trunc i64 %79 to i32
  call void @cqrt_push(i32 %88)
  %89 = lshr i64 %79, 32
  %90 = trunc i64 %89 to i32
  call void @cqrt_push(i32 %90)
  br label %44

91:                                               ; preds = %72
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %77, i32 %92)
  br label %94

93:                                               ; preds = %72
  br label %94

94:                                               ; preds = %91, %93
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %76, i32 %95)
  br label %96

96:                                               ; preds = %94
  %97 = call i32 @cq_template_mul_i64_hl(i32 %20, i64 8)
  %98 = call i32 @cq_template_add_i64(i32 %28, i32 %97)
  %99 = call i32 @cqrt_alloc_i1(i1 false)
  %100 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %100)
  call void @cqrt_and_i1(i32 %0, i32 %100, i32 %99)
  %101 = call i32 @cqrt_qram_load_i64_controlled(i32 %99, i32 %11, i32 %98)
  %102 = call i32 @cq_template_and_i64_hl(i32 %19, i64 63)
  %103 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %102)
  %104 = call i32 @cq_template_xor_i64_hl(i32 %103, i64 -1)
  %105 = call i32 @cq_template_and_i64(i32 %101, i32 %104)
  %106 = call i32 @cq_template_icmp_eq_i64_hl(i32 %105, i64 0)
  %107 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 0)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  %109 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %109)
  call void @cqrt_and_i1(i32 %0, i32 %109, i32 %108)
  %110 = call i32 @cq_template_select_i1(i32 %108, i32 %106, i32 %95)
  %111 = call i32 @cqrt_alloc_i1(i1 false)
  %112 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %112)
  call void @cqrt_xor_i1(i32 %25, i32 %112)
  call void @cqrt_and_i1(i32 %0, i32 %112, i32 %111)
  %113 = call i32 @cq_template_select_i1(i32 %111, i32 %107, i32 %110)
  %114 = call i32 @cq_template_zext_i1_to_i32(i32 %113)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  %115 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %114, i32 %115)
  call void @cq_template_zext_i1_to_i32_unc(i32 %114, i32 %113)
  call void @cqrt_free(i32 %114)
  call void @cq_template_select_i1_unc(i32 %113, i32 %111, i32 %107, i32 %110)
  call void @cqrt_free(i32 %113)
  call void @cqrt_and_i1(i32 %0, i32 %112, i32 %111)
  call void @cqrt_free(i32 %111)
  call void @cqrt_xor_i1(i32 %25, i32 %112)
  call void @cqrt_not_i1(i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cq_template_select_i1_unc(i32 %110, i32 %108, i32 %106, i32 %95)
  call void @cqrt_free(i32 %110)
  call void @cqrt_and_i1(i32 %0, i32 %109, i32 %108)
  call void @cqrt_free(i32 %108)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %109)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %107, i32 %22, i32 0)
  call void @cqrt_free(i32 %107)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %106, i32 %105, i64 0)
  call void @cqrt_free(i32 %106)
  call void @cq_template_and_i64_unc(i32 %105, i32 %101, i32 %104)
  call void @cqrt_free(i32 %105)
  call void @cq_template_xor_i64_hl_unc(i32 %104, i32 %103, i64 -1)
  call void @cqrt_free(i32 %104)
  call void @cq_template_shl_i64_lh_unc(i32 %103, i64 -1, i32 %102)
  call void @cqrt_free(i32 %103)
  call void @cq_template_and_i64_hl_unc(i32 %102, i32 %19, i64 63)
  call void @cqrt_free(i32 %102)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %101, i32 %99, i32 %11, i32 %98)
  call void @cqrt_free(i32 %101)
  call void @cqrt_and_i1(i32 %0, i32 %100, i32 %99)
  call void @cqrt_free(i32 %99)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %100)
  call void @cqrt_free(i32 %100)
  call void @cq_template_add_i64_unc(i32 %98, i32 %28, i32 %97)
  call void @cqrt_free(i32 %98)
  call void @cq_template_mul_i64_hl_unc(i32 %97, i32 %20, i64 8)
  call void @cqrt_free(i32 %97)
  br label %166

116:                                              ; preds = %119
  call void @cqrt_and_i1(i32 %31, i32 %35, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cq_template_select_i1_unc(i32 %39, i32 %38, i32 %36, i32 %33)
  call void @cqrt_free(i32 %39)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_xor_i1(i32 %35, i32 %37)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %34, i64 0)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %34, i32 %31, i32 %11, i32 %28)
  call void @cqrt_free(i32 %34)
  call void @cqrt_free(i32 %33)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %32)
  call void @cqrt_xor_i1(i32 %25, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %29, i32 %18, i32 64)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %28, i32 %27, i32 %11, i32 %26)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i64_hl_unc(i32 %26, i32 %17, i64 8)
  call void @cqrt_free(i32 %26)
  call void @cq_template_icmp_ult_i64_unc(i32 %25, i32 %20, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_zext_i32_to_i64_unc(i32 %24, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cq_template_abs_i32_unc(i32 %23, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %22, i32 %0, i32 %11, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %17, i64 4)
  call void @cqrt_free(i32 %21)
  call void @cq_template_lshr_i64_hl_unc(i32 %20, i32 %19, i64 6)
  call void @cqrt_free(i32 %20)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_and_i32_hl_unc(i32 %18, i32 %13, i32 255)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i64_hl_unc(i32 %17, i32 %16, i64 ptrtoint (ptr @zs to i64))
  call void @cqrt_free(i32 %17)
  call void @cq_template_mul_i64_hl_unc(i32 %16, i32 %15, i64 16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %12, i32 1)
  call void @cqrt_free(i32 %14)
  %117 = load i32, ptr @__cq_act_f, align 4
  %118 = add i32 %117, -1
  store i32 %118, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %115

119:                                              ; preds = %167, %120
  br label %116

120:                                              ; preds = %167, %148
  %121 = call i32 @cqrt_pop()
  %122 = zext i32 %121 to i64
  %123 = shl i64 %122, 32
  %124 = or i64 0, %123
  %125 = call i32 @cqrt_pop()
  %126 = zext i32 %125 to i64
  %127 = or i64 %124, %126
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
  %141 = call i32 @cqrt_pop()
  %142 = call i32 @cqrt_pop()
  %143 = call i32 @cqrt_pop()
  %144 = call i32 @cqrt_pop()
  %145 = call i32 @cqrt_pop()
  %146 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %146, i32 %145, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_and_i1(i32 %143, i32 %142, i32 %145)
  call void @cqrt_xor_i1(i32 %143, i32 %145)
  call void @cqrt_free(i32 %145)
  call void @cq_template_select_i1_unc(i32 %141, i32 %140, i32 %139, i32 %138)
  call void @cqrt_free(i32 %141)
  call void @cqrt_and_i1(i32 %146, i32 %137, i32 %140)
  call void @cqrt_free(i32 %140)
  call void @cqrt_and_i1(i32 %142, i32 %143, i32 %137)
  call void @cqrt_free(i32 %137)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %139, i32 %136, i64 0)
  call void @cqrt_free(i32 %139)
  call void @cq_template_and_i64_unc(i32 %136, i32 %135, i32 %134)
  call void @cqrt_free(i32 %136)
  call void @cq_template_xor_i64_hl_unc(i32 %134, i32 %133, i64 -1)
  call void @cqrt_free(i32 %134)
  call void @cq_template_shl_i64_lh_unc(i32 %133, i64 -1, i32 %132)
  call void @cqrt_free(i32 %133)
  call void @cq_template_and_i64_hl_unc(i32 %132, i32 %19, i64 63)
  call void @cqrt_free(i32 %132)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %135, i32 %131, i32 %11, i32 %130)
  call void @cqrt_free(i32 %135)
  call void @cqrt_and_i1(i32 %146, i32 %129, i32 %131)
  call void @cqrt_free(i32 %131)
  call void @cqrt_and_i1(i32 %142, i32 %143, i32 %129)
  call void @cqrt_free(i32 %129)
  call void @cq_template_add_i64_unc(i32 %130, i32 %28, i32 %128)
  call void @cqrt_free(i32 %130)
  call void @cq_template_mul_i64_hl_unc(i32 %128, i32 %20, i64 8)
  call void @cqrt_free(i32 %128)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %142, i32 %20, i64 %127)
  call void @cqrt_free(i32 %142)
  %147 = call i32 @cqrt_pop()
  switch i32 %147, label %148 [
    i32 1, label %119
  ]

148:                                              ; preds = %120
  %149 = call i32 @cqrt_pop()
  %150 = zext i32 %149 to i64
  %151 = shl i64 %150, 32
  %152 = or i64 0, %151
  %153 = call i32 @cqrt_pop()
  %154 = zext i32 %153 to i64
  %155 = or i64 %152, %154
  %156 = call i32 @cqrt_pop()
  %157 = call i32 @cqrt_pop()
  %158 = call i32 @cqrt_pop()
  %159 = call i32 @cqrt_pop()
  %160 = call i32 @cqrt_pop()
  %161 = call i32 @cqrt_pop()
  %162 = call i32 @cqrt_pop()
  %163 = call i32 @cqrt_pop()
  %164 = call i32 @cqrt_pop()
  %165 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %165, i32 %164, i32 %163)
  call void @cqrt_free(i32 %163)
  call void @cq_template_select_i1_unc(i32 %162, i32 %161, i32 %160, i32 %159)
  call void @cqrt_free(i32 %162)
  call void @cqrt_and_i1(i32 %165, i32 %158, i32 %161)
  call void @cqrt_free(i32 %161)
  call void @cqrt_xor_i1(i32 %164, i32 %158)
  call void @cqrt_not_i1(i32 %158)
  call void @cqrt_free(i32 %158)
  call void @cqrt_free(i32 %160)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %164, i32 %157, i64 0)
  call void @cqrt_free(i32 %164)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %157, i32 %165, i32 %11, i32 %156)
  call void @cqrt_free(i32 %157)
  call void @cq_template_add_i64_hl_unc(i32 %156, i32 %28, i64 %155)
  call void @cqrt_free(i32 %156)
  br label %120

166:                                              ; preds = %96
  call void @cqrt_copy_i1(i32 %76, i32 %95)
  call void @cqrt_free(i32 %95)
  br label %167

167:                                              ; preds = %166
  switch i32 %73, label %119 [
    i32 1, label %120
  ]

168:                                              ; preds = %5
  %169 = call i32 @cqrt_alloc_i32(i32 0)
  %170 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %170)
  call void @cqrt_push(i32 0)
  call void @cqrt_push(i32 0)
  %171 = load i32, ptr @__cq_act_f, align 4
  %172 = add i32 %171, -1
  store i32 %172, ptr @__cq_act_f, align 4
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %169
}

declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @g, ptr @.cq.sig, ptr @__cq_q_g_11_t, ptr @__cq_q_g_11_t_ctl, ptr @__cq_q_g_11_t_unc, ptr @__cq_q_g_11_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_111_t, ptr @__cq_q_f_111_t_ctl, ptr @__cq_q_f_111_t_unc, ptr @__cq_q_f_111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_g_11_t_unc(i32 %out, i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_k, align 4
  store i32 %2, ptr @__cq_k, align 4
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_lshr_i64_hl(i32 %1, i64 6)
  %7 = call i32 @cq_template_add_i64_hl(i32 %0, i64 4)
  %8 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %7)
  %9 = call i32 @cq_template_abs_i32(i32 %8)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_icmp_ult_i64(i32 %6, i32 %10)
  %12 = call i32 @cq_template_add_i64_hl(i32 %0, i64 8)
  %13 = call i32 @cqrt_qram_load_i64_controlled(i32 %11, i32 %5, i32 %12)
  %14 = call i32 @cq_template_icmp_ult_i64_hl(i32 %1, i64 64)
  br label %15

15:                                               ; preds = %3
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %11, i32 %16)
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %16)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_qram_load_i64_controlled(i32 %16, i32 %5, i32 %13)
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 0)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_xor_i1(i32 %19, i32 %21)
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %22)
  %23 = call i32 @cq_template_select_i1(i32 %22, i32 %20, i32 %17)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %16, i32 %19, i32 %24)
  %25 = icmp ult i32 0, %2
  br i1 %25, label %26, label %54

26:                                               ; preds = %58, %15
  %from = phi i32 [ 0, %58 ], [ 1, %15 ]
  %27 = phi i32 [ 0, %15 ], [ %49, %58 ]
  %28 = phi i32 [ %24, %15 ], [ %67, %58 ]
  %29 = phi i64 [ 0, %15 ], [ %32, %58 ]
  %30 = phi i32 [ %19, %15 ], [ %62, %58 ]
  %31 = phi i32 [ %23, %15 ], [ %66, %58 ]
  call void @cqrt_push(i32 %from)
  %32 = add i64 %29, 1
  %33 = call i32 @cq_template_icmp_eq_i64_hl(i32 %6, i64 %32)
  %34 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %35 = call i32 @cq_template_add_i64(i32 %13, i32 %34)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %30, i32 %36)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %36, i32 %37)
  %38 = call i32 @cqrt_qram_load_i64_controlled(i32 %37, i32 %5, i32 %35)
  %39 = call i32 @cq_template_and_i64_hl(i32 %1, i64 63)
  %40 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %39)
  %41 = call i32 @cq_template_xor_i64_hl(i32 %40, i64 -1)
  %42 = call i32 @cq_template_and_i64(i32 %38, i32 %41)
  %43 = call i32 @cq_template_icmp_eq_i64_hl(i32 %42, i64 0)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %33, i32 %30, i32 %44)
  %45 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %44, i32 %45)
  %46 = call i32 @cq_template_select_i1(i32 %45, i32 %43, i32 %31)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %30, i32 %47)
  call void @cqrt_and_i1(i32 %30, i32 %33, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %28, i32 %47, i32 %48)
  %49 = add i32 %27, 1
  %50 = icmp ult i32 %49, %2
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %34)
  %51 = trunc i64 %32 to i32
  call void @cqrt_push(i32 %51)
  %52 = lshr i64 %32, 32
  %53 = trunc i64 %52 to i32
  call void @cqrt_push(i32 %53)
  br i1 %50, label %58, label %54

54:                                               ; preds = %26, %15
  %55 = phi i32 [ 0, %15 ], [ 1, %26 ]
  %56 = phi i32 [ %23, %15 ], [ %46, %26 ]
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %56, i32 %57)
  br label %71

58:                                               ; preds = %26
  %59 = mul i64 %32, 8
  %60 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %59)
  %61 = call i32 @cqrt_qram_load_i64_controlled(i32 %48, i32 %5, i32 %60)
  %62 = call i32 @cq_template_icmp_eq_i64_hl(i32 %61, i64 0)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %64)
  call void @cqrt_xor_i1(i32 %62, i32 %64)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %48, i32 %64, i32 %65)
  %66 = call i32 @cq_template_select_i1(i32 %65, i32 %63, i32 %46)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %48, i32 %62, i32 %67)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %60)
  %68 = trunc i64 %59 to i32
  call void @cqrt_push(i32 %68)
  %69 = lshr i64 %59, 32
  %70 = trunc i64 %69 to i32
  call void @cqrt_push(i32 %70)
  br label %26

71:                                               ; preds = %54
  %72 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 8)
  %73 = call i32 @cq_template_add_i64(i32 %13, i32 %72)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %14, i32 %11, i32 %74)
  %75 = call i32 @cqrt_qram_load_i64_controlled(i32 %74, i32 %5, i32 %73)
  %76 = call i32 @cq_template_and_i64_hl(i32 %1, i64 63)
  %77 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %76)
  %78 = call i32 @cq_template_xor_i64_hl(i32 %77, i64 -1)
  %79 = call i32 @cq_template_and_i64(i32 %75, i32 %78)
  %80 = call i32 @cq_template_icmp_eq_i64_hl(i32 %79, i64 0)
  %81 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)
  %82 = call i32 @cq_template_select_i1(i32 %14, i32 %80, i32 %57)
  %83 = call i32 @cq_template_select_i1(i32 %11, i32 %82, i32 %81)
  %84 = call i32 @cq_template_zext_i1_to_i32(i32 %83)
  call void @cqrt_copy_i32(i32 %84, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %84, i32 %83)
  call void @cqrt_free(i32 %84)
  call void @cq_template_select_i1_unc(i32 %83, i32 %11, i32 %82, i32 %81)
  call void @cqrt_free(i32 %83)
  call void @cq_template_select_i1_unc(i32 %82, i32 %14, i32 %80, i32 %57)
  call void @cqrt_free(i32 %82)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %81, i32 %8, i32 0)
  call void @cqrt_free(i32 %81)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %80, i32 %79, i64 0)
  call void @cqrt_free(i32 %80)
  call void @cq_template_and_i64_unc(i32 %79, i32 %75, i32 %78)
  call void @cqrt_free(i32 %79)
  call void @cq_template_xor_i64_hl_unc(i32 %78, i32 %77, i64 -1)
  call void @cqrt_free(i32 %78)
  call void @cq_template_shl_i64_lh_unc(i32 %77, i64 -1, i32 %76)
  call void @cqrt_free(i32 %77)
  call void @cq_template_and_i64_hl_unc(i32 %76, i32 %1, i64 63)
  call void @cqrt_free(i32 %76)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %75, i32 %74, i32 %5, i32 %73)
  call void @cqrt_free(i32 %75)
  call void @cqrt_and_i1(i32 %14, i32 %11, i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cq_template_add_i64_unc(i32 %73, i32 %13, i32 %72)
  call void @cqrt_free(i32 %73)
  call void @cq_template_mul_i64_hl_unc(i32 %72, i32 %6, i64 8)
  call void @cqrt_free(i32 %72)
  br label %133

85:                                               ; preds = %86
  call void @cqrt_and_i1(i32 %16, i32 %19, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cq_template_select_i1_unc(i32 %23, i32 %22, i32 %20, i32 %17)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cqrt_xor_i1(i32 %19, i32 %21)
  call void @cqrt_not_i1(i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %20)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %18, i64 0)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %18, i32 %16, i32 %5, i32 %13)
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %16)
  call void @cqrt_xor_i1(i32 %11, i32 %16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %14, i32 %1, i64 64)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %13, i32 %11, i32 %5, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %0, i64 8)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_ult_i64_unc(i32 %11, i32 %6, i32 %10)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_abs_i32_unc(i32 %9, i32 %8)
  call void @cqrt_free(i32 %9)
  call void @cqrt_qram_load_i32_unc(i32 %8, i32 %5, i32 %7)
  call void @cqrt_free(i32 %8)
  call void @cq_template_add_i64_hl_unc(i32 %7, i32 %0, i64 4)
  call void @cqrt_free(i32 %7)
  call void @cq_template_lshr_i64_hl_unc(i32 %6, i32 %1, i64 6)
  call void @cqrt_free(i32 %6)
  call void @cqrt_free(i32 %out)
  store i32 %4, ptr @__cq_k, align 4
  ret void

86:                                               ; preds = %134, %87
  br label %85

87:                                               ; preds = %134, %115
  %88 = call i32 @cqrt_pop()
  %89 = zext i32 %88 to i64
  %90 = shl i64 %89, 32
  %91 = or i64 0, %90
  %92 = call i32 @cqrt_pop()
  %93 = zext i32 %92 to i64
  %94 = or i64 %91, %93
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
  %110 = call i32 @cqrt_pop()
  %111 = call i32 @cqrt_pop()
  %112 = call i32 @cqrt_pop()
  %113 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %113, i32 %112, i32 %111)
  call void @cqrt_free(i32 %111)
  call void @cqrt_and_i1(i32 %110, i32 %109, i32 %112)
  call void @cqrt_xor_i1(i32 %110, i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cq_template_select_i1_unc(i32 %108, i32 %107, i32 %106, i32 %105)
  call void @cqrt_free(i32 %108)
  call void @cqrt_and_i1(i32 %113, i32 %104, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %109, i32 %110, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %106, i32 %103, i64 0)
  call void @cqrt_free(i32 %106)
  call void @cq_template_and_i64_unc(i32 %103, i32 %102, i32 %101)
  call void @cqrt_free(i32 %103)
  call void @cq_template_xor_i64_hl_unc(i32 %101, i32 %100, i64 -1)
  call void @cqrt_free(i32 %101)
  call void @cq_template_shl_i64_lh_unc(i32 %100, i64 -1, i32 %99)
  call void @cqrt_free(i32 %100)
  call void @cq_template_and_i64_hl_unc(i32 %99, i32 %1, i64 63)
  call void @cqrt_free(i32 %99)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %102, i32 %98, i32 %5, i32 %97)
  call void @cqrt_free(i32 %102)
  call void @cqrt_and_i1(i32 %113, i32 %96, i32 %98)
  call void @cqrt_free(i32 %98)
  call void @cqrt_and_i1(i32 %109, i32 %110, i32 %96)
  call void @cqrt_free(i32 %96)
  call void @cq_template_add_i64_unc(i32 %97, i32 %13, i32 %95)
  call void @cqrt_free(i32 %97)
  call void @cq_template_mul_i64_hl_unc(i32 %95, i32 %6, i64 8)
  call void @cqrt_free(i32 %95)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %109, i32 %6, i64 %94)
  call void @cqrt_free(i32 %109)
  %114 = call i32 @cqrt_pop()
  switch i32 %114, label %115 [
    i32 1, label %86
  ]

115:                                              ; preds = %87
  %116 = call i32 @cqrt_pop()
  %117 = zext i32 %116 to i64
  %118 = shl i64 %117, 32
  %119 = or i64 0, %118
  %120 = call i32 @cqrt_pop()
  %121 = zext i32 %120 to i64
  %122 = or i64 %119, %121
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
  call void @cqrt_and_i1(i32 %132, i32 %131, i32 %130)
  call void @cqrt_free(i32 %130)
  call void @cq_template_select_i1_unc(i32 %129, i32 %128, i32 %127, i32 %126)
  call void @cqrt_free(i32 %129)
  call void @cqrt_and_i1(i32 %132, i32 %125, i32 %128)
  call void @cqrt_free(i32 %128)
  call void @cqrt_xor_i1(i32 %131, i32 %125)
  call void @cqrt_not_i1(i32 %125)
  call void @cqrt_free(i32 %125)
  call void @cqrt_free(i32 %127)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %131, i32 %124, i64 0)
  call void @cqrt_free(i32 %131)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %124, i32 %132, i32 %5, i32 %123)
  call void @cqrt_free(i32 %124)
  call void @cq_template_add_i64_hl_unc(i32 %123, i32 %13, i64 %122)
  call void @cqrt_free(i32 %123)
  br label %87

133:                                              ; preds = %71
  call void @cqrt_copy_i1(i32 %56, i32 %57)
  call void @cqrt_free(i32 %57)
  br label %134

134:                                              ; preds = %133
  switch i32 %55, label %86 [
    i32 1, label %87
  ]
}

define internal void @__cq_q_g_11_t_ctl_unc(i32 %0, i32 %out, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = load i32, ptr @__cq_act_g, align 4
  %7 = add i32 %6, 1
  store i32 %7, ptr @__cq_act_g, align 4
  %8 = icmp ult i32 %6, %3
  br i1 %8, label %9, label %149

9:                                                ; preds = %4
  %10 = call i32 @__cq_mem()
  %11 = call i32 @cq_template_lshr_i64_hl(i32 %2, i64 6)
  %12 = call i32 @cq_template_add_i64_hl(i32 %1, i64 4)
  %13 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %10, i32 %12)
  %14 = call i32 @cq_template_abs_i32(i32 %13)
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %16 = call i32 @cq_template_icmp_ult_i64(i32 %11, i32 %15)
  %17 = call i32 @cq_template_add_i64_hl(i32 %1, i64 8)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  %19 = call i32 @cqrt_qram_load_i64_controlled(i32 %18, i32 %10, i32 %17)
  %20 = call i32 @cq_template_icmp_ult_i64_hl(i32 %2, i64 64)
  br label %21

21:                                               ; preds = %9
  %22 = call i32 @cqrt_alloc_i1(i1 false)
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %23)
  call void @cqrt_and_i1(i32 %16, i32 %20, i32 %23)
  call void @cqrt_and_i1(i32 %0, i32 %23, i32 %22)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_qram_load_i64_controlled(i32 %22, i32 %10, i32 %19)
  %26 = call i32 @cq_template_icmp_eq_i64_hl(i32 %25, i64 0)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %28, i32 %29)
  %30 = call i32 @cq_template_select_i1(i32 %29, i32 %27, i32 %24)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %31)
  %32 = icmp ult i32 0, %3
  br i1 %32, label %33, label %61

33:                                               ; preds = %65, %21
  %from = phi i32 [ 0, %65 ], [ 1, %21 ]
  %34 = phi i32 [ 0, %21 ], [ %56, %65 ]
  %35 = phi i32 [ %31, %21 ], [ %74, %65 ]
  %36 = phi i64 [ 0, %21 ], [ %39, %65 ]
  %37 = phi i32 [ %26, %21 ], [ %69, %65 ]
  %38 = phi i32 [ %30, %21 ], [ %73, %65 ]
  call void @cqrt_push(i32 %from)
  %39 = add i64 %36, 1
  %40 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %39)
  %41 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %42 = call i32 @cq_template_add_i64(i32 %19, i32 %41)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %37, i32 %43)
  %44 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %43, i32 %44)
  %45 = call i32 @cqrt_qram_load_i64_controlled(i32 %44, i32 %10, i32 %42)
  %46 = call i32 @cq_template_and_i64_hl(i32 %2, i64 63)
  %47 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %46)
  %48 = call i32 @cq_template_xor_i64_hl(i32 %47, i64 -1)
  %49 = call i32 @cq_template_and_i64(i32 %45, i32 %48)
  %50 = call i32 @cq_template_icmp_eq_i64_hl(i32 %49, i64 0)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %40, i32 %37, i32 %51)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %51, i32 %52)
  %53 = call i32 @cq_template_select_i1(i32 %52, i32 %50, i32 %38)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %37, i32 %54)
  call void @cqrt_and_i1(i32 %37, i32 %40, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %35, i32 %54, i32 %55)
  %56 = add i32 %34, 1
  %57 = icmp ult i32 %56, %3
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %41)
  %58 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %58)
  %59 = lshr i64 %39, 32
  %60 = trunc i64 %59 to i32
  call void @cqrt_push(i32 %60)
  br i1 %57, label %65, label %61

61:                                               ; preds = %33, %21
  %62 = phi i32 [ 0, %21 ], [ 1, %33 ]
  %63 = phi i32 [ %30, %21 ], [ %53, %33 ]
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %63, i32 %64)
  br label %78

65:                                               ; preds = %33
  %66 = mul i64 %39, 8
  %67 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %66)
  %68 = call i32 @cqrt_qram_load_i64_controlled(i32 %55, i32 %10, i32 %67)
  %69 = call i32 @cq_template_icmp_eq_i64_hl(i32 %68, i64 0)
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %71)
  call void @cqrt_xor_i1(i32 %69, i32 %71)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %71, i32 %72)
  %73 = call i32 @cq_template_select_i1(i32 %72, i32 %70, i32 %53)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %55, i32 %69, i32 %74)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %67)
  %75 = trunc i64 %66 to i32
  call void @cqrt_push(i32 %75)
  %76 = lshr i64 %66, 32
  %77 = trunc i64 %76 to i32
  call void @cqrt_push(i32 %77)
  br label %33

78:                                               ; preds = %61
  %79 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 8)
  %80 = call i32 @cq_template_add_i64(i32 %19, i32 %79)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %82)
  call void @cqrt_and_i1(i32 %0, i32 %82, i32 %81)
  %83 = call i32 @cqrt_qram_load_i64_controlled(i32 %81, i32 %10, i32 %80)
  %84 = call i32 @cq_template_and_i64_hl(i32 %2, i64 63)
  %85 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %84)
  %86 = call i32 @cq_template_xor_i64_hl(i32 %85, i64 -1)
  %87 = call i32 @cq_template_and_i64(i32 %83, i32 %86)
  %88 = call i32 @cq_template_icmp_eq_i64_hl(i32 %87, i64 0)
  %89 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %91)
  call void @cqrt_and_i1(i32 %0, i32 %91, i32 %90)
  %92 = call i32 @cq_template_select_i1(i32 %90, i32 %88, i32 %64)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %94)
  call void @cqrt_xor_i1(i32 %16, i32 %94)
  call void @cqrt_and_i1(i32 %0, i32 %94, i32 %93)
  %95 = call i32 @cq_template_select_i1(i32 %93, i32 %89, i32 %92)
  %96 = call i32 @cq_template_zext_i1_to_i32(i32 %95)
  call void @cqrt_copy_i32(i32 %96, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %96, i32 %95)
  call void @cqrt_free(i32 %96)
  call void @cq_template_select_i1_unc(i32 %95, i32 %93, i32 %89, i32 %92)
  call void @cqrt_free(i32 %95)
  call void @cqrt_and_i1(i32 %0, i32 %94, i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cqrt_xor_i1(i32 %16, i32 %94)
  call void @cqrt_not_i1(i32 %94)
  call void @cqrt_free(i32 %94)
  call void @cq_template_select_i1_unc(i32 %92, i32 %90, i32 %88, i32 %64)
  call void @cqrt_free(i32 %92)
  call void @cqrt_and_i1(i32 %0, i32 %91, i32 %90)
  call void @cqrt_free(i32 %90)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %89, i32 %13, i32 0)
  call void @cqrt_free(i32 %89)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %88, i32 %87, i64 0)
  call void @cqrt_free(i32 %88)
  call void @cq_template_and_i64_unc(i32 %87, i32 %83, i32 %86)
  call void @cqrt_free(i32 %87)
  call void @cq_template_xor_i64_hl_unc(i32 %86, i32 %85, i64 -1)
  call void @cqrt_free(i32 %86)
  call void @cq_template_shl_i64_lh_unc(i32 %85, i64 -1, i32 %84)
  call void @cqrt_free(i32 %85)
  call void @cq_template_and_i64_hl_unc(i32 %84, i32 %2, i64 63)
  call void @cqrt_free(i32 %84)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %83, i32 %81, i32 %10, i32 %80)
  call void @cqrt_free(i32 %83)
  call void @cqrt_and_i1(i32 %0, i32 %82, i32 %81)
  call void @cqrt_free(i32 %81)
  call void @cqrt_and_i1(i32 %20, i32 %16, i32 %82)
  call void @cqrt_free(i32 %82)
  call void @cq_template_add_i64_unc(i32 %80, i32 %19, i32 %79)
  call void @cqrt_free(i32 %80)
  call void @cq_template_mul_i64_hl_unc(i32 %79, i32 %11, i64 8)
  call void @cqrt_free(i32 %79)
  br label %147

97:                                               ; preds = %100
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cq_template_select_i1_unc(i32 %30, i32 %29, i32 %27, i32 %24)
  call void @cqrt_free(i32 %30)
  call void @cqrt_and_i1(i32 %22, i32 %28, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_xor_i1(i32 %26, i32 %28)
  call void @cqrt_not_i1(i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_free(i32 %27)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %26, i32 %25, i64 0)
  call void @cqrt_free(i32 %26)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %25, i32 %22, i32 %10, i32 %19)
  call void @cqrt_free(i32 %25)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %0, i32 %23, i32 %22)
  call void @cqrt_free(i32 %22)
  call void @cqrt_and_i1(i32 %16, i32 %20, i32 %23)
  call void @cqrt_xor_i1(i32 %16, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %20, i32 %2, i64 64)
  call void @cqrt_free(i32 %20)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %19, i32 %18, i32 %10, i32 %17)
  call void @cqrt_free(i32 %19)
  call void @cqrt_and_i1(i32 %0, i32 %16, i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i64_hl_unc(i32 %17, i32 %1, i64 8)
  call void @cqrt_free(i32 %17)
  call void @cq_template_icmp_ult_i64_unc(i32 %16, i32 %11, i32 %15)
  call void @cqrt_free(i32 %16)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_abs_i32_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %13, i32 %0, i32 %10, i32 %12)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %1, i64 4)
  call void @cqrt_free(i32 %12)
  call void @cq_template_lshr_i64_hl_unc(i32 %11, i32 %2, i64 6)
  call void @cqrt_free(i32 %11)
  %98 = load i32, ptr @__cq_act_g, align 4
  %99 = add i32 %98, -1
  store i32 %99, ptr @__cq_act_g, align 4
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

100:                                              ; preds = %148, %101
  br label %97

101:                                              ; preds = %148, %129
  %102 = call i32 @cqrt_pop()
  %103 = zext i32 %102 to i64
  %104 = shl i64 %103, 32
  %105 = or i64 0, %104
  %106 = call i32 @cqrt_pop()
  %107 = zext i32 %106 to i64
  %108 = or i64 %105, %107
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
  call void @cq_template_and_i64_hl_unc(i32 %113, i32 %2, i64 63)
  call void @cqrt_free(i32 %113)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %116, i32 %112, i32 %10, i32 %111)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %127, i32 %110, i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cqrt_and_i1(i32 %123, i32 %124, i32 %110)
  call void @cqrt_free(i32 %110)
  call void @cq_template_add_i64_unc(i32 %111, i32 %19, i32 %109)
  call void @cqrt_free(i32 %111)
  call void @cq_template_mul_i64_hl_unc(i32 %109, i32 %11, i64 8)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %123, i32 %11, i64 %108)
  call void @cqrt_free(i32 %123)
  %128 = call i32 @cqrt_pop()
  switch i32 %128, label %129 [
    i32 1, label %100
  ]

129:                                              ; preds = %101
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
  %146 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %146, i32 %145, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cq_template_select_i1_unc(i32 %143, i32 %142, i32 %141, i32 %140)
  call void @cqrt_free(i32 %143)
  call void @cqrt_and_i1(i32 %146, i32 %139, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_xor_i1(i32 %145, i32 %139)
  call void @cqrt_not_i1(i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_free(i32 %141)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %145, i32 %138, i64 0)
  call void @cqrt_free(i32 %145)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %138, i32 %146, i32 %10, i32 %137)
  call void @cqrt_free(i32 %138)
  call void @cq_template_add_i64_hl_unc(i32 %137, i32 %19, i64 %136)
  call void @cqrt_free(i32 %137)
  br label %101

147:                                              ; preds = %78
  call void @cqrt_copy_i1(i32 %63, i32 %64)
  call void @cqrt_free(i32 %64)
  br label %148

148:                                              ; preds = %147
  switch i32 %62, label %100 [
    i32 1, label %101
  ]

149:                                              ; preds = %4
  %150 = load i32, ptr @__cq_act_g, align 4
  %151 = add i32 %150, -1
  store i32 %151, ptr @__cq_act_g, align 4
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_f_111_t_unc(i32 %out, i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_k, align 4
  store i32 %3, ptr @__cq_k, align 4
  %6 = call i32 @cqrt_pop()
  %7 = call i32 @cqrt_pop()
  %8 = call i32 @__cq_mem()
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 16)
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @zs to i64))
  %13 = call i32 @cq_template_and_i32_hl(i32 %6, i32 255)
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)
  %15 = call i32 @cq_template_lshr_i64_hl(i32 %14, i64 6)
  %16 = call i32 @cq_template_add_i64_hl(i32 %12, i64 4)
  %17 = call i32 @cqrt_qram_load_i32(i32 %8, i32 %16)
  %18 = call i32 @cq_template_abs_i32(i32 %17)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)
  %20 = call i32 @cq_template_icmp_ult_i64(i32 %15, i32 %19)
  %21 = call i32 @cq_template_add_i64_hl(i32 %12, i64 8)
  %22 = call i32 @cqrt_qram_load_i64_controlled(i32 %20, i32 %8, i32 %21)
  %23 = call i32 @cq_template_icmp_ult_i32_hl(i32 %13, i32 64)
  br label %24

24:                                               ; preds = %4
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %20, i32 %25)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %25)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  %27 = call i32 @cqrt_qram_load_i64_controlled(i32 %25, i32 %8, i32 %22)
  %28 = call i32 @cq_template_icmp_eq_i64_hl(i32 %27, i64 0)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_xor_i1(i32 %28, i32 %30)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %25, i32 %30, i32 %31)
  %32 = call i32 @cq_template_select_i1(i32 %31, i32 %29, i32 %26)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %25, i32 %28, i32 %33)
  %34 = call i32 @llvm.umin.i32(i32 %3, i32 3)
  %35 = icmp ult i32 %3, 3
  %36 = icmp ult i32 0, %34
  br i1 %36, label %37, label %65

37:                                               ; preds = %68, %24
  %from = phi i32 [ 0, %68 ], [ 1, %24 ]
  %38 = phi i32 [ 0, %24 ], [ %60, %68 ]
  %39 = phi i32 [ %33, %24 ], [ %77, %68 ]
  %40 = phi i64 [ 0, %24 ], [ %43, %68 ]
  %41 = phi i32 [ %28, %24 ], [ %72, %68 ]
  %42 = phi i32 [ %32, %24 ], [ %76, %68 ]
  call void @cqrt_push(i32 %from)
  %43 = add i64 %40, 1
  %44 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 %43)
  %45 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 8)
  %46 = call i32 @cq_template_add_i64(i32 %22, i32 %45)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %41, i32 %47)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %47, i32 %48)
  %49 = call i32 @cqrt_qram_load_i64_controlled(i32 %48, i32 %8, i32 %46)
  %50 = call i32 @cq_template_and_i64_hl(i32 %14, i64 63)
  %51 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %50)
  %52 = call i32 @cq_template_xor_i64_hl(i32 %51, i64 -1)
  %53 = call i32 @cq_template_and_i64(i32 %49, i32 %52)
  %54 = call i32 @cq_template_icmp_eq_i64_hl(i32 %53, i64 0)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %44, i32 %41, i32 %55)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %55, i32 %56)
  %57 = call i32 @cq_template_select_i1(i32 %56, i32 %54, i32 %42)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %41, i32 %58)
  call void @cqrt_and_i1(i32 %41, i32 %44, i32 %58)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %39, i32 %58, i32 %59)
  %60 = add i32 %38, 1
  %61 = icmp ult i32 %60, %34
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %45)
  %62 = trunc i64 %43 to i32
  call void @cqrt_push(i32 %62)
  %63 = lshr i64 %43, 32
  %64 = trunc i64 %63 to i32
  call void @cqrt_push(i32 %64)
  br i1 %61, label %68, label %65

65:                                               ; preds = %37, %24
  %66 = phi i32 [ 0, %24 ], [ 1, %37 ]
  %67 = phi i32 [ %32, %24 ], [ %57, %37 ]
  br i1 %35, label %81, label %82

68:                                               ; preds = %37
  %69 = mul i64 %43, 8
  %70 = call i32 @cq_template_add_i64_hl(i32 %22, i64 %69)
  %71 = call i32 @cqrt_qram_load_i64_controlled(i32 %59, i32 %8, i32 %70)
  %72 = call i32 @cq_template_icmp_eq_i64_hl(i32 %71, i64 0)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_xor_i1(i32 %72, i32 %74)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %59, i32 %74, i32 %75)
  %76 = call i32 @cq_template_select_i1(i32 %75, i32 %73, i32 %57)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %59, i32 %72, i32 %77)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %72)
  call void @cqrt_push(i32 %77)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %70)
  %78 = trunc i64 %69 to i32
  call void @cqrt_push(i32 %78)
  %79 = lshr i64 %69, 32
  %80 = trunc i64 %79 to i32
  call void @cqrt_push(i32 %80)
  br label %37

81:                                               ; preds = %65
  br label %83

82:                                               ; preds = %65
  br label %83

83:                                               ; preds = %82, %81
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %67, i32 %84)
  br label %85

85:                                               ; preds = %83
  %86 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 8)
  %87 = call i32 @cq_template_add_i64(i32 %22, i32 %86)
  %88 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %23, i32 %20, i32 %88)
  %89 = call i32 @cqrt_qram_load_i64_controlled(i32 %88, i32 %8, i32 %87)
  %90 = call i32 @cq_template_and_i64_hl(i32 %14, i64 63)
  %91 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %90)
  %92 = call i32 @cq_template_xor_i64_hl(i32 %91, i64 -1)
  %93 = call i32 @cq_template_and_i64(i32 %89, i32 %92)
  %94 = call i32 @cq_template_icmp_eq_i64_hl(i32 %93, i64 0)
  %95 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 0)
  %96 = call i32 @cq_template_select_i1(i32 %23, i32 %94, i32 %84)
  %97 = call i32 @cq_template_select_i1(i32 %20, i32 %96, i32 %95)
  %98 = call i32 @cq_template_zext_i1_to_i32(i32 %97)
  call void @cqrt_copy_i32(i32 %98, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %98, i32 %97)
  call void @cqrt_free(i32 %98)
  call void @cq_template_select_i1_unc(i32 %97, i32 %20, i32 %96, i32 %95)
  call void @cqrt_free(i32 %97)
  call void @cq_template_select_i1_unc(i32 %96, i32 %23, i32 %94, i32 %84)
  call void @cqrt_free(i32 %96)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %95, i32 %17, i32 0)
  call void @cqrt_free(i32 %95)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %94, i32 %93, i64 0)
  call void @cqrt_free(i32 %94)
  call void @cq_template_and_i64_unc(i32 %93, i32 %89, i32 %92)
  call void @cqrt_free(i32 %93)
  call void @cq_template_xor_i64_hl_unc(i32 %92, i32 %91, i64 -1)
  call void @cqrt_free(i32 %92)
  call void @cq_template_shl_i64_lh_unc(i32 %91, i64 -1, i32 %90)
  call void @cqrt_free(i32 %91)
  call void @cq_template_and_i64_hl_unc(i32 %90, i32 %14, i64 63)
  call void @cqrt_free(i32 %90)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %89, i32 %88, i32 %8, i32 %87)
  call void @cqrt_free(i32 %89)
  call void @cqrt_and_i1(i32 %23, i32 %20, i32 %88)
  call void @cqrt_free(i32 %88)
  call void @cq_template_add_i64_unc(i32 %87, i32 %22, i32 %86)
  call void @cqrt_free(i32 %87)
  call void @cq_template_mul_i64_hl_unc(i32 %86, i32 %15, i64 8)
  call void @cqrt_free(i32 %86)
  br label %147

99:                                               ; preds = %100
  call void @cqrt_and_i1(i32 %25, i32 %28, i32 %33)
  call void @cqrt_free(i32 %33)
  call void @cq_template_select_i1_unc(i32 %32, i32 %31, i32 %29, i32 %26)
  call void @cqrt_free(i32 %32)
  call void @cqrt_and_i1(i32 %25, i32 %30, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_xor_i1(i32 %28, i32 %30)
  call void @cqrt_not_i1(i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %29)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %28, i32 %27, i64 0)
  call void @cqrt_free(i32 %28)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %27, i32 %25, i32 %8, i32 %22)
  call void @cqrt_free(i32 %27)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %20, i32 %23, i32 %25)
  call void @cqrt_xor_i1(i32 %20, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %23, i32 %13, i32 64)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %22, i32 %20, i32 %8, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %12, i64 8)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_ult_i64_unc(i32 %20, i32 %15, i32 %19)
  call void @cqrt_free(i32 %20)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_abs_i32_unc(i32 %18, i32 %17)
  call void @cqrt_free(i32 %18)
  call void @cqrt_qram_load_i32_unc(i32 %17, i32 %8, i32 %16)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %12, i64 4)
  call void @cqrt_free(i32 %16)
  call void @cq_template_lshr_i64_hl_unc(i32 %15, i32 %14, i64 6)
  call void @cqrt_free(i32 %15)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)
  call void @cqrt_free(i32 %14)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %6, i32 255)
  call void @cqrt_free(i32 %13)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @zs to i64))
  call void @cqrt_free(i32 %12)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 16)
  call void @cqrt_free(i32 %11)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 1)
  call void @cqrt_free(i32 %9)
  call void @cqrt_free(i32 %out)
  store i32 %5, ptr @__cq_k, align 4
  ret void

100:                                              ; preds = %148, %101
  br label %99

101:                                              ; preds = %148, %129
  %102 = call i32 @cqrt_pop()
  %103 = zext i32 %102 to i64
  %104 = shl i64 %103, 32
  %105 = or i64 0, %104
  %106 = call i32 @cqrt_pop()
  %107 = zext i32 %106 to i64
  %108 = or i64 %105, %107
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
  call void @cq_template_and_i64_hl_unc(i32 %113, i32 %14, i64 63)
  call void @cqrt_free(i32 %113)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %116, i32 %112, i32 %8, i32 %111)
  call void @cqrt_free(i32 %116)
  call void @cqrt_and_i1(i32 %127, i32 %110, i32 %112)
  call void @cqrt_free(i32 %112)
  call void @cqrt_and_i1(i32 %123, i32 %124, i32 %110)
  call void @cqrt_free(i32 %110)
  call void @cq_template_add_i64_unc(i32 %111, i32 %22, i32 %109)
  call void @cqrt_free(i32 %111)
  call void @cq_template_mul_i64_hl_unc(i32 %109, i32 %15, i64 8)
  call void @cqrt_free(i32 %109)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %123, i32 %15, i64 %108)
  call void @cqrt_free(i32 %123)
  %128 = call i32 @cqrt_pop()
  switch i32 %128, label %129 [
    i32 1, label %100
  ]

129:                                              ; preds = %101
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
  %146 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %146, i32 %145, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cq_template_select_i1_unc(i32 %143, i32 %142, i32 %141, i32 %140)
  call void @cqrt_free(i32 %143)
  call void @cqrt_and_i1(i32 %146, i32 %139, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_xor_i1(i32 %145, i32 %139)
  call void @cqrt_not_i1(i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_free(i32 %141)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %145, i32 %138, i64 0)
  call void @cqrt_free(i32 %145)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %138, i32 %146, i32 %8, i32 %137)
  call void @cqrt_free(i32 %138)
  call void @cq_template_add_i64_hl_unc(i32 %137, i32 %22, i64 %136)
  call void @cqrt_free(i32 %137)
  br label %101

147:                                              ; preds = %85
  call void @cqrt_copy_i1(i32 %67, i32 %84)
  call void @cqrt_free(i32 %84)
  br label %148

148:                                              ; preds = %147
  switch i32 %66, label %100 [
    i32 1, label %101
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
  br i1 %11, label %12, label %163

12:                                               ; preds = %5
  %13 = call i32 @__cq_mem()
  %14 = call i32 @cq_template_and_i32_hl(i32 %8, i32 1)
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)
  %16 = call i32 @cq_template_mul_i64_hl(i32 %15, i64 16)
  %17 = call i32 @cq_template_add_i64_hl(i32 %16, i64 ptrtoint (ptr @zs to i64))
  %18 = call i32 @cq_template_and_i32_hl(i32 %7, i32 255)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)
  %20 = call i32 @cq_template_lshr_i64_hl(i32 %19, i64 6)
  %21 = call i32 @cq_template_add_i64_hl(i32 %17, i64 4)
  %22 = call i32 @cqrt_qram_load_i32_controlled(i32 %0, i32 %13, i32 %21)
  %23 = call i32 @cq_template_abs_i32(i32 %22)
  %24 = call i32 @cq_template_zext_i32_to_i64(i32 %23)
  %25 = call i32 @cq_template_icmp_ult_i64(i32 %20, i32 %24)
  %26 = call i32 @cq_template_add_i64_hl(i32 %17, i64 8)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %27)
  %28 = call i32 @cqrt_qram_load_i64_controlled(i32 %27, i32 %13, i32 %26)
  %29 = call i32 @cq_template_icmp_ult_i32_hl(i32 %18, i32 64)
  br label %30

30:                                               ; preds = %12
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  %32 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %25, i32 %32)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %32)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  %34 = call i32 @cqrt_qram_load_i64_controlled(i32 %31, i32 %13, i32 %28)
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %34, i64 0)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_xor_i1(i32 %35, i32 %37)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %38)
  %39 = call i32 @cq_template_select_i1(i32 %38, i32 %36, i32 %33)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %31, i32 %35, i32 %40)
  %41 = call i32 @llvm.umin.i32(i32 %4, i32 3)
  %42 = icmp ult i32 %4, 3
  %43 = icmp ult i32 0, %41
  br i1 %43, label %44, label %72

44:                                               ; preds = %75, %30
  %from = phi i32 [ 0, %75 ], [ 1, %30 ]
  %45 = phi i32 [ 0, %30 ], [ %67, %75 ]
  %46 = phi i32 [ %40, %30 ], [ %84, %75 ]
  %47 = phi i64 [ 0, %30 ], [ %50, %75 ]
  %48 = phi i32 [ %35, %30 ], [ %79, %75 ]
  %49 = phi i32 [ %39, %30 ], [ %83, %75 ]
  call void @cqrt_push(i32 %from)
  %50 = add i64 %47, 1
  %51 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 %50)
  %52 = call i32 @cq_template_mul_i64_hl(i32 %20, i64 8)
  %53 = call i32 @cq_template_add_i64(i32 %28, i32 %52)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %48, i32 %54)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %54, i32 %55)
  %56 = call i32 @cqrt_qram_load_i64_controlled(i32 %55, i32 %13, i32 %53)
  %57 = call i32 @cq_template_and_i64_hl(i32 %19, i64 63)
  %58 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %57)
  %59 = call i32 @cq_template_xor_i64_hl(i32 %58, i64 -1)
  %60 = call i32 @cq_template_and_i64(i32 %56, i32 %59)
  %61 = call i32 @cq_template_icmp_eq_i64_hl(i32 %60, i64 0)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %51, i32 %48, i32 %62)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %62, i32 %63)
  %64 = call i32 @cq_template_select_i1(i32 %63, i32 %61, i32 %49)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %48, i32 %65)
  call void @cqrt_and_i1(i32 %48, i32 %51, i32 %65)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %46, i32 %65, i32 %66)
  %67 = add i32 %45, 1
  %68 = icmp ult i32 %67, %41
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %52)
  %69 = trunc i64 %50 to i32
  call void @cqrt_push(i32 %69)
  %70 = lshr i64 %50, 32
  %71 = trunc i64 %70 to i32
  call void @cqrt_push(i32 %71)
  br i1 %68, label %75, label %72

72:                                               ; preds = %44, %30
  %73 = phi i32 [ 0, %30 ], [ 1, %44 ]
  %74 = phi i32 [ %39, %30 ], [ %64, %44 ]
  br i1 %42, label %88, label %89

75:                                               ; preds = %44
  %76 = mul i64 %50, 8
  %77 = call i32 @cq_template_add_i64_hl(i32 %28, i64 %76)
  %78 = call i32 @cqrt_qram_load_i64_controlled(i32 %66, i32 %13, i32 %77)
  %79 = call i32 @cq_template_icmp_eq_i64_hl(i32 %78, i64 0)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %81)
  call void @cqrt_xor_i1(i32 %79, i32 %81)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %81, i32 %82)
  %83 = call i32 @cq_template_select_i1(i32 %82, i32 %80, i32 %64)
  %84 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %66, i32 %79, i32 %84)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %79)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %78)
  call void @cqrt_push(i32 %77)
  %85 = trunc i64 %76 to i32
  call void @cqrt_push(i32 %85)
  %86 = lshr i64 %76, 32
  %87 = trunc i64 %86 to i32
  call void @cqrt_push(i32 %87)
  br label %44

88:                                               ; preds = %72
  br label %90

89:                                               ; preds = %72
  br label %90

90:                                               ; preds = %89, %88
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %74, i32 %91)
  br label %92

92:                                               ; preds = %90
  %93 = call i32 @cq_template_mul_i64_hl(i32 %20, i64 8)
  %94 = call i32 @cq_template_add_i64(i32 %28, i32 %93)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  %96 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %96)
  call void @cqrt_and_i1(i32 %0, i32 %96, i32 %95)
  %97 = call i32 @cqrt_qram_load_i64_controlled(i32 %95, i32 %13, i32 %94)
  %98 = call i32 @cq_template_and_i64_hl(i32 %19, i64 63)
  %99 = call i32 @cq_template_shl_i64_lh(i64 -1, i32 %98)
  %100 = call i32 @cq_template_xor_i64_hl(i32 %99, i64 -1)
  %101 = call i32 @cq_template_and_i64(i32 %97, i32 %100)
  %102 = call i32 @cq_template_icmp_eq_i64_hl(i32 %101, i64 0)
  %103 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 0)
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %105)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %104)
  %106 = call i32 @cq_template_select_i1(i32 %104, i32 %102, i32 %91)
  %107 = call i32 @cqrt_alloc_i1(i1 false)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %108)
  call void @cqrt_xor_i1(i32 %25, i32 %108)
  call void @cqrt_and_i1(i32 %0, i32 %108, i32 %107)
  %109 = call i32 @cq_template_select_i1(i32 %107, i32 %103, i32 %106)
  %110 = call i32 @cq_template_zext_i1_to_i32(i32 %109)
  call void @cqrt_copy_i32(i32 %110, i32 %out)
  call void @cq_template_zext_i1_to_i32_unc(i32 %110, i32 %109)
  call void @cqrt_free(i32 %110)
  call void @cq_template_select_i1_unc(i32 %109, i32 %107, i32 %103, i32 %106)
  call void @cqrt_free(i32 %109)
  call void @cqrt_and_i1(i32 %0, i32 %108, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_xor_i1(i32 %25, i32 %108)
  call void @cqrt_not_i1(i32 %108)
  call void @cqrt_free(i32 %108)
  call void @cq_template_select_i1_unc(i32 %106, i32 %104, i32 %102, i32 %91)
  call void @cqrt_free(i32 %106)
  call void @cqrt_and_i1(i32 %0, i32 %105, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %105)
  call void @cqrt_free(i32 %105)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %103, i32 %22, i32 0)
  call void @cqrt_free(i32 %103)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %102, i32 %101, i64 0)
  call void @cqrt_free(i32 %102)
  call void @cq_template_and_i64_unc(i32 %101, i32 %97, i32 %100)
  call void @cqrt_free(i32 %101)
  call void @cq_template_xor_i64_hl_unc(i32 %100, i32 %99, i64 -1)
  call void @cqrt_free(i32 %100)
  call void @cq_template_shl_i64_lh_unc(i32 %99, i64 -1, i32 %98)
  call void @cqrt_free(i32 %99)
  call void @cq_template_and_i64_hl_unc(i32 %98, i32 %19, i64 63)
  call void @cqrt_free(i32 %98)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %97, i32 %95, i32 %13, i32 %94)
  call void @cqrt_free(i32 %97)
  call void @cqrt_and_i1(i32 %0, i32 %96, i32 %95)
  call void @cqrt_free(i32 %95)
  call void @cqrt_and_i1(i32 %29, i32 %25, i32 %96)
  call void @cqrt_free(i32 %96)
  call void @cq_template_add_i64_unc(i32 %94, i32 %28, i32 %93)
  call void @cqrt_free(i32 %94)
  call void @cq_template_mul_i64_hl_unc(i32 %93, i32 %20, i64 8)
  call void @cqrt_free(i32 %93)
  br label %161

111:                                              ; preds = %114
  call void @cqrt_and_i1(i32 %31, i32 %35, i32 %40)
  call void @cqrt_free(i32 %40)
  call void @cq_template_select_i1_unc(i32 %39, i32 %38, i32 %36, i32 %33)
  call void @cqrt_free(i32 %39)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_xor_i1(i32 %35, i32 %37)
  call void @cqrt_not_i1(i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_free(i32 %36)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %35, i32 %34, i64 0)
  call void @cqrt_free(i32 %35)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %34, i32 %31, i32 %13, i32 %28)
  call void @cqrt_free(i32 %34)
  call void @cqrt_free(i32 %33)
  call void @cqrt_and_i1(i32 %0, i32 %32, i32 %31)
  call void @cqrt_free(i32 %31)
  call void @cqrt_and_i1(i32 %25, i32 %29, i32 %32)
  call void @cqrt_xor_i1(i32 %25, i32 %32)
  call void @cqrt_free(i32 %32)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %29, i32 %18, i32 64)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %28, i32 %27, i32 %13, i32 %26)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cq_template_add_i64_hl_unc(i32 %26, i32 %17, i64 8)
  call void @cqrt_free(i32 %26)
  call void @cq_template_icmp_ult_i64_unc(i32 %25, i32 %20, i32 %24)
  call void @cqrt_free(i32 %25)
  call void @cq_template_zext_i32_to_i64_unc(i32 %24, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cq_template_abs_i32_unc(i32 %23, i32 %22)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %22, i32 %0, i32 %13, i32 %21)
  call void @cqrt_free(i32 %22)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %17, i64 4)
  call void @cqrt_free(i32 %21)
  call void @cq_template_lshr_i64_hl_unc(i32 %20, i32 %19, i64 6)
  call void @cqrt_free(i32 %20)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_and_i32_hl_unc(i32 %18, i32 %7, i32 255)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i64_hl_unc(i32 %17, i32 %16, i64 ptrtoint (ptr @zs to i64))
  call void @cqrt_free(i32 %17)
  call void @cq_template_mul_i64_hl_unc(i32 %16, i32 %15, i64 16)
  call void @cqrt_free(i32 %16)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)
  call void @cqrt_free(i32 %15)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %8, i32 1)
  call void @cqrt_free(i32 %14)
  %112 = load i32, ptr @__cq_act_f, align 4
  %113 = add i32 %112, -1
  store i32 %113, ptr @__cq_act_f, align 4
  call void @cqrt_free(i32 %out)
  store i32 %6, ptr @__cq_k, align 4
  ret void

114:                                              ; preds = %162, %115
  br label %111

115:                                              ; preds = %162, %143
  %116 = call i32 @cqrt_pop()
  %117 = zext i32 %116 to i64
  %118 = shl i64 %117, 32
  %119 = or i64 0, %118
  %120 = call i32 @cqrt_pop()
  %121 = zext i32 %120 to i64
  %122 = or i64 %119, %121
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
  %141 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %141, i32 %140, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_and_i1(i32 %138, i32 %137, i32 %140)
  call void @cqrt_xor_i1(i32 %138, i32 %140)
  call void @cqrt_free(i32 %140)
  call void @cq_template_select_i1_unc(i32 %136, i32 %135, i32 %134, i32 %133)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %141, i32 %132, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cqrt_and_i1(i32 %137, i32 %138, i32 %132)
  call void @cqrt_free(i32 %132)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %134, i32 %131, i64 0)
  call void @cqrt_free(i32 %134)
  call void @cq_template_and_i64_unc(i32 %131, i32 %130, i32 %129)
  call void @cqrt_free(i32 %131)
  call void @cq_template_xor_i64_hl_unc(i32 %129, i32 %128, i64 -1)
  call void @cqrt_free(i32 %129)
  call void @cq_template_shl_i64_lh_unc(i32 %128, i64 -1, i32 %127)
  call void @cqrt_free(i32 %128)
  call void @cq_template_and_i64_hl_unc(i32 %127, i32 %19, i64 63)
  call void @cqrt_free(i32 %127)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %130, i32 %126, i32 %13, i32 %125)
  call void @cqrt_free(i32 %130)
  call void @cqrt_and_i1(i32 %141, i32 %124, i32 %126)
  call void @cqrt_free(i32 %126)
  call void @cqrt_and_i1(i32 %137, i32 %138, i32 %124)
  call void @cqrt_free(i32 %124)
  call void @cq_template_add_i64_unc(i32 %125, i32 %28, i32 %123)
  call void @cqrt_free(i32 %125)
  call void @cq_template_mul_i64_hl_unc(i32 %123, i32 %20, i64 8)
  call void @cqrt_free(i32 %123)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %137, i32 %20, i64 %122)
  call void @cqrt_free(i32 %137)
  %142 = call i32 @cqrt_pop()
  switch i32 %142, label %143 [
    i32 1, label %114
  ]

143:                                              ; preds = %115
  %144 = call i32 @cqrt_pop()
  %145 = zext i32 %144 to i64
  %146 = shl i64 %145, 32
  %147 = or i64 0, %146
  %148 = call i32 @cqrt_pop()
  %149 = zext i32 %148 to i64
  %150 = or i64 %147, %149
  %151 = call i32 @cqrt_pop()
  %152 = call i32 @cqrt_pop()
  %153 = call i32 @cqrt_pop()
  %154 = call i32 @cqrt_pop()
  %155 = call i32 @cqrt_pop()
  %156 = call i32 @cqrt_pop()
  %157 = call i32 @cqrt_pop()
  %158 = call i32 @cqrt_pop()
  %159 = call i32 @cqrt_pop()
  %160 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %160, i32 %159, i32 %158)
  call void @cqrt_free(i32 %158)
  call void @cq_template_select_i1_unc(i32 %157, i32 %156, i32 %155, i32 %154)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %160, i32 %153, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cqrt_xor_i1(i32 %159, i32 %153)
  call void @cqrt_not_i1(i32 %153)
  call void @cqrt_free(i32 %153)
  call void @cqrt_free(i32 %155)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %159, i32 %152, i64 0)
  call void @cqrt_free(i32 %159)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %152, i32 %160, i32 %13, i32 %151)
  call void @cqrt_free(i32 %152)
  call void @cq_template_add_i64_hl_unc(i32 %151, i32 %28, i64 %150)
  call void @cqrt_free(i32 %151)
  br label %115

161:                                              ; preds = %92
  call void @cqrt_copy_i1(i32 %74, i32 %91)
  call void @cqrt_free(i32 %91)
  br label %162

162:                                              ; preds = %161
  switch i32 %73, label %114 [
    i32 1, label %115
  ]

163:                                              ; preds = %5
  %164 = load i32, ptr @__cq_act_f, align 4
  %165 = add i32 %164, -1
  store i32 %165, ptr @__cq_act_f, align 4
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
