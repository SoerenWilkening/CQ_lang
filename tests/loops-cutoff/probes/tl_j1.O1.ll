; ModuleID = 'j1.c'
source_filename = "j1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = select i1 %3, i32 2, i32 0
  %7 = select i1 %4, i32 4, i32 0
  %8 = select i1 %5, i32 8, i32 0
  %9 = or disjoint i32 %7, %8
  %10 = or disjoint i32 %9, %6
  br i1 %2, label %11, label %21

11:                                               ; preds = %1, %16
  %12 = phi i32 [ %18, %16 ], [ 0, %1 ]
  %13 = phi i32 [ %17, %16 ], [ %10, %1 ]
  %14 = and i32 %13, 4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %35

16:                                               ; preds = %11
  %17 = lshr i32 %13, 1
  %18 = add nuw nsw i32 %12, 1
  %19 = and i32 %13, 2
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %11, !llvm.loop !6

21:                                               ; preds = %16, %1
  %22 = phi i32 [ %10, %1 ], [ %17, %16 ]
  %23 = phi i32 [ 0, %1 ], [ %18, %16 ]
  %24 = and i32 %0, 1
  br label %25

25:                                               ; preds = %21, %32
  %26 = phi i32 [ %24, %21 ], [ %33, %32 ]
  %27 = shl nuw nsw i32 2, %26
  %28 = and i32 %27, %22
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %32, label %30

30:                                               ; preds = %25
  %31 = or disjoint i32 %26, 20
  br label %35

32:                                               ; preds = %25
  %33 = add nuw nsw i32 %26, 1
  %34 = icmp eq i32 %33, 3
  br i1 %34, label %35, label %25, !llvm.loop !9

35:                                               ; preds = %11, %32, %30
  %36 = phi i32 [ %23, %30 ], [ %23, %32 ], [ %12, %11 ]
  %37 = phi i32 [ %31, %30 ], [ 30, %32 ], [ 9, %11 ]
  %38 = shl nsw i32 %36, 8
  %39 = add nsw i32 %37, %38
  %40 = tail call i32 @cq_measure_si32(i32 noundef %39) #3
  ret i32 %40
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
!9 = distinct !{!9, !7, !8}
