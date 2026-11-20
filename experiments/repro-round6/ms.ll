; ModuleID = '<stdin>'
source_filename = "repro-round3/mathieu_seed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@calls = local_unnamed_addr global i32 0, align 4
@__cq_act_mc = internal global i32 0, align 4
@__cq_act_f = internal global i32 0, align 4
@__cq_k = internal global i32 -1, align 4
@.cq.sig = private unnamed_addr constant [28 x i8] c"i32 (i32, i32, double, ptr)\00", align 1
@.cq.sig.1 = private unnamed_addr constant [31 x i8] c"i32 (double, double, i32, i32)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define i32 @mc(i32 noundef %0, i32 noundef %1, double noundef %2, ptr noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 64, i64 16)
  %7 = call ptr @__cq_alloc(i64 8, i64 8)
  %8 = fcmp ugt double %2, 0.000000e+00
  br i1 %8, label %9, label %12

9:                                                ; preds = %4
  %10 = add i32 %0, -3
  %11 = icmp ult i32 %10, -2
  br i1 %11, label %12, label %14

12:                                               ; preds = %100, %14, %9, %4
  %13 = phi i32 [ 1, %4 ], [ 2, %9 ], [ 0, %100 ], [ %15, %14 ]
  ret i32 %13

14:                                               ; preds = %9
  %15 = call fastcc i32 @char_a(i32 noundef %1, double noundef %2, ptr noundef %7)
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %12

17:                                               ; preds = %14
  %18 = ptrtoint ptr %7 to i64
  %19 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %18)
  call fastcc void @__cq_q_fill_010(double %2, i32 %19, ptr %6)
  call void @cqrt_qram_load_f64_hl_unc(i32 %19, i32 %5, i64 %18)
  %20 = and i32 %1, 1
  %21 = icmp eq i32 %20, 0
  %22 = icmp eq i32 %0, 1
  br i1 %21, label %23, label %25

23:                                               ; preds = %17
  %24 = sitofp i32 %1 to double
  br label %28

25:                                               ; preds = %17
  %26 = add nsw i32 %1, -1
  %27 = sitofp i32 %26 to double
  br label %102

28:                                               ; preds = %23
  %29 = call i32 @cqrt_alloc_i1(i1 true)
  %30 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %31 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %32 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %34

33:                                               ; preds = %60
  br label %85

34:                                               ; preds = %60, %28
  %from7 = phi i32 [ 0, %60 ], [ 1, %28 ]
  %35 = phi i64 [ 0, %28 ], [ %71, %60 ]
  %36 = phi i32 [ %30, %28 ], [ %73, %60 ]
  %37 = phi i32 [ %31, %28 ], [ %74, %60 ]
  %trip = phi i32 [ %29, %28 ], [ %46, %60 ]
  %xcap = phi i32 [ %32, %28 ], [ %75, %60 ]
  call void @cqrt_push(i32 %from7)
  %38 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %35
  %39 = ptrtoint ptr %38 to i64
  %40 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %trip, i32 %5, i64 %39)
  %41 = call i32 @cq_template_fabs_f64(i32 %40)
  %42 = call i32 @cq_template_fcmp_ogt_f64(i32 %36, i32 %41)
  %43 = call i32 @cq_template_select_f64(i32 %42, i32 %36, i32 %41)
  %44 = call i32 @cq_template_fdiv_f64(i32 %41, i32 %43)
  %45 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %44, double 0x3D06849B86A12B9B)
  %46 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %46)
  %47 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %45, i32 %47)
  call void @cqrt_and_i1(i32 %trip, i32 %45, i32 %46)
  %48 = trunc nuw nsw i64 %35 to i32
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %40)
  %49 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %49)
  %50 = lshr i64 %39, 32
  %51 = trunc i64 %50 to i32
  call void @cqrt_push(i32 %51)
  br i1 %22, label %52, label %56

52:                                               ; preds = %34
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_xor_i1(i32 %45, i32 %53)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %53, i32 %54)
  %55 = call fastcc double @__cq_q_jn__00_ctl(i32 %54, i32 %48, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %53, i32 %54)
  call void @cqrt_free(i32 %54)
  call void @cqrt_xor_i1(i32 %45, i32 %53)
  call void @cqrt_not_i1(i32 %53)
  call void @cqrt_free(i32 %53)
  br label %60

56:                                               ; preds = %34
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_xor_i1(i32 %45, i32 %57)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %57, i32 %58)
  %59 = call fastcc double @__cq_q_yn__00_ctl(i32 %58, i32 %48, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %57, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_xor_i1(i32 %45, i32 %57)
  call void @cqrt_not_i1(i32 %57)
  call void @cqrt_free(i32 %57)
  br label %60

60:                                               ; preds = %52, %56
  %from6 = phi i32 [ 0, %52 ], [ 1, %56 ]
  %61 = phi double [ %55, %52 ], [ %59, %56 ]
  call void @cqrt_push(i32 %from6)
  %62 = trunc nuw nsw i64 %35 to i32
  %63 = uitofp nneg i32 %62 to double
  %64 = tail call double @llvm.fmuladd.f64(double %24, double 5.000000e-01, double %63)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_xor_i1(i32 %45, i32 %65)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %65, i32 %66)
  %67 = call fastcc double @__cq_q_sgn_0_ctl(i32 %66, double %64)
  call void @cqrt_and_i1(i32 %trip, i32 %65, i32 %66)
  call void @cqrt_free(i32 %66)
  call void @cqrt_xor_i1(i32 %45, i32 %65)
  call void @cqrt_not_i1(i32 %65)
  call void @cqrt_free(i32 %65)
  %68 = call i32 @cq_template_fmul_f64_hl(i32 %40, double %67)
  %69 = call i32 @cq_template_fmul_f64_hl(i32 %68, double %61)
  %70 = call i32 @cq_template_fadd_f64(i32 %69, i32 %37)
  %71 = add nuw nsw i64 %35, 1
  %72 = icmp eq i64 %71, 8
  %73 = call i32 @cq_template_select_f64(i32 %46, i32 %43, i32 %36)
  %74 = call i32 @cq_template_select_f64(i32 %46, i32 %70, i32 %37)
  %75 = call i32 @cq_template_select_f64(i32 %47, i32 %37, i32 %xcap)
  %76 = call i32 @cq_template_select_f64(i32 %46, i32 %70, i32 %75)
  call void @cqrt_push(i32 %76)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %75)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %68)
  %77 = bitcast double %61 to i64
  %78 = trunc i64 %77 to i32
  call void @cqrt_push(i32 %78)
  %79 = lshr i64 %77, 32
  %80 = trunc i64 %79 to i32
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %40)
  %81 = bitcast double %67 to i64
  %82 = trunc i64 %81 to i32
  call void @cqrt_push(i32 %82)
  %83 = lshr i64 %81, 32
  %84 = trunc i64 %83 to i32
  call void @cqrt_push(i32 %84)
  br i1 %72, label %33, label %34

85:                                               ; preds = %33
  br label %86

86:                                               ; preds = %85, %161
  %87 = phi i32 [ %29, %85 ], [ poison, %161 ]
  %88 = phi i32 [ %30, %85 ], [ poison, %161 ]
  %89 = phi i32 [ %31, %85 ], [ poison, %161 ]
  %90 = phi i32 [ %32, %85 ], [ poison, %161 ]
  %ran11 = phi i1 [ true, %85 ], [ false, %161 ]
  %91 = phi i32 [ poison, %85 ], [ %103, %161 ]
  %92 = phi i32 [ poison, %85 ], [ %104, %161 ]
  %93 = phi i32 [ poison, %85 ], [ %105, %161 ]
  %94 = phi i32 [ poison, %85 ], [ %106, %161 ]
  %ran = phi i1 [ false, %85 ], [ true, %161 ]
  %95 = phi i32 [ %76, %85 ], [ %152, %161 ]
  %96 = ptrtoint ptr %6 to i64
  %97 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %96)
  %98 = call i32 @cq_template_fdiv_f64(i32 %95, i32 %97)
  call void @cqrt_qram_load_f64_hl_unc(i32 %97, i32 %5, i64 %96)
  call void @cqrt_free(i32 %97)
  br i1 %ran, label %184, label %216

99:                                               ; preds = %216
  br i1 %ran11, label %239, label %271

100:                                              ; preds = %271
  %101 = ptrtoint ptr %3 to i64
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %101, i32 %98)
  br label %12

102:                                              ; preds = %25
  %103 = call i32 @cqrt_alloc_i1(i1 true)
  %104 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %105 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %106 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %108

107:                                              ; preds = %135
  br label %161

108:                                              ; preds = %135, %102
  %from3 = phi i32 [ 0, %135 ], [ 1, %102 ]
  %109 = phi i64 [ 0, %102 ], [ %147, %135 ]
  %110 = phi i32 [ %104, %102 ], [ %149, %135 ]
  %111 = phi i32 [ %105, %102 ], [ %150, %135 ]
  %trip1 = phi i32 [ %103, %102 ], [ %120, %135 ]
  %xcap2 = phi i32 [ %106, %102 ], [ %151, %135 ]
  call void @cqrt_push(i32 %from3)
  %112 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %109
  %113 = ptrtoint ptr %112 to i64
  %114 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %trip1, i32 %5, i64 %113)
  %115 = call i32 @cq_template_fabs_f64(i32 %114)
  %116 = call i32 @cq_template_fcmp_ogt_f64(i32 %110, i32 %115)
  %117 = call i32 @cq_template_select_f64(i32 %116, i32 %110, i32 %115)
  %118 = call i32 @cq_template_fdiv_f64(i32 %115, i32 %117)
  %119 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %118, double 0x3D06849B86A12B9B)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %120)
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %119, i32 %121)
  call void @cqrt_and_i1(i32 %trip1, i32 %119, i32 %120)
  %122 = trunc i64 %109 to i32
  %123 = add i32 %122, 1
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %119)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %114)
  %124 = trunc i64 %113 to i32
  call void @cqrt_push(i32 %124)
  %125 = lshr i64 %113, 32
  %126 = trunc i64 %125 to i32
  call void @cqrt_push(i32 %126)
  br i1 %22, label %127, label %131

127:                                              ; preds = %108
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %128)
  call void @cqrt_xor_i1(i32 %119, i32 %128)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %128, i32 %129)
  %130 = call fastcc double @__cq_q_jn__00_ctl(i32 %129, i32 %123, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %128, i32 %129)
  call void @cqrt_free(i32 %129)
  call void @cqrt_xor_i1(i32 %119, i32 %128)
  call void @cqrt_not_i1(i32 %128)
  call void @cqrt_free(i32 %128)
  br label %135

131:                                              ; preds = %108
  %132 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %132)
  call void @cqrt_xor_i1(i32 %119, i32 %132)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %132, i32 %133)
  %134 = call fastcc double @__cq_q_yn__00_ctl(i32 %133, i32 %123, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %132, i32 %133)
  call void @cqrt_free(i32 %133)
  call void @cqrt_xor_i1(i32 %119, i32 %132)
  call void @cqrt_not_i1(i32 %132)
  call void @cqrt_free(i32 %132)
  br label %135

135:                                              ; preds = %127, %131
  %from = phi i32 [ 0, %127 ], [ 1, %131 ]
  %136 = phi double [ %130, %127 ], [ %134, %131 ]
  call void @cqrt_push(i32 %from)
  %137 = trunc nuw nsw i64 %109 to i32
  %138 = uitofp nneg i32 %137 to double
  %139 = tail call double @llvm.fmuladd.f64(double %27, double 5.000000e-01, double %138)
  %140 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %140)
  call void @cqrt_xor_i1(i32 %119, i32 %140)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %140, i32 %141)
  %142 = call fastcc double @__cq_q_sgn_0_ctl(i32 %141, double %139)
  call void @cqrt_and_i1(i32 %trip1, i32 %140, i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cqrt_xor_i1(i32 %119, i32 %140)
  call void @cqrt_not_i1(i32 %140)
  call void @cqrt_free(i32 %140)
  %143 = call i32 @cq_template_fmul_f64_hl(i32 %114, double %142)
  %144 = fadd double %136, 1.000000e+00
  %145 = call i32 @cq_template_fmul_f64_hl(i32 %143, double %144)
  %146 = call i32 @cq_template_fadd_f64(i32 %145, i32 %111)
  %147 = add nuw nsw i64 %109, 1
  %148 = icmp eq i64 %147, 8
  %149 = call i32 @cq_template_select_f64(i32 %120, i32 %117, i32 %110)
  %150 = call i32 @cq_template_select_f64(i32 %120, i32 %146, i32 %111)
  %151 = call i32 @cq_template_select_f64(i32 %121, i32 %111, i32 %xcap2)
  %152 = call i32 @cq_template_select_f64(i32 %120, i32 %146, i32 %151)
  call void @cqrt_push(i32 %152)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %146)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %111)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %110)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %143)
  %153 = bitcast double %144 to i64
  %154 = trunc i64 %153 to i32
  call void @cqrt_push(i32 %154)
  %155 = lshr i64 %153, 32
  %156 = trunc i64 %155 to i32
  call void @cqrt_push(i32 %156)
  call void @cqrt_push(i32 %114)
  %157 = bitcast double %142 to i64
  %158 = trunc i64 %157 to i32
  call void @cqrt_push(i32 %158)
  %159 = lshr i64 %157, 32
  %160 = trunc i64 %159 to i32
  call void @cqrt_push(i32 %160)
  br i1 %148, label %107, label %108

161:                                              ; preds = %107
  br label %86

162:                                              ; preds = %163
  call void @cqrt_free(i32 %94)
  call void @cqrt_free(i32 %93)
  call void @cqrt_free(i32 %92)
  call void @cqrt_free(i32 %91)
  br label %216

163:                                              ; preds = %182, %183
  %164 = call i32 @cqrt_pop()
  %165 = zext i32 %164 to i64
  %166 = shl i64 %165, 32
  %167 = or i64 0, %166
  %168 = call i32 @cqrt_pop()
  %169 = zext i32 %168 to i64
  %170 = or i64 %167, %169
  %171 = call i32 @cqrt_pop()
  %172 = call i32 @cqrt_pop()
  %173 = call i32 @cqrt_pop()
  %174 = call i32 @cqrt_pop()
  %175 = call i32 @cqrt_pop()
  %176 = call i32 @cqrt_pop()
  %177 = call i32 @cqrt_pop()
  %178 = call i32 @cqrt_pop()
  %179 = call i32 @cqrt_pop()
  %180 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %180, i32 %179, i32 %178)
  call void @cqrt_free(i32 %178)
  call void @cqrt_and_i1(i32 %180, i32 %179, i32 %177)
  call void @cqrt_xor_i1(i32 %180, i32 %177)
  call void @cqrt_free(i32 %177)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %179, i32 %176, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %179)
  call void @cq_template_fdiv_f64_unc(i32 %176, i32 %175, i32 %174)
  call void @cqrt_free(i32 %176)
  call void @cq_template_select_f64_unc(i32 %174, i32 %173, i32 %172, i32 %175)
  call void @cqrt_free(i32 %174)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %173, i32 %172, i32 %175)
  call void @cqrt_free(i32 %173)
  call void @cq_template_fabs_f64_unc(i32 %175, i32 %171)
  call void @cqrt_free(i32 %175)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %171, i32 %180, i32 %5, i64 %170)
  %181 = call i32 @cqrt_pop()
  switch i32 %181, label %184 [
    i32 1, label %162
  ]

182:                                              ; preds = %184
  br label %163

183:                                              ; preds = %184
  br label %163

184:                                              ; preds = %86, %163
  %185 = call i32 @cqrt_pop()
  %186 = zext i32 %185 to i64
  %187 = shl i64 %186, 32
  %188 = or i64 0, %187
  %189 = call i32 @cqrt_pop()
  %190 = zext i32 %189 to i64
  %191 = or i64 %188, %190
  %192 = bitcast i64 %191 to double
  %193 = call i32 @cqrt_pop()
  %194 = call i32 @cqrt_pop()
  %195 = zext i32 %194 to i64
  %196 = shl i64 %195, 32
  %197 = or i64 0, %196
  %198 = call i32 @cqrt_pop()
  %199 = zext i32 %198 to i64
  %200 = or i64 %197, %199
  %201 = bitcast i64 %200 to double
  %202 = call i32 @cqrt_pop()
  %203 = call i32 @cqrt_pop()
  %204 = call i32 @cqrt_pop()
  %205 = call i32 @cqrt_pop()
  %206 = call i32 @cqrt_pop()
  %207 = call i32 @cqrt_pop()
  %208 = call i32 @cqrt_pop()
  %209 = call i32 @cqrt_pop()
  %210 = call i32 @cqrt_pop()
  %211 = call i32 @cqrt_pop()
  %212 = call i32 @cqrt_pop()
  %213 = call i32 @cqrt_pop()
  %214 = call i32 @cqrt_pop()
  call void @cq_template_select_f64_unc(i32 %214, i32 %213, i32 %212, i32 %211)
  call void @cqrt_free(i32 %214)
  call void @cq_template_select_f64_unc(i32 %211, i32 %210, i32 %209, i32 %208)
  call void @cqrt_free(i32 %211)
  call void @cq_template_select_f64_unc(i32 %207, i32 %213, i32 %212, i32 %209)
  call void @cqrt_free(i32 %207)
  call void @cq_template_select_f64_unc(i32 %206, i32 %213, i32 %205, i32 %204)
  call void @cqrt_free(i32 %206)
  call void @cq_template_fadd_f64_unc(i32 %212, i32 %203, i32 %209)
  call void @cqrt_free(i32 %212)
  call void @cq_template_fmul_f64_hl_unc(i32 %203, i32 %202, double %201)
  call void @cqrt_free(i32 %203)
  call void @cq_template_fmul_f64_hl_unc(i32 %202, i32 %193, double %192)
  call void @cqrt_free(i32 %202)
  %215 = call i32 @cqrt_pop()
  switch i32 %215, label %183 [
    i32 1, label %182
  ]

216:                                              ; preds = %162, %86
  br label %99

217:                                              ; preds = %218
  call void @cqrt_free(i32 %90)
  call void @cqrt_free(i32 %89)
  call void @cqrt_free(i32 %88)
  call void @cqrt_free(i32 %87)
  br label %271

218:                                              ; preds = %237, %238
  %219 = call i32 @cqrt_pop()
  %220 = zext i32 %219 to i64
  %221 = shl i64 %220, 32
  %222 = or i64 0, %221
  %223 = call i32 @cqrt_pop()
  %224 = zext i32 %223 to i64
  %225 = or i64 %222, %224
  %226 = call i32 @cqrt_pop()
  %227 = call i32 @cqrt_pop()
  %228 = call i32 @cqrt_pop()
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  %233 = call i32 @cqrt_pop()
  %234 = call i32 @cqrt_pop()
  %235 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %235, i32 %234, i32 %233)
  call void @cqrt_free(i32 %233)
  call void @cqrt_and_i1(i32 %235, i32 %234, i32 %232)
  call void @cqrt_xor_i1(i32 %235, i32 %232)
  call void @cqrt_free(i32 %232)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %234, i32 %231, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %234)
  call void @cq_template_fdiv_f64_unc(i32 %231, i32 %230, i32 %229)
  call void @cqrt_free(i32 %231)
  call void @cq_template_select_f64_unc(i32 %229, i32 %228, i32 %227, i32 %230)
  call void @cqrt_free(i32 %229)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %228, i32 %227, i32 %230)
  call void @cqrt_free(i32 %228)
  call void @cq_template_fabs_f64_unc(i32 %230, i32 %226)
  call void @cqrt_free(i32 %230)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %226, i32 %235, i32 %5, i64 %225)
  %236 = call i32 @cqrt_pop()
  switch i32 %236, label %239 [
    i32 1, label %217
  ]

237:                                              ; preds = %239
  br label %218

238:                                              ; preds = %239
  br label %218

239:                                              ; preds = %99, %218
  %240 = call i32 @cqrt_pop()
  %241 = zext i32 %240 to i64
  %242 = shl i64 %241, 32
  %243 = or i64 0, %242
  %244 = call i32 @cqrt_pop()
  %245 = zext i32 %244 to i64
  %246 = or i64 %243, %245
  %247 = bitcast i64 %246 to double
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = zext i32 %249 to i64
  %251 = shl i64 %250, 32
  %252 = or i64 0, %251
  %253 = call i32 @cqrt_pop()
  %254 = zext i32 %253 to i64
  %255 = or i64 %252, %254
  %256 = bitcast i64 %255 to double
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
  call void @cq_template_select_f64_unc(i32 %269, i32 %268, i32 %267, i32 %266)
  call void @cqrt_free(i32 %269)
  call void @cq_template_select_f64_unc(i32 %266, i32 %265, i32 %264, i32 %263)
  call void @cqrt_free(i32 %266)
  call void @cq_template_select_f64_unc(i32 %262, i32 %268, i32 %267, i32 %264)
  call void @cqrt_free(i32 %262)
  call void @cq_template_select_f64_unc(i32 %261, i32 %268, i32 %260, i32 %259)
  call void @cqrt_free(i32 %261)
  call void @cq_template_fadd_f64_unc(i32 %267, i32 %258, i32 %264)
  call void @cqrt_free(i32 %267)
  call void @cq_template_fmul_f64_hl_unc(i32 %258, i32 %257, double %256)
  call void @cqrt_free(i32 %258)
  call void @cq_template_fmul_f64_hl_unc(i32 %257, i32 %248, double %247)
  call void @cqrt_free(i32 %257)
  %270 = call i32 @cqrt_pop()
  switch i32 %270, label %238 [
    i32 1, label %237
  ]

271:                                              ; preds = %217, %99
  br label %100
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @char_a(i32 noundef %0, double noundef %1, ptr noundef %2) unnamed_addr #2 {
  %4 = call i32 @__cq_mem()
  %5 = sitofp i32 %0 to double
  %6 = fmul double %5, %1
  %7 = ptrtoint ptr %2 to i64
  %8 = call i32 @cqrt_alloc_f64(double %6)
  call void @cqrt_qram_store_f64_hl(i32 %4, i64 %7, i32 %8)
  %9 = icmp sgt i32 %0, 6
  %10 = zext i1 %9 to i32
  ret i32 %10
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f(double noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 8, i64 8)
  %7 = ptrtoint ptr %6 to i64
  %8 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %7, i32 %8)
  %9 = call i32 @cqrt_alloc_f64(double %0)
  call void @cqrt_ry_f64(i32 %9, double %1)
  %10 = call i32 @__cq_q_mc_0010(i32 %3, i32 %2, i32 %9, ptr %6)
  %11 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %7)
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 6.400000e+01)
  %13 = call i32 @cq_template_fptosi_f64_to_i32(i32 %12)
  call void @cq_template_fmul_f64_hl_unc(i32 %12, i32 %11, double 6.400000e+01)
  call void @cqrt_free(i32 %12)
  call void @cqrt_qram_load_f64_hl_unc(i32 %11, i32 %5, i64 %7)
  call void @cqrt_free(i32 %11)
  ret i32 %13
}

declare i32 @cqrt_alloc_f64(double)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_f64_hl(i32, i64, i32)

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_qram_load_f64_hl(i32, i64)

define internal fastcc void @__cq_q_fill_010(double %0, i32 %1, ptr %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cq_template_fadd_f64_hl(i32 %1, double %0)
  br label %6

6:                                                ; preds = %3
  br label %8

7:                                                ; preds = %18
  br label %23

8:                                                ; preds = %18, %6
  %from = phi i32 [ 0, %18 ], [ 1, %6 ]
  %9 = phi i64 [ 0, %6 ], [ %11, %18 ]
  %10 = icmp ult i64 %9, 3
  %11 = add nuw nsw i64 %9, 1
  %12 = trunc nuw nsw i64 %11 to i32
  %13 = uitofp nneg i32 %12 to double
  %14 = call i32 @cq_template_fdiv_f64_hl(i32 %5, double %13)
  %15 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %16 = select i1 %10, i32 %14, i32 %15
  %cq.ch = select i1 %10, i1 false, i1 true
  %cq.not = xor i1 %cq.ch, true
  br i1 %cq.not, label %.cq.arm, label %17

.cq.arm:                                          ; preds = %8
  call void @cqrt_free(i32 %15)
  br label %17

17:                                               ; preds = %8, %.cq.arm
  %cq.not1 = xor i1 %10, true
  br i1 %cq.not1, label %.cq.arm2, label %18

.cq.arm2:                                         ; preds = %17
  call void @cq_template_fdiv_f64_hl_unc(i32 %14, i32 %5, double %13)
  call void @cqrt_free(i32 %14)
  br label %18

18:                                               ; preds = %.cq.arm2, %17
  call void @cqrt_push(i32 %from)
  %19 = getelementptr inbounds double, ptr %2, i64 %9
  %20 = ptrtoint ptr %19 to i64
  call void @cqrt_qram_store_f64_hl(i32 %4, i64 %20, i32 %16)
  %21 = icmp eq i64 %11, 8
  br i1 %21, label %7, label %8

22:                                               ; preds = %23
  call void @cq_template_fadd_f64_hl_unc(i32 %5, i32 %1, double %0)
  call void @cqrt_free(i32 %5)
  ret void

23:                                               ; preds = %7, %23
  %24 = call i32 @cqrt_pop()
  switch i32 %24, label %23 [
    i32 1, label %22
  ]
}

declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_qram_load_f64_hl_controlled(i32, i32, i64)

declare i32 @cq_template_fabs_f64(i32)

declare i32 @cq_template_fcmp_ogt_f64(i32, i32)

declare i32 @cq_template_select_f64(i32, i32, i32)

declare i32 @cq_template_fdiv_f64(i32, i32)

declare i32 @cq_template_fcmp_olt_f64_hl(i32, double)

declare void @cqrt_xor_i1(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

define internal fastcc double @__cq_q_yn__00_ctl(i32 %0, i32 %1, double %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @calls to i64), i32 %5)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @calls to i64), i32 %7)
  call void @cqrt_free(i32 %7)
  %10 = sitofp i32 %1 to double
  %11 = fsub double %2, %10
  ret double %11
}

declare void @cqrt_not_i1(i32)

define internal fastcc double @__cq_q_jn__00_ctl(i32 %0, i32 %1, double %2) unnamed_addr {
  %4 = call i32 @__cq_mem()
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @calls to i64), i32 %5)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @calls to i64), i32 %7)
  call void @cqrt_free(i32 %7)
  %10 = sitofp i32 %1 to double
  %11 = tail call double @llvm.fmuladd.f64(double %2, double %10, double 1.000000e+00)
  ret double %11
}

