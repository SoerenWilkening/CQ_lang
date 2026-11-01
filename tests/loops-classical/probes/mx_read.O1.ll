; ModuleID = 'mx_read.c'
source_filename = "mx_read.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_find(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %7, label %21

7:                                                ; preds = %4
  %8 = zext nneg i32 %3 to i64
  %9 = load i32, ptr %2, align 4, !tbaa !6
  %10 = icmp eq i32 %9, %5
  br i1 %10, label %23, label %11

11:                                               ; preds = %7, %15
  %12 = phi i64 [ %13, %15 ], [ 0, %7 ]
  %13 = add nuw nsw i64 %12, 1
  %14 = icmp eq i64 %13, %8
  br i1 %14, label %19, label %15, !llvm.loop !10

15:                                               ; preds = %11
  %16 = getelementptr inbounds i32, ptr %2, i64 %13
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %19, label %11, !llvm.loop !10

19:                                               ; preds = %11, %15
  %20 = icmp ult i64 %13, %8
  br label %21

21:                                               ; preds = %19, %4
  %22 = phi i1 [ %6, %4 ], [ %20, %19 ]
  br i1 %22, label %23, label %24

23:                                               ; preds = %7, %21
  tail call void @cq_phi(double noundef 1.000000e+00) #3
  br label %24

24:                                               ; preds = %23, %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  ret i32 %25
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_find2(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %7, label %21

7:                                                ; preds = %4
  %8 = zext nneg i32 %3 to i64
  %9 = load i32, ptr %2, align 4, !tbaa !6
  %10 = icmp eq i32 %9, %5
  br i1 %10, label %23, label %11

11:                                               ; preds = %7, %15
  %12 = phi i64 [ %13, %15 ], [ 0, %7 ]
  %13 = add nuw nsw i64 %12, 1
  %14 = icmp eq i64 %13, %8
  br i1 %14, label %19, label %15, !llvm.loop !10

15:                                               ; preds = %11
  %16 = getelementptr inbounds i32, ptr %2, i64 %13
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %19, label %11, !llvm.loop !10

19:                                               ; preds = %11, %15
  %20 = icmp ult i64 %13, %8
  br label %21

21:                                               ; preds = %19, %4
  %22 = phi i1 [ %6, %4 ], [ %20, %19 ]
  br i1 %22, label %23, label %24

23:                                               ; preds = %7, %21
  tail call void @cq_phi(double noundef 1.000000e+00) #3
  br label %24

24:                                               ; preds = %23, %21
  %25 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %1) #2
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  ret i32 %26
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
