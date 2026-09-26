; ModuleID = 'i64_and_rotr2_for.k3m.s1.ll'
source_filename = "i64_and_rotr2_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice()
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice() unnamed_addr #1 {
  %1 = tail call i64 @cq_theta_sll(i64 noundef 0, double noundef 2.500000e-01) #3
  %2 = tail call i64 @cq_theta_sll(i64 noundef 1, double noundef 5.000000e-01) #3
  %3 = icmp sgt i64 %1, 1
  %4 = icmp slt i64 %2, 5
  %5 = and i1 %3, %4
  br label %6

6:                                                ; preds = %0
  %7 = select i1 %5, i64 %2, i64 0
  %8 = trunc i64 %7 to i32
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 0x3FE6666666666666) #3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = select i1 %5, i64 %2, i64 1
  %12 = trunc i64 %11 to i32
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 0x3FE6666666666666) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %15 = add nsw i32 %14, %10
  %16 = select i1 %5, i64 %2, i64 2
  %17 = trunc i64 %16 to i32
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 0x3FE6666666666666) #3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %20 = add nsw i32 %19, %15
  %21 = tail call i64 @cq_measure_sll(i64 noundef %1) #3
  %22 = trunc i64 %21 to i32
  %23 = tail call i64 @cq_measure_sll(i64 noundef %2) #3
  %24 = trunc i64 %23 to i32
  %25 = add i32 %20, %22
  %26 = add i32 %25, %24
  ret i32 %26
}

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
