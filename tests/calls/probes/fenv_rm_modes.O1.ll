; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @rm_zero(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = tail call i32 @fesetround(i32 noundef 2048) #5
  %6 = tail call double @third(double noundef %2) #5
  %7 = tail call i32 @fesetround(i32 noundef 0) #5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %9 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double 3.000000e-01, metadata !"ogt", metadata !"fpexcept.strict") #6
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %8, %10
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define double @rmq_q(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  %5 = tail call double @cq_theta_f64(double noundef %1, double noundef %2) #4
  %6 = icmp sgt i32 %4, 2
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = tail call i32 @fesetround(i32 noundef 2048) #5
  br label %9

9:                                                ; preds = %7, %3
  %10 = tail call double @third(double noundef %5) #5
  %11 = tail call double @cq_measure_f64(double noundef %10) #5
  ret double %11
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp strictfp uwtable
define double @rmq_zero(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  %5 = icmp sgt i32 %4, 2
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = tail call i32 @fesetround(i32 noundef 1024) #5
  br label %8

8:                                                ; preds = %6, %3
  %9 = tail call double @third(double noundef %1) #5
  %10 = tail call double @cq_measure_f64(double noundef %9) #5
  ret double %10
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @third(double noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @llvm.experimental.constrained.fdiv.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %3 = tail call double @llvm.experimental.constrained.fadd.f64(double %2, double 1.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  ret double %3
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { nounwind strictfp }
attributes #6 = { strictfp }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
