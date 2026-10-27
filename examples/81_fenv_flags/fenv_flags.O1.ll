; ModuleID = 'fenv_flags.c'
source_filename = "fenv_flags.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @fenv_flags(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call i32 @feclearexcept(i32 noundef 63) #4    ; C: feclearexcept(FE_ALL_EXCEPT);
  %7 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double y = x / c;
  %8 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %7, double %3, metadata !"ogt", metadata !"fpexcept.strict") #5    ; C: if (y > k)  (signaling compare)
  br i1 %8, label %9, label %11    ; C: if (y > k)

9:                                                ; preds = %4
  %10 = tail call i32 @feraiseexcept(i32 noundef 8) #4    ; C: feraiseexcept(FE_OVERFLOW);
  br label %11    ; C: end of if

11:                                               ; preds = %9, %4
  %12 = tail call i32 @fetestexcept(i32 noundef 41) #4    ; C: int f = fetestexcept(FE_INEXACT | FE_OVERFLOW | FE_INVALID);
  %13 = tail call i32 @feclearexcept(i32 noundef 32) #4    ; C: feclearexcept(FE_INEXACT);
  %14 = tail call i32 @fetestexcept(i32 noundef 63) #4    ; C: int g = fetestexcept(FE_ALL_EXCEPT);
  %15 = tail call i32 @cq_measure_si32(i32 noundef %12) #4    ; C: cq_measure(f)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14) #4    ; C: cq_measure(g)
  %17 = add nsw i32 %16, %15    ; C: cq_measure(f) + cq_measure(g)
  ret i32 %17    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
