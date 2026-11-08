; ModuleID = 'rot_after_read.c'
source_filename = "rot_after_read.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @r_after(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %12, label %9

7:                                                ; preds = %12
  %8 = icmp eq i32 %18, 2
  br label %9

9:                                                ; preds = %7, %4
  %10 = phi i32 [ %5, %4 ], [ %19, %7 ]
  %11 = phi i1 [ false, %4 ], [ %8, %7 ]
  br i1 %11, label %22, label %23

12:                                               ; preds = %4, %12
  %13 = phi i32 [ %20, %12 ], [ 0, %4 ]
  %14 = phi i32 [ %18, %12 ], [ 0, %4 ]
  %15 = phi i32 [ %19, %12 ], [ %5, %4 ]
  %16 = shl i32 %14, 1
  %17 = and i32 %15, 1
  %18 = or disjoint i32 %16, %17
  %19 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef %2) #2
  %20 = add nuw nsw i32 %13, 1
  %21 = icmp eq i32 %20, %3
  br i1 %21, label %7, label %12, !llvm.loop !6

22:                                               ; preds = %9
  tail call void @cq_phi(double noundef 1.000000e+00) #3
  br label %23

23:                                               ; preds = %22, %9
  %24 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %24
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @r_before(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %12, label %9

7:                                                ; preds = %12
  %8 = icmp eq i32 %19, 2
  br label %9

9:                                                ; preds = %7, %4
  %10 = phi i32 [ %5, %4 ], [ %16, %7 ]
  %11 = phi i1 [ false, %4 ], [ %8, %7 ]
  br i1 %11, label %22, label %23

12:                                               ; preds = %4, %12
  %13 = phi i32 [ %20, %12 ], [ 0, %4 ]
  %14 = phi i32 [ %19, %12 ], [ 0, %4 ]
  %15 = phi i32 [ %16, %12 ], [ %5, %4 ]
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef %2) #2
  %17 = shl i32 %14, 1
  %18 = and i32 %16, 1
  %19 = or disjoint i32 %18, %17
  %20 = add nuw nsw i32 %13, 1
  %21 = icmp eq i32 %20, %3
  br i1 %21, label %7, label %12, !llvm.loop !9

22:                                               ; preds = %9
  tail call void @cq_phi(double noundef 1.000000e+00) #3
  br label %23

23:                                               ; preds = %22, %9
  %24 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %24
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
