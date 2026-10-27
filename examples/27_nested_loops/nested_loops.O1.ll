; ModuleID = 'nested_loops.c'
source_filename = "nested_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_loops(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %7 = icmp sgt i32 %2, 0    ; C: i < n  (first test)
  br i1 %7, label %8, label %15    ; C: outer for  (enter?)

8:                                                ; preds = %5
  %9 = icmp sgt i32 %3, 0    ; C: j < m  (first test, hoisted)
  br label %10    ; C: outer loop head

10:                                               ; preds = %8, %18
  %11 = phi i32 [ 0, %8 ], [ %20, %18 ]    ; C: i
  %12 = phi i32 [ 0, %8 ], [ %19, %18 ]    ; C: acc at the start of outer trip i
  br i1 %9, label %13, label %18    ; C: inner for  (enter?)

13:                                               ; preds = %10
  %14 = mul nsw i32 %11, %4    ; C: i * c
  br label %22    ; C: inner loop head

15:                                               ; preds = %18, %5
  %16 = phi i32 [ 0, %5 ], [ %19, %18 ]    ; C: acc after the loops
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3    ; C: cq_measure(acc)
  ret i32 %17    ; C: return

18:                                               ; preds = %22, %10
  %19 = phi i32 [ %12, %10 ], [ %27, %22 ]    ; C: acc at the end of outer trip i
  %20 = add nuw nsw i32 %11, 1    ; C: i++
  %21 = icmp eq i32 %20, %2    ; C: i < n  (re-test)
  br i1 %21, label %15, label %10, !llvm.loop !6    ; C: outer: another trip?

22:                                               ; preds = %13, %22
  %23 = phi i32 [ 0, %13 ], [ %28, %22 ]    ; C: j
  %24 = phi i32 [ %12, %13 ], [ %27, %22 ]    ; C: acc
  %25 = add nsw i32 %23, %14    ; C: i * c + j
  %26 = xor i32 %25, %6    ; C: x ^ (i * c + j)
  %27 = add nsw i32 %26, %24    ; C: acc = acc + (x ^ (i * c + j));
  %28 = add nuw nsw i32 %23, 1    ; C: j++
  %29 = icmp eq i32 %28, %3    ; C: j < m  (re-test)
  br i1 %29, label %18, label %22, !llvm.loop !9    ; C: inner: another trip?
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
