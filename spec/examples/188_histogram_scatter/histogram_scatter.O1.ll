; ModuleID = 'histogram_scatter.c'
source_filename = "histogram_scatter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@t = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @histogram(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  br label %20

5:                                                ; preds = %20
  %6 = load i32, ptr %3, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = shl i32 %8, 4
  %10 = or i32 %9, %6
  %11 = getelementptr inbounds i8, ptr %3, i64 8
  %12 = load i32, ptr %11, align 8, !tbaa !6
  %13 = shl i32 %12, 8
  %14 = or i32 %10, %13
  %15 = getelementptr inbounds i8, ptr %3, i64 12
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = shl i32 %16, 12
  %18 = or i32 %14, %17
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %19

20:                                               ; preds = %2, %20
  %21 = phi i32 [ 0, %2 ], [ %29, %20 ]
  %22 = shl nuw nsw i32 %21, 1
  %23 = lshr i32 %4, %22
  %24 = and i32 %23, 3
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %26, align 4, !tbaa !6
  %29 = add nuw nsw i32 %21, 1
  %30 = icmp eq i32 %29, 4
  br i1 %30, label %5, label %20, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @gather_scatter(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  br label %23

6:                                                ; preds = %23
  %7 = tail call i32 @cq_measure_si32(i32 noundef %32) #5
  %8 = load i32, ptr %4, align 16, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %4, i64 4
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = shl i32 %10, 8
  %12 = or i32 %11, %8
  %13 = getelementptr inbounds i8, ptr %4, i64 8
  %14 = load i32, ptr %13, align 8, !tbaa !6
  %15 = shl i32 %14, 16
  %16 = or i32 %12, %15
  %17 = getelementptr inbounds i8, ptr %4, i64 12
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = shl i32 %18, 24
  %20 = or i32 %16, %19
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = add nsw i32 %21, %7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %22

23:                                               ; preds = %3, %23
  %24 = phi i32 [ 0, %3 ], [ %39, %23 ]
  %25 = phi i32 [ 0, %3 ], [ %32, %23 ]
  %26 = mul nuw nsw i32 %24, 3
  %27 = lshr i32 %5, %26
  %28 = and i32 %27, 7
  %29 = zext nneg i32 %28 to i64
  %30 = getelementptr inbounds [8 x i32], ptr @t, i64 0, i64 %29
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = add nsw i32 %31, %25
  %33 = add nsw i32 %24, %2
  %34 = shl nuw nsw i32 %24, 1
  %35 = lshr i32 %5, %34
  %36 = and i32 %35, 3
  %37 = zext nneg i32 %36 to i64
  %38 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %37
  store i32 %33, ptr %38, align 4, !tbaa !6
  %39 = add nuw nsw i32 %24, 1
  %40 = icmp eq i32 %39, 4
  br i1 %40, label %6, label %23, !llvm.loop !13
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
