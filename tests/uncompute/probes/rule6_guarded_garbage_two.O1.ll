; ModuleID = 'd3.c'
source_filename = "d3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 3.000000e-01) #2
  %3 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 0x3FE6666666666666) #2
  %4 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 2.000000e-01) #2
  %5 = sext i8 %2 to i32
  %6 = mul nsw i32 %5, 3
  %7 = and i32 %0, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %18, label %9

9:                                                ; preds = %1
  %10 = sext i8 %3 to i32
  %11 = sub nsw i32 %5, %10
  %12 = and i8 %4, 1
  %13 = icmp eq i8 %12, 0
  br i1 %13, label %16, label %14

14:                                               ; preds = %9
  %15 = add nsw i32 %11, 2
  br label %18

16:                                               ; preds = %9
  %17 = xor i32 %11, -1
  br label %18

18:                                               ; preds = %14, %16, %1
  %19 = phi i32 [ %15, %14 ], [ %17, %16 ], [ %6, %1 ]
  %20 = add nsw i32 %19, 1
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  ret i32 %21
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
