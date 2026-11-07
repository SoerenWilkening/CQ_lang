; ModuleID = 'a1.c'
source_filename = "a1.c"
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
  %13 = and i32 %0, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %35

15:                                               ; preds = %1
  %16 = and i32 %0, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %20, label %18

18:                                               ; preds = %25, %15
  %19 = icmp eq i32 %8, 0
  br i1 %19, label %35, label %28

20:                                               ; preds = %15, %25
  %21 = phi i32 [ %26, %25 ], [ %16, %15 ]
  %22 = shl nuw nsw i32 1, %21
  %23 = and i32 %22, %8
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %47, label %25

25:                                               ; preds = %20
  %26 = add nuw nsw i32 %21, 1
  %27 = icmp eq i32 %21, 0
  br i1 %27, label %20, label %18, !llvm.loop !6

28:                                               ; preds = %18, %28
  %29 = phi i32 [ %32, %28 ], [ 100, %18 ]
  %30 = phi i32 [ %31, %28 ], [ %12, %18 ]
  %31 = lshr i32 %30, 1
  %32 = add nuw nsw i32 %29, 1
  %33 = and i32 %30, 6
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %35, label %28, !llvm.loop !9

35:                                               ; preds = %28, %18, %1
  %36 = phi i32 [ %12, %1 ], [ %12, %18 ], [ %31, %28 ]
  %37 = phi i32 [ 100, %1 ], [ 100, %18 ], [ %32, %28 ]
  %38 = and i32 %36, 1
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %47, label %40

40:                                               ; preds = %35, %40
  %41 = phi i32 [ %44, %40 ], [ %37, %35 ]
  %42 = phi i32 [ %43, %40 ], [ %36, %35 ]
  %43 = lshr i32 %42, 1
  %44 = add nuw nsw i32 %41, 10
  %45 = and i32 %42, 2
  %46 = icmp eq i32 %45, 0
  br i1 %46, label %47, label %40, !llvm.loop !10

47:                                               ; preds = %20, %40, %35
  %48 = phi i32 [ %37, %35 ], [ %44, %40 ], [ %21, %20 ]
  %49 = tail call i32 @cq_measure_si32(i32 noundef %48) #3
  ret i32 %49
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
!10 = distinct !{!10, !7, !8}
