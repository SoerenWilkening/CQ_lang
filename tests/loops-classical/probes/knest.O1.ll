; ModuleID = 'knest.c'
source_filename = "knest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @k_in_c(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %16

5:                                                ; preds = %2
  %6 = icmp sgt i32 %3, 0
  br label %7

7:                                                ; preds = %5, %7
  %8 = phi i32 [ 0, %5 ], [ %14, %7 ]
  %9 = phi i32 [ 0, %5 ], [ %13, %7 ]
  %10 = phi i32 [ 0, %5 ], [ %12, %7 ]
  %11 = select i1 %6, i32 %8, i32 0
  %12 = add i32 %10, %11
  %13 = add nuw nsw i32 %9, 1
  %14 = add i32 %8, %3
  %15 = icmp eq i32 %13, %0
  br i1 %15, label %16, label %7, !llvm.loop !6

16:                                               ; preds = %7, %2
  %17 = phi i32 [ 0, %2 ], [ %12, %7 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @k_in_arm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %17

5:                                                ; preds = %2
  %6 = icmp sgt i32 %3, 0
  %7 = add i32 %3, -1
  %8 = zext i32 %7 to i33
  %9 = add i32 %3, -2
  %10 = zext i32 %9 to i33
  %11 = mul i33 %8, %10
  %12 = lshr i33 %11, 1
  %13 = trunc nuw i33 %12 to i32
  %14 = add i32 %3, %13
  %15 = add i32 %14, -1
  %16 = select i1 %6, i32 %15, i32 0
  br label %20

17:                                               ; preds = %20, %2
  %18 = phi i32 [ 0, %2 ], [ %23, %20 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %19

20:                                               ; preds = %5, %20
  %21 = phi i32 [ 0, %5 ], [ %24, %20 ]
  %22 = phi i32 [ 0, %5 ], [ %23, %20 ]
  %23 = xor i32 %16, %22
  %24 = add nuw nsw i32 %21, 1
  %25 = icmp eq i32 %24, %0
  br i1 %25, label %17, label %20, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_in_c3(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %17

5:                                                ; preds = %2
  %6 = tail call i32 @llvm.smax.i32(i32 %3, i32 0)
  %7 = mul i32 %6, %0
  %8 = tail call i32 @llvm.smax.i32(i32 %3, i32 0)
  br label %12

9:                                                ; preds = %12
  %10 = add nuw nsw i32 %13, 1
  %11 = icmp eq i32 %10, %0
  br i1 %11, label %17, label %12, !llvm.loop !10

12:                                               ; preds = %5, %9
  %13 = phi i32 [ 0, %5 ], [ %10, %9 ]
  %14 = phi i32 [ 0, %5 ], [ %15, %9 ]
  %15 = add i32 %14, %8
  %16 = icmp sgt i32 %15, %3
  br i1 %16, label %17, label %9

17:                                               ; preds = %12, %9, %2
  %18 = phi i32 [ 0, %2 ], [ %7, %9 ], [ %15, %12 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %19
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
