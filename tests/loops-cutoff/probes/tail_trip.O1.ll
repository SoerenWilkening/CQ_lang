; ModuleID = 'tail_trip.c'
source_filename = "tail_trip.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @tt_skip(i32 noundef %0) local_unnamed_addr #0 {
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
  %13 = and i32 %0, 1
  %14 = add nuw nsw i32 %13, 1
  br label %15

15:                                               ; preds = %1, %39
  %16 = phi i32 [ 0, %1 ], [ %42, %39 ]
  %17 = phi i32 [ 0, %1 ], [ %40, %39 ]
  %18 = phi i32 [ %12, %1 ], [ %41, %39 ]
  %19 = and i32 %18, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %35, label %23

21:                                               ; preds = %39
  %22 = tail call i32 @cq_measure_si32(i32 noundef %40) #3
  ret i32 %22

23:                                               ; preds = %15, %30
  %24 = phi i32 [ %32, %30 ], [ 0, %15 ]
  %25 = phi i32 [ %31, %30 ], [ %18, %15 ]
  %26 = icmp eq i32 %24, 1
  %27 = select i1 %5, i1 %26, i1 false
  br i1 %27, label %28, label %30

28:                                               ; preds = %23
  %29 = add nsw i32 %17, 100
  br label %39

30:                                               ; preds = %23
  %31 = lshr i32 %25, 1
  %32 = add nuw nsw i32 %24, 1
  %33 = and i32 %25, 2
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %35, label %23, !llvm.loop !6

35:                                               ; preds = %30, %15
  %36 = phi i32 [ 0, %15 ], [ %32, %30 ]
  %37 = add i32 %16, %17
  %38 = add i32 %37, %36
  br label %39

39:                                               ; preds = %35, %28
  %40 = phi i32 [ %29, %28 ], [ %38, %35 ]
  %41 = xor i32 %18, %0
  %42 = add nuw nsw i32 %16, 1
  %43 = icmp eq i32 %16, %14
  br i1 %43, label %21, label %15, !llvm.loop !9
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @tt_rot(i32 noundef %0) local_unnamed_addr #0 {
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
  %13 = and i32 %0, 1
  %14 = add nuw nsw i32 %13, 1
  br label %15

15:                                               ; preds = %1, %50
  %16 = phi i32 [ 0, %1 ], [ %54, %50 ]
  %17 = phi i32 [ 0, %1 ], [ %52, %50 ]
  %18 = phi i8 [ 0, %1 ], [ %51, %50 ]
  %19 = phi i32 [ %12, %1 ], [ %53, %50 ]
  %20 = and i32 %19, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %40, label %28

22:                                               ; preds = %50
  %23 = tail call i32 @cq_measure_si32(i32 noundef %52) #3
  %24 = trunc nuw i8 %51 to i1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #3
  %26 = select i1 %25, i32 256, i32 0
  %27 = add nsw i32 %26, %23
  ret i32 %27

28:                                               ; preds = %15, %35
  %29 = phi i32 [ %37, %35 ], [ 0, %15 ]
  %30 = phi i32 [ %36, %35 ], [ %19, %15 ]
  %31 = icmp eq i32 %29, 1
  %32 = select i1 %5, i1 %31, i1 false
  br i1 %32, label %33, label %35

33:                                               ; preds = %28
  %34 = add nsw i32 %17, 100
  br label %50

35:                                               ; preds = %28
  %36 = lshr i32 %30, 1
  %37 = add nuw nsw i32 %29, 1
  %38 = and i32 %30, 2
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %40, label %28, !llvm.loop !10

40:                                               ; preds = %35, %15
  %41 = phi i32 [ 0, %15 ], [ %37, %35 ]
  %42 = add i32 %16, %17
  %43 = add i32 %42, %41
  %44 = trunc nuw i8 %18 to i1
  %45 = add nuw nsw i32 %16, 1
  %46 = uitofp nneg i32 %45 to double
  %47 = fmul double %46, 2.500000e-01
  %48 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %44, double noundef %47) #2
  %49 = zext i1 %48 to i8
  br label %50

