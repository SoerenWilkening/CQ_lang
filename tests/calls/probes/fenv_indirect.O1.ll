; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef nonnull ptr @pick(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp eq i32 %0, 0
  %3 = select i1 %2, ptr @fplain, ptr @fhalf
  ret ptr %3
}

; Function Attrs: nounwind ssp uwtable
define double @fi_call(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %5 = tail call ptr @pick(i32 noundef %2)
  %6 = tail call double %5(double noundef %4) #7, !callees !6
  %7 = tail call double @cq_measure_f64(double noundef %6) #7
  ret double %7
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @fi_pred(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %5 = fcmp ogt double %4, 5.000000e-01
  br i1 %5, label %6, label %9

6:                                                ; preds = %3
  %7 = tail call ptr @pick(i32 noundef %2)
  %8 = tail call double %7(double noundef %4) #7, !callees !6
  br label %9

9:                                                ; preds = %6, %3
  %10 = phi double [ %8, %6 ], [ 1.000000e+00, %3 ]
  %11 = tail call double @cq_measure_f64(double noundef %10) #7
  ret double %11
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @fplain(double noundef %0) #3 {
  %2 = fadd double %0, 2.000000e+00
  ret double %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @fhalf(double noundef %0) #4 {
  %2 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %0, double 5.000000e-01, double -1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  ret double %2
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #5

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { strictfp }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{ptr @fhalf, ptr @fplain}
