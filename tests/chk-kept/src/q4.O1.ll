; ModuleID = 'q4.c'
source_filename = "q4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@vp = global ptr @inc, align 8

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal range(i32 -2147483648, 2147483647) i32 @inc(i32 noundef %0) #0 {
  %2 = add nsw i32 %0, -1
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @q4a(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = load volatile ptr, ptr @vp, align 8, !tbaa !6
  %5 = tail call fastcc i32 @f(i32 noundef %3, ptr noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @f(i32 noundef %0, ptr nocapture noundef readonly %1) unnamed_addr #3 {
  %3 = tail call i32 %1(i32 noundef %0) #5
  %4 = icmp sgt i32 %3, -1
  %5 = zext i1 %4 to i32
  %6 = add nsw i32 %5, %0
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @q4b(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = load volatile ptr, ptr @vp, align 8, !tbaa !6
  %8 = tail call fastcc i32 @f(i32 noundef %3, ptr noundef %7)
  br label %9

9:                                                ; preds = %6, %2
  %10 = phi i32 [ %8, %6 ], [ 0, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @q4c(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = load volatile ptr, ptr @vp, align 8, !tbaa !6
  %8 = tail call fastcc i32 @f2(i32 noundef %3, ptr noundef %7)
  br label %9

9:                                                ; preds = %6, %2
  %10 = phi i32 [ %8, %6 ], [ 0, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @f2(i32 noundef %0, ptr nocapture noundef readonly %1) unnamed_addr #3 {
  %3 = mul i32 %0, 3
  br label %4

4:                                                ; preds = %2, %10
  %5 = phi i32 [ 0, %2 ], [ %12, %10 ]
  %6 = phi i32 [ 0, %2 ], [ %11, %10 ]
  %7 = add nsw i32 %5, %0
  %8 = tail call i32 %1(i32 noundef %7) #5
  %9 = icmp sgt i32 %8, -1
  br i1 %9, label %14, label %10

10:                                               ; preds = %4
  %11 = add nsw i32 %6, %0
  %12 = add nuw nsw i32 %5, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %14, label %4, !llvm.loop !10

14:                                               ; preds = %4, %10
  %15 = phi i32 [ %6, %4 ], [ %3, %10 ]
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @q4d(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = load volatile ptr, ptr @vp, align 8, !tbaa !6
  %5 = tail call fastcc i32 @f2(i32 noundef %3, ptr noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %6
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
