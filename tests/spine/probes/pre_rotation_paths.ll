; cq-drcl, cq-s32y, cq-jkq8 (CR rule 2, f684858: pre-rotation copies per path and trip; were stops).
; a2c: the old value of a rotation inside a classical arm, read after the classical join: the Ry hits a copy
; of x's rail and x keeps its rail on both paths. loopinv: the old value of an in-place rotation inside a loop,
; invariant over the loop: each trip rotates a fresh copy, x keeps its value.
; USERCHECK a2c
; USERCHECK loopinv
; Source:
;   #include "CQ.h"
;   /* CR rule 2 (f684858): pre-rotation copies per path and trip. */
;   /* The old value of a rotation inside a classical arm, read after the classical join. */
;   int a2c(int x0, double tx, int c, double t) {
;     int x = x0; cq_theta(&x, tx);
;     int xm = x;
;     if (c != 0) cq_theta(&xm, t);
;     int m1 = cq_measure(xm);
;     return cq_measure(x) + m1;
;   }
;   /* The old value of an in-place rotation inside a loop, invariant over the loop, read after it. */
;   int loopinv(int x0, double t, int n) {
;     int x = x0; cq_theta(&x, t);
;     for (int i = 0; i < n; i++) { int y = x; cq_theta(&y, t); }
;     return cq_measure(x);
;   }
; ModuleID = 'prerot.c'
source_filename = "prerot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @a2c(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp eq i32 %2, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %4
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %3) #2
  br label %9

9:                                                ; preds = %7, %4
  %10 = phi i32 [ %8, %7 ], [ %5, %4 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @loopinv(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %8, %3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  ret i32 %7

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %11, %8 ], [ 0, %3 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2
  %11 = add nuw nsw i32 %9, 1
  %12 = icmp eq i32 %11, %2
  br i1 %12, label %6, label %8, !llvm.loop !6
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
