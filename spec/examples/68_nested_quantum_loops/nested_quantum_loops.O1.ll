; ModuleID = 'nested_quantum_loops.c'
source_filename = "nested_quantum_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_quantum_loops(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = icmp eq i32 %4, 0    ; C: for (i = x; i > 0; ...)  guard: x == 0 skips both loops
  br i1 %5, label %9, label %6    ; C: for (i = x; i > 0; ...)  guard

6:                                                ; preds = %3, %12
  %7 = phi i32 [ %13, %12 ], [ %4, %3 ]    ; C: i  (x on entry, i - 1 after each outer trip)
  %8 = phi i32 [ %19, %12 ], [ 0, %3 ]    ; C: acc at the start of the outer trip
  br label %15    ; C: enter the inner loop (do-while: j = 0 < i holds)

9:                                                ; preds = %12, %3
  %10 = phi i32 [ 0, %3 ], [ %19, %12 ]    ; C: acc after the loops (0 if skipped)
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #3    ; C: cq_measure(acc)
  ret i32 %11    ; C: return

12:                                               ; preds = %15
  %13 = add i32 %7, -1    ; C: i--
  %14 = icmp eq i32 %13, 0    ; C: i > 0  (outer latch)
  br i1 %14, label %9, label %6, !llvm.loop !6    ; C: i > 0  (outer latch)

15:                                               ; preds = %6, %15
  %16 = phi i32 [ 0, %6 ], [ %20, %15 ]    ; C: j  (0 at inner entry)
  %17 = phi i32 [ %8, %6 ], [ %19, %15 ]    ; C: acc inside the inner loop
  %18 = mul i32 %17, %2    ; C: acc * a
  %19 = add i32 %18, %16    ; C: acc = acc * a + j;
  %20 = add nuw i32 %16, 1    ; C: j++
  %21 = icmp eq i32 %20, %7    ; C: j < i  (inner latch, as j + 1 == i)
  br i1 %21, label %12, label %15, !llvm.loop !9    ; C: j < i  (inner latch)
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

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
