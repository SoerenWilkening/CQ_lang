; ModuleID = 'arms_classical_exits.c'
source_filename = "arms_classical_exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define void @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %6, label %5

5:                                                ; preds = %17, %3
  ret void

6:                                                ; preds = %3, %17
  %7 = phi i32 [ %8, %17 ], [ 0, %3 ]
  %8 = add nuw nsw i32 %7, 1
  %9 = uitofp nneg i32 %8 to double
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %9) #2
  br i1 %10, label %11, label %13

11:                                               ; preds = %6
  %12 = add nsw i32 %7, %1
  switch i32 %12, label %16 [
    i32 1, label %17
    i32 5, label %17
    i32 9, label %17
  ]

13:                                               ; preds = %6
  %14 = mul nsw i32 %7, %2
  %15 = trunc i32 %14 to i8
  switch i8 %15, label %16 [
    i8 3, label %17
    i8 7, label %17
    i8 11, label %17
  ]

16:                                               ; preds = %13, %11
  tail call void @cq_phi(double noundef 5.000000e-01) #3
  br label %17

17:                                               ; preds = %13, %13, %13, %11, %11, %11, %16
  %18 = icmp eq i32 %8, %0
  br i1 %18, label %5, label %6, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
