; cq-ihlt, cq-jkq8 (CR rule 2, collapse is static, f684858; was a stop): the callee measures its formal on one
; classical path only, then the caller measures a value computed from it: an ordinary measurement of y's rail,
; nothing is re-read.
; CHECK-COUNT f: call i32 @cqrt_measure_i32( 1
; USERCHECK f
; Source:
;   #include "CQ.h"
;   /* CR rule 2, collapse is static (f684858): the callee measures its formal on one classical path only; the
;      caller's later cq_measure of a value read from it is an ordinary measurement, nothing is re-read. */
;   static int __attribute__((noinline)) readout(int v, int k) { return k > 0 ? cq_measure(v) : k; }
;   int f(int x0, double th, int k, int c) {
;     int x = x0; cq_theta(&x, th);
;     int y = x + c;
;     int m = readout(x, k);
;     return cq_measure(y) + m;
;   }
; ModuleID = 'cmsome.c'
source_filename = "cmsome.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = add nsw i32 %5, %3
  %7 = tail call fastcc i32 @readout(i32 noundef %5, i32 noundef %2)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @readout(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %0) #4
  br label %6

6:                                                ; preds = %2, %4
  %7 = phi i32 [ %5, %4 ], [ %1, %2 ]
  ret i32 %7
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
