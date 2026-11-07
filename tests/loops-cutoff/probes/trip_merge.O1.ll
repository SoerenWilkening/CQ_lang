; ModuleID = 'tests/loops-cutoff/probes/trip_merge.c'
source_filename = "tests/loops-cutoff/probes/trip_merge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #2
  %7 = zext i1 %2 to i32
  %8 = select i1 %3, i32 2, i32 0
  %9 = or disjoint i32 %8, %7
  %10 = select i1 %4, i32 4, i32 0
  %11 = or disjoint i32 %9, %10
  %12 = select i1 %5, i32 8, i32 0
  %13 = or disjoint i32 %11, %12
  %14 = select i1 %6, i32 16, i32 0
  %15 = or disjoint i32 %13, %14
  br label %16

16:                                               ; preds = %40, %1
  %17 = phi i32 [ %15, %1 ], [ %45, %40 ]
  %18 = phi i32 [ 0, %1 ], [ %44, %40 ]
  %19 = and i32 %17, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %36, label %21

21:                                               ; preds = %16
  %22 = lshr i32 %17, 1
  %23 = lshr i32 %17, 3
  %24 = xor i32 %22, %23
  %25 = and i32 %24, 1
  %26 = icmp eq i32 %25, 0
  br i1 %26, label %40, label %27

27:                                               ; preds = %21, %27
  %28 = phi i32 [ %33, %27 ], [ 1, %21 ]
  %29 = phi i32 [ %32, %27 ], [ %24, %21 ]
  %30 = lshr i32 %29, 1
  %31 = lshr i32 %29, 3
  %32 = xor i32 %30, %31
  %33 = add nuw nsw i32 %28, 2
  %34 = and i32 %32, 1
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %40, label %27, !llvm.loop !6

36:                                               ; preds = %16
  %37 = and i32 %17, 2
  %38 = icmp eq i32 %37, 0
  %39 = select i1 %38, i32 0, i32 7
  br label %40

40:                                               ; preds = %27, %21, %36
  %41 = phi i32 [ %17, %36 ], [ %24, %21 ], [ %32, %27 ]
  %42 = phi i32 [ %39, %36 ], [ 1, %21 ], [ %33, %27 ]
  %43 = mul nsw i32 %18, 3
  %44 = add nsw i32 %42, %43
  %45 = lshr i32 %41, 1
  %46 = icmp ult i32 %41, 2
  br i1 %46, label %47, label %16, !llvm.loop !9

47:                                               ; preds = %40
  %48 = tail call i32 @cq_measure_si32(i32 noundef %44) #3
  ret i32 %48
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
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
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
