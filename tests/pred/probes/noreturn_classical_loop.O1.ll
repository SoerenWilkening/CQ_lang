; ModuleID = 'noreturn_classical_loop.c'
source_filename = "noreturn_classical_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @top(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  br label %5

3:                                                ; preds = %10
  %4 = tail call i32 @cq_measure_si32(i32 noundef 3) #6
  ret i32 %4

5:                                                ; preds = %1, %10
  %6 = phi i32 [ 0, %1 ], [ %11, %10 ]
  %7 = ashr i32 %2, %6
  %8 = icmp eq i32 %7, 5
  br i1 %8, label %9, label %10

9:                                                ; preds = %5
  tail call void @abort() #7
  unreachable

10:                                               ; preds = %5
  %11 = add nuw nsw i32 %6, 1
  %12 = icmp eq i32 %11, 3
  br i1 %12, label %3, label %5, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @value(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  br label %5

3:                                                ; preds = %11
  %4 = tail call i32 @cq_measure_si32(i32 noundef %12) #6
  ret i32 %4

5:                                                ; preds = %1, %11
  %6 = phi i32 [ 0, %1 ], [ %13, %11 ]
  %7 = phi i32 [ 0, %1 ], [ %12, %11 ]
  %8 = ashr i32 %2, %6
  %9 = icmp eq i32 %8, 5
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @abort() #7
  unreachable

11:                                               ; preds = %5
  %12 = add nsw i32 %8, %7
  %13 = add nuw nsw i32 %6, 1
  %14 = icmp eq i32 %13, 3
  br i1 %14, label %3, label %5, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @live_exit(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %14

5:                                                ; preds = %2, %10
  %6 = phi i32 [ %12, %10 ], [ 0, %2 ]
  %7 = phi i32 [ %11, %10 ], [ 0, %2 ]
  %8 = ashr i32 %3, %6
  switch i32 %8, label %10 [
    i32 5, label %9
    i32 2, label %14
  ]

9:                                                ; preds = %5
  tail call void @abort() #7
  unreachable

10:                                               ; preds = %5
  %11 = add nuw nsw i32 %6, %7
  %12 = add nuw nsw i32 %6, 1
  %13 = icmp eq i32 %12, %1
  br i1 %13, label %14, label %5, !llvm.loop !10

14:                                               ; preds = %10, %5, %2
  %15 = phi i32 [ 0, %2 ], [ %11, %10 ], [ %7, %5 ]
  %16 = add nsw i32 %15, %3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @in_classical_arm(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %17, %2
  %6 = phi i32 [ %3, %2 ], [ %18, %17 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #6
  ret i32 %7

8:                                                ; preds = %2, %17
  %9 = phi i32 [ %19, %17 ], [ 0, %2 ]
  %10 = phi i32 [ %18, %17 ], [ %3, %2 ]
  %11 = and i32 %9, 1
  %12 = icmp ne i32 %11, 0
  %13 = ashr i32 %3, %9
  %14 = icmp eq i32 %13, 5
  %15 = select i1 %12, i1 %14, i1 false
  br i1 %15, label %16, label %17

16:                                               ; preds = %8
  tail call void @abort() #7
  unreachable

17:                                               ; preds = %8
  %18 = add nsw i32 %9, %10
  %19 = add nuw nsw i32 %9, 1
  %20 = icmp eq i32 %19, %1
  br i1 %20, label %5, label %8, !llvm.loop !11
}

; Function Attrs: nounwind ssp uwtable
define i32 @classical_test(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %18

6:                                                ; preds = %3, %14
  %7 = phi i32 [ %16, %14 ], [ 0, %3 ]
  %8 = phi i32 [ %15, %14 ], [ 0, %3 ]
  %9 = icmp eq i32 %7, %2
  br i1 %9, label %10, label %11

10:                                               ; preds = %6
  tail call void @exit(i32 noundef 1) #8
  unreachable

11:                                               ; preds = %6
  %12 = ashr i32 %4, %7
  %13 = icmp eq i32 %12, 2
  br i1 %13, label %18, label %14

14:                                               ; preds = %11
  %15 = add nuw nsw i32 %7, %8
  %16 = add nuw nsw i32 %7, 1
  %17 = icmp eq i32 %16, %1
  br i1 %17, label %18, label %6, !llvm.loop !12

18:                                               ; preds = %14, %11, %3
  %19 = phi i32 [ 0, %3 ], [ %15, %14 ], [ %8, %11 ]
  %20 = add nsw i32 %19, %4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #6
  ret i32 %21
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @classical_switch(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %15, %3
  %7 = phi i32 [ %4, %3 ], [ %16, %15 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #6
  ret i32 %8

9:                                                ; preds = %3, %15
  %10 = phi i32 [ %17, %15 ], [ 0, %3 ]
  %11 = phi i32 [ %16, %15 ], [ %4, %3 ]
  %12 = sub nsw i32 %10, %2
  switch i32 %12, label %15 [
    i32 2, label %13
    i32 7, label %14
  ]

13:                                               ; preds = %9
  tail call void @exit(i32 noundef 1) #8
  unreachable

14:                                               ; preds = %9
  tail call void @exit(i32 noundef 2) #8
  unreachable

15:                                               ; preds = %9
  %16 = add nsw i32 %10, %11
  %17 = add nuw nsw i32 %10, 1
  %18 = icmp eq i32 %17, %1
  br i1 %18, label %6, label %9, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @classical_switch_arm(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %5 = and i32 %4, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp sgt i32 %1, 0
  %8 = and i1 %6, %7
  br i1 %8, label %9, label %19

9:                                                ; preds = %3, %15
  %10 = phi i32 [ %17, %15 ], [ 0, %3 ]
  %11 = phi i32 [ %16, %15 ], [ %4, %3 ]
  %12 = sub nsw i32 %10, %2
  switch i32 %12, label %15 [
    i32 2, label %13
    i32 7, label %14
  ]

13:                                               ; preds = %9
  tail call void @exit(i32 noundef 1) #8
  unreachable

14:                                               ; preds = %9
  tail call void @exit(i32 noundef 2) #8
  unreachable

15:                                               ; preds = %9
  %16 = add nsw i32 %10, %11
  %17 = add nuw nsw i32 %10, 1
  %18 = icmp eq i32 %17, %1
  br i1 %18, label %19, label %9, !llvm.loop !14

19:                                               ; preds = %15, %3
  %20 = phi i32 [ %4, %3 ], [ %16, %15 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #6
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @under_arm(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = and i32 %3, 1
  %5 = icmp ne i32 %4, 0
  %6 = icmp sgt i32 %1, 0
  %7 = and i1 %5, %6
  br i1 %7, label %8, label %22

8:                                                ; preds = %2
  %9 = mul i32 %3, %1
  br label %10

10:                                               ; preds = %8, %19
  %11 = phi i32 [ %20, %19 ], [ 0, %8 ]
  %12 = ashr i32 %3, %11
  %13 = icmp eq i32 %12, 5
  br i1 %13, label %14, label %19

14:                                               ; preds = %10
  %15 = and i32 %3, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %18, label %17

17:                                               ; preds = %14
  tail call void @abort() #7
  unreachable

18:                                               ; preds = %14
  tail call void @exit(i32 noundef 2) #8
  unreachable

19:                                               ; preds = %10
  %20 = add nuw nsw i32 %11, 1
  %21 = icmp eq i32 %20, %1
  br i1 %21, label %22, label %10, !llvm.loop !15

22:                                               ; preds = %19, %2
  %23 = phi i32 [ 0, %2 ], [ %9, %19 ]
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #6
  ret i32 %24
}

; Function Attrs: noreturn nounwind ssp uwtable
define noundef i32 @no_live_exit(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  tail call void @exit(i32 noundef 0) #8
  unreachable
}

; Function Attrs: nounwind ssp uwtable
define i32 @two_levels(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %13

6:                                                ; preds = %3
  %7 = icmp sgt i32 %2, 0
  br label %8

8:                                                ; preds = %6, %16
  %9 = phi i32 [ 0, %6 ], [ %18, %16 ]
  %10 = phi i32 [ 0, %6 ], [ %17, %16 ]
  br i1 %7, label %11, label %16

11:                                               ; preds = %8
  %12 = ashr i32 %4, %9
  br label %20

13:                                               ; preds = %16, %3
  %14 = phi i32 [ 0, %3 ], [ %17, %16 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #6
  ret i32 %15

16:                                               ; preds = %26, %8
  %17 = phi i32 [ %10, %8 ], [ %28, %26 ]
  %18 = add nuw nsw i32 %9, 1
  %19 = icmp eq i32 %18, %1
  br i1 %19, label %13, label %8, !llvm.loop !16

20:                                               ; preds = %11, %26
  %21 = phi i32 [ 0, %11 ], [ %29, %26 ]
  %22 = phi i32 [ %10, %11 ], [ %28, %26 ]
  %23 = xor i32 %21, %12
  %24 = icmp eq i32 %23, 5
  br i1 %24, label %25, label %26

25:                                               ; preds = %20
  tail call void @abort() #7
  unreachable

26:                                               ; preds = %20
  %27 = ashr i32 %4, %21
  %28 = add nsw i32 %27, %22
  %29 = add nuw nsw i32 %21, 1
  %30 = icmp eq i32 %29, %2
  br i1 %30, label %16, label %20, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @in_k_loop(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %23, label %4

4:                                                ; preds = %1, %9
  %5 = phi i32 [ %11, %9 ], [ %2, %1 ]
  %6 = phi i32 [ %10, %9 ], [ 0, %1 ]
  %7 = phi i32 [ %8, %9 ], [ 0, %1 ]
  %8 = add nuw nsw i32 %7, 3
  br label %15

9:                                                ; preds = %20
  %10 = add nuw nsw i32 %6, 1
  %11 = ashr i32 %2, %10
  %12 = icmp ne i32 %11, 0
  %13 = icmp ult i32 %6, 8
  %14 = and i1 %13, %12
  br i1 %14, label %4, label %23, !llvm.loop !18

15:                                               ; preds = %4, %20
  %16 = phi i32 [ 0, %4 ], [ %21, %20 ]
  %17 = xor i32 %16, %5
  %18 = icmp eq i32 %17, 5
  br i1 %18, label %19, label %20

19:                                               ; preds = %15
  tail call void @abort() #7
  unreachable

20:                                               ; preds = %15
  %21 = add nuw nsw i32 %16, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %9, label %15, !llvm.loop !19

23:                                               ; preds = %9, %1
  %24 = phi i32 [ 0, %1 ], [ %8, %9 ]
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #6
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @guarded_in_k_loop(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %26, label %5

5:                                                ; preds = %2
  %6 = icmp sgt i32 %1, 0
  br label %7

7:                                                ; preds = %5, %21
  %8 = phi i32 [ %3, %5 ], [ %24, %21 ]
  %9 = phi i32 [ 0, %5 ], [ %23, %21 ]
  %10 = phi i32 [ 0, %5 ], [ %22, %21 ]
  br i1 %6, label %11, label %21

11:                                               ; preds = %7, %17
  %12 = phi i32 [ %19, %17 ], [ 0, %7 ]
  %13 = phi i32 [ %18, %17 ], [ %10, %7 ]
  %14 = xor i32 %12, %8
  %15 = icmp eq i32 %14, 5
  br i1 %15, label %16, label %17

16:                                               ; preds = %11
  tail call void @abort() #7
  unreachable

17:                                               ; preds = %11
  %18 = add nsw i32 %12, %13
  %19 = add nuw nsw i32 %12, 1
  %20 = icmp eq i32 %19, %1
  br i1 %20, label %21, label %11, !llvm.loop !20

21:                                               ; preds = %17, %7
  %22 = phi i32 [ %10, %7 ], [ %18, %17 ]
  %23 = add nuw nsw i32 %9, 1
  %24 = ashr i32 %3, %23
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %26, label %7, !llvm.loop !21

26:                                               ; preds = %21, %2
  %27 = phi i32 [ 0, %2 ], [ %22, %21 ]
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #6
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_in_classical_in_k(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %30, label %4

4:                                                ; preds = %1, %12
  %5 = phi i32 [ %13, %12 ], [ 0, %1 ]
  %6 = phi i32 [ %27, %12 ], [ 0, %1 ]
  br label %7

7:                                                ; preds = %4, %25
  %8 = phi i32 [ 0, %4 ], [ %28, %25 ]
  %9 = phi i32 [ %6, %4 ], [ %27, %25 ]
  %10 = ashr i32 %2, %8
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %25, label %16

12:                                               ; preds = %25
  %13 = add nuw nsw i32 %5, 1
  %14 = ashr i32 %2, %13
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %30, label %4, !llvm.loop !22

16:                                               ; preds = %7, %21
  %17 = phi i32 [ %22, %21 ], [ 0, %7 ]
  %18 = xor i32 %17, %2
  %19 = icmp eq i32 %18, 9
  br i1 %19, label %20, label %21

20:                                               ; preds = %16
  tail call void @abort() #7
  unreachable

21:                                               ; preds = %16
  %22 = add nuw nsw i32 %17, 1
  %23 = ashr i32 %10, %22
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %16, !llvm.loop !23

25:                                               ; preds = %21, %7
  %26 = phi i32 [ 0, %7 ], [ %22, %21 ]
  %27 = add nsw i32 %26, %9
  %28 = add nuw nsw i32 %8, 1
  %29 = icmp eq i32 %8, 0
  br i1 %29, label %7, label %12, !llvm.loop !24

30:                                               ; preds = %12, %1
  %31 = phi i32 [ 0, %1 ], [ %27, %12 ]
  %32 = tail call i32 @cq_measure_si32(i32 noundef %31) #6
  ret i32 %32
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
attributes #7 = { cold noreturn nounwind }
attributes #8 = { noreturn nounwind }

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
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
!21 = distinct !{!21, !7, !8}
!22 = distinct !{!22, !7, !8}
!23 = distinct !{!23, !7, !8}
!24 = distinct !{!24, !7, !8}
