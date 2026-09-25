; ModuleID = 'i8_lit_two_for.k3m.s1.ll'
source_filename = "i8_lit_two_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice(i32 noundef %0)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext 0, double noundef 2.500000e-01) #3
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext 1, double noundef 5.000000e-01) #3
  %4 = icmp sgt i8 %2, 1
  %5 = icmp sgt i32 %0, 0
  %6 = and i1 %5, %4
  br label %7

7:                                                ; preds = %1
  %8 = select i1 %6, i32 0, i32 55
  %9 = select i1 %6, i32 7, i32 0
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %12 = add i32 %10, %11
  %13 = select i1 %6, i32 1, i32 55
  %14 = select i1 %6, i32 7, i32 1
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %17 = add i32 %15, %12
  %18 = add i32 %17, %16
  %19 = select i1 %6, i32 2, i32 55
  %20 = select i1 %6, i32 7, i32 2
  %21 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %23 = add i32 %21, %18
  %24 = add i32 %23, %22
  %25 = tail call signext i8 @cq_measure_si8(i8 noundef signext %2) #3
  %26 = sext i8 %25 to i32
  %27 = tail call signext i8 @cq_measure_si8(i8 noundef signext %3) #3
  %28 = sext i8 %27 to i32
  %29 = add i32 %24, %26
  %30 = add i32 %29, %28
  ret i32 %30
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare signext i8 @cq_measure_si8(i8 noundef signext) local_unnamed_addr #2

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
