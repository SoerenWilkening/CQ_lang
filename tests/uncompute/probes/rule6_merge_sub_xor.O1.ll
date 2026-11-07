; ModuleID = 'n3.c'
source_filename = "n3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 3.000000e-01) #2
  %3 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 0x3FE6666666666666) #2
  %4 = fptosi double %2 to i64
  %5 = fptosi double %3 to i64
  %6 = and i32 %0, 1
  %7 = icmp eq i32 %6, 0
  %8 = sub nsw i64 %4, %5
  %9 = xor i64 %5, %4
  %10 = select i1 %7, i64 %9, i64 %8
  %11 = tail call i64 @cq_measure_sl(i64 noundef %10) #3
  %12 = trunc i64 %11 to i32
  ret i32 %12
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

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
