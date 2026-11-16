; ModuleID = 'diff_f8.c'
source_filename = "diff_f8.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f8_call_in(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 2
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = tail call fastcc i32 @f8_g(i32 noundef %8)
  %10 = add i32 %9, %7
  %11 = lshr i32 %8, 2
  %12 = and i32 %8, 8
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !6

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #5
  ret i32 %16
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f8_g(i32 noundef %0) unnamed_addr #2 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %12, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %8, %4 ], [ 1, %1 ]
  %6 = phi i32 [ %9, %4 ], [ %0, %1 ]
  %7 = mul i32 %5, 3
  %8 = add i32 %7, %6
  %9 = lshr i32 %6, 1
  %10 = and i32 %6, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !9

12:                                               ; preds = %4, %1
  %13 = phi i32 [ 1, %1 ], [ %8, %4 ]
  ret i32 %13
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f8_recur(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = tail call fastcc i32 @f8_rec(i32 noundef %3)
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #5
  ret i32 %5
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f8_rec(i32 noundef %0) unnamed_addr #3 {
  br label %2

2:                                                ; preds = %7, %1
  %3 = phi i32 [ 0, %1 ], [ %9, %7 ]
  %4 = phi i32 [ %0, %1 ], [ %8, %7 ]
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %2
  %8 = lshr i32 %4, 1
  %9 = add i32 %3, 3
  br label %2

10:                                               ; preds = %2
  %11 = add i32 %3, %4
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_arm_exit(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %11, %4 ]
  %6 = and i32 %5, 4
  %7 = icmp eq i32 %6, 0
  %8 = add i32 %5, 1
  %9 = mul i32 %5, 3
  %10 = select i1 %7, i32 %9, i32 %8
  %11 = lshr i32 %5, 1
  %12 = and i32 %10, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %4, !llvm.loop !10

14:                                               ; preds = %4
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %10) #5
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_flag(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i1 [ %9, %6 ], [ false, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = xor i1 %7, true
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !11

13:                                               ; preds = %6, %2
  %14 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %15 = phi i1 [ false, %2 ], [ %9, %6 ]
  %16 = add i32 %14, 100
  %17 = select i1 %15, i32 %14, i32 %16
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #5
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_test_only(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 3
  %5 = icmp eq i32 %4, 1
  br i1 %5, label %12, label %6

6:                                                ; preds = %2
  %7 = and i32 %3, 3
  %8 = icmp eq i32 %7, 3
  br label %9

9:                                                ; preds = %6, %9
  %10 = phi i32 [ %11, %9 ], [ 0, %6 ]
  %11 = add i32 %10, 1
  br i1 %8, label %12, label %9, !llvm.loop !12

12:                                               ; preds = %9, %2
  %13 = phi i32 [ 0, %2 ], [ %11, %9 ]
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %13) #5
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_ptr(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, i32 9, i32 0
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #5
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_two_loops(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #4
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %13

8:                                                ; preds = %13, %3
  %9 = phi i32 [ %4, %3 ], [ %17, %13 ]
  %10 = phi i32 [ 0, %3 ], [ %16, %13 ]
  %11 = and i32 %5, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %27, label %20

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %16, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %17, %13 ], [ %4, %3 ]
  %16 = add i32 %14, 2
  %17 = lshr i32 %15, 1
  %18 = and i32 %15, 2
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %8, label %13, !llvm.loop !13

20:                                               ; preds = %8, %20
  %21 = phi i32 [ %23, %20 ], [ 0, %8 ]
  %22 = phi i32 [ %24, %20 ], [ %5, %8 ]
  %23 = add i32 %21, %10
  %24 = lshr i32 %22, 1
  %25 = and i32 %22, 2
  %26 = icmp eq i32 %25, 0
  br i1 %26, label %27, label %20, !llvm.loop !14

27:                                               ; preds = %20, %8
  %28 = phi i32 [ %5, %8 ], [ %24, %20 ]
  %29 = phi i32 [ 0, %8 ], [ %23, %20 ]
  %30 = mul i32 %10, 7
  %31 = add i32 %30, %9
  %32 = add i32 %31, %28
  %33 = add i32 %32, %29
  %34 = tail call i32 @cq_measure_ui32(i32 noundef %33) #5
  ret i32 %34
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_ctl_exit(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = and i32 %4, 64
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call fastcc i32 @f8_h(i32 noundef %4, i32 noundef %1)
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ %1, %3 ]
  %11 = xor i32 %10, %4
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #5
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f8_h(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  br label %3

3:                                                ; preds = %3, %2
  %4 = phi i32 [ %0, %2 ], [ %8, %3 ]
  %5 = phi i32 [ %1, %2 ], [ %7, %3 ]
  %6 = mul i32 %5, 5
  %7 = add i32 %6, %4
  %8 = lshr i32 %4, 1
  %9 = and i32 %4, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %3, !llvm.loop !15

11:                                               ; preds = %3
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f8_phi_val(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %17, label %6

6:                                                ; preds = %2, %13
  %7 = phi i32 [ %9, %13 ], [ 0, %2 ]
  %8 = phi i32 [ %14, %13 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = and i32 %9, 8
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef %1) #5
  br label %13

13:                                               ; preds = %12, %6
  %14 = lshr i32 %8, 1
  %15 = and i32 %8, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %6, !llvm.loop !16

17:                                               ; preds = %13, %2
  %18 = phi i32 [ 0, %2 ], [ %9, %13 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #5
  ret i32 %19
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
