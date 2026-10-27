; ModuleID = '57_multi_carried_arm_in_loop/multi_carried_arm_in_loop.c'
source_filename = "57_multi_carried_arm_in_loop/multi_carried_arm_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @multi_carried_arm_in_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&ix, th);
  %6 = icmp sgt i32 %3, 0    ; C: for (i = 0; i < n; ...)  (does the loop run at all)
  br i1 %6, label %10, label %7    ; C: for (i = 0; i < n; ...)

7:                                                ; preds = %10, %4
  %8 = phi i32 [ 0, %4 ], [ %21, %10 ]    ; C: q after the loop (0 if it never ran)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3    ; C: cq_measure(q)
  ret i32 %9    ; C: return

10:                                               ; preds = %4, %10
  %11 = phi i32 [ %24, %10 ], [ %5, %4 ]    ; C: ix
  %12 = phi i32 [ %26, %10 ], [ 0, %4 ]    ; C: i
  %13 = phi i32 [ %25, %10 ], [ %2, %4 ]    ; C: r
  %14 = phi i32 [ %21, %10 ], [ 0, %4 ]    ; C: q
  %15 = phi i32 [ %19, %10 ], [ 0, %4 ]    ; C: s
  %16 = add nsw i32 %13, %15    ; C: int t = s + r;
  %17 = icmp sgt i32 %16, %11    ; C: if (t <= ix)  (negated)
  %18 = add nsw i32 %16, %13    ; C: t + r
  %19 = select i1 %17, i32 %15, i32 %18    ; C: s = t + r;  (as a select: the arm became selects)
  %20 = select i1 %17, i32 0, i32 %13    ; C: q += r;  (the increment, 0 outside the arm)
  %21 = add nsw i32 %20, %14    ; C: q += r;
  %22 = select i1 %17, i32 0, i32 %16    ; C: ix -= t;  (the decrement, 0 outside the arm)
  %23 = sub nsw i32 %11, %22    ; C: ix -= t;
  %24 = shl nsw i32 %23, 1    ; C: ix += ix;
  %25 = ashr i32 %13, 1    ; C: r >>= 1;
  %26 = add nuw nsw i32 %12, 1    ; C: i++
  %27 = icmp eq i32 %26, %3    ; C: i < n
  br i1 %27, label %7, label %10, !llvm.loop !6    ; C: i < n
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
