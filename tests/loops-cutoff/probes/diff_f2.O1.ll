; ModuleID = 'diff_f2.c'
source_filename = "diff_f2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f2_xor(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  br label %5

5:                                                ; preds = %5, %3
  %6 = phi i32 [ %4, %3 ], [ %8, %5 ]
  %7 = phi i32 [ %1, %3 ], [ %10, %5 ]
  %8 = xor i32 %7, %6
  %9 = shl i32 %7, 1
  %10 = or disjoint i32 %9, 1
  %11 = and i32 %8, 4
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %5, !llvm.loop !6

13:                                               ; preds = %5
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %8) #3
  ret i32 %14
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f2_addc(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 2
  %7 = icmp eq i32 %6, 0
  %8 = add i32 %5, 7
  br i1 %7, label %9, label %4, !llvm.loop !9

9:                                                ; preds = %4
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %5) #3
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_sq(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %7, %4 ]
  %6 = mul i32 %5, %5
  %7 = add i32 %6, 1
  %8 = and i32 %7, 2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %4, !llvm.loop !10

10:                                               ; preds = %4
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_shr(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !11

9:                                                ; preds = %4
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %5) #3
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_swap(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  br label %5

5:                                                ; preds = %5, %3
  %6 = phi i32 [ %1, %3 ], [ %7, %5 ]
  %7 = phi i32 [ %4, %3 ], [ %8, %5 ]
  %8 = add i32 %6, 1
  %9 = xor i32 %8, %7
  %10 = and i32 %9, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %5, !llvm.loop !12

12:                                               ; preds = %5
  %13 = mul i32 %8, 7
  %14 = add i32 %13, %7
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #3
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_qarm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %11, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %10, %4 ]
  %7 = and i32 %5, 2
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, i32 0, i32 %5
  %10 = add i32 %9, %6
  %11 = lshr i32 %5, 1
  br i1 %8, label %12, label %4, !llvm.loop !13

12:                                               ; preds = %4
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %10) #3
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_carm(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = and i32 %1, 1
  %6 = icmp eq i32 %5, 0
  br label %7

7:                                                ; preds = %7, %3
  %8 = phi i32 [ %4, %3 ], [ %13, %7 ]
  %9 = phi i32 [ 1, %3 ], [ %12, %7 ]
  %10 = mul i32 %9, 3
  %11 = add i32 %10, %8
  %12 = select i1 %6, i32 %9, i32 %11
  %13 = lshr i32 %8, 1
  %14 = and i32 %8, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %7, !llvm.loop !14

16:                                               ; preds = %7
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %12) #3
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_counter(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = add nuw i32 %9, 4
  %11 = add i32 %7, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !15

14:                                               ; preds = %6, %2
  %15 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %16 = phi i32 [ 0, %2 ], [ %11, %6 ]
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %16) #3
  %19 = add i32 %18, %17
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f2_const_init(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %17, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ 9, %2 ]
  %8 = phi i32 [ %10, %6 ], [ 5, %2 ]
  %9 = phi i32 [ %12, %6 ], [ %3, %2 ]
  %10 = add i32 %7, %8
  %11 = xor i32 %7, %9
  %12 = lshr i32 %9, 1
  %13 = and i32 %9, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %6, !llvm.loop !16

15:                                               ; preds = %6
  %16 = sub i32 %10, %11
  br label %17

17:                                               ; preds = %15, %2
  %18 = phi i32 [ -4, %2 ], [ %16, %15 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #3
  ret i32 %19
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
