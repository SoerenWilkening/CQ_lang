; ModuleID = 'experiments/gsl/build/repro/specfunc/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.gsl_sf_result_struct = type { double, double }

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.exp.f64(double) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log.f64(double) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #1

; Function Attrs: nounwind ssp uwtable
declare range(i32 0, 17) i32 @gsl_sf_exp_mult_err_e(double noundef, double noundef, double noundef, double noundef, ptr nocapture noundef writeonly) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
declare hidden fastcc i32 @hyperg_1F1_asymp_posx(double noundef, double noundef, double noundef, ptr noundef) unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
declare hidden fastcc i32 @hyperg_1F1_asymp_negx(double noundef, double noundef, double noundef, ptr noundef) unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @hyperg_1F1_ab_neg(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3) unnamed_addr #2 {
  %5 = alloca %struct.gsl_sf_result_struct, align 8
  %6 = fsub double %1, %0
  %7 = tail call double @llvm.fabs.f64(double %2)
  %8 = tail call double @llvm.fabs.f64(double %0)
  %9 = tail call double @llvm.fabs.f64(double %1)
  %10 = fcmp ogt double %8, 1.000000e+00
  %11 = select i1 %10, double %8, double 1.000000e+00
  %12 = fcmp ogt double %9, 1.000000e+00
  %13 = select i1 %12, double %9, double 1.000000e+00
  %14 = fadd double %6, 5.000000e-01
  %15 = tail call double @llvm.floor.f64(double %14)
  %16 = fsub double %6, %15
  %17 = fcmp uge double %16, 0x3D19000000000000
  %18 = fcmp olt double %8, 1.000000e+01
  %19 = fcmp olt double %9, 1.000000e+01
  %20 = and i1 %18, %19
  %21 = fcmp olt double %7, 5.000000e+00
  %22 = and i1 %20, %21
  br i1 %22, label %27, label %23

23:                                               ; preds = %4
  %24 = fmul double %11, 8.000000e-01
  %25 = fmul double %7, %24
  %26 = fcmp olt double %25, %1
  br i1 %26, label %27, label %29

27:                                               ; preds = %23, %4
  %28 = tail call i32 @gsl_sf_hyperg_1F1_series_e(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3) #3
  br label %107

29:                                               ; preds = %23
  %30 = fcmp ogt double %2, 0.000000e+00
  %31 = fcmp ogt double %13, %11
  %32 = and i1 %30, %31
  br i1 %32, label %33, label %41

33:                                               ; preds = %29
  %34 = fmul double %2, 0x4005BF0A8B145769
  %35 = fdiv double %34, %13
  %36 = tail call double @llvm.log.f64(double %35)
  %37 = fmul double %11, %36
  %38 = fcmp olt double %37, 0xC03D0B2CDE569E24
  br i1 %38, label %39, label %41

39:                                               ; preds = %33
  %40 = tail call i32 @gsl_sf_hyperg_1F1_series_e(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3) #3
  br label %107

41:                                               ; preds = %33, %29
  br i1 %21, label %42, label %46

42:                                               ; preds = %41
  %43 = tail call double @llvm.fabs.f64(double %6)
  %44 = fcmp olt double %43, 1.000000e+01
  %45 = and i1 %19, %44
  br i1 %45, label %53, label %46

46:                                               ; preds = %42, %41
  %47 = tail call double @llvm.fabs.f64(double %6)
  %48 = fcmp ogt double %47, 1.000000e+00
  %49 = select i1 %48, double %47, double 1.000000e+00
  %50 = fmul double %49, 8.000000e-01
  %51 = fmul double %7, %50
  %52 = fcmp olt double %51, %1
  br i1 %52, label %53, label %63

