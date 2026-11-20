; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/experiments/gsl/build/repro/min/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str.17 = external hidden unnamed_addr constant [43 x i8], align 1
@.str.1.18 = external hidden unnamed_addr constant [29 x i8], align 1

declare i32 @gsl_finite(double noundef) local_unnamed_addr #0

declare void @gsl_error(ptr noundef, ptr noundef, i32 noundef, i32 noundef) local_unnamed_addr #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 10) i32 @gsl_min_find_bracket(ptr nocapture noundef readonly %0, ptr nocapture noundef writeonly %1, ptr nocapture noundef writeonly %2, ptr nocapture noundef %3, ptr nocapture noundef %4, ptr nocapture noundef %5, ptr nocapture noundef %6, i64 noundef %7) local_unnamed_addr #2 {
  %9 = alloca double, align 8
  %10 = alloca double, align 8
  %11 = alloca double, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  %12 = load double, ptr %4, align 8, !tbaa !6
  store volatile double %12, ptr %9, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)
  %13 = load double, ptr %6, align 8, !tbaa !6
  store volatile double %13, ptr %10, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %11)
  %14 = load double, ptr %3, align 8, !tbaa !6
  %15 = load double, ptr %5, align 8, !tbaa !6
  %16 = load volatile double, ptr %10, align 8, !tbaa !6
  %17 = load volatile double, ptr %9, align 8, !tbaa !6
  %18 = fcmp ult double %16, %17
  br i1 %18, label %30, label %19

19:                                               ; preds = %8
  %20 = fsub double %15, %14
  %21 = tail call double @llvm.fmuladd.f64(double %20, double 3.819660e-01, double %14)
  %22 = load ptr, ptr %0, align 8, !tbaa !10
  %23 = getelementptr inbounds i8, ptr %0, i64 8
  %24 = load ptr, ptr %23, align 8, !tbaa !13
  %25 = tail call double %22(double noundef %21, ptr noundef %24) #4
  store volatile double %25, ptr %11, align 8, !tbaa !6
  %26 = load volatile double, ptr %11, align 8, !tbaa !6
  %27 = tail call i32 @gsl_finite(double noundef %26) #4
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %43

29:                                               ; preds = %19
  tail call void @gsl_error(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.1.18, i32 noundef 58, i32 noundef 9) #4
  br label %120

30:                                               ; preds = %8
  %31 = load volatile double, ptr %10, align 8, !tbaa !6
  store volatile double %31, ptr %11, align 8, !tbaa !6
  %32 = fsub double %15, %14
  %33 = fdiv double %32, 3.819660e-01
  %34 = fadd double %14, %33
  %35 = load ptr, ptr %0, align 8, !tbaa !10
  %36 = getelementptr inbounds i8, ptr %0, i64 8
  %37 = load ptr, ptr %36, align 8, !tbaa !13
  %38 = tail call double %35(double noundef %34, ptr noundef %37) #4
  store volatile double %38, ptr %10, align 8, !tbaa !6
  %39 = load volatile double, ptr %10, align 8, !tbaa !6
  %40 = tail call i32 @gsl_finite(double noundef %39) #4
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %42, label %43

42:                                               ; preds = %30
  tail call void @gsl_error(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.1.18, i32 noundef 66, i32 noundef 9) #4
  br label %120

43:                                               ; preds = %30, %19
  %44 = phi double [ %15, %19 ], [ %34, %30 ]
  %45 = phi double [ %21, %19 ], [ %15, %30 ]
  %46 = getelementptr inbounds i8, ptr %0, i64 8
  %47 = getelementptr inbounds i8, ptr %0, i64 8
  %48 = getelementptr inbounds i8, ptr %0, i64 8
  %49 = tail call i64 @llvm.umax.i64(i64 %7, i64 2)
  %50 = add i64 %49, -1
  br label %51

51:                                               ; preds = %109, %43
  %52 = phi double [ %14, %43 ], [ %105, %109 ]
  %53 = phi double [ %44, %43 ], [ %106, %109 ]
  %54 = phi double [ %45, %43 ], [ %107, %109 ]
  %55 = phi i64 [ 1, %43 ], [ %110, %109 ]
  %56 = load volatile double, ptr %11, align 8, !tbaa !6
  %57 = load volatile double, ptr %9, align 8, !tbaa !6
  %58 = fcmp olt double %56, %57
  %59 = load volatile double, ptr %11, align 8, !tbaa !6
  br i1 %58, label %60, label %94

60:                                               ; preds = %51
  %61 = load volatile double, ptr %10, align 8, !tbaa !6
  %62 = fcmp olt double %59, %61
  br i1 %62, label %63, label %67

63:                                               ; preds = %60
  store double %52, ptr %3, align 8, !tbaa !6
  store double %53, ptr %5, align 8, !tbaa !6
  store double %54, ptr %1, align 8, !tbaa !6
  %64 = load volatile double, ptr %9, align 8, !tbaa !6
  store double %64, ptr %4, align 8, !tbaa !6
  %65 = load volatile double, ptr %10, align 8, !tbaa !6
  store double %65, ptr %6, align 8, !tbaa !6
  %66 = load volatile double, ptr %11, align 8, !tbaa !6
  store double %66, ptr %2, align 8, !tbaa !6
  br label %120

