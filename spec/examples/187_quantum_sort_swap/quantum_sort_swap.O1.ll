; ModuleID = 'quantum_sort_swap.c'
source_filename = "quantum_sort_swap.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_sort_swap(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
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
  br label %17

15:                                               ; preds = %26
  %16 = load i32, ptr %3, align 16, !tbaa !6
  br label %42

17:                                               ; preds = %2, %26
  %18 = phi i64 [ 0, %2 ], [ %21, %26 ]
  %19 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = add nuw nsw i64 %18, 1
  %22 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !6
  %24 = icmp ugt i32 %20, %23
  br i1 %24, label %25, label %26

25:                                               ; preds = %17
  store i32 %23, ptr %19, align 4, !tbaa !6
  store i32 %20, ptr %22, align 4, !tbaa !6
  br label %26

26:                                               ; preds = %17, %25
  %27 = icmp eq i64 %21, 3
  br i1 %27, label %15, label %17, !llvm.loop !10

28:                                               ; preds = %42
  %29 = load i32, ptr %6, align 4, !tbaa !6
  %30 = shl i32 %29, 2
  %31 = load i32, ptr %9, align 8, !tbaa !6
  %32 = shl i32 %31, 4
  %33 = load i32, ptr %12, align 4, !tbaa !6
  %34 = shl i32 %33, 6
  %35 = or i32 %30, %32
  %36 = or i32 %35, %34
  %37 = or i32 %36, %16
  %38 = tail call i32 @cq_measure_ui32(i32 noundef %37) #5
  %39 = tail call i32 @cq_measure_ui32(i32 noundef %47) #5
  %40 = shl i32 %39, 8
  %41 = or i32 %40, %38
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %41

42:                                               ; preds = %15, %42
  %43 = phi i64 [ 1, %15 ], [ %48, %42 ]
  %44 = phi i32 [ %16, %15 ], [ %47, %42 ]
  %45 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %43
  %46 = load i32, ptr %45, align 4, !tbaa !6
  %47 = tail call i32 @llvm.umax.i32(i32 %46, i32 %44)
  %48 = add nuw nsw i64 %43, 1
  %49 = icmp eq i64 %48, 4
  br i1 %49, label %28, label %42, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!13 = distinct !{!13, !11, !12}
