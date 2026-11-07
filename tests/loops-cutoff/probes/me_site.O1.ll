; ModuleID = 'me_site.c'
source_filename = "me_site.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = xor i1 %2, true
  %7 = select i1 %6, i1 true, i1 %3
  br i1 %7, label %26, label %8

8:                                                ; preds = %1
  %9 = select i1 %4, i32 4, i32 0
  %10 = select i1 %5, i32 8, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = select i1 %3, i32 2, i32 0
  %13 = zext i1 %2 to i32
  %14 = or disjoint i32 %12, %13
  %15 = or disjoint i32 %11, %14
  br label %16

16:                                               ; preds = %8, %16
  %17 = phi i32 [ %22, %16 ], [ 0, %8 ]
  %18 = phi i32 [ %20, %16 ], [ %15, %8 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #3
  %20 = lshr i32 %18, 1
  %21 = add i32 %17, 1
  %22 = add i32 %21, %19
  %23 = and i32 %18, 2
  %24 = icmp eq i32 %23, 0
  %25 = select i1 %24, i1 true, i1 %3
  br i1 %25, label %26, label %16, !llvm.loop !6

26:                                               ; preds = %16, %1
  %27 = phi i32 [ 0, %1 ], [ %22, %16 ]
  ret i32 %27
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = xor i1 %2, true
  %7 = select i1 %6, i1 true, i1 %5
  br i1 %7, label %26, label %8

8:                                                ; preds = %1
  %9 = select i1 %4, i32 4, i32 0
  %10 = select i1 %5, i32 8, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = select i1 %3, i32 2, i32 0
  %13 = zext i1 %2 to i32
  %14 = or disjoint i32 %12, %13
  %15 = or disjoint i32 %11, %14
  br label %16

16:                                               ; preds = %8, %16
  %17 = phi i32 [ %22, %16 ], [ 0, %8 ]
  %18 = phi i32 [ %20, %16 ], [ %15, %8 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #3
  %20 = lshr i32 %18, 1
  %21 = add i32 %17, 1
  %22 = add i32 %21, %19
  %23 = and i32 %18, 2
  %24 = icmp eq i32 %23, 0
  %25 = select i1 %24, i1 true, i1 %5
  br i1 %25, label %26, label %16, !llvm.loop !9

26:                                               ; preds = %16, %1
  %27 = phi i32 [ 0, %1 ], [ %22, %16 ]
  ret i32 %27
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
