; ModuleID = 'g5.c'
source_filename = "g5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
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

13:                                               ; preds = %1, %36
  %14 = phi i32 [ 3, %1 ], [ %38, %36 ]
  %15 = phi i32 [ 0, %1 ], [ %37, %36 ]
  %16 = icmp sgt i32 %14, 1
  br i1 %16, label %17, label %30

17:                                               ; preds = %13
  %18 = add nsw i32 %14, -1
  %19 = add i32 %18, %15
  br label %20

20:                                               ; preds = %17, %26
  %21 = phi i32 [ %28, %26 ], [ %14, %17 ]
  %22 = phi i32 [ %27, %26 ], [ %15, %17 ]
  %23 = shl i32 3, %22
  %24 = and i32 %23, %12
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %26, label %30

26:                                               ; preds = %20
  %27 = add nsw i32 %22, 1
  %28 = add nsw i32 %21, -1
  %29 = icmp sgt i32 %21, 2
  br i1 %29, label %20, label %30, !llvm.loop !6

30:                                               ; preds = %20, %26, %13
  %31 = phi i32 [ %15, %13 ], [ %22, %20 ], [ %19, %26 ]
  %32 = phi i32 [ %14, %13 ], [ %21, %20 ], [ 1, %26 ]
  %33 = shl nuw i32 1, %31
  %34 = and i32 %33, %12
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %40, label %36

36:                                               ; preds = %30
  %37 = add nsw i32 %31, 1
  %38 = add nsw i32 %32, -1
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %40, label %13, !llvm.loop !9

40:                                               ; preds = %30, %36
  %41 = phi i32 [ 99, %36 ], [ %31, %30 ]
  %42 = tail call i32 @cq_measure_si32(i32 noundef %41) #3
  ret i32 %42
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!9 = distinct !{!9, !8}
