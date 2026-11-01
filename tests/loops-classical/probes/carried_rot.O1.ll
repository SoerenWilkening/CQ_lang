; ModuleID = 'carried_rot.c'
source_filename = "carried_rot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p38(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %5 = add nsw i32 %4, 1
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = mul nsw i32 %4, 5
  br label %14

9:                                                ; preds = %14, %3
  %10 = phi i32 [ %5, %3 ], [ %21, %14 ]
  %11 = phi i32 [ 0, %3 ], [ %20, %14 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %13 = xor i32 %12, %11
  ret i32 %13

14:                                               ; preds = %7, %14
  %15 = phi i32 [ 0, %7 ], [ %22, %14 ]
  %16 = phi i32 [ 0, %7 ], [ %20, %14 ]
  %17 = phi i32 [ %5, %7 ], [ %21, %14 ]
  %18 = add nsw i32 %15, %8
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %20 = xor i32 %19, %16
  %21 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef %2) #2
  %22 = add nuw nsw i32 %15, 1
  %23 = icmp eq i32 %22, %1
  br i1 %23, label %9, label %14, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p38_cut(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  %6 = add nsw i32 %4, 1
  %7 = and i32 %5, 7
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %12, %3
  %10 = phi i32 [ %6, %3 ], [ %15, %12 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i32 [ %16, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %15, %12 ], [ %6, %3 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef %2) #2
  %16 = add nuw nsw i32 %13, 1
  %17 = icmp eq i32 %16, %7
  br i1 %17, label %9, label %12, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @p38_cutx(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  %6 = add nsw i32 %4, 1
  %7 = and i32 %5, 7
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %17, label %12

9:                                                ; preds = %12
  %10 = add nuw nsw i32 %13, 1
  %11 = icmp eq i32 %10, %7
  br i1 %11, label %17, label %12, !llvm.loop !10

12:                                               ; preds = %3, %9
  %13 = phi i32 [ %10, %9 ], [ 0, %3 ]
  %14 = phi i32 [ %15, %9 ], [ %6, %3 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef %2) #2
  %16 = icmp eq i32 %15, 3
  br i1 %16, label %17, label %9

17:                                               ; preds = %9, %12, %3
  %18 = phi i32 [ %6, %3 ], [ %15, %9 ], [ 3, %12 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  ret i32 %19
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
