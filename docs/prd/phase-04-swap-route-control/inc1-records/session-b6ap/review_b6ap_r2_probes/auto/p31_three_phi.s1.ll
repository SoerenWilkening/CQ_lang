; ModuleID = '../probes/p31_three_phi.c'
source_filename = "../probes/p31_three_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 9, %3 ], [ 5, %0 ]
  %7 = phi i32 [ 5, %3 ], [ 2, %0 ]
  %8 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %13 = add nsw i32 %11, %12
  %14 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %15 = add nsw i32 %13, %14
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
