; cq-hzji: a vector constrained op works per lane (rule 3); cqcheck user PASS.
; C source (clang-19 -O1, -include CQ.h):
;   #include <fenv.h>
;   #pragma STDC FENV_ACCESS ON
;   typedef double v2 __attribute__((vector_size(16)));
;   int vec_q(double x0, double th, double c) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       v2 a = {x, x}; v2 b = {c, 3.0};
;       v2 r = a / b;
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r[0]) + (int)cq_measure(r[1]);
;   }
; CHECK vec_q: call i32 @cq_template_fdiv_f64_hl_rm_exc(
; ModuleID = 'vec2.c'
source_filename = "vec2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @vec_q(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #4
  %6 = insertelement <2 x double> poison, double %4, i64 0
  %7 = shufflevector <2 x double> %6, <2 x double> poison, <2 x i32> zeroinitializer
  %8 = insertelement <2 x double> <double poison, double 3.000000e+00>, double %2, i64 0
  %9 = tail call <2 x double> @llvm.experimental.constrained.fdiv.v2f64(<2 x double> %7, <2 x double> %8, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  %10 = tail call i32 @fetestexcept(i32 noundef 63) #4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = extractelement <2 x double> %9, i64 0
  %13 = tail call double @cq_measure_f64(double noundef %12) #4
  %14 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %13, metadata !"fpexcept.strict") #5
  %15 = add nsw i32 %14, %11
  %16 = extractelement <2 x double> %9, i64 1
  %17 = tail call double @cq_measure_f64(double noundef %16) #4
  %18 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %17, metadata !"fpexcept.strict") #5
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare <2 x double> @llvm.experimental.constrained.fdiv.v2f64(<2 x double>, <2 x double>, metadata, metadata) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #2

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nomerge nounwind strictfp }
attributes #4 = { nounwind strictfp }
attributes #5 = { strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
