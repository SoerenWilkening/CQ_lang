; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_leading_gate.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_leading_gate.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %7

3:                                                ; preds = %15
  %4 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %16) #2
  %6 = add nsw i32 %5, %4
  ret i32 %6

7:                                                ; preds = %0, %15
  %8 = phi i32 [ 0, %0 ], [ %18, %15 ]
  %9 = phi i32 [ %2, %0 ], [ %16, %15 ]
  %10 = phi i32 [ %1, %0 ], [ %17, %15 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.500000e-01) #2
  %12 = icmp eq i32 %10, 5
  br i1 %12, label %13, label %15

13:                                               ; preds = %7
  %14 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 9.000000e-01) #2
  br label %15

15:                                               ; preds = %13, %7
  %16 = phi i32 [ %14, %13 ], [ %11, %7 ]
  tail call void @cq_phi(double noundef 1.000000e-01) #2
  %17 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 5.000000e-02) #2
  %18 = add nuw nsw i32 %8, 1
  %19 = icmp eq i32 %8, 0
  br i1 %19, label %7, label %3, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
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