53:                                               ; preds = %46, %42
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #3
  %54 = fneg double %2
  %55 = call i32 @gsl_sf_hyperg_1F1_series_e(double noundef %6, double noundef %1, double noundef %54, ptr noundef nonnull %5) #3
  %56 = fmul double %7, 0x3CB0000000000000
  %57 = load double, ptr %5, align 8, !tbaa !6
  %58 = getelementptr inbounds i8, ptr %5, i64 8
  %59 = load double, ptr %58, align 8, !tbaa !11
  %60 = call i32 @gsl_sf_exp_mult_err_e(double noundef %2, double noundef %56, double noundef %57, double noundef %59, ptr noundef %3) #3
  %61 = icmp eq i32 %60, 0
  %62 = select i1 %61, i32 %55, i32 %60
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #3
  br label %107

63:                                               ; preds = %46
  %64 = fcmp olt double %2, -3.000000e+01
  br i1 %64, label %65, label %76

65:                                               ; preds = %63
  %66 = fadd double %0, 1.000000e+00
  %67 = fsub double %66, %1
  %68 = tail call double @llvm.fabs.f64(double %67)
  %69 = fcmp ogt double %68, 1.000000e+00
  %70 = select i1 %69, double %68, double 1.000000e+00
  %71 = fmul double %11, %70
  %72 = fmul double %7, 0x3FEFAE147AE147AE
  %73 = fcmp olt double %71, %72
  br i1 %73, label %74, label %76

74:                                               ; preds = %65
  %75 = tail call fastcc i32 @hyperg_1F1_asymp_negx(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3)
  br label %107

76:                                               ; preds = %65, %63
  %77 = fcmp ogt double %2, 1.000000e+02
  br i1 %77, label %78, label %88

78:                                               ; preds = %76
  %79 = fsub double 1.000000e+00, %0
  %80 = tail call double @llvm.fabs.f64(double %79)
  %81 = fcmp ogt double %80, 1.000000e+00
  %82 = select i1 %81, double %80, double 1.000000e+00
  %83 = fmul double %82, %49
  %84 = fmul double %7, 0x3FEFAE147AE147AE
  %85 = fcmp olt double %83, %84
  br i1 %85, label %86, label %88

86:                                               ; preds = %78
  %87 = tail call fastcc i32 @hyperg_1F1_asymp_posx(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3)
  br label %107

88:                                               ; preds = %78, %76
  %89 = fcmp ule double %6, 0.000000e+00
  %90 = or i1 %89, %17
  %91 = and i1 %30, %90
  br i1 %91, label %92, label %94

92:                                               ; preds = %88
  %93 = tail call fastcc i32 @hyperg_1F1_U(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3)
  br label %107

94:                                               ; preds = %88
  %95 = fcmp olt double %2, 0.000000e+00
  br i1 %95, label %96, label %105

96:                                               ; preds = %94
  %97 = fneg double %2
  %98 = tail call i32 @gsl_sf_hyperg_1F1_series_e(double noundef %6, double noundef %1, double noundef %97, ptr noundef %3) #3
  %99 = tail call double @llvm.exp.f64(double %2)
  %100 = load double, ptr %3, align 8, !tbaa !6
  %101 = fmul double %99, %100
  store double %101, ptr %3, align 8, !tbaa !6
  %102 = getelementptr inbounds i8, ptr %3, i64 8
  %103 = load double, ptr %102, align 8, !tbaa !11
  %104 = fmul double %99, %103
  store double %104, ptr %102, align 8, !tbaa !11
  br label %107

105:                                              ; preds = %94
  %106 = tail call i32 @gsl_sf_hyperg_1F1_series_e(double noundef %0, double noundef %1, double noundef %2, ptr noundef %3) #3
  br label %107

107:                                              ; preds = %105, %96, %92, %86, %74, %53, %39, %27
  %108 = phi i32 [ %28, %27 ], [ %40, %39 ], [ %62, %53 ], [ %75, %74 ], [ %87, %86 ], [ %98, %96 ], [ %106, %105 ], [ %93, %92 ]
  ret i32 %108
}

; Function Attrs: nounwind ssp uwtable
declare hidden fastcc i32 @hyperg_1F1_U(double noundef, double noundef, double noundef, ptr noundef) unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
declare i32 @gsl_sf_hyperg_1F1_series_e(double noundef, double noundef, double noundef, ptr nocapture noundef writeonly) local_unnamed_addr #2

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
