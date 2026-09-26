; ModuleID = 'sib_rolled.k3.c'
source_filename = "sib_rolled.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3
  %4 = icmp sgt i32 %2, 1
  %5 = icmp slt i32 %3, 5
  %6 = and i1 %4, %5
  br label %13

7:                                                ; preds = %13
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %21

9:                                                ; preds = %7
  %10 = icmp sgt i32 %2, 1
  %11 = icmp slt i32 %3, 5
  %12 = and i1 %10, %11
  br label %27

13:                                               ; preds = %1, %13
  %14 = phi i32 [ 0, %1 ], [ %18, %13 ]
  %15 = phi i32 [ 0, %1 ], [ %19, %13 ]
  %16 = select i1 %6, i32 %15, i32 55
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %18 = add nsw i32 %17, %14
  %19 = add nuw nsw i32 %15, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %7, label %13, !llvm.loop !6

21:                                               ; preds = %27, %7
  %22 = phi i32 [ %18, %7 ], [ %32, %27 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %24 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %25 = add i32 %23, %22
  %26 = add i32 %25, %24
  ret i32 %26

27:                                               ; preds = %9, %27
  %28 = phi i32 [ %18, %9 ], [ %32, %27 ]
  %29 = phi i32 [ 0, %9 ], [ %33, %27 ]
  %30 = select i1 %12, i32 %29, i32 66
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #3
  %32 = add nsw i32 %31, %28
  %33 = add nuw nsw i32 %29, 1
  %34 = icmp eq i32 %33, %0
  br i1 %34, label %21, label %27, !llvm.loop !9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!8 = !{!"llvm.loop.unroll.full"}
!9 = distinct !{!9, !7, !8}
