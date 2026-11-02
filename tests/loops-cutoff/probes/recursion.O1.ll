; ModuleID = 'recursion.c'
source_filename = "recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @rc_struct(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 3
  %5 = tail call fastcc { double, double } @halves(i32 noundef %4, double noundef 8.000000e+00)
  %6 = extractvalue { double, double } %5, 0
  %7 = extractvalue { double, double } %5, 1
  %8 = tail call double @cq_measure_f64(double noundef %6) #5
  %9 = tail call double @cq_measure_f64(double noundef %7) #5
  %10 = fsub double %8, %9
  ret double %10
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc { double, double } @halves(i32 noundef %0, double noundef %1) unnamed_addr #2 {
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %13, label %4

4:                                                ; preds = %2
  %5 = add nsw i32 %0, -1
  %6 = fmul double %1, 5.000000e-01
  %7 = tail call fastcc { double, double } @halves(i32 noundef %5, double noundef %6)
  %8 = extractvalue { double, double } %7, 0
  %9 = extractvalue { double, double } %7, 1
  %10 = fadd double %8, %1
  %11 = fneg double %1
  %12 = tail call double @llvm.fmuladd.f64(double %11, double 3.000000e+00, double %9)
  br label %15

13:                                               ; preds = %2
  %14 = fmul double %1, 2.500000e-01
  br label %15

15:                                               ; preds = %13, %4
  %16 = phi double [ %10, %4 ], [ %1, %13 ]
  %17 = phi double [ %12, %4 ], [ %14, %13 ]
  %18 = insertvalue { double, double } poison, double %16, 0
  %19 = insertvalue { double, double } %18, double %17, 1
  ret { double, double } %19
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
