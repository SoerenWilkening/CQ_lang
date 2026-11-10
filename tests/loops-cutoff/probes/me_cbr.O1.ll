; ModuleID = 'me_cbr.c'
source_filename = "me_cbr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = zext i1 %2 to i32
  %7 = select i1 %4, i32 2, i32 0
  %8 = or disjoint i32 %7, %6
  %9 = xor i1 %2, true
  %10 = select i1 %9, i1 true, i1 %5
  br i1 %10, label %33, label %11

11:                                               ; preds = %1
  %12 = select i1 %3, i32 2, i32 0
  %13 = select i1 %4, i32 4, i32 0
  %14 = or disjoint i32 %12, %13
  %15 = select i1 %5, i32 8, i32 0
  %16 = or disjoint i32 %14, %15
  %17 = or disjoint i32 %16, %6
  %18 = and i32 %0, 1
  %19 = icmp eq i32 %18, 0
  br label %20

20:                                               ; preds = %11, %26
  %21 = phi i32 [ 0, %11 ], [ %29, %26 ]
  %22 = phi i32 [ %17, %11 ], [ %28, %26 ]
  br i1 %19, label %26, label %23

23:                                               ; preds = %20
  %24 = tail call i32 @cq_measure_ui32(i32 noundef %8) #3
  %25 = add i32 %24, %21
  br label %26

26:                                               ; preds = %23, %20
  %27 = phi i32 [ %25, %23 ], [ %21, %20 ]
  %28 = lshr i32 %22, 1
  %29 = add nsw i32 %27, 1
  %30 = and i32 %22, 2
  %31 = icmp eq i32 %30, 0
  %32 = select i1 %31, i1 true, i1 %5
  br i1 %32, label %33, label %20, !llvm.loop !6

33:                                               ; preds = %26, %1
  %34 = phi i32 [ 0, %1 ], [ %29, %26 ]
  ret i32 %34
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = and i32 %0, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %12, label %6

6:                                                ; preds = %1
  %7 = zext i1 %2 to i32
  %8 = select i1 %3, i32 2, i32 0
  %9 = or disjoint i32 %8, %7
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #3
  %11 = add nsw i32 %10, 1
  br label %12

12:                                               ; preds = %6, %1
  %13 = phi i32 [ %11, %6 ], [ 1, %1 ]
  ret i32 %13
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
