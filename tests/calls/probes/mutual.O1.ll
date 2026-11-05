; ModuleID = 'mutual.c'
source_filename = "mutual.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @mutual(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 3
  %6 = tail call fastcc i32 @even(i32 noundef %5, i32 noundef %2)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @even(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %9, label %4

4:                                                ; preds = %2
  %5 = add nsw i32 %0, -1
  %6 = mul nsw i32 %1, 3
  %7 = tail call fastcc i32 @odd(i32 noundef %5, i32 noundef %6)
  %8 = add nsw i32 %7, 1
  br label %9

9:                                                ; preds = %2, %4
  %10 = phi i32 [ %8, %4 ], [ %1, %2 ]
  ret i32 %10
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @odd(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = add nsw i32 %1, 1
  br label %11

6:                                                ; preds = %2
  %7 = add nsw i32 %0, -1
  %8 = add nsw i32 %1, 5
  %9 = tail call fastcc i32 @even(i32 noundef %7, i32 noundef %8)
  %10 = add nsw i32 %9, 2
  br label %11

11:                                               ; preds = %6, %4
  %12 = phi i32 [ %5, %4 ], [ %10, %6 ]
  ret i32 %12
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
