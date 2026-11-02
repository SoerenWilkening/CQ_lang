; ModuleID = 'rule19_kept.c'
source_filename = "rule19_kept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @image(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @square(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = mul nsw i32 %3, %3
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @mix(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %7 = and i32 %5, 7
  %8 = or i32 %6, 1
  %9 = mul nsw i32 %8, %7
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_frozen(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @image(i32 noundef %0, double noundef %1, i32 noundef %2)
  %5 = mul nsw i32 %4, 3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  ret i32 %6
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @k_frozen_rot(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #2 {
  %5 = tail call i32 @image(i32 noundef %0, double noundef %1, i32 noundef %2)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %3) #3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_twin(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @square(i32 noundef %0, double noundef %1)
  %5 = add nsw i32 %4, %2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_meas(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @square(i32 noundef %0, double noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @k_twin2(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #2 {
  %5 = tail call i32 @mix(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3)
  %6 = xor i32 %5, 5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
