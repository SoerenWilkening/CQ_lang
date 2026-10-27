; ModuleID = 'measure_then_reuse.c'
source_filename = "measure_then_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @measure_then_reuse(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %7 = icmp sgt i32 %6, %2
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %3) #2
  br label %12

10:                                               ; preds = %4
  %11 = add nsw i32 %5, 1
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %15 = add nsw i32 %14, %6
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @measure_entangled_rotate_other(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %7 = add nsw i32 %6, %2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %9 = icmp sgt i32 %8, %3
  br i1 %9, label %10, label %12

10:                                               ; preds = %5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %4) #2
  br label %12

12:                                               ; preds = %10, %5
  %13 = phi i32 [ %11, %10 ], [ %6, %5 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %15 = add nsw i32 %14, %8
  ret i32 %15
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
