; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_two_regs.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_two_regs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 1.250000e-01) #2
  br label %10

4:                                                ; preds = %23
  %5 = tail call i32 @cq_measure_si32(i32 noundef %25) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %19) #2
  %7 = add nsw i32 %6, %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %24) #2
  %9 = add nsw i32 %7, %8
  ret i32 %9

10:                                               ; preds = %0, %23
  %11 = phi i32 [ 0, %0 ], [ %26, %23 ]
  %12 = phi i32 [ %3, %0 ], [ %24, %23 ]
  %13 = phi i32 [ %2, %0 ], [ %19, %23 ]
  %14 = phi i32 [ %1, %0 ], [ %25, %23 ]
  %15 = icmp eq i32 %14, 5
  br i1 %15, label %16, label %18

16:                                               ; preds = %10
  %17 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 9.000000e-01) #2
  br label %18

18:                                               ; preds = %16, %10
  %19 = phi i32 [ %17, %16 ], [ %13, %10 ]
  %20 = icmp eq i32 %14, 3
  br i1 %20, label %21, label %23

21:                                               ; preds = %18
  %22 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 0x3FE6666666666666) #2
  br label %23

23:                                               ; preds = %21, %18
  %24 = phi i32 [ %22, %21 ], [ %12, %18 ]
  tail call void @cq_phi(double noundef 1.000000e-01) #2
  %25 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-02) #2
  %26 = add nuw nsw i32 %11, 1
  %27 = icmp eq i32 %11, 0
  br i1 %27, label %10, label %4, !llvm.loop !6
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
