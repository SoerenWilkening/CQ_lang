; ModuleID = 'conjunct_nest.c'
source_filename = "conjunct_nest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cn_guard(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = and i32 %3, 3
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %4
  %9 = and i32 %2, 1
  %10 = icmp ne i32 %9, 0
  br label %14

11:                                               ; preds = %33, %4
  %12 = phi i32 [ 1, %4 ], [ %34, %33 ]
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #3
  ret i32 %13

14:                                               ; preds = %8, %33
  %15 = phi i32 [ 0, %8 ], [ %35, %33 ]
  %16 = phi i32 [ 1, %8 ], [ %34, %33 ]
  %17 = add i32 %15, %5
  %18 = icmp ugt i32 %17, 2
  %19 = select i1 %10, i1 %18, i1 false
  br i1 %19, label %20, label %33

20:                                               ; preds = %14, %20
  %21 = phi i32 [ %27, %20 ], [ 0, %14 ]
  %22 = phi i32 [ %24, %20 ], [ %17, %14 ]
  %23 = phi i32 [ %26, %20 ], [ %16, %14 ]
  %24 = add i32 %22, -3
  %25 = mul i32 %23, 5
  %26 = add i32 %24, %25
  %27 = add nuw nsw i32 %21, 1
  %28 = shl nuw i32 2, %21
  %29 = and i32 %28, %2
  %30 = icmp ne i32 %29, 0
  %31 = icmp ugt i32 %24, 2
  %32 = select i1 %30, i1 %31, i1 false
  br i1 %32, label %20, label %33, !llvm.loop !6

33:                                               ; preds = %20, %14
  %34 = phi i32 [ %16, %14 ], [ %26, %20 ]
  %35 = add nuw nsw i32 %15, 1
  %36 = icmp eq i32 %35, %6
  br i1 %36, label %11, label %14, !llvm.loop !9
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @cn_do(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = and i32 %3, 3
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %11

8:                                                ; preds = %28, %4
  %9 = phi i32 [ 1, %4 ], [ %21, %28 ]
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #3
  ret i32 %10

11:                                               ; preds = %4, %28
  %12 = phi i32 [ %29, %28 ], [ 0, %4 ]
  %13 = phi i32 [ %21, %28 ], [ 1, %4 ]
  %14 = add i32 %12, %5
  br label %15

15:                                               ; preds = %15, %11
  %16 = phi i32 [ %13, %11 ], [ %21, %15 ]
  %17 = phi i32 [ %14, %11 ], [ %19, %15 ]
  %18 = phi i32 [ 0, %11 ], [ %22, %15 ]
  %19 = add i32 %17, -3
  %20 = mul i32 %16, 5
  %21 = add i32 %19, %20
  %22 = add nuw nsw i32 %18, 1
  %23 = shl nuw i32 2, %18
  %24 = and i32 %23, %2
  %25 = icmp ne i32 %24, 0
  %26 = icmp ugt i32 %19, 2
  %27 = select i1 %25, i1 %26, i1 false
  br i1 %27, label %15, label %28, !llvm.loop !10

28:                                               ; preds = %15
  %29 = add nuw nsw i32 %12, 1
  %30 = icmp eq i32 %29, %6
  br i1 %30, label %8, label %11, !llvm.loop !11
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
