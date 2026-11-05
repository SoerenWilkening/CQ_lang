; ModuleID = 'depth_classical_formal.c'
source_filename = "depth_classical_formal.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @r13(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #3
  %5 = and i32 %0, 1
  %6 = and i32 %4, 3
  %7 = tail call fastcc i32 @f(i32 noundef %5, i32 noundef %6, i32 noundef %2)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #2 {
  %4 = icmp slt i32 %1, 1
  br i1 %4, label %5, label %9

5:                                                ; preds = %3
  %6 = add nsw i32 %2, %0
  br label %7

7:                                                ; preds = %5, %9
  %8 = phi i32 [ %14, %9 ], [ %6, %5 ]
  ret i32 %8

9:                                                ; preds = %3
  %10 = add nsw i32 %0, -1
  %11 = add nsw i32 %1, -1
  %12 = add nsw i32 %2, 1
  %13 = tail call fastcc i32 @f(i32 noundef %10, i32 noundef %11, i32 noundef %12)
  %14 = sub nsw i32 %2, %13
  br label %7
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
