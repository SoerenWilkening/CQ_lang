; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_range_oracle.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_range_oracle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  br label %4

2:                                                ; preds = %10
  %3 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  ret i32 %3

4:                                                ; preds = %0, %10
  %5 = phi i32 [ 0, %0 ], [ %12, %10 ]
  %6 = phi i32 [ %1, %0 ], [ %11, %10 ]
  %7 = add i32 %6, -6
  %8 = icmp ult i32 %7, 14
  br i1 %8, label %9, label %10

9:                                                ; preds = %4
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %10

10:                                               ; preds = %9, %4
  %11 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #2
  %12 = add nuw nsw i32 %5, 1
  %13 = icmp eq i32 %5, 0
  br i1 %13, label %4, label %2, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  br label %2

2:                                                ; preds = %8, %0
  %3 = phi i32 [ 0, %0 ], [ %10, %8 ]
  %4 = phi i32 [ %1, %0 ], [ %9, %8 ]
  %5 = add i32 %4, -6
  %6 = icmp ult i32 %5, 14
  br i1 %6, label %7, label %8

7:                                                ; preds = %2
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %8

8:                                                ; preds = %7, %2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #2
  %10 = add nuw nsw i32 %3, 1
  %11 = icmp eq i32 %3, 0
  br i1 %11, label %2, label %12, !llvm.loop !6

12:                                               ; preds = %8
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
