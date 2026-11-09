; ModuleID = 'q7.c'
source_filename = "q7.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@last = local_unnamed_addr global i32 0, align 4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable
define i32 @steps(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp ugt i32 %0, 3
  br i1 %2, label %3, label %11

3:                                                ; preds = %1, %3
  %4 = phi i32 [ %9, %3 ], [ 0, %1 ]
  %5 = phi i32 [ %8, %3 ], [ %0, %1 ]
  %6 = lshr i32 %5, 2
  %7 = xor i32 %6, -1
  %8 = add i32 %5, %7
  %9 = add nuw nsw i32 %4, 1
  %10 = icmp ugt i32 %8, 3
  br i1 %10, label %3, label %11, !llvm.loop !6

11:                                               ; preds = %3, %1
  %12 = phi i32 [ 0, %1 ], [ %9, %3 ]
  store i32 %12, ptr @last, align 4, !tbaa !9
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @q7(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = icmp ult i32 %2, 64
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @steps(i32 noundef %2)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ 1, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
