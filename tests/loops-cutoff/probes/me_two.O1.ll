; ModuleID = 'me_two.c'
source_filename = "me_two.c"
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
  %10 = select i1 %5, i32 8, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = or disjoint i32 %11, %8
  br i1 %2, label %13, label %25

13:                                               ; preds = %1, %18
  %14 = phi i32 [ %20, %18 ], [ 0, %1 ]
  %15 = phi i32 [ %19, %18 ], [ %12, %1 ]
  %16 = icmp eq i32 %14, 1
  %17 = select i1 %5, i1 %16, i1 false
  br i1 %17, label %35, label %18

18:                                               ; preds = %13
  %19 = lshr i32 %15, 1
  %20 = add nuw nsw i32 %14, 1
  %21 = and i32 %15, 2
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %13, !llvm.loop !6

23:                                               ; preds = %18
  %24 = add nuw nsw i32 %14, 1001
  br label %25

25:                                               ; preds = %23, %1
  %26 = phi i32 [ %12, %1 ], [ %19, %23 ]
  %27 = phi i32 [ 1000, %1 ], [ %24, %23 ]
  br i1 %4, label %28, label %31

28:                                               ; preds = %25
  %29 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  %30 = add nsw i32 %29, 1
  br label %35

31:                                               ; preds = %25
  %32 = or disjoint i32 %26, 2000
  %33 = tail call i32 @cq_measure_ui32(i32 noundef %32) #3
  %34 = add i32 %33, 2
  br label %35

35:                                               ; preds = %13, %31, %28
  %36 = phi i32 [ %30, %28 ], [ %34, %31 ], [ 100, %13 ]
  ret i32 %36
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

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
