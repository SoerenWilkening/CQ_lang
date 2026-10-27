; ModuleID = 'nested_switch.c'
source_filename = "nested_switch.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_switch(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %9 = and i32 %7, 3
  switch i32 %9, label %19 [
    i32 0, label %10
    i32 1, label %12
  ]

10:                                               ; preds = %6
  %11 = add nsw i32 %4, 1
  br label %21

12:                                               ; preds = %6
  %13 = and i32 %8, 3
  switch i32 %13, label %17 [
    i32 0, label %14
    i32 2, label %16
  ]

14:                                               ; preds = %12
  %15 = add nsw i32 %4, 2
  br label %21

16:                                               ; preds = %12
  tail call void @cq_phi(double noundef %5) #3
  br label %21

17:                                               ; preds = %12
  %18 = add nsw i32 %8, %4
  br label %21

19:                                               ; preds = %6
  %20 = add nsw i32 %7, %4
  br label %21

21:                                               ; preds = %14, %16, %17, %19, %10
  %22 = phi i32 [ %20, %19 ], [ %18, %17 ], [ %4, %16 ], [ %15, %14 ], [ %11, %10 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
