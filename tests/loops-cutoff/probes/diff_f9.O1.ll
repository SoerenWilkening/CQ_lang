; ModuleID = 'diff_f9.c'
source_filename = "diff_f9.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k_f9_rk = internal constant i32 2, align 4
@f9_tab = internal unnamed_addr constant [16 x i16] [i16 5, i16 3, i16 0, i16 7, i16 1, i16 9, i16 2, i16 8, i16 0, i16 4, i16 6, i16 1, i16 3, i16 0, i16 2, i16 5], align 16
@llvm.used = appending global [1 x ptr] [ptr @__cq_k_f9_rk], section "llvm.metadata"

; Function Attrs: nounwind ssp uwtable
define i32 @f9_meas_arm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !6

9:                                                ; preds = %4
  %10 = mul i32 %5, 3
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #4
  ret i32 %11
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f9_meas_carry(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %12, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %13, %6 ], [ %3, %2 ]
  %9 = shl i32 %7, 1
  %10 = and i32 %8, 2
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #4
  %12 = add i32 %11, %9
  %13 = lshr i32 %8, 1
  %14 = and i32 %8, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %6, !llvm.loop !8

16:                                               ; preds = %6, %2
  %17 = phi i32 [ %3, %2 ], [ %13, %6 ]
  %18 = phi i32 [ 0, %2 ], [ %12, %6 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %17) #4
  %20 = add i32 %19, %18
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @f9_rk(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 4
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = tail call fastcc i32 @f9_g(i32 noundef %8)
  %10 = add i32 %9, %7
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 8
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !10

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #4
  ret i32 %16
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f9_g(i32 noundef %0) unnamed_addr #2 {
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
  br i1 %11, label %12, label %4, !llvm.loop !11

12:                                               ; preds = %4, %1
  %13 = phi i32 [ 1, %1 ], [ %8, %4 ]
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f9_latches(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %20, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %17, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %12, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = shl i32 %8, 4
  %11 = and i32 %10, 32
  %12 = or i32 %11, %9
  %13 = and i32 %8, 16
  %14 = icmp eq i32 %13, 0
  %15 = add i32 %7, 5
  %16 = xor i32 %12, %7
  %17 = select i1 %14, i32 %16, i32 %15
  %18 = and i32 %8, 2
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %6, !llvm.loop !12

20:                                               ; preds = %6, %2
  %21 = phi i32 [ %3, %2 ], [ %12, %6 ]
  %22 = phi i32 [ 0, %2 ], [ %17, %6 ]
  %23 = add i32 %22, %21
  %24 = tail call i32 @cq_measure_ui32(i32 noundef %23) #4
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define signext i16 @f9_i16(i16 noundef signext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef %1) #3
  %4 = icmp sgt i16 %3, 100
  br i1 %4, label %5, label %11

5:                                                ; preds = %2, %5
  %6 = phi i16 [ %8, %5 ], [ 0, %2 ]
  %7 = phi i16 [ %9, %5 ], [ %3, %2 ]
  %8 = add i16 %6, 7
  %9 = udiv i16 %7, 3
  %10 = icmp ugt i16 %7, 302
  br i1 %10, label %5, label %11, !llvm.loop !13

11:                                               ; preds = %5, %2
  %12 = phi i16 [ %3, %2 ], [ %9, %5 ]
  %13 = phi i16 [ 0, %2 ], [ %8, %5 ]
  %14 = add i16 %13, %12
  %15 = tail call signext i16 @cq_measure_si16(i16 noundef signext %14) #4
  ret i16 %15
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f9_struct(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = tail call fastcc i64 @f9_pair(i32 noundef %3)
  %5 = trunc i64 %4 to i32
  %6 = lshr i64 %4, 32
  %7 = trunc nuw i64 %6 to i32
  %8 = mul i32 %5, 3
  %9 = add i32 %8, %7
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  ret i32 %10
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i64 @f9_pair(i32 noundef %0) unnamed_addr #2 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %18, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %10, %4 ], [ %0, %1 ]
  %6 = phi i32 [ %8, %4 ], [ 1, %1 ]
  %7 = phi i32 [ %9, %4 ], [ 2, %1 ]
  %8 = add i32 %6, %7
  %9 = xor i32 %5, %7
  %10 = lshr i32 %5, 1
  %11 = and i32 %5, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %4, !llvm.loop !14

13:                                               ; preds = %4
  %14 = zext i32 %9 to i64
  %15 = shl nuw i64 %14, 32
  %16 = zext i32 %8 to i64
  %17 = or disjoint i64 %15, %16
  br label %18

18:                                               ; preds = %13, %1
  %19 = phi i64 [ 8589934593, %1 ], [ %17, %13 ]
  ret i64 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f9_rot_arm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 4, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !15

13:                                               ; preds = %6, %2
  %14 = phi i32 [ %3, %2 ], [ %10, %6 ]
  %15 = phi i32 [ 4, %2 ], [ %9, %6 ]
  %16 = and i32 %14, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %20, label %18

18:                                               ; preds = %13
  %19 = tail call i32 @cq_theta_ui32(i32 noundef %15, double noundef %1) #3
  br label %20

20:                                               ; preds = %18, %13
  %21 = phi i32 [ %19, %18 ], [ %15, %13 ]
  %22 = tail call i32 @cq_measure_ui32(i32 noundef %21) #4
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @f9_chase(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 15
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %1) #3
  %5 = and i32 %4, 15
  %6 = zext nneg i32 %5 to i64
  %7 = lshr i64 8452, %6
  %8 = and i64 %7, 1
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %10, label %26

10:                                               ; preds = %2, %10
  %11 = phi i64 [ %20, %10 ], [ %6, %2 ]
  %12 = phi i32 [ %19, %10 ], [ %5, %2 ]
  %13 = phi i32 [ %18, %10 ], [ 0, %2 ]
  %14 = getelementptr inbounds [16 x i16], ptr @f9_tab, i64 0, i64 %11
  %15 = load i16, ptr %14, align 2, !tbaa !16
  %16 = zext i16 %15 to i32
  %17 = add nuw nsw i32 %12, %16
  %18 = add i32 %13, 1
  %19 = and i32 %17, 15
  %20 = zext nneg i32 %19 to i64
  %21 = lshr i64 8452, %20
  %22 = and i64 %21, 1
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %10, label %24, !llvm.loop !20

24:                                               ; preds = %10
  %25 = shl i32 %18, 4
  br label %26

26:                                               ; preds = %24, %2
  %27 = phi i32 [ 0, %2 ], [ %25, %24 ]
  %28 = phi i32 [ %5, %2 ], [ %19, %24 ]
  %29 = or disjoint i32 %28, %27
  %30 = tail call i32 @cq_measure_ui32(i32 noundef %29) #4
  ret i32 %30
}

; Function Attrs: nounwind ssp uwtable
define i32 @f9_for_n(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ 0, %2 ], [ %9, %4 ]
  %6 = shl nuw i32 1, %5
  %7 = and i32 %6, %3
  %8 = icmp eq i32 %7, 0
  %9 = add i32 %5, 1
  br i1 %8, label %10, label %4, !llvm.loop !21

10:                                               ; preds = %4
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  ret i32 %11
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = distinct !{!8, !9, !7}
!9 = !{!"llvm.loop.mustprogress"}
!10 = distinct !{!10, !9, !7}
!11 = distinct !{!11, !9, !7}
!12 = distinct !{!12, !9, !7}
!13 = distinct !{!13, !9, !7}
!14 = distinct !{!14, !9, !7}
!15 = distinct !{!15, !9, !7}
!16 = !{!17, !17, i64 0}
!17 = !{!"short", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = distinct !{!20, !9, !7}
!21 = distinct !{!21, !9, !7}
