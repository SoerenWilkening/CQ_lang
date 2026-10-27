; ModuleID = 'fmuladd.c'
source_filename = "fmuladd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fmuladd_qcc(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call double @llvm.fmuladd.f64(double %5, double %2, double %3)    ; C: x * a + b
  %7 = tail call double @cq_measure_f64(double noundef %6) #4    ; C: cq_measure(x * a + b)
  ret double %7    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: nounwind ssp uwtable
define double @fmuladd_qqq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %3) #3    ; C: cq_theta(&x, tx);
  %8 = tail call double @cq_theta_f64(double noundef %1, double noundef %4) #3    ; C: cq_theta(&y, ty);
  %9 = tail call double @cq_theta_f64(double noundef %2, double noundef %5) #3    ; C: cq_theta(&z, tz);
  %10 = tail call double @llvm.fmuladd.f64(double %7, double %8, double %9)    ; C: x * y + z
  %11 = tail call double @cq_measure_f64(double noundef %10) #4    ; C: cq_measure(x * y + z)
  ret double %11    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
