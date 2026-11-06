; ModuleID = 'tail_phis.c'
source_filename = "tail_phis.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tp_g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @tp_tail(i32 noundef %0, i64 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  switch i64 %1, label %53 [
    i64 3, label %11
    i64 1, label %8
    i64 2, label %5
  ]

5:                                                ; preds = %3
  %6 = and i32 %4, 256
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %31, label %53

8:                                                ; preds = %3
  %9 = and i32 %4, 1
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %43, label %22

11:                                               ; preds = %3, %19
  %12 = phi i32 [ %20, %19 ], [ 0, %3 ]
  %13 = shl nuw nsw i32 1, %12
  %14 = and i32 %13, %4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %19, label %16

16:                                               ; preds = %11
  %17 = or disjoint i32 %12, 40
  %18 = zext nneg i32 %17 to i64
  br label %53

19:                                               ; preds = %11
  %20 = add nuw nsw i32 %12, 1
  %21 = icmp eq i32 %20, 5
  br i1 %21, label %53, label %11, !llvm.loop !6

22:                                               ; preds = %8, %22
  %23 = phi i64 [ %25, %22 ], [ 0, %8 ]
  %24 = trunc i64 %23 to i32
  %25 = add nuw nsw i64 %23, 1
  %26 = shl nuw i32 2, %24
  %27 = and i32 %26, %4
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %43, label %22, !llvm.loop !9

29:                                               ; preds = %37
  %30 = add nuw nsw i64 %33, 7
  br label %53

31:                                               ; preds = %5, %37
  %32 = phi i32 [ %39, %37 ], [ 0, %5 ]
  %33 = phi i64 [ %38, %37 ], [ 0, %5 ]
  %34 = shl nuw i32 1, %32
  %35 = and i32 %34, %4
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %43, label %37

37:                                               ; preds = %31
  %38 = add nuw nsw i64 %33, 2
  %39 = add nuw nsw i32 %32, 1
  %40 = shl i32 512, %32
  %41 = and i32 %40, %4
  %42 = icmp eq i32 %41, 0
  br i1 %42, label %31, label %29, !llvm.loop !10

43:                                               ; preds = %31, %22, %8
  %44 = phi i64 [ 0, %8 ], [ %25, %22 ], [ %33, %31 ]
  %45 = and i32 %4, 1048576
  %46 = icmp eq i32 %45, 0
  br i1 %46, label %49, label %47

47:                                               ; preds = %43
  %48 = add nuw nsw i64 %44, 1
  br label %53

49:                                               ; preds = %43
  %50 = and i32 %4, 2097152
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %53, label %52

52:                                               ; preds = %49
  store i32 1, ptr @tp_g, align 4, !tbaa !11
  br label %53

53:                                               ; preds = %19, %5, %29, %49, %52, %3, %47, %16
  %54 = phi i64 [ %18, %16 ], [ %48, %47 ], [ 7, %3 ], [ -1, %52 ], [ -1, %49 ], [ 5, %5 ], [ %30, %29 ], [ 50, %19 ]
  %55 = tail call i64 @cq_measure_sl(i64 noundef %54) #3
  %56 = trunc i64 %55 to i32
  ret i32 %56
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

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
!10 = distinct !{!10, !8}
!11 = !{!12, !12, i64 0}
!12 = !{!"int", !13, i64 0}
!13 = !{!"omnipotent char", !14, i64 0}
!14 = !{!"Simple C/C++ TBAA"}
