; ModuleID = 'diff_f1.c'
source_filename = "diff_f1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f1_while(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %9, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = add i32 %7, 3
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !6

13:                                               ; preds = %6, %2
  %14 = phi i32 [ %3, %2 ], [ %9, %6 ]
  %15 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %16 = add i32 %15, %14
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #3
  ret i32 %17
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f1_do(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %7, %4 ]
  %6 = lshr i32 %5, 1
  %7 = xor i32 %6, 5
  %8 = and i32 %5, 4
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %4, !llvm.loop !9

10:                                               ; preds = %4
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_for(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = icmp ugt i32 %3, 3
  br i1 %4, label %8, label %5

5:                                                ; preds = %8, %2
  %6 = phi i32 [ 0, %2 ], [ %11, %8 ]
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #3
  ret i32 %7

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %12, %8 ], [ %3, %2 ]
  %10 = phi i32 [ %11, %8 ], [ 0, %2 ]
  %11 = add i32 %9, %10
  %12 = lshr i32 %9, 2
  %13 = icmp ugt i32 %9, 15
  br i1 %13, label %8, label %5, !llvm.loop !10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_comp(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul i32 %5, 3
  %7 = add i32 %6, 1
  %8 = lshr i32 %5, 1
  %9 = and i32 %7, 4
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !11

11:                                               ; preds = %4
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %8) #3
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_load(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 7
  %5 = zext nneg i32 %4 to i64
  %6 = lshr i64 180, %5
  %7 = and i64 %6, 1
  %8 = icmp eq i64 %7, 0
  br i1 %8, label %9, label %19

9:                                                ; preds = %2, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %2 ]
  %11 = phi i32 [ %12, %9 ], [ %3, %2 ]
  %12 = add i32 %11, 3
  %13 = add i32 %10, 1
  %14 = and i32 %12, 7
  %15 = zext nneg i32 %14 to i64
  %16 = lshr i64 180, %15
  %17 = and i64 %16, 1
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %9, label %19, !llvm.loop !12

19:                                               ; preds = %9, %2
  %20 = phi i32 [ 0, %2 ], [ %13, %9 ]
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %20) #3
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_and(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = icmp ne i32 %1, 0
  %6 = and i32 %4, 1
  %7 = icmp ne i32 %6, 0
  %8 = select i1 %5, i1 %7, i1 false
  br i1 %8, label %9, label %18

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %12, %9 ], [ %4, %3 ]
  %12 = lshr i32 %11, 1
  %13 = add nuw i32 %10, 1
  %14 = icmp ult i32 %13, %1
  %15 = and i32 %11, 2
  %16 = icmp ne i32 %15, 0
  %17 = select i1 %14, i1 %16, i1 false
  br i1 %17, label %9, label %18, !llvm.loop !13

18:                                               ; preds = %9, %3
  %19 = phi i32 [ %4, %3 ], [ %12, %9 ]
  %20 = phi i32 [ 0, %3 ], [ %13, %9 ]
  %21 = xor i32 %20, %19
  %22 = tail call i32 @cq_measure_ui32(i32 noundef %21) #3
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_and2(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = and i32 %4, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp ne i32 %1, 0
  %8 = and i1 %6, %7
  br i1 %8, label %9, label %18

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %12, %9 ], [ %4, %3 ]
  %12 = lshr i32 %11, 1
  %13 = add nuw i32 %10, 1
  %14 = and i32 %11, 2
  %15 = icmp ne i32 %14, 0
  %16 = icmp ne i32 %13, %1
  %17 = select i1 %15, i1 %16, i1 false
  br i1 %17, label %9, label %18, !llvm.loop !14

18:                                               ; preds = %9, %3
  %19 = phi i32 [ %4, %3 ], [ %12, %9 ]
  %20 = phi i32 [ 0, %3 ], [ %13, %9 ]
  %21 = add i32 %20, %19
  %22 = tail call i32 @cq_measure_ui32(i32 noundef %21) #3
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_cmp2(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = and i32 %1, 15
  %6 = icmp ult i32 %4, %5
  br i1 %6, label %7, label %13

7:                                                ; preds = %3, %7
  %8 = phi i32 [ %11, %7 ], [ %5, %3 ]
  %9 = phi i32 [ %10, %7 ], [ %4, %3 ]
  %10 = add i32 %9, 2
  %11 = add i32 %8, -1
  %12 = icmp ult i32 %10, %11
  br i1 %12, label %7, label %13, !llvm.loop !15

13:                                               ; preds = %7, %3
  %14 = phi i32 [ %4, %3 ], [ %10, %7 ]
  %15 = phi i32 [ %5, %3 ], [ %11, %7 ]
  %16 = shl i32 %14, 4
  %17 = add i32 %16, %15
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #3
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @f1_or(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 9
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %9, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = add i32 %7, 1
  %11 = and i32 %8, 18
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !16

13:                                               ; preds = %6, %2
  %14 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  ret i32 %15
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
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
