; ModuleID = 'h5.c'
source_filename = "h5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = zext i1 %2 to i32
  %7 = select i1 %3, i32 2, i32 0
  %8 = or disjoint i32 %7, %6
  %9 = select i1 %4, i32 4, i32 0
  %10 = select i1 %5, i32 8, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = or disjoint i32 %11, %8
  %13 = and i32 %0, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %1
  br i1 %3, label %26, label %33

16:                                               ; preds = %1
  br i1 %2, label %33, label %17

17:                                               ; preds = %16, %22
  %18 = phi i32 [ %23, %22 ], [ %12, %16 ]
  %19 = phi i32 [ %24, %22 ], [ 0, %16 ]
  %20 = and i32 %18, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %33, label %22

22:                                               ; preds = %17
  %23 = lshr i32 %18, 1
  %24 = add nuw nsw i32 %19, 1
  %25 = icmp ult i32 %18, 8
  br i1 %25, label %17, label %49, !llvm.loop !6

26:                                               ; preds = %15, %26
  %27 = phi i32 [ %30, %26 ], [ 0, %15 ]
  %28 = phi i32 [ %29, %26 ], [ %12, %15 ]
  %29 = lshr i32 %28, 1
  %30 = add nuw nsw i32 %27, 2
  %31 = and i32 %28, 4
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %33, label %26

33:                                               ; preds = %17, %26, %15, %16
  %34 = phi i32 [ %12, %16 ], [ %12, %15 ], [ %29, %26 ], [ %18, %17 ]
  %35 = phi i32 [ 3, %16 ], [ 0, %15 ], [ 0, %26 ], [ 4, %17 ]
  %36 = phi i32 [ 0, %16 ], [ 0, %15 ], [ %30, %26 ], [ %19, %17 ]
  br i1 %3, label %40, label %37

37:                                               ; preds = %33
  %38 = and i32 %34, 4
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %49, label %42

40:                                               ; preds = %33
  %41 = or disjoint i32 %35, 64
  br label %49

42:                                               ; preds = %37, %42
  %43 = phi i32 [ %46, %42 ], [ %35, %37 ]
  %44 = phi i32 [ %45, %42 ], [ %34, %37 ]
  %45 = lshr i32 %44, 1
  %46 = add nuw nsw i32 %43, 2
  %47 = and i32 %44, 8
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %49, label %42, !llvm.loop !9

49:                                               ; preds = %22, %42, %37, %40
  %50 = phi i32 [ %41, %40 ], [ %35, %37 ], [ %46, %42 ], [ 0, %22 ]
  %51 = phi i32 [ %36, %40 ], [ %36, %37 ], [ %36, %42 ], [ %24, %22 ]
  %52 = shl nsw i32 %51, 8
  %53 = add nsw i32 %52, %50
  %54 = tail call i32 @cq_measure_si32(i32 noundef %53) #3
  ret i32 %54
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
