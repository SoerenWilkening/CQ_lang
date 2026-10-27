; ModuleID = 'fp_intrinsics.c'
source_filename = "fp_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fabs_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call double @llvm.fabs.f64(double %3)    ; C: fabs(x)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4    ; C: cq_measure(fabs(x))
  ret double %5    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @copysign_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call double @llvm.copysign.f64(double %4, double %2)    ; C: copysign(x, s)
  %6 = tail call double @cq_measure_f64(double noundef %5) #4    ; C: cq_measure(copysign(x, s))
  ret double %6    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #2

; Function Attrs: nounwind ssp uwtable
define double @sqrt_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call double @llvm.sqrt.f64(double %3)    ; C: sqrt(x)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4    ; C: cq_measure(sqrt(x))
  ret double %5    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @floor_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call double @llvm.floor.f64(double %3)    ; C: floor(x)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4    ; C: cq_measure(floor(x))
  ret double %5    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @trunc_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call double @llvm.trunc.f64(double %3)    ; C: trunc(x)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4    ; C: cq_measure(trunc(x))
  ret double %5    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.trunc.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @rint_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call double @llvm.rint.f64(double %3)    ; C: rint(x)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4    ; C: cq_measure(rint(x))
  ret double %5    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.rint.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @fmax_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call double @llvm.maxnum.f64(double %4, double %2)    ; C: fmax(x, c)
  %6 = tail call double @cq_measure_f64(double noundef %5) #4    ; C: cq_measure(fmax(x, c))
  ret double %6    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.maxnum.f64(double, double) #2

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
