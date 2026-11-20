; ModuleID = 'gsl/build/repro/specfunc/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.ceil.f64(double) #0

; Function Attrs: nounwind ssp uwtable
define hidden fastcc range(i32 0, 2) i32 @psi_complex_rhp(double %0, double %1, ptr nocapture noundef %2, ptr nocapture noundef %3) unnamed_addr #1 {
  %5 = fcmp oeq double %0, 0.000000e+00
  %6 = fcmp oeq double %1, 0.000000e+00
  %7 = select i1 %5, i1 %6, i1 false
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  store double 0.000000e+00, ptr %2, align 8, !tbaa !6
  store double 0.000000e+00, ptr %3, align 8, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %2, i64 8
  store double 0.000000e+00, ptr %9, align 8, !tbaa !11
  %10 = getelementptr inbounds i8, ptr %3, i64 8
  store double 0.000000e+00, ptr %10, align 8, !tbaa !11
  br label %121

11:                                               ; preds = %4
  %12 = fcmp olt double %0, 2.000000e+01
  %13 = tail call double @llvm.fabs.f64(double %1)
  %14 = fcmp olt double %13, 2.000000e+01
  %15 = select i1 %12, i1 %14, i1 false
  br i1 %15, label %16, label %27

16:                                               ; preds = %11
  %17 = fadd double %1, 2.000000e+01
  %18 = tail call double @llvm.sqrt.f64(double %17)
  %19 = fsub double 2.000000e+01, %1
  %20 = tail call double @llvm.sqrt.f64(double %19)
  %21 = fneg double %0
  %22 = tail call double @llvm.fmuladd.f64(double %18, double %20, double %21)
  %23 = fcmp ogt double %22, 0.000000e+00
  %24 = tail call double @llvm.ceil.f64(double %22)
  %25 = fptosi double %24 to i32
  %26 = select i1 %23, i32 %25, i32 0
  br label %27

27:                                               ; preds = %16, %11
  %28 = phi i32 [ %26, %16 ], [ 0, %11 ]
  %29 = sitofp i32 %28 to double
  %30 = tail call { double, double } @gsl_complex_add_real(double %0, double %1, double noundef %29) #3
  %31 = extractvalue { double, double } %30, 0
  %32 = extractvalue { double, double } %30, 1
  %33 = tail call { double, double } @gsl_complex_inverse(double %31, double %32) #3
  %34 = extractvalue { double, double } %33, 0
  %35 = extractvalue { double, double } %33, 1
  %36 = tail call { double, double } @gsl_complex_mul(double %34, double %35, double %34, double %35) #3
  %37 = extractvalue { double, double } %36, 0
  %38 = extractvalue { double, double } %36, 1
  %39 = tail call { double, double } @gsl_complex_mul_real(double %37, double %38, double noundef -1.050000e+00) #3
  %40 = extractvalue { double, double } %39, 0
  %41 = extractvalue { double, double } %39, 1
  %42 = tail call { double, double } @gsl_complex_add_real(double %40, double %41, double noundef 1.000000e+00) #3
  %43 = extractvalue { double, double } %42, 0
  %44 = extractvalue { double, double } %42, 1
  %45 = tail call { double, double } @gsl_complex_mul_real(double %43, double %44, double noundef 0xBFDE79E79E79E79E) #3
  %46 = extractvalue { double, double } %45, 0
  %47 = extractvalue { double, double } %45, 1
  %48 = tail call { double, double } @gsl_complex_mul(double %46, double %47, double %37, double %38) #3
  %49 = extractvalue { double, double } %48, 0
  %50 = extractvalue { double, double } %48, 1
  %51 = tail call { double, double } @gsl_complex_add_real(double %49, double %50, double noundef 1.000000e+00) #3
  %52 = extractvalue { double, double } %51, 0
  %53 = extractvalue { double, double } %51, 1
  %54 = tail call { double, double } @gsl_complex_mul_real(double %52, double %53, double noundef -1.000000e-01) #3
  %55 = extractvalue { double, double } %54, 0
  %56 = extractvalue { double, double } %54, 1
  %57 = tail call { double, double } @gsl_complex_mul(double %55, double %56, double %37, double %38) #3
  %58 = extractvalue { double, double } %57, 0
  %59 = extractvalue { double, double } %57, 1
  %60 = tail call { double, double } @gsl_complex_add_real(double %58, double %59, double noundef 1.000000e+00) #3
  %61 = extractvalue { double, double } %60, 0
  %62 = extractvalue { double, double } %60, 1
  %63 = tail call { double, double } @gsl_complex_mul(double %61, double %62, double %37, double %38) #3
  %64 = extractvalue { double, double } %63, 0
  %65 = extractvalue { double, double } %63, 1
  %66 = tail call { double, double } @gsl_complex_mul_real(double %64, double %65, double noundef 0xBFB5555555555555) #3
  %67 = extractvalue { double, double } %66, 0
  %68 = extractvalue { double, double } %66, 1
  %69 = tail call { double, double } @gsl_complex_mul_real(double %34, double %35, double noundef -5.000000e-01) #3
  %70 = extractvalue { double, double } %69, 0
  %71 = extractvalue { double, double } %69, 1
  %72 = tail call { double, double } @gsl_complex_add(double %67, double %68, double %70, double %71) #3
  %73 = extractvalue { double, double } %72, 0
  %74 = extractvalue { double, double } %72, 1
  %75 = tail call { double, double } @gsl_complex_log(double %31, double %32) #3
  %76 = extractvalue { double, double } %75, 0
  %77 = extractvalue { double, double } %75, 1
  %78 = tail call { double, double } @gsl_complex_add(double %76, double %77, double %73, double %74) #3
  %79 = extractvalue { double, double } %78, 0
  %80 = extractvalue { double, double } %78, 1
  %81 = tail call double @llvm.fabs.f64(double %79)
  %82 = fmul double %81, 0x3CC0000000000000
  %83 = getelementptr inbounds i8, ptr %2, i64 8
  store double %82, ptr %83, align 8, !tbaa !11
  %84 = tail call double @llvm.fabs.f64(double %80)
  %85 = fmul double %84, 0x3CC0000000000000
  %86 = getelementptr inbounds i8, ptr %3, i64 8
  store double %85, ptr %86, align 8, !tbaa !11
  %87 = icmp sgt i32 %28, 0
  br i1 %87, label %88, label %111

