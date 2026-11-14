; ModuleID = 'ctl_helper.c'
source_filename = "ctl_helper.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@p1 = global ptr @t1, align 8
@p2 = local_unnamed_addr global ptr @t2, align 8
@p3 = global ptr @t3, align 8

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t1(i32 noundef %0, i32 noundef %1) #0 {
  %3 = tail call fastcc i32 @h1(i32 noundef %0, i32 noundef %1)
  %4 = add i32 %3, 1
  ret i32 %4
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t2(i32 noundef %0, i32 noundef %1) #0 {
  %3 = tail call fastcc i32 @h2(i32 noundef %0, i32 noundef %1)
  %4 = add i32 %3, 2
  ret i32 %4
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t3(i32 noundef %0, i32 noundef %1) #0 {
  %3 = tail call fastcc i32 @hq(i32 noundef %0, i32 noundef %1)
  %4 = add i32 %3, 3
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @ch1(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile ptr, ptr @p1, align 8, !tbaa !6
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @ch3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile ptr, ptr @p3, align 8, !tbaa !6
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h1(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %11

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %5, 1
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !10

11:                                               ; preds = %4, %2
  %12 = phi i32 [ 0, %2 ], [ %9, %4 ]
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h2(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %13, label %5

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %10, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %9, %5 ], [ %0, %2 ]
  %8 = lshr i32 %7, 1
  %9 = add i32 %8, %1
  %10 = add i32 %6, 1
  %11 = and i32 %9, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %5, !llvm.loop !13

13:                                               ; preds = %5, %2
  %14 = phi i32 [ 0, %2 ], [ %10, %5 ]
  ret i32 %14
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @hq(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = and i32 %1, 1
  %4 = icmp ne i32 %3, 0
  %5 = icmp ugt i32 %0, 2
  %6 = and i1 %4, %5
  br i1 %6, label %7, label %19

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %11, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %10, %7 ], [ %0, %2 ]
  %10 = add i32 %9, -3
  %11 = add nuw nsw i32 %8, 1
  %12 = shl nuw i32 2, %8
  %13 = and i32 %12, %1
  %14 = icmp ne i32 %13, 0
  %15 = icmp ugt i32 %10, 2
  %16 = select i1 %14, i1 %15, i1 false
  br i1 %16, label %7, label %17, !llvm.loop !14

17:                                               ; preds = %7
  %18 = shl i32 %11, 4
  br label %19

19:                                               ; preds = %17, %2
  %20 = phi i32 [ %0, %2 ], [ %10, %17 ]
  %21 = phi i32 [ 0, %2 ], [ %18, %17 ]
  %22 = add i32 %21, %20
  ret i32 %22
}

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
