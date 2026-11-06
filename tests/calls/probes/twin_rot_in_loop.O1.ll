; ModuleID = 'twin_rot_in_loop.c'
source_filename = "twin_rot_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = internal unnamed_addr constant [2 x ptr] [ptr @h, ptr @k], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @r1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call fastcc i32 @f(i32 noundef %0)
  ret i32 %2
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @f(i32 noundef %0) unnamed_addr #1 {
  br label %3

2:                                                ; preds = %3
  ret i32 %8

3:                                                ; preds = %1, %3
  %4 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %9, %3 ]
  %6 = add nsw i32 %5, %0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #4
  %8 = add nsw i32 %7, %4
  %9 = add nuw nsw i32 %5, 1
  %10 = icmp eq i32 %9, 3
  br i1 %10, label %2, label %3, !llvm.loop !6
}

; Function Attrs: nounwind ssp uwtable
define i32 @r2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call fastcc i32 @g(i32 noundef %0)
  %3 = shl nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) unnamed_addr #1 {
  %2 = tail call fastcc i32 @f(i32 noundef %0)
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @r3(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [2 x ptr], ptr @tab, i64 0, i64 %3
  %5 = load ptr, ptr %4, align 8, !tbaa !9
  %6 = tail call i32 %5(i32 noundef %0) #5
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal i32 @h(i32 noundef %0) #1 {
  br label %3

2:                                                ; preds = %3
  ret i32 %8

3:                                                ; preds = %1, %3
  %4 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %9, %3 ]
  %6 = add nsw i32 %5, %0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #4
  %8 = add nsw i32 %7, %4
  %9 = add nuw nsw i32 %5, 1
  %10 = icmp eq i32 %9, 3
  br i1 %10, label %2, label %3, !llvm.loop !13
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal range(i32 -2147483648, 2147483647) i32 @k(i32 noundef %0) #3 {
  %2 = add nsw i32 %0, -1
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = distinct !{!13, !7, !8}
