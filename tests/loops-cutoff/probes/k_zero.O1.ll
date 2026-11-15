; ModuleID = 'k_zero.c'
source_filename = "k_zero.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k_kz_while = internal constant i32 0, align 4
@__cq_k_kz_do = internal constant i32 0, align 4
@__cq_k_kz_tab = internal constant i32 0, align 4
@__cq_k_kz_rf = internal constant i32 0, align 4
@pf = global ptr @kf, align 8
@llvm.used = appending global [4 x ptr] [ptr @__cq_k_kz_do, ptr @__cq_k_kz_rf, ptr @__cq_k_kz_tab, ptr @__cq_k_kz_while], section "llvm.metadata"

; Function Attrs: nounwind ssp uwtable
define i32 @kz_while(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = icmp ugt i32 %4, 9
  br i1 %5, label %6, label %15

6:                                                ; preds = %3, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %3 ]
  %8 = phi i32 [ %10, %6 ], [ %4, %3 ]
  %9 = mul i32 %8, %2
  %10 = add i32 %9, 1
  %11 = add i32 %7, 1
  %12 = icmp ugt i32 %10, 9
  br i1 %12, label %6, label %13, !llvm.loop !6

13:                                               ; preds = %6
  %14 = shl i32 %11, 6
  br label %15

15:                                               ; preds = %13, %3
  %16 = phi i32 [ %4, %3 ], [ %10, %13 ]
  %17 = phi i32 [ 0, %3 ], [ %14, %13 ]
  %18 = or disjoint i32 %17, %16
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #5
  ret i32 %19
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @kz_do(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  br label %5

5:                                                ; preds = %5, %3
  %6 = phi i32 [ %4, %3 ], [ %9, %5 ]
  %7 = phi i32 [ 0, %3 ], [ %10, %5 ]
  %8 = mul i32 %6, %2
  %9 = add i32 %8, 1
  %10 = add i32 %7, 2
  %11 = icmp ugt i32 %9, 9
  br i1 %11, label %5, label %12, !llvm.loop !9

12:                                               ; preds = %5
  %13 = shl i32 %10, 6
  %14 = or disjoint i32 %13, %9
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #5
  ret i32 %15
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kf(i32 noundef %0, i32 noundef %1) #2 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %13

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %5, 1
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !10

11:                                               ; preds = %4
  %12 = shl i32 %9, 6
  br label %13

13:                                               ; preds = %11, %2
  %14 = phi i32 [ %0, %2 ], [ %8, %11 ]
  %15 = phi i32 [ 0, %2 ], [ %12, %11 ]
  %16 = or disjoint i32 %15, %14
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @kz_tab(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = load volatile ptr, ptr @pf, align 8, !tbaa !11
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #5
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #5
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @kz_rec(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = tail call fastcc i32 @kz_rf(i32 noundef %3)
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #5
  ret i32 %5
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @kz_rf(i32 noundef %0) unnamed_addr #3 {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi i32 [ 0, %1 ], [ %8, %6 ]
  %4 = phi i32 [ %0, %1 ], [ %7, %6 ]
  %5 = icmp ugt i32 %4, 9
  br i1 %5, label %6, label %9

6:                                                ; preds = %2
  %7 = udiv i32 %4, 3
  %8 = add i32 %3, 1
  br label %2

9:                                                ; preds = %2
  %10 = shl nuw nsw i32 %4, 4
  %11 = add i32 %3, %10
  ret i32 %11
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = !{!12, !12, i64 0}
!12 = !{!"any pointer", !13, i64 0}
!13 = !{!"omnipotent char", !14, i64 0}
!14 = !{!"Simple C/C++ TBAA"}
