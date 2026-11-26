; ModuleID = 'me_seq.c'
source_filename = "me_seq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %2, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp ugt i32 %4, 2
  %8 = select i1 %6, i1 %7, i1 false
  br i1 %8, label %9, label %24

9:                                                ; preds = %3, %14
  %10 = phi i32 [ %18, %14 ], [ 0, %3 ]
  %11 = phi i32 [ %17, %14 ], [ 1, %3 ]
  %12 = phi i32 [ %15, %14 ], [ %4, %3 ]
  %13 = icmp eq i32 %12, 8
  br i1 %13, label %32, label %14

14:                                               ; preds = %9
  %15 = add i32 %12, -3
  %16 = mul i32 %11, 5
  %17 = add i32 %16, %15
  %18 = add nuw nsw i32 %10, 1
  %19 = shl nuw i32 2, %10
  %20 = and i32 %19, %2
  %21 = icmp ne i32 %20, 0
  %22 = icmp ugt i32 %15, 2
  %23 = and i1 %21, %22
  br i1 %23, label %9, label %24, !llvm.loop !6

24:                                               ; preds = %14, %3
  %25 = phi i32 [ %4, %3 ], [ %15, %14 ]
  %26 = phi i32 [ 1, %3 ], [ %17, %14 ]
  %27 = tail call i32 @cq_measure_ui32(i32 noundef %25) #4
  %28 = shl i32 %27, 12
  %29 = tail call i32 @cq_measure_ui32(i32 noundef %26) #4
  %30 = shl i32 %29, 4
  %31 = add i32 %30, %28
  br label %32

32:                                               ; preds = %9, %24
  %33 = phi i32 [ %31, %24 ], [ 77, %9 ]
  ret i32 %33
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @e0(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = icmp ugt i32 %4, 2
  br i1 %5, label %6, label %20

6:                                                ; preds = %3
  %7 = mul i32 %4, -1431655765
  %8 = add i32 %7, -1431655768
  %9 = add i32 %4, -3
  %10 = udiv i32 %9, 3
  %11 = icmp ugt i32 %8, %10
  br label %12

12:                                               ; preds = %6, %15
  %13 = phi i32 [ %18, %15 ], [ 1, %6 ]
  %14 = phi i32 [ %16, %15 ], [ %4, %6 ]
  br i1 %11, label %15, label %28

15:                                               ; preds = %12
  %16 = add i32 %14, -3
  %17 = mul i32 %13, 5
  %18 = add i32 %17, %16
  %19 = icmp ugt i32 %16, 2
  br i1 %19, label %12, label %20, !llvm.loop !9

20:                                               ; preds = %15, %3
  %21 = phi i32 [ %4, %3 ], [ %16, %15 ]
  %22 = phi i32 [ 1, %3 ], [ %18, %15 ]
  %23 = tail call i32 @cq_measure_ui32(i32 noundef %21) #4
  %24 = shl i32 %23, 12
  %25 = tail call i32 @cq_measure_ui32(i32 noundef %22) #4
  %26 = shl i32 %25, 4
  %27 = add i32 %26, %24
  br label %28

28:                                               ; preds = %12, %20
  %29 = phi i32 [ %27, %20 ], [ 77, %12 ]
  ret i32 %29
}

; Function Attrs: nounwind ssp uwtable
define i32 @ec(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %6 = icmp eq i32 %3, 0
  br i1 %6, label %26, label %7

7:                                                ; preds = %4
  %8 = add i32 %3, -1
  %9 = tail call i32 @llvm.umin.i32(i32 %2, i32 %8)
  br label %10

10:                                               ; preds = %7, %21
  %11 = phi i32 [ %22, %21 ], [ 0, %7 ]
  %12 = phi i32 [ %14, %21 ], [ 1, %7 ]
  %13 = mul i32 %12, 5
  %14 = add i32 %13, %5
  %15 = icmp eq i32 %11, %2
  br i1 %15, label %16, label %21

16:                                               ; preds = %10
  %17 = sub i32 %14, %9
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #4
  %19 = mul i32 %18, 7
  %20 = add i32 %19, %2
  br label %29

21:                                               ; preds = %10
  %22 = add nuw i32 %11, 1
  %23 = icmp eq i32 %22, %3
  br i1 %23, label %24, label %10, !llvm.loop !10

24:                                               ; preds = %21
  %25 = add i32 %14, 3
  br label %26

26:                                               ; preds = %24, %4
  %27 = phi i32 [ 4, %4 ], [ %25, %24 ]
  %28 = tail call i32 @cq_measure_ui32(i32 noundef %27) #4
  br label %29

29:                                               ; preds = %26, %16
  %30 = phi i32 [ %20, %16 ], [ %28, %26 ]
  ret i32 %30
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
