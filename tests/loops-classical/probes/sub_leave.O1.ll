; ModuleID = 'sub_leave.c'
source_filename = "sub_leave.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sl_goto(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %33

7:                                                ; preds = %4
  %8 = icmp sgt i32 %3, 0
  br label %12

9:                                                ; preds = %29
  %10 = add nuw nsw i32 %13, 1
  %11 = icmp eq i32 %10, %2
  br i1 %11, label %33, label %12, !llvm.loop !6

12:                                               ; preds = %7, %9
  %13 = phi i32 [ 0, %7 ], [ %10, %9 ]
  %14 = phi i32 [ 0, %7 ], [ %30, %9 ]
  %15 = shl nsw i32 %13, 2
  br i1 %8, label %19, label %29

16:                                               ; preds = %19
  %17 = add nuw nsw i32 %24, %15
  %18 = icmp eq i32 %17, 9
  br i1 %18, label %26, label %19, !llvm.loop !9

19:                                               ; preds = %12, %16
  %20 = phi i32 [ %23, %16 ], [ %14, %12 ]
  %21 = phi i32 [ %24, %16 ], [ 0, %12 ]
  %22 = xor i32 %21, %5
  %23 = add nsw i32 %22, %20
  %24 = add nuw nsw i32 %21, 1
  %25 = icmp eq i32 %24, %3
  br i1 %25, label %26, label %16, !llvm.loop !9

26:                                               ; preds = %16, %19
  %27 = phi i32 [ 5, %19 ], [ 8, %16 ]
  %28 = icmp slt i32 %24, %3
  br label %29

29:                                               ; preds = %26, %12
  %30 = phi i32 [ %14, %12 ], [ %23, %26 ]
  %31 = phi i1 [ %8, %12 ], [ %28, %26 ]
  %32 = phi i32 [ 5, %12 ], [ %27, %26 ]
  br i1 %31, label %33, label %9

33:                                               ; preds = %29, %9, %4
  %34 = phi i32 [ 0, %4 ], [ %30, %9 ], [ %30, %29 ]
  %35 = phi i32 [ 2, %4 ], [ %32, %29 ], [ 2, %9 ]
  switch i32 %35, label %38 [
    i32 2, label %36
    i32 8, label %36
  ]

36:                                               ; preds = %33, %33
  %37 = tail call i32 @cq_measure_si32(i32 noundef %34) #3
  br label %38

38:                                               ; preds = %36, %33
  %39 = phi i32 [ undef, %33 ], [ %37, %36 ]
  ret i32 %39
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @sl_nest(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %8, label %13

8:                                                ; preds = %5
  %9 = icmp sgt i32 %3, 0
  br label %10

10:                                               ; preds = %8, %16
  %11 = phi i32 [ 0, %8 ], [ %18, %16 ]
  %12 = phi i32 [ 0, %8 ], [ %17, %16 ]
  br i1 %9, label %20, label %16

13:                                               ; preds = %16, %5
  %14 = phi i32 [ 0, %5 ], [ %17, %16 ]
  %15 = icmp eq i32 %4, 3
  br i1 %15, label %29, label %27

16:                                               ; preds = %20, %10
  %17 = phi i32 [ %12, %10 ], [ %24, %20 ]
  %18 = add nuw nsw i32 %11, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %13, label %10, !llvm.loop !10

20:                                               ; preds = %10, %20
  %21 = phi i32 [ %25, %20 ], [ 0, %10 ]
  %22 = phi i32 [ %24, %20 ], [ %12, %10 ]
  %23 = xor i32 %21, %6
  %24 = add nsw i32 %23, %22
  %25 = add nuw nsw i32 %21, 1
  %26 = icmp eq i32 %25, %3
  br i1 %26, label %16, label %20, !llvm.loop !11

27:                                               ; preds = %13
  %28 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  br label %29

29:                                               ; preds = %13, %27
  %30 = phi i32 [ %28, %27 ], [ 7, %13 ]
  ret i32 %30
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
