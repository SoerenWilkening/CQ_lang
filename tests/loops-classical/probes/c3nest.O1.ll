; ModuleID = 'c3nest.c'
source_filename = "c3nest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @n_inner1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %8, label %20

5:                                                ; preds = %11
  %6 = add nuw nsw i32 %9, 1
  %7 = icmp eq i32 %6, %0
  br i1 %7, label %20, label %8, !llvm.loop !6

8:                                                ; preds = %2, %5
  %9 = phi i32 [ %6, %5 ], [ 0, %2 ]
  %10 = phi i32 [ %17, %5 ], [ 0, %2 ]
  br label %13

11:                                               ; preds = %13
  %12 = icmp eq i32 %17, 5
  br i1 %12, label %20, label %5

13:                                               ; preds = %8, %13
  %14 = phi i32 [ 0, %8 ], [ %18, %13 ]
  %15 = phi i32 [ %10, %8 ], [ %17, %13 ]
  %16 = xor i32 %14, %3
  %17 = add nsw i32 %16, %15
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %11, label %13, !llvm.loop !9

20:                                               ; preds = %5, %11, %2
  %21 = phi i32 [ 0, %2 ], [ %17, %5 ], [ 5, %11 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @n_inner3(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %2) #3
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %21

6:                                                ; preds = %3
  %7 = icmp sgt i32 %1, 0
  %8 = add nsw i32 %4, 4
  %9 = add i32 %1, -1
  %10 = tail call i32 @llvm.umin.i32(i32 %4, i32 %9)
  %11 = add i32 %10, 1
  %12 = select i1 %7, i32 %11, i32 0
  br label %13

13:                                               ; preds = %13, %6
  %14 = phi i32 [ 0, %6 ], [ %18, %13 ]
  %15 = phi i32 [ 0, %6 ], [ %16, %13 ]
  %16 = add i32 %15, %12
  %17 = icmp eq i32 %16, %8
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %0
  %20 = select i1 %17, i1 true, i1 %19
  br i1 %20, label %21, label %13, !llvm.loop !10

21:                                               ; preds = %13, %3
  %22 = phi i32 [ 0, %3 ], [ %16, %13 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i32 @n_phase(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %18

5:                                                ; preds = %2, %7
  %6 = phi i32 [ %9, %7 ], [ 0, %2 ]
  br label %12

7:                                                ; preds = %12
  %8 = icmp eq i32 %3, %6
  %9 = add nuw nsw i32 %6, 1
  %10 = icmp eq i32 %9, %0
  %11 = select i1 %8, i1 true, i1 %10
  br i1 %11, label %18, label %5, !llvm.loop !11

12:                                               ; preds = %5, %12
  %13 = phi i32 [ 0, %5 ], [ %14, %12 ]
  %14 = add nuw nsw i32 %13, 1
  %15 = uitofp nneg i32 %14 to double
  %16 = fmul double %15, %1
  tail call void @cq_phi(double noundef %16) #4
  %17 = icmp eq i32 %13, 0
  br i1 %17, label %12, label %7, !llvm.loop !12

18:                                               ; preds = %7, %2
  %19 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  ret i32 %19
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #2

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
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
