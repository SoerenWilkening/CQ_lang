; ModuleID = 'diff_f4.c'
source_filename = "diff_f4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@f4_fp = global ptr @f4_g, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @f4_qif(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 17
  %5 = icmp eq i32 %4, 17
  br i1 %5, label %6, label %13

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !6

13:                                               ; preds = %6, %2
  %14 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %15 = phi i32 [ 1, %2 ], [ %9, %6 ]
  %16 = add i32 %15, %14
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #4
  ret i32 %17
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f4_cif(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3
  %5 = and i32 %1, 1
  %6 = icmp eq i32 %5, 0
  %7 = and i32 %4, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %6, i1 true, i1 %8
  br i1 %9, label %17, label %10

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %13, %10 ], [ 1, %3 ]
  %12 = phi i32 [ %14, %10 ], [ %4, %3 ]
  %13 = add i32 %11, %12
  %14 = lshr i32 %12, 1
  %15 = and i32 %12, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %10, !llvm.loop !9

17:                                               ; preds = %10, %3
  %18 = phi i32 [ %4, %3 ], [ %14, %10 ]
  %19 = phi i32 [ 1, %3 ], [ %13, %10 ]
  %20 = add i32 %19, %18
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %20) #4
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_cfor(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %2, %20
  %5 = phi i32 [ 0, %2 ], [ %25, %20 ]
  %6 = phi i32 [ 1, %2 ], [ %22, %20 ]
  %7 = phi i32 [ %3, %2 ], [ %24, %20 ]
  %8 = and i32 %7, 1
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %20, label %13

10:                                               ; preds = %20
  %11 = add i32 %22, %24
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %4, %13
  %14 = phi i32 [ %16, %13 ], [ %6, %4 ]
  %15 = phi i32 [ %17, %13 ], [ %7, %4 ]
  %16 = add i32 %14, %15
  %17 = lshr i32 %15, 1
  %18 = and i32 %15, 2
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %13, !llvm.loop !10

20:                                               ; preds = %13, %4
  %21 = phi i32 [ %7, %4 ], [ %17, %13 ]
  %22 = phi i32 [ %6, %4 ], [ %16, %13 ]
  %23 = mul i32 %21, 3
  %24 = add nuw nsw i32 %23, 1
  %25 = add nuw nsw i32 %5, 1
  %26 = icmp eq i32 %5, 0
  br i1 %26, label %4, label %10, !llvm.loop !11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_cforn(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3
  %5 = and i32 %1, 3
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %13, label %7

7:                                                ; preds = %3, %25
  %8 = phi i32 [ %29, %25 ], [ 0, %3 ]
  %9 = phi i32 [ %27, %25 ], [ 1, %3 ]
  %10 = phi i32 [ %28, %25 ], [ %4, %3 ]
  %11 = and i32 %10, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %25, label %18

13:                                               ; preds = %25, %3
  %14 = phi i32 [ %4, %3 ], [ %28, %25 ]
  %15 = phi i32 [ 1, %3 ], [ %27, %25 ]
  %16 = xor i32 %15, %14
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #4
  ret i32 %17

18:                                               ; preds = %7, %18
  %19 = phi i32 [ %21, %18 ], [ %9, %7 ]
  %20 = phi i32 [ %22, %18 ], [ %10, %7 ]
  %21 = add i32 %19, %20
  %22 = lshr i32 %20, 1
  %23 = and i32 %20, 2
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %18, !llvm.loop !12

25:                                               ; preds = %18, %7
  %26 = phi i32 [ %10, %7 ], [ %22, %18 ]
  %27 = phi i32 [ %9, %7 ], [ %21, %18 ]
  %28 = add i32 %26, 3
  %29 = add nuw nsw i32 %8, 1
  %30 = icmp eq i32 %29, %5
  br i1 %30, label %13, label %7, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_after_meas(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = mul i32 %3, 3
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #3
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %3) #4
  %7 = and i32 %5, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %16, label %9

9:                                                ; preds = %2, %9
  %10 = phi i32 [ %12, %9 ], [ %6, %2 ]
  %11 = phi i32 [ %13, %9 ], [ %5, %2 ]
  %12 = add i32 %10, %11
  %13 = lshr i32 %11, 1
  %14 = and i32 %11, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %9, !llvm.loop !14

16:                                               ; preds = %9, %2
  %17 = phi i32 [ %6, %2 ], [ %12, %9 ]
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #4
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_call1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = tail call i32 @f4_g(i32 noundef %3)
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #4
  ret i32 %5
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @f4_g(i32 noundef %0) #2 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %11, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %7, %4 ], [ 1, %1 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %1 ]
  %7 = add i32 %5, %6
  %8 = lshr i32 %6, 1
  %9 = and i32 %6, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !15

11:                                               ; preds = %4, %1
  %12 = phi i32 [ %0, %1 ], [ %8, %4 ]
  %13 = phi i32 [ 1, %1 ], [ %7, %4 ]
  %14 = xor i32 %13, %12
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_call2(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = tail call i32 @f4_g(i32 noundef %3)
  %5 = add i32 %4, 1
  %6 = tail call i32 @f4_g(i32 noundef %5)
  %7 = mul i32 %4, 3
  %8 = add i32 %7, %6
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_callq(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 32
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %2
  %7 = tail call i32 @f4_g(i32 noundef %3)
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ %7, %6 ], [ 7, %2 ]
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_calln(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3
  %5 = and i32 %1, 7
  %6 = tail call fastcc i32 @f4_gn(i32 noundef %4, i32 noundef %5)
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f4_gn(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp ne i32 %1, 0
  %4 = and i32 %0, 1
  %5 = icmp ne i32 %4, 0
  %6 = and i1 %3, %5
  br i1 %6, label %11, label %7

7:                                                ; preds = %11, %2
  %8 = phi i32 [ %0, %2 ], [ %16, %11 ]
  %9 = phi i32 [ 1, %2 ], [ %15, %11 ]
  %10 = xor i32 %9, %8
  ret i32 %10

11:                                               ; preds = %2, %11
  %12 = phi i32 [ %17, %11 ], [ 0, %2 ]
  %13 = phi i32 [ %15, %11 ], [ 1, %2 ]
  %14 = phi i32 [ %16, %11 ], [ %0, %2 ]
  %15 = add i32 %13, %14
  %16 = lshr i32 %14, 1
  %17 = add nuw nsw i32 %12, 1
  %18 = icmp ult i32 %17, %1
  %19 = and i32 %14, 2
  %20 = icmp ne i32 %19, 0
  %21 = select i1 %18, i1 %20, i1 false
  br i1 %21, label %11, label %7, !llvm.loop !16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f4_fptr(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = load volatile ptr, ptr @f4_fp, align 8, !tbaa !17
  %5 = tail call i32 %4(i32 noundef %3) #4
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  ret i32 %6
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
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
!17 = !{!18, !18, i64 0}
!18 = !{!"any pointer", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
