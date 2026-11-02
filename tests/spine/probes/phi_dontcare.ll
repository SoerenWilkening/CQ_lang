; ModuleID = 'phi_dontcare.c'
source_filename = "phi_dontcare.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define double @pd(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  %4 = tail call fastcc double @g(double noundef %1, double noundef %3) #5
  %5 = tail call double @cq_measure_f64(double noundef %4) #6
  ret double %5
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define internal fastcc double @g(double noundef %0, double noundef %1) unnamed_addr #2 {
  %3 = tail call double @llvm.experimental.constrained.floor.f64(double %1, metadata !"fpexcept.ignore") #5
  %4 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %3, double %1, metadata !"oeq", metadata !"fpexcept.ignore") #5
  br i1 %4, label %5, label %10

5:                                                ; preds = %2
  %6 = tail call double @llvm.experimental.constrained.fmul.f64(double 5.000000e-01, double %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %7 = tail call double @llvm.experimental.constrained.floor.f64(double %6, metadata !"fpexcept.ignore") #5
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double 5.000000e-01, double %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %9 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %7, double %8, metadata !"une", metadata !"fpexcept.ignore") #5
  br label %10

10:                                               ; preds = %5, %2
  %11 = phi i1 [ false, %2 ], [ %9, %5 ]
  %12 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double 0.000000e+00, metadata !"ole", metadata !"fpexcept.ignore") #5
  br i1 %12, label %13, label %32

13:                                               ; preds = %10
  %14 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %0, double 0.000000e+00, metadata !"oeq", metadata !"fpexcept.ignore") #5
  br i1 %14, label %15, label %24

15:                                               ; preds = %13
  %16 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %1, double 0.000000e+00, metadata !"olt", metadata !"fpexcept.ignore") #5
  br i1 %16, label %17, label %22

17:                                               ; preds = %15
  br i1 %11, label %18, label %20

18:                                               ; preds = %17
  %19 = tail call double @llvm.experimental.constrained.fdiv.f64(double -1.000000e+00, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br label %45

20:                                               ; preds = %17
  %21 = tail call double @llvm.experimental.constrained.fdiv.f64(double 1.000000e+00, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br label %45

22:                                               ; preds = %15
  %23 = select i1 %11, double -0.000000e+00, double 0.000000e+00
  br label %45

24:                                               ; preds = %13
  br i1 %4, label %29, label %25

25:                                               ; preds = %24
  %26 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %27 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %28 = tail call double @llvm.experimental.constrained.fdiv.f64(double %26, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br label %45

29:                                               ; preds = %24
  %30 = fneg double %0
  %31 = xor i1 %11, true
  br label %32

32:                                               ; preds = %29, %10
  %33 = phi double [ %30, %29 ], [ %0, %10 ]
  %34 = phi i1 [ %31, %29 ], [ true, %10 ]
  %35 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %33, double %1, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br i1 %4, label %36, label %41

36:                                               ; preds = %32
  %37 = tail call double @llvm.experimental.constrained.floor.f64(double %35, metadata !"fpexcept.ignore") #5
  %38 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %37, double %35, metadata !"oeq", metadata !"fpexcept.ignore") #5
  br i1 %38, label %39, label %41

39:                                               ; preds = %36
  %40 = tail call double @llvm.experimental.constrained.fmul.f64(double %35, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br label %41

41:                                               ; preds = %39, %36, %32
  %42 = phi double [ %40, %39 ], [ %35, %36 ], [ %35, %32 ]
  %43 = fneg double %42
  %44 = select i1 %34, double %42, double %43
  br label %45

45:                                               ; preds = %22, %41, %25, %20, %18
  %46 = phi double [ %19, %18 ], [ %21, %20 ], [ %44, %41 ], [ %28, %25 ], [ %23, %22 ]
  ret double %46
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.floor.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #3

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { strictfp }
attributes #6 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
; USERCHECK pd
