; ModuleID = 'fmod_frem.c'
source_filename = "fmod_frem.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fmod_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = frem double %4, %2    ; C: fmod(x, c)
  %6 = tail call double @cq_measure_f64(double noundef %5) #3    ; C: cq_measure(fmod(x, c))
  ret double %6    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @fmod_cq(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = frem double %2, %4    ; C: fmod(c, x)
  %6 = tail call double @cq_measure_f64(double noundef %5) #3    ; C: cq_measure(fmod(c, x))
  ret double %6    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define float @fmodf_qq(float noundef %0, float noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call float @cq_theta_f32(float noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call float @cq_theta_f32(float noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = frem float %5, %6    ; C: fmodf(x, y)
  %8 = tail call float @cq_measure_f32(float noundef %7) #3    ; C: cq_measure(fmodf(x, y))
  ret float %8    ; C: return
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @fmodl_qc(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) local_unnamed_addr #0 {
  %4 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = frem x86_fp80 %4, %2    ; C: fmodl(x, c)
  %6 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %5) #3    ; C: cq_measure(fmodl(x, c))
  ret x86_fp80 %6    ; C: return
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #1

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #1

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
