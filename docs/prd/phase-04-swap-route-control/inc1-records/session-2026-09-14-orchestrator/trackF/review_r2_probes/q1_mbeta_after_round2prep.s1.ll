; ModuleID = 'q1_mbeta_after_round2prep.c'
source_filename = "q1_mbeta_after_round2prep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %4 = select i1 %3, i32 1, i32 4
  %5 = add nsw i32 %4, %0
  %6 = icmp sgt i32 %5, 2
  br i1 %6, label %7, label %10

7:                                                ; preds = %2
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %9 = zext i1 %8 to i8
  br label %10

10:                                               ; preds = %7, %2
  %11 = phi i8 [ %9, %7 ], [ 0, %2 ]
  br i1 %3, label %12, label %16

12:                                               ; preds = %10
  %13 = trunc nuw i8 %11 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 2.500000e-01) #2
  %15 = zext i1 %14 to i8
  br label %16

16:                                               ; preds = %12, %10
  %17 = phi i8 [ %15, %12 ], [ %11, %10 ]
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #2
  %19 = zext i1 %18 to i32
  %20 = trunc nuw i8 %17 to i1
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #2
  %22 = zext i1 %21 to i32
  %23 = add nuw nsw i32 %22, %19
  %24 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %25 = add nsw i32 %23, %24
  ret i32 %25
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