define internal fastcc double @__cq_q_sgn_0_ctl(i32 %0, double %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @calls to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @calls to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = fptosi double %1 to i64
  %10 = and i64 %9, 1
  %11 = icmp eq i64 %10, 0
  %12 = select i1 %11, double 1.000000e+00, double -1.000000e+00
  ret double %12
}

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare i32 @cq_template_fadd_f64(i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_push(i32)

declare i32 @cqrt_pop()

declare void @cq_template_select_f64_unc(i32, i32, i32, i32)

declare void @cq_template_fadd_f64_unc(i32, i32, i32)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare void @cq_template_fcmp_olt_f64_hl_unc(i32, i32, double)

declare void @cq_template_fdiv_f64_unc(i32, i32, i32)

declare void @cq_template_fcmp_ogt_f64_unc(i32, i32, i32)

declare void @cq_template_fabs_f64_unc(i32, i32)

declare void @cqrt_qram_load_f64_hl_controlled_unc(i32, i32, i32, i64)

define internal i32 @__cq_q_mc_1111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  %7 = call i32 @__cq_mem()
  %8 = call ptr @__cq_alloc(i64 64, i64 16)
  %9 = call ptr @__cq_alloc(i64 8, i64 8)
  %10 = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %2, double 0.000000e+00)
  %11 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -3)
  %12 = call i32 @cq_template_icmp_ult_i32_hl(i32 %11, i32 -2)
  %13 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %13)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %13)
  %14 = call fastcc i32 @__cq_q_char_a_110_ctl(i32 %13, i32 %1, i32 %2, ptr %9)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %13)
  call void @cqrt_xor_i1(i32 %10, i32 %13)
  call void @cqrt_free(i32 %13)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)
  %16 = ptrtoint ptr %9 to i64
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %18)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %18)
  call void @cqrt_and_i1(i32 %15, i32 %18, i32 %17)
  %19 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %17, i32 %7, i64 %16)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  %21 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %21)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %21)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %20)
  call fastcc void @__cq_q_fill_110_ctl(i32 %20, i32 %2, i32 %19, ptr %8)
  call void @cqrt_and_i1(i32 %15, i32 %21, i32 %20)
  call void @cqrt_free(i32 %20)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %21)
  call void @cqrt_xor_i1(i32 %10, i32 %21)
  call void @cqrt_free(i32 %21)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %19, i32 %17, i32 %7, i64 %16)
  call void @cqrt_and_i1(i32 %15, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %18)
  call void @cqrt_xor_i1(i32 %10, i32 %18)
  call void @cqrt_free(i32 %18)
  %22 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 0)
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 1)
  %25 = call i32 @cq_template_sitofp_i32_to_f64(i32 %1)
  br label %26

26:                                               ; preds = %5
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %29)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %29)
  call void @cqrt_and_i1(i32 %15, i32 %29, i32 %28)
  call void @cqrt_and_i1(i32 %23, i32 %28, i32 %27)
  %30 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %31 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %32 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %34

33:                                               ; preds = %34
  br label %102

34:                                               ; preds = %34, %26
  %from3 = phi i32 [ 0, %34 ], [ 1, %26 ]
  %35 = phi i64 [ 0, %26 ], [ %85, %34 ]
  %36 = phi i32 [ %30, %26 ], [ %87, %34 ]
  %37 = phi i32 [ %31, %26 ], [ %88, %34 ]
  %trip = phi i32 [ %27, %26 ], [ %50, %34 ]
  %xcap = phi i32 [ %32, %26 ], [ %89, %34 ]
  call void @cqrt_push(i32 %from3)
  %38 = getelementptr inbounds [8 x double], ptr %8, i64 0, i64 %35
  %39 = ptrtoint ptr %38 to i64
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  %42 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %42)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %42)
  call void @cqrt_and_i1(i32 %15, i32 %42, i32 %41)
  call void @cqrt_and_i1(i32 %23, i32 %41, i32 %40)
  %43 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %40, i32 %43)
  %44 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %43, i32 %7, i64 %39)
  %45 = call i32 @cq_template_fabs_f64(i32 %44)
  %46 = call i32 @cq_template_fcmp_ogt_f64(i32 %36, i32 %45)
  %47 = call i32 @cq_template_select_f64(i32 %46, i32 %36, i32 %45)
  %48 = call i32 @cq_template_fdiv_f64(i32 %45, i32 %47)
  %49 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %48, double 0x3D06849B86A12B9B)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %50)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %54)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %54)
  call void @cqrt_and_i1(i32 %15, i32 %54, i32 %53)
  call void @cqrt_and_i1(i32 %23, i32 %53, i32 %52)
  call void @cqrt_and_i1(i32 %49, i32 %52, i32 %51)
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %51, i32 %55)
  call void @cqrt_and_i1(i32 %trip, i32 %51, i32 %50)
  %56 = trunc nuw nsw i64 %35 to i32
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %61)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %61)
  call void @cqrt_and_i1(i32 %15, i32 %61, i32 %60)
  call void @cqrt_and_i1(i32 %23, i32 %60, i32 %59)
  call void @cqrt_xor_i1(i32 %59, i32 %58)
  call void @cqrt_and_i1(i32 %59, i32 %24, i32 %58)
  call void @cqrt_xor_i1(i32 %58, i32 %57)
  call void @cqrt_and_i1(i32 %58, i32 %49, i32 %57)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %57, i32 %62)
  %63 = call fastcc double @__cq_q_yn__00_ctl(i32 %62, i32 %56, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %57, i32 %62)
  call void @cqrt_free(i32 %62)
  call void @cqrt_and_i1(i32 %58, i32 %49, i32 %57)
  call void @cqrt_xor_i1(i32 %58, i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %59, i32 %24, i32 %58)
  call void @cqrt_xor_i1(i32 %59, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_and_i1(i32 %23, i32 %60, i32 %59)
  call void @cqrt_free(i32 %59)
  call void @cqrt_and_i1(i32 %15, i32 %61, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %61)
  call void @cqrt_xor_i1(i32 %10, i32 %61)
  call void @cqrt_free(i32 %61)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %68)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %68)
  call void @cqrt_and_i1(i32 %15, i32 %68, i32 %67)
  call void @cqrt_and_i1(i32 %23, i32 %67, i32 %66)
  call void @cqrt_and_i1(i32 %24, i32 %66, i32 %65)
  call void @cqrt_xor_i1(i32 %65, i32 %64)
  call void @cqrt_and_i1(i32 %65, i32 %49, i32 %64)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %64, i32 %69)
  %70 = call fastcc double @__cq_q_jn__00_ctl(i32 %69, i32 %56, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %64, i32 %69)
  call void @cqrt_free(i32 %69)
  call void @cqrt_and_i1(i32 %65, i32 %49, i32 %64)
  call void @cqrt_xor_i1(i32 %65, i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cqrt_and_i1(i32 %24, i32 %66, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %23, i32 %67, i32 %66)
  call void @cqrt_free(i32 %66)
  call void @cqrt_and_i1(i32 %15, i32 %68, i32 %67)
  call void @cqrt_free(i32 %67)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %68)
  call void @cqrt_xor_i1(i32 %10, i32 %68)
  call void @cqrt_free(i32 %68)
  %71 = call i32 @cq_template_select_f64_ll(i32 %24, double %70, double %63)
  %72 = trunc nuw nsw i64 %35 to i32
  %73 = uitofp nneg i32 %72 to double
  %74 = call i32 @cq_template_fmul_f64_hl(i32 %25, double 5.000000e-01)
  %75 = call i32 @cq_template_fadd_f64_hl(i32 %74, double %73)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %79)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %79)
  call void @cqrt_and_i1(i32 %15, i32 %79, i32 %78)
  call void @cqrt_and_i1(i32 %23, i32 %78, i32 %77)
  call void @cqrt_xor_i1(i32 %77, i32 %76)
  call void @cqrt_and_i1(i32 %77, i32 %49, i32 %76)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %76, i32 %80)
  %81 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %80, i32 %75)
  call void @cqrt_and_i1(i32 %trip, i32 %76, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_and_i1(i32 %77, i32 %49, i32 %76)
  call void @cqrt_xor_i1(i32 %77, i32 %76)
  call void @cqrt_free(i32 %76)
  call void @cqrt_and_i1(i32 %23, i32 %78, i32 %77)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %15, i32 %79, i32 %78)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %79)
  call void @cqrt_xor_i1(i32 %10, i32 %79)
  call void @cqrt_free(i32 %79)
  call void @cq_template_fadd_f64_hl_unc(i32 %75, i32 %74, double %73)
  call void @cqrt_free(i32 %75)
  call void @cq_template_fmul_f64_hl_unc(i32 %74, i32 %25, double 5.000000e-01)
  call void @cqrt_free(i32 %74)
  %82 = call i32 @cq_template_fmul_f64(i32 %44, i32 %81)
  %83 = call i32 @cq_template_fmul_f64(i32 %82, i32 %71)
  %84 = call i32 @cq_template_fadd_f64(i32 %83, i32 %37)
  %85 = add nuw nsw i64 %35, 1
  %86 = icmp eq i64 %85, 8
  %87 = call i32 @cq_template_select_f64(i32 %50, i32 %47, i32 %36)
  %88 = call i32 @cq_template_select_f64(i32 %50, i32 %84, i32 %37)
  %89 = call i32 @cq_template_select_f64(i32 %55, i32 %37, i32 %xcap)
  %90 = call i32 @cq_template_select_f64(i32 %50, i32 %84, i32 %89)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %89)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %83)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %81)
  %91 = bitcast double %70 to i64
  %92 = trunc i64 %91 to i32
  call void @cqrt_push(i32 %92)
  %93 = lshr i64 %91, 32
  %94 = trunc i64 %93 to i32
  call void @cqrt_push(i32 %94)
  %95 = bitcast double %63 to i64
  %96 = trunc i64 %95 to i32
  call void @cqrt_push(i32 %96)
  %97 = lshr i64 %95, 32
  %98 = trunc i64 %97 to i32
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %43)
  %99 = trunc i64 %39 to i32
  call void @cqrt_push(i32 %99)
  %100 = lshr i64 %39, 32
  %101 = trunc i64 %100 to i32
  call void @cqrt_push(i32 %101)
  call void @cqrt_push(i32 %40)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  br i1 %86, label %33, label %34

102:                                              ; preds = %33
  %103 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %104 = call i32 @cq_template_sitofp_i32_to_f64(i32 %103)
  br label %105

105:                                              ; preds = %102
  %106 = call i32 @cqrt_alloc_i1(i1 false)
  %107 = call i32 @cqrt_alloc_i1(i1 false)
  %108 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %108)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %108)
  call void @cqrt_and_i1(i32 %15, i32 %108, i32 %107)
  call void @cqrt_xor_i1(i32 %107, i32 %106)
  call void @cqrt_and_i1(i32 %107, i32 %23, i32 %106)
  %109 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %110 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %112

111:                                              ; preds = %112
  br label %182

112:                                              ; preds = %112, %105
  %from = phi i32 [ 0, %112 ], [ 1, %105 ]
  %113 = phi i64 [ 0, %105 ], [ %165, %112 ]
  %114 = phi i32 [ %109, %105 ], [ %167, %112 ]
  %115 = phi i32 [ %110, %105 ], [ %168, %112 ]
  %trip1 = phi i32 [ %106, %105 ], [ %128, %112 ]
  %xcap2 = phi i32 [ %90, %105 ], [ %169, %112 ]
  call void @cqrt_push(i32 %from)
  %116 = getelementptr inbounds [8 x double], ptr %8, i64 0, i64 %113
  %117 = ptrtoint ptr %116 to i64
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  %119 = call i32 @cqrt_alloc_i1(i1 false)
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %120)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %120)
  call void @cqrt_and_i1(i32 %15, i32 %120, i32 %119)
  call void @cqrt_xor_i1(i32 %119, i32 %118)
  call void @cqrt_and_i1(i32 %119, i32 %23, i32 %118)
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %118, i32 %121)
  %122 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %121, i32 %7, i64 %117)
  %123 = call i32 @cq_template_fabs_f64(i32 %122)
  %124 = call i32 @cq_template_fcmp_ogt_f64(i32 %114, i32 %123)
  %125 = call i32 @cq_template_select_f64(i32 %124, i32 %114, i32 %123)
  %126 = call i32 @cq_template_fdiv_f64(i32 %123, i32 %125)
  %127 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %126, double 0x3D06849B86A12B9B)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %128)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  %131 = call i32 @cqrt_alloc_i1(i1 false)
  %132 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %132)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %132)
  call void @cqrt_and_i1(i32 %15, i32 %132, i32 %131)
  call void @cqrt_xor_i1(i32 %131, i32 %130)
  call void @cqrt_and_i1(i32 %131, i32 %23, i32 %130)
  call void @cqrt_and_i1(i32 %127, i32 %130, i32 %129)
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %129, i32 %133)
  call void @cqrt_and_i1(i32 %trip1, i32 %129, i32 %128)
  %134 = trunc i64 %113 to i32
  %135 = add i32 %134, 1
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  %140 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %140)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %140)
  call void @cqrt_and_i1(i32 %15, i32 %140, i32 %139)
  call void @cqrt_xor_i1(i32 %139, i32 %138)
  call void @cqrt_and_i1(i32 %139, i32 %23, i32 %138)
  call void @cqrt_xor_i1(i32 %138, i32 %137)
  call void @cqrt_and_i1(i32 %138, i32 %127, i32 %137)
  call void @cqrt_xor_i1(i32 %137, i32 %136)
  call void @cqrt_and_i1(i32 %137, i32 %24, i32 %136)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %136, i32 %141)
  %142 = call fastcc double @__cq_q_yn__00_ctl(i32 %141, i32 %135, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %136, i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cqrt_and_i1(i32 %137, i32 %24, i32 %136)
  call void @cqrt_xor_i1(i32 %137, i32 %136)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %138, i32 %127, i32 %137)
  call void @cqrt_xor_i1(i32 %138, i32 %137)
  call void @cqrt_free(i32 %137)
  call void @cqrt_and_i1(i32 %139, i32 %23, i32 %138)
  call void @cqrt_xor_i1(i32 %139, i32 %138)
  call void @cqrt_free(i32 %138)
  call void @cqrt_and_i1(i32 %15, i32 %140, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %140)
  call void @cqrt_xor_i1(i32 %10, i32 %140)
  call void @cqrt_free(i32 %140)
  %143 = call i32 @cqrt_alloc_i1(i1 false)
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %147)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %147)
  call void @cqrt_and_i1(i32 %15, i32 %147, i32 %146)
  call void @cqrt_xor_i1(i32 %146, i32 %145)
  call void @cqrt_and_i1(i32 %146, i32 %23, i32 %145)
  call void @cqrt_xor_i1(i32 %145, i32 %144)
  call void @cqrt_and_i1(i32 %145, i32 %127, i32 %144)
  call void @cqrt_and_i1(i32 %24, i32 %144, i32 %143)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %143, i32 %148)
  %149 = call fastcc double @__cq_q_jn__00_ctl(i32 %148, i32 %135, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %143, i32 %148)
  call void @cqrt_free(i32 %148)
  call void @cqrt_and_i1(i32 %24, i32 %144, i32 %143)
  call void @cqrt_free(i32 %143)
  call void @cqrt_and_i1(i32 %145, i32 %127, i32 %144)
  call void @cqrt_xor_i1(i32 %145, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_and_i1(i32 %146, i32 %23, i32 %145)
  call void @cqrt_xor_i1(i32 %146, i32 %145)
  call void @cqrt_free(i32 %145)
  call void @cqrt_and_i1(i32 %15, i32 %147, i32 %146)
  call void @cqrt_free(i32 %146)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %147)
  call void @cqrt_xor_i1(i32 %10, i32 %147)
  call void @cqrt_free(i32 %147)
  %150 = call i32 @cq_template_select_f64_ll(i32 %24, double %149, double %142)
  %151 = trunc nuw nsw i64 %113 to i32
  %152 = uitofp nneg i32 %151 to double
  %153 = call i32 @cq_template_fmul_f64_hl(i32 %104, double 5.000000e-01)
  %154 = call i32 @cq_template_fadd_f64_hl(i32 %153, double %152)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %158)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %158)
  call void @cqrt_and_i1(i32 %15, i32 %158, i32 %157)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_and_i1(i32 %157, i32 %23, i32 %156)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_and_i1(i32 %156, i32 %127, i32 %155)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %155, i32 %159)
  %160 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %159, i32 %154)
  call void @cqrt_and_i1(i32 %trip1, i32 %155, i32 %159)
  call void @cqrt_free(i32 %159)
  call void @cqrt_and_i1(i32 %156, i32 %127, i32 %155)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_free(i32 %155)
  call void @cqrt_and_i1(i32 %157, i32 %23, i32 %156)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cqrt_and_i1(i32 %15, i32 %158, i32 %157)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %158)
  call void @cqrt_xor_i1(i32 %10, i32 %158)
  call void @cqrt_free(i32 %158)
  call void @cq_template_fadd_f64_hl_unc(i32 %154, i32 %153, double %152)
  call void @cqrt_free(i32 %154)
  call void @cq_template_fmul_f64_hl_unc(i32 %153, i32 %104, double 5.000000e-01)
  call void @cqrt_free(i32 %153)
  %161 = call i32 @cq_template_fmul_f64(i32 %122, i32 %160)
  %162 = call i32 @cq_template_fadd_f64_hl(i32 %150, double 1.000000e+00)
  %163 = call i32 @cq_template_fmul_f64(i32 %161, i32 %162)
  %164 = call i32 @cq_template_fadd_f64(i32 %163, i32 %115)
  %165 = add nuw nsw i64 %113, 1
  %166 = icmp eq i64 %165, 8
  %167 = call i32 @cq_template_select_f64(i32 %128, i32 %125, i32 %114)
  %168 = call i32 @cq_template_select_f64(i32 %128, i32 %164, i32 %115)
  %169 = call i32 @cq_template_select_f64(i32 %133, i32 %115, i32 %xcap2)
  %170 = call i32 @cq_template_select_f64(i32 %128, i32 %164, i32 %169)
  call void @cqrt_push(i32 %170)
  call void @cqrt_push(i32 %128)
  call void @cqrt_push(i32 %164)
  call void @cqrt_push(i32 %169)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %168)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %114)
  call void @cqrt_push(i32 %163)
  call void @cqrt_push(i32 %161)
  call void @cqrt_push(i32 %162)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %160)
  %171 = bitcast double %149 to i64
  %172 = trunc i64 %171 to i32
  call void @cqrt_push(i32 %172)
  %173 = lshr i64 %171, 32
  %174 = trunc i64 %173 to i32
  call void @cqrt_push(i32 %174)
  %175 = bitcast double %142 to i64
  %176 = trunc i64 %175 to i32
  call void @cqrt_push(i32 %176)
  %177 = lshr i64 %175, 32
  %178 = trunc i64 %177 to i32
  call void @cqrt_push(i32 %178)
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %127)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %132)
  call void @cqrt_push(i32 %126)
  call void @cqrt_push(i32 %123)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %121)
  %179 = trunc i64 %117 to i32
  call void @cqrt_push(i32 %179)
  %180 = lshr i64 %117, 32
  %181 = trunc i64 %180 to i32
  call void @cqrt_push(i32 %181)
  call void @cqrt_push(i32 %118)
  call void @cqrt_push(i32 %119)
  call void @cqrt_push(i32 %120)
  br i1 %166, label %111, label %112

182:                                              ; preds = %111
  %183 = call i32 @cqrt_alloc_i1(i1 false)
  %184 = call i32 @cqrt_alloc_i1(i1 false)
  %185 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %185)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %185)
  call void @cqrt_and_i1(i32 %15, i32 %185, i32 %184)
  call void @cqrt_xor_i1(i32 %184, i32 %183)
  call void @cqrt_and_i1(i32 %184, i32 %23, i32 %183)
  %186 = call i32 @cq_template_select_f64(i32 %183, i32 %164, i32 %170)
  %187 = ptrtoint ptr %8 to i64
  %188 = call i32 @cqrt_alloc_i1(i1 false)
  %189 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %189)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %189)
  call void @cqrt_and_i1(i32 %15, i32 %189, i32 %188)
  %190 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %188, i32 %7, i64 %187)
  %191 = call i32 @cq_template_fdiv_f64(i32 %186, i32 %190)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %190, i32 %188, i32 %7, i64 %187)
  call void @cqrt_free(i32 %190)
  call void @cqrt_and_i1(i32 %15, i32 %189, i32 %188)
  call void @cqrt_free(i32 %188)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %189)
  call void @cqrt_xor_i1(i32 %10, i32 %189)
  call void @cqrt_free(i32 %189)
  call void @cq_template_select_f64_unc(i32 %186, i32 %183, i32 %164, i32 %170)
  call void @cqrt_free(i32 %186)
  call void @cqrt_and_i1(i32 %184, i32 %23, i32 %183)
  call void @cqrt_xor_i1(i32 %184, i32 %183)
  call void @cqrt_free(i32 %183)
  call void @cqrt_and_i1(i32 %15, i32 %185, i32 %184)
  call void @cqrt_free(i32 %184)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %185)
  call void @cqrt_xor_i1(i32 %10, i32 %185)
  call void @cqrt_free(i32 %185)
  br label %201

192:                                              ; preds = %200
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %104, i32 %103)
  call void @cqrt_free(i32 %104)
  call void @cq_template_add_i32_hl_unc(i32 %103, i32 %1, i32 -1)
  call void @cqrt_free(i32 %103)
  br label %257

193:                                              ; preds = %256
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %25, i32 %1)
  call void @cqrt_free(i32 %25)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %0, i32 1)
  call void @cqrt_free(i32 %24)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %23, i32 %22, i32 0)
  call void @cqrt_free(i32 %23)
  call void @cq_template_and_i32_hl_unc(i32 %22, i32 %1, i32 1)
  call void @cqrt_free(i32 %22)
  %194 = call i32 @cqrt_alloc_i1(i1 false)
  %195 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %10, i32 %195)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %195)
  call void @cqrt_and_i1(i32 %15, i32 %195, i32 %194)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %195)
  call void @cqrt_xor_i1(i32 %10, i32 %195)
  call void @cqrt_free(i32 %195)
  call void @cqrt_qram_store_f64_controlled(i32 %194, i32 %7, i32 %3, i32 %191)
  %196 = call i32 @cq_template_select_i32_lh(i32 %15, i32 0, i32 %14)
  %197 = call i32 @cq_template_select_i32_lh(i32 %12, i32 2, i32 %196)
  %198 = call i32 @cq_template_select_i32_hl(i32 %10, i32 %197, i32 1)
  %199 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %198, i32 %199)
  call void @cq_template_select_i32_hl_unc(i32 %198, i32 %10, i32 %197, i32 1)
  call void @cqrt_free(i32 %198)
  call void @cq_template_select_i32_lh_unc(i32 %197, i32 %12, i32 2, i32 %196)
  call void @cqrt_free(i32 %197)
  call void @cq_template_select_i32_lh_unc(i32 %196, i32 %15, i32 0, i32 %14)
  call void @cqrt_free(i32 %196)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %14, i32 0)
  call void @cqrt_free(i32 %15)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %12, i32 %11, i32 -2)
  call void @cqrt_free(i32 %12)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %0, i32 -3)
  call void @cqrt_free(i32 %11)
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %10, i32 %2, double 0.000000e+00)
  call void @cqrt_free(i32 %10)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %199

200:                                              ; preds = %201
  call void @cqrt_free(i32 %110)
  call void @cqrt_free(i32 %109)
  call void @cqrt_and_i1(i32 %107, i32 %23, i32 %106)
  call void @cqrt_xor_i1(i32 %107, i32 %106)
  call void @cqrt_free(i32 %106)
  call void @cqrt_and_i1(i32 %15, i32 %108, i32 %107)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %108)
  call void @cqrt_xor_i1(i32 %10, i32 %108)
  call void @cqrt_free(i32 %108)
  br label %192

201:                                              ; preds = %182, %201
  %202 = call i32 @cqrt_pop()
  %203 = call i32 @cqrt_pop()
  %204 = call i32 @cqrt_pop()
  %205 = call i32 @cqrt_pop()
  %206 = zext i32 %205 to i64
  %207 = shl i64 %206, 32
  %208 = or i64 0, %207
  %209 = call i32 @cqrt_pop()
  %210 = zext i32 %209 to i64
  %211 = or i64 %208, %210
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
  %223 = zext i32 %222 to i64
  %224 = shl i64 %223, 32
  %225 = or i64 0, %224
  %226 = call i32 @cqrt_pop()
  %227 = zext i32 %226 to i64
  %228 = or i64 %225, %227
  %229 = bitcast i64 %228 to double
  %230 = call i32 @cqrt_pop()
  %231 = zext i32 %230 to i64
  %232 = shl i64 %231, 32
  %233 = or i64 0, %232
  %234 = call i32 @cqrt_pop()
  %235 = zext i32 %234 to i64
  %236 = or i64 %233, %235
  %237 = bitcast i64 %236 to double
  %238 = call i32 @cqrt_pop()
  %239 = call i32 @cqrt_pop()
  %240 = call i32 @cqrt_pop()
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
  %253 = call i32 @cqrt_pop()
  %254 = call i32 @cqrt_pop()
  call void @cq_template_select_f64_unc(i32 %254, i32 %253, i32 %252, i32 %251)
  call void @cqrt_free(i32 %254)
  call void @cq_template_select_f64_unc(i32 %251, i32 %250, i32 %249, i32 %248)
  call void @cqrt_free(i32 %251)
  call void @cq_template_select_f64_unc(i32 %247, i32 %253, i32 %252, i32 %249)
  call void @cqrt_free(i32 %247)
  call void @cq_template_select_f64_unc(i32 %246, i32 %253, i32 %245, i32 %244)
  call void @cqrt_free(i32 %246)
  call void @cq_template_fadd_f64_unc(i32 %252, i32 %243, i32 %249)
  call void @cqrt_free(i32 %252)
  call void @cq_template_fmul_f64_unc(i32 %243, i32 %242, i32 %241)
  call void @cqrt_free(i32 %243)
  call void @cq_template_fadd_f64_hl_unc(i32 %241, i32 %240, double 1.000000e+00)
  call void @cqrt_free(i32 %241)
  call void @cq_template_fmul_f64_unc(i32 %242, i32 %239, i32 %238)
  call void @cqrt_free(i32 %242)
  call void @cq_template_select_f64_ll_unc(i32 %240, i32 %24, double %237, double %229)
  call void @cqrt_free(i32 %240)
  call void @cqrt_and_i1(i32 %221, i32 %220, i32 %250)
  call void @cqrt_free(i32 %250)
  call void @cqrt_and_i1(i32 %221, i32 %220, i32 %253)
  call void @cqrt_xor_i1(i32 %221, i32 %253)
  call void @cqrt_free(i32 %253)
  call void @cqrt_and_i1(i32 %219, i32 %218, i32 %220)
  call void @cqrt_free(i32 %220)
  call void @cqrt_and_i1(i32 %217, i32 %23, i32 %218)
  call void @cqrt_xor_i1(i32 %217, i32 %218)
  call void @cqrt_free(i32 %218)
  call void @cqrt_and_i1(i32 %15, i32 %216, i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %216)
  call void @cqrt_xor_i1(i32 %10, i32 %216)
  call void @cqrt_free(i32 %216)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %219, i32 %215, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %219)
  call void @cq_template_fdiv_f64_unc(i32 %215, i32 %214, i32 %245)
  call void @cqrt_free(i32 %215)
  call void @cq_template_select_f64_unc(i32 %245, i32 %213, i32 %244, i32 %214)
  call void @cqrt_free(i32 %245)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %213, i32 %244, i32 %214)
  call void @cqrt_free(i32 %213)
  call void @cq_template_fabs_f64_unc(i32 %214, i32 %239)
  call void @cqrt_free(i32 %214)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %239, i32 %212, i32 %7, i64 %211)
  call void @cqrt_and_i1(i32 %221, i32 %204, i32 %212)
  call void @cqrt_free(i32 %212)
  call void @cqrt_and_i1(i32 %203, i32 %23, i32 %204)
  call void @cqrt_xor_i1(i32 %203, i32 %204)
  call void @cqrt_free(i32 %204)
  call void @cqrt_and_i1(i32 %15, i32 %202, i32 %203)
  call void @cqrt_free(i32 %203)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %202)
  call void @cqrt_xor_i1(i32 %10, i32 %202)
  call void @cqrt_free(i32 %202)
  %255 = call i32 @cqrt_pop()
  switch i32 %255, label %201 [
    i32 1, label %200
  ]

