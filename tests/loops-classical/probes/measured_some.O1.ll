; ModuleID = 'measured_some.c'
source_filename = "measured_some.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @m_r8(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = mul nsw i32 %4, 3
  %6 = add nsw i32 %5, 1
  %7 = icmp eq i32 %2, 7
  br i1 %7, label %10, label %8

8:                                                ; preds = %3
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %20, label %12

10:                                               ; preds = %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  br label %27

12:                                               ; preds = %20, %8
  %13 = phi i32 [ %6, %8 ], [ %24, %20 ]
  %14 = add nsw i32 %13, 2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = mul nsw i32 %17, 7
  %19 = add nsw i32 %18, %16
  br label %27

20:                                               ; preds = %8, %20
  %21 = phi i32 [ %25, %20 ], [ 0, %8 ]
  %22 = phi i32 [ %24, %20 ], [ %6, %8 ]
  %23 = mul nsw i32 %22, 5
  %24 = sub nsw i32 %23, %4
  %25 = add nuw nsw i32 %21, 1
  %26 = icmp eq i32 %25, %2
  br i1 %26, label %12, label %20, !llvm.loop !6

27:                                               ; preds = %12, %10
  %28 = phi i32 [ %11, %10 ], [ %19, %12 ]
  ret i32 %28
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @m_r8b(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = mul nsw i32 %4, 3
  %6 = add nsw i32 %5, 1
  %7 = icmp eq i32 %2, 7
  br i1 %7, label %10, label %8

8:                                                ; preds = %3
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %20, label %12

10:                                               ; preds = %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  br label %27

12:                                               ; preds = %20, %8
  %13 = phi i32 [ %6, %8 ], [ %24, %20 ]
  %14 = add nsw i32 %13, 2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = mul nsw i32 %17, 7
  %19 = add nsw i32 %18, %16
  br label %27

20:                                               ; preds = %8, %20
  %21 = phi i32 [ %25, %20 ], [ 0, %8 ]
  %22 = phi i32 [ %24, %20 ], [ %6, %8 ]
  %23 = mul nsw i32 %22, %22
  %24 = sub nsw i32 %23, %4
  %25 = add nuw nsw i32 %21, 1
  %26 = icmp eq i32 %25, %2
  br i1 %26, label %12, label %20, !llvm.loop !9

27:                                               ; preds = %12, %10
  %28 = phi i32 [ %11, %10 ], [ %19, %12 ]
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define i32 @m_r8c(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = mul nsw i32 %4, 3
  %6 = add nsw i32 %5, 1
  %7 = icmp eq i32 %2, 7
  br i1 %7, label %10, label %8

8:                                                ; preds = %3
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %19, label %12

10:                                               ; preds = %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  br label %26

12:                                               ; preds = %19, %8
  %13 = phi i32 [ %6, %8 ], [ %23, %19 ]
  %14 = add nsw i32 %13, 2
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %17 = mul nsw i32 %16, 7
  %18 = add nsw i32 %17, %15
  br label %26

19:                                               ; preds = %8, %19
  %20 = phi i32 [ %24, %19 ], [ 0, %8 ]
  %21 = phi i32 [ %23, %19 ], [ %6, %8 ]
  %22 = mul nsw i32 %21, 5
  %23 = sub nsw i32 %22, %4
  %24 = add nuw nsw i32 %20, 1
  %25 = icmp eq i32 %24, %2
  br i1 %25, label %12, label %19, !llvm.loop !10

26:                                               ; preds = %12, %10
  %27 = phi i32 [ %11, %10 ], [ %18, %12 ]
  ret i32 %27
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
