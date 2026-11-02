; cq-hzji: clones carrying the environment that change the mode (classically; quantum, restored before return),
; and a clone compiled without FENV_ACCESS between a FENV_ACCESS caller and a strict callee: by the rule 23
; ruling of 2026-11-02 (cq-57ju) it is a caller without the fenv state (mode 0, an empty flags rail, the returned
; flags dropped) whoever calls it. cqcheck user PASS: clone_mode, clone_qmode.
; C source (clang-19 -O1, -include CQ.h):
;   #include <fenv.h>
;   #pragma STDC FENV_ACCESS ON
;   static __attribute__((noinline)) double scaled_up(double v, double c) {
;       fesetround(FE_UPWARD);
;       double r = v * c;
;       fesetround(FE_TONEAREST);
;       return r;
;   }
;   int clone_mode(double x0, double th, double c) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       double r = scaled_up(x, c);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r);
;   }
;   static __attribute__((noinline)) double qmode(double v, double c, double k) {
;       if (v > k) fesetround(FE_UPWARD);
;       double r = v * c;
;       fesetround(FE_TONEAREST);
;       return r;
;   }
;   int clone_qmode(double x0, double th, double c, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       double r = qmode(x, c, k);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r);
;   }
;   static __attribute__((noinline)) double leaf(double v, double c) { return v * c; }
;   #pragma STDC FENV_ACCESS OFF
;   static __attribute__((noinline)) double mid(double v, double c) { return leaf(v, c) * 2.0; }
;   #pragma STDC FENV_ACCESS ON
;   int chain(double x0, double th, double c) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       double r = mid(x, c);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r);
;   }
; CHECK __cq_q_scaled_up_10: call i32 @fesetround(i32 noundef 2048)
; CHECK __cq_q_qmode_100: call i32 @cq_template_fmul_f64_hl_rmq(
; CHECK chain: call fastcc i32 @__cq_q_mid_10(
; CHECK __cq_q_mid_10: call fastcc { i32, i32 } @__cq_q_leaf_10(i32 %{{a}}, double %{{b}}, i32 0,
; ModuleID = 'clone_env.c'
source_filename = "clone_env.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @clone_mode(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #7
  %6 = tail call fastcc double @scaled_up(double noundef %4, double noundef %2) #8
  %7 = tail call i32 @fetestexcept(i32 noundef 63) #7
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #7
  %9 = tail call double @cq_measure_f64(double noundef %6) #7
  %10 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %9, metadata !"fpexcept.strict") #8
  %11 = add nsw i32 %10, %8
  ret i32 %11
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp strictfp uwtable
define internal fastcc double @scaled_up(double noundef %0, double noundef %1) unnamed_addr #2 {
  %3 = tail call i32 @fesetround(i32 noundef 2048) #7
  %4 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  %5 = tail call i32 @fesetround(i32 noundef 0) #7
  ret double %4
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @clone_qmode(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %6 = tail call i32 @feclearexcept(i32 noundef 63) #7
  %7 = tail call fastcc double @qmode(double noundef %5, double noundef %2, double noundef %3) #8
  %8 = tail call i32 @fetestexcept(i32 noundef 63) #7
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  %10 = tail call double @cq_measure_f64(double noundef %7) #7
  %11 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %10, metadata !"fpexcept.strict") #8
  %12 = add nsw i32 %11, %9
  ret i32 %12
}

; Function Attrs: noinline nounwind ssp strictfp uwtable
define internal fastcc double @qmode(double noundef %0, double noundef %1, double noundef %2) unnamed_addr #2 {
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double %2, metadata !"ogt", metadata !"fpexcept.strict") #8
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = tail call i32 @fesetround(i32 noundef 2048) #7
  br label %7

7:                                                ; preds = %5, %3
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  %9 = tail call i32 @fesetround(i32 noundef 0) #7
  ret double %8
}

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @chain(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #7
  %6 = tail call fastcc double @mid(double noundef %4, double noundef %2) #8
  %7 = tail call i32 @fetestexcept(i32 noundef 63) #7
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #7
  %9 = tail call double @cq_measure_f64(double noundef %6) #7
  %10 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %9, metadata !"fpexcept.strict") #8
  %11 = add nsw i32 %10, %8
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable
define internal fastcc double @mid(double noundef %0, double noundef %1) unnamed_addr #4 {
  %3 = tail call fastcc double @leaf(double noundef %0, double noundef %1)
  %4 = fmul double %3, 2.000000e+00
  ret double %4
}

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define internal fastcc double @leaf(double noundef %0, double noundef %1) unnamed_addr #5 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  ret double %3
}

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind strictfp }
attributes #7 = { nounwind strictfp }
attributes #8 = { strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
