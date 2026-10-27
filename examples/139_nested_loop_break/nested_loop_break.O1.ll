; ModuleID = 'nested_loop_break.c'
source_filename = "nested_loop_break.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_loop_break(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %7 = icmp sgt i32 %2, 0    ; C: n > 0  (outer loop runs at all)
  br i1 %7, label %8, label %13    ; C: for (i = 0; i < n; ...)

8:                                                ; preds = %5
  %9 = icmp sgt i32 %3, 0    ; C: m > 0  (inner loop runs at all; hoisted)
  br label %10

10:                                               ; preds = %8, %26
  %11 = phi i32 [ 0, %8 ], [ %28, %26 ]    ; C: i
  %12 = phi i32 [ 0, %8 ], [ %27, %26 ]    ; C: acc at the start of outer trip i
  br i1 %9, label %16, label %26    ; C: for (j = 0; j < m; ...)

13:                                               ; preds = %26, %5
  %14 = phi i32 [ 0, %5 ], [ %27, %26 ]    ; C: acc at return
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3    ; C: cq_measure(acc)
  ret i32 %15    ; C: return cq_measure(acc);

16:                                               ; preds = %10, %16
  %17 = phi i32 [ %23, %16 ], [ 0, %10 ]    ; C: j
  %18 = phi i32 [ %21, %16 ], [ %12, %10 ]    ; C: acc at the start of inner trip j
  %19 = add nuw nsw i32 %17, %11    ; C: i + j
  %20 = xor i32 %19, %6    ; C: x ^ (i + j)
  %21 = add nsw i32 %20, %18    ; C: acc += x ^ (i + j);
  %22 = icmp sle i32 %21, %4    ; C: !(acc > lim)  (no break)
  %23 = add nuw nsw i32 %17, 1    ; C: j++
  %24 = icmp slt i32 %23, %3    ; C: j < m
  %25 = select i1 %22, i1 %24, i1 false    ; C: continue the inner loop: no break && j < m
  br i1 %25, label %16, label %26, !llvm.loop !6    ; C: inner latch

26:                                               ; preds = %16, %10
  %27 = phi i32 [ %12, %10 ], [ %21, %16 ]    ; C: acc after the inner loop (break or exhaustion)
  %28 = add nuw nsw i32 %11, 1    ; C: i++
  %29 = icmp eq i32 %28, %2    ; C: i == n
  br i1 %29, label %13, label %10, !llvm.loop !9    ; C: outer latch
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
!9 = distinct !{!9, !7, !8}
