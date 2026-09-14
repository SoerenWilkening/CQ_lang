; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_derived_oracle_2iter.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_derived_oracle_2iter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = ashr i32 %1, 2
  %3 = add nsw i32 %2, %1
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %6

5:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %6

6:                                                ; preds = %5, %0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef -5.000000e-01) #2
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %10

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %10

10:                                               ; preds = %9, %6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01) #2
  %12 = ashr i32 %11, 2
  %13 = add nsw i32 %12, %11
  %14 = icmp eq i32 %13, 5
  br i1 %14, label %15, label %16

15:                                               ; preds = %10
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %16

16:                                               ; preds = %15, %10
  %17 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef -5.000000e-01) #2
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %19, label %20

19:                                               ; preds = %16
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %20

20:                                               ; preds = %19, %16
  %21 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 5.000000e-01) #2
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  ret i32 %22
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
