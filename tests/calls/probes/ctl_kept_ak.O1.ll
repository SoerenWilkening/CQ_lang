; ModuleID = 'ctl_kept_ak.c'
source_filename = "ctl_kept_ak.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e1(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 64
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call fastcc i32 @g(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ 9, %3 ]
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #4
  ret i32 %11
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @g(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp ugt i32 %0, 2
  br i1 %3, label %4, label %13

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 1, %2 ]
  %6 = phi i32 [ %7, %4 ], [ %0, %2 ]
  %7 = add i32 %6, -3
  %8 = mul i32 %5, 5
  %9 = add i32 %8, %7
  %10 = icmp ugt i32 %7, 2
  br i1 %10, label %4, label %11, !llvm.loop !6

11:                                               ; preds = %4
  %12 = shl i32 %9, 4
  br label %13

13:                                               ; preds = %11, %2
  %14 = phi i32 [ %0, %2 ], [ %7, %11 ]
  %15 = phi i32 [ 16, %2 ], [ %12, %11 ]
  %16 = add i32 %14, %1
  %17 = add i32 %16, %15
  ret i32 %17
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @e2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 64
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %3
  %8 = and i32 %4, 3
  %9 = tail call fastcc i32 @h(i32 noundef %8, i32 noundef %2)
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %9, %7 ], [ 9, %3 ]
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #4
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 1, %2 ], [ %12, %6 ]
  ret i32 %5

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %12, %6 ], [ 1, %2 ]
  %9 = mul i32 %8, 3
  %10 = and i32 %8, 7
  %11 = lshr i32 %1, %10
  %12 = xor i32 %11, %9
  %13 = add nuw nsw i32 %7, 1
  %14 = icmp eq i32 %13, %0
  br i1 %14, label %4, label %6, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @e3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 64
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call fastcc i32 @k(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ 9, %3 ]
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #4
  ret i32 %11
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @k(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = tail call fastcc i32 @g(i32 noundef %0, i32 noundef %1)
  %4 = add i32 %3, 1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!9 = distinct !{!9, !7, !8}
