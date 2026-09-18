; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/fam/nd_between_4.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/fam/nd_between_4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2
  br i1 %1, label %3, label %4

3:                                                ; preds = %0
  br label %4

4:                                                ; preds = %0, %3
  %5 = phi i32 [ 2, %3 ], [ 5, %0 ]
  %6 = phi i32 [ 2, %3 ], [ 6, %0 ]
  %7 = phi i32 [ 2, %3 ], [ 7, %0 ]
  %8 = phi i32 [ 2, %3 ], [ 8, %0 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
