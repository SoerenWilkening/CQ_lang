; cq-mgkr (CR rule 6, dead on one classical path only, ruling cq-mzqo): classical selects and phis over a
; bijective update of a dead y. r6_sel: x + 7 or x itself, measured (x cleaned from x + 7 where chosen).
; r6_neg: s or -s (the images garbage: undone through s, nothing cleaned). r6_two: y ^ 5 or y + 3 (y cleaned
; on both paths, no plain part). r6_phi: nested choice y + 9 / y / y - 4 under a rotation of the result (the
; clean-up runs only where the outer merge kept y + 9; y - 4's path undoes y by rule 5).
; C (clang -O1 -target x86_64-apple-macosx -include CQ.h):
; C: unsigned r6_sel(unsigned x0, double th, int c) {
; C:     unsigned x = x0;
; C:     cq_theta(&x, th);
; C:     unsigned r = c > 1 ? x + 7 : x;
; C:     return cq_measure(r);
; C: }
; C: double r6_neg(double x0, double th, int c) {
; C:     double x = x0;
; C:     cq_theta(&x, th);
; C:     double s = x * 3.0;
; C:     double r = c == 0 ? s : -s;
; C:     return cq_measure(r - 1.0);
; C: }
; C: unsigned r6_two(unsigned x0, double th, int c) {
; C:     unsigned x = x0;
; C:     cq_theta(&x, th);
; C:     unsigned y = x * 3u;
; C:     unsigned r = c > 1 ? y ^ 5u : y + 3u;
; C:     return cq_measure(r);
; C: }
; C: unsigned r6_phi(unsigned x0, double th, int c, int d) {
; C:     unsigned x = x0;
; C:     cq_theta(&x, th);
; C:     unsigned y = x | 1u, r;
; C:     if (c > 1) { if (d) r = y + 9u; else r = y; } else r = y - 4u;
; C:     cq_theta(&r, th);
; C:     return cq_measure(r);
; C: }
; USERCHECK r6_sel
; USERCHECK r6_neg
; USERCHECK r6_two
; USERCHECK r6_phi
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @r6_sel(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 1
  %6 = add i32 %4, 7
  %7 = select i1 %5, i32 %6, i32 %4
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @r6_neg(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2
  %5 = fmul double %4, 3.000000e+00
  %6 = icmp eq i32 %2, 0
  %7 = fneg double %5
  %8 = select i1 %6, double %5, double %7
  %9 = fadd double %8, -1.000000e+00
  %10 = tail call double @cq_measure_f64(double noundef %9) #3
  ret double %10
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @r6_two(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = mul i32 %4, 3
  %6 = icmp sgt i32 %2, 1
  %7 = xor i32 %5, 5
  %8 = add i32 %5, 3
  %9 = select i1 %6, i32 %7, i32 %8
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #3
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @r6_phi(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = or i32 %5, 1
  %7 = icmp sgt i32 %2, 1
  %8 = add i32 %6, -4
  %9 = icmp eq i32 %3, 0
  %10 = add i32 %6, 9
  %11 = select i1 %9, i32 %6, i32 %10
  %12 = select i1 %7, i32 %11, i32 %8
  %13 = tail call i32 @cq_theta_ui32(i32 noundef %12, double noundef %1) #2
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %13) #3
  ret i32 %14
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
