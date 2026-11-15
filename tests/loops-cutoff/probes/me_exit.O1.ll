; ModuleID = 'me_exit.c'
source_filename = "me_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ex_pre(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = zext i1 %2 to i32
  %7 = select i1 %3, i32 2, i32 0
  %8 = or disjoint i32 %7, %6
  %9 = select i1 %4, i32 4, i32 0
  %10 = or disjoint i32 %8, %9
  %11 = select i1 %5, i32 8, i32 0
  %12 = or disjoint i32 %10, %11
  br label %13

13:                                               ; preds = %18, %1
  %14 = phi i32 [ %12, %1 ], [ %21, %18 ]
  %15 = phi i32 [ 0, %1 ], [ %20, %18 ]
  %16 = and i32 %14, 4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %23

18:                                               ; preds = %13
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  %20 = add i32 %19, %15
  %21 = lshr i32 %14, 1
  %22 = icmp ult i32 %14, 2
  br i1 %22, label %23, label %13, !llvm.loop !6

23:                                               ; preds = %18, %13
  %24 = phi i32 [ %15, %13 ], [ %20, %18 ]
  ret i32 %24
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ex_conj(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = zext i1 %2 to i32
  %7 = select i1 %3, i32 2, i32 0
  %8 = select i1 %4, i32 4, i32 0
  %9 = select i1 %5, i32 8, i32 0
  %10 = or disjoint i32 %7, %6
  %11 = or disjoint i32 %10, %8
  %12 = or disjoint i32 %11, %9
  %13 = or disjoint i32 %12, 16
  br label %14

14:                                               ; preds = %14, %1
  %15 = phi i32 [ %13, %1 ], [ %19, %14 ]
  %16 = phi i32 [ 0, %1 ], [ %18, %14 ]
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  %18 = add i32 %17, %16
  %19 = lshr i32 %15, 1
  %20 = and i32 %15, 2
  %21 = icmp eq i32 %20, 0
  %22 = select i1 %21, i1 true, i1 %4
  br i1 %22, label %23, label %14, !llvm.loop !8

23:                                               ; preds = %14
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @ex_arm(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  br i1 %4, label %6, label %24

6:                                                ; preds = %1
  %7 = select i1 %3, i32 2, i32 0
  %8 = zext i1 %2 to i32
  %9 = or disjoint i32 %7, %8
  %10 = select i1 %5, i32 8, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = or disjoint i32 %11, 4
  br label %13

13:                                               ; preds = %6, %13
  %14 = phi i32 [ %19, %13 ], [ %12, %6 ]
  %15 = phi i32 [ %18, %13 ], [ %0, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  %17 = add i32 %15, 1
  %18 = add i32 %17, %16
  %19 = lshr i32 %14, 1
  %20 = and i32 %14, 2
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %13, !llvm.loop !10

22:                                               ; preds = %13
  %23 = add nsw i32 %18, 10
  br label %24

24:                                               ; preds = %22, %1
  %25 = phi i32 [ %23, %22 ], [ %0, %1 ]
  ret i32 %25
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = distinct !{!8, !9, !7}
!9 = !{!"llvm.loop.mustprogress"}
!10 = distinct !{!10, !9, !7}