256:                                              ; preds = %257
  call void @cqrt_free(i32 %32)
  call void @cqrt_free(i32 %31)
  call void @cqrt_free(i32 %30)
  call void @cqrt_and_i1(i32 %23, i32 %28, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_and_i1(i32 %15, i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %29)
  call void @cqrt_xor_i1(i32 %10, i32 %29)
  call void @cqrt_free(i32 %29)
  br label %193

257:                                              ; preds = %192, %257
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = call i32 @cqrt_pop()
  %262 = zext i32 %261 to i64
  %263 = shl i64 %262, 32
  %264 = or i64 0, %263
  %265 = call i32 @cqrt_pop()
  %266 = zext i32 %265 to i64
  %267 = or i64 %264, %266
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
  %285 = bitcast i64 %284 to double
  %286 = call i32 @cqrt_pop()
  %287 = zext i32 %286 to i64
  %288 = shl i64 %287, 32
  %289 = or i64 0, %288
  %290 = call i32 @cqrt_pop()
  %291 = zext i32 %290 to i64
  %292 = or i64 %289, %291
  %293 = bitcast i64 %292 to double
  %294 = call i32 @cqrt_pop()
  %295 = call i32 @cqrt_pop()
  %296 = call i32 @cqrt_pop()
  %297 = call i32 @cqrt_pop()
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
  call void @cq_template_select_f64_unc(i32 %309, i32 %308, i32 %307, i32 %306)
  call void @cqrt_free(i32 %309)
  call void @cq_template_select_f64_unc(i32 %306, i32 %305, i32 %304, i32 %303)
  call void @cqrt_free(i32 %306)
  call void @cq_template_select_f64_unc(i32 %302, i32 %308, i32 %307, i32 %304)
  call void @cqrt_free(i32 %302)
  call void @cq_template_select_f64_unc(i32 %301, i32 %308, i32 %300, i32 %299)
  call void @cqrt_free(i32 %301)
  call void @cq_template_fadd_f64_unc(i32 %307, i32 %298, i32 %304)
  call void @cqrt_free(i32 %307)
  call void @cq_template_fmul_f64_unc(i32 %298, i32 %297, i32 %296)
  call void @cqrt_free(i32 %298)
  call void @cq_template_fmul_f64_unc(i32 %297, i32 %295, i32 %294)
  call void @cqrt_free(i32 %297)
  call void @cq_template_select_f64_ll_unc(i32 %296, i32 %24, double %293, double %285)
  call void @cqrt_free(i32 %296)
  call void @cqrt_and_i1(i32 %277, i32 %276, i32 %305)
  call void @cqrt_free(i32 %305)
  call void @cqrt_and_i1(i32 %277, i32 %276, i32 %308)
  call void @cqrt_xor_i1(i32 %277, i32 %308)
  call void @cqrt_free(i32 %308)
  call void @cqrt_and_i1(i32 %275, i32 %274, i32 %276)
  call void @cqrt_free(i32 %276)
  call void @cqrt_and_i1(i32 %23, i32 %273, i32 %274)
  call void @cqrt_free(i32 %274)
  call void @cqrt_and_i1(i32 %15, i32 %272, i32 %273)
  call void @cqrt_free(i32 %273)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %272)
  call void @cqrt_xor_i1(i32 %10, i32 %272)
  call void @cqrt_free(i32 %272)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %275, i32 %271, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %275)
  call void @cq_template_fdiv_f64_unc(i32 %271, i32 %270, i32 %300)
  call void @cqrt_free(i32 %271)
  call void @cq_template_select_f64_unc(i32 %300, i32 %269, i32 %299, i32 %270)
  call void @cqrt_free(i32 %300)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %269, i32 %299, i32 %270)
  call void @cqrt_free(i32 %269)
  call void @cq_template_fabs_f64_unc(i32 %270, i32 %295)
  call void @cqrt_free(i32 %270)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %295, i32 %268, i32 %7, i64 %267)
  call void @cqrt_and_i1(i32 %277, i32 %260, i32 %268)
  call void @cqrt_free(i32 %268)
  call void @cqrt_and_i1(i32 %23, i32 %259, i32 %260)
  call void @cqrt_free(i32 %260)
  call void @cqrt_and_i1(i32 %15, i32 %258, i32 %259)
  call void @cqrt_free(i32 %259)
  call void @cqrt_and_i1(i32 %10, i32 %12, i32 %258)
  call void @cqrt_xor_i1(i32 %10, i32 %258)
  call void @cqrt_free(i32 %258)
  %310 = call i32 @cqrt_pop()
  switch i32 %310, label %257 [
    i32 1, label %256
  ]
}

declare i32 @cq_template_fcmp_ugt_f64_hl(i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)

define internal fastcc i32 @__cq_q_char_a_110_ctl(i32 %0, i32 %1, i32 %2, ptr %3) unnamed_addr {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_sitofp_i32_to_f64(i32 %1)
  %7 = call i32 @cq_template_fmul_f64(i32 %6, i32 %2)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %6, i32 %1)
  call void @cqrt_free(i32 %6)
  %8 = ptrtoint ptr %3 to i64
  call void @cqrt_qram_store_f64_hl_controlled(i32 %0, i32 %5, i64 %8, i32 %7)
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 6)
  %10 = call i32 @cq_template_zext_i1_to_i32(i32 %9)
  %11 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %10, i32 %11)
  call void @cq_template_zext_i1_to_i32_unc(i32 %10, i32 %9)
  call void @cqrt_free(i32 %10)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %1, i32 6)
  call void @cqrt_free(i32 %9)
  ret i32 %11
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

define internal fastcc void @__cq_q_fill_110_ctl(i32 %0, i32 %1, i32 %2, ptr %3) unnamed_addr {
  %5 = call i32 @__cq_mem()
  %6 = call i32 @cq_template_fadd_f64(i32 %1, i32 %2)
  br label %7

7:                                                ; preds = %4
  br label %9

8:                                                ; preds = %19
  br label %24

9:                                                ; preds = %19, %7
  %from = phi i32 [ 0, %19 ], [ 1, %7 ]
  %10 = phi i64 [ 0, %7 ], [ %12, %19 ]
  %11 = icmp ult i64 %10, 3
  %12 = add nuw nsw i64 %10, 1
  %13 = trunc nuw nsw i64 %12 to i32
  %14 = uitofp nneg i32 %13 to double
  %15 = call i32 @cq_template_fdiv_f64_hl(i32 %6, double %14)
  %16 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %17 = select i1 %11, i32 %15, i32 %16
  %cq.ch = select i1 %11, i1 false, i1 true
  %cq.not = xor i1 %cq.ch, true
  br i1 %cq.not, label %.cq.arm, label %18

.cq.arm:                                          ; preds = %9
  call void @cqrt_free(i32 %16)
  br label %18

18:                                               ; preds = %9, %.cq.arm
  %cq.not1 = xor i1 %11, true
  br i1 %cq.not1, label %.cq.arm2, label %19

.cq.arm2:                                         ; preds = %18
  call void @cq_template_fdiv_f64_hl_unc(i32 %15, i32 %6, double %14)
  call void @cqrt_free(i32 %15)
  br label %19

19:                                               ; preds = %.cq.arm2, %18
  call void @cqrt_push(i32 %from)
  %20 = getelementptr inbounds double, ptr %3, i64 %10
  %21 = ptrtoint ptr %20 to i64
  call void @cqrt_qram_store_f64_hl_controlled(i32 %0, i32 %5, i64 %21, i32 %17)
  %22 = icmp eq i64 %12, 8
  br i1 %22, label %8, label %9

23:                                               ; preds = %24
  call void @cq_template_fadd_f64_unc(i32 %6, i32 %1, i32 %2)
  call void @cqrt_free(i32 %6)
  ret void

24:                                               ; preds = %8, %24
  %25 = call i32 @cqrt_pop()
  switch i32 %25, label %24 [
    i32 1, label %23
  ]
}

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_sitofp_i32_to_f64(i32)

declare i32 @cq_template_select_f64_ll(i32, double, double)

declare i32 @cq_template_fadd_f64_hl(i32, double)

define internal fastcc i32 @__cq_q_sgn_1_ctl(i32 %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @calls to i64), i32 %4)
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
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %3, i64 ptrtoint (ptr @calls to i64), i32 %6)
  call void @cqrt_free(i32 %6)
  %9 = call i32 @cq_template_fptosi_f64_to_i64(i32 %1)
  %10 = call i32 @cq_template_and_i64_hl(i32 %9, i64 1)
  %11 = call i32 @cq_template_icmp_eq_i64_hl(i32 %10, i64 0)
  %12 = call i32 @cq_template_select_f64_ll(i32 %11, double 1.000000e+00, double -1.000000e+00)
  %13 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %12, i32 %13)
  call void @cq_template_select_f64_ll_unc(i32 %12, i32 %11, double 1.000000e+00, double -1.000000e+00)
  call void @cqrt_free(i32 %12)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %11, i32 %10, i64 0)
  call void @cqrt_free(i32 %11)
  call void @cq_template_and_i64_hl_unc(i32 %10, i32 %9, i64 1)
  call void @cqrt_free(i32 %10)
  call void @cq_template_fptosi_f64_to_i64_unc(i32 %9, i32 %1)
  call void @cqrt_free(i32 %9)
  ret i32 %13
}

declare i32 @cq_template_fmul_f64(i32, i32)

declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

declare void @cqrt_qram_store_f64_controlled(i32, i32, i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare i32 @cq_template_select_i32_hl(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare void @cq_template_fmul_f64_unc(i32, i32, i32)

declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)

declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)

declare void @cq_template_fcmp_ugt_f64_hl_unc(i32, i32, double)

define internal i32 @__cq_q_mc_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_mc, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_mc, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %340

11:                                               ; preds = %6
  %12 = call i32 @__cq_mem()
  %13 = call ptr @__cq_alloc(i64 64, i64 16)
  %14 = call ptr @__cq_alloc(i64 8, i64 8)
  %15 = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %3, double 0.000000e+00)
  %16 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -3)
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %16, i32 -2)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %19)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %19)
  call void @cqrt_and_i1(i32 %0, i32 %19, i32 %18)
  %20 = call fastcc i32 @__cq_q_char_a_110_ctl(i32 %18, i32 %2, i32 %3, ptr %14)
  call void @cqrt_and_i1(i32 %0, i32 %19, i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %19)
  call void @cqrt_xor_i1(i32 %15, i32 %19)
  call void @cqrt_free(i32 %19)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 0)
  %22 = ptrtoint ptr %14 to i64
  %23 = call i32 @cqrt_alloc_i1(i1 false)
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %25)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %25)
  call void @cqrt_and_i1(i32 %21, i32 %25, i32 %24)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %23)
  %26 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %23, i32 %12, i64 %22)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %29)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %29)
  call void @cqrt_and_i1(i32 %21, i32 %29, i32 %28)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %27)
  call fastcc void @__cq_q_fill_110_ctl(i32 %27, i32 %3, i32 %26, ptr %13)
  call void @cqrt_and_i1(i32 %0, i32 %28, i32 %27)
  call void @cqrt_free(i32 %27)
  call void @cqrt_and_i1(i32 %21, i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %29)
  call void @cqrt_xor_i1(i32 %15, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %26, i32 %23, i32 %12, i64 %22)
  call void @cqrt_and_i1(i32 %0, i32 %24, i32 %23)
  call void @cqrt_free(i32 %23)
  call void @cqrt_and_i1(i32 %21, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %25)
  call void @cqrt_xor_i1(i32 %15, i32 %25)
  call void @cqrt_free(i32 %25)
  %30 = call i32 @cq_template_and_i32_hl(i32 %2, i32 1)
  %31 = call i32 @cq_template_icmp_eq_i32_hl(i32 %30, i32 0)
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)
  %33 = call i32 @cq_template_sitofp_i32_to_f64(i32 %2)
  br label %34

34:                                               ; preds = %11
  %35 = call i32 @cqrt_alloc_i1(i1 false)
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %38)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %38)
  call void @cqrt_and_i1(i32 %21, i32 %38, i32 %37)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %36)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  %39 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %40 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %41 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %43

42:                                               ; preds = %43
  br label %116

43:                                               ; preds = %43, %34
  %from3 = phi i32 [ 0, %43 ], [ 1, %34 ]
  %44 = phi i64 [ 0, %34 ], [ %99, %43 ]
  %45 = phi i32 [ %39, %34 ], [ %101, %43 ]
  %46 = phi i32 [ %40, %34 ], [ %102, %43 ]
  %trip = phi i32 [ %35, %34 ], [ %60, %43 ]
  %xcap = phi i32 [ %41, %34 ], [ %103, %43 ]
  call void @cqrt_push(i32 %from3)
  %47 = getelementptr inbounds [8 x double], ptr %13, i64 0, i64 %44
  %48 = ptrtoint ptr %47 to i64
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %52)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %52)
  call void @cqrt_and_i1(i32 %21, i32 %52, i32 %51)
  call void @cqrt_and_i1(i32 %31, i32 %51, i32 %50)
  call void @cqrt_and_i1(i32 %0, i32 %50, i32 %49)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %49, i32 %53)
  %54 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %53, i32 %12, i64 %48)
  %55 = call i32 @cq_template_fabs_f64(i32 %54)
  %56 = call i32 @cq_template_fcmp_ogt_f64(i32 %45, i32 %55)
  %57 = call i32 @cq_template_select_f64(i32 %56, i32 %45, i32 %55)
  %58 = call i32 @cq_template_fdiv_f64(i32 %55, i32 %57)
  %59 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %58, double 0x3D06849B86A12B9B)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %60)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %65)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %65)
  call void @cqrt_and_i1(i32 %21, i32 %65, i32 %64)
  call void @cqrt_and_i1(i32 %31, i32 %64, i32 %63)
  call void @cqrt_and_i1(i32 %59, i32 %63, i32 %62)
  call void @cqrt_and_i1(i32 %0, i32 %62, i32 %61)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %61, i32 %66)
  call void @cqrt_and_i1(i32 %trip, i32 %61, i32 %60)
  %67 = trunc nuw nsw i64 %44 to i32
  %68 = call i32 @cqrt_alloc_i1(i1 false)
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %73)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %73)
  call void @cqrt_and_i1(i32 %21, i32 %73, i32 %72)
  call void @cqrt_and_i1(i32 %31, i32 %72, i32 %71)
  call void @cqrt_xor_i1(i32 %71, i32 %70)
  call void @cqrt_and_i1(i32 %71, i32 %32, i32 %70)
  call void @cqrt_xor_i1(i32 %70, i32 %69)
  call void @cqrt_and_i1(i32 %70, i32 %59, i32 %69)
  call void @cqrt_and_i1(i32 %0, i32 %69, i32 %68)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %68, i32 %74)
  %75 = call fastcc double @__cq_q_yn__00_ctl(i32 %74, i32 %67, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %68, i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cqrt_and_i1(i32 %0, i32 %69, i32 %68)
  call void @cqrt_free(i32 %68)
  call void @cqrt_and_i1(i32 %70, i32 %59, i32 %69)
  call void @cqrt_xor_i1(i32 %70, i32 %69)
  call void @cqrt_free(i32 %69)
  call void @cqrt_and_i1(i32 %71, i32 %32, i32 %70)
  call void @cqrt_xor_i1(i32 %71, i32 %70)
  call void @cqrt_free(i32 %70)
  call void @cqrt_and_i1(i32 %31, i32 %72, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %21, i32 %73, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %73)
  call void @cqrt_xor_i1(i32 %15, i32 %73)
  call void @cqrt_free(i32 %73)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %81)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %81)
  call void @cqrt_and_i1(i32 %21, i32 %81, i32 %80)
  call void @cqrt_and_i1(i32 %31, i32 %80, i32 %79)
  call void @cqrt_and_i1(i32 %32, i32 %79, i32 %78)
  call void @cqrt_xor_i1(i32 %78, i32 %77)
  call void @cqrt_and_i1(i32 %78, i32 %59, i32 %77)
  call void @cqrt_and_i1(i32 %0, i32 %77, i32 %76)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %76, i32 %82)
  %83 = call fastcc double @__cq_q_jn__00_ctl(i32 %82, i32 %67, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %76, i32 %82)
  call void @cqrt_free(i32 %82)
  call void @cqrt_and_i1(i32 %0, i32 %77, i32 %76)
  call void @cqrt_free(i32 %76)
  call void @cqrt_and_i1(i32 %78, i32 %59, i32 %77)
  call void @cqrt_xor_i1(i32 %78, i32 %77)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %32, i32 %79, i32 %78)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %31, i32 %80, i32 %79)
  call void @cqrt_free(i32 %79)
  call void @cqrt_and_i1(i32 %21, i32 %81, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %81)
  call void @cqrt_xor_i1(i32 %15, i32 %81)
  call void @cqrt_free(i32 %81)
  %84 = call i32 @cq_template_select_f64_ll(i32 %32, double %83, double %75)
  %85 = trunc nuw nsw i64 %44 to i32
  %86 = uitofp nneg i32 %85 to double
  %87 = call i32 @cq_template_fmul_f64_hl(i32 %33, double 5.000000e-01)
  %88 = call i32 @cq_template_fadd_f64_hl(i32 %87, double %86)
  %89 = call i32 @cqrt_alloc_i1(i1 false)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %93)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %93)
  call void @cqrt_and_i1(i32 %21, i32 %93, i32 %92)
  call void @cqrt_and_i1(i32 %31, i32 %92, i32 %91)
  call void @cqrt_xor_i1(i32 %91, i32 %90)
  call void @cqrt_and_i1(i32 %91, i32 %59, i32 %90)
  call void @cqrt_and_i1(i32 %0, i32 %90, i32 %89)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %89, i32 %94)
  %95 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %94, i32 %88)
  call void @cqrt_and_i1(i32 %trip, i32 %89, i32 %94)
  call void @cqrt_free(i32 %94)
  call void @cqrt_and_i1(i32 %0, i32 %90, i32 %89)
  call void @cqrt_free(i32 %89)
  call void @cqrt_and_i1(i32 %91, i32 %59, i32 %90)
  call void @cqrt_xor_i1(i32 %91, i32 %90)
  call void @cqrt_free(i32 %90)
  call void @cqrt_and_i1(i32 %31, i32 %92, i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cqrt_and_i1(i32 %21, i32 %93, i32 %92)
  call void @cqrt_free(i32 %92)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %93)
  call void @cqrt_xor_i1(i32 %15, i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cq_template_fadd_f64_hl_unc(i32 %88, i32 %87, double %86)
  call void @cqrt_free(i32 %88)
  call void @cq_template_fmul_f64_hl_unc(i32 %87, i32 %33, double 5.000000e-01)
  call void @cqrt_free(i32 %87)
  %96 = call i32 @cq_template_fmul_f64(i32 %54, i32 %95)
  %97 = call i32 @cq_template_fmul_f64(i32 %96, i32 %84)
  %98 = call i32 @cq_template_fadd_f64(i32 %97, i32 %46)
  %99 = add nuw nsw i64 %44, 1
  %100 = icmp eq i64 %99, 8
  %101 = call i32 @cq_template_select_f64(i32 %60, i32 %57, i32 %45)
  %102 = call i32 @cq_template_select_f64(i32 %60, i32 %98, i32 %46)
  %103 = call i32 @cq_template_select_f64(i32 %66, i32 %46, i32 %xcap)
  %104 = call i32 @cq_template_select_f64(i32 %60, i32 %98, i32 %103)
  call void @cqrt_push(i32 %104)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %102)
  call void @cqrt_push(i32 %101)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %95)
  %105 = bitcast double %83 to i64
  %106 = trunc i64 %105 to i32
  call void @cqrt_push(i32 %106)
  %107 = lshr i64 %105, 32
  %108 = trunc i64 %107 to i32
  call void @cqrt_push(i32 %108)
  %109 = bitcast double %75 to i64
  %110 = trunc i64 %109 to i32
  call void @cqrt_push(i32 %110)
  %111 = lshr i64 %109, 32
  %112 = trunc i64 %111 to i32
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %53)
  %113 = trunc i64 %48 to i32
  call void @cqrt_push(i32 %113)
  %114 = lshr i64 %48, 32
  %115 = trunc i64 %114 to i32
  call void @cqrt_push(i32 %115)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %52)
  br i1 %100, label %42, label %43

116:                                              ; preds = %42
  %117 = call i32 @cq_template_add_i32_hl(i32 %2, i32 -1)
  %118 = call i32 @cq_template_sitofp_i32_to_f64(i32 %117)
  br label %119

119:                                              ; preds = %116
  %120 = call i32 @cqrt_alloc_i1(i1 false)
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  %122 = call i32 @cqrt_alloc_i1(i1 false)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %123)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %123)
  call void @cqrt_and_i1(i32 %21, i32 %123, i32 %122)
  call void @cqrt_xor_i1(i32 %122, i32 %121)
  call void @cqrt_and_i1(i32 %122, i32 %31, i32 %121)
  call void @cqrt_and_i1(i32 %0, i32 %121, i32 %120)
  %124 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %125 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %127

126:                                              ; preds = %127
  br label %202

