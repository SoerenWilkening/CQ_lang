; ModuleID = 'recv_k_cut.c'
source_filename = "recv_k_cut.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fp = global ptr @g, align 8
@__cq_k_e = internal constant i32 2, align 4
@llvm.used = appending global [1 x ptr] [ptr @__cq_k_e], section "llvm.metadata"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @g(i32 noundef %0) #0 {
  %2 = icmp ugt i32 %0, 2
  br i1 %2, label %3, label %18

3:                                                ; preds = %1
  %4 = add i32 %0, -6
  %5 = icmp ult i32 %4, -3
  %6 = select i1 %5, i32 2, i32 1
  br label %7

7:                                                ; preds = %3, %7
  %8 = phi i32 [ %14, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %13, %7 ], [ 1, %3 ]
  %10 = phi i32 [ %11, %7 ], [ %0, %3 ]
  %11 = add i32 %10, -3
  %12 = mul i32 %9, 5
  %13 = add i32 %12, %11
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, %6
  br i1 %15, label %16, label %7, !llvm.loop !6

16:                                               ; preds = %7
  %17 = shl i32 %13, 4
  br label %18

18:                                               ; preds = %16, %1
  %19 = phi i32 [ %0, %1 ], [ %11, %16 ]
  %20 = phi i32 [ 16, %1 ], [ %17, %16 ]
  %21 = add i32 %20, %19
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = load volatile ptr, ptr @fp, align 8, !tbaa !9
  %5 = tail call i32 %4(i32 noundef %3) #4
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  ret i32 %6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

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
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
