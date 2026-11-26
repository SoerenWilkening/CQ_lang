; ModuleID = 'switch_case_set_merge.c'
source_filename = "switch_case_set_merge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #2
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %20

6:                                                ; preds = %2
  switch i32 %0, label %16 [
    i32 1, label %20
    i32 2, label %20
    i32 3, label %20
    i32 0, label %7
    i32 3074, label %7
    i32 3200, label %14
    i32 3202, label %14
  ]

7:                                                ; preds = %6, %6
  %8 = lshr exact i32 %3, 1
  %9 = and i32 %8, 3
  switch i32 %9, label %20 [
    i32 0, label %10
    i32 1, label %12
  ]

10:                                               ; preds = %7
  %11 = mul nsw i32 %3, 3
  br label %16

12:                                               ; preds = %7
  %13 = xor i32 %3, 85
  br label %16

14:                                               ; preds = %6, %6
  %15 = add nsw i32 %3, 9
  br label %16

16:                                               ; preds = %6, %10, %12, %14
  %17 = phi i32 [ %15, %14 ], [ %13, %12 ], [ %11, %10 ], [ 0, %6 ]
  %18 = mul nsw i32 %17, 3
  %19 = add nsw i32 %18, %0
  br label %20

20:                                               ; preds = %7, %6, %6, %6, %2, %16
  %21 = phi i32 [ %19, %16 ], [ 5, %2 ], [ 7, %6 ], [ 7, %6 ], [ 7, %6 ], [ 8, %7 ]
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
