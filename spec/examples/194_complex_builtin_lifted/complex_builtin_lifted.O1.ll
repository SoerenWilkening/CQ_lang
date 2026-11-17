; ModuleID = 'complex_builtin_lifted.c'
source_filename = "complex_builtin_lifted.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @complex_mul_builtin(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2
  %7 = fmul double %2, 0.000000e+00
  %8 = fadd double %7, %6
  %9 = fmul double %4, 0.000000e+00
  %10 = fadd double %9, %3
  %11 = fmul double %10, %8
  %12 = fmul double %2, %4
  %13 = fmul double %8, %4
  %14 = fmul double %10, %2
  %15 = fsub double %11, %12
  %16 = fadd double %14, %13
  %17 = fcmp uno double %15, 0.000000e+00
  br i1 %17, label %18, label %24, !prof !6

18:                                               ; preds = %5
  %19 = fcmp uno double %16, 0.000000e+00
  br i1 %19, label %20, label %24, !prof !6

20:                                               ; preds = %18
  %21 = tail call { double, double } @__muldc3(double noundef %8, double noundef %2, double noundef %10, double noundef %4) #3
  %22 = extractvalue { double, double } %21, 0
  %23 = extractvalue { double, double } %21, 1
  br label %24

24:                                               ; preds = %20, %18, %5
  %25 = phi double [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]
  %26 = phi double [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]
  %27 = fadd double %25, %26
  %28 = tail call double @cq_measure_f64(double noundef %27) #3
  ret double %28
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare { double, double } @__muldc3(double, double, double, double) local_unnamed_addr

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @complex_div_builtin(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call double @cq_theta_f64(double noundef %2, double noundef %3) #2
  %8 = tail call double @cq_theta_f64(double noundef %4, double noundef %5) #2
  %9 = fmul double %1, 0.000000e+00
  %10 = fadd double %9, %0
  %11 = fmul double %8, 0.000000e+00
  %12 = fadd double %7, %11
  %13 = tail call { double, double } @__divdc3(double noundef %10, double noundef %1, double noundef %12, double noundef %8) #3
  %14 = extractvalue { double, double } %13, 0
  %15 = extractvalue { double, double } %13, 1
  %16 = tail call double @cq_measure_f64(double noundef %14) #3
  %17 = tail call double @cq_measure_f64(double noundef %15) #3
  %18 = fadd double %16, %17
  ret double %18
}

declare { double, double } @__divdc3(double, double, double, double) local_unnamed_addr

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!"branch_weights", i32 1, i32 1048575}
