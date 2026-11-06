; ModuleID = 'noreturn_shapes.c'
source_filename = "noreturn_shapes.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @two_tests(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = and i32 %2, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %6, label %5

5:                                                ; preds = %1
  tail call void @abort() #6
  unreachable

6:                                                ; preds = %1
  %7 = load i32, ptr @g, align 4, !tbaa !6
  %8 = add nsw i32 %7, 1
  store i32 %8, ptr @g, align 4, !tbaa !6
  %9 = and i32 %2, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %6
  tail call void @abort() #6
  unreachable

12:                                               ; preds = %6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #7
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @classical_inner(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %9

5:                                                ; preds = %2
  %6 = and i32 %1, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  tail call void @exit(i32 noundef 1) #8
  unreachable

9:                                                ; preds = %5, %2
  %10 = phi i32 [ 0, %2 ], [ 5, %5 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @in_arm(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = and i32 %2, 2
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %12, label %5

5:                                                ; preds = %1
  %6 = and i32 %2, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = load i32, ptr @g, align 4, !tbaa !6
  %10 = add nsw i32 %9, 1
  store i32 %10, ptr @g, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %8, %5
  tail call void @abort() #6
  unreachable

12:                                               ; preds = %1
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #7
  ret i32 %13
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @status_phi(i32 noundef %0) local_unnamed_addr #4 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %3 = icmp eq i32 %2, 7
  br i1 %3, label %9, label %4

4:                                                ; preds = %1
  %5 = and i32 %2, -2
  %6 = icmp eq i32 %5, 14
  br i1 %6, label %11, label %7

7:                                                ; preds = %4
  %8 = load i32, ptr @g, align 4, !tbaa !6
  br label %13

9:                                                ; preds = %1
  tail call void @exit(i32 noundef 9) #8
  unreachable

10:                                               ; preds = %13
  store i32 %16, ptr @g, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %10, %4
  %12 = phi i32 [ %17, %10 ], [ 1, %4 ]
  tail call void @exit(i32 noundef %12) #8
  unreachable

13:                                               ; preds = %7, %13
  %14 = phi i32 [ %17, %13 ], [ 1, %7 ]
  %15 = phi i32 [ %16, %13 ], [ %8, %7 ]
  %16 = add nsw i32 %15, 1
  %17 = add nuw nsw i32 %14, 1
  %18 = ashr i32 %2, %17
  %19 = icmp eq i32 %18, 7
  br i1 %19, label %10, label %13, !llvm.loop !10
}

; Function Attrs: nounwind ssp uwtable
define i32 @siblings(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #5
  br label %5

5:                                                ; preds = %9, %2
  %6 = phi i32 [ 0, %2 ], [ %10, %9 ]
  %7 = ashr i32 %3, %6
  switch i32 %7, label %9 [
    i32 0, label %11
    i32 5, label %8
  ]

8:                                                ; preds = %5
  tail call void @abort() #6
  unreachable

9:                                                ; preds = %5
  %10 = add nuw nsw i32 %6, 1
  br label %5, !llvm.loop !12

11:                                               ; preds = %5, %18
  %12 = phi i32 [ %19, %18 ], [ %6, %5 ]
  %13 = phi i32 [ %20, %18 ], [ %7, %5 ]
  %14 = ashr i32 %4, %13
  switch i32 %14, label %18 [
    i32 0, label %15
    i32 5, label %17
  ]

15:                                               ; preds = %11
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  ret i32 %16

17:                                               ; preds = %11
  tail call void @abort() #6
  unreachable

18:                                               ; preds = %11
  %19 = add nuw nsw i32 %12, 2
  %20 = add nuw nsw i32 %13, 1
  br label %11, !llvm.loop !14
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { cold noreturn nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !13, !11}
!13 = !{!"llvm.loop.mustprogress"}
!14 = distinct !{!14, !13, !11}
