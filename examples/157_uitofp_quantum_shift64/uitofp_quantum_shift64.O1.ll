; ModuleID = 'uitofp_quantum_shift64.c'
source_filename = "uitofp_quantum_shift64.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @uitofp_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = uitofp i32 %3 to double
  %5 = tail call double @cq_measure_f64(double noundef %4) #3
  ret double %5
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @shl_amount_q_i64(i64 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #2
  %5 = zext nneg i32 %4 to i64
  %6 = shl i64 %0, %5
  %7 = tail call i64 @cq_measure_sll(i64 noundef %6) #3
  ret i64 %7
}

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @lshr_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ull(i64 noundef %0, double noundef %2) #2
  %6 = tail call i64 @cq_theta_ull(i64 noundef %1, double noundef %3) #2
  %7 = lshr i64 %5, %6
  %8 = tail call i64 @cq_measure_ull(i64 noundef %7) #3
  ret i64 %8
}

declare i64 @cq_theta_ull(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #1

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
