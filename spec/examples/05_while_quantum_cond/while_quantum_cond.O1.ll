; ModuleID = 'while_quantum_cond.c'
source_filename = "while_quantum_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @while_quantum_cond(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2    ; C: unsigned x = x0; cq_theta(&x, th);
  %7 = icmp ugt i32 %6, %2    ; C: x > k  (first test)
  br i1 %7, label %8, label %15    ; C: while (x > k)  (enter the loop?)

8:                                                ; preds = %5, %8
  %9 = phi i32 [ %13, %8 ], [ 0, %5 ]    ; C: n
  %10 = phi i32 [ %12, %8 ], [ %6, %5 ]    ; C: x
  %11 = mul i32 %10, %3    ; C: x * a
  %12 = add i32 %11, %4    ; C: x = x * a + b;
  %13 = add nuw nsw i32 %9, 1    ; C: n++;
  %14 = icmp ugt i32 %12, %2    ; C: x > k  (re-test)
  br i1 %14, label %8, label %15, !llvm.loop !6    ; C: while (x > k)  (another trip?)

15:                                               ; preds = %8, %5
  %16 = phi i32 [ 0, %5 ], [ %13, %8 ]    ; C: n after the loop
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3    ; C: cq_measure(n)
  ret i32 %17    ; C: return cq_measure(n);
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

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
