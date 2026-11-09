; ModuleID = 'q6.c'
source_filename = "q6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@T = internal unnamed_addr constant [4 x i32] [i32 5, i32 7, i32 11, i32 13], align 16
@cell = local_unnamed_addr global i32 0, align 4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define i32 @rd(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %3, label %5

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  br label %7

5:                                                ; preds = %7, %1
  %6 = phi i32 [ 0, %1 ], [ %12, %7 ]
  ret i32 %6

7:                                                ; preds = %3, %7
  %8 = phi i64 [ 0, %3 ], [ %13, %7 ]
  %9 = phi i32 [ 0, %3 ], [ %12, %7 ]
  %10 = getelementptr inbounds [4 x i32], ptr @T, i64 0, i64 %8
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = add nsw i32 %11, %9
  %13 = add nuw nsw i64 %8, 1
  %14 = icmp eq i64 %13, %4
  br i1 %14, label %5, label %7, !llvm.loop !10
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define range(i32 -2147483647, -2147483648) i32 @wr(i32 noundef %0) local_unnamed_addr #1 {
  store i32 %0, ptr @cell, align 4, !tbaa !6
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @q6(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %10

5:                                                ; preds = %2
  %6 = and i32 %3, 3
  %7 = tail call i32 @rd(i32 noundef %6)
  %8 = mul nsw i32 %7, 3
  %9 = tail call i32 @wr(i32 noundef %8)
  br label %15

10:                                               ; preds = %2
  %11 = add nsw i32 %3, 1
  %12 = and i32 %11, 3
  %13 = tail call i32 @rd(i32 noundef %12)
  %14 = mul nsw i32 %13, 5
  br label %15

15:                                               ; preds = %10, %5
  %16 = phi i32 [ %9, %5 ], [ %14, %10 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
