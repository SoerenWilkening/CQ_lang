; ModuleID = 'abort_cover.c'
source_filename = "abort_cover.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @ac_ret(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %8 = icmp slt i32 %3, %2
  br i1 %8, label %9, label %11

9:                                                ; preds = %6
  store i32 %3, ptr @g, align 4, !tbaa !6
  %10 = icmp sgt i32 %4, %3
  br i1 %10, label %32, label %11

11:                                               ; preds = %9, %6
  %12 = icmp ne i32 %7, 7
  %13 = icmp sgt i32 %2, 0
  %14 = and i1 %12, %13
  br i1 %14, label %15, label %29

15:                                               ; preds = %11
  %16 = icmp eq i32 %5, 0
  br label %17

17:                                               ; preds = %15, %25
  %18 = phi i32 [ 0, %15 ], [ %27, %25 ]
  %19 = phi i32 [ 0, %15 ], [ %26, %25 ]
  %20 = icmp sgt i32 %7, %18
  br i1 %20, label %21, label %23

21:                                               ; preds = %17
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  %22 = add nsw i32 %19, %7
  br label %25

23:                                               ; preds = %17
  br i1 %16, label %25, label %24

24:                                               ; preds = %23
  store i32 %18, ptr @g, align 4, !tbaa !6
  br label %25

25:                                               ; preds = %21, %24, %23
  %26 = phi i32 [ %22, %21 ], [ %19, %24 ], [ %19, %23 ]
  %27 = add nuw nsw i32 %18, 1
  %28 = icmp eq i32 %27, %2
  br i1 %28, label %29, label %17, !llvm.loop !10

29:                                               ; preds = %25, %11
  %30 = phi i32 [ 0, %11 ], [ %26, %25 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #3
  br label %32

32:                                               ; preds = %9, %29
  %33 = phi i32 [ %31, %29 ], [ 0, %9 ]
  ret i32 %33
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
