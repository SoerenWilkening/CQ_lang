; ModuleID = 's2.c'
source_filename = "s2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 3.000000e-01) #2
  %3 = and i32 %0, 3
  switch i32 %3, label %16 [
    i32 0, label %4
    i32 1, label %7
    i32 2, label %10
    i32 3, label %13
  ]

4:                                                ; preds = %1
  %5 = sext i8 %2 to i32
  %6 = add nsw i32 %5, 1
  br label %17

7:                                                ; preds = %1
  %8 = xor i8 %2, 5
  %9 = sext i8 %8 to i32
  br label %17

10:                                               ; preds = %1
  %11 = sext i8 %2 to i32
  %12 = add nsw i32 %11, 9
  br label %17

13:                                               ; preds = %1
  %14 = sext i8 %2 to i32
  %15 = mul nsw i32 %14, 3
  br label %17

16:                                               ; preds = %1
  unreachable

17:                                               ; preds = %13, %10, %7, %4
  %18 = phi i32 [ %15, %13 ], [ %12, %10 ], [ %9, %7 ], [ %6, %4 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  ret i32 %19
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

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
