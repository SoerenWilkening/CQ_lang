; ModuleID = 'carm.c'
source_filename = "carm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @a_diamond(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %2) #2
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %19, %3
  %7 = phi i32 [ 0, %3 ], [ %20, %19 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8

9:                                                ; preds = %3, %19
  %10 = phi i32 [ %21, %19 ], [ 0, %3 ]
  %11 = phi i32 [ %20, %19 ], [ 0, %3 ]
  %12 = icmp eq i32 %4, %10
  br i1 %12, label %13, label %19

13:                                               ; preds = %9
  %14 = icmp eq i32 %10, %1
  br i1 %14, label %15, label %17

15:                                               ; preds = %13
  %16 = add nsw i32 %11, 3
  br label %19

17:                                               ; preds = %13
  %18 = add nsw i32 %11, %4
  br label %19

19:                                               ; preds = %9, %17, %15
  %20 = phi i32 [ %16, %15 ], [ %18, %17 ], [ %11, %9 ]
  %21 = add nuw nsw i32 %10, 1
  %22 = icmp eq i32 %21, %0
  br i1 %22, label %6, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @a_inner(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %2) #2
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %3
  %7 = and i32 %4, 1
  %8 = icmp eq i32 %7, 0
  br label %12

9:                                                ; preds = %22, %3
  %10 = phi i32 [ 0, %3 ], [ %24, %22 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %11

12:                                               ; preds = %6, %22
  %13 = phi i32 [ 0, %6 ], [ %25, %22 ]
  %14 = phi i32 [ 0, %6 ], [ %24, %22 ]
  br i1 %8, label %22, label %15

15:                                               ; preds = %12
  %16 = icmp slt i32 %13, %1
  %17 = sub nsw i32 0, %13
  %18 = select i1 %16, i32 %13, i32 %17
  %19 = add i32 %18, %4
  %20 = mul nsw i32 %19, 3
  %21 = xor i32 %20, %14
  br label %22

22:                                               ; preds = %15, %12
  %23 = phi i32 [ %21, %15 ], [ %14, %12 ]
  %24 = add nsw i32 %23, 1
  %25 = add nuw nsw i32 %13, 1
  %26 = icmp eq i32 %25, %0
  br i1 %26, label %9, label %12, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @a_phase(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %2) #2
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = fmul double %2, 5.000000e-01
  br label %10

8:                                                ; preds = %18, %3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  ret i32 %9

10:                                               ; preds = %6, %18
  %11 = phi i32 [ 0, %6 ], [ %19, %18 ]
  %12 = icmp eq i32 %4, %11
  br i1 %12, label %13, label %18

13:                                               ; preds = %10
  %14 = shl nuw i32 1, %11
  %15 = and i32 %14, %1
  %16 = icmp eq i32 %15, 0
  %17 = select i1 %16, double %7, double %2
  tail call void @cq_phi(double noundef %17) #3
  br label %18

18:                                               ; preds = %13, %10
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, %0
  br i1 %20, label %8, label %10, !llvm.loop !10
}

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
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
