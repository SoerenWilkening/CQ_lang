; cq-jkq8 (CR rule 23; was a stop): llvm.set.rounding / llvm.get.rounding (FLT_ROUNDS) are the rounding mode
; the C17 calls read and write: the plugin rewrites them as fesetround / fegetround with x86-64's encoding
; change before the final taint, and rule 23's fenv construction lowers them.
; CHECK rnd: call i32 @fegetround()
; USERCHECK rnd
; Source:
;   #include "CQ.h"
;   #include <fenv.h>
;   #include <float.h>
;   #pragma STDC FENV_ACCESS ON
;   /* CR rule 23: FLT_ROUNDS (llvm.get.rounding) and __builtin_set_flt_rounds (llvm.set.rounding) are the
;      environment's mode, read and written as fegetround / fesetround. */
;   int rnd(double x0, double th, int k) {
;     double x = x0; cq_theta(&x, th);
;     __builtin_set_flt_rounds(k & 3);
;     double y = x * 3.0 + 1.0;
;     int r = FLT_ROUNDS;
;     fesetround(FE_TONEAREST);
;     return r + (int)cq_measure(y);
;   }
; ModuleID = 'rnd.c'
source_filename = "rnd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @rnd(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %5 = and i32 %2, 3
  tail call void @llvm.set.rounding(i32 %5) #5
  %6 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %4, double 3.000000e+00, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  %7 = tail call i32 @llvm.get.rounding() #5
  %8 = tail call i32 @fesetround(i32 noundef 0) #6
  %9 = tail call double @cq_measure_f64(double noundef %6) #6
  %10 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %9, metadata !"fpexcept.strict") #5
  %11 = add nsw i32 %10, %7
  ret i32 %11
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare void @llvm.set.rounding(i32) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.get.rounding() #2

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { strictfp }
attributes #6 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
