; ModuleID = 'table_k6.c'
source_filename = "table_k6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@pf = global ptr @kf, align 8
@pd = global ptr @kd, align 8
@__cq_k_tk6_f = internal constant i32 6, align 4
@__cq_k_tk6_d = internal constant i32 6, align 4
@__cq_k_tk2_f = internal constant i32 2, align 4
@llvm.used = appending global [3 x ptr] [ptr @__cq_k_tk2_f, ptr @__cq_k_tk6_d, ptr @__cq_k_tk6_f], section "llvm.metadata"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kf(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %11

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %5, 1
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !6

11:                                               ; preds = %4, %2
  %12 = phi i32 [ 0, %2 ], [ %9, %4 ]
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kd(i32 noundef %0, i32 noundef %1) #0 {
  br label %3

3:                                                ; preds = %3, %2
  %4 = phi i32 [ %0, %2 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %2 ], [ %8, %3 ]
  %6 = mul i32 %4, %1
  %7 = add i32 %6, 1
  %8 = add i32 %5, 2
  %9 = icmp ugt i32 %7, 9
  br i1 %9, label %3, label %10, !llvm.loop !9

10:                                               ; preds = %3
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk6_f(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile ptr, ptr @pf, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @tk6_d(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile ptr, ptr @pd, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk2_f(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile ptr, ptr @pf, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #4
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #4
  ret i32 %7
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !12, i64 0}
!12 = !{!"omnipotent char", !13, i64 0}
!13 = !{!"Simple C/C++ TBAA"}
