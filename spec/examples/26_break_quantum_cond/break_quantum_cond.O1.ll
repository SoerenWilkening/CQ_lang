; ModuleID = 'break_quantum_cond.c'
source_filename = "break_quantum_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_quantum_cond(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call i32 @llvm.smax.i32(i32 %2, i32 0)    ; C: n  (clamped to >= 0; loop folded)
  %7 = freeze i32 %5    ; C: x
  %8 = sub i32 %7, %3    ; C: x - k  (the i at which x == i + k)
  %9 = tail call i32 @llvm.umin.i32(i32 %8, i32 %6)    ; C: i after the loop = min(x - k, n)  (loop folded)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4    ; C: cq_measure(i)
  ret i32 %10    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @break_with_body(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %7 = icmp slt i32 %2, 1    ; C: i < n  (first test, negated)
  %8 = icmp eq i32 %6, %3    ; C: x == i + k  (first test, i = 0)
  %9 = select i1 %7, i1 true, i1 %8    ; C: loop not entered: n < 1 || x == k
  br i1 %9, label %20, label %10    ; C: for (...) { if (...) break; ...

10:                                               ; preds = %5, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %5 ]    ; C: i
  %12 = phi i32 [ %14, %10 ], [ 0, %5 ]    ; C: acc
  %13 = mul nsw i32 %12, %4    ; C: acc * c
  %14 = add nsw i32 %13, %11    ; C: acc = acc * c + i;
  %15 = add nuw nsw i32 %11, 1    ; C: i++
  %16 = icmp sge i32 %15, %2    ; C: i < n  (re-test, negated)
  %17 = add nsw i32 %15, %3    ; C: i + k
  %18 = icmp eq i32 %6, %17    ; C: x == i + k  (break test)
  %19 = select i1 %16, i1 true, i1 %18    ; C: exit: i >= n || x == i + k
  br i1 %19, label %20, label %10, !llvm.loop !6    ; C: another trip?

20:                                               ; preds = %10, %5
  %21 = phi i32 [ 0, %5 ], [ %14, %10 ]    ; C: acc after the loop
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4    ; C: cq_measure(acc)
  ret i32 %22    ; C: return
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