127:                                              ; preds = %127, %119
  %from = phi i32 [ 0, %127 ], [ 1, %119 ]
  %128 = phi i64 [ 0, %119 ], [ %185, %127 ]
  %129 = phi i32 [ %124, %119 ], [ %187, %127 ]
  %130 = phi i32 [ %125, %119 ], [ %188, %127 ]
  %trip1 = phi i32 [ %120, %119 ], [ %144, %127 ]
  %xcap2 = phi i32 [ %104, %119 ], [ %189, %127 ]
  call void @cqrt_push(i32 %from)
  %131 = getelementptr inbounds [8 x double], ptr %13, i64 0, i64 %128
  %132 = ptrtoint ptr %131 to i64
  %133 = call i32 @cqrt_alloc_i1(i1 false)
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %136)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %136)
  call void @cqrt_and_i1(i32 %21, i32 %136, i32 %135)
  call void @cqrt_xor_i1(i32 %135, i32 %134)
  call void @cqrt_and_i1(i32 %135, i32 %31, i32 %134)
  call void @cqrt_and_i1(i32 %0, i32 %134, i32 %133)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %133, i32 %137)
  %138 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %137, i32 %12, i64 %132)
  %139 = call i32 @cq_template_fabs_f64(i32 %138)
  %140 = call i32 @cq_template_fcmp_ogt_f64(i32 %129, i32 %139)
  %141 = call i32 @cq_template_select_f64(i32 %140, i32 %129, i32 %139)
  %142 = call i32 @cq_template_fdiv_f64(i32 %139, i32 %141)
  %143 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %142, double 0x3D06849B86A12B9B)
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %144)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %149)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %149)
  call void @cqrt_and_i1(i32 %21, i32 %149, i32 %148)
  call void @cqrt_xor_i1(i32 %148, i32 %147)
  call void @cqrt_and_i1(i32 %148, i32 %31, i32 %147)
  call void @cqrt_and_i1(i32 %143, i32 %147, i32 %146)
  call void @cqrt_and_i1(i32 %0, i32 %146, i32 %145)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %145, i32 %150)
  call void @cqrt_and_i1(i32 %trip1, i32 %145, i32 %144)
  %151 = trunc i64 %128 to i32
  %152 = add i32 %151, 1
  %153 = call i32 @cqrt_alloc_i1(i1 false)
  %154 = call i32 @cqrt_alloc_i1(i1 false)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %158)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %158)
  call void @cqrt_and_i1(i32 %21, i32 %158, i32 %157)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_and_i1(i32 %157, i32 %31, i32 %156)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_and_i1(i32 %156, i32 %143, i32 %155)
  call void @cqrt_xor_i1(i32 %155, i32 %154)
  call void @cqrt_and_i1(i32 %155, i32 %32, i32 %154)
  call void @cqrt_and_i1(i32 %0, i32 %154, i32 %153)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %153, i32 %159)
  %160 = call fastcc double @__cq_q_yn__00_ctl(i32 %159, i32 %152, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %153, i32 %159)
  call void @cqrt_free(i32 %159)
  call void @cqrt_and_i1(i32 %0, i32 %154, i32 %153)
  call void @cqrt_free(i32 %153)
  call void @cqrt_and_i1(i32 %155, i32 %32, i32 %154)
  call void @cqrt_xor_i1(i32 %155, i32 %154)
  call void @cqrt_free(i32 %154)
  call void @cqrt_and_i1(i32 %156, i32 %143, i32 %155)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_free(i32 %155)
  call void @cqrt_and_i1(i32 %157, i32 %31, i32 %156)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cqrt_and_i1(i32 %21, i32 %158, i32 %157)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %158)
  call void @cqrt_xor_i1(i32 %15, i32 %158)
  call void @cqrt_free(i32 %158)
  %161 = call i32 @cqrt_alloc_i1(i1 false)
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  %164 = call i32 @cqrt_alloc_i1(i1 false)
  %165 = call i32 @cqrt_alloc_i1(i1 false)
  %166 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %166)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %166)
  call void @cqrt_and_i1(i32 %21, i32 %166, i32 %165)
  call void @cqrt_xor_i1(i32 %165, i32 %164)
  call void @cqrt_and_i1(i32 %165, i32 %31, i32 %164)
  call void @cqrt_xor_i1(i32 %164, i32 %163)
  call void @cqrt_and_i1(i32 %164, i32 %143, i32 %163)
  call void @cqrt_and_i1(i32 %32, i32 %163, i32 %162)
  call void @cqrt_and_i1(i32 %0, i32 %162, i32 %161)
  %167 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %161, i32 %167)
  %168 = call fastcc double @__cq_q_jn__00_ctl(i32 %167, i32 %152, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %161, i32 %167)
  call void @cqrt_free(i32 %167)
  call void @cqrt_and_i1(i32 %0, i32 %162, i32 %161)
  call void @cqrt_free(i32 %161)
  call void @cqrt_and_i1(i32 %32, i32 %163, i32 %162)
  call void @cqrt_free(i32 %162)
  call void @cqrt_and_i1(i32 %164, i32 %143, i32 %163)
  call void @cqrt_xor_i1(i32 %164, i32 %163)
  call void @cqrt_free(i32 %163)
  call void @cqrt_and_i1(i32 %165, i32 %31, i32 %164)
  call void @cqrt_xor_i1(i32 %165, i32 %164)
  call void @cqrt_free(i32 %164)
  call void @cqrt_and_i1(i32 %21, i32 %166, i32 %165)
  call void @cqrt_free(i32 %165)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %166)
  call void @cqrt_xor_i1(i32 %15, i32 %166)
  call void @cqrt_free(i32 %166)
  %169 = call i32 @cq_template_select_f64_ll(i32 %32, double %168, double %160)
  %170 = trunc nuw nsw i64 %128 to i32
  %171 = uitofp nneg i32 %170 to double
  %172 = call i32 @cq_template_fmul_f64_hl(i32 %118, double 5.000000e-01)
  %173 = call i32 @cq_template_fadd_f64_hl(i32 %172, double %171)
  %174 = call i32 @cqrt_alloc_i1(i1 false)
  %175 = call i32 @cqrt_alloc_i1(i1 false)
  %176 = call i32 @cqrt_alloc_i1(i1 false)
  %177 = call i32 @cqrt_alloc_i1(i1 false)
  %178 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %178)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %178)
  call void @cqrt_and_i1(i32 %21, i32 %178, i32 %177)
  call void @cqrt_xor_i1(i32 %177, i32 %176)
  call void @cqrt_and_i1(i32 %177, i32 %31, i32 %176)
  call void @cqrt_xor_i1(i32 %176, i32 %175)
  call void @cqrt_and_i1(i32 %176, i32 %143, i32 %175)
  call void @cqrt_and_i1(i32 %0, i32 %175, i32 %174)
  %179 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %174, i32 %179)
  %180 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %179, i32 %173)
  call void @cqrt_and_i1(i32 %trip1, i32 %174, i32 %179)
  call void @cqrt_free(i32 %179)
  call void @cqrt_and_i1(i32 %0, i32 %175, i32 %174)
  call void @cqrt_free(i32 %174)
  call void @cqrt_and_i1(i32 %176, i32 %143, i32 %175)
  call void @cqrt_xor_i1(i32 %176, i32 %175)
  call void @cqrt_free(i32 %175)
  call void @cqrt_and_i1(i32 %177, i32 %31, i32 %176)
  call void @cqrt_xor_i1(i32 %177, i32 %176)
  call void @cqrt_free(i32 %176)
  call void @cqrt_and_i1(i32 %21, i32 %178, i32 %177)
  call void @cqrt_free(i32 %177)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %178)
  call void @cqrt_xor_i1(i32 %15, i32 %178)
  call void @cqrt_free(i32 %178)
  call void @cq_template_fadd_f64_hl_unc(i32 %173, i32 %172, double %171)
  call void @cqrt_free(i32 %173)
  call void @cq_template_fmul_f64_hl_unc(i32 %172, i32 %118, double 5.000000e-01)
  call void @cqrt_free(i32 %172)
  %181 = call i32 @cq_template_fmul_f64(i32 %138, i32 %180)
  %182 = call i32 @cq_template_fadd_f64_hl(i32 %169, double 1.000000e+00)
  %183 = call i32 @cq_template_fmul_f64(i32 %181, i32 %182)
  %184 = call i32 @cq_template_fadd_f64(i32 %183, i32 %130)
  %185 = add nuw nsw i64 %128, 1
  %186 = icmp eq i64 %185, 8
  %187 = call i32 @cq_template_select_f64(i32 %144, i32 %141, i32 %129)
  %188 = call i32 @cq_template_select_f64(i32 %144, i32 %184, i32 %130)
  %189 = call i32 @cq_template_select_f64(i32 %150, i32 %130, i32 %xcap2)
  %190 = call i32 @cq_template_select_f64(i32 %144, i32 %184, i32 %189)
  call void @cqrt_push(i32 %190)
  call void @cqrt_push(i32 %144)
  call void @cqrt_push(i32 %184)
  call void @cqrt_push(i32 %189)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %187)
  call void @cqrt_push(i32 %141)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %183)
  call void @cqrt_push(i32 %181)
  call void @cqrt_push(i32 %182)
  call void @cqrt_push(i32 %169)
  call void @cqrt_push(i32 %138)
  call void @cqrt_push(i32 %180)
  %191 = bitcast double %168 to i64
  %192 = trunc i64 %191 to i32
  call void @cqrt_push(i32 %192)
  %193 = lshr i64 %191, 32
  %194 = trunc i64 %193 to i32
  call void @cqrt_push(i32 %194)
  %195 = bitcast double %160 to i64
  %196 = trunc i64 %195 to i32
  call void @cqrt_push(i32 %196)
  %197 = lshr i64 %195, 32
  %198 = trunc i64 %197 to i32
  call void @cqrt_push(i32 %198)
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %146)
  call void @cqrt_push(i32 %143)
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %142)
  call void @cqrt_push(i32 %139)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %137)
  %199 = trunc i64 %132 to i32
  call void @cqrt_push(i32 %199)
  %200 = lshr i64 %132, 32
  %201 = trunc i64 %200 to i32
  call void @cqrt_push(i32 %201)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %134)
  call void @cqrt_push(i32 %135)
  call void @cqrt_push(i32 %136)
  br i1 %186, label %126, label %127

202:                                              ; preds = %126
  %203 = call i32 @cqrt_alloc_i1(i1 false)
  %204 = call i32 @cqrt_alloc_i1(i1 false)
  %205 = call i32 @cqrt_alloc_i1(i1 false)
  %206 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %206)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %206)
  call void @cqrt_and_i1(i32 %21, i32 %206, i32 %205)
  call void @cqrt_xor_i1(i32 %205, i32 %204)
  call void @cqrt_and_i1(i32 %205, i32 %31, i32 %204)
  call void @cqrt_and_i1(i32 %0, i32 %204, i32 %203)
  %207 = call i32 @cq_template_select_f64(i32 %203, i32 %184, i32 %190)
  %208 = ptrtoint ptr %13 to i64
  %209 = call i32 @cqrt_alloc_i1(i1 false)
  %210 = call i32 @cqrt_alloc_i1(i1 false)
  %211 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %211)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %211)
  call void @cqrt_and_i1(i32 %21, i32 %211, i32 %210)
  call void @cqrt_and_i1(i32 %0, i32 %210, i32 %209)
  %212 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %209, i32 %12, i64 %208)
  %213 = call i32 @cq_template_fdiv_f64(i32 %207, i32 %212)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %212, i32 %209, i32 %12, i64 %208)
  call void @cqrt_free(i32 %212)
  call void @cqrt_and_i1(i32 %0, i32 %210, i32 %209)
  call void @cqrt_free(i32 %209)
  call void @cqrt_and_i1(i32 %21, i32 %211, i32 %210)
  call void @cqrt_free(i32 %210)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %211)
  call void @cqrt_xor_i1(i32 %15, i32 %211)
  call void @cqrt_free(i32 %211)
  call void @cq_template_select_f64_unc(i32 %207, i32 %203, i32 %184, i32 %190)
  call void @cqrt_free(i32 %207)
  call void @cqrt_and_i1(i32 %0, i32 %204, i32 %203)
  call void @cqrt_free(i32 %203)
  call void @cqrt_and_i1(i32 %205, i32 %31, i32 %204)
  call void @cqrt_xor_i1(i32 %205, i32 %204)
  call void @cqrt_free(i32 %204)
  call void @cqrt_and_i1(i32 %21, i32 %206, i32 %205)
  call void @cqrt_free(i32 %205)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %206)
  call void @cqrt_xor_i1(i32 %15, i32 %206)
  call void @cqrt_free(i32 %206)
  br label %226

214:                                              ; preds = %225
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %118, i32 %117)
  call void @cqrt_free(i32 %118)
  call void @cq_template_add_i32_hl_unc(i32 %117, i32 %2, i32 -1)
  call void @cqrt_free(i32 %117)
  br label %284

215:                                              ; preds = %283
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %33, i32 %2)
  call void @cqrt_free(i32 %33)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %32, i32 %1, i32 1)
  call void @cqrt_free(i32 %32)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %31, i32 %30, i32 0)
  call void @cqrt_free(i32 %31)
  call void @cq_template_and_i32_hl_unc(i32 %30, i32 %2, i32 1)
  call void @cqrt_free(i32 %30)
  %216 = call i32 @cqrt_alloc_i1(i1 false)
  %217 = call i32 @cqrt_alloc_i1(i1 false)
  %218 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %15, i32 %218)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %218)
  call void @cqrt_and_i1(i32 %21, i32 %218, i32 %217)
  call void @cqrt_and_i1(i32 %0, i32 %217, i32 %216)
  call void @cqrt_and_i1(i32 %21, i32 %218, i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %218)
  call void @cqrt_xor_i1(i32 %15, i32 %218)
  call void @cqrt_free(i32 %218)
  call void @cqrt_qram_store_f64_controlled(i32 %216, i32 %12, i32 %4, i32 %213)
  %219 = call i32 @cq_template_select_i32_lh(i32 %21, i32 0, i32 %20)
  %220 = call i32 @cq_template_select_i32_lh(i32 %17, i32 2, i32 %219)
  %221 = call i32 @cq_template_select_i32_hl(i32 %15, i32 %220, i32 1)
  %222 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %221, i32 %222)
  call void @cq_template_select_i32_hl_unc(i32 %221, i32 %15, i32 %220, i32 1)
  call void @cqrt_free(i32 %221)
  call void @cq_template_select_i32_lh_unc(i32 %220, i32 %17, i32 2, i32 %219)
  call void @cqrt_free(i32 %220)
  call void @cq_template_select_i32_lh_unc(i32 %219, i32 %21, i32 0, i32 %20)
  call void @cqrt_free(i32 %219)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %20, i32 0)
  call void @cqrt_free(i32 %21)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %17, i32 %16, i32 -2)
  call void @cqrt_free(i32 %17)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %1, i32 -3)
  call void @cqrt_free(i32 %16)
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %15, i32 %3, double 0.000000e+00)
  call void @cqrt_free(i32 %15)
  %223 = load i32, ptr @__cq_act_mc, align 4
  %224 = add i32 %223, -1
  store i32 %224, ptr @__cq_act_mc, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %222

225:                                              ; preds = %226
  call void @cqrt_free(i32 %125)
  call void @cqrt_free(i32 %124)
  call void @cqrt_and_i1(i32 %0, i32 %121, i32 %120)
  call void @cqrt_free(i32 %120)
  call void @cqrt_and_i1(i32 %122, i32 %31, i32 %121)
  call void @cqrt_xor_i1(i32 %122, i32 %121)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %21, i32 %123, i32 %122)
  call void @cqrt_free(i32 %122)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %123)
  call void @cqrt_xor_i1(i32 %15, i32 %123)
  call void @cqrt_free(i32 %123)
  br label %214

226:                                              ; preds = %202, %226
  %227 = call i32 @cqrt_pop()
  %228 = call i32 @cqrt_pop()
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = zext i32 %231 to i64
  %233 = shl i64 %232, 32
  %234 = or i64 0, %233
  %235 = call i32 @cqrt_pop()
  %236 = zext i32 %235 to i64
  %237 = or i64 %234, %236
  %238 = call i32 @cqrt_pop()
  %239 = call i32 @cqrt_pop()
  %240 = call i32 @cqrt_pop()
  %241 = call i32 @cqrt_pop()
  %242 = call i32 @cqrt_pop()
  %243 = call i32 @cqrt_pop()
  %244 = call i32 @cqrt_pop()
  %245 = call i32 @cqrt_pop()
  %246 = call i32 @cqrt_pop()
  %247 = call i32 @cqrt_pop()
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = zext i32 %249 to i64
  %251 = shl i64 %250, 32
  %252 = or i64 0, %251
  %253 = call i32 @cqrt_pop()
  %254 = zext i32 %253 to i64
  %255 = or i64 %252, %254
  %256 = bitcast i64 %255 to double
  %257 = call i32 @cqrt_pop()
  %258 = zext i32 %257 to i64
  %259 = shl i64 %258, 32
  %260 = or i64 0, %259
  %261 = call i32 @cqrt_pop()
  %262 = zext i32 %261 to i64
  %263 = or i64 %260, %262
  %264 = bitcast i64 %263 to double
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
  %279 = call i32 @cqrt_pop()
  %280 = call i32 @cqrt_pop()
  %281 = call i32 @cqrt_pop()
  call void @cq_template_select_f64_unc(i32 %281, i32 %280, i32 %279, i32 %278)
  call void @cqrt_free(i32 %281)
  call void @cq_template_select_f64_unc(i32 %278, i32 %277, i32 %276, i32 %275)
  call void @cqrt_free(i32 %278)
  call void @cq_template_select_f64_unc(i32 %274, i32 %280, i32 %279, i32 %276)
  call void @cqrt_free(i32 %274)
  call void @cq_template_select_f64_unc(i32 %273, i32 %280, i32 %272, i32 %271)
  call void @cqrt_free(i32 %273)
  call void @cq_template_fadd_f64_unc(i32 %279, i32 %270, i32 %276)
  call void @cqrt_free(i32 %279)
  call void @cq_template_fmul_f64_unc(i32 %270, i32 %269, i32 %268)
  call void @cqrt_free(i32 %270)
  call void @cq_template_fadd_f64_hl_unc(i32 %268, i32 %267, double 1.000000e+00)
  call void @cqrt_free(i32 %268)
  call void @cq_template_fmul_f64_unc(i32 %269, i32 %266, i32 %265)
  call void @cqrt_free(i32 %269)
  call void @cq_template_select_f64_ll_unc(i32 %267, i32 %32, double %264, double %256)
  call void @cqrt_free(i32 %267)
  call void @cqrt_and_i1(i32 %248, i32 %247, i32 %277)
  call void @cqrt_free(i32 %277)
  call void @cqrt_and_i1(i32 %248, i32 %247, i32 %280)
  call void @cqrt_xor_i1(i32 %248, i32 %280)
  call void @cqrt_free(i32 %280)
  call void @cqrt_and_i1(i32 %0, i32 %246, i32 %247)
  call void @cqrt_free(i32 %247)
  call void @cqrt_and_i1(i32 %245, i32 %244, i32 %246)
  call void @cqrt_free(i32 %246)
  call void @cqrt_and_i1(i32 %243, i32 %31, i32 %244)
  call void @cqrt_xor_i1(i32 %243, i32 %244)
  call void @cqrt_free(i32 %244)
  call void @cqrt_and_i1(i32 %21, i32 %242, i32 %243)
  call void @cqrt_free(i32 %243)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %242)
  call void @cqrt_xor_i1(i32 %15, i32 %242)
  call void @cqrt_free(i32 %242)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %245, i32 %241, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %245)
  call void @cq_template_fdiv_f64_unc(i32 %241, i32 %240, i32 %272)
  call void @cqrt_free(i32 %241)
  call void @cq_template_select_f64_unc(i32 %272, i32 %239, i32 %271, i32 %240)
  call void @cqrt_free(i32 %272)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %239, i32 %271, i32 %240)
  call void @cqrt_free(i32 %239)
  call void @cq_template_fabs_f64_unc(i32 %240, i32 %266)
  call void @cqrt_free(i32 %240)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %266, i32 %238, i32 %12, i64 %237)
  call void @cqrt_and_i1(i32 %248, i32 %230, i32 %238)
  call void @cqrt_free(i32 %238)
  call void @cqrt_and_i1(i32 %0, i32 %229, i32 %230)
  call void @cqrt_free(i32 %230)
  call void @cqrt_and_i1(i32 %228, i32 %31, i32 %229)
  call void @cqrt_xor_i1(i32 %228, i32 %229)
  call void @cqrt_free(i32 %229)
  call void @cqrt_and_i1(i32 %21, i32 %227, i32 %228)
  call void @cqrt_free(i32 %228)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %227)
  call void @cqrt_xor_i1(i32 %15, i32 %227)
  call void @cqrt_free(i32 %227)
  %282 = call i32 @cqrt_pop()
  switch i32 %282, label %226 [
    i32 1, label %225
  ]

283:                                              ; preds = %284
  call void @cqrt_free(i32 %41)
  call void @cqrt_free(i32 %40)
  call void @cqrt_free(i32 %39)
  call void @cqrt_and_i1(i32 %0, i32 %36, i32 %35)
  call void @cqrt_free(i32 %35)
  call void @cqrt_and_i1(i32 %31, i32 %37, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_and_i1(i32 %21, i32 %38, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %38)
  call void @cqrt_xor_i1(i32 %15, i32 %38)
  call void @cqrt_free(i32 %38)
  br label %215

284:                                              ; preds = %214, %284
  %285 = call i32 @cqrt_pop()
  %286 = call i32 @cqrt_pop()
  %287 = call i32 @cqrt_pop()
  %288 = call i32 @cqrt_pop()
  %289 = call i32 @cqrt_pop()
  %290 = zext i32 %289 to i64
  %291 = shl i64 %290, 32
  %292 = or i64 0, %291
  %293 = call i32 @cqrt_pop()
  %294 = zext i32 %293 to i64
  %295 = or i64 %292, %294
  %296 = call i32 @cqrt_pop()
  %297 = call i32 @cqrt_pop()
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
  %308 = zext i32 %307 to i64
  %309 = shl i64 %308, 32
  %310 = or i64 0, %309
  %311 = call i32 @cqrt_pop()
  %312 = zext i32 %311 to i64
  %313 = or i64 %310, %312
  %314 = bitcast i64 %313 to double
  %315 = call i32 @cqrt_pop()
  %316 = zext i32 %315 to i64
  %317 = shl i64 %316, 32
  %318 = or i64 0, %317
  %319 = call i32 @cqrt_pop()
  %320 = zext i32 %319 to i64
  %321 = or i64 %318, %320
  %322 = bitcast i64 %321 to double
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
  call void @cq_template_select_f64_unc(i32 %338, i32 %337, i32 %336, i32 %335)
  call void @cqrt_free(i32 %338)
  call void @cq_template_select_f64_unc(i32 %335, i32 %334, i32 %333, i32 %332)
  call void @cqrt_free(i32 %335)
  call void @cq_template_select_f64_unc(i32 %331, i32 %337, i32 %336, i32 %333)
  call void @cqrt_free(i32 %331)
  call void @cq_template_select_f64_unc(i32 %330, i32 %337, i32 %329, i32 %328)
  call void @cqrt_free(i32 %330)
  call void @cq_template_fadd_f64_unc(i32 %336, i32 %327, i32 %333)
  call void @cqrt_free(i32 %336)
  call void @cq_template_fmul_f64_unc(i32 %327, i32 %326, i32 %325)
  call void @cqrt_free(i32 %327)
  call void @cq_template_fmul_f64_unc(i32 %326, i32 %324, i32 %323)
  call void @cqrt_free(i32 %326)
  call void @cq_template_select_f64_ll_unc(i32 %325, i32 %32, double %322, double %314)
  call void @cqrt_free(i32 %325)
  call void @cqrt_and_i1(i32 %306, i32 %305, i32 %334)
  call void @cqrt_free(i32 %334)
  call void @cqrt_and_i1(i32 %306, i32 %305, i32 %337)
  call void @cqrt_xor_i1(i32 %306, i32 %337)
  call void @cqrt_free(i32 %337)
  call void @cqrt_and_i1(i32 %0, i32 %304, i32 %305)
  call void @cqrt_free(i32 %305)
  call void @cqrt_and_i1(i32 %303, i32 %302, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cqrt_and_i1(i32 %31, i32 %301, i32 %302)
  call void @cqrt_free(i32 %302)
  call void @cqrt_and_i1(i32 %21, i32 %300, i32 %301)
  call void @cqrt_free(i32 %301)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %300)
  call void @cqrt_xor_i1(i32 %15, i32 %300)
  call void @cqrt_free(i32 %300)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %303, i32 %299, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %303)
  call void @cq_template_fdiv_f64_unc(i32 %299, i32 %298, i32 %329)
  call void @cqrt_free(i32 %299)
  call void @cq_template_select_f64_unc(i32 %329, i32 %297, i32 %328, i32 %298)
  call void @cqrt_free(i32 %329)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %297, i32 %328, i32 %298)
  call void @cqrt_free(i32 %297)
  call void @cq_template_fabs_f64_unc(i32 %298, i32 %324)
  call void @cqrt_free(i32 %298)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %324, i32 %296, i32 %12, i64 %295)
  call void @cqrt_and_i1(i32 %306, i32 %288, i32 %296)
  call void @cqrt_free(i32 %296)
  call void @cqrt_and_i1(i32 %0, i32 %287, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_and_i1(i32 %31, i32 %286, i32 %287)
  call void @cqrt_free(i32 %287)
  call void @cqrt_and_i1(i32 %21, i32 %285, i32 %286)
  call void @cqrt_free(i32 %286)
  call void @cqrt_and_i1(i32 %15, i32 %17, i32 %285)
  call void @cqrt_xor_i1(i32 %15, i32 %285)
  call void @cqrt_free(i32 %285)
  %339 = call i32 @cqrt_pop()
  switch i32 %339, label %284 [
    i32 1, label %283
  ]

340:                                              ; preds = %6
  %341 = call i32 @cqrt_alloc_i32(i32 0)
  %342 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %342)
  %343 = load i32, ptr @__cq_act_mc, align 4
  %344 = add i32 %343, -1
  store i32 %344, ptr @__cq_act_mc, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %341
}

declare void @cqrt_copy_i1(i32, i32)

declare void @cqrt_ry_f64(i32, double)

define i32 @__cq_q_mc_0010(i32 %0, i32 %1, i32 %2, ptr %3) local_unnamed_addr {
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 64, i64 16)
  %7 = call ptr @__cq_alloc(i64 8, i64 8)
  %8 = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %2, double 0.000000e+00)
  %9 = add i32 %0, -3
  %10 = icmp ult i32 %9, -2
  %11 = call i32 @cq_template_select_i32_ll(i32 %8, i32 2, i32 1)
  br i1 %10, label %12, label %26

12:                                               ; preds = %4, %26, %107
  %13 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %116, %107 ]
  %14 = phi i32 [ poison, %4 ], [ %27, %26 ], [ %27, %107 ]
  %15 = phi i32 [ poison, %4 ], [ %29, %26 ], [ %29, %107 ]
  %cq.run31 = phi i1 [ true, %4 ], [ true, %26 ], [ false, %107 ]
  %16 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %40, %107 ]
  %17 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %41, %107 ]
  %18 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %42, %107 ]
  %ran20 = phi i1 [ false, %4 ], [ false, %26 ], [ %ran24, %107 ]
  %19 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %108, %107 ]
  %20 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %109, %107 ]
  %21 = phi i32 [ poison, %4 ], [ poison, %26 ], [ %110, %107 ]
  %ran = phi i1 [ false, %4 ], [ false, %26 ], [ %ran11, %107 ]
  %cq.run3 = phi i1 [ true, %107 ], [ true, %26 ], [ false, %4 ]
  %cq.run = phi i1 [ true, %107 ], [ false, %26 ], [ false, %4 ]
  %22 = phi i32 [ %11, %4 ], [ %29, %26 ], [ %116, %107 ]
  br i1 %ran, label %202, label %234

23:                                               ; preds = %234
  br i1 %ran20, label %259, label %291

24:                                               ; preds = %291
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %22, i32 %25)
  br i1 %cq.run, label %.cq.arm41, label %.cq.after40

.cq.arm41:                                        ; preds = %24
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %8, i32 0, i32 1)
  call void @cqrt_free(i32 %13)
  br label %.cq.after40

.cq.after40:                                      ; preds = %24, %.cq.arm41
  br i1 %cq.run3, label %.cq.arm39, label %.cq.after38

.cq.arm39:                                        ; preds = %.cq.after40
  call void @cq_template_select_i32_ll_unc(i32 %15, i32 %8, i32 %14, i32 1)
  call void @cqrt_free(i32 %15)
  br label %.cq.after38

.cq.after38:                                      ; preds = %.cq.after40, %.cq.arm39
  call void @cq_template_select_i32_ll_unc(i32 %11, i32 %8, i32 2, i32 1)
  call void @cqrt_free(i32 %11)
  br i1 %cq.run25, label %.cq.arm, label %.cq.after

.cq.arm:                                          ; preds = %.cq.after38
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %8, i32 %2, double 0.000000e+00)
  call void @cqrt_free(i32 %8)
  br label %.cq.after

.cq.after:                                        ; preds = %.cq.after38, %.cq.arm
  ret i32 %25

26:                                               ; preds = %4
  %27 = call fastcc i32 @__cq_q_char_a_010_ctl(i32 %8, i32 %1, i32 %2, ptr %7)
  %28 = icmp eq i32 %27, 0
  %29 = call i32 @cq_template_select_i32_ll(i32 %8, i32 %27, i32 1)
  br i1 %28, label %30, label %12

