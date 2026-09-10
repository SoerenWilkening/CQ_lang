; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/c/a13_measure_parent_after_select.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/c/a13_measure_parent_after_select.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 3.000000e-01) #2
  %3 = select i1 %2, i32 2, i32 5
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %5 = zext i1 %4 to i32
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7
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
