; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %12

3:                                                ; preds = %1, %3
  %4 = phi i32 [ 0, %1 ], [ %12, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %13, %3 ]
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %7 = shl nsw i32 %6, 1
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %11 = add i32 %9, %4
  %12 = add i32 %11, %10
  %13 = add nuw nsw i32 %5, 1
  %14 = icmp eq i32 %13, 100
  br i1 %14, label %2, label %3, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %10, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %11, %1 ]
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 2.500000e-01) #2
  %5 = shl nsw i32 %4, 1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %9 = add i32 %7, %2
  %10 = add i32 %9, %8
  %11 = add nuw nsw i32 %3, 1
  %12 = icmp eq i32 %11, 100
  br i1 %12, label %13, label %1, !llvm.loop !6

13:                                               ; preds = %1
  ret i32 %10
}

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