30:                                               ; preds = %26
  %31 = ptrtoint ptr %7 to i64
  %32 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %8, i32 %5, i64 %31)
  call fastcc void @__cq_q_fill_110_ctl(i32 %8, i32 %2, i32 %32, ptr %6)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %32, i32 %8, i32 %5, i64 %31)
  %33 = and i32 %1, 1
  %34 = icmp eq i32 %33, 0
  %35 = icmp eq i32 %0, 1
  br i1 %34, label %36, label %38

36:                                               ; preds = %30
  %37 = sitofp i32 %1 to double
  br label %44

38:                                               ; preds = %102, %30
  %39 = phi i32 [ %93, %102 ], [ poison, %30 ]
  %40 = phi i32 [ %45, %102 ], [ poison, %30 ]
  %41 = phi i32 [ %46, %102 ], [ poison, %30 ]
  %42 = phi i32 [ %47, %102 ], [ poison, %30 ]
  %ran24 = phi i1 [ true, %102 ], [ false, %30 ]
  %43 = xor i1 %34, true
  br i1 %43, label %103, label %106

44:                                               ; preds = %36
  %45 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %46 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %47 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %49

48:                                               ; preds = %77
  br label %102

49:                                               ; preds = %77, %44
  %from16 = phi i32 [ 0, %77 ], [ 1, %44 ]
  %50 = phi i64 [ 0, %44 ], [ %88, %77 ]
  %51 = phi i32 [ %45, %44 ], [ %90, %77 ]
  %52 = phi i32 [ %46, %44 ], [ %91, %77 ]
  %trip = phi i32 [ %8, %44 ], [ %62, %77 ]
  %xcap = phi i32 [ %47, %44 ], [ %92, %77 ]
  call void @cqrt_push(i32 %from16)
  %53 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %50
  %54 = ptrtoint ptr %53 to i64
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %8, i32 %55)
  %56 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %55, i32 %5, i64 %54)
  %57 = call i32 @cq_template_fabs_f64(i32 %56)
  %58 = call i32 @cq_template_fcmp_ogt_f64(i32 %51, i32 %57)
  %59 = call i32 @cq_template_select_f64(i32 %58, i32 %51, i32 %57)
  %60 = call i32 @cq_template_fdiv_f64(i32 %57, i32 %59)
  %61 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %60, double 0x3D06849B86A12B9B)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %62)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %61, i32 %8, i32 %63)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %63, i32 %64)
  call void @cqrt_and_i1(i32 %trip, i32 %63, i32 %62)
  %65 = trunc nuw nsw i64 %50 to i32
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %55)
  %66 = trunc i64 %54 to i32
  call void @cqrt_push(i32 %66)
  %67 = lshr i64 %54, 32
  %68 = trunc i64 %67 to i32
  call void @cqrt_push(i32 %68)
  br i1 %35, label %69, label %73

69:                                               ; preds = %49
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %70)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %70)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %70, i32 %71)
  %72 = call fastcc double @__cq_q_jn__00_ctl(i32 %71, i32 %65, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %70, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %70)
  call void @cqrt_xor_i1(i32 %8, i32 %70)
  call void @cqrt_free(i32 %70)
  br label %77

73:                                               ; preds = %49
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %74)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %74)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %74, i32 %75)
  %76 = call fastcc double @__cq_q_yn__00_ctl(i32 %75, i32 %65, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %74, i32 %75)
  call void @cqrt_free(i32 %75)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %74)
  call void @cqrt_xor_i1(i32 %8, i32 %74)
  call void @cqrt_free(i32 %74)
  br label %77

77:                                               ; preds = %69, %73
  %from15 = phi i32 [ 0, %69 ], [ 1, %73 ]
  %78 = phi double [ %72, %69 ], [ %76, %73 ]
  call void @cqrt_push(i32 %from15)
  %79 = trunc nuw nsw i64 %50 to i32
  %80 = uitofp nneg i32 %79 to double
  %81 = tail call double @llvm.fmuladd.f64(double %37, double 5.000000e-01, double %80)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %82)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %82)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %82, i32 %83)
  %84 = call fastcc double @__cq_q_sgn_0_ctl(i32 %83, double %81)
  call void @cqrt_and_i1(i32 %trip, i32 %82, i32 %83)
  call void @cqrt_free(i32 %83)
  call void @cqrt_and_i1(i32 %8, i32 %61, i32 %82)
  call void @cqrt_xor_i1(i32 %8, i32 %82)
  call void @cqrt_free(i32 %82)
  %85 = call i32 @cq_template_fmul_f64_hl(i32 %56, double %84)
  %86 = call i32 @cq_template_fmul_f64_hl(i32 %85, double %78)
  %87 = call i32 @cq_template_fadd_f64(i32 %86, i32 %52)
  %88 = add nuw nsw i64 %50, 1
  %89 = icmp eq i64 %88, 8
  %90 = call i32 @cq_template_select_f64(i32 %62, i32 %59, i32 %51)
  %91 = call i32 @cq_template_select_f64(i32 %62, i32 %87, i32 %52)
  %92 = call i32 @cq_template_select_f64(i32 %64, i32 %52, i32 %xcap)
  %93 = call i32 @cq_template_select_f64(i32 %62, i32 %87, i32 %92)
  call void @cqrt_push(i32 %93)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %92)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %90)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %85)
  %94 = bitcast double %78 to i64
  %95 = trunc i64 %94 to i32
  call void @cqrt_push(i32 %95)
  %96 = lshr i64 %94, 32
  %97 = trunc i64 %96 to i32
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %56)
  %98 = bitcast double %84 to i64
  %99 = trunc i64 %98 to i32
  call void @cqrt_push(i32 %99)
  %100 = lshr i64 %98, 32
  %101 = trunc i64 %100 to i32
  call void @cqrt_push(i32 %101)
  br i1 %89, label %48, label %49

102:                                              ; preds = %48
  br label %38

103:                                              ; preds = %38
  %104 = add nsw i32 %1, -1
  %105 = sitofp i32 %104 to double
  br label %117

106:                                              ; preds = %38
  br label %107

107:                                              ; preds = %177, %106
  %108 = phi i32 [ %118, %177 ], [ poison, %106 ]
  %109 = phi i32 [ %119, %177 ], [ poison, %106 ]
  %110 = phi i32 [ %120, %177 ], [ poison, %106 ]
  %ran11 = phi i1 [ true, %177 ], [ false, %106 ]
  %111 = phi i32 [ %39, %106 ], [ %168, %177 ]
  %112 = ptrtoint ptr %6 to i64
  %113 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %8, i32 %5, i64 %112)
  %114 = call i32 @cq_template_fdiv_f64(i32 %111, i32 %113)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %113, i32 %8, i32 %5, i64 %112)
  call void @cqrt_free(i32 %113)
  %115 = ptrtoint ptr %3 to i64
  call void @cqrt_qram_store_f64_hl_controlled(i32 %8, i32 %5, i64 %115, i32 %114)
  %116 = call i32 @cq_template_select_i32_ll(i32 %8, i32 0, i32 1)
  br label %12

117:                                              ; preds = %103
  %118 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %119 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %120 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %122

121:                                              ; preds = %151
  br label %177

122:                                              ; preds = %151, %117
  %from10 = phi i32 [ 0, %151 ], [ 1, %117 ]
  %123 = phi i64 [ 0, %117 ], [ %163, %151 ]
  %124 = phi i32 [ %118, %117 ], [ %165, %151 ]
  %125 = phi i32 [ %119, %117 ], [ %166, %151 ]
  %trip1 = phi i32 [ %8, %117 ], [ %135, %151 ]
  %xcap2 = phi i32 [ %120, %117 ], [ %167, %151 ]
  call void @cqrt_push(i32 %from10)
  %126 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %123
  %127 = ptrtoint ptr %126 to i64
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %8, i32 %128)
  %129 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %128, i32 %5, i64 %127)
  %130 = call i32 @cq_template_fabs_f64(i32 %129)
  %131 = call i32 @cq_template_fcmp_ogt_f64(i32 %124, i32 %130)
  %132 = call i32 @cq_template_select_f64(i32 %131, i32 %124, i32 %130)
  %133 = call i32 @cq_template_fdiv_f64(i32 %130, i32 %132)
  %134 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %133, double 0x3D06849B86A12B9B)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %135)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %134, i32 %8, i32 %136)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %136, i32 %137)
  call void @cqrt_and_i1(i32 %trip1, i32 %136, i32 %135)
  %138 = trunc i64 %123 to i32
  %139 = add i32 %138, 1
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %136)
  call void @cqrt_push(i32 %137)
  call void @cqrt_push(i32 %135)
  call void @cqrt_push(i32 %134)
  call void @cqrt_push(i32 %133)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %132)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %128)
  %140 = trunc i64 %127 to i32
  call void @cqrt_push(i32 %140)
  %141 = lshr i64 %127, 32
  %142 = trunc i64 %141 to i32
  call void @cqrt_push(i32 %142)
  br i1 %35, label %143, label %147

143:                                              ; preds = %122
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %144)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %144)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %144, i32 %145)
  %146 = call fastcc double @__cq_q_jn__00_ctl(i32 %145, i32 %139, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %144, i32 %145)
  call void @cqrt_free(i32 %145)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %144)
  call void @cqrt_xor_i1(i32 %8, i32 %144)
  call void @cqrt_free(i32 %144)
  br label %151

147:                                              ; preds = %122
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %148)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %148)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %148, i32 %149)
  %150 = call fastcc double @__cq_q_yn__00_ctl(i32 %149, i32 %139, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %148, i32 %149)
  call void @cqrt_free(i32 %149)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %148)
  call void @cqrt_xor_i1(i32 %8, i32 %148)
  call void @cqrt_free(i32 %148)
  br label %151

151:                                              ; preds = %143, %147
  %from = phi i32 [ 0, %143 ], [ 1, %147 ]
  %152 = phi double [ %146, %143 ], [ %150, %147 ]
  call void @cqrt_push(i32 %from)
  %153 = trunc nuw nsw i64 %123 to i32
  %154 = uitofp nneg i32 %153 to double
  %155 = tail call double @llvm.fmuladd.f64(double %105, double 5.000000e-01, double %154)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %156)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %156)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %156, i32 %157)
  %158 = call fastcc double @__cq_q_sgn_0_ctl(i32 %157, double %155)
  call void @cqrt_and_i1(i32 %trip1, i32 %156, i32 %157)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %8, i32 %134, i32 %156)
  call void @cqrt_xor_i1(i32 %8, i32 %156)
  call void @cqrt_free(i32 %156)
  %159 = call i32 @cq_template_fmul_f64_hl(i32 %129, double %158)
  %160 = fadd double %152, 1.000000e+00
  %161 = call i32 @cq_template_fmul_f64_hl(i32 %159, double %160)
  %162 = call i32 @cq_template_fadd_f64(i32 %161, i32 %125)
  %163 = add nuw nsw i64 %123, 1
  %164 = icmp eq i64 %163, 8
  %165 = call i32 @cq_template_select_f64(i32 %135, i32 %132, i32 %124)
  %166 = call i32 @cq_template_select_f64(i32 %135, i32 %162, i32 %125)
  %167 = call i32 @cq_template_select_f64(i32 %137, i32 %125, i32 %xcap2)
  %168 = call i32 @cq_template_select_f64(i32 %135, i32 %162, i32 %167)
  call void @cqrt_push(i32 %168)
  call void @cqrt_push(i32 %135)
  call void @cqrt_push(i32 %162)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %137)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %165)
  call void @cqrt_push(i32 %132)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %161)
  call void @cqrt_push(i32 %159)
  %169 = bitcast double %160 to i64
  %170 = trunc i64 %169 to i32
  call void @cqrt_push(i32 %170)
  %171 = lshr i64 %169, 32
  %172 = trunc i64 %171 to i32
  call void @cqrt_push(i32 %172)
  call void @cqrt_push(i32 %129)
  %173 = bitcast double %158 to i64
  %174 = trunc i64 %173 to i32
  call void @cqrt_push(i32 %174)
  %175 = lshr i64 %173, 32
  %176 = trunc i64 %175 to i32
  call void @cqrt_push(i32 %176)
  br i1 %164, label %121, label %122

177:                                              ; preds = %121
  br label %107

178:                                              ; preds = %179
  call void @cqrt_free(i32 %21)
  call void @cqrt_free(i32 %20)
  call void @cqrt_free(i32 %19)
  br label %234

179:                                              ; preds = %200, %201
  %cq.run29 = phi i1 [ %cq.run30, %200 ], [ %cq.run30, %201 ]
  %180 = call i32 @cqrt_pop()
  %181 = zext i32 %180 to i64
  %182 = shl i64 %181, 32
  %183 = or i64 0, %182
  %184 = call i32 @cqrt_pop()
  %185 = zext i32 %184 to i64
  %186 = or i64 %183, %185
  %187 = call i32 @cqrt_pop()
  %188 = call i32 @cqrt_pop()
  %189 = call i32 @cqrt_pop()
  %190 = call i32 @cqrt_pop()
  %191 = call i32 @cqrt_pop()
  %192 = call i32 @cqrt_pop()
  %193 = call i32 @cqrt_pop()
  %194 = call i32 @cqrt_pop()
  %195 = call i32 @cqrt_pop()
  %196 = call i32 @cqrt_pop()
  %197 = call i32 @cqrt_pop()
  %198 = call i32 @cqrt_pop()
  call void @cqrt_and_i1(i32 %198, i32 %197, i32 %196)
  call void @cqrt_free(i32 %196)
  call void @cqrt_and_i1(i32 %198, i32 %197, i32 %195)
  call void @cqrt_xor_i1(i32 %198, i32 %195)
  call void @cqrt_free(i32 %195)
  call void @cqrt_and_i1(i32 %194, i32 %8, i32 %197)
  call void @cqrt_free(i32 %197)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %194, i32 %193, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %194)
  call void @cq_template_fdiv_f64_unc(i32 %193, i32 %192, i32 %191)
  call void @cqrt_free(i32 %193)
  call void @cq_template_select_f64_unc(i32 %191, i32 %190, i32 %189, i32 %192)
  call void @cqrt_free(i32 %191)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %190, i32 %189, i32 %192)
  call void @cqrt_free(i32 %190)
  call void @cq_template_fabs_f64_unc(i32 %192, i32 %188)
  call void @cqrt_free(i32 %192)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %188, i32 %187, i32 %5, i64 %186)
  call void @cqrt_and_i1(i32 %198, i32 %8, i32 %187)
  call void @cqrt_free(i32 %187)
  %199 = call i32 @cqrt_pop()
  switch i32 %199, label %202 [
    i32 1, label %178
  ]

200:                                              ; preds = %202
  br label %179

201:                                              ; preds = %202
  br label %179

202:                                              ; preds = %12, %179
  %cq.run30 = phi i1 [ %cq.run31, %12 ], [ %cq.run29, %179 ]
  %203 = call i32 @cqrt_pop()
  %204 = zext i32 %203 to i64
  %205 = shl i64 %204, 32
  %206 = or i64 0, %205
  %207 = call i32 @cqrt_pop()
  %208 = zext i32 %207 to i64
  %209 = or i64 %206, %208
  %210 = bitcast i64 %209 to double
  %211 = call i32 @cqrt_pop()
  %212 = call i32 @cqrt_pop()
  %213 = zext i32 %212 to i64
  %214 = shl i64 %213, 32
  %215 = or i64 0, %214
  %216 = call i32 @cqrt_pop()
  %217 = zext i32 %216 to i64
  %218 = or i64 %215, %217
  %219 = bitcast i64 %218 to double
  %220 = call i32 @cqrt_pop()
  %221 = call i32 @cqrt_pop()
  %222 = call i32 @cqrt_pop()
  %223 = call i32 @cqrt_pop()
  %224 = call i32 @cqrt_pop()
  %225 = call i32 @cqrt_pop()
  %226 = call i32 @cqrt_pop()
  %227 = call i32 @cqrt_pop()
  %228 = call i32 @cqrt_pop()
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  call void @cq_template_select_f64_unc(i32 %232, i32 %231, i32 %230, i32 %229)
  call void @cqrt_free(i32 %232)
  call void @cq_template_select_f64_unc(i32 %229, i32 %228, i32 %227, i32 %226)
  call void @cqrt_free(i32 %229)
  call void @cq_template_select_f64_unc(i32 %225, i32 %231, i32 %230, i32 %227)
  call void @cqrt_free(i32 %225)
  call void @cq_template_select_f64_unc(i32 %224, i32 %231, i32 %223, i32 %222)
  call void @cqrt_free(i32 %224)
  call void @cq_template_fadd_f64_unc(i32 %230, i32 %221, i32 %227)
  call void @cqrt_free(i32 %230)
  call void @cq_template_fmul_f64_hl_unc(i32 %221, i32 %220, double %219)
  call void @cqrt_free(i32 %221)
  call void @cq_template_fmul_f64_hl_unc(i32 %220, i32 %211, double %210)
  call void @cqrt_free(i32 %220)
  %233 = call i32 @cqrt_pop()
  switch i32 %233, label %201 [
    i32 1, label %200
  ]

234:                                              ; preds = %178, %12
  %cq.run28 = phi i1 [ %cq.run29, %178 ], [ %cq.run31, %12 ]
  br label %23

235:                                              ; preds = %236
  call void @cqrt_free(i32 %18)
  call void @cqrt_free(i32 %17)
  call void @cqrt_free(i32 %16)
  br label %291

236:                                              ; preds = %257, %258
  %cq.run26 = phi i1 [ %cq.run27, %257 ], [ %cq.run27, %258 ]
  %237 = call i32 @cqrt_pop()
  %238 = zext i32 %237 to i64
  %239 = shl i64 %238, 32
  %240 = or i64 0, %239
  %241 = call i32 @cqrt_pop()
  %242 = zext i32 %241 to i64
  %243 = or i64 %240, %242
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
  call void @cqrt_and_i1(i32 %255, i32 %254, i32 %252)
  call void @cqrt_xor_i1(i32 %255, i32 %252)
  call void @cqrt_free(i32 %252)
  call void @cqrt_and_i1(i32 %251, i32 %8, i32 %254)
  call void @cqrt_free(i32 %254)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %251, i32 %250, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %251)
  call void @cq_template_fdiv_f64_unc(i32 %250, i32 %249, i32 %248)
  call void @cqrt_free(i32 %250)
  call void @cq_template_select_f64_unc(i32 %248, i32 %247, i32 %246, i32 %249)
  call void @cqrt_free(i32 %248)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %247, i32 %246, i32 %249)
  call void @cqrt_free(i32 %247)
  call void @cq_template_fabs_f64_unc(i32 %249, i32 %245)
  call void @cqrt_free(i32 %249)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %245, i32 %244, i32 %5, i64 %243)
  call void @cqrt_and_i1(i32 %255, i32 %8, i32 %244)
  call void @cqrt_free(i32 %244)
  %256 = call i32 @cqrt_pop()
  switch i32 %256, label %259 [
    i32 1, label %235
  ]

257:                                              ; preds = %259
  br label %236

258:                                              ; preds = %259
  br label %236

259:                                              ; preds = %23, %236
  %cq.run27 = phi i1 [ %cq.run28, %23 ], [ %cq.run26, %236 ]
  %260 = call i32 @cqrt_pop()
  %261 = zext i32 %260 to i64
  %262 = shl i64 %261, 32
  %263 = or i64 0, %262
  %264 = call i32 @cqrt_pop()
  %265 = zext i32 %264 to i64
  %266 = or i64 %263, %265
  %267 = bitcast i64 %266 to double
  %268 = call i32 @cqrt_pop()
  %269 = call i32 @cqrt_pop()
  %270 = zext i32 %269 to i64
  %271 = shl i64 %270, 32
  %272 = or i64 0, %271
  %273 = call i32 @cqrt_pop()
  %274 = zext i32 %273 to i64
  %275 = or i64 %272, %274
  %276 = bitcast i64 %275 to double
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
  call void @cq_template_select_f64_unc(i32 %289, i32 %288, i32 %287, i32 %286)
  call void @cqrt_free(i32 %289)
  call void @cq_template_select_f64_unc(i32 %286, i32 %285, i32 %284, i32 %283)
  call void @cqrt_free(i32 %286)
  call void @cq_template_select_f64_unc(i32 %282, i32 %288, i32 %287, i32 %284)
  call void @cqrt_free(i32 %282)
  call void @cq_template_select_f64_unc(i32 %281, i32 %288, i32 %280, i32 %279)
  call void @cqrt_free(i32 %281)
  call void @cq_template_fadd_f64_unc(i32 %287, i32 %278, i32 %284)
  call void @cqrt_free(i32 %287)
  call void @cq_template_fmul_f64_hl_unc(i32 %278, i32 %277, double %276)
  call void @cqrt_free(i32 %278)
  call void @cq_template_fmul_f64_hl_unc(i32 %277, i32 %268, double %267)
  call void @cqrt_free(i32 %277)
  %290 = call i32 @cqrt_pop()
  switch i32 %290, label %258 [
    i32 1, label %257
  ]

291:                                              ; preds = %235, %23
  %cq.run25 = phi i1 [ %cq.run26, %235 ], [ %cq.run28, %23 ]
  br label %24
}

declare i32 @cq_template_fptosi_f64_to_i32(i32)

define internal i32 @__cq_q_f_1111_t(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %cq.mints = alloca ptr, align 8
  %6 = load i32, ptr @__cq_k, align 4
  store i32 %4, ptr @__cq_k, align 4
  store ptr null, ptr %cq.mints, align 8
  %7 = call i32 @__cq_mem()
  %8 = call ptr @__cq_alloc(i64 8, i64 8)
  %9 = ptrtoint ptr %8 to i64
  %10 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_qram_store_f64_hl(i32 %7, i64 %9, i32 %10)
  %11 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %0, i32 %11)
  call void @cqrt_ry_f64_qangle(i32 %11, i32 %1)
  %12 = alloca { i32, ptr }, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 0
  store i32 %11, ptr %13, align 4
  %14 = load ptr, ptr %cq.mints, align 8
  %15 = getelementptr inbounds { i32, ptr }, ptr %12, i32 0, i32 1
  store ptr %14, ptr %15, align 8
  store ptr %12, ptr %cq.mints, align 8
  %16 = call i32 @__cq_q_mc_1110(i32 %3, i32 %2, i32 %11, ptr %8)
  %17 = call i32 @cqrt_qram_load_f64_hl(i32 %7, i64 %9)
  %18 = call i32 @cq_template_fmul_f64_hl(i32 %17, double 6.400000e+01)
  %19 = call i32 @cq_template_fptosi_f64_to_i32(i32 %18)
  %20 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %20)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %19, i32 %21)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %19, i32 %18)
  call void @cqrt_free(i32 %19)
  call void @cq_template_fmul_f64_hl_unc(i32 %18, i32 %17, double 6.400000e+01)
  call void @cqrt_free(i32 %18)
  call void @cqrt_qram_load_f64_hl_unc(i32 %17, i32 %7, i64 %9)
  call void @cqrt_free(i32 %17)
  store i32 %6, ptr @__cq_k, align 4
  ret i32 %21
}

declare void @cqrt_copy_f64(i32, i32)

declare void @cqrt_ry_f64_qangle(i32, i32)

define i32 @__cq_q_mc_1110(i32 %0, i32 %1, i32 %2, ptr %3) local_unnamed_addr {
  %5 = call i32 @__cq_mem()
  %6 = call ptr @__cq_alloc(i64 64, i64 16)
  %7 = call ptr @__cq_alloc(i64 8, i64 8)
  %8 = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %2, double 0.000000e+00)
  %9 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -3)
  %10 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 -2)
  %11 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %11)
  %12 = call fastcc i32 @__cq_q_char_a_110_ctl(i32 %11, i32 %1, i32 %2, ptr %7)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %11)
  call void @cqrt_xor_i1(i32 %8, i32 %11)
  call void @cqrt_free(i32 %11)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)
  %14 = ptrtoint ptr %7 to i64
  %15 = call i32 @cqrt_alloc_i1(i1 false)
  %16 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %16)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %16)
  call void @cqrt_and_i1(i32 %13, i32 %16, i32 %15)
  %17 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %15, i32 %5, i64 %14)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %19)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %19)
  call void @cqrt_and_i1(i32 %13, i32 %19, i32 %18)
  call fastcc void @__cq_q_fill_110_ctl(i32 %18, i32 %2, i32 %17, ptr %6)
  call void @cqrt_and_i1(i32 %13, i32 %19, i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %19)
  call void @cqrt_xor_i1(i32 %8, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %17, i32 %15, i32 %5, i64 %14)
  call void @cqrt_and_i1(i32 %13, i32 %16, i32 %15)
  call void @cqrt_free(i32 %15)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %16)
  call void @cqrt_xor_i1(i32 %8, i32 %16)
  call void @cqrt_free(i32 %16)
  %20 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %20, i32 0)
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 1)
  %23 = call i32 @cq_template_sitofp_i32_to_f64(i32 %1)
  br label %24

24:                                               ; preds = %4
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  %27 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %27)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %27)
  call void @cqrt_and_i1(i32 %13, i32 %27, i32 %26)
  call void @cqrt_and_i1(i32 %21, i32 %26, i32 %25)
  %28 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %29 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %30 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %32

31:                                               ; preds = %32
  br label %100

