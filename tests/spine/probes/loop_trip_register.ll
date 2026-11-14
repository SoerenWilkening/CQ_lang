; /* tests/spine probe (cq-8plep, CR rule 19 mint sites, rule 14 K trips): a register minted in one trip of a K-loop is
;  * bound to no original value at the return (the next trip and the exit rebind the loop's values); its mint site is
;  * the cq_theta that rotated it. Two shapes: a rotation behind a classical branch beside a cq_measure, and a fresh
;  * register per trip. ph_theta's §6 fails on a leak of the per-trip copies (cq-bxikv, loops-cutoff), not on this site. */
; #include "CQ.h"
; unsigned ph_theta(unsigned x0, double th, unsigned k, int c, unsigned y0) {
;   unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
;   unsigned m = 0;
;   while (x > k) {
;     x >>= 1;
;     if (c & 1) m += cq_measure(y & 3);
;     if (c & 2) cq_theta(&y, 0.25);
;   }
;   return m * 16 + cq_measure(y);
; }
; unsigned f_fresh(unsigned x0, double th, unsigned k, unsigned y0) {
;   unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
;   unsigned m = 0;
;   while (x > k) { x >>= 1; unsigned t = (y + x) & 3; cq_theta(&t, 0.25); m ^= t; }
;   return m;
; }
; ModuleID = 'loop_trip_register.c'
source_filename = "loop_trip_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ph_theta(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #2
  %8 = icmp ugt i32 %6, %2
  br i1 %8, label %9, label %32

9:                                                ; preds = %5
  %10 = and i32 %3, 1
  %11 = icmp eq i32 %10, 0
  %12 = and i32 %3, 2
  %13 = icmp eq i32 %12, 0
  br label %14

14:                                               ; preds = %9, %27
  %15 = phi i32 [ 0, %9 ], [ %24, %27 ]
  %16 = phi i32 [ %7, %9 ], [ %28, %27 ]
  %17 = phi i32 [ %6, %9 ], [ %18, %27 ]
  %18 = lshr i32 %17, 1
  br i1 %11, label %23, label %19

19:                                               ; preds = %14
  %20 = and i32 %16, 3
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %20) #3
  %22 = add i32 %21, %15
  br label %23

23:                                               ; preds = %19, %14
  %24 = phi i32 [ %22, %19 ], [ %15, %14 ]
  br i1 %13, label %27, label %25

25:                                               ; preds = %23
  %26 = tail call i32 @cq_theta_ui32(i32 noundef %16, double noundef 2.500000e-01) #2
  br label %27

27:                                               ; preds = %25, %23
  %28 = phi i32 [ %26, %25 ], [ %16, %23 ]
  %29 = icmp ugt i32 %18, %2
  br i1 %29, label %14, label %30, !llvm.loop !6

30:                                               ; preds = %27
  %31 = shl i32 %24, 4
  br label %32

32:                                               ; preds = %30, %5
  %33 = phi i32 [ %7, %5 ], [ %28, %30 ]
  %34 = phi i32 [ 0, %5 ], [ %31, %30 ]
  %35 = tail call i32 @cq_measure_ui32(i32 noundef %33) #3
  %36 = add i32 %35, %34
  ret i32 %36
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_fresh(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %1) #2
  %7 = icmp ugt i32 %5, %2
  br i1 %7, label %8, label %17

8:                                                ; preds = %4, %8
  %9 = phi i32 [ %11, %8 ], [ %5, %4 ]
  %10 = phi i32 [ %15, %8 ], [ 0, %4 ]
  %11 = lshr i32 %9, 1
  %12 = add i32 %11, %6
  %13 = and i32 %12, 3
  %14 = tail call i32 @cq_theta_ui32(i32 noundef %13, double noundef 2.500000e-01) #2
  %15 = xor i32 %14, %10
  %16 = icmp ugt i32 %11, %2
  br i1 %16, label %8, label %17, !llvm.loop !9

17:                                               ; preds = %8, %4
  %18 = phi i32 [ 0, %4 ], [ %15, %8 ]
  ret i32 %18
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
; USERCHECK ph_theta
; USERCHECK f_fresh
