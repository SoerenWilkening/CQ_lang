; ModuleID = 'trip_exit.c'
source_filename = "trip_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@te_G = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @te_direct(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul nsw i32 %5, %5
  %7 = add nuw nsw i32 %6, 3
  %8 = lshr i32 %5, 1
  %9 = and i32 %7, 4
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !6

11:                                               ; preds = %4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %12
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @te_sub(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul nsw i32 %5, %5
  %7 = mul nsw i32 %5, 15
  %8 = lshr i32 %5, 1
  %9 = xor i32 %6, %7
  %10 = and i32 %9, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !9

12:                                               ; preds = %4
  %13 = sub nsw i32 %6, %7
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_meas(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %7, %4 ]
  %6 = mul nsw i32 %5, %5
  %7 = lshr i32 %5, 1
  %8 = and i32 %6, 4
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %4, !llvm.loop !10

10:                                               ; preds = %4
  %11 = add nuw nsw i32 %6, %7
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_store(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul nsw i32 %5, %5
  %7 = mul nsw i32 %5, 15
  %8 = lshr i32 %5, 1
  %9 = xor i32 %6, %7
  %10 = and i32 %9, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !11

12:                                               ; preds = %4
  %13 = sub nsw i32 %6, %7
  store i32 %13, ptr @te_G, align 4, !tbaa !12
  %14 = xor i32 %13, 1
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_ret(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul nsw i32 %5, %5
  %7 = mul nsw i32 %5, 15
  %8 = lshr i32 %5, 1
  %9 = xor i32 %6, %7
  %10 = and i32 %9, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !16

12:                                               ; preds = %4
  %13 = sub nsw i32 %6, %7
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_rot(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = mul i32 %5, %5
  %7 = mul i32 %5, 15
  %8 = lshr i32 %5, 1
  %9 = xor i32 %6, %7
  %10 = and i32 %9, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !17

12:                                               ; preds = %4
  %13 = sub i32 %6, %7
  %14 = tail call i32 @cq_theta_ui32(i32 noundef %13, double noundef %1) #3
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #4
  ret i32 %15
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @te_next(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ 1, %2 ], [ %8, %4 ]
  %6 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %7 = mul nsw i32 %6, %6
  %8 = xor i32 %7, %5
  %9 = lshr i32 %6, 1
  %10 = and i32 %7, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !18

12:                                               ; preds = %4
  %13 = sub nsw i32 %8, %5
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_cbr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %2, 1
  %6 = icmp eq i32 %5, 0
  br label %7

7:                                                ; preds = %13, %3
  %8 = phi i32 [ %4, %3 ], [ %16, %13 ]
  br i1 %6, label %11, label %9

9:                                                ; preds = %7
  %10 = tail call fastcc i32 @te_g(i32 noundef %8)
  br label %13

11:                                               ; preds = %7
  %12 = mul nsw i32 %8, %8
  br label %13

13:                                               ; preds = %11, %9
  %14 = phi i32 [ %10, %9 ], [ %12, %11 ]
  %15 = mul nsw i32 %8, 15
  %16 = lshr i32 %8, 1
  %17 = xor i32 %14, %15
  %18 = and i32 %17, 2
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %7, !llvm.loop !19

20:                                               ; preds = %13
  %21 = sub nsw i32 %14, %15
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  ret i32 %22
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @te_g(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_region(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %11, %2
  %5 = phi i32 [ %3, %2 ], [ %12, %11 ]
  %6 = mul nsw i32 %5, %5
  %7 = mul nsw i32 %5, 15
  %8 = xor i32 %6, %7
  %9 = and i32 %8, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %15

11:                                               ; preds = %4
  %12 = lshr i32 %5, 1
  %13 = and i32 %5, 128
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %4, label %17, !llvm.loop !20

15:                                               ; preds = %4
  %16 = sub nsw i32 %6, %7
  br label %17

17:                                               ; preds = %11, %15
  %18 = phi i32 [ %16, %15 ], [ %12, %11 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @te_nested(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = xor i32 %3, 5
  br label %5

5:                                                ; preds = %17, %2
  %6 = phi i32 [ 0, %2 ], [ %19, %17 ]
  %7 = phi i32 [ %4, %2 ], [ %20, %17 ]
  %8 = phi i32 [ %3, %2 ], [ %13, %17 ]
  br label %9

9:                                                ; preds = %9, %5
  %10 = phi i32 [ %8, %5 ], [ %13, %9 ]
  %11 = mul nsw i32 %10, %10
  %12 = mul nsw i32 %10, 15
  %13 = lshr i32 %10, 1
  %14 = xor i32 %11, %12
  %15 = and i32 %14, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %9, !llvm.loop !21

17:                                               ; preds = %9
  %18 = sub nsw i32 %11, %12
  %19 = add nsw i32 %18, %6
  %20 = lshr i32 %7, 1
  %21 = and i32 %7, 2
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %5, !llvm.loop !22

23:                                               ; preds = %17
  %24 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %24
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!12 = !{!13, !13, i64 0}
!13 = !{!"int", !14, i64 0}
!14 = !{!"omnipotent char", !15, i64 0}
!15 = !{!"Simple C/C++ TBAA"}
!16 = distinct !{!16, !7, !8}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !8}
!21 = distinct !{!21, !7, !8}
!22 = distinct !{!22, !7, !8}
