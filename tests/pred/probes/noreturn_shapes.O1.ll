; ModuleID = 'noreturn_shapes.c'
source_filename = "noreturn_shapes.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @two_tests(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = and i32 %2, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %6, label %5

5:                                                ; preds = %1
  tail call void @abort() #6
  unreachable

6:                                                ; preds = %1
  %7 = load i32, ptr @g, align 4, !tbaa !6
  %8 = add nsw i32 %7, 1
  store i32 %8, ptr @g, align 4, !tbaa !6
  %9 = and i32 %2, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %6
  tail call void @abort() #6
  unreachable

12:                                               ; preds = %6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #7
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @classical_inner(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %9

5:                                                ; preds = %2
  %6 = and i32 %1, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  tail call void @exit(i32 noundef 1) #8
  unreachable

9:                                                ; preds = %5, %2
  %10 = phi i32 [ 0, %2 ], [ 5, %5 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @in_arm(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = and i32 %2, 2
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %12, label %5

5:                                                ; preds = %1
  %6 = and i32 %2, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = load i32, ptr @g, align 4, !tbaa !6
  %10 = add nsw i32 %9, 1
  store i32 %10, ptr @g, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %8, %5
  tail call void @abort() #6
  unreachable

12:                                               ; preds = %1
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #7
  ret i32 %13
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @status_phi(i32 noundef %0) local_unnamed_addr #4 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = icmp eq i32 %2, 7
  br i1 %3, label %9, label %4

4:                                                ; preds = %1
  %5 = and i32 %2, -2
  %6 = icmp eq i32 %5, 14
  br i1 %6, label %11, label %7

7:                                                ; preds = %4
  %8 = load i32, ptr @g, align 4, !tbaa !6
  br label %13

9:                                                ; preds = %1
  tail call void @exit(i32 noundef 9) #8
  unreachable

10:                                               ; preds = %13
  store i32 %16, ptr @g, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %10, %4
  %12 = phi i32 [ %17, %10 ], [ 1, %4 ]
  tail call void @exit(i32 noundef %12) #8
  unreachable

13:                                               ; preds = %7, %13
  %14 = phi i32 [ %17, %13 ], [ 1, %7 ]
  %15 = phi i32 [ %16, %13 ], [ %8, %7 ]
  %16 = add nsw i32 %15, 1
  %17 = add nuw nsw i32 %14, 1
  %18 = ashr i32 %2, %17
  %19 = icmp eq i32 %18, 7
  br i1 %19, label %10, label %13, !llvm.loop !10
}

; Function Attrs: nounwind ssp uwtable
define i32 @siblings(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #5
  br label %5

5:                                                ; preds = %9, %2
  %6 = phi i32 [ 0, %2 ], [ %10, %9 ]
  %7 = ashr i32 %3, %6
  switch i32 %7, label %9 [
    i32 0, label %11
    i32 5, label %8
  ]

8:                                                ; preds = %5
  tail call void @abort() #6
  unreachable

9:                                                ; preds = %5
  %10 = add nuw nsw i32 %6, 1
  br label %5, !llvm.loop !12

11:                                               ; preds = %5, %18
  %12 = phi i32 [ %19, %18 ], [ %6, %5 ]
  %13 = phi i32 [ %20, %18 ], [ %7, %5 ]
  %14 = ashr i32 %4, %13
  switch i32 %14, label %18 [
    i32 0, label %15
    i32 5, label %17
  ]

15:                                               ; preds = %11
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  ret i32 %16

17:                                               ; preds = %11
  tail call void @abort() #6
  unreachable

18:                                               ; preds = %11
  %19 = add nuw nsw i32 %12, 2
  %20 = add nuw nsw i32 %13, 1
  br label %11, !llvm.loop !14
}

; Function Attrs: noreturn nounwind ssp uwtable
define noundef i32 @classical_guard(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = and i32 %1, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %11

6:                                                ; preds = %2
  %7 = and i32 %3, -2
  %8 = icmp eq i32 %7, 6
  br i1 %8, label %13, label %9

9:                                                ; preds = %6
  %10 = load i32, ptr @g, align 4, !tbaa !6
  br label %14

11:                                               ; preds = %2
  tail call void @exit(i32 noundef 0) #8
  unreachable

12:                                               ; preds = %14
  store i32 %17, ptr @g, align 4, !tbaa !6
  br label %13

13:                                               ; preds = %12, %6
  tail call void @exit(i32 noundef 0) #8
  unreachable

14:                                               ; preds = %9, %14
  %15 = phi i32 [ %18, %14 ], [ 1, %9 ]
  %16 = phi i32 [ %17, %14 ], [ %10, %9 ]
  %17 = add nsw i32 %16, 1
  %18 = add nuw nsw i32 %15, 1
  %19 = ashr i32 %3, %18
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %12, label %14, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @nested_inner(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #5
  %5 = icmp eq i32 %3, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %2, %16
  %7 = phi i32 [ %17, %16 ], [ 0, %2 ]
  %8 = phi i32 [ %13, %16 ], [ 0, %2 ]
  br label %12

9:                                                ; preds = %16, %2
  %10 = phi i32 [ 0, %2 ], [ %13, %16 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #7
  ret i32 %11

12:                                               ; preds = %6, %21
  %13 = phi i32 [ %22, %21 ], [ %8, %6 ]
  %14 = phi i32 [ %23, %21 ], [ 0, %6 ]
  %15 = ashr i32 %4, %14
  switch i32 %15, label %21 [
    i32 0, label %16
    i32 5, label %20
  ]

16:                                               ; preds = %12
  %17 = add nuw nsw i32 %7, 1
  %18 = ashr i32 %3, %17
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %9, label %6, !llvm.loop !16

20:                                               ; preds = %12
  tail call void @abort() #6
  unreachable

21:                                               ; preds = %12
  %22 = add nsw i32 %13, 1
  %23 = add nuw nsw i32 %14, 1
  br label %12, !llvm.loop !17
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @nested_no_live_exit(i32 noundef %0) local_unnamed_addr #4 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = load i32, ptr @g, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %14, %1
  %5 = phi i32 [ %3, %1 ], [ %15, %14 ]
  %6 = phi i32 [ 0, %1 ], [ %16, %14 ]
  %7 = ashr i32 %2, %6
  switch i32 %7, label %11 [
    i32 0, label %8
    i32 5, label %10
  ]

8:                                                ; preds = %4
  %9 = add nsw i32 %5, 2
  store i32 %9, ptr @g, align 4, !tbaa !6
  br label %14

10:                                               ; preds = %4
  tail call void @abort() #6
  unreachable

11:                                               ; preds = %4
  %12 = add nsw i32 %5, 1
  store i32 %12, ptr @g, align 4, !tbaa !6
  %13 = add nuw nsw i32 %6, 1
  br label %14

14:                                               ; preds = %11, %8
  %15 = phi i32 [ %12, %11 ], [ %9, %8 ]
  %16 = phi i32 [ %13, %11 ], [ 0, %8 ]
  br label %4, !llvm.loop !18
}

; Function Attrs: nounwind ssp uwtable
define i32 @nested_three(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e+00) #5
  %7 = icmp eq i32 %4, 0
  br i1 %7, label %13, label %8

8:                                                ; preds = %3
  %9 = icmp eq i32 %5, 0
  br label %10

10:                                               ; preds = %8, %19
  %11 = phi i32 [ 0, %8 ], [ %21, %19 ]
  %12 = phi i32 [ 0, %8 ], [ %20, %19 ]
  br i1 %9, label %19, label %16

13:                                               ; preds = %19, %3
  %14 = phi i32 [ 0, %3 ], [ %20, %19 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #7
  ret i32 %15

16:                                               ; preds = %10, %28
  %17 = phi i32 [ %29, %28 ], [ 0, %10 ]
  %18 = phi i32 [ %25, %28 ], [ %12, %10 ]
  br label %24

19:                                               ; preds = %28, %10
  %20 = phi i32 [ %12, %10 ], [ %25, %28 ]
  %21 = add nuw nsw i32 %11, 1
  %22 = ashr i32 %4, %21
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %13, label %10, !llvm.loop !19

24:                                               ; preds = %16, %33
  %25 = phi i32 [ %34, %33 ], [ %18, %16 ]
  %26 = phi i32 [ %35, %33 ], [ 0, %16 ]
  %27 = ashr i32 %6, %26
  switch i32 %27, label %33 [
    i32 0, label %28
    i32 5, label %32
  ]

28:                                               ; preds = %24
  %29 = add nuw nsw i32 %17, 1
  %30 = ashr i32 %5, %29
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %19, label %16, !llvm.loop !20

32:                                               ; preds = %24
  tail call void @abort() #6
  unreachable

33:                                               ; preds = %24
  %34 = add nsw i32 %25, 1
  %35 = add nuw nsw i32 %26, 1
  br label %24, !llvm.loop !21
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { cold noreturn nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !13, !11}
!13 = !{!"llvm.loop.mustprogress"}
!14 = distinct !{!14, !13, !11}
!15 = distinct !{!15, !11}
!16 = distinct !{!16, !13, !11}
!17 = distinct !{!17, !13, !11}
!18 = distinct !{!18, !11}
!19 = distinct !{!19, !13, !11}
!20 = distinct !{!20, !13, !11}
!21 = distinct !{!21, !13, !11}
