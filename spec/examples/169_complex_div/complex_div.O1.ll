; ModuleID = 'complex_div.c'
source_filename = "complex_div.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define { double, double } @__divdc3(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @llvm.fabs.f64(double %2)
  %6 = tail call double @llvm.fabs.f64(double %3)
  %7 = tail call double @llvm.maxnum.f64(double %5, double %6)
  %8 = tail call double @logb(double noundef %7) #5
  %9 = tail call double @llvm.fabs.f64(double %8)
  %10 = fcmp ueq double %9, 0x7FF0000000000000
  br i1 %10, label %16, label %11

11:                                               ; preds = %4
  %12 = fptosi double %8 to i32
  %13 = sub nsw i32 0, %12
  %14 = tail call double @scalbn(double noundef %2, i32 noundef %13) #5
  %15 = tail call double @scalbn(double noundef %3, i32 noundef %13) #5
  br label %16

16:                                               ; preds = %11, %4
  %17 = phi double [ %14, %11 ], [ %2, %4 ]
  %18 = phi double [ %15, %11 ], [ %3, %4 ]
  %19 = phi i32 [ %12, %11 ], [ 0, %4 ]
  %20 = fmul double %18, %18
  %21 = tail call double @llvm.fmuladd.f64(double %17, double %17, double %20)
  %22 = fmul double %18, %1
  %23 = tail call double @llvm.fmuladd.f64(double %0, double %17, double %22)
  %24 = fdiv double %23, %21
  %25 = sub nsw i32 0, %19
  %26 = tail call double @scalbn(double noundef %24, i32 noundef %25) #5
  %27 = fneg double %18
  %28 = fmul double %27, %0
  %29 = tail call double @llvm.fmuladd.f64(double %1, double %17, double %28)
  %30 = fdiv double %29, %21
  %31 = tail call double @scalbn(double noundef %30, i32 noundef %25) #5
  %32 = fcmp ord double %26, 0.000000e+00
  %33 = fcmp ord double %31, 0.000000e+00
  %34 = select i1 %32, i1 true, i1 %33
  br i1 %34, label %94, label %35

35:                                               ; preds = %16
  %36 = fcmp oeq double %21, 0.000000e+00
  br i1 %36, label %37, label %45

37:                                               ; preds = %35
  %38 = fcmp ord double %0, 0.000000e+00
  %39 = fcmp ord double %1, 0.000000e+00
  %40 = or i1 %38, %39
  br i1 %40, label %41, label %45

41:                                               ; preds = %37
  %42 = tail call double @llvm.copysign.f64(double 0x7FF0000000000000, double %17)
  %43 = fmul double %42, %0
  %44 = fmul double %42, %1
  br label %94

45:                                               ; preds = %37, %35
  %46 = tail call double @llvm.fabs.f64(double %0)
  %47 = fcmp une double %46, 0x7FF0000000000000
  %48 = tail call double @llvm.fabs.f64(double %1)
  %49 = fcmp une double %48, 0x7FF0000000000000
  %50 = and i1 %47, %49
  %51 = tail call double @llvm.fabs.f64(double %17)
  %52 = fcmp ueq double %51, 0x7FF0000000000000
  %53 = select i1 %50, i1 true, i1 %52
  %54 = tail call double @llvm.fabs.f64(double %18)
  %55 = fcmp ueq double %54, 0x7FF0000000000000
  %56 = select i1 %53, i1 true, i1 %55
  br i1 %56, label %71, label %57

57:                                               ; preds = %45
  %58 = select i1 %47, double 0.000000e+00, double 1.000000e+00
  %59 = tail call double @llvm.copysign.f64(double %58, double %0)
  %60 = tail call double @llvm.fabs.f64(double %1)
  %61 = fcmp une double %60, 0x7FF0000000000000
  %62 = select i1 %61, double 0.000000e+00, double 1.000000e+00
  %63 = tail call double @llvm.copysign.f64(double %62, double %1)
  %64 = fmul double %63, %18
  %65 = tail call double @llvm.fmuladd.f64(double %59, double %17, double %64)
  %66 = fmul double %65, 0x7FF0000000000000
  %67 = fneg double %59
  %68 = fmul double %18, %67
  %69 = tail call double @llvm.fmuladd.f64(double %63, double %17, double %68)
  %70 = fmul double %69, 0x7FF0000000000000
  br label %94

