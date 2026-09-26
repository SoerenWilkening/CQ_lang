; ModuleID = 'lit_i8_r_dw.k3.c'
source_filename = "lit_i8_r_dw.k3.c"
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

10:                                               ; preds = %10, %1
  %11 = phi i32 [ 0, %1 ], [ %20, %10 ]
  %12 = phi i32 [ 0, %1 ], [ %19, %10 ]
  %13 = select i1 %7, i32 %11, i32 55
  %14 = icmp sgt i32 %11, %9
  %15 = zext i1 %14 to i32
  %16 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = add i32 %16, %12
  %19 = add i32 %18, %17
  %20 = add nuw nsw i32 %11, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %22, label %10, !llvm.loop !6

22:                                               ; preds = %10
  %23 = tail call signext i8 @cq_theta_si8(i8 noundef signext %3, double noundef 0x3FE6666666666666) #3
  %24 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %25 = tail call signext i8 @cq_measure_si8(i8 noundef signext %23) #3
  %26 = sext i8 %25 to i32
  %27 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %28 = add i32 %24, %19
  %29 = add i32 %28, %26
  %30 = add i32 %29, %27
  ret i32 %30
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