32:                                               ; preds = %32, %24
  %from3 = phi i32 [ 0, %32 ], [ 1, %24 ]
  %33 = phi i64 [ 0, %24 ], [ %83, %32 ]
  %34 = phi i32 [ %28, %24 ], [ %85, %32 ]
  %35 = phi i32 [ %29, %24 ], [ %86, %32 ]
  %trip = phi i32 [ %25, %24 ], [ %48, %32 ]
  %xcap = phi i32 [ %30, %24 ], [ %87, %32 ]
  call void @cqrt_push(i32 %from3)
  %36 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %33
  %37 = ptrtoint ptr %36 to i64
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  %40 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %40)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %40)
  call void @cqrt_and_i1(i32 %13, i32 %40, i32 %39)
  call void @cqrt_and_i1(i32 %21, i32 %39, i32 %38)
  %41 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %38, i32 %41)
  %42 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %41, i32 %5, i64 %37)
  %43 = call i32 @cq_template_fabs_f64(i32 %42)
  %44 = call i32 @cq_template_fcmp_ogt_f64(i32 %34, i32 %43)
  %45 = call i32 @cq_template_select_f64(i32 %44, i32 %34, i32 %43)
  %46 = call i32 @cq_template_fdiv_f64(i32 %43, i32 %45)
  %47 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %46, double 0x3D06849B86A12B9B)
  %48 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %48)
  %49 = call i32 @cqrt_alloc_i1(i1 false)
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %52)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %52)
  call void @cqrt_and_i1(i32 %13, i32 %52, i32 %51)
  call void @cqrt_and_i1(i32 %21, i32 %51, i32 %50)
  call void @cqrt_and_i1(i32 %47, i32 %50, i32 %49)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %49, i32 %53)
  call void @cqrt_and_i1(i32 %trip, i32 %49, i32 %48)
  %54 = trunc nuw nsw i64 %33 to i32
  %55 = call i32 @cqrt_alloc_i1(i1 false)
  %56 = call i32 @cqrt_alloc_i1(i1 false)
  %57 = call i32 @cqrt_alloc_i1(i1 false)
  %58 = call i32 @cqrt_alloc_i1(i1 false)
  %59 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %59)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %59)
  call void @cqrt_and_i1(i32 %13, i32 %59, i32 %58)
  call void @cqrt_and_i1(i32 %21, i32 %58, i32 %57)
  call void @cqrt_xor_i1(i32 %57, i32 %56)
  call void @cqrt_and_i1(i32 %57, i32 %22, i32 %56)
  call void @cqrt_xor_i1(i32 %56, i32 %55)
  call void @cqrt_and_i1(i32 %56, i32 %47, i32 %55)
  %60 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %55, i32 %60)
  %61 = call fastcc double @__cq_q_yn__00_ctl(i32 %60, i32 %54, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %55, i32 %60)
  call void @cqrt_free(i32 %60)
  call void @cqrt_and_i1(i32 %56, i32 %47, i32 %55)
  call void @cqrt_xor_i1(i32 %56, i32 %55)
  call void @cqrt_free(i32 %55)
  call void @cqrt_and_i1(i32 %57, i32 %22, i32 %56)
  call void @cqrt_xor_i1(i32 %57, i32 %56)
  call void @cqrt_free(i32 %56)
  call void @cqrt_and_i1(i32 %21, i32 %58, i32 %57)
  call void @cqrt_free(i32 %57)
  call void @cqrt_and_i1(i32 %13, i32 %59, i32 %58)
  call void @cqrt_free(i32 %58)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %59)
  call void @cqrt_xor_i1(i32 %8, i32 %59)
  call void @cqrt_free(i32 %59)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %66)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %66)
  call void @cqrt_and_i1(i32 %13, i32 %66, i32 %65)
  call void @cqrt_and_i1(i32 %21, i32 %65, i32 %64)
  call void @cqrt_and_i1(i32 %22, i32 %64, i32 %63)
  call void @cqrt_xor_i1(i32 %63, i32 %62)
  call void @cqrt_and_i1(i32 %63, i32 %47, i32 %62)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %62, i32 %67)
  %68 = call fastcc double @__cq_q_jn__00_ctl(i32 %67, i32 %54, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %62, i32 %67)
  call void @cqrt_free(i32 %67)
  call void @cqrt_and_i1(i32 %63, i32 %47, i32 %62)
  call void @cqrt_xor_i1(i32 %63, i32 %62)
  call void @cqrt_free(i32 %62)
  call void @cqrt_and_i1(i32 %22, i32 %64, i32 %63)
  call void @cqrt_free(i32 %63)
  call void @cqrt_and_i1(i32 %21, i32 %65, i32 %64)
  call void @cqrt_free(i32 %64)
  call void @cqrt_and_i1(i32 %13, i32 %66, i32 %65)
  call void @cqrt_free(i32 %65)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %66)
  call void @cqrt_xor_i1(i32 %8, i32 %66)
  call void @cqrt_free(i32 %66)
  %69 = call i32 @cq_template_select_f64_ll(i32 %22, double %68, double %61)
  %70 = trunc nuw nsw i64 %33 to i32
  %71 = uitofp nneg i32 %70 to double
  %72 = call i32 @cq_template_fmul_f64_hl(i32 %23, double 5.000000e-01)
  %73 = call i32 @cq_template_fadd_f64_hl(i32 %72, double %71)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  %76 = call i32 @cqrt_alloc_i1(i1 false)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %77)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %77)
  call void @cqrt_and_i1(i32 %13, i32 %77, i32 %76)
  call void @cqrt_and_i1(i32 %21, i32 %76, i32 %75)
  call void @cqrt_xor_i1(i32 %75, i32 %74)
  call void @cqrt_and_i1(i32 %75, i32 %47, i32 %74)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %74, i32 %78)
  %79 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %78, i32 %73)
  call void @cqrt_and_i1(i32 %trip, i32 %74, i32 %78)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %75, i32 %47, i32 %74)
  call void @cqrt_xor_i1(i32 %75, i32 %74)
  call void @cqrt_free(i32 %74)
  call void @cqrt_and_i1(i32 %21, i32 %76, i32 %75)
  call void @cqrt_free(i32 %75)
  call void @cqrt_and_i1(i32 %13, i32 %77, i32 %76)
  call void @cqrt_free(i32 %76)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %77)
  call void @cqrt_xor_i1(i32 %8, i32 %77)
  call void @cqrt_free(i32 %77)
  call void @cq_template_fadd_f64_hl_unc(i32 %73, i32 %72, double %71)
  call void @cqrt_free(i32 %73)
  call void @cq_template_fmul_f64_hl_unc(i32 %72, i32 %23, double 5.000000e-01)
  call void @cqrt_free(i32 %72)
  %80 = call i32 @cq_template_fmul_f64(i32 %42, i32 %79)
  %81 = call i32 @cq_template_fmul_f64(i32 %80, i32 %69)
  %82 = call i32 @cq_template_fadd_f64(i32 %81, i32 %35)
  %83 = add nuw nsw i64 %33, 1
  %84 = icmp eq i64 %83, 8
  %85 = call i32 @cq_template_select_f64(i32 %48, i32 %45, i32 %34)
  %86 = call i32 @cq_template_select_f64(i32 %48, i32 %82, i32 %35)
  %87 = call i32 @cq_template_select_f64(i32 %53, i32 %35, i32 %xcap)
  %88 = call i32 @cq_template_select_f64(i32 %48, i32 %82, i32 %87)
  call void @cqrt_push(i32 %88)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %82)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %86)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %45)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %81)
  call void @cqrt_push(i32 %80)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %79)
  %89 = bitcast double %68 to i64
  %90 = trunc i64 %89 to i32
  call void @cqrt_push(i32 %90)
  %91 = lshr i64 %89, 32
  %92 = trunc i64 %91 to i32
  call void @cqrt_push(i32 %92)
  %93 = bitcast double %61 to i64
  %94 = trunc i64 %93 to i32
  call void @cqrt_push(i32 %94)
  %95 = lshr i64 %93, 32
  %96 = trunc i64 %95 to i32
  call void @cqrt_push(i32 %96)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %44)
  call void @cqrt_push(i32 %41)
  %97 = trunc i64 %37 to i32
  call void @cqrt_push(i32 %97)
  %98 = lshr i64 %37, 32
  %99 = trunc i64 %98 to i32
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %38)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %40)
  br i1 %84, label %31, label %32

100:                                              ; preds = %31
  %101 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)
  %102 = call i32 @cq_template_sitofp_i32_to_f64(i32 %101)
  br label %103

103:                                              ; preds = %100
  %104 = call i32 @cqrt_alloc_i1(i1 false)
  %105 = call i32 @cqrt_alloc_i1(i1 false)
  %106 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %106)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %106)
  call void @cqrt_and_i1(i32 %13, i32 %106, i32 %105)
  call void @cqrt_xor_i1(i32 %105, i32 %104)
  call void @cqrt_and_i1(i32 %105, i32 %21, i32 %104)
  %107 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %108 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %110

109:                                              ; preds = %110
  br label %180

110:                                              ; preds = %110, %103
  %from = phi i32 [ 0, %110 ], [ 1, %103 ]
  %111 = phi i64 [ 0, %103 ], [ %163, %110 ]
  %112 = phi i32 [ %107, %103 ], [ %165, %110 ]
  %113 = phi i32 [ %108, %103 ], [ %166, %110 ]
  %trip1 = phi i32 [ %104, %103 ], [ %126, %110 ]
  %xcap2 = phi i32 [ %88, %103 ], [ %167, %110 ]
  call void @cqrt_push(i32 %from)
  %114 = getelementptr inbounds [8 x double], ptr %6, i64 0, i64 %111
  %115 = ptrtoint ptr %114 to i64
  %116 = call i32 @cqrt_alloc_i1(i1 false)
  %117 = call i32 @cqrt_alloc_i1(i1 false)
  %118 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %118)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %118)
  call void @cqrt_and_i1(i32 %13, i32 %118, i32 %117)
  call void @cqrt_xor_i1(i32 %117, i32 %116)
  call void @cqrt_and_i1(i32 %117, i32 %21, i32 %116)
  %119 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %116, i32 %119)
  %120 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %119, i32 %5, i64 %115)
  %121 = call i32 @cq_template_fabs_f64(i32 %120)
  %122 = call i32 @cq_template_fcmp_ogt_f64(i32 %112, i32 %121)
  %123 = call i32 @cq_template_select_f64(i32 %122, i32 %112, i32 %121)
  %124 = call i32 @cq_template_fdiv_f64(i32 %121, i32 %123)
  %125 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %124, double 0x3D06849B86A12B9B)
  %126 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %126)
  %127 = call i32 @cqrt_alloc_i1(i1 false)
  %128 = call i32 @cqrt_alloc_i1(i1 false)
  %129 = call i32 @cqrt_alloc_i1(i1 false)
  %130 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %130)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %130)
  call void @cqrt_and_i1(i32 %13, i32 %130, i32 %129)
  call void @cqrt_xor_i1(i32 %129, i32 %128)
  call void @cqrt_and_i1(i32 %129, i32 %21, i32 %128)
  call void @cqrt_and_i1(i32 %125, i32 %128, i32 %127)
  %131 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %127, i32 %131)
  call void @cqrt_and_i1(i32 %trip1, i32 %127, i32 %126)
  %132 = trunc i64 %111 to i32
  %133 = add i32 %132, 1
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %138)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %138)
  call void @cqrt_and_i1(i32 %13, i32 %138, i32 %137)
  call void @cqrt_xor_i1(i32 %137, i32 %136)
  call void @cqrt_and_i1(i32 %137, i32 %21, i32 %136)
  call void @cqrt_xor_i1(i32 %136, i32 %135)
  call void @cqrt_and_i1(i32 %136, i32 %125, i32 %135)
  call void @cqrt_xor_i1(i32 %135, i32 %134)
  call void @cqrt_and_i1(i32 %135, i32 %22, i32 %134)
  %139 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %134, i32 %139)
  %140 = call fastcc double @__cq_q_yn__00_ctl(i32 %139, i32 %133, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %134, i32 %139)
  call void @cqrt_free(i32 %139)
  call void @cqrt_and_i1(i32 %135, i32 %22, i32 %134)
  call void @cqrt_xor_i1(i32 %135, i32 %134)
  call void @cqrt_free(i32 %134)
  call void @cqrt_and_i1(i32 %136, i32 %125, i32 %135)
  call void @cqrt_xor_i1(i32 %136, i32 %135)
  call void @cqrt_free(i32 %135)
  call void @cqrt_and_i1(i32 %137, i32 %21, i32 %136)
  call void @cqrt_xor_i1(i32 %137, i32 %136)
  call void @cqrt_free(i32 %136)
  call void @cqrt_and_i1(i32 %13, i32 %138, i32 %137)
  call void @cqrt_free(i32 %137)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %138)
  call void @cqrt_xor_i1(i32 %8, i32 %138)
  call void @cqrt_free(i32 %138)
  %141 = call i32 @cqrt_alloc_i1(i1 false)
  %142 = call i32 @cqrt_alloc_i1(i1 false)
  %143 = call i32 @cqrt_alloc_i1(i1 false)
  %144 = call i32 @cqrt_alloc_i1(i1 false)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %145)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %145)
  call void @cqrt_and_i1(i32 %13, i32 %145, i32 %144)
  call void @cqrt_xor_i1(i32 %144, i32 %143)
  call void @cqrt_and_i1(i32 %144, i32 %21, i32 %143)
  call void @cqrt_xor_i1(i32 %143, i32 %142)
  call void @cqrt_and_i1(i32 %143, i32 %125, i32 %142)
  call void @cqrt_and_i1(i32 %22, i32 %142, i32 %141)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %141, i32 %146)
  %147 = call fastcc double @__cq_q_jn__00_ctl(i32 %146, i32 %133, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %141, i32 %146)
  call void @cqrt_free(i32 %146)
  call void @cqrt_and_i1(i32 %22, i32 %142, i32 %141)
  call void @cqrt_free(i32 %141)
  call void @cqrt_and_i1(i32 %143, i32 %125, i32 %142)
  call void @cqrt_xor_i1(i32 %143, i32 %142)
  call void @cqrt_free(i32 %142)
  call void @cqrt_and_i1(i32 %144, i32 %21, i32 %143)
  call void @cqrt_xor_i1(i32 %144, i32 %143)
  call void @cqrt_free(i32 %143)
  call void @cqrt_and_i1(i32 %13, i32 %145, i32 %144)
  call void @cqrt_free(i32 %144)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %145)
  call void @cqrt_xor_i1(i32 %8, i32 %145)
  call void @cqrt_free(i32 %145)
  %148 = call i32 @cq_template_select_f64_ll(i32 %22, double %147, double %140)
  %149 = trunc nuw nsw i64 %111 to i32
  %150 = uitofp nneg i32 %149 to double
  %151 = call i32 @cq_template_fmul_f64_hl(i32 %102, double 5.000000e-01)
  %152 = call i32 @cq_template_fadd_f64_hl(i32 %151, double %150)
  %153 = call i32 @cqrt_alloc_i1(i1 false)
  %154 = call i32 @cqrt_alloc_i1(i1 false)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %156)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %156)
  call void @cqrt_and_i1(i32 %13, i32 %156, i32 %155)
  call void @cqrt_xor_i1(i32 %155, i32 %154)
  call void @cqrt_and_i1(i32 %155, i32 %21, i32 %154)
  call void @cqrt_xor_i1(i32 %154, i32 %153)
  call void @cqrt_and_i1(i32 %154, i32 %125, i32 %153)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %153, i32 %157)
  %158 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %157, i32 %152)
  call void @cqrt_and_i1(i32 %trip1, i32 %153, i32 %157)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %154, i32 %125, i32 %153)
  call void @cqrt_xor_i1(i32 %154, i32 %153)
  call void @cqrt_free(i32 %153)
  call void @cqrt_and_i1(i32 %155, i32 %21, i32 %154)
  call void @cqrt_xor_i1(i32 %155, i32 %154)
  call void @cqrt_free(i32 %154)
  call void @cqrt_and_i1(i32 %13, i32 %156, i32 %155)
  call void @cqrt_free(i32 %155)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %156)
  call void @cqrt_xor_i1(i32 %8, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cq_template_fadd_f64_hl_unc(i32 %152, i32 %151, double %150)
  call void @cqrt_free(i32 %152)
  call void @cq_template_fmul_f64_hl_unc(i32 %151, i32 %102, double 5.000000e-01)
  call void @cqrt_free(i32 %151)
  %159 = call i32 @cq_template_fmul_f64(i32 %120, i32 %158)
  %160 = call i32 @cq_template_fadd_f64_hl(i32 %148, double 1.000000e+00)
  %161 = call i32 @cq_template_fmul_f64(i32 %159, i32 %160)
  %162 = call i32 @cq_template_fadd_f64(i32 %161, i32 %113)
  %163 = add nuw nsw i64 %111, 1
  %164 = icmp eq i64 %163, 8
  %165 = call i32 @cq_template_select_f64(i32 %126, i32 %123, i32 %112)
  %166 = call i32 @cq_template_select_f64(i32 %126, i32 %162, i32 %113)
  %167 = call i32 @cq_template_select_f64(i32 %131, i32 %113, i32 %xcap2)
  %168 = call i32 @cq_template_select_f64(i32 %126, i32 %162, i32 %167)
  call void @cqrt_push(i32 %168)
  call void @cqrt_push(i32 %126)
  call void @cqrt_push(i32 %162)
  call void @cqrt_push(i32 %167)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %166)
  call void @cqrt_push(i32 %165)
  call void @cqrt_push(i32 %123)
  call void @cqrt_push(i32 %112)
  call void @cqrt_push(i32 %161)
  call void @cqrt_push(i32 %159)
  call void @cqrt_push(i32 %160)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %120)
  call void @cqrt_push(i32 %158)
  %169 = bitcast double %147 to i64
  %170 = trunc i64 %169 to i32
  call void @cqrt_push(i32 %170)
  %171 = lshr i64 %169, 32
  %172 = trunc i64 %171 to i32
  call void @cqrt_push(i32 %172)
  %173 = bitcast double %140 to i64
  %174 = trunc i64 %173 to i32
  call void @cqrt_push(i32 %174)
  %175 = lshr i64 %173, 32
  %176 = trunc i64 %175 to i32
  call void @cqrt_push(i32 %176)
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %127)
  call void @cqrt_push(i32 %125)
  call void @cqrt_push(i32 %128)
  call void @cqrt_push(i32 %129)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %124)
  call void @cqrt_push(i32 %121)
  call void @cqrt_push(i32 %122)
  call void @cqrt_push(i32 %119)
  %177 = trunc i64 %115 to i32
  call void @cqrt_push(i32 %177)
  %178 = lshr i64 %115, 32
  %179 = trunc i64 %178 to i32
  call void @cqrt_push(i32 %179)
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %117)
  call void @cqrt_push(i32 %118)
  br i1 %164, label %109, label %110

180:                                              ; preds = %109
  %181 = call i32 @cqrt_alloc_i1(i1 false)
  %182 = call i32 @cqrt_alloc_i1(i1 false)
  %183 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %183)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %183)
  call void @cqrt_and_i1(i32 %13, i32 %183, i32 %182)
  call void @cqrt_xor_i1(i32 %182, i32 %181)
  call void @cqrt_and_i1(i32 %182, i32 %21, i32 %181)
  %184 = call i32 @cq_template_select_f64(i32 %181, i32 %162, i32 %168)
  %185 = ptrtoint ptr %6 to i64
  %186 = call i32 @cqrt_alloc_i1(i1 false)
  %187 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %187)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %187)
  call void @cqrt_and_i1(i32 %13, i32 %187, i32 %186)
  %188 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %186, i32 %5, i64 %185)
  %189 = call i32 @cq_template_fdiv_f64(i32 %184, i32 %188)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %188, i32 %186, i32 %5, i64 %185)
  call void @cqrt_free(i32 %188)
  call void @cqrt_and_i1(i32 %13, i32 %187, i32 %186)
  call void @cqrt_free(i32 %186)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %187)
  call void @cqrt_xor_i1(i32 %8, i32 %187)
  call void @cqrt_free(i32 %187)
  call void @cq_template_select_f64_unc(i32 %184, i32 %181, i32 %162, i32 %168)
  call void @cqrt_free(i32 %184)
  call void @cqrt_and_i1(i32 %182, i32 %21, i32 %181)
  call void @cqrt_xor_i1(i32 %182, i32 %181)
  call void @cqrt_free(i32 %181)
  call void @cqrt_and_i1(i32 %13, i32 %183, i32 %182)
  call void @cqrt_free(i32 %182)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %183)
  call void @cqrt_xor_i1(i32 %8, i32 %183)
  call void @cqrt_free(i32 %183)
  br label %200

190:                                              ; preds = %199
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %102, i32 %101)
  call void @cqrt_free(i32 %102)
  call void @cq_template_add_i32_hl_unc(i32 %101, i32 %1, i32 -1)
  call void @cqrt_free(i32 %101)
  br label %256

191:                                              ; preds = %255
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %23, i32 %1)
  call void @cqrt_free(i32 %23)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %0, i32 1)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %20, i32 0)
  call void @cqrt_free(i32 %21)
  call void @cq_template_and_i32_hl_unc(i32 %20, i32 %1, i32 1)
  call void @cqrt_free(i32 %20)
  %192 = ptrtoint ptr %3 to i64
  %193 = call i32 @cqrt_alloc_i1(i1 false)
  %194 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %8, i32 %194)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %194)
  call void @cqrt_and_i1(i32 %13, i32 %194, i32 %193)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %194)
  call void @cqrt_xor_i1(i32 %8, i32 %194)
  call void @cqrt_free(i32 %194)
  call void @cqrt_qram_store_f64_hl_controlled(i32 %193, i32 %5, i64 %192, i32 %189)
  %195 = call i32 @cq_template_select_i32_lh(i32 %13, i32 0, i32 %12)
  %196 = call i32 @cq_template_select_i32_lh(i32 %10, i32 2, i32 %195)
  %197 = call i32 @cq_template_select_i32_hl(i32 %8, i32 %196, i32 1)
  %198 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %197, i32 %198)
  call void @cq_template_select_i32_hl_unc(i32 %197, i32 %8, i32 %196, i32 1)
  call void @cqrt_free(i32 %197)
  call void @cq_template_select_i32_lh_unc(i32 %196, i32 %10, i32 2, i32 %195)
  call void @cqrt_free(i32 %196)
  call void @cq_template_select_i32_lh_unc(i32 %195, i32 %13, i32 0, i32 %12)
  call void @cqrt_free(i32 %195)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)
  call void @cqrt_free(i32 %13)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %10, i32 %9, i32 -2)
  call void @cqrt_free(i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %0, i32 -3)
  call void @cqrt_free(i32 %9)
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %8, i32 %2, double 0.000000e+00)
  call void @cqrt_free(i32 %8)
  ret i32 %198

199:                                              ; preds = %200
  call void @cqrt_free(i32 %108)
  call void @cqrt_free(i32 %107)
  call void @cqrt_and_i1(i32 %105, i32 %21, i32 %104)
  call void @cqrt_xor_i1(i32 %105, i32 %104)
  call void @cqrt_free(i32 %104)
  call void @cqrt_and_i1(i32 %13, i32 %106, i32 %105)
  call void @cqrt_free(i32 %105)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %106)
  call void @cqrt_xor_i1(i32 %8, i32 %106)
  call void @cqrt_free(i32 %106)
  br label %190

200:                                              ; preds = %180, %200
  %201 = call i32 @cqrt_pop()
  %202 = call i32 @cqrt_pop()
  %203 = call i32 @cqrt_pop()
  %204 = call i32 @cqrt_pop()
  %205 = zext i32 %204 to i64
  %206 = shl i64 %205, 32
  %207 = or i64 0, %206
  %208 = call i32 @cqrt_pop()
  %209 = zext i32 %208 to i64
  %210 = or i64 %207, %209
  %211 = call i32 @cqrt_pop()
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
  %222 = zext i32 %221 to i64
  %223 = shl i64 %222, 32
  %224 = or i64 0, %223
  %225 = call i32 @cqrt_pop()
  %226 = zext i32 %225 to i64
  %227 = or i64 %224, %226
  %228 = bitcast i64 %227 to double
  %229 = call i32 @cqrt_pop()
  %230 = zext i32 %229 to i64
  %231 = shl i64 %230, 32
  %232 = or i64 0, %231
  %233 = call i32 @cqrt_pop()
  %234 = zext i32 %233 to i64
  %235 = or i64 %232, %234
  %236 = bitcast i64 %235 to double
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
  %247 = call i32 @cqrt_pop()
  %248 = call i32 @cqrt_pop()
  %249 = call i32 @cqrt_pop()
  %250 = call i32 @cqrt_pop()
  %251 = call i32 @cqrt_pop()
  %252 = call i32 @cqrt_pop()
  %253 = call i32 @cqrt_pop()
  call void @cq_template_select_f64_unc(i32 %253, i32 %252, i32 %251, i32 %250)
  call void @cqrt_free(i32 %253)
  call void @cq_template_select_f64_unc(i32 %250, i32 %249, i32 %248, i32 %247)
  call void @cqrt_free(i32 %250)
  call void @cq_template_select_f64_unc(i32 %246, i32 %252, i32 %251, i32 %248)
  call void @cqrt_free(i32 %246)
  call void @cq_template_select_f64_unc(i32 %245, i32 %252, i32 %244, i32 %243)
  call void @cqrt_free(i32 %245)
  call void @cq_template_fadd_f64_unc(i32 %251, i32 %242, i32 %248)
  call void @cqrt_free(i32 %251)
  call void @cq_template_fmul_f64_unc(i32 %242, i32 %241, i32 %240)
  call void @cqrt_free(i32 %242)
  call void @cq_template_fadd_f64_hl_unc(i32 %240, i32 %239, double 1.000000e+00)
  call void @cqrt_free(i32 %240)
  call void @cq_template_fmul_f64_unc(i32 %241, i32 %238, i32 %237)
  call void @cqrt_free(i32 %241)
  call void @cq_template_select_f64_ll_unc(i32 %239, i32 %22, double %236, double %228)
  call void @cqrt_free(i32 %239)
  call void @cqrt_and_i1(i32 %220, i32 %219, i32 %249)
  call void @cqrt_free(i32 %249)
  call void @cqrt_and_i1(i32 %220, i32 %219, i32 %252)
  call void @cqrt_xor_i1(i32 %220, i32 %252)
  call void @cqrt_free(i32 %252)
  call void @cqrt_and_i1(i32 %218, i32 %217, i32 %219)
  call void @cqrt_free(i32 %219)
  call void @cqrt_and_i1(i32 %216, i32 %21, i32 %217)
  call void @cqrt_xor_i1(i32 %216, i32 %217)
  call void @cqrt_free(i32 %217)
  call void @cqrt_and_i1(i32 %13, i32 %215, i32 %216)
  call void @cqrt_free(i32 %216)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %215)
  call void @cqrt_xor_i1(i32 %8, i32 %215)
  call void @cqrt_free(i32 %215)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %218, i32 %214, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %218)
  call void @cq_template_fdiv_f64_unc(i32 %214, i32 %213, i32 %244)
  call void @cqrt_free(i32 %214)
  call void @cq_template_select_f64_unc(i32 %244, i32 %212, i32 %243, i32 %213)
  call void @cqrt_free(i32 %244)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %212, i32 %243, i32 %213)
  call void @cqrt_free(i32 %212)
  call void @cq_template_fabs_f64_unc(i32 %213, i32 %238)
  call void @cqrt_free(i32 %213)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %238, i32 %211, i32 %5, i64 %210)
  call void @cqrt_and_i1(i32 %220, i32 %203, i32 %211)
  call void @cqrt_free(i32 %211)
  call void @cqrt_and_i1(i32 %202, i32 %21, i32 %203)
  call void @cqrt_xor_i1(i32 %202, i32 %203)
  call void @cqrt_free(i32 %203)
  call void @cqrt_and_i1(i32 %13, i32 %201, i32 %202)
  call void @cqrt_free(i32 %202)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %201)
  call void @cqrt_xor_i1(i32 %8, i32 %201)
  call void @cqrt_free(i32 %201)
  %254 = call i32 @cqrt_pop()
  switch i32 %254, label %200 [
    i32 1, label %199
  ]

