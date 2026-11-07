; ModuleID = 'f4.c'
source_filename = "f4.c"
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
  switch i32 %27, label %45 [
    i32 2, label %28
    i32 5, label %42
  ]

28:                                               ; preds = %25
  %29 = lshr i32 %0, 2
  %30 = and i32 %29, 3
  %31 = icmp eq i32 %30, 3
  br i1 %31, label %42, label %32

32:                                               ; preds = %28
  %33 = tail call i32 @llvm.umax.i32(i32 %30, i32 2)
  br label %37

34:                                               ; preds = %37
  %35 = add nuw nsw i32 %38, 1
  %36 = icmp eq i32 %38, %33
  br i1 %36, label %42, label %37, !llvm.loop !9

37:                                               ; preds = %32, %34
  %38 = phi i32 [ %35, %34 ], [ %30, %32 ]
  %39 = shl nuw nsw i32 2, %38
  %40 = and i32 %39, %12
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %34, label %42

42:                                               ; preds = %37, %34, %28, %25
  %43 = phi i32 [ %26, %25 ], [ 40, %28 ], [ 40, %34 ], [ 3, %37 ]
  %44 = tail call i32 @cq_measure_si32(i32 noundef %43) #4
  br label %45

45:                                               ; preds = %42, %25
  %46 = phi i32 [ undef, %25 ], [ %44, %42 ]
  ret i32 %46
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
