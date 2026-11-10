; ModuleID = 'meas_table_t.c'
source_filename = "meas_table_t.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @in(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 -2147483646, -2147483648) i32 @in2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp eq i32 %1, 0
  %4 = select i1 %3, ptr @in2, ptr @in
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 %4(i32 noundef %6) #3, !callees !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @twice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  %3 = add nsw i32 %2, %0
  %4 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @g(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp eq i32 %1, 0
  %4 = select i1 %3, ptr @in, ptr @twice
  %5 = add nsw i32 %0, 1
  %6 = tail call i32 %4(i32 noundef %5) #3, !callees !7
  %7 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @meas(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_measure_si32(i32 noundef %0) #3
  ret i32 %2
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @outer(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @meas(i32 noundef %0)
  %3 = add nsw i32 %2, %0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp eq i32 %1, 0
  %4 = select i1 %3, ptr @in, ptr @outer
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 %4(i32 noundef %6) #3, !callees !8
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @inner(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 1
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %4 = add nsw i32 %3, %0
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @n(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp eq i32 %1, 0
  %4 = select i1 %3, ptr @in, ptr @inner
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 %4(i32 noundef %6) #3, !callees !9
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{ptr @in, ptr @in2}
!7 = !{ptr @in, ptr @twice}
!8 = !{ptr @in, ptr @outer}
!9 = !{ptr @in, ptr @inner}
