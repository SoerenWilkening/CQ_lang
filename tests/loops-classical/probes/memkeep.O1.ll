; ModuleID = 'memkeep.c'
source_filename = "memkeep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @k_hist(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  br label %13

6:                                                ; preds = %13
  %7 = getelementptr inbounds i8, ptr %4, i64 4
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %5, double noundef %2) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %9) #5
  %12 = add i32 %11, %10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ 0, %3 ], [ %22, %13 ]
  %15 = shl nuw nsw i32 %14, 1
  %16 = lshr i32 %5, %15
  %17 = and i32 %16, 3
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %19, align 4, !tbaa !6
  %22 = add nuw nsw i32 %14, 1
  %23 = icmp eq i32 %22, 4
  br i1 %23, label %6, label %13, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @k_whole(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  br label %23

5:                                                ; preds = %23
  %6 = load i32, ptr %3, align 16, !tbaa !6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #5
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #5
  %11 = shl i32 %10, 1
  %12 = or i32 %11, %7
  %13 = getelementptr inbounds i8, ptr %3, i64 8
  %14 = load i32, ptr %13, align 8, !tbaa !6
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #5
  %16 = shl i32 %15, 2
  %17 = or i32 %12, %16
  %18 = getelementptr inbounds i8, ptr %3, i64 12
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #5
  %21 = shl i32 %20, 3
  %22 = or i32 %17, %21
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %22

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %33, %23 ]
  %25 = trunc nuw nsw i64 %24 to i32
  %26 = lshr i32 %4, %25
  %27 = trunc i64 %24 to i32
  %28 = or i32 %27, 4
  %29 = lshr i32 %4, %28
  %30 = xor i32 %29, %26
  %31 = and i32 %30, 1
  %32 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %24
  store i32 %31, ptr %32, align 4, !tbaa !6
  %33 = add nuw nsw i64 %24, 1
  %34 = icmp eq i64 %33, 4
  br i1 %34, label %5, label %23, !llvm.loop !13
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
