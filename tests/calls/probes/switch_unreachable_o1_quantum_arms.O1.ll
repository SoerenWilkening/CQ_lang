; ModuleID = 's4.c'
source_filename = "s4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 3.000000e-01) #2
  %3 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 0x3FE6666666666666) #2
  %4 = and i32 %0, 3
  switch i32 %4, label %24 [
    i32 0, label %5
    i32 1, label %8
    i32 2, label %14
    i32 3, label %21
  ]

5:                                                ; preds = %1
  %6 = sext i8 %2 to i32
  %7 = add nsw i32 %6, 1
  br label %25

8:                                                ; preds = %1
  %9 = and i8 %3, 1
  %10 = icmp eq i8 %9, 0
  %11 = sext i8 %2 to i32
  %12 = xor i32 %11, 5
  %13 = select i1 %10, i32 %11, i32 %12
  br label %25

14:                                               ; preds = %1
  %15 = sext i8 %2 to i32
  %16 = add nsw i32 %15, 9
  %17 = and i8 %3, 2
  %18 = icmp eq i8 %17, 0
  %19 = mul nsw i32 %16, 3
  %20 = select i1 %18, i32 %16, i32 %19
  br label %25

21:                                               ; preds = %1
  %22 = sext i8 %2 to i32
  %23 = mul nsw i32 %22, %22
  br label %25

24:                                               ; preds = %1
  unreachable

25:                                               ; preds = %14, %21, %8, %5
  %26 = phi i32 [ %23, %21 ], [ %13, %8 ], [ %7, %5 ], [ %20, %14 ]
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  ret i32 %27
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
