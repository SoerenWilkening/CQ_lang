; ModuleID = 'arm_test.c'
source_filename = "arm_test.c"
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

13:                                               ; preds = %18, %1
  %14 = phi i32 [ %12, %1 ], [ %19, %18 ]
  %15 = phi i32 [ 0, %1 ], [ %20, %18 ]
  %16 = and i32 %14, 1
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %24, label %18

18:                                               ; preds = %13
  %19 = lshr i32 %14, 1
  %20 = add nuw nsw i32 %15, 1
  br i1 %5, label %21, label %13, !llvm.loop !6

21:                                               ; preds = %18
  %22 = and i32 %0, 1
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %35, label %32

24:                                               ; preds = %13
  %25 = and i32 %0, 2
  %26 = icmp eq i32 %25, 0
  %27 = select i1 %26, i1 true, i1 %4
  %28 = select i1 %26, i32 48, i32 34
  br i1 %27, label %35, label %29

29:                                               ; preds = %24
  %30 = and i32 %14, 2
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %35, label %32, !llvm.loop !9

32:                                               ; preds = %29, %21
  %33 = phi i32 [ 65, %21 ], [ 66, %29 ]
  %34 = phi i32 [ %20, %21 ], [ %15, %29 ]
  br label %35

35:                                               ; preds = %24, %21, %29, %32
  %36 = phi i32 [ %33, %32 ], [ 33, %21 ], [ 48, %29 ], [ %28, %24 ]
  %37 = phi i32 [ %34, %32 ], [ %20, %21 ], [ %15, %29 ], [ %15, %24 ]
  %38 = shl nsw i32 %37, 8
  %39 = add nuw nsw i32 %38, %36
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