67:                                               ; preds = %60
  %68 = load volatile double, ptr %11, align 8, !tbaa !6
  %69 = load volatile double, ptr %10, align 8, !tbaa !6
  %70 = fcmp ogt double %68, %69
  %71 = load volatile double, ptr %11, align 8, !tbaa !6
  br i1 %70, label %72, label %84

72:                                               ; preds = %67
  store volatile double %71, ptr %9, align 8, !tbaa !6
  %73 = load volatile double, ptr %10, align 8, !tbaa !6
  store volatile double %73, ptr %11, align 8, !tbaa !6
  %74 = fsub double %53, %54
  %75 = fdiv double %74, 3.819660e-01
  %76 = fadd double %54, %75
  %77 = load ptr, ptr %0, align 8, !tbaa !10
  %78 = load ptr, ptr %48, align 8, !tbaa !13
  %79 = tail call double %77(double noundef %76, ptr noundef %78) #4
  store volatile double %79, ptr %10, align 8, !tbaa !6
  %80 = load volatile double, ptr %10, align 8, !tbaa !6
  %81 = tail call i32 @gsl_finite(double noundef %80) #4
  %82 = icmp eq i32 %81, 0
  br i1 %82, label %83, label %104

83:                                               ; preds = %72
  tail call void @gsl_error(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.1.18, i32 noundef 95, i32 noundef 9) #4
  br label %120

84:                                               ; preds = %67
  store volatile double %71, ptr %10, align 8, !tbaa !6
  %85 = fsub double %54, %52
  %86 = tail call double @llvm.fmuladd.f64(double %85, double 3.819660e-01, double %52)
  %87 = load ptr, ptr %0, align 8, !tbaa !10
  %88 = load ptr, ptr %47, align 8, !tbaa !13
  %89 = tail call double %87(double noundef %86, ptr noundef %88) #4
  store volatile double %89, ptr %11, align 8, !tbaa !6
  %90 = load volatile double, ptr %11, align 8, !tbaa !6
  %91 = tail call i32 @gsl_finite(double noundef %90) #4
  %92 = icmp eq i32 %91, 0
  br i1 %92, label %93, label %104

93:                                               ; preds = %84
  tail call void @gsl_error(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.1.18, i32 noundef 103, i32 noundef 9) #4
  br label %120

94:                                               ; preds = %51
  store volatile double %59, ptr %10, align 8, !tbaa !6
  %95 = fsub double %54, %52
  %96 = tail call double @llvm.fmuladd.f64(double %95, double 3.819660e-01, double %52)
  %97 = load ptr, ptr %0, align 8, !tbaa !10
  %98 = load ptr, ptr %46, align 8, !tbaa !13
  %99 = tail call double %97(double noundef %96, ptr noundef %98) #4
  store volatile double %99, ptr %11, align 8, !tbaa !6
  %100 = load volatile double, ptr %11, align 8, !tbaa !6
  %101 = tail call i32 @gsl_finite(double noundef %100) #4
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %103, label %104

103:                                              ; preds = %94
  tail call void @gsl_error(ptr noundef nonnull @.str.17, ptr noundef nonnull @.str.1.18, i32 noundef 112, i32 noundef 9) #4
  br label %120

104:                                              ; preds = %94, %84, %72
  %105 = phi double [ %54, %72 ], [ %52, %84 ], [ %52, %94 ]
  %106 = phi double [ %76, %72 ], [ %54, %84 ], [ %54, %94 ]
  %107 = phi double [ %53, %72 ], [ %86, %84 ], [ %96, %94 ]
  %108 = icmp eq i64 %55, %50
  br i1 %108, label %116, label %109

109:                                              ; preds = %104
  %110 = add nuw i64 %55, 1
  %111 = fsub double %106, %105
  %112 = fadd double %105, %106
  %113 = fmul double %112, 5.000000e-01
  %114 = tail call double @llvm.fmuladd.f64(double %113, double 0x3E50000000000000, double 0x3E50000000000000)
  %115 = fcmp ogt double %111, %114
  br i1 %115, label %51, label %116, !llvm.loop !14

116:                                              ; preds = %109, %104
  store double %105, ptr %3, align 8, !tbaa !6
  store double %106, ptr %5, align 8, !tbaa !6
  store double %107, ptr %1, align 8, !tbaa !6
  %117 = load volatile double, ptr %9, align 8, !tbaa !6
  store double %117, ptr %4, align 8, !tbaa !6
  %118 = load volatile double, ptr %10, align 8, !tbaa !6
  store double %118, ptr %6, align 8, !tbaa !6
  %119 = load volatile double, ptr %11, align 8, !tbaa !6
  store double %119, ptr %2, align 8, !tbaa !6
  br label %120

120:                                              ; preds = %116, %103, %93, %83, %63, %42, %29
  %121 = phi i32 [ 0, %63 ], [ -1, %116 ], [ 9, %83 ], [ 9, %93 ], [ 9, %103 ], [ 9, %29 ], [ 9, %42 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  ret i32 %121
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

attributes #0 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !12, i64 0}
!11 = !{!"gsl_function_struct", !12, i64 0, !12, i64 8}
!12 = !{!"any pointer", !8, i64 0}
!13 = !{!11, !12, i64 8}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
