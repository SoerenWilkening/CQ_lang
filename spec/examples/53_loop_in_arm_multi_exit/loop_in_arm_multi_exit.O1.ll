; ModuleID = '53_loop_in_arm_multi_exit/loop_in_arm_multi_exit.c'
source_filename = "53_loop_in_arm_multi_exit/loop_in_arm_multi_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @loop_in_arm_multi_exit(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&hx, t1);
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&lx, t2);
  %9 = icmp slt i32 %7, %4    ; C: if (hx < k1)
  br i1 %9, label %10, label %29    ; C: if (hx < k1)

10:                                               ; preds = %6
  %11 = icmp eq i32 %7, 0    ; C: if (hx == 0)
  br i1 %11, label %12, label %20    ; C: if (hx == 0)

12:                                               ; preds = %10
  %13 = icmp sgt i32 %8, 0    ; C: for (; lx > 0; ...)  (guard, first test)
  br i1 %13, label %14, label %32    ; C: for (; lx > 0; ...)

14:                                               ; preds = %12, %14
  %15 = phi i32 [ %17, %14 ], [ -1043, %12 ]    ; C: e  (starts at -1043)
  %16 = phi i32 [ %18, %14 ], [ %8, %12 ]    ; C: lx
  %17 = add nsw i32 %15, -1    ; C: e--
  %18 = shl nuw i32 %16, 1    ; C: lx <<= 1
  %19 = icmp sgt i32 %18, 0    ; C: lx > 0  (latch test)
  br i1 %19, label %14, label %32, !llvm.loop !6    ; C: lx > 0

20:                                               ; preds = %10
  %21 = shl i32 %7, 11    ; C: hx <<= 11
  %22 = icmp sgt i32 %21, 0    ; C: for (...; hx > 0; ...)  (guard, first test)
  br i1 %22, label %23, label %32    ; C: for (...; hx > 0; ...)

23:                                               ; preds = %20, %23
  %24 = phi i32 [ %26, %23 ], [ -1022, %20 ]    ; C: e  (starts at -1022)
  %25 = phi i32 [ %27, %23 ], [ %21, %20 ]    ; C: hx
  %26 = add nsw i32 %24, -1    ; C: e--
  %27 = shl nuw i32 %25, 1    ; C: hx <<= 1
  %28 = icmp sgt i32 %27, 0    ; C: hx > 0  (latch test)
  br i1 %28, label %23, label %32, !llvm.loop !9    ; C: hx > 0

29:                                               ; preds = %6
  %30 = ashr i32 %7, 20    ; C: hx >> 20
  %31 = sub nsw i32 %30, %5    ; C: e = (hx >> 20) - c;
  br label %32    ; C: end of else

32:                                               ; preds = %23, %14, %20, %12, %29
  %33 = phi i32 [ %31, %29 ], [ -1043, %12 ], [ -1022, %20 ], [ %17, %14 ], [ %26, %23 ]    ; C: e  (five ways in: else arm, two loop guards that failed, two loop exits)
  %34 = tail call i32 @cq_measure_si32(i32 noundef %33) #3    ; C: cq_measure(e)
  ret i32 %34    ; C: return
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
