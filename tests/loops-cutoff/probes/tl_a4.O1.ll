; ModuleID = 'a4.c'
source_filename = "a4.c"
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
  %11 = and i32 %0, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %24, label %13

13:                                               ; preds = %1
  br i1 %2, label %14, label %25

14:                                               ; preds = %13, %19
  %15 = phi i32 [ %21, %19 ], [ 0, %13 ]
  %16 = phi i32 [ %20, %19 ], [ %10, %13 ]
  %17 = icmp eq i32 %15, 1
  %18 = select i1 %3, i1 %17, i1 false
  br i1 %18, label %43, label %19

19:                                               ; preds = %14
  %20 = lshr i32 %16, 1
  %21 = add nuw nsw i32 %15, 1
  %22 = and i32 %16, 2
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %25, label %14, !llvm.loop !6

24:                                               ; preds = %1
  br i1 %3, label %43, label %25

25:                                               ; preds = %19, %13, %24
  %26 = phi i32 [ %10, %24 ], [ %10, %13 ], [ %20, %19 ]
  %27 = phi i32 [ 0, %24 ], [ 0, %13 ], [ %21, %19 ]
  br i1 %4, label %43, label %28

28:                                               ; preds = %25
  %29 = and i32 %0, 2
  %30 = icmp ne i32 %29, 0
  %31 = select i1 %30, i1 %5, i1 false
  br label %32

32:                                               ; preds = %28, %37
  %33 = phi i32 [ %38, %37 ], [ %26, %28 ]
  %34 = phi i32 [ %39, %37 ], [ %27, %28 ]
  %35 = and i32 %33, 2
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %43, label %37

37:                                               ; preds = %32
  %38 = lshr i32 %33, 1
  %39 = add nuw nsw i32 %34, 1
  br i1 %31, label %40, label %32, !llvm.loop !9

40:                                               ; preds = %37
  %41 = mul i32 %27, 10
  %42 = add i32 %41, 150
  br label %43

43:                                               ; preds = %14, %32, %25, %24, %40
  %44 = phi i32 [ %42, %40 ], [ 120, %24 ], [ 130, %25 ], [ 900, %32 ], [ 110, %14 ]
  %45 = phi i32 [ %39, %40 ], [ 0, %24 ], [ %27, %25 ], [ %34, %32 ], [ 1, %14 ]
  %46 = add nsw i32 %45, %44
  %47 = tail call i32 @cq_measure_si32(i32 noundef %46) #3
  ret i32 %47
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
