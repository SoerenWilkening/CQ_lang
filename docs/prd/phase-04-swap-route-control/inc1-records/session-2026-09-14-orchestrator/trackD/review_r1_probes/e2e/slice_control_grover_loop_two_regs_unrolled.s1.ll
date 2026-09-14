; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_two_regs_unrolled.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_two_regs_unrolled.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %5

5:                                                ; preds = %4, %0
  %6 = icmp eq i32 %2, 3
  br i1 %6, label %7, label %8

7:                                                ; preds = %5
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %8

8:                                                ; preds = %7, %5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef -5.000000e-01) #2
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef -2.500000e-01) #2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #2
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.500000e-01) #2
  %13 = icmp eq i32 %11, 5
  br i1 %13, label %14, label %15

14:                                               ; preds = %8
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %15

15:                                               ; preds = %14, %8
  %16 = icmp eq i32 %12, 3
  br i1 %16, label %17, label %18

17:                                               ; preds = %15
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %18

18:                                               ; preds = %17, %15
  %19 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef -5.000000e-01) #2
  %20 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef -2.500000e-01) #2
  %21 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 5.000000e-01) #2
  %22 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 2.500000e-01) #2
  %23 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %24 = tail call i32 @cq_measure_si32(i32 noundef %22) #2
  %25 = add nsw i32 %24, %23
  ret i32 %25
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
