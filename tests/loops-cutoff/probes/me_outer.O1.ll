; ModuleID = 'me_outer.c'
source_filename = "me_outer.c"
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
  %8 = or disjoint i32 %6, %7
  %9 = select i1 %5, i32 8, i32 0
  %10 = or disjoint i32 %8, %9
  %11 = and i32 %0, 1
  %12 = add nuw nsw i32 %11, 1
  br label %14

13:                                               ; preds = %34
  ret i32 %35

14:                                               ; preds = %1, %34
  %15 = phi i32 [ 0, %1 ], [ %37, %34 ]
  %16 = phi i32 [ 0, %1 ], [ %35, %34 ]
  %17 = phi i32 [ %10, %1 ], [ %36, %34 ]
  br label %18

18:                                               ; preds = %25, %14
  %19 = phi i32 [ %17, %14 ], [ %26, %25 ]
  %20 = phi i32 [ 0, %14 ], [ %27, %25 ]
  %21 = icmp eq i32 %20, 1
  %22 = select i1 %5, i1 %21, i1 false
  br i1 %22, label %23, label %25

23:                                               ; preds = %18
  %24 = add nsw i32 %16, 100
  br label %34

25:                                               ; preds = %18
  %26 = lshr i32 %19, 1
  %27 = add nuw nsw i32 %20, 1
  %28 = and i32 %19, 2
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %18, !llvm.loop !6

30:                                               ; preds = %25
  %31 = add nuw i32 %27, %15
  %32 = tail call i32 @cq_measure_ui32(i32 noundef %31) #3
  %33 = add i32 %32, %16
  br label %34

34:                                               ; preds = %30, %23
  %35 = phi i32 [ %24, %23 ], [ %33, %30 ]
  %36 = xor i32 %17, %0
  %37 = add nuw nsw i32 %15, 1
  %38 = icmp eq i32 %15, %12
  br i1 %38, label %13, label %14, !llvm.loop !9
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

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
!9 = distinct !{!9, !7, !8}
