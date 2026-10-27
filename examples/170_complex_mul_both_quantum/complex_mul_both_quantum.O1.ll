; ModuleID = 'complex_mul_both_quantum.c'
source_filename = "complex_mul_both_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define { double, double } @__muldc3(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = fmul double %0, %2
  %6 = fmul double %1, %3
  %7 = fmul double %0, %3
  %8 = fmul double %1, %2
  %9 = fsub double %5, %6
  %10 = fadd double %8, %7
  %11 = fcmp uno double %9, 0.000000e+00
  %12 = fcmp uno double %10, 0.000000e+00
  %13 = and i1 %11, %12
  br i1 %13, label %14, label %99

14:                                               ; preds = %4
  %15 = tail call double @llvm.fabs.f64(double %0)
  %16 = fcmp oeq double %15, 0x7FF0000000000000
  %17 = tail call double @llvm.fabs.f64(double %1)
  %18 = fcmp oeq double %17, 0x7FF0000000000000
  %19 = or i1 %16, %18
  br i1 %19, label %20, label %31

20:                                               ; preds = %14
  %21 = uitofp i1 %16 to double
  %22 = tail call double @llvm.copysign.f64(double %21, double %0)
  %23 = uitofp i1 %18 to double
  %24 = tail call double @llvm.copysign.f64(double %23, double %1)
  %25 = fcmp uno double %2, 0.000000e+00
  %26 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %2)
  %27 = select i1 %25, double %26, double %2
  %28 = fcmp uno double %3, 0.000000e+00
  %29 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %3)
  %30 = select i1 %28, double %29, double %3
  br label %31

31:                                               ; preds = %14, %20
  %32 = phi double [ %30, %20 ], [ %3, %14 ]
  %33 = phi double [ %27, %20 ], [ %2, %14 ]
  %34 = phi double [ %24, %20 ], [ %1, %14 ]
  %35 = phi double [ %22, %20 ], [ %0, %14 ]
  %36 = phi i32 [ 1, %20 ], [ 0, %14 ]
  %37 = tail call double @llvm.fabs.f64(double %33)
  %38 = fcmp oeq double %37, 0x7FF0000000000000
  %39 = tail call double @llvm.fabs.f64(double %32)
  %40 = fcmp oeq double %39, 0x7FF0000000000000
  %41 = or i1 %40, %38
  br i1 %41, label %42, label %53

42:                                               ; preds = %31
  %43 = uitofp i1 %38 to double
  %44 = tail call double @llvm.copysign.f64(double %43, double %33)
  %45 = uitofp i1 %40 to double
  %46 = tail call double @llvm.copysign.f64(double %45, double %32)
  %47 = fcmp uno double %35, 0.000000e+00
  %48 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %35)
  %49 = select i1 %47, double %48, double %35
  %50 = fcmp uno double %34, 0.000000e+00
  %51 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %34)
  %52 = select i1 %50, double %51, double %34
  br label %53

53:                                               ; preds = %31, %42
  %54 = phi double [ %46, %42 ], [ %32, %31 ]
  %55 = phi double [ %44, %42 ], [ %33, %31 ]
  %56 = phi double [ %52, %42 ], [ %34, %31 ]
  %57 = phi double [ %49, %42 ], [ %35, %31 ]
  %58 = phi i32 [ 1, %42 ], [ %36, %31 ]
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %60, label %85

60:                                               ; preds = %53
  %61 = tail call double @llvm.fabs.f64(double %5)
  %62 = fcmp oeq double %61, 0x7FF0000000000000
  %63 = tail call double @llvm.fabs.f64(double %6)
  %64 = fcmp oeq double %63, 0x7FF0000000000000
  %65 = or i1 %62, %64
  %66 = tail call double @llvm.fabs.f64(double %7)
  %67 = fcmp oeq double %66, 0x7FF0000000000000
  %68 = or i1 %67, %65
  %69 = tail call double @llvm.fabs.f64(double %8)
  %70 = fcmp oeq double %69, 0x7FF0000000000000
  %71 = or i1 %70, %68
  br i1 %71, label %72, label %85

72:                                               ; preds = %60
  %73 = fcmp uno double %57, 0.000000e+00
  %74 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %57)
  %75 = select i1 %73, double %74, double %57
  %76 = fcmp uno double %56, 0.000000e+00
  %77 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %56)
  %78 = select i1 %76, double %77, double %56
  %79 = fcmp uno double %55, 0.000000e+00
  %80 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %55)
  %81 = select i1 %79, double %80, double %55
  %82 = fcmp uno double %54, 0.000000e+00
  %83 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %54)
  %84 = select i1 %82, double %83, double %54
  br label %85

85:                                               ; preds = %60, %72, %53
  %86 = phi double [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]
  %87 = phi double [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  %88 = phi double [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  %89 = phi double [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]
  br i1 %90, label %99, label %91

91:                                               ; preds = %85
  %92 = fneg double %88
  %93 = fmul double %86, %92
  %94 = tail call double @llvm.fmuladd.f64(double %89, double %87, double %93)
  %95 = fmul double %94, 0x7FF0000000000000
  %96 = fmul double %87, %88
  %97 = tail call double @llvm.fmuladd.f64(double %89, double %86, double %96)
  %98 = fmul double %97, 0x7FF0000000000000
  br label %99

99:                                               ; preds = %85, %91, %4
  %100 = phi double [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]
  %101 = phi double [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]
  %102 = insertvalue { double, double } poison, double %101, 0
  %103 = insertvalue { double, double } %102, double %100, 1
  ret { double, double } %103
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define double @complex_mul_both_quantum(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5, double noundef %6, double noundef %7) local_unnamed_addr #2 {
  %9 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %10 = tail call double @cq_theta_f64(double noundef %2, double noundef %3) #5
  %11 = tail call double @cq_theta_f64(double noundef %4, double noundef %5) #5
  %12 = tail call double @cq_theta_f64(double noundef %6, double noundef %7) #5
  %13 = fmul double %10, 0.000000e+00
  %14 = fadd double %9, %13
  %15 = fmul double %12, 0.000000e+00
  %16 = fadd double %11, %15
  %17 = fmul double %14, %16
  %18 = fmul double %10, %12
  %19 = fmul double %14, %12
  %20 = fmul double %10, %16
  %21 = fsub double %17, %18
  %22 = fadd double %19, %20
  %23 = fcmp uno double %21, 0.000000e+00
  br i1 %23, label %24, label %30, !prof !6

24:                                               ; preds = %8
  %25 = fcmp uno double %22, 0.000000e+00
  br i1 %25, label %26, label %30, !prof !6

26:                                               ; preds = %24
  %27 = tail call { double, double } @__muldc3(double noundef %14, double noundef %10, double noundef %16, double noundef %12) #6
  %28 = extractvalue { double, double } %27, 0
  %29 = extractvalue { double, double } %27, 1
  br label %30

30:                                               ; preds = %26, %24, %8
  %31 = phi double [ %21, %8 ], [ %21, %24 ], [ %28, %26 ]
  %32 = phi double [ %22, %8 ], [ %22, %24 ], [ %29, %26 ]
  %33 = tail call double @cq_measure_f64(double noundef %31) #6
  %34 = tail call double @cq_measure_f64(double noundef %32) #6
  %35 = fadd double %33, %34
  ret double %35
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!"branch_weights", i32 1, i32 1048575}
