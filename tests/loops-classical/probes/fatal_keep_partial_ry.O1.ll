; ModuleID = 'fatal_keep_partial_ry.c'
source_filename = "fatal_keep_partial_ry.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p30(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  %6 = and i32 %5, 3
  store i32 %6, ptr %4, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %4, i64 4
  %8 = lshr i32 %5, 2
  %9 = and i32 %8, 3
  store i32 %9, ptr %7, align 4, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  %11 = lshr i32 %5, 4
  %12 = and i32 %11, 3
  store i32 %12, ptr %10, align 8, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %4, i64 12
  %14 = lshr i32 %5, 6
  %15 = and i32 %14, 3
  store i32 %15, ptr %13, align 4, !tbaa !6
  br label %23

16:                                               ; preds = %32
  %17 = tail call i32 @cq_theta_ui32(i32 noundef %5, double noundef %2) #3
  %18 = load i32, ptr %13, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #4
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %17) #4
  %21 = shl i32 %20, 8
  %22 = or i32 %21, %19
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %22

23:                                               ; preds = %3, %32
  %24 = phi i64 [ 0, %3 ], [ %27, %32 ]
  %25 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %24
  %26 = load i32, ptr %25, align 4, !tbaa !6
  %27 = add nuw nsw i64 %24, 1
  %28 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %27
  %29 = load i32, ptr %28, align 4, !tbaa !6
  %30 = icmp ugt i32 %26, %29
  br i1 %30, label %31, label %32

31:                                               ; preds = %23
  store i32 %29, ptr %25, align 4, !tbaa !6
  store i32 %26, ptr %28, align 4, !tbaa !6
  br label %32

32:                                               ; preds = %23, %31
  %33 = icmp eq i64 %27, 3
  br i1 %33, label %16, label %23, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
