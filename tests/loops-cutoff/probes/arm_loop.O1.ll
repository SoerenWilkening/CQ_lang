; ModuleID = 'arm_loop.c'
source_filename = "arm_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @al_arm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %13, %2
  %5 = phi i32 [ 0, %2 ], [ %9, %13 ]
  %6 = phi i32 [ 1, %2 ], [ %8, %13 ]
  %7 = mul nsw i32 %6, 3
  %8 = add nsw i32 %7, %5
  %9 = add nuw nsw i32 %5, 1
  %10 = shl i32 512, %5
  %11 = and i32 %10, %3
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %17

13:                                               ; preds = %4
  %14 = shl i32 2, %5
  %15 = and i32 %14, %3
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %26, label %4, !llvm.loop !6

17:                                               ; preds = %4, %17
  %18 = phi i32 [ %22, %17 ], [ %9, %4 ]
  %19 = shl i32 65536, %18
  %20 = and i32 %19, %3
  %21 = icmp eq i32 %20, 0
  %22 = add nuw nsw i32 %18, 1
  br i1 %21, label %23, label %17, !llvm.loop !9

23:                                               ; preds = %17
  %24 = mul nuw nsw i32 %18, 7
  %25 = add nsw i32 %24, %8
  br label %26

26:                                               ; preds = %13, %23
  %27 = phi i32 [ %25, %23 ], [ %8, %13 ]
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  ret i32 %28
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @al_nested_read(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %13, %2
  %5 = phi i32 [ 0, %2 ], [ %16, %13 ]
  %6 = phi i32 [ 0, %2 ], [ %15, %13 ]
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i32 [ %5, %4 ], [ %12, %7 ]
  %9 = shl i32 256, %8
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  %12 = add nuw nsw i32 %8, 1
  br i1 %11, label %13, label %7, !llvm.loop !10

13:                                               ; preds = %7
  %14 = mul nsw i32 %6, 5
  %15 = add nsw i32 %8, %14
  %16 = add nuw nsw i32 %5, 1
  %17 = shl i32 2, %5
  %18 = and i32 %17, %3
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %4, !llvm.loop !11

20:                                               ; preds = %13
  %21 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @al_nested_break(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %20, %2
  %5 = phi i32 [ 0, %2 ], [ %25, %20 ]
  %6 = phi i32 [ 1, %2 ], [ %24, %20 ]
  br label %7

7:                                                ; preds = %13, %4
  %8 = phi i32 [ %6, %4 ], [ %15, %13 ]
  %9 = phi i32 [ 0, %4 ], [ %16, %13 ]
  %10 = shl i32 4096, %9
  %11 = and i32 %10, %3
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %20

13:                                               ; preds = %7
  %14 = add i32 %8, %5
  %15 = add i32 %14, %9
  %16 = add nuw nsw i32 %9, 1
  %17 = shl i32 512, %9
  %18 = and i32 %17, %3
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %7, !llvm.loop !12

20:                                               ; preds = %7, %13
  %21 = phi i32 [ %8, %7 ], [ %15, %13 ]
  %22 = phi i32 [ %9, %7 ], [ %16, %13 ]
  %23 = mul nsw i32 %21, 3
  %24 = add nsw i32 %23, %22
  %25 = add nuw nsw i32 %5, 1
  %26 = shl i32 2, %5
  %27 = and i32 %26, %3
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %4, !llvm.loop !13

29:                                               ; preds = %20
  %30 = tail call i32 @cq_measure_si32(i32 noundef %24) #3
  ret i32 %30
}

; Function Attrs: nounwind ssp uwtable
define i32 @al_nested_multi(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %23, %2
  %5 = phi i32 [ 0, %2 ], [ %26, %23 ]
  %6 = phi i32 [ 1, %2 ], [ %25, %23 ]
  br label %7

7:                                                ; preds = %15, %4
  %8 = phi i32 [ 0, %4 ], [ %16, %15 ]
  %9 = shl i32 4096, %8
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %7
  %13 = mul nsw i32 %6, 7
  %14 = add nsw i32 %8, %13
  br label %23

15:                                               ; preds = %7
  %16 = add nuw nsw i32 %8, 1
  %17 = shl i32 512, %8
  %18 = and i32 %17, %3
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %7, !llvm.loop !14

20:                                               ; preds = %15
  %21 = mul nuw nsw i32 %16, 3
  %22 = add nsw i32 %21, %6
  br label %23

23:                                               ; preds = %20, %12
  %24 = phi i32 [ %14, %12 ], [ %22, %20 ]
  %25 = xor i32 %24, %5
  %26 = add nuw nsw i32 %5, 1
  %27 = shl i32 2, %5
  %28 = and i32 %27, %3
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %4, !llvm.loop !15

30:                                               ; preds = %23
  %31 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  ret i32 %31
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
