; ModuleID = 'probes/fenv_later_arm_mode.c'
source_filename = "probes/fenv_later_arm_mode.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @nx(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  ret double %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #1

; Function Attrs: nounwind ssp strictfp uwtable
define range(i32 0, 2) i32 @e(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = icmp sgt i32 %4, 5
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = tail call double @nx(double noundef %2) #4
  br label %11

8:                                                ; preds = %3
  %9 = tail call i32 @fesetround(i32 noundef 2048) #6
  %10 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  br label %11

11:                                               ; preds = %8, %6
  %12 = phi double [ %7, %6 ], [ %10, %8 ]
  %13 = tail call double @cq_measure_f64(double noundef %12) #6
  %14 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %13, double 1.000000e+00, metadata !"ogt", metadata !"fpexcept.strict") #4
  %15 = zext i1 %14 to i32
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @fesetround(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #1

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
