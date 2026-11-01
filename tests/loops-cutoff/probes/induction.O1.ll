; ModuleID = 'induction.c'
source_filename = "induction.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ind_qstart_exit(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i32 [ %5, %4 ], [ %11, %7 ]
  %9 = phi i32 [ %6, %4 ], [ %12, %7 ]
  %10 = mul nsw i32 %8, 3
  %11 = add nsw i32 %10, %9
  %12 = add nsw i32 %9, -2
  %13 = icmp slt i32 %11, 100
  br i1 %13, label %7, label %14, !llvm.loop !6

14:                                               ; preds = %7
  %15 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %17 = add nsw i32 %16, %15
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ind_qstart_test(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = icmp ugt i32 %5, %2
  br i1 %6, label %7, label %14

7:                                                ; preds = %4, %7
  %8 = phi i32 [ %11, %7 ], [ 0, %4 ]
  %9 = phi i32 [ %12, %7 ], [ %5, %4 ]
  %10 = xor i32 %9, %3
  %11 = add i32 %8, %10
  %12 = add i32 %9, -1
  %13 = icmp ugt i32 %12, %2
  br i1 %13, label %7, label %14, !llvm.loop !9

14:                                               ; preds = %7, %4
  %15 = phi i32 [ 0, %4 ], [ %11, %7 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ind_cstart(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %5

5:                                                ; preds = %5, %3
  %6 = phi i32 [ %4, %3 ], [ %8, %5 ]
  %7 = phi i32 [ %2, %3 ], [ %9, %5 ]
  %8 = add nsw i32 %7, %6
  %9 = add nsw i32 %7, 3
  %10 = icmp slt i32 %8, 50
  br i1 %10, label %5, label %11, !llvm.loop !10

11:                                               ; preds = %5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  ret i32 %12
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
