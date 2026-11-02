; #include "CQ.h"
; /* cq-hsee (CR rules 8, 9; spine regions): a quantum branch whose region holds a classical branch and a switch whose
;    default -O1 makes `unreachable` (musl jn's switch (nm1 & 3)): the region ends at its post-dominator over the
;    paths that go on, so the condition's rail stays live for the flags of the blocks under it. */
; __attribute__((noinline)) double h(int n, double x) {
;   double r = x;
;   if ((double)n < x) {
;     if (x > 100.0) {
;       switch (n & 3) {
;       case 0: r = x + 1.0; break;
;       case 1: r = x - 1.0; break;
;       case 2: r = 2.0 * x; break;
;       case 3: r = -x; break;
;       }
;     } else {
;       r = x * 3.0;
;     }
;   }
;   return r;
; }
; double e_region(int n, double x) { cq_theta(&n, 0.3); return cq_measure(h(n, x)); }
; USERCHECK e_region
; ModuleID = 'region_dead_end.c'
source_filename = "region_dead_end.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @h(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = sitofp i32 %0 to double
  %4 = fcmp olt double %3, %1
  br i1 %4, label %5, label %20

5:                                                ; preds = %2
  %6 = fcmp ogt double %1, 1.000000e+02
  br i1 %6, label %7, label %18

7:                                                ; preds = %5
  %8 = and i32 %0, 3
  switch i32 %8, label %17 [
    i32 0, label %9
    i32 1, label %11
    i32 2, label %13
    i32 3, label %15
  ]

9:                                                ; preds = %7
  %10 = fadd double %1, 1.000000e+00
  br label %20

11:                                               ; preds = %7
  %12 = fadd double %1, -1.000000e+00
  br label %20

13:                                               ; preds = %7
  %14 = fmul double %1, 2.000000e+00
  br label %20

15:                                               ; preds = %7
  %16 = fneg double %1
  br label %20

17:                                               ; preds = %7
  unreachable

18:                                               ; preds = %5
  %19 = fmul double %1, 3.000000e+00
  br label %20

20:                                               ; preds = %18, %15, %13, %11, %9, %2
  %21 = phi double [ %16, %15 ], [ %14, %13 ], [ %12, %11 ], [ %10, %9 ], [ %19, %18 ], [ %1, %2 ]
  ret double %21
}

; Function Attrs: nounwind ssp uwtable
define double @e_region(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = tail call double @h(i32 noundef %3, double noundef %1)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4
  ret double %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
