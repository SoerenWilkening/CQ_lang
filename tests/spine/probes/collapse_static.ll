; /* tests/spine probe (CR rule 2, "Collapse is static"; cq-8nj3o, cq-yjbwv): taint and the spine decide by one static
;  * predicate (cq::measuredBefore) whether a read sees a measured value. A measurement in a quantum arm runs
;  * unconditionally (p1, p9: the later branch is classical); one on a classical path only leaves the value a rail (p8);
;  * one in a loop arm leaves the read of the next trip a rail (loopm). Each once stopped the pass with
;  * "spine: rail() of a classical value".
;  * Regenerate collapse_static.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h collapse_static.c */
; USERCHECK p1
; USERCHECK p8
; USERCHECK p9
; USERCHECK loopm
; ModuleID = 'collapse_static.c'
source_filename = "collapse_static.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 7.500000e-01) #2
  %5 = icmp sgt i32 %2, %0
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ 0, %1 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %11 = add nsw i32 %10, %9
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %15

13:                                               ; preds = %8
  %14 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  br label %15

15:                                               ; preds = %13, %8
  %16 = phi i32 [ %14, %13 ], [ 0, %8 ]
  %17 = add i32 %10, %9
  %18 = add i32 %17, %16
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p8(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 0, %1 ]
  %9 = icmp sgt i32 %2, 3
  br i1 %9, label %10, label %12

10:                                               ; preds = %7
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i32 [ %11, %10 ], [ 0, %7 ]
  %14 = add nsw i32 %13, %8
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @p9(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 7.500000e-01) #2
  %5 = icmp sgt i32 %3, %0
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ 0, %1 ]
  %10 = icmp sgt i32 %2, 3
  br i1 %10, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  br label %13

13:                                               ; preds = %11, %8
  %14 = phi i32 [ %12, %11 ], [ 0, %8 ]
  %15 = add nsw i32 %14, %9
  %16 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %17 = add nsw i32 %15, %16
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @loopm(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef 5.000000e-01) #2
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %13, %2
  ret i32 0

6:                                                ; preds = %2, %13
  %7 = phi i32 [ %14, %13 ], [ 0, %2 ]
  %8 = shl nuw i32 1, %7
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %13, label %11

11:                                               ; preds = %6
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %3) #3
  br label %13

13:                                               ; preds = %6, %11
  %14 = add nuw i32 %7, 1
  %15 = icmp eq i32 %14, %0
  br i1 %15, label %5, label %6, !llvm.loop !6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

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
