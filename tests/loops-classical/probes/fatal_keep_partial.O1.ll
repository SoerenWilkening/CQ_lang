; ModuleID = 'fatal_keep_partial.c'
source_filename = "fatal_keep_partial.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p31(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #4
  %5 = and i32 %4, 3
  store i32 %5, ptr %3, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %3, i64 4
  %7 = lshr i32 %4, 2
  %8 = and i32 %7, 3
  store i32 %8, ptr %6, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  %10 = lshr i32 %4, 4
  %11 = and i32 %10, 3
  store i32 %11, ptr %9, align 8, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %3, i64 12
  %13 = lshr i32 %4, 6
  %14 = and i32 %13, 3
  store i32 %14, ptr %12, align 4, !tbaa !6
  br label %21

15:                                               ; preds = %30
  %16 = load i32, ptr %12, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #4
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %4) #4
  %19 = shl i32 %18, 8
  %20 = or i32 %19, %17
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #4
  ret i32 %20

21:                                               ; preds = %2, %30
  %22 = phi i64 [ 0, %2 ], [ %25, %30 ]
  %23 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !6
  %25 = add nuw nsw i64 %22, 1
  %26 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = icmp ugt i32 %24, %27
  br i1 %28, label %29, label %30

29:                                               ; preds = %21
  store i32 %27, ptr %23, align 4, !tbaa !6
  store i32 %24, ptr %26, align 4, !tbaa !6
  br label %30

30:                                               ; preds = %21, %29
  %31 = icmp eq i64 %25, 3
  br i1 %31, label %15, label %21, !llvm.loop !10
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
