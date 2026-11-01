; ModuleID = 'loops.c'
source_filename = "loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_acc(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @llvm.smax.i32(i32 %2, i32 1)
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i32 [ 0, %4 ], [ %11, %7 ]
  %9 = phi i32 [ 0, %4 ], [ %12, %7 ]
  %10 = mul nsw i32 %8, %3
  %11 = add nsw i32 %10, %5
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, %6
  br i1 %13, label %14, label %7, !llvm.loop !6

14:                                               ; preds = %7
  %15 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_brk(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  br label %7

7:                                                ; preds = %7, %5
  %8 = phi i32 [ 0, %5 ], [ %11, %7 ]
  %9 = phi i32 [ 0, %5 ], [ %12, %7 ]
  %10 = mul nsw i32 %8, %4
  %11 = add nsw i32 %10, %9
  %12 = add nuw nsw i32 %9, 1
  %13 = add nsw i32 %12, %3
  %14 = icmp ne i32 %6, %13
  %15 = icmp slt i32 %12, %2
  %16 = and i1 %15, %14
  br i1 %16, label %7, label %17, !llvm.loop !9

17:                                               ; preds = %7
  %18 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_nest(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %7 = tail call i32 @llvm.smax.i32(i32 %3, i32 1)
  %8 = tail call i32 @llvm.smax.i32(i32 %2, i32 1)
  br label %9

9:                                                ; preds = %21, %5
  %10 = phi i32 [ 0, %5 ], [ %18, %21 ]
  %11 = phi i32 [ 0, %5 ], [ %22, %21 ]
  %12 = mul nsw i32 %11, %4
  br label %13

13:                                               ; preds = %13, %9
  %14 = phi i32 [ %10, %9 ], [ %18, %13 ]
  %15 = phi i32 [ 0, %9 ], [ %19, %13 ]
  %16 = add nsw i32 %15, %12
  %17 = xor i32 %16, %6
  %18 = add nsw i32 %17, %14
  %19 = add nuw nsw i32 %15, 1
  %20 = icmp eq i32 %19, %7
  br i1 %20, label %21, label %13, !llvm.loop !10

21:                                               ; preds = %13
  %22 = add nuw nsw i32 %11, 1
  %23 = icmp eq i32 %22, %8
  br i1 %23, label %24, label %9, !llvm.loop !11

24:                                               ; preds = %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_mod(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %7 = tail call i32 @llvm.smax.i32(i32 %4, i32 1)
  br label %8

8:                                                ; preds = %19, %5
  %9 = phi i32 [ 1, %5 ], [ %20, %19 ]
  %10 = phi i32 [ %2, %5 ], [ %21, %19 ]
  %11 = phi i32 [ 0, %5 ], [ %22, %19 ]
  %12 = urem i32 %10, %3
  %13 = shl nuw i32 1, %11
  %14 = and i32 %13, %6
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %19, label %16

16:                                               ; preds = %8
  %17 = mul i32 %12, %9
  %18 = urem i32 %17, %3
  br label %19

19:                                               ; preds = %16, %8
  %20 = phi i32 [ %18, %16 ], [ %9, %8 ]
  %21 = mul i32 %12, %12
  %22 = add nuw nsw i32 %11, 1
  %23 = icmp eq i32 %22, %7
  br i1 %23, label %24, label %8, !llvm.loop !12

24:                                               ; preds = %19
  %25 = tail call i32 @cq_measure_ui32(i32 noundef %20) #5
  %26 = tail call i32 @cq_measure_ui32(i32 noundef %6) #5
  %27 = add i32 %26, %25
  ret i32 %27
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_nb(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %7 = tail call i32 @llvm.smax.i32(i32 %2, i32 1)
  br label %8

8:                                                ; preds = %21, %5
  %9 = phi i32 [ 0, %5 ], [ %16, %21 ]
  %10 = phi i32 [ 0, %5 ], [ %22, %21 ]
  br label %11

11:                                               ; preds = %11, %8
  %12 = phi i32 [ %9, %8 ], [ %16, %11 ]
  %13 = phi i32 [ 0, %8 ], [ %18, %11 ]
  %14 = add nuw nsw i32 %13, %10
  %15 = xor i32 %14, %6
  %16 = add nsw i32 %15, %12
  %17 = icmp sle i32 %16, %4
  %18 = add nuw nsw i32 %13, 1
  %19 = icmp slt i32 %18, %3
  %20 = select i1 %17, i1 %19, i1 false
  br i1 %20, label %11, label %21, !llvm.loop !13

21:                                               ; preds = %11
  %22 = add nuw nsw i32 %10, 1
  %23 = icmp eq i32 %22, %7
  br i1 %23, label %24, label %8, !llvm.loop !14

24:                                               ; preds = %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define double @p_horner(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %6 = load double, ptr %2, align 8, !tbaa !15
  %7 = tail call i32 @llvm.smax.i32(i32 %3, i32 2)
  %8 = zext nneg i32 %7 to i64
  br label %9

9:                                                ; preds = %9, %4
  %10 = phi i64 [ %15, %9 ], [ 1, %4 ]
  %11 = phi double [ %14, %9 ], [ %6, %4 ]
  %12 = getelementptr inbounds double, ptr %2, i64 %10
  %13 = load double, ptr %12, align 8, !tbaa !15
  %14 = tail call double @llvm.fmuladd.f64(double %11, double %5, double %13)
  %15 = add nuw nsw i64 %10, 1
  %16 = icmp eq i64 %15, %8
  br i1 %16, label %17, label %9, !llvm.loop !19

17:                                               ; preds = %9
  %18 = tail call double @cq_measure_f64(double noundef %14) #5
  ret double %18
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_arm(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %19, label %9

9:                                                ; preds = %5, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %5 ]
  %11 = phi i32 [ %14, %9 ], [ 0, %5 ]
  %12 = mul nsw i32 %10, %4
  %13 = add nsw i32 %12, %11
  %14 = add nuw nsw i32 %11, 1
  %15 = add nsw i32 %14, %3
  %16 = icmp ne i32 %6, %15
  %17 = icmp slt i32 %14, %2
  %18 = and i1 %17, %16
  br i1 %18, label %9, label %19, !llvm.loop !20

19:                                               ; preds = %9, %5
  %20 = phi i32 [ 0, %5 ], [ %13, %9 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_phase(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @llvm.smax.i32(i32 %2, i32 1)
  br label %7

7:                                                ; preds = %13, %4
  %8 = phi i32 [ 0, %4 ], [ %14, %13 ]
  %9 = shl nuw i32 1, %8
  %10 = and i32 %9, %5
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %7
  tail call void @cq_phi(double noundef %3) #5
  br label %13

13:                                               ; preds = %12, %7
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, %6
  br i1 %15, label %16, label %7, !llvm.loop !21

16:                                               ; preds = %13
  %17 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %17
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_cjoin(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @llvm.smax.i32(i32 %2, i32 1)
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i32 [ 0, %4 ], [ %14, %7 ]
  %9 = phi i32 [ 0, %4 ], [ %15, %7 ]
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  %12 = add nsw i32 %8, %5
  %13 = xor i32 %9, %8
  %14 = select i1 %11, i32 %13, i32 %12
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %15, %6
  br i1 %16, label %17, label %7, !llvm.loop !22

17:                                               ; preds = %7
  %18 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_tphase(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  br label %7

7:                                                ; preds = %7, %5
  %8 = phi i32 [ 0, %5 ], [ %10, %7 ]
  %9 = phi i32 [ 0, %5 ], [ %11, %7 ]
  tail call void @cq_phi(double noundef %4) #5
  %10 = add nuw nsw i32 %9, %8
  %11 = add nuw nsw i32 %9, 1
  %12 = add nsw i32 %11, %3
  %13 = icmp ne i32 %6, %12
  %14 = icmp slt i32 %11, %2
  %15 = and i1 %14, %13
  br i1 %15, label %7, label %16, !llvm.loop !23

16:                                               ; preds = %7
  %17 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_bwb(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %7 = icmp slt i32 %2, 1
  %8 = icmp eq i32 %6, %3
  %9 = select i1 %7, i1 true, i1 %8
  br i1 %9, label %20, label %10

10:                                               ; preds = %5, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %5 ]
  %12 = phi i32 [ %14, %10 ], [ 0, %5 ]
  %13 = mul nsw i32 %12, %4
  %14 = add nsw i32 %13, %11
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp sge i32 %15, %2
  %17 = add nsw i32 %15, %3
  %18 = icmp eq i32 %6, %17
  %19 = select i1 %16, i1 true, i1 %18
  br i1 %19, label %20, label %10, !llvm.loop !24

20:                                               ; preds = %10, %5
  %21 = phi i32 [ 0, %5 ], [ %14, %10 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #5
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_g2(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = icmp slt i32 %2, 1
  %7 = icmp eq i32 %5, %3
  %8 = select i1 %6, i1 true, i1 %7
  br i1 %8, label %16, label %9

9:                                                ; preds = %4, %9
  %10 = phi i32 [ %11, %9 ], [ 0, %4 ]
  tail call void @cq_phi(double noundef 5.000000e-01) #5
  %11 = add nuw nsw i32 %10, 1
  %12 = icmp sge i32 %11, %2
  %13 = add nsw i32 %11, %3
  %14 = icmp eq i32 %5, %13
  %15 = select i1 %12, i1 true, i1 %14
  br i1 %15, label %16, label %9, !llvm.loop !25

16:                                               ; preds = %9, %4
  %17 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_edge_seed(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %4
  %8 = icmp sgt i32 %2, 0
  br label %9

9:                                                ; preds = %7, %14
  %10 = phi i32 [ 0, %7 ], [ %20, %14 ]
  %11 = phi i32 [ 0, %7 ], [ %19, %14 ]
  br i1 %8, label %22, label %14

12:                                               ; preds = %14, %4
  %13 = phi i32 [ 0, %4 ], [ %19, %14 ]
  ret i32 %13

14:                                               ; preds = %22, %9
  %15 = phi i32 [ 0, %9 ], [ %26, %22 ]
  %16 = icmp eq i32 %15, 3
  %17 = zext i1 %16 to i32
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %19 = add nsw i32 %18, %11
  %20 = add nuw nsw i32 %10, 1
  %21 = icmp eq i32 %20, %3
  br i1 %21, label %12, label %9, !llvm.loop !26

22:                                               ; preds = %9, %22
  %23 = phi i32 [ %27, %22 ], [ 0, %9 ]
  %24 = phi i32 [ %26, %22 ], [ 0, %9 ]
  %25 = lshr i32 %5, %23
  %26 = add i32 %25, %24
  %27 = add nuw nsw i32 %23, 1
  %28 = icmp eq i32 %27, %2
  br i1 %28, label %14, label %22, !llvm.loop !27
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!15 = !{!16, !16, i64 0}
!16 = !{!"double", !17, i64 0}
!17 = !{!"omnipotent char", !18, i64 0}
!18 = !{!"Simple C/C++ TBAA"}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
!21 = distinct !{!21, !7, !8}
!22 = distinct !{!22, !7, !8}
!23 = distinct !{!23, !7, !8}
!24 = distinct !{!24, !7, !8}
!25 = distinct !{!25, !7, !8}
!26 = distinct !{!26, !7, !8}
!27 = distinct !{!27, !7, !8}
