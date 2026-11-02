; ModuleID = 'exits.c'
source_filename = "exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ce_found(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %12

6:                                                ; preds = %3, %6
  %7 = phi i32 [ %8, %6 ], [ 0, %3 ]
  tail call void @cq_phi(double noundef 5.000000e-01) #3
  %8 = add nuw nsw i32 %7, 1
  %9 = shl i32 2, %7
  %10 = and i32 %9, %4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %6, !llvm.loop !6

12:                                               ; preds = %6, %3
  %13 = phi i32 [ 0, %3 ], [ 5, %6 ]
  %14 = add nsw i32 %13, %4
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ce_region(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %18, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %9 = mul nsw i32 %8, 3
  %10 = add nsw i32 %9, 1
  %11 = add nuw nsw i32 %7, 1
  %12 = shl nuw i32 2, %7
  %13 = and i32 %12, %3
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %6, !llvm.loop !9

15:                                               ; preds = %6
  %16 = shl nsw i32 %10, 1
  %17 = add nsw i32 %16, %11
  br label %18

18:                                               ; preds = %15, %2
  %19 = phi i32 [ 2, %2 ], [ %17, %15 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @ce_body(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %17, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %12, %6 ], [ 1, %2 ]
  %9 = mul nuw nsw i32 %7, 5
  %10 = xor i32 %9, %8
  %11 = mul nsw i32 %8, 3
  %12 = add nsw i32 %10, %11
  %13 = add nuw nsw i32 %7, 1
  %14 = shl nuw i32 2, %7
  %15 = and i32 %14, %3
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %6, !llvm.loop !10

17:                                               ; preds = %6, %2
  %18 = phi i32 [ 0, %2 ], [ %10, %6 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  ret i32 %19
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
