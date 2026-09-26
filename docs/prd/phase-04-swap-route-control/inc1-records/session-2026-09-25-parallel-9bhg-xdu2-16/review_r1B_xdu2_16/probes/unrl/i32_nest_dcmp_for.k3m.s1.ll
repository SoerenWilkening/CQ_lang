; ModuleID = 'i32_nest_dcmp_for.k3.c'
source_filename = "i32_nest_dcmp_for.k3.c"
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
  %3 = icmp sgt i32 %1, 1
  %4 = icmp slt i32 %2, 5
  %5 = and i1 %3, %4
  %6 = icmp slt i32 %1, -3
  %7 = or i1 %6, %5
  br label %13

8:                                                ; preds = %13
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) #3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %11 = add i32 %9, %23
  %12 = add i32 %11, %10
  ret i32 %12

13:                                               ; preds = %0, %13
  %14 = phi i32 [ 0, %0 ], [ %23, %13 ]
  %15 = phi i32 [ 0, %0 ], [ %24, %13 ]
  %16 = select i1 %7, i32 %15, i32 55
  %17 = add nsw i32 %15, %2
  %18 = icmp sgt i32 %17, 3
  %19 = zext i1 %18 to i32
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %21 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %22 = add i32 %20, %14
  %23 = add i32 %22, %21
  %24 = add nuw nsw i32 %15, 1
  %25 = icmp eq i32 %24, 3
  br i1 %25, label %8, label %13, !llvm.loop !6
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.full"}