71:                                               ; preds = %45
  %72 = fcmp une double %8, 0x7FF0000000000000
  %73 = fcmp ueq double %46, 0x7FF0000000000000
  %74 = or i1 %73, %72
  %75 = tail call double @llvm.fabs.f64(double %1)
  %76 = fcmp ueq double %75, 0x7FF0000000000000
  %77 = or i1 %76, %74
  br i1 %77, label %94, label %78

78:                                               ; preds = %71
  %79 = tail call double @llvm.fabs.f64(double %17)
  %80 = fcmp une double %79, 0x7FF0000000000000
  %81 = select i1 %80, double 0.000000e+00, double 1.000000e+00
  %82 = tail call double @llvm.copysign.f64(double %81, double %17)
  %83 = tail call double @llvm.fabs.f64(double %18)
  %84 = fcmp une double %83, 0x7FF0000000000000
  %85 = select i1 %84, double 0.000000e+00, double 1.000000e+00
  %86 = tail call double @llvm.copysign.f64(double %85, double %18)
  %87 = fmul double %86, %1
  %88 = tail call double @llvm.fmuladd.f64(double %0, double %82, double %87)
  %89 = fmul double %88, 0.000000e+00
  %90 = fneg double %86
  %91 = fmul double %90, %0
  %92 = tail call double @llvm.fmuladd.f64(double %1, double %82, double %91)
  %93 = fmul double %92, 0.000000e+00
  br label %94

94:                                               ; preds = %41, %71, %78, %57, %16
  %95 = phi double [ %70, %57 ], [ %93, %78 ], [ %31, %71 ], [ %44, %41 ], [ %31, %16 ]
  %96 = phi double [ %66, %57 ], [ %89, %78 ], [ %26, %71 ], [ %43, %41 ], [ %26, %16 ]
  %97 = insertvalue { double, double } poison, double %96, 0
  %98 = insertvalue { double, double } %97, double %95, 1
  ret { double, double } %98
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @logb(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.maxnum.f64(double, double) #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @scalbn(double noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #2

; Function Attrs: nounwind ssp uwtable
define double @complex_div_q_c(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #3 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %7 = fmul double %2, 0.000000e+00
  %8 = fadd double %7, %6
  %9 = fmul double %4, 0.000000e+00
  %10 = fadd double %9, %3
  %11 = tail call { double, double } @__divdc3(double noundef %8, double noundef %2, double noundef %10, double noundef %4) #7
  %12 = extractvalue { double, double } %11, 0
  %13 = extractvalue { double, double } %11, 1
  %14 = fadd double %12, %13
  %15 = tail call double @cq_measure_f64(double noundef %14) #7
  ret double %15
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #4

declare double @cq_measure_f64(double noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define double @complex_div_c_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #3 {
  %7 = tail call double @cq_theta_f64(double noundef %2, double noundef %3) #6
  %8 = tail call double @cq_theta_f64(double noundef %4, double noundef %5) #6
  %9 = fmul double %1, 0.000000e+00
  %10 = fadd double %9, %0
  %11 = fmul double %8, 0.000000e+00
  %12 = fadd double %7, %11
  %13 = tail call { double, double } @__divdc3(double noundef %10, double noundef %1, double noundef %12, double noundef %8) #7
  %14 = extractvalue { double, double } %13, 0
  %15 = extractvalue { double, double } %13, 1
  %16 = tail call double @cq_measure_f64(double noundef %14) #7
  %17 = tail call double @cq_measure_f64(double noundef %15) #7
  %18 = fadd double %16, %17
  ret double %18
}

attributes #0 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
