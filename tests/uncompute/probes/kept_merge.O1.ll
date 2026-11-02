; ModuleID = 'kept_merge.c'
source_filename = "kept_merge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ks(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = icmp eq i32 %1, 0
  %5 = and i32 %3, 6
  %6 = or i32 %3, 1
  %7 = select i1 %4, i32 %6, i32 %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @kp(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %5 = and i32 %4, 6
  %6 = icmp eq i32 %1, 0
  %7 = or i32 %4, 1
  %8 = select i1 %6, i32 %7, i32 %5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %10 = icmp eq i32 %2, 0
  br i1 %10, label %15, label %11

11:                                               ; preds = %3
  %12 = mul nuw nsw i32 %5, 7
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %14 = add nsw i32 %13, %9
  br label %15

15:                                               ; preds = %11, %3
  %16 = phi i32 [ %14, %11 ], [ %9, %3 ]
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @kq(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %4 = and i32 %3, 6
  %5 = icmp eq i32 %1, 0
  %6 = or i32 %3, 1
  %7 = select i1 %5, i32 %6, i32 %4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %9 = mul nuw nsw i32 %4, 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = add nsw i32 %10, %8
  ret i32 %11
}

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