255:                                              ; preds = %256
  call void @cqrt_free(i32 %30)
  call void @cqrt_free(i32 %29)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %21, i32 %26, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %13, i32 %27, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %27)
  call void @cqrt_xor_i1(i32 %8, i32 %27)
  call void @cqrt_free(i32 %27)
  br label %191

256:                                              ; preds = %190, %256
  %257 = call i32 @cqrt_pop()
  %258 = call i32 @cqrt_pop()
  %259 = call i32 @cqrt_pop()
  %260 = call i32 @cqrt_pop()
  %261 = zext i32 %260 to i64
  %262 = shl i64 %261, 32
  %263 = or i64 0, %262
  %264 = call i32 @cqrt_pop()
  %265 = zext i32 %264 to i64
  %266 = or i64 %263, %265
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
  %278 = zext i32 %277 to i64
  %279 = shl i64 %278, 32
  %280 = or i64 0, %279
  %281 = call i32 @cqrt_pop()
  %282 = zext i32 %281 to i64
  %283 = or i64 %280, %282
  %284 = bitcast i64 %283 to double
  %285 = call i32 @cqrt_pop()
  %286 = zext i32 %285 to i64
  %287 = shl i64 %286, 32
  %288 = or i64 0, %287
  %289 = call i32 @cqrt_pop()
  %290 = zext i32 %289 to i64
  %291 = or i64 %288, %290
  %292 = bitcast i64 %291 to double
  %293 = call i32 @cqrt_pop()
  %294 = call i32 @cqrt_pop()
  %295 = call i32 @cqrt_pop()
  %296 = call i32 @cqrt_pop()
  %297 = call i32 @cqrt_pop()
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
  call void @cq_template_select_f64_unc(i32 %308, i32 %307, i32 %306, i32 %305)
  call void @cqrt_free(i32 %308)
  call void @cq_template_select_f64_unc(i32 %305, i32 %304, i32 %303, i32 %302)
  call void @cqrt_free(i32 %305)
  call void @cq_template_select_f64_unc(i32 %301, i32 %307, i32 %306, i32 %303)
  call void @cqrt_free(i32 %301)
  call void @cq_template_select_f64_unc(i32 %300, i32 %307, i32 %299, i32 %298)
  call void @cqrt_free(i32 %300)
  call void @cq_template_fadd_f64_unc(i32 %306, i32 %297, i32 %303)
  call void @cqrt_free(i32 %306)
  call void @cq_template_fmul_f64_unc(i32 %297, i32 %296, i32 %295)
  call void @cqrt_free(i32 %297)
  call void @cq_template_fmul_f64_unc(i32 %296, i32 %294, i32 %293)
  call void @cqrt_free(i32 %296)
  call void @cq_template_select_f64_ll_unc(i32 %295, i32 %22, double %292, double %284)
  call void @cqrt_free(i32 %295)
  call void @cqrt_and_i1(i32 %276, i32 %275, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cqrt_and_i1(i32 %276, i32 %275, i32 %307)
  call void @cqrt_xor_i1(i32 %276, i32 %307)
  call void @cqrt_free(i32 %307)
  call void @cqrt_and_i1(i32 %274, i32 %273, i32 %275)
  call void @cqrt_free(i32 %275)
  call void @cqrt_and_i1(i32 %21, i32 %272, i32 %273)
  call void @cqrt_free(i32 %273)
  call void @cqrt_and_i1(i32 %13, i32 %271, i32 %272)
  call void @cqrt_free(i32 %272)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %271)
  call void @cqrt_xor_i1(i32 %8, i32 %271)
  call void @cqrt_free(i32 %271)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %274, i32 %270, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %274)
  call void @cq_template_fdiv_f64_unc(i32 %270, i32 %269, i32 %299)
  call void @cqrt_free(i32 %270)
  call void @cq_template_select_f64_unc(i32 %299, i32 %268, i32 %298, i32 %269)
  call void @cqrt_free(i32 %299)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %268, i32 %298, i32 %269)
  call void @cqrt_free(i32 %268)
  call void @cq_template_fabs_f64_unc(i32 %269, i32 %294)
  call void @cqrt_free(i32 %269)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %294, i32 %267, i32 %5, i64 %266)
  call void @cqrt_and_i1(i32 %276, i32 %259, i32 %267)
  call void @cqrt_free(i32 %267)
  call void @cqrt_and_i1(i32 %21, i32 %258, i32 %259)
  call void @cqrt_free(i32 %259)
  call void @cqrt_and_i1(i32 %13, i32 %257, i32 %258)
  call void @cqrt_free(i32 %258)
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %257)
  call void @cqrt_xor_i1(i32 %8, i32 %257)
  call void @cqrt_free(i32 %257)
  %309 = call i32 @cqrt_pop()
  switch i32 %309, label %256 [
    i32 1, label %255
  ]
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

declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)

define internal i32 @__cq_q_f_1111_t_ctl(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  %8 = load i32, ptr @__cq_act_f, align 4
  %9 = add i32 %8, 1
  store i32 %9, ptr @__cq_act_f, align 4
  %10 = icmp ult i32 %8, %5
  br i1 %10, label %11, label %29

11:                                               ; preds = %6
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %12 = call i32 @__cq_mem()
  %13 = call ptr @__cq_alloc(i64 8, i64 8)
  %14 = ptrtoint ptr %13 to i64
  %15 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_qram_store_f64_hl_controlled(i32 %0, i32 %12, i64 %14, i32 %15)
  %16 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  call void @cqrt_copy_f64(i32 %1, i32 %16)
  call void @cqrt_ry_f64_qangle_controlled(i32 %0, i32 %16, i32 %2)
  %17 = alloca { i32, ptr }, align 8
  %18 = getelementptr inbounds { i32, ptr }, ptr %17, i32 0, i32 0
  store i32 %16, ptr %18, align 4
  %19 = load ptr, ptr %cq.mints, align 8
  %20 = getelementptr inbounds { i32, ptr }, ptr %17, i32 0, i32 1
  store ptr %19, ptr %20, align 8
  store ptr %17, ptr %cq.mints, align 8
  %21 = call i32 @__cq_q_mc_1110_ctl(i32 %0, i32 %4, i32 %3, i32 %16, ptr %13)
  %22 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %0, i32 %12, i64 %14)
  %23 = call i32 @cq_template_fmul_f64_hl(i32 %22, double 6.400000e+01)
  %24 = call i32 @cq_template_fptosi_f64_to_i32(i32 %23)
  %25 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %25)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %24, i32 %26)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %24, i32 %23)
  call void @cqrt_free(i32 %24)
  call void @cq_template_fmul_f64_hl_unc(i32 %23, i32 %22, double 6.400000e+01)
  call void @cqrt_free(i32 %23)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %22, i32 %0, i32 %12, i64 %14)
  call void @cqrt_free(i32 %22)
  %27 = load i32, ptr @__cq_act_f, align 4
  %28 = add i32 %27, -1
  store i32 %28, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %26

29:                                               ; preds = %6
  %30 = call i32 @cqrt_alloc_i32(i32 0)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %31)
  call void @cqrt_push(i32 0)
  %32 = load i32, ptr @__cq_act_f, align 4
  %33 = add i32 %32, -1
  store i32 %33, ptr @__cq_act_f, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret i32 %30
}

declare void @cqrt_qram_store_f64_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_f64_qangle_controlled(i32, i32, i32)

define i32 @__cq_q_mc_1110_ctl(i32 %0, i32 %1, i32 %2, i32 %3, ptr %4) local_unnamed_addr {
  %6 = load i32, ptr @__cq_k, align 4
  %7 = icmp eq i32 %6, -1
  %8 = select i1 %7, i32 4, i32 %6
  %9 = load i32, ptr @__cq_act_mc, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_mc, align 4
  %11 = icmp ult i32 %9, %8
  br i1 %11, label %12, label %342

12:                                               ; preds = %5
  %13 = call i32 @__cq_mem()
  %14 = call ptr @__cq_alloc(i64 64, i64 16)
  %15 = call ptr @__cq_alloc(i64 8, i64 8)
  %16 = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %3, double 0.000000e+00)
  %17 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -3)
  %18 = call i32 @cq_template_icmp_ult_i32_hl(i32 %17, i32 -2)
  %19 = call i32 @cqrt_alloc_i1(i1 false)
  %20 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %20)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  %21 = call fastcc i32 @__cq_q_char_a_110_ctl(i32 %19, i32 %2, i32 %3, ptr %15)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %19)
  call void @cqrt_free(i32 %19)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %20)
  call void @cqrt_xor_i1(i32 %16, i32 %20)
  call void @cqrt_free(i32 %20)
  %22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %21, i32 0)
  %23 = ptrtoint ptr %15 to i64
  %24 = call i32 @cqrt_alloc_i1(i1 false)
  %25 = call i32 @cqrt_alloc_i1(i1 false)
  %26 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %26)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %26)
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %25)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  %27 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %24, i32 %13, i64 %23)
  %28 = call i32 @cqrt_alloc_i1(i1 false)
  %29 = call i32 @cqrt_alloc_i1(i1 false)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %30)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %30)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %29)
  call void @cqrt_and_i1(i32 %0, i32 %29, i32 %28)
  call fastcc void @__cq_q_fill_110_ctl(i32 %28, i32 %3, i32 %27, ptr %14)
  call void @cqrt_and_i1(i32 %0, i32 %29, i32 %28)
  call void @cqrt_free(i32 %28)
  call void @cqrt_and_i1(i32 %22, i32 %30, i32 %29)
  call void @cqrt_free(i32 %29)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %30)
  call void @cqrt_xor_i1(i32 %16, i32 %30)
  call void @cqrt_free(i32 %30)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %27, i32 %24, i32 %13, i64 %23)
  call void @cqrt_and_i1(i32 %0, i32 %25, i32 %24)
  call void @cqrt_free(i32 %24)
  call void @cqrt_and_i1(i32 %22, i32 %26, i32 %25)
  call void @cqrt_free(i32 %25)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %26)
  call void @cqrt_xor_i1(i32 %16, i32 %26)
  call void @cqrt_free(i32 %26)
  %31 = call i32 @cq_template_and_i32_hl(i32 %2, i32 1)
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %31, i32 0)
  %33 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)
  %34 = call i32 @cq_template_sitofp_i32_to_f64(i32 %2)
  br label %35

35:                                               ; preds = %12
  %36 = call i32 @cqrt_alloc_i1(i1 false)
  %37 = call i32 @cqrt_alloc_i1(i1 false)
  %38 = call i32 @cqrt_alloc_i1(i1 false)
  %39 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %39)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %39)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %38)
  call void @cqrt_and_i1(i32 %32, i32 %38, i32 %37)
  call void @cqrt_and_i1(i32 %0, i32 %37, i32 %36)
  %40 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %41 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %42 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %44

43:                                               ; preds = %44
  br label %117

44:                                               ; preds = %44, %35
  %from3 = phi i32 [ 0, %44 ], [ 1, %35 ]
  %45 = phi i64 [ 0, %35 ], [ %100, %44 ]
  %46 = phi i32 [ %40, %35 ], [ %102, %44 ]
  %47 = phi i32 [ %41, %35 ], [ %103, %44 ]
  %trip = phi i32 [ %36, %35 ], [ %61, %44 ]
  %xcap = phi i32 [ %42, %35 ], [ %104, %44 ]
  call void @cqrt_push(i32 %from3)
  %48 = getelementptr inbounds [8 x double], ptr %14, i64 0, i64 %45
  %49 = ptrtoint ptr %48 to i64
  %50 = call i32 @cqrt_alloc_i1(i1 false)
  %51 = call i32 @cqrt_alloc_i1(i1 false)
  %52 = call i32 @cqrt_alloc_i1(i1 false)
  %53 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %53)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %53)
  call void @cqrt_and_i1(i32 %22, i32 %53, i32 %52)
  call void @cqrt_and_i1(i32 %32, i32 %52, i32 %51)
  call void @cqrt_and_i1(i32 %0, i32 %51, i32 %50)
  %54 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %50, i32 %54)
  %55 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %54, i32 %13, i64 %49)
  %56 = call i32 @cq_template_fabs_f64(i32 %55)
  %57 = call i32 @cq_template_fcmp_ogt_f64(i32 %46, i32 %56)
  %58 = call i32 @cq_template_select_f64(i32 %57, i32 %46, i32 %56)
  %59 = call i32 @cq_template_fdiv_f64(i32 %56, i32 %58)
  %60 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %59, double 0x3D06849B86A12B9B)
  %61 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip, i32 %61)
  %62 = call i32 @cqrt_alloc_i1(i1 false)
  %63 = call i32 @cqrt_alloc_i1(i1 false)
  %64 = call i32 @cqrt_alloc_i1(i1 false)
  %65 = call i32 @cqrt_alloc_i1(i1 false)
  %66 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %66)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %66)
  call void @cqrt_and_i1(i32 %22, i32 %66, i32 %65)
  call void @cqrt_and_i1(i32 %32, i32 %65, i32 %64)
  call void @cqrt_and_i1(i32 %60, i32 %64, i32 %63)
  call void @cqrt_and_i1(i32 %0, i32 %63, i32 %62)
  %67 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %62, i32 %67)
  call void @cqrt_and_i1(i32 %trip, i32 %62, i32 %61)
  %68 = trunc nuw nsw i64 %45 to i32
  %69 = call i32 @cqrt_alloc_i1(i1 false)
  %70 = call i32 @cqrt_alloc_i1(i1 false)
  %71 = call i32 @cqrt_alloc_i1(i1 false)
  %72 = call i32 @cqrt_alloc_i1(i1 false)
  %73 = call i32 @cqrt_alloc_i1(i1 false)
  %74 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %74)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %74)
  call void @cqrt_and_i1(i32 %22, i32 %74, i32 %73)
  call void @cqrt_and_i1(i32 %32, i32 %73, i32 %72)
  call void @cqrt_xor_i1(i32 %72, i32 %71)
  call void @cqrt_and_i1(i32 %72, i32 %33, i32 %71)
  call void @cqrt_xor_i1(i32 %71, i32 %70)
  call void @cqrt_and_i1(i32 %71, i32 %60, i32 %70)
  call void @cqrt_and_i1(i32 %0, i32 %70, i32 %69)
  %75 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %69, i32 %75)
  %76 = call fastcc double @__cq_q_yn__00_ctl(i32 %75, i32 %68, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %69, i32 %75)
  call void @cqrt_free(i32 %75)
  call void @cqrt_and_i1(i32 %0, i32 %70, i32 %69)
  call void @cqrt_free(i32 %69)
  call void @cqrt_and_i1(i32 %71, i32 %60, i32 %70)
  call void @cqrt_xor_i1(i32 %71, i32 %70)
  call void @cqrt_free(i32 %70)
  call void @cqrt_and_i1(i32 %72, i32 %33, i32 %71)
  call void @cqrt_xor_i1(i32 %72, i32 %71)
  call void @cqrt_free(i32 %71)
  call void @cqrt_and_i1(i32 %32, i32 %73, i32 %72)
  call void @cqrt_free(i32 %72)
  call void @cqrt_and_i1(i32 %22, i32 %74, i32 %73)
  call void @cqrt_free(i32 %73)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %74)
  call void @cqrt_xor_i1(i32 %16, i32 %74)
  call void @cqrt_free(i32 %74)
  %77 = call i32 @cqrt_alloc_i1(i1 false)
  %78 = call i32 @cqrt_alloc_i1(i1 false)
  %79 = call i32 @cqrt_alloc_i1(i1 false)
  %80 = call i32 @cqrt_alloc_i1(i1 false)
  %81 = call i32 @cqrt_alloc_i1(i1 false)
  %82 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %82)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %82)
  call void @cqrt_and_i1(i32 %22, i32 %82, i32 %81)
  call void @cqrt_and_i1(i32 %32, i32 %81, i32 %80)
  call void @cqrt_and_i1(i32 %33, i32 %80, i32 %79)
  call void @cqrt_xor_i1(i32 %79, i32 %78)
  call void @cqrt_and_i1(i32 %79, i32 %60, i32 %78)
  call void @cqrt_and_i1(i32 %0, i32 %78, i32 %77)
  %83 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %77, i32 %83)
  %84 = call fastcc double @__cq_q_jn__00_ctl(i32 %83, i32 %68, double 2.000000e+00)
  call void @cqrt_and_i1(i32 %trip, i32 %77, i32 %83)
  call void @cqrt_free(i32 %83)
  call void @cqrt_and_i1(i32 %0, i32 %78, i32 %77)
  call void @cqrt_free(i32 %77)
  call void @cqrt_and_i1(i32 %79, i32 %60, i32 %78)
  call void @cqrt_xor_i1(i32 %79, i32 %78)
  call void @cqrt_free(i32 %78)
  call void @cqrt_and_i1(i32 %33, i32 %80, i32 %79)
  call void @cqrt_free(i32 %79)
  call void @cqrt_and_i1(i32 %32, i32 %81, i32 %80)
  call void @cqrt_free(i32 %80)
  call void @cqrt_and_i1(i32 %22, i32 %82, i32 %81)
  call void @cqrt_free(i32 %81)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %82)
  call void @cqrt_xor_i1(i32 %16, i32 %82)
  call void @cqrt_free(i32 %82)
  %85 = call i32 @cq_template_select_f64_ll(i32 %33, double %84, double %76)
  %86 = trunc nuw nsw i64 %45 to i32
  %87 = uitofp nneg i32 %86 to double
  %88 = call i32 @cq_template_fmul_f64_hl(i32 %34, double 5.000000e-01)
  %89 = call i32 @cq_template_fadd_f64_hl(i32 %88, double %87)
  %90 = call i32 @cqrt_alloc_i1(i1 false)
  %91 = call i32 @cqrt_alloc_i1(i1 false)
  %92 = call i32 @cqrt_alloc_i1(i1 false)
  %93 = call i32 @cqrt_alloc_i1(i1 false)
  %94 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %94)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %94)
  call void @cqrt_and_i1(i32 %22, i32 %94, i32 %93)
  call void @cqrt_and_i1(i32 %32, i32 %93, i32 %92)
  call void @cqrt_xor_i1(i32 %92, i32 %91)
  call void @cqrt_and_i1(i32 %92, i32 %60, i32 %91)
  call void @cqrt_and_i1(i32 %0, i32 %91, i32 %90)
  %95 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip, i32 %90, i32 %95)
  %96 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %95, i32 %89)
  call void @cqrt_and_i1(i32 %trip, i32 %90, i32 %95)
  call void @cqrt_free(i32 %95)
  call void @cqrt_and_i1(i32 %0, i32 %91, i32 %90)
  call void @cqrt_free(i32 %90)
  call void @cqrt_and_i1(i32 %92, i32 %60, i32 %91)
  call void @cqrt_xor_i1(i32 %92, i32 %91)
  call void @cqrt_free(i32 %91)
  call void @cqrt_and_i1(i32 %32, i32 %93, i32 %92)
  call void @cqrt_free(i32 %92)
  call void @cqrt_and_i1(i32 %22, i32 %94, i32 %93)
  call void @cqrt_free(i32 %93)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %94)
  call void @cqrt_xor_i1(i32 %16, i32 %94)
  call void @cqrt_free(i32 %94)
  call void @cq_template_fadd_f64_hl_unc(i32 %89, i32 %88, double %87)
  call void @cqrt_free(i32 %89)
  call void @cq_template_fmul_f64_hl_unc(i32 %88, i32 %34, double 5.000000e-01)
  call void @cqrt_free(i32 %88)
  %97 = call i32 @cq_template_fmul_f64(i32 %55, i32 %96)
  %98 = call i32 @cq_template_fmul_f64(i32 %97, i32 %85)
  %99 = call i32 @cq_template_fadd_f64(i32 %98, i32 %47)
  %100 = add nuw nsw i64 %45, 1
  %101 = icmp eq i64 %100, 8
  %102 = call i32 @cq_template_select_f64(i32 %61, i32 %58, i32 %46)
  %103 = call i32 @cq_template_select_f64(i32 %61, i32 %99, i32 %47)
  %104 = call i32 @cq_template_select_f64(i32 %67, i32 %47, i32 %xcap)
  %105 = call i32 @cq_template_select_f64(i32 %61, i32 %99, i32 %104)
  call void @cqrt_push(i32 %105)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %99)
  call void @cqrt_push(i32 %104)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %xcap)
  call void @cqrt_push(i32 %103)
  call void @cqrt_push(i32 %102)
  call void @cqrt_push(i32 %58)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %98)
  call void @cqrt_push(i32 %97)
  call void @cqrt_push(i32 %85)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %96)
  %106 = bitcast double %84 to i64
  %107 = trunc i64 %106 to i32
  call void @cqrt_push(i32 %107)
  %108 = lshr i64 %106, 32
  %109 = trunc i64 %108 to i32
  call void @cqrt_push(i32 %109)
  %110 = bitcast double %76 to i64
  %111 = trunc i64 %110 to i32
  call void @cqrt_push(i32 %111)
  %112 = lshr i64 %110, 32
  %113 = trunc i64 %112 to i32
  call void @cqrt_push(i32 %113)
  call void @cqrt_push(i32 %trip)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %63)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %64)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %57)
  call void @cqrt_push(i32 %54)
  %114 = trunc i64 %49 to i32
  call void @cqrt_push(i32 %114)
  %115 = lshr i64 %49, 32
  %116 = trunc i64 %115 to i32
  call void @cqrt_push(i32 %116)
  call void @cqrt_push(i32 %50)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %52)
  call void @cqrt_push(i32 %53)
  br i1 %101, label %43, label %44

117:                                              ; preds = %43
  %118 = call i32 @cq_template_add_i32_hl(i32 %2, i32 -1)
  %119 = call i32 @cq_template_sitofp_i32_to_f64(i32 %118)
  br label %120

120:                                              ; preds = %117
  %121 = call i32 @cqrt_alloc_i1(i1 false)
  %122 = call i32 @cqrt_alloc_i1(i1 false)
  %123 = call i32 @cqrt_alloc_i1(i1 false)
  %124 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %124)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %124)
  call void @cqrt_and_i1(i32 %22, i32 %124, i32 %123)
  call void @cqrt_xor_i1(i32 %123, i32 %122)
  call void @cqrt_and_i1(i32 %123, i32 %32, i32 %122)
  call void @cqrt_and_i1(i32 %0, i32 %122, i32 %121)
  %125 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %126 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  br label %128

127:                                              ; preds = %128
  br label %203

