; ModuleID = 'rule6.c'
source_filename = "rule6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @r_b3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %9, %3
  %7 = phi i32 [ 5, %3 ], [ %13, %9 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %14, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %13, %9 ], [ 5, %3 ]
  %12 = xor i32 %11, %4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef %1) #2
  %14 = add nuw nsw i32 %10, 1
  %15 = icmp eq i32 %14, %2
  br i1 %15, label %6, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @r_c2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %10, label %6

6:                                                ; preds = %10, %3
  %7 = phi i32 [ %4, %3 ], [ %14, %10 ]
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %1) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  ret i32 %9

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %3 ]
  %12 = phi i32 [ %14, %10 ], [ %4, %3 ]
  %13 = mul nuw nsw i32 %11, %11
  %14 = xor i32 %13, %12
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  br i1 %16, label %6, label %10, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @r_sub(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %9, %3
  %7 = phi i32 [ 7, %3 ], [ %13, %9 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %14, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %13, %9 ], [ 7, %3 ]
  %12 = sub nsw i32 %4, %11
  %13 = mul nsw i32 %12, 3
  %14 = add nuw nsw i32 %10, 1
  %15 = icmp eq i32 %14, %2
  br i1 %15, label %6, label %9, !llvm.loop !10
}

; Function Attrs: nounwind ssp uwtable
define i32 @r_live(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = add nsw i32 %4, 1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %1) #2
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %13, label %8

8:                                                ; preds = %13, %3
  %9 = phi i32 [ %6, %3 ], [ %17, %13 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %18, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %17, %13 ], [ %6, %3 ]
  %16 = add nsw i32 %15, %4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef %1) #2
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %8, label %13, !llvm.loop !11
}

; Function Attrs: nounwind ssp uwtable
define double @r_fneg(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2
  %5 = fmul double %4, 2.000000e+00
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %10, %3
  %8 = phi double [ %5, %3 ], [ %14, %10 ]
  %9 = tail call double @cq_measure_f64(double noundef %8) #3
  ret double %9

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %3 ]
  %12 = phi double [ %14, %10 ], [ %5, %3 ]
  %13 = fneg double %12
  %14 = tail call double @cq_theta_f64(double noundef %13, double noundef %1) #2
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  br i1 %16, label %7, label %10, !llvm.loop !12
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @r_c3(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %7, label %16

7:                                                ; preds = %4, %7
  %8 = phi i32 [ %13, %7 ], [ 0, %4 ]
  %9 = phi i32 [ %10, %7 ], [ 1, %4 ]
  %10 = add nsw i32 %9, %5
  %11 = add nsw i32 %8, %2
  %12 = icmp eq i32 %5, %11
  %13 = add nuw nsw i32 %8, 1
  %14 = icmp eq i32 %13, %3
  %15 = select i1 %12, i1 true, i1 %14
  br i1 %15, label %16, label %7, !llvm.loop !13

16:                                               ; preds = %7, %4
  %17 = phi i32 [ 1, %4 ], [ %10, %7 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  ret i32 %18
}

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
