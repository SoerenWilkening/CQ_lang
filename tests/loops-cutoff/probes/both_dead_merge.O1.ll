; ModuleID = 'both_dead_merge.c'
source_filename = "both_dead_merge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bd_merge(i32 noundef %0, i64 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = trunc i32 %0 to i8
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %4, double noundef %2) #2
  %6 = icmp eq i64 %1, 0
  %7 = zext i8 %5 to i32
  %8 = add i8 %5, 3
  %9 = zext i8 %8 to i32
  %10 = sub nsw i32 %7, %9
  %11 = select i1 %6, i32 0, i32 %10
  %12 = and i8 %5, 1
  %13 = zext nneg i8 %12 to i32
  %14 = add nsw i32 %11, %13
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  ret i32 %15
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

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