50:                                               ; preds = %40, %33
  %51 = phi i8 [ %18, %33 ], [ %49, %40 ]
  %52 = phi i32 [ %34, %33 ], [ %43, %40 ]
  %53 = xor i32 %19, %0
  %54 = add nuw nsw i32 %16, 1
  %55 = icmp eq i32 %16, %14
  br i1 %55, label %22, label %15, !llvm.loop !11
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @tt_arm(i32 noundef %0) local_unnamed_addr #0 {
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
  %13 = and i32 %0, 1
  %14 = and i32 %0, 4
  %15 = icmp eq i32 %14, 0
  %16 = add nuw nsw i32 %13, 1
  br label %17

17:                                               ; preds = %1, %45
  %18 = phi i32 [ 0, %1 ], [ %48, %45 ]
  %19 = phi i32 [ 0, %1 ], [ %46, %45 ]
  %20 = phi i32 [ %12, %1 ], [ %47, %45 ]
  %21 = and i32 %20, 1
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %37, label %25

23:                                               ; preds = %45
  %24 = tail call i32 @cq_measure_si32(i32 noundef %46) #3
  ret i32 %24

25:                                               ; preds = %17, %32
  %26 = phi i32 [ %34, %32 ], [ 0, %17 ]
  %27 = phi i32 [ %33, %32 ], [ %20, %17 ]
  %28 = icmp eq i32 %26, 1
  %29 = select i1 %5, i1 %28, i1 false
  br i1 %29, label %30, label %32

30:                                               ; preds = %25
  %31 = add nsw i32 %19, 100
  br label %45

32:                                               ; preds = %25
  %33 = lshr i32 %27, 1
  %34 = add nuw nsw i32 %26, 1
  %35 = and i32 %27, 2
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %25, !llvm.loop !12

37:                                               ; preds = %32, %17
  %38 = phi i32 [ 0, %17 ], [ %34, %32 ]
  %39 = add i32 %18, %19
  %40 = add i32 %39, %38
  br i1 %15, label %43, label %41

41:                                               ; preds = %37
  %42 = xor i32 %40, 5
  br label %45

43:                                               ; preds = %37
  %44 = add nsw i32 %40, 1
  br label %45

45:                                               ; preds = %41, %43, %30
  %46 = phi i32 [ %31, %30 ], [ %42, %41 ], [ %44, %43 ]
  %47 = xor i32 %20, %0
  %48 = add nuw nsw i32 %18, 1
  %49 = icmp eq i32 %18, %16
  br i1 %49, label %23, label %17, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @tt_cskip(i32 noundef %0) local_unnamed_addr #0 {
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
  %12 = and i32 %0, 2
  %13 = icmp eq i32 %12, 0
  %14 = add nuw nsw i32 %11, 1
  br label %17

15:                                               ; preds = %37
  %16 = tail call i32 @cq_measure_si32(i32 noundef %38) #3
  ret i32 %16

17:                                               ; preds = %1, %37
  %18 = phi i32 [ 0, %1 ], [ %40, %37 ]
  %19 = phi i32 [ 0, %1 ], [ %38, %37 ]
  %20 = phi i32 [ %10, %1 ], [ %39, %37 ]
  br i1 %13, label %33, label %21

21:                                               ; preds = %17, %28
  %22 = phi i32 [ %29, %28 ], [ %20, %17 ]
  %23 = phi i32 [ %30, %28 ], [ 0, %17 ]
  %24 = icmp eq i32 %23, 1
  %25 = select i1 %5, i1 %24, i1 false
  br i1 %25, label %26, label %28

26:                                               ; preds = %21
  %27 = add nsw i32 %19, 100
  br label %37

28:                                               ; preds = %21
  %29 = lshr i32 %22, 1
  %30 = add nuw nsw i32 %23, 1
  %31 = and i32 %22, 2
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %33, label %21, !llvm.loop !14

33:                                               ; preds = %28, %17
  %34 = phi i32 [ 0, %17 ], [ %30, %28 ]
  %35 = add i32 %18, %19
  %36 = add i32 %35, %34
  br label %37

37:                                               ; preds = %33, %26
  %38 = phi i32 [ %27, %26 ], [ %36, %33 ]
  %39 = xor i32 %20, %0
  %40 = add nuw nsw i32 %18, 1
  %41 = icmp eq i32 %18, %14
  br i1 %41, label %15, label %17, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @tt_kk(i32 noundef %0) local_unnamed_addr #0 {
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
  %13 = xor i32 %12, %0
  %14 = and i32 %13, 1
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %44, label %16

