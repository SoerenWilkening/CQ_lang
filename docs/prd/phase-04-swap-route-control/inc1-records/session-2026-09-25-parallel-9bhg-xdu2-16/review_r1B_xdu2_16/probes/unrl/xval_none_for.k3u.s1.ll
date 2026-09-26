; ModuleID = 'xval_none_for.k3m.s1.ll'
source_filename = "xval_none_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice()
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice() unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 4.000000e-01) #3
  %4 = icmp sgt i32 %1, 1
  %5 = icmp slt i32 %3, 5
  %6 = and i1 %4, %5
  br label %7

7:                                                ; preds = %0
  %8 = xor i32 1, %2
  %9 = icmp sgt i32 %8, 3
  %10 = zext i1 %9 to i32
  %11 = select i1 %6, i32 %10, i32 55
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = xor i32 2, %2
  %14 = icmp sgt i32 %13, 3
  %15 = zext i1 %14 to i32
  %16 = select i1 %6, i32 %15, i32 55
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %18 = add nsw i32 %17, %12
  %19 = xor i32 3, %2
  %20 = icmp sgt i32 %19, 3
  %21 = zext i1 %20 to i32
  %22 = select i1 %6, i32 %21, i32 55
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  %24 = add nsw i32 %23, %18
  %25 = tail call i32 @cq_measure_si32(i32 noundef %1) #3
  %26 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %27 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %28 = add i32 %25, %24
  %29 = add i32 %28, %26
  %30 = add i32 %29, %27
  ret i32 %30
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