128:                                              ; preds = %128, %120
  %from = phi i32 [ 0, %128 ], [ 1, %120 ]
  %129 = phi i64 [ 0, %120 ], [ %186, %128 ]
  %130 = phi i32 [ %125, %120 ], [ %188, %128 ]
  %131 = phi i32 [ %126, %120 ], [ %189, %128 ]
  %trip1 = phi i32 [ %121, %120 ], [ %145, %128 ]
  %xcap2 = phi i32 [ %105, %120 ], [ %190, %128 ]
  call void @cqrt_push(i32 %from)
  %132 = getelementptr inbounds [8 x double], ptr %14, i64 0, i64 %129
  %133 = ptrtoint ptr %132 to i64
  %134 = call i32 @cqrt_alloc_i1(i1 false)
  %135 = call i32 @cqrt_alloc_i1(i1 false)
  %136 = call i32 @cqrt_alloc_i1(i1 false)
  %137 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %137)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %137)
  call void @cqrt_and_i1(i32 %22, i32 %137, i32 %136)
  call void @cqrt_xor_i1(i32 %136, i32 %135)
  call void @cqrt_and_i1(i32 %136, i32 %32, i32 %135)
  call void @cqrt_and_i1(i32 %0, i32 %135, i32 %134)
  %138 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %134, i32 %138)
  %139 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %138, i32 %13, i64 %133)
  %140 = call i32 @cq_template_fabs_f64(i32 %139)
  %141 = call i32 @cq_template_fcmp_ogt_f64(i32 %130, i32 %140)
  %142 = call i32 @cq_template_select_f64(i32 %141, i32 %130, i32 %140)
  %143 = call i32 @cq_template_fdiv_f64(i32 %140, i32 %142)
  %144 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %143, double 0x3D06849B86A12B9B)
  %145 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %trip1, i32 %145)
  %146 = call i32 @cqrt_alloc_i1(i1 false)
  %147 = call i32 @cqrt_alloc_i1(i1 false)
  %148 = call i32 @cqrt_alloc_i1(i1 false)
  %149 = call i32 @cqrt_alloc_i1(i1 false)
  %150 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %150)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %150)
  call void @cqrt_and_i1(i32 %22, i32 %150, i32 %149)
  call void @cqrt_xor_i1(i32 %149, i32 %148)
  call void @cqrt_and_i1(i32 %149, i32 %32, i32 %148)
  call void @cqrt_and_i1(i32 %144, i32 %148, i32 %147)
  call void @cqrt_and_i1(i32 %0, i32 %147, i32 %146)
  %151 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %146, i32 %151)
  call void @cqrt_and_i1(i32 %trip1, i32 %146, i32 %145)
  %152 = trunc i64 %129 to i32
  %153 = add i32 %152, 1
  %154 = call i32 @cqrt_alloc_i1(i1 false)
  %155 = call i32 @cqrt_alloc_i1(i1 false)
  %156 = call i32 @cqrt_alloc_i1(i1 false)
  %157 = call i32 @cqrt_alloc_i1(i1 false)
  %158 = call i32 @cqrt_alloc_i1(i1 false)
  %159 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %159)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %159)
  call void @cqrt_and_i1(i32 %22, i32 %159, i32 %158)
  call void @cqrt_xor_i1(i32 %158, i32 %157)
  call void @cqrt_and_i1(i32 %158, i32 %32, i32 %157)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_and_i1(i32 %157, i32 %144, i32 %156)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_and_i1(i32 %156, i32 %33, i32 %155)
  call void @cqrt_and_i1(i32 %0, i32 %155, i32 %154)
  %160 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %154, i32 %160)
  %161 = call fastcc double @__cq_q_yn__00_ctl(i32 %160, i32 %153, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %154, i32 %160)
  call void @cqrt_free(i32 %160)
  call void @cqrt_and_i1(i32 %0, i32 %155, i32 %154)
  call void @cqrt_free(i32 %154)
  call void @cqrt_and_i1(i32 %156, i32 %33, i32 %155)
  call void @cqrt_xor_i1(i32 %156, i32 %155)
  call void @cqrt_free(i32 %155)
  call void @cqrt_and_i1(i32 %157, i32 %144, i32 %156)
  call void @cqrt_xor_i1(i32 %157, i32 %156)
  call void @cqrt_free(i32 %156)
  call void @cqrt_and_i1(i32 %158, i32 %32, i32 %157)
  call void @cqrt_xor_i1(i32 %158, i32 %157)
  call void @cqrt_free(i32 %157)
  call void @cqrt_and_i1(i32 %22, i32 %159, i32 %158)
  call void @cqrt_free(i32 %158)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %159)
  call void @cqrt_xor_i1(i32 %16, i32 %159)
  call void @cqrt_free(i32 %159)
  %162 = call i32 @cqrt_alloc_i1(i1 false)
  %163 = call i32 @cqrt_alloc_i1(i1 false)
  %164 = call i32 @cqrt_alloc_i1(i1 false)
  %165 = call i32 @cqrt_alloc_i1(i1 false)
  %166 = call i32 @cqrt_alloc_i1(i1 false)
  %167 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %167)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %167)
  call void @cqrt_and_i1(i32 %22, i32 %167, i32 %166)
  call void @cqrt_xor_i1(i32 %166, i32 %165)
  call void @cqrt_and_i1(i32 %166, i32 %32, i32 %165)
  call void @cqrt_xor_i1(i32 %165, i32 %164)
  call void @cqrt_and_i1(i32 %165, i32 %144, i32 %164)
  call void @cqrt_and_i1(i32 %33, i32 %164, i32 %163)
  call void @cqrt_and_i1(i32 %0, i32 %163, i32 %162)
  %168 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %162, i32 %168)
  %169 = call fastcc double @__cq_q_jn__00_ctl(i32 %168, i32 %153, double 3.000000e+00)
  call void @cqrt_and_i1(i32 %trip1, i32 %162, i32 %168)
  call void @cqrt_free(i32 %168)
  call void @cqrt_and_i1(i32 %0, i32 %163, i32 %162)
  call void @cqrt_free(i32 %162)
  call void @cqrt_and_i1(i32 %33, i32 %164, i32 %163)
  call void @cqrt_free(i32 %163)
  call void @cqrt_and_i1(i32 %165, i32 %144, i32 %164)
  call void @cqrt_xor_i1(i32 %165, i32 %164)
  call void @cqrt_free(i32 %164)
  call void @cqrt_and_i1(i32 %166, i32 %32, i32 %165)
  call void @cqrt_xor_i1(i32 %166, i32 %165)
  call void @cqrt_free(i32 %165)
  call void @cqrt_and_i1(i32 %22, i32 %167, i32 %166)
  call void @cqrt_free(i32 %166)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %167)
  call void @cqrt_xor_i1(i32 %16, i32 %167)
  call void @cqrt_free(i32 %167)
  %170 = call i32 @cq_template_select_f64_ll(i32 %33, double %169, double %161)
  %171 = trunc nuw nsw i64 %129 to i32
  %172 = uitofp nneg i32 %171 to double
  %173 = call i32 @cq_template_fmul_f64_hl(i32 %119, double 5.000000e-01)
  %174 = call i32 @cq_template_fadd_f64_hl(i32 %173, double %172)
  %175 = call i32 @cqrt_alloc_i1(i1 false)
  %176 = call i32 @cqrt_alloc_i1(i1 false)
  %177 = call i32 @cqrt_alloc_i1(i1 false)
  %178 = call i32 @cqrt_alloc_i1(i1 false)
  %179 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %179)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %179)
  call void @cqrt_and_i1(i32 %22, i32 %179, i32 %178)
  call void @cqrt_xor_i1(i32 %178, i32 %177)
  call void @cqrt_and_i1(i32 %178, i32 %32, i32 %177)
  call void @cqrt_xor_i1(i32 %177, i32 %176)
  call void @cqrt_and_i1(i32 %177, i32 %144, i32 %176)
  call void @cqrt_and_i1(i32 %0, i32 %176, i32 %175)
  %180 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_and_i1(i32 %trip1, i32 %175, i32 %180)
  %181 = call fastcc i32 @__cq_q_sgn_1_ctl(i32 %180, i32 %174)
  call void @cqrt_and_i1(i32 %trip1, i32 %175, i32 %180)
  call void @cqrt_free(i32 %180)
  call void @cqrt_and_i1(i32 %0, i32 %176, i32 %175)
  call void @cqrt_free(i32 %175)
  call void @cqrt_and_i1(i32 %177, i32 %144, i32 %176)
  call void @cqrt_xor_i1(i32 %177, i32 %176)
  call void @cqrt_free(i32 %176)
  call void @cqrt_and_i1(i32 %178, i32 %32, i32 %177)
  call void @cqrt_xor_i1(i32 %178, i32 %177)
  call void @cqrt_free(i32 %177)
  call void @cqrt_and_i1(i32 %22, i32 %179, i32 %178)
  call void @cqrt_free(i32 %178)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %179)
  call void @cqrt_xor_i1(i32 %16, i32 %179)
  call void @cqrt_free(i32 %179)
  call void @cq_template_fadd_f64_hl_unc(i32 %174, i32 %173, double %172)
  call void @cqrt_free(i32 %174)
  call void @cq_template_fmul_f64_hl_unc(i32 %173, i32 %119, double 5.000000e-01)
  call void @cqrt_free(i32 %173)
  %182 = call i32 @cq_template_fmul_f64(i32 %139, i32 %181)
  %183 = call i32 @cq_template_fadd_f64_hl(i32 %170, double 1.000000e+00)
  %184 = call i32 @cq_template_fmul_f64(i32 %182, i32 %183)
  %185 = call i32 @cq_template_fadd_f64(i32 %184, i32 %131)
  %186 = add nuw nsw i64 %129, 1
  %187 = icmp eq i64 %186, 8
  %188 = call i32 @cq_template_select_f64(i32 %145, i32 %142, i32 %130)
  %189 = call i32 @cq_template_select_f64(i32 %145, i32 %185, i32 %131)
  %190 = call i32 @cq_template_select_f64(i32 %151, i32 %131, i32 %xcap2)
  %191 = call i32 @cq_template_select_f64(i32 %145, i32 %185, i32 %190)
  call void @cqrt_push(i32 %191)
  call void @cqrt_push(i32 %145)
  call void @cqrt_push(i32 %185)
  call void @cqrt_push(i32 %190)
  call void @cqrt_push(i32 %151)
  call void @cqrt_push(i32 %131)
  call void @cqrt_push(i32 %xcap2)
  call void @cqrt_push(i32 %189)
  call void @cqrt_push(i32 %188)
  call void @cqrt_push(i32 %142)
  call void @cqrt_push(i32 %130)
  call void @cqrt_push(i32 %184)
  call void @cqrt_push(i32 %182)
  call void @cqrt_push(i32 %183)
  call void @cqrt_push(i32 %170)
  call void @cqrt_push(i32 %139)
  call void @cqrt_push(i32 %181)
  %192 = bitcast double %169 to i64
  %193 = trunc i64 %192 to i32
  call void @cqrt_push(i32 %193)
  %194 = lshr i64 %192, 32
  %195 = trunc i64 %194 to i32
  call void @cqrt_push(i32 %195)
  %196 = bitcast double %161 to i64
  %197 = trunc i64 %196 to i32
  call void @cqrt_push(i32 %197)
  %198 = lshr i64 %196, 32
  %199 = trunc i64 %198 to i32
  call void @cqrt_push(i32 %199)
  call void @cqrt_push(i32 %trip1)
  call void @cqrt_push(i32 %146)
  call void @cqrt_push(i32 %147)
  call void @cqrt_push(i32 %144)
  call void @cqrt_push(i32 %148)
  call void @cqrt_push(i32 %149)
  call void @cqrt_push(i32 %150)
  call void @cqrt_push(i32 %143)
  call void @cqrt_push(i32 %140)
  call void @cqrt_push(i32 %141)
  call void @cqrt_push(i32 %138)
  %200 = trunc i64 %133 to i32
  call void @cqrt_push(i32 %200)
  %201 = lshr i64 %133, 32
  %202 = trunc i64 %201 to i32
  call void @cqrt_push(i32 %202)
  call void @cqrt_push(i32 %134)
  call void @cqrt_push(i32 %135)
  call void @cqrt_push(i32 %136)
  call void @cqrt_push(i32 %137)
  br i1 %187, label %127, label %128

203:                                              ; preds = %127
  %204 = call i32 @cqrt_alloc_i1(i1 false)
  %205 = call i32 @cqrt_alloc_i1(i1 false)
  %206 = call i32 @cqrt_alloc_i1(i1 false)
  %207 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %207)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %207)
  call void @cqrt_and_i1(i32 %22, i32 %207, i32 %206)
  call void @cqrt_xor_i1(i32 %206, i32 %205)
  call void @cqrt_and_i1(i32 %206, i32 %32, i32 %205)
  call void @cqrt_and_i1(i32 %0, i32 %205, i32 %204)
  %208 = call i32 @cq_template_select_f64(i32 %204, i32 %185, i32 %191)
  %209 = ptrtoint ptr %14 to i64
  %210 = call i32 @cqrt_alloc_i1(i1 false)
  %211 = call i32 @cqrt_alloc_i1(i1 false)
  %212 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %212)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %212)
  call void @cqrt_and_i1(i32 %22, i32 %212, i32 %211)
  call void @cqrt_and_i1(i32 %0, i32 %211, i32 %210)
  %213 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %210, i32 %13, i64 %209)
  %214 = call i32 @cq_template_fdiv_f64(i32 %208, i32 %213)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %213, i32 %210, i32 %13, i64 %209)
  call void @cqrt_free(i32 %213)
  call void @cqrt_and_i1(i32 %0, i32 %211, i32 %210)
  call void @cqrt_free(i32 %210)
  call void @cqrt_and_i1(i32 %22, i32 %212, i32 %211)
  call void @cqrt_free(i32 %211)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %212)
  call void @cqrt_xor_i1(i32 %16, i32 %212)
  call void @cqrt_free(i32 %212)
  call void @cq_template_select_f64_unc(i32 %208, i32 %204, i32 %185, i32 %191)
  call void @cqrt_free(i32 %208)
  call void @cqrt_and_i1(i32 %0, i32 %205, i32 %204)
  call void @cqrt_free(i32 %204)
  call void @cqrt_and_i1(i32 %206, i32 %32, i32 %205)
  call void @cqrt_xor_i1(i32 %206, i32 %205)
  call void @cqrt_free(i32 %205)
  call void @cqrt_and_i1(i32 %22, i32 %207, i32 %206)
  call void @cqrt_free(i32 %206)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %207)
  call void @cqrt_xor_i1(i32 %16, i32 %207)
  call void @cqrt_free(i32 %207)
  br label %228

215:                                              ; preds = %227
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %119, i32 %118)
  call void @cqrt_free(i32 %119)
  call void @cq_template_add_i32_hl_unc(i32 %118, i32 %2, i32 -1)
  call void @cqrt_free(i32 %118)
  br label %286

216:                                              ; preds = %285
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %34, i32 %2)
  call void @cqrt_free(i32 %34)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %33, i32 %1, i32 1)
  call void @cqrt_free(i32 %33)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %32, i32 %31, i32 0)
  call void @cqrt_free(i32 %32)
  call void @cq_template_and_i32_hl_unc(i32 %31, i32 %2, i32 1)
  call void @cqrt_free(i32 %31)
  %217 = ptrtoint ptr %4 to i64
  %218 = call i32 @cqrt_alloc_i1(i1 false)
  %219 = call i32 @cqrt_alloc_i1(i1 false)
  %220 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xor_i1(i32 %16, i32 %220)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %220)
  call void @cqrt_and_i1(i32 %22, i32 %220, i32 %219)
  call void @cqrt_and_i1(i32 %0, i32 %219, i32 %218)
  call void @cqrt_and_i1(i32 %22, i32 %220, i32 %219)
  call void @cqrt_free(i32 %219)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %220)
  call void @cqrt_xor_i1(i32 %16, i32 %220)
  call void @cqrt_free(i32 %220)
  call void @cqrt_qram_store_f64_hl_controlled(i32 %218, i32 %13, i64 %217, i32 %214)
  %221 = call i32 @cq_template_select_i32_lh(i32 %22, i32 0, i32 %21)
  %222 = call i32 @cq_template_select_i32_lh(i32 %18, i32 2, i32 %221)
  %223 = call i32 @cq_template_select_i32_hl(i32 %16, i32 %222, i32 1)
  %224 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %223, i32 %224)
  call void @cq_template_select_i32_hl_unc(i32 %223, i32 %16, i32 %222, i32 1)
  call void @cqrt_free(i32 %223)
  call void @cq_template_select_i32_lh_unc(i32 %222, i32 %18, i32 2, i32 %221)
  call void @cqrt_free(i32 %222)
  call void @cq_template_select_i32_lh_unc(i32 %221, i32 %22, i32 0, i32 %21)
  call void @cqrt_free(i32 %221)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %22, i32 %21, i32 0)
  call void @cqrt_free(i32 %22)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %18, i32 %17, i32 -2)
  call void @cqrt_free(i32 %18)
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %1, i32 -3)
  call void @cqrt_free(i32 %17)
  call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %16, i32 %3, double 0.000000e+00)
  call void @cqrt_free(i32 %16)
  %225 = load i32, ptr @__cq_act_mc, align 4
  %226 = add i32 %225, -1
  store i32 %226, ptr @__cq_act_mc, align 4
  ret i32 %224

227:                                              ; preds = %228
  call void @cqrt_free(i32 %126)
  call void @cqrt_free(i32 %125)
  call void @cqrt_and_i1(i32 %0, i32 %122, i32 %121)
  call void @cqrt_free(i32 %121)
  call void @cqrt_and_i1(i32 %123, i32 %32, i32 %122)
  call void @cqrt_xor_i1(i32 %123, i32 %122)
  call void @cqrt_free(i32 %122)
  call void @cqrt_and_i1(i32 %22, i32 %124, i32 %123)
  call void @cqrt_free(i32 %123)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %124)
  call void @cqrt_xor_i1(i32 %16, i32 %124)
  call void @cqrt_free(i32 %124)
  br label %215

228:                                              ; preds = %203, %228
  %229 = call i32 @cqrt_pop()
  %230 = call i32 @cqrt_pop()
  %231 = call i32 @cqrt_pop()
  %232 = call i32 @cqrt_pop()
  %233 = call i32 @cqrt_pop()
  %234 = zext i32 %233 to i64
  %235 = shl i64 %234, 32
  %236 = or i64 0, %235
  %237 = call i32 @cqrt_pop()
  %238 = zext i32 %237 to i64
  %239 = or i64 %236, %238
  %240 = call i32 @cqrt_pop()
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
  %252 = zext i32 %251 to i64
  %253 = shl i64 %252, 32
  %254 = or i64 0, %253
  %255 = call i32 @cqrt_pop()
  %256 = zext i32 %255 to i64
  %257 = or i64 %254, %256
  %258 = bitcast i64 %257 to double
  %259 = call i32 @cqrt_pop()
  %260 = zext i32 %259 to i64
  %261 = shl i64 %260, 32
  %262 = or i64 0, %261
  %263 = call i32 @cqrt_pop()
  %264 = zext i32 %263 to i64
  %265 = or i64 %262, %264
  %266 = bitcast i64 %265 to double
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
  call void @cq_template_select_f64_unc(i32 %283, i32 %282, i32 %281, i32 %280)
  call void @cqrt_free(i32 %283)
  call void @cq_template_select_f64_unc(i32 %280, i32 %279, i32 %278, i32 %277)
  call void @cqrt_free(i32 %280)
  call void @cq_template_select_f64_unc(i32 %276, i32 %282, i32 %281, i32 %278)
  call void @cqrt_free(i32 %276)
  call void @cq_template_select_f64_unc(i32 %275, i32 %282, i32 %274, i32 %273)
  call void @cqrt_free(i32 %275)
  call void @cq_template_fadd_f64_unc(i32 %281, i32 %272, i32 %278)
  call void @cqrt_free(i32 %281)
  call void @cq_template_fmul_f64_unc(i32 %272, i32 %271, i32 %270)
  call void @cqrt_free(i32 %272)
  call void @cq_template_fadd_f64_hl_unc(i32 %270, i32 %269, double 1.000000e+00)
  call void @cqrt_free(i32 %270)
  call void @cq_template_fmul_f64_unc(i32 %271, i32 %268, i32 %267)
  call void @cqrt_free(i32 %271)
  call void @cq_template_select_f64_ll_unc(i32 %269, i32 %33, double %266, double %258)
  call void @cqrt_free(i32 %269)
  call void @cqrt_and_i1(i32 %250, i32 %249, i32 %279)
  call void @cqrt_free(i32 %279)
  call void @cqrt_and_i1(i32 %250, i32 %249, i32 %282)
  call void @cqrt_xor_i1(i32 %250, i32 %282)
  call void @cqrt_free(i32 %282)
  call void @cqrt_and_i1(i32 %0, i32 %248, i32 %249)
  call void @cqrt_free(i32 %249)
  call void @cqrt_and_i1(i32 %247, i32 %246, i32 %248)
  call void @cqrt_free(i32 %248)
  call void @cqrt_and_i1(i32 %245, i32 %32, i32 %246)
  call void @cqrt_xor_i1(i32 %245, i32 %246)
  call void @cqrt_free(i32 %246)
  call void @cqrt_and_i1(i32 %22, i32 %244, i32 %245)
  call void @cqrt_free(i32 %245)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %244)
  call void @cqrt_xor_i1(i32 %16, i32 %244)
  call void @cqrt_free(i32 %244)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %247, i32 %243, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %247)
  call void @cq_template_fdiv_f64_unc(i32 %243, i32 %242, i32 %274)
  call void @cqrt_free(i32 %243)
  call void @cq_template_select_f64_unc(i32 %274, i32 %241, i32 %273, i32 %242)
  call void @cqrt_free(i32 %274)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %241, i32 %273, i32 %242)
  call void @cqrt_free(i32 %241)
  call void @cq_template_fabs_f64_unc(i32 %242, i32 %268)
  call void @cqrt_free(i32 %242)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %268, i32 %240, i32 %13, i64 %239)
  call void @cqrt_and_i1(i32 %250, i32 %232, i32 %240)
  call void @cqrt_free(i32 %240)
  call void @cqrt_and_i1(i32 %0, i32 %231, i32 %232)
  call void @cqrt_free(i32 %232)
  call void @cqrt_and_i1(i32 %230, i32 %32, i32 %231)
  call void @cqrt_xor_i1(i32 %230, i32 %231)
  call void @cqrt_free(i32 %231)
  call void @cqrt_and_i1(i32 %22, i32 %229, i32 %230)
  call void @cqrt_free(i32 %230)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %229)
  call void @cqrt_xor_i1(i32 %16, i32 %229)
  call void @cqrt_free(i32 %229)
  %284 = call i32 @cqrt_pop()
  switch i32 %284, label %228 [
    i32 1, label %227
  ]

285:                                              ; preds = %286
  call void @cqrt_free(i32 %42)
  call void @cqrt_free(i32 %41)
  call void @cqrt_free(i32 %40)
  call void @cqrt_and_i1(i32 %0, i32 %37, i32 %36)
  call void @cqrt_free(i32 %36)
  call void @cqrt_and_i1(i32 %32, i32 %38, i32 %37)
  call void @cqrt_free(i32 %37)
  call void @cqrt_and_i1(i32 %22, i32 %39, i32 %38)
  call void @cqrt_free(i32 %38)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %39)
  call void @cqrt_xor_i1(i32 %16, i32 %39)
  call void @cqrt_free(i32 %39)
  br label %216

286:                                              ; preds = %215, %286
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
  %310 = zext i32 %309 to i64
  %311 = shl i64 %310, 32
  %312 = or i64 0, %311
  %313 = call i32 @cqrt_pop()
  %314 = zext i32 %313 to i64
  %315 = or i64 %312, %314
  %316 = bitcast i64 %315 to double
  %317 = call i32 @cqrt_pop()
  %318 = zext i32 %317 to i64
  %319 = shl i64 %318, 32
  %320 = or i64 0, %319
  %321 = call i32 @cqrt_pop()
  %322 = zext i32 %321 to i64
  %323 = or i64 %320, %322
  %324 = bitcast i64 %323 to double
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
  call void @cq_template_select_f64_unc(i32 %340, i32 %339, i32 %338, i32 %337)
  call void @cqrt_free(i32 %340)
  call void @cq_template_select_f64_unc(i32 %337, i32 %336, i32 %335, i32 %334)
  call void @cqrt_free(i32 %337)
  call void @cq_template_select_f64_unc(i32 %333, i32 %339, i32 %338, i32 %335)
  call void @cqrt_free(i32 %333)
  call void @cq_template_select_f64_unc(i32 %332, i32 %339, i32 %331, i32 %330)
  call void @cqrt_free(i32 %332)
  call void @cq_template_fadd_f64_unc(i32 %338, i32 %329, i32 %335)
  call void @cqrt_free(i32 %338)
  call void @cq_template_fmul_f64_unc(i32 %329, i32 %328, i32 %327)
  call void @cqrt_free(i32 %329)
  call void @cq_template_fmul_f64_unc(i32 %328, i32 %326, i32 %325)
  call void @cqrt_free(i32 %328)
  call void @cq_template_select_f64_ll_unc(i32 %327, i32 %33, double %324, double %316)
  call void @cqrt_free(i32 %327)
  call void @cqrt_and_i1(i32 %308, i32 %307, i32 %336)
  call void @cqrt_free(i32 %336)
  call void @cqrt_and_i1(i32 %308, i32 %307, i32 %339)
  call void @cqrt_xor_i1(i32 %308, i32 %339)
  call void @cqrt_free(i32 %339)
  call void @cqrt_and_i1(i32 %0, i32 %306, i32 %307)
  call void @cqrt_free(i32 %307)
  call void @cqrt_and_i1(i32 %305, i32 %304, i32 %306)
  call void @cqrt_free(i32 %306)
  call void @cqrt_and_i1(i32 %32, i32 %303, i32 %304)
  call void @cqrt_free(i32 %304)
  call void @cqrt_and_i1(i32 %22, i32 %302, i32 %303)
  call void @cqrt_free(i32 %303)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %302)
  call void @cqrt_xor_i1(i32 %16, i32 %302)
  call void @cqrt_free(i32 %302)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %305, i32 %301, double 0x3D06849B86A12B9B)
  call void @cqrt_free(i32 %305)
  call void @cq_template_fdiv_f64_unc(i32 %301, i32 %300, i32 %331)
  call void @cqrt_free(i32 %301)
  call void @cq_template_select_f64_unc(i32 %331, i32 %299, i32 %330, i32 %300)
  call void @cqrt_free(i32 %331)
  call void @cq_template_fcmp_ogt_f64_unc(i32 %299, i32 %330, i32 %300)
  call void @cqrt_free(i32 %299)
  call void @cq_template_fabs_f64_unc(i32 %300, i32 %326)
  call void @cqrt_free(i32 %300)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %326, i32 %298, i32 %13, i64 %297)
  call void @cqrt_and_i1(i32 %308, i32 %290, i32 %298)
  call void @cqrt_free(i32 %298)
  call void @cqrt_and_i1(i32 %0, i32 %289, i32 %290)
  call void @cqrt_free(i32 %290)
  call void @cqrt_and_i1(i32 %32, i32 %288, i32 %289)
  call void @cqrt_free(i32 %289)
  call void @cqrt_and_i1(i32 %22, i32 %287, i32 %288)
  call void @cqrt_free(i32 %288)
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %287)
  call void @cqrt_xor_i1(i32 %16, i32 %287)
  call void @cqrt_free(i32 %287)
  %341 = call i32 @cqrt_pop()
  switch i32 %341, label %286 [
    i32 1, label %285
  ]

342:                                              ; preds = %5
  %343 = call i32 @cqrt_alloc_i32(i32 0)
  %344 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %344)
  %345 = load i32, ptr @__cq_act_mc, align 4
  %346 = add i32 %345, -1
  store i32 %346, ptr @__cq_act_mc, align 4
  ret i32 %343
}

declare i32 @cq_template_fdiv_f64_hl(i32, double)

declare void @cq_template_fdiv_f64_hl_unc(i32, i32, double)

declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_fptosi_f64_to_i64(i32)

declare i32 @cq_template_and_i64_hl(i32, i64)

declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)

declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

declare void @cq_template_and_i64_hl_unc(i32, i32, i64)

declare void @cq_template_fptosi_f64_to_i64_unc(i32, i32)

define internal fastcc i32 @__cq_q_char_a_010_ctl(i32 %0, i32 %1, i32 %2, ptr %3) unnamed_addr {
  %5 = call i32 @__cq_mem()
  %6 = sitofp i32 %1 to double
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %6)
  %8 = ptrtoint ptr %3 to i64
  call void @cqrt_qram_store_f64_hl_controlled(i32 %0, i32 %5, i64 %8, i32 %7)
  %9 = icmp sgt i32 %1, 6
  %10 = zext i1 %9 to i32
  ret i32 %10
}

declare i32 @cq_template_select_i32_ll(i32, i32, i32)

declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @mc, ptr @.cq.sig, ptr @__cq_q_mc_1111_t, ptr @__cq_q_mc_1111_t_ctl, ptr @__cq_q_mc_1111_t_unc, ptr @__cq_q_mc_1111_t_ctl_unc)
  call void @__cq_clone_register(ptr @f, ptr @.cq.sig.1, ptr @__cq_q_f_1111_t, ptr @__cq_q_f_1111_t_ctl, ptr @__cq_q_f_1111_t_unc, ptr @__cq_q_f_1111_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_mc_1111_t_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = load i32, ptr @__cq_k, align 4
  store i32 %5, ptr @__cq_k, align 4
  store i32 %7, ptr @__cq_k, align 4
  ret void
}

define internal void @__cq_q_mc_1111_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6) {
  %8 = load i32, ptr @__cq_k, align 4
  store i32 %6, ptr @__cq_k, align 4
  %9 = load i32, ptr @__cq_act_mc, align 4
  %10 = add i32 %9, 1
  store i32 %10, ptr @__cq_act_mc, align 4
  %11 = load i32, ptr @__cq_act_mc, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_mc, align 4
  store i32 %8, ptr @__cq_k, align 4
  ret void
}

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
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
