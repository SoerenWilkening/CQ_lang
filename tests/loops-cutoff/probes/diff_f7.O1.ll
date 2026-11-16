; ModuleID = 'diff_f7.c'
source_filename = "diff_f7.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f7_break(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2, %12
  %7 = phi i32 [ %13, %12 ], [ %3, %2 ]
  %8 = and i32 %7, 8
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %6
  %11 = mul i32 %7, 3
  br label %16

12:                                               ; preds = %6
  %13 = lshr i32 %7, 1
  %14 = and i32 %7, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %6, !llvm.loop !6

16:                                               ; preds = %12, %2, %10
  %17 = phi i32 [ %7, %10 ], [ %3, %2 ], [ %13, %12 ]
  %18 = phi i32 [ %11, %10 ], [ 0, %2 ], [ 0, %12 ]
  %19 = add i32 %18, %17
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #5
  ret i32 %20
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f7_ret(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %18, label %6

6:                                                ; preds = %2, %11
  %7 = phi i32 [ %12, %11 ], [ 1, %2 ]
  %8 = phi i32 [ %13, %11 ], [ %3, %2 ]
  %9 = and i32 %8, 4
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %18

11:                                               ; preds = %6
  %12 = add i32 %7, %8
  %13 = lshr i32 %8, 1
  %14 = and i32 %8, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %6, !llvm.loop !9

16:                                               ; preds = %11
  %17 = xor i32 %12, 7
  br label %18

18:                                               ; preds = %6, %2, %16
  %19 = phi i32 [ 6, %2 ], [ %17, %16 ], [ %7, %6 ]
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #5
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_cont(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %7, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %11, %4 ]
  %7 = lshr i32 %5, 1
  %8 = and i32 %5, 4
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, i32 %7, i32 0
  %11 = add i32 %10, %6
  %12 = and i32 %5, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %4, !llvm.loop !10

14:                                               ; preds = %4
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %11) #5
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_nest(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %23, label %6

6:                                                ; preds = %2, %18
  %7 = phi i32 [ %19, %18 ], [ 0, %2 ]
  %8 = phi i32 [ %20, %18 ], [ %3, %2 ]
  %9 = and i32 %8, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %18, label %11

11:                                               ; preds = %6, %11
  %12 = phi i32 [ %14, %11 ], [ %8, %6 ]
  %13 = phi i32 [ %15, %11 ], [ %7, %6 ]
  %14 = lshr i32 %12, 2
  %15 = add i32 %13, 1
  %16 = and i32 %12, 8
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %11, !llvm.loop !11

18:                                               ; preds = %11, %6
  %19 = phi i32 [ %7, %6 ], [ %15, %11 ]
  %20 = lshr i32 %8, 1
  %21 = and i32 %8, 2
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %6, !llvm.loop !12

23:                                               ; preds = %18, %2
  %24 = phi i32 [ %3, %2 ], [ %20, %18 ]
  %25 = phi i32 [ 0, %2 ], [ %19, %18 ]
  %26 = add i32 %25, %24
  %27 = tail call i32 @cq_measure_ui32(i32 noundef %26) #5
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define zeroext i8 @f7_u8(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #4
  %4 = and i8 %3, 1
  %5 = icmp eq i8 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i8 [ %10, %6 ], [ 3, %2 ]
  %8 = phi i8 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i8 %7, 5
  %10 = add i8 %9, %8
  %11 = lshr i8 %8, 1
  %12 = and i8 %8, 2
  %13 = icmp eq i8 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !13

14:                                               ; preds = %6, %2
  %15 = phi i8 [ 3, %2 ], [ %10, %6 ]
  %16 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %15) #5
  ret i8 %16
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @f7_u64(i64 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_ull(i64 noundef %0, double noundef %1) #4
  %4 = and i64 %3, 1
  %5 = icmp eq i64 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i64 [ %10, %6 ], [ 3, %2 ]
  %8 = phi i64 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i64 %7, 65537
  %10 = add i64 %9, %8
  %11 = lshr i64 %8, 1
  %12 = and i64 %8, 2
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !14

14:                                               ; preds = %6, %2
  %15 = phi i64 [ 3, %2 ], [ %10, %6 ]
  %16 = tail call i64 @cq_measure_ull(i64 noundef %15) #5
  ret i64 %16
}

declare i64 @cq_theta_ull(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f7_switch(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %4

4:                                                ; preds = %14, %2
  %5 = phi i32 [ %3, %2 ], [ %16, %14 ]
  %6 = phi i32 [ 0, %2 ], [ %15, %14 ]
  %7 = and i32 %5, 3
  switch i32 %7, label %12 [
    i32 0, label %8
    i32 1, label %10
  ]

8:                                                ; preds = %4
  %9 = add i32 %6, 1
  br label %14

10:                                               ; preds = %4
  %11 = xor i32 %6, 6
  br label %14

12:                                               ; preds = %4
  %13 = add i32 %6, %5
  br label %14

14:                                               ; preds = %12, %10, %8
  %15 = phi i32 [ %13, %12 ], [ %11, %10 ], [ %9, %8 ]
  %16 = lshr i32 %5, 2
  %17 = and i32 %5, 16
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %19, label %4, !llvm.loop !15

19:                                               ; preds = %14
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %15) #5
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_lcssa(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %11, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %10, %4 ]
  %7 = mul i32 %5, %5
  %8 = add i32 %7, %6
  %9 = and i32 %8, 3
  %10 = add i32 %9, %6
  %11 = lshr i32 %5, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %4, !llvm.loop !16

14:                                               ; preds = %4
  %15 = shl i32 %8, 1
  %16 = add i32 %10, %15
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_inner_c(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %25, label %7

7:                                                ; preds = %3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br label %10

10:                                               ; preds = %7, %13
  %11 = phi i32 [ 1, %7 ], [ %14, %13 ]
  %12 = phi i32 [ %4, %7 ], [ %15, %13 ]
  br i1 %9, label %13, label %18

13:                                               ; preds = %18, %10
  %14 = phi i32 [ %11, %10 ], [ %22, %18 ]
  %15 = lshr i32 %12, 1
  %16 = and i32 %12, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %25, label %10, !llvm.loop !17

18:                                               ; preds = %10, %18
  %19 = phi i32 [ %23, %18 ], [ 0, %10 ]
  %20 = phi i32 [ %22, %18 ], [ %11, %10 ]
  %21 = mul i32 %20, 3
  %22 = add i32 %21, %12
  %23 = add nuw nsw i32 %19, 1
  %24 = icmp eq i32 %23, %8
  br i1 %24, label %13, label %18, !llvm.loop !18

25:                                               ; preds = %13, %3
  %26 = phi i32 [ 1, %3 ], [ %14, %13 ]
  %27 = tail call i32 @cq_measure_ui32(i32 noundef %26) #5
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_mix(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %4

4:                                                ; preds = %2, %4
  %5 = phi i32 [ 0, %2 ], [ %9, %4 ]
  %6 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %7 = mul i32 %6, 5
  %8 = add i32 %7, 1
  %9 = add i32 %5, 1
  %10 = icmp ult i32 %9, 3
  %11 = and i32 %7, 1
  %12 = icmp eq i32 %11, 0
  %13 = select i1 %10, i1 true, i1 %12
  br i1 %13, label %4, label %14, !llvm.loop !19

14:                                               ; preds = %4
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  %16 = add i32 %15, %9
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f7_call_unc(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = tail call fastcc i32 @f7_h(i32 noundef %3)
  %5 = and i32 %4, 2
  %6 = icmp eq i32 %5, 0
  %7 = add i32 %3, 5
  %8 = select i1 %6, i32 %3, i32 %7
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  ret i32 %9
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f7_h(i32 noundef %0) unnamed_addr #2 {
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
  br i1 %11, label %12, label %4, !llvm.loop !20

12:                                               ; preds = %4, %1
  %13 = phi i32 [ 1, %1 ], [ %8, %4 ]
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define double @f7_dbl(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi double [ %9, %6 ], [ 1.000000e+00, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = tail call double @llvm.fmuladd.f64(double %7, double 1.500000e+00, double 2.500000e-01)
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !21

13:                                               ; preds = %6, %2
  %14 = phi double [ 1.000000e+00, %2 ], [ %9, %6 ]
  %15 = tail call double @cq_measure_f64(double noundef %14) #5
  ret double %15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
!21 = distinct !{!21, !7, !8}
