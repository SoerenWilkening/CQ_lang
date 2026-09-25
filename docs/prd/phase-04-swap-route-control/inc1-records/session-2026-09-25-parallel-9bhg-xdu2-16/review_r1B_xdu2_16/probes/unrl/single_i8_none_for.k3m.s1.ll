; ModuleID = 'single_i8_none_for.k3.c'
source_filename = "single_i8_none_for.k3.c"
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
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext 1, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 4.000000e-01) #3
  %4 = icmp sgt i32 %1, 1
  %5 = sext i8 %2 to i32
  %6 = sub nsw i32 3, %5
  br label %15

7:                                                ; preds = %15
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #3
  %9 = tail call signext i8 @cq_measure_si8(i8 noundef signext %2) #3
  %10 = sext i8 %9 to i32
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %12 = add i32 %8, %24
  %13 = add i32 %12, %10
  %14 = add i32 %13, %11
  ret i32 %14

15:                                               ; preds = %0, %15
  %16 = phi i32 [ 0, %0 ], [ %24, %15 ]
  %17 = phi i32 [ 0, %0 ], [ %25, %15 ]
  %18 = select i1 %4, i32 %17, i32 55
  %19 = icmp sgt i32 %17, %6
  %20 = zext i1 %19 to i32
  %21 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %23 = add i32 %21, %16
  %24 = add i32 %23, %22
  %25 = add nuw nsw i32 %17, 1
  %26 = icmp eq i32 %25, 3
  br i1 %26, label %7, label %15, !llvm.loop !6
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.full"}
