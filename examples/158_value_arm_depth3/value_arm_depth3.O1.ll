; ModuleID = 'value_arm_depth3.c'
source_filename = "value_arm_depth3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @value_arm_depth3(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9) local_unnamed_addr #0 {
  %11 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %12 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #2
  %14 = icmp sgt i32 %11, %6
  br i1 %14, label %15, label %26

15:                                               ; preds = %10
  %16 = icmp sgt i32 %12, %7
  br i1 %16, label %17, label %24

17:                                               ; preds = %15
  %18 = icmp sgt i32 %13, %8
  br i1 %18, label %19, label %22

19:                                               ; preds = %17
  %20 = add nsw i32 %12, %11
  %21 = add nsw i32 %20, %13
  br label %28

22:                                               ; preds = %17
  %23 = mul nsw i32 %12, %11
  br label %28

24:                                               ; preds = %15
  %25 = sub nsw i32 %12, %9
  br label %28

26:                                               ; preds = %10
  %27 = add nsw i32 %13, %9
  br label %28

28:                                               ; preds = %24, %22, %19, %26
  %29 = phi i32 [ %21, %19 ], [ %23, %22 ], [ %25, %24 ], [ %27, %26 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #3
  ret i32 %30
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
