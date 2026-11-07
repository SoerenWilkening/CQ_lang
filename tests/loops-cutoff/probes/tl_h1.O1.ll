; ModuleID = 'h1.c'
source_filename = "h1.c"
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
  %14 = icmp eq i32 %12, 1
  %15 = select i1 %5, i1 %14, i1 false
  br i1 %15, label %42, label %16

16:                                               ; preds = %11
  %17 = lshr i32 %13, 1
  %18 = add nuw nsw i32 %12, 1
  %19 = and i32 %13, 2
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %11, !llvm.loop !6

21:                                               ; preds = %16, %1
  %22 = phi i32 [ %10, %1 ], [ %17, %16 ]
  %23 = phi i32 [ 0, %1 ], [ %18, %16 ]
  %24 = select i1 %4, i1 true, i1 %3
  %25 = select i1 %4, i32 6, i32 7
  br i1 %24, label %39, label %26

26:                                               ; preds = %21, %31
  %27 = phi i32 [ %33, %31 ], [ 0, %21 ]
  %28 = phi i32 [ %32, %31 ], [ %22, %21 ]
  %29 = and i32 %28, 2
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %34, label %31

31:                                               ; preds = %26
  %32 = lshr i32 %28, 1
  %33 = add nuw nsw i32 %27, 1
  br i1 %2, label %36, label %26, !llvm.loop !9

34:                                               ; preds = %26
  %35 = add nuw nsw i32 %27, 8
  br label %36

36:                                               ; preds = %31, %34
  %37 = phi i32 [ %35, %34 ], [ %33, %31 ]
  %38 = phi i32 [ 0, %34 ], [ 5, %31 ]
  switch i32 %38, label %48 [
    i32 0, label %39
    i32 5, label %39
  ]

39:                                               ; preds = %21, %36, %36
  %40 = phi i32 [ %37, %36 ], [ %37, %36 ], [ %25, %21 ]
  %41 = add nsw i32 %40, 16
  br label %42

42:                                               ; preds = %11, %39
  %43 = phi i32 [ %23, %39 ], [ %12, %11 ]
  %44 = phi i32 [ %41, %39 ], [ 100, %11 ]
  %45 = shl nsw i32 %43, 8
  %46 = add nsw i32 %44, %45
  %47 = tail call i32 @cq_measure_si32(i32 noundef %46) #3
  br label %48

48:                                               ; preds = %42, %36
  %49 = phi i32 [ %47, %42 ], [ undef, %36 ]
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
