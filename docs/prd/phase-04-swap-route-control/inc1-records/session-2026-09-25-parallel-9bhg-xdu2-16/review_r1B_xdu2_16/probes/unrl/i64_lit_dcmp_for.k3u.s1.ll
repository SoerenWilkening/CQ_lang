; ModuleID = 'i64_lit_dcmp_for.k3m.s1.ll'
source_filename = "i64_lit_dcmp_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice(i32 noundef %0)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call i64 @cq_theta_sll(i64 noundef 0, double noundef 2.500000e-01) #3
  %3 = tail call i64 @cq_theta_sll(i64 noundef 1, double noundef 5.000000e-01) #3
  %4 = icmp sgt i64 %2, 1
  %5 = icmp sgt i32 %0, 0
  %6 = and i1 %5, %4
  br label %7

7:                                                ; preds = %1
  %8 = select i1 %6, i32 0, i32 55
  %9 = icmp sgt i64 %3, 3
  %10 = zext i1 %9 to i32
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %13 = add i32 %11, %12
  %14 = select i1 %6, i32 1, i32 55
  %15 = add nsw i64 %3, 1
  %16 = icmp sgt i64 %15, 3
  %17 = zext i1 %16 to i32
  %18 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %20 = add i32 %18, %13
  %21 = add i32 %20, %19
  %22 = select i1 %6, i32 2, i32 55
  %23 = add nsw i64 %3, 2
  %24 = icmp sgt i64 %23, 3
  %25 = zext i1 %24 to i32
  %26 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  %28 = add i32 %26, %21
  %29 = add i32 %28, %27
  %30 = tail call i64 @cq_measure_sll(i64 noundef %2) #3
  %31 = trunc i64 %30 to i32
  %32 = tail call i64 @cq_measure_sll(i64 noundef %3) #3
  %33 = trunc i64 %32 to i32
  %34 = add i32 %29, %31
  %35 = add i32 %34, %33
  ret i32 %35
}

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #2

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
