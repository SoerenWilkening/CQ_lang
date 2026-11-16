; ModuleID = 'diff_f6.c'
source_filename = "diff_f6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k_f6_k1 = internal constant i32 1, align 4
@__cq_k_f6_k2 = internal constant i32 2, align 4
@__cq_k_f6_k7 = internal constant i32 7, align 4
@__cq_k_f6_k1n = internal constant i32 1, align 4
@llvm.used = appending global [4 x ptr] [ptr @__cq_k_f6_k1, ptr @__cq_k_f6_k1n, ptr @__cq_k_f6_k2, ptr @__cq_k_f6_k7], section "llvm.metadata"

; Function Attrs: nounwind ssp uwtable
define i32 @f6_k1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 3
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !6

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 1, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f6_k2(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 3
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !9

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 1, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_k7(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 3
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !10

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 1, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_k4(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = mul i32 %7, 3
  %10 = add i32 %9, %8
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !11

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 1, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_bound(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = icmp ne i32 %1, 0
  %6 = and i32 %4, 1
  %7 = icmp ne i32 %6, 0
  %8 = select i1 %5, i1 %7, i1 false
  br i1 %8, label %12, label %9

9:                                                ; preds = %12, %3
  %10 = phi i32 [ 1, %3 ], [ %17, %12 ]
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #3
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i32 [ %19, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %17, %12 ], [ 1, %3 ]
  %15 = phi i32 [ %18, %12 ], [ %4, %3 ]
  %16 = mul i32 %14, 3
  %17 = add i32 %16, %15
  %18 = lshr i32 %15, 1
  %19 = add nuw i32 %13, 1
  %20 = icmp ult i32 %19, %1
  %21 = and i32 %15, 2
  %22 = icmp ne i32 %21, 0
  %23 = select i1 %20, i1 %22, i1 false
  br i1 %23, label %12, label %9, !llvm.loop !12
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_k1n(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %5 = icmp ne i32 %1, 0
  %6 = and i32 %4, 1
  %7 = icmp ne i32 %6, 0
  %8 = select i1 %5, i1 %7, i1 false
  br i1 %8, label %12, label %9

9:                                                ; preds = %12, %3
  %10 = phi i32 [ 1, %3 ], [ %17, %12 ]
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #3
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i32 [ %19, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %17, %12 ], [ 1, %3 ]
  %15 = phi i32 [ %18, %12 ], [ %4, %3 ]
  %16 = mul i32 %14, 3
  %17 = add i32 %16, %15
  %18 = lshr i32 %15, 1
  %19 = add nuw i32 %13, 1
  %20 = icmp ult i32 %19, %1
  %21 = and i32 %15, 2
  %22 = icmp ne i32 %21, 0
  %23 = select i1 %20, i1 %22, i1 false
  br i1 %23, label %12, label %9, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_do(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %6 = phi i32 [ 1, %2 ], [ %8, %4 ]
  %7 = mul i32 %6, 3
  %8 = add i32 %7, %5
  %9 = lshr i32 %5, 1
  %10 = and i32 %5, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !14

12:                                               ; preds = %4
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %8) #3
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f6_long(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = or i32 %0, 255
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %1) #2
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %15, label %7

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %11, %7 ], [ 1, %2 ]
  %9 = phi i32 [ %12, %7 ], [ %4, %2 ]
  %10 = mul i32 %8, 3
  %11 = add i32 %10, %9
  %12 = lshr i32 %9, 1
  %13 = and i32 %9, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %7, !llvm.loop !15

15:                                               ; preds = %7, %2
  %16 = phi i32 [ 1, %2 ], [ %11, %7 ]
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #3
  ret i32 %17
}

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
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
