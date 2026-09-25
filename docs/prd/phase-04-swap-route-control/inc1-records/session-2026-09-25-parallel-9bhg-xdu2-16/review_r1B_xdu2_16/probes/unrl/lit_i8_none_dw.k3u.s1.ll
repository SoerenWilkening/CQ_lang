; ModuleID = 'lit_i8_none_dw.k3m.s1.ll'
source_filename = "lit_i8_none_dw.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice(i32 noundef %0)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #3
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext 1, double noundef 5.000000e-01) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 4.000000e-01) #3
  %5 = icmp sgt i32 %2, 1
  %6 = icmp sgt i32 %0, 0
  %7 = and i1 %6, %5
  %8 = sext i8 %3 to i32
  %9 = sub nsw i32 3, %8
  br label %10

10:                                               ; preds = %1
  %11 = select i1 %7, i32 0, i32 55
  %12 = icmp sgt i32 0, %9
  %13 = zext i1 %12 to i32
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %16 = add i32 %14, %15
  %17 = select i1 %7, i32 1, i32 55
  %18 = icmp sgt i32 1, %9
  %19 = zext i1 %18 to i32
  %20 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %21 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %22 = add i32 %20, %16
  %23 = add i32 %22, %21
  %24 = select i1 %7, i32 2, i32 55
  %25 = icmp sgt i32 2, %9
  %26 = zext i1 %25 to i32
  %27 = tail call i32 @cq_measure_si32(i32 noundef %24) #3
  %28 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  %29 = add i32 %27, %23
  %30 = add i32 %29, %28
  %31 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %32 = tail call signext i8 @cq_measure_si8(i8 noundef signext %3) #3
  %33 = sext i8 %32 to i32
  %34 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %35 = add i32 %31, %30
  %36 = add i32 %35, %33
  %37 = add i32 %36, %34
  ret i32 %37
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

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
