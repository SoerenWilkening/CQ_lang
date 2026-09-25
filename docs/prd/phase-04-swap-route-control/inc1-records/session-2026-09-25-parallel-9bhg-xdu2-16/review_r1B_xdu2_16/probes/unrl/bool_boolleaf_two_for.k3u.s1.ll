; ModuleID = 'bool_boolleaf_two_for.k3m.s1.ll'
source_filename = "bool_boolleaf_two_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice()
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice() unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.500000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3
  %3 = icmp slt i32 %2, 5
  %4 = and i1 %1, %3
  br label %5

5:                                                ; preds = %0
  %6 = select i1 %4, i32 0, i32 55
  %7 = select i1 %4, i32 7, i32 0
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %10 = add i32 %8, %9
  %11 = select i1 %4, i32 1, i32 55
  %12 = select i1 %4, i32 7, i32 1
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %15 = add i32 %13, %10
  %16 = add i32 %15, %14
  %17 = select i1 %4, i32 2, i32 55
  %18 = select i1 %4, i32 7, i32 2
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %20 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %21 = add i32 %19, %16
  %22 = add i32 %21, %20
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #3
  %24 = zext i1 %23 to i32
  %25 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %26 = add i32 %22, %24
  %27 = add i32 %26, %25
  ret i32 %27
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
