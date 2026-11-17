; ModuleID = 'phase_in_loop_and_classical.c'
source_filename = "phase_in_loop_and_classical.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @phase_in_loop(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = icmp sgt i32 %2, 0    ; C: i < n  (first test)
  br i1 %6, label %9, label %7    ; C: for (...)  (enter?)

7:                                                ; preds = %13, %4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x)
  ret i32 %8    ; C: return

9:                                                ; preds = %4, %13
  %10 = phi i32 [ %14, %13 ], [ 0, %4 ]    ; C: i
  %11 = icmp eq i32 %5, %10    ; C: x == i
  br i1 %11, label %12, label %13    ; C: if (x == i)

12:                                               ; preds = %9
  tail call void @cq_phi(double noundef %3) #3    ; C: cq_phi(phi);
  br label %13    ; C: end of if

13:                                               ; preds = %9, %12
  %14 = add nuw nsw i32 %10, 1    ; C: i++
  %15 = icmp eq i32 %14, %2    ; C: i < n  (re-test)
  br i1 %15, label %7, label %9, !llvm.loop !6    ; C: another trip?
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @phase_under_classical(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = icmp eq i32 %2, 0    ; C: flag  (classical, negated)
  br i1 %6, label %8, label %7    ; C: if (flag)

7:                                                ; preds = %4
  tail call void @cq_phi(double noundef %3) #3    ; C: cq_phi(phi);
  br label %8    ; C: end of if

8:                                                ; preds = %7, %4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x)
  ret i32 %9    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @phase_uncontrolled(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  tail call void @cq_phi(double noundef %2) #3    ; C: cq_phi(phi);
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3    ; C: cq_measure(x)
  ret i32 %5    ; C: return
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
