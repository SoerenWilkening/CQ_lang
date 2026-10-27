; ModuleID = 'fenv_rounding.c'
source_filename = "fenv_rounding.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define double @fenv_rounding(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call i32 @fesetround(i32 noundef 2048) #4    ; C: fesetround(FE_UPWARD);
  %7 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: double y = x * c;  (rounded upward)
  %8 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %5, double %3, metadata !"ogt", metadata !"fpexcept.ignore") #5    ; C: x > k
  %9 = select i1 %8, i32 2048, i32 1024    ; C: x > k ? FE_UPWARD : FE_DOWNWARD
  %10 = tail call i32 @fesetround(i32 noundef %9) #4    ; C: fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);
  %11 = tail call double @llvm.experimental.constrained.fadd.f64(double %7, double %2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: double z = y + c;  (rounded under the quantum mode)
  %12 = tail call i32 @fegetround() #4    ; C: int m = fegetround();
  %13 = tail call i32 @fesetround(i32 noundef 0) #4    ; C: fesetround(FE_TONEAREST);
  %14 = tail call double @llvm.experimental.constrained.fmul.f64(double %11, double %2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: double w = z * c;
  %15 = tail call double @cq_measure_f64(double noundef %14) #4    ; C: cq_measure(w)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #4    ; C: cq_measure(m)
  %17 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: (double)cq_measure(m)
  %18 = tail call double @llvm.experimental.constrained.fadd.f64(double %15, double %17, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: cq_measure(w) + (double)cq_measure(m)
  ret double %18    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

declare i32 @fegetround() local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define double @quantum_mode_classical_op(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %7 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %2, metadata !"ogt", metadata !"fpexcept.ignore") #5    ; C: x > k
  %8 = select i1 %7, i32 2048, i32 1024    ; C: x > k ? FE_UPWARD : FE_DOWNWARD
  %9 = tail call i32 @fesetround(i32 noundef %8) #4    ; C: fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);
  %10 = tail call double @llvm.experimental.constrained.fadd.f64(double %3, double %4, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5    ; C: double s = a + b;  (classical operands, quantum mode)
  %11 = tail call i32 @fesetround(i32 noundef 0) #4    ; C: fesetround(FE_TONEAREST);
  %12 = tail call double @cq_measure_f64(double noundef %10) #4    ; C: cq_measure(s)
  ret double %12    ; C: return
}

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
