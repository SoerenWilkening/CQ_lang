; cq-3v36 (CR rules 2, 14): a cq_measure after a loop with a quantum exit, of a value the loop carried, gives the
; classical outcome: "a cq_measure in an exit arm runs once, after the K trips, on the arm's value merged across the
; trips", and its outcome is classical. The entry keeps its double return (it returned a re-seeded rail handle as i32).
; CHECK km: define double @km(
; CHECK km: %{{m}} = call double @cqrt_measure_f64(i32 %{{acc}})
; CHECK km: ret double %{{m}}
; USERCHECK km
; Source:
;   double km(int x0, double th, double a) { int x = x0 & 3; cq_theta(&x, th); double acc = 0; int i = 0;
;     do { acc += a; i++; } while ((x >> i) & 1); return cq_measure(acc); }
; ModuleID = 'km.c'
source_filename = "km.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @km(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %0, 3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2
  br label %6

6:                                                ; preds = %6, %3
  %7 = phi double [ 0.000000e+00, %3 ], [ %9, %6 ]
  %8 = phi i32 [ 0, %3 ], [ %10, %6 ]
  %9 = fadd double %7, %2
  %10 = add nuw nsw i32 %8, 1
  %11 = shl i32 2, %8
  %12 = and i32 %11, %5
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !6

14:                                               ; preds = %6
  %15 = tail call double @cq_measure_f64(double noundef %9) #3
  ret double %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
