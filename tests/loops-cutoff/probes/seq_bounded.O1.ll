; ModuleID = 'seq_bounded.c'
source_filename = "seq_bounded.c"
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
  br label %16

13:                                               ; preds = %16
  %14 = add nuw nsw i32 %17, 1
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %24, label %16, !llvm.loop !6

16:                                               ; preds = %1, %13
  %17 = phi i32 [ 0, %1 ], [ %14, %13 ]
  %18 = shl nuw nsw i32 1, %17
  %19 = and i32 %18, %12
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %13, label %29

21:                                               ; preds = %24
  %22 = add nuw nsw i32 %25, 1
  %23 = icmp eq i32 %22, 3
  br i1 %23, label %29, label %24, !llvm.loop !9

24:                                               ; preds = %13, %21
  %25 = phi i32 [ %22, %21 ], [ 0, %13 ]
  %26 = shl nuw nsw i32 2, %25
  %27 = and i32 %26, %12
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %21, label %29

29:                                               ; preds = %16, %21, %24
  %30 = phi i32 [ 3, %24 ], [ 40, %21 ], [ 2, %16 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #3
  ret i32 %31
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
