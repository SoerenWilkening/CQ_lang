; ModuleID = 'horner_accumulator.c'
source_filename = "horner_accumulator.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @horner(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = load double, ptr %2, align 8, !tbaa !6    ; C: double s = coef[0];
  %7 = icmp sgt i32 %3, 1    ; C: i < n  (first test, i = 1)
  br i1 %7, label %8, label %10    ; C: for (...)  (enter?)

8:                                                ; preds = %4
  %9 = zext nneg i32 %3 to i64    ; C: n as the 64-bit trip bound
  br label %13    ; C: loop head

10:                                               ; preds = %13, %4
  %11 = phi double [ %6, %4 ], [ %18, %13 ]    ; C: s after the loop
  %12 = tail call double @cq_measure_f64(double noundef %11) #4    ; C: cq_measure(s)
  ret double %12    ; C: return

13:                                               ; preds = %8, %13
  %14 = phi i64 [ 1, %8 ], [ %19, %13 ]    ; C: i
  %15 = phi double [ %6, %8 ], [ %18, %13 ]    ; C: s
  %16 = getelementptr inbounds double, ptr %2, i64 %14    ; C: &coef[i]
  %17 = load double, ptr %16, align 8, !tbaa !6    ; C: coef[i]
  %18 = tail call double @llvm.fmuladd.f64(double %15, double %5, double %17)    ; C: s = s * x + coef[i];  (fused)
  %19 = add nuw nsw i64 %14, 1    ; C: i++
  %20 = icmp eq i64 %19, %9    ; C: i < n  (re-test)
  br i1 %20, label %10, label %13, !llvm.loop !10    ; C: another trip?
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

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
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