88:                                               ; preds = %88, %27
  %89 = phi i32 [ %109, %88 ], [ %28, %27 ]
  %90 = phi double [ %102, %88 ], [ %80, %27 ]
  %91 = phi double [ %101, %88 ], [ %79, %27 ]
  %92 = uitofp nneg i32 %89 to double
  %93 = fadd double %92, -1.000000e+00
  %94 = tail call { double, double } @gsl_complex_add_real(double %0, double %1, double noundef %93) #3
  %95 = extractvalue { double, double } %94, 0
  %96 = extractvalue { double, double } %94, 1
  %97 = tail call { double, double } @gsl_complex_inverse(double %95, double %96) #3
  %98 = extractvalue { double, double } %97, 0
  %99 = extractvalue { double, double } %97, 1
  %100 = tail call { double, double } @gsl_complex_sub(double %91, double %90, double %98, double %99) #3
  %101 = extractvalue { double, double } %100, 0
  %102 = extractvalue { double, double } %100, 1
  %103 = tail call double @llvm.fabs.f64(double %98)
  %104 = load double, ptr %83, align 8, !tbaa !11
  %105 = tail call double @llvm.fmuladd.f64(double %103, double 0x3CC0000000000000, double %104)
  store double %105, ptr %83, align 8, !tbaa !11
  %106 = tail call double @llvm.fabs.f64(double %99)
  %107 = load double, ptr %86, align 8, !tbaa !11
  %108 = tail call double @llvm.fmuladd.f64(double %106, double 0x3CC0000000000000, double %107)
  store double %108, ptr %86, align 8, !tbaa !11
  %109 = add nsw i32 %89, -1
  %110 = icmp sgt i32 %89, 1
  br i1 %110, label %88, label %111, !llvm.loop !12

111:                                              ; preds = %88, %27
  %112 = phi double [ %79, %27 ], [ %101, %88 ]
  %113 = phi double [ %80, %27 ], [ %102, %88 ]
  store double %112, ptr %2, align 8, !tbaa !6
  store double %113, ptr %3, align 8, !tbaa !6
  %114 = load double, ptr %2, align 8, !tbaa !6
  %115 = tail call double @llvm.fabs.f64(double %114)
  %116 = load double, ptr %83, align 8, !tbaa !11
  %117 = tail call double @llvm.fmuladd.f64(double %115, double 0x3CC0000000000000, double %116)
  store double %117, ptr %83, align 8, !tbaa !11
  %118 = tail call double @llvm.fabs.f64(double %113)
  %119 = load double, ptr %86, align 8, !tbaa !11
  %120 = tail call double @llvm.fmuladd.f64(double %118, double 0x3CC0000000000000, double %119)
  store double %120, ptr %86, align 8, !tbaa !11
  br label %121

121:                                              ; preds = %111, %8
  %122 = phi i32 [ 1, %8 ], [ 0, %111 ]
  ret i32 %122
}

declare { double, double } @gsl_complex_mul_real(double, double, double noundef) local_unnamed_addr #2

declare { double, double } @gsl_complex_add_real(double, double, double noundef) local_unnamed_addr #2

declare { double, double } @gsl_complex_inverse(double, double) local_unnamed_addr #2

declare { double, double } @gsl_complex_mul(double, double, double, double) local_unnamed_addr #2

declare { double, double } @gsl_complex_add(double, double, double, double) local_unnamed_addr #2

declare { double, double } @gsl_complex_log(double, double) local_unnamed_addr #2

declare { double, double } @gsl_complex_sub(double, double, double, double) local_unnamed_addr #2

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !8, i64 0}
!7 = !{!"gsl_sf_result_struct", !8, i64 0, !8, i64 8}
!8 = !{!"double", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
