; ModuleID = 'q3_arms.c'
source_filename = "q3_arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p10(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext 0, double noundef 7.500000e-01) #2
  %5 = icmp sgt i32 %2, %0
  br i1 %5, label %6, label %9

6:                                                ; preds = %1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %8 = add nsw i32 %7, 1
  br label %13

9:                                                ; preds = %1
  %10 = tail call signext i16 @cq_measure_si16(i16 noundef signext %4) #3
  %11 = sext i16 %10 to i32
  %12 = mul nsw i32 %11, 3
  br label %13

13:                                               ; preds = %9, %6
  %14 = phi i32 [ %8, %6 ], [ %12, %9 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p14(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 7.500000e-01) #2
  %5 = icmp sgt i32 %2, %0
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ 0, %1 ]
  %10 = icmp slt i32 %2, %0
  br i1 %10, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  br label %13

13:                                               ; preds = %11, %8
  %14 = phi i32 [ %12, %11 ], [ 0, %8 ]
  %15 = add nsw i32 %14, %9
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @sw(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext 0, double noundef 7.500000e-01) #2
  %5 = tail call i64 @cq_theta_sll(i64 noundef 0, double noundef 1.250000e-01) #2
  %6 = add nsw i32 %2, %0
  %7 = and i32 %6, 3
  switch i32 %7, label %19 [
    i32 0, label %8
    i32 1, label %11
    i32 2, label %15
    i32 3, label %20
  ]

8:                                                ; preds = %1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %10 = add nsw i32 %9, 1
  br label %20

11:                                               ; preds = %1
  %12 = tail call signext i16 @cq_measure_si16(i16 noundef signext %4) #3
  %13 = sext i16 %12 to i32
  %14 = mul nsw i32 %13, 3
  br label %20

15:                                               ; preds = %1
  %16 = tail call i64 @cq_measure_sll(i64 noundef %5) #3
  %17 = trunc i64 %16 to i32
  %18 = add nsw i32 %17, -2
  br label %20

19:                                               ; preds = %1
  unreachable

20:                                               ; preds = %1, %15, %11, %8
  %21 = phi i32 [ %18, %15 ], [ %14, %11 ], [ %10, %8 ], [ 7, %1 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %23 = add nsw i32 %22, %21
  ret i32 %23
}

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #1

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
