; /* tests/spine probe (CR rule 23 with rule 2's cq_theta; cq-181j): `int m = fegetround(); cq_theta(&m, t);` where the mode is a
;  * rail: m is bound to the MODE rail, which eff-fenv also binds to a detached probe key. The Ry hits a copy of it; the
;  * environment keeps its rail. It crashed in beginPreRotation (functionOf of the detached key).
;  * Regenerate fenv_mode_rotated_copy.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h fenv_mode_rotated_copy.c */
; USERCHECK p5
; CHECK p5: call void @cqrt_copy_i32(i32 %{{mode}}, i32 %{{m}})
; CHECK p5: call void @cqrt_ry_i32(i32 %{{m}}, double %{{t}})
; ModuleID = 'fenv_mode_rotated_copy.c'
source_filename = "fenv_mode_rotated_copy.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define double @p5(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  %8 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %7, double %2, metadata !"ogt", metadata !"fpexcept.ignore") #4
  %9 = select i1 %8, i32 2048, i32 1024
  %10 = tail call i32 @fesetround(i32 noundef %9) #5
  %11 = tail call i32 @fegetround() #5
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %5) #3
  %13 = tail call double @llvm.experimental.constrained.fadd.f64(double %3, double %4, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %14 = tail call i32 @fesetround(i32 noundef 0) #5
  %15 = tail call double @cq_measure_f64(double noundef %13) #5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  %17 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %16, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  %18 = tail call double @llvm.experimental.constrained.fadd.f64(double %15, double %17, metadata !"round.dynamic", metadata !"fpexcept.ignore") #4
  ret double %18
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

declare i32 @fegetround() local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #2

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nomerge nounwind strictfp }
attributes #4 = { strictfp }
attributes #5 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
