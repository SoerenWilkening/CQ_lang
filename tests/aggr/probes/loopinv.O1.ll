; ModuleID = 'loopinv.c'
source_filename = "loopinv.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @l_invariant(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 1.000000e+00) #2
  %3 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 1.000000e+00) #2
  %4 = insertelement <2 x i64> poison, i64 %2, i64 0
  %5 = insertelement <2 x i64> %4, i64 %3, i64 1
  %6 = mul <2 x i64> %5, <i64 3, i64 3>
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %1
  %9 = zext nneg i32 %0 to i64
  br label %12

10:                                               ; preds = %12, %1
  %11 = phi i64 [ 0, %1 ], [ %23, %12 ]
  ret i64 %11

12:                                               ; preds = %8, %12
  %13 = phi i64 [ 0, %8 ], [ %24, %12 ]
  %14 = phi i64 [ 0, %8 ], [ %23, %12 ]
  %15 = insertelement <2 x i64> poison, i64 %13, i64 0
  %16 = shl nuw nsw i64 %13, 1
  %17 = insertelement <2 x i64> %15, i64 %16, i64 1
  %18 = add <2 x i64> %17, %6
  %19 = shufflevector <2 x i64> %18, <2 x i64> poison, <2 x i32> <i32 1, i32 poison>
  %20 = xor <2 x i64> %18, %19
  %21 = extractelement <2 x i64> %20, i64 0
  %22 = tail call i64 @cq_measure_sl(i64 noundef %21) #3
  %23 = add nsw i64 %22, %14
  %24 = add nuw nsw i64 %13, 1
  %25 = icmp eq i64 %24, %9
  br i1 %25, label %10, label %12, !llvm.loop !6
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

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
