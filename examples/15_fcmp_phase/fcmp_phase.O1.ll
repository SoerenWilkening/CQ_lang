; ModuleID = 'fcmp_phase.c'
source_filename = "fcmp_phase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fcmp_olt(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = fcmp olt double %5, %2    ; C: if (x < k)
  br i1 %6, label %7, label %8    ; C: if (x < k)

7:                                                ; preds = %4
  tail call void @cq_phi(double noundef %3) #3    ; C: cq_phi(phi);
  br label %8    ; C: end of if

8:                                                ; preds = %7, %4
  %9 = tail call double @cq_measure_f64(double noundef %5) #3    ; C: cq_measure(x)
  ret double %9    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @fcmp_unordered(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = fcmp ult double %5, %2    ; C: if (!(x >= k))
  br i1 %6, label %7, label %8    ; C: if (!(x >= k))

7:                                                ; preds = %4
  tail call void @cq_phi(double noundef %3) #3    ; C: cq_phi(phi);
  br label %8    ; C: end of if

8:                                                ; preds = %7, %4
  %9 = tail call double @cq_measure_f64(double noundef %5) #3    ; C: cq_measure(x)
  ret double %9    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define double @fcmp_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %7 = tail call double @cq_theta_f64(double noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %8 = fcmp oeq double %6, %7    ; C: if (x == y)
  br i1 %8, label %9, label %10    ; C: if (x == y)

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef %4) #3    ; C: cq_phi(phi);
  br label %10    ; C: end of if

10:                                               ; preds = %9, %5
  %11 = tail call double @cq_measure_f64(double noundef %6) #3    ; C: cq_measure(x)
  ret double %11    ; C: return
}

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