16:                                               ; preds = %1, %38
  %17 = phi i32 [ %41, %38 ], [ %13, %1 ]
  %18 = phi i32 [ %39, %38 ], [ 0, %1 ]
  %19 = phi i32 [ %40, %38 ], [ %12, %1 ]
  %20 = and i32 %19, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %34, label %22

22:                                               ; preds = %16, %29
  %23 = phi i32 [ %31, %29 ], [ 0, %16 ]
  %24 = phi i32 [ %30, %29 ], [ %19, %16 ]
  %25 = icmp eq i32 %23, 1
  %26 = select i1 %5, i1 %25, i1 false
  br i1 %26, label %27, label %29

27:                                               ; preds = %22
  %28 = add nsw i32 %18, 100
  br label %38

29:                                               ; preds = %22
  %30 = lshr i32 %24, 1
  %31 = add nuw nsw i32 %23, 1
  %32 = and i32 %24, 2
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %34, label %22, !llvm.loop !16

34:                                               ; preds = %29, %16
  %35 = phi i32 [ 0, %16 ], [ %31, %29 ]
  %36 = add i32 %18, 1
  %37 = add i32 %36, %35
  br label %38

38:                                               ; preds = %34, %27
  %39 = phi i32 [ %28, %27 ], [ %37, %34 ]
  %40 = xor i32 %19, %0
  %41 = lshr i32 %17, 1
  %42 = and i32 %17, 2
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %44, label %16, !llvm.loop !17

44:                                               ; preds = %38, %1
  %45 = phi i32 [ 0, %1 ], [ %39, %38 ]
  %46 = tail call i32 @cq_measure_si32(i32 noundef %45) #3
  ret i32 %46
}

; Function Attrs: nounwind ssp uwtable
define i32 @tt_kk_arm(i32 noundef %0) local_unnamed_addr #0 {
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
  %13 = xor i32 %12, %0
  %14 = and i32 %13, 1
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %51, label %16

16:                                               ; preds = %1
  %17 = and i32 %0, 4
  %18 = icmp eq i32 %17, 0
  br label %19

19:                                               ; preds = %16, %45
  %20 = phi i32 [ %13, %16 ], [ %48, %45 ]
  %21 = phi i32 [ 0, %16 ], [ %46, %45 ]
  %22 = phi i32 [ %12, %16 ], [ %47, %45 ]
  %23 = and i32 %22, 1
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %37, label %25

25:                                               ; preds = %19, %32
  %26 = phi i32 [ %34, %32 ], [ 0, %19 ]
  %27 = phi i32 [ %33, %32 ], [ %22, %19 ]
  %28 = icmp eq i32 %26, 1
  %29 = select i1 %5, i1 %28, i1 false
  br i1 %29, label %30, label %32

30:                                               ; preds = %25
  %31 = add nsw i32 %21, 100
  br label %45

32:                                               ; preds = %25
  %33 = lshr i32 %27, 1
  %34 = add nuw nsw i32 %26, 1
  %35 = and i32 %27, 2
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %25, !llvm.loop !18

37:                                               ; preds = %32, %19
  %38 = phi i32 [ 0, %19 ], [ %34, %32 ]
  %39 = add i32 %21, 1
  %40 = add i32 %39, %38
  br i1 %18, label %43, label %41

41:                                               ; preds = %37
  %42 = xor i32 %40, 5
  br label %45

43:                                               ; preds = %37
  %44 = add nsw i32 %40, 1
  br label %45

45:                                               ; preds = %41, %43, %30
  %46 = phi i32 [ %31, %30 ], [ %42, %41 ], [ %44, %43 ]
  %47 = xor i32 %22, %0
  %48 = lshr i32 %20, 1
  %49 = and i32 %20, 2
  %50 = icmp eq i32 %49, 0
  br i1 %50, label %51, label %19, !llvm.loop !19

51:                                               ; preds = %45, %1
  %52 = phi i32 [ 0, %1 ], [ %46, %45 ]
  %53 = tail call i32 @cq_measure_si32(i32 noundef %52) #3
  ret i32 %53
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
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
