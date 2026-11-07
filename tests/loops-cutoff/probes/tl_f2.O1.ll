; ModuleID = 'f2.c'
source_filename = "f2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %6 = zext i1 %2 to i32
  %7 = select i1 %3, i32 2, i32 0
  %8 = or disjoint i32 %7, %6
  %9 = select i1 %4, i32 4, i32 0
  %10 = or disjoint i32 %8, %9
  %11 = select i1 %5, i32 8, i32 0
  %12 = or disjoint i32 %10, %11
  %13 = and i32 %0, 3
  %14 = icmp eq i32 %13, 3
  br i1 %14, label %25, label %15

15:                                               ; preds = %1
  %16 = tail call i32 @llvm.umax.i32(i32 %13, i32 2)
  br label %20

17:                                               ; preds = %20
  %18 = add nuw nsw i32 %21, 1
  %19 = icmp eq i32 %21, %16
  br i1 %19, label %25, label %20, !llvm.loop !6

20:                                               ; preds = %15, %17
  %21 = phi i32 [ %18, %17 ], [ %13, %15 ]
  %22 = shl nuw nsw i32 1, %21
  %23 = and i32 %22, %12
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %17, label %25

25:                                               ; preds = %17, %20, %1
  %26 = phi i32 [ 5, %1 ], [ 5, %17 ], [ 2, %20 ]
  %27 = phi i32 [ 2, %1 ], [ 2, %17 ], [ 5, %20 ]
  switch i32 %27, label %46 [
    i32 2, label %28
    i32 5, label %43
  ]

28:                                               ; preds = %25
  br i1 %4, label %43, label %29

29:                                               ; preds = %28
  %30 = lshr i32 %0, 2
  %31 = and i32 %30, 3
  %32 = icmp eq i32 %31, 3
  br i1 %32, label %43, label %33

33:                                               ; preds = %29
  %34 = tail call i32 @llvm.umax.i32(i32 %31, i32 2)
  br label %38

35:                                               ; preds = %38
  %36 = add nuw nsw i32 %39, 1
  %37 = icmp eq i32 %39, %34
  br i1 %37, label %43, label %38, !llvm.loop !9

38:                                               ; preds = %33, %35
  %39 = phi i32 [ %36, %35 ], [ %31, %33 ]
  %40 = shl nuw nsw i32 2, %39
  %41 = and i32 %40, %12
  %42 = icmp eq i32 %41, 0
  br i1 %42, label %35, label %43

43:                                               ; preds = %38, %35, %29, %28, %25
  %44 = phi i32 [ %26, %25 ], [ 6, %28 ], [ 40, %29 ], [ 40, %35 ], [ 3, %38 ]
  %45 = tail call i32 @cq_measure_si32(i32 noundef %44) #4
  br label %46

46:                                               ; preds = %43, %25
  %47 = phi i32 [ undef, %25 ], [ %45, %43 ]
  ret i32 %47
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #2

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
