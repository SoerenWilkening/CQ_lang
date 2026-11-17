; ModuleID = 'for_classical_bound.c'
source_filename = "for_classical_bound.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @for_classical_bound(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = icmp sgt i32 %2, 0    ; C: i < n  (first test)
  br i1 %6, label %10, label %7    ; C: for (...)  (enter the loop?)

7:                                                ; preds = %10, %4
  %8 = phi i32 [ 0, %4 ], [ %14, %10 ]    ; C: acc after the loop
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3    ; C: cq_measure(acc)
  ret i32 %9    ; C: return

10:                                               ; preds = %4, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %4 ]    ; C: i
  %12 = phi i32 [ %14, %10 ], [ 0, %4 ]    ; C: acc
  %13 = mul nsw i32 %12, %3    ; C: acc * c
  %14 = add nsw i32 %13, %5    ; C: acc = acc * c + x;
  %15 = add nuw nsw i32 %11, 1    ; C: i++
  %16 = icmp eq i32 %15, %2    ; C: i < n  (re-test)
  br i1 %16, label %7, label %10, !llvm.loop !6    ; C: for (...)  (another trip?)
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
