; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_two_regs_unrolled.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_inplace_ry_loop_two_regs_unrolled.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 1.250000e-01) #2
  %4 = icmp eq i32 %1, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i32 [ %6, %5 ], [ %2, %0 ]
  %9 = icmp eq i32 %1, 3
  br i1 %9, label %10, label %12

10:                                               ; preds = %7
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #2
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i32 [ %11, %10 ], [ %3, %7 ]
  tail call void @cq_phi(double noundef 1.000000e-01) #2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-02) #2
  %15 = icmp eq i32 %14, 5
  br i1 %15, label %16, label %18

16:                                               ; preds = %12
  %17 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #2
  br label %18

18:                                               ; preds = %16, %12
  %19 = phi i32 [ %17, %16 ], [ %8, %12 ]
  %20 = icmp eq i32 %14, 3
  br i1 %20, label %21, label %23

21:                                               ; preds = %18
  %22 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 0x3FE6666666666666) #2
  br label %23

23:                                               ; preds = %21, %18
  %24 = phi i32 [ %22, %21 ], [ %13, %18 ]
  tail call void @cq_phi(double noundef 1.000000e-01) #2
  %25 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-02) #2
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #2
  %27 = tail call i32 @cq_measure_si32(i32 noundef %19) #2
  %28 = add nsw i32 %27, %26
  %29 = tail call i32 @cq_measure_si32(i32 noundef %24) #2
  %30 = add nsw i32 %28, %29
  ret i32 %30
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
