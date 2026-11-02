; ModuleID = 'twin_strict.c'
source_filename = "twin_strict.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @g(double noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %4 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double %3, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %5 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.strict") #4
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = add nsw i64 %1, 1
  %8 = tail call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %7, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %9 = tail call double @llvm.experimental.constrained.fadd.f64(double %4, double %8, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %10

10:                                               ; preds = %6, %2
  %11 = phi double [ %9, %6 ], [ %4, %2 ]
  ret double %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i64(i64, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #1

; Function Attrs: nounwind ssp strictfp uwtable
define double @e_twin(double noundef %0, i64 noundef %1) local_unnamed_addr #2 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #5
  %4 = tail call double @g(double noundef %3, i64 noundef %1) #4
  %5 = tail call double @llvm.experimental.constrained.fadd.f64(double %4, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %6 = tail call double @cq_measure_f64(double noundef %5) #6
  ret double %6
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #2 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { strictfp }
attributes #5 = { nomerge nounwind strictfp }
attributes #6 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
