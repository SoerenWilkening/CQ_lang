; ModuleID = 'trip_factor.c'
source_filename = "trip_factor.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @pa_mixed(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !10
  %10 = load volatile ptr, ptr %7, align 8, !tbaa !10
  %11 = icmp ugt i32 %8, %2
  br i1 %11, label %12, label %25

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp ne i32 %13, 0
  br label %15

15:                                               ; preds = %12, %23
  %16 = phi i32 [ %8, %12 ], [ %17, %23 ]
  %17 = lshr i32 %16, 1
  %18 = icmp ugt i32 %9, %17
  %19 = select i1 %14, i1 %18, i1 false
  br i1 %19, label %20, label %23

20:                                               ; preds = %15
  %21 = load i32, ptr %10, align 4, !tbaa !6
  %22 = xor i32 %21, 5
  store i32 %22, ptr %10, align 4, !tbaa !6
  br label %23

23:                                               ; preds = %20, %15
  %24 = icmp ugt i32 %17, %2
  br i1 %24, label %15, label %25, !llvm.loop !12

25:                                               ; preds = %23, %5
  %26 = phi i32 [ %8, %5 ], [ %17, %23 ]
  %27 = load i32, ptr %10, align 4, !tbaa !6
  %28 = call i32 @cq_measure_ui32(i32 noundef %27) #4
  %29 = shl i32 %28, 4
  %30 = call i32 @cq_measure_ui32(i32 noundef %26) #4
  %31 = add i32 %29, %30
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  ret i32 %31
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @pb_nested(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !10
  %10 = load volatile ptr, ptr %7, align 8, !tbaa !10
  %11 = icmp ugt i32 %8, %2
  br i1 %11, label %12, label %37

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp ne i32 %13, 0
  %15 = and i32 %3, 2
  %16 = icmp eq i32 %15, 0
  br label %17

17:                                               ; preds = %12, %35
  %18 = phi i32 [ %8, %12 ], [ %20, %35 ]
  %19 = phi i32 [ 0, %12 ], [ %30, %35 ]
  %20 = lshr i32 %18, 1
  %21 = icmp ugt i32 %9, %20
  %22 = select i1 %14, i1 %21, i1 false
  br i1 %22, label %23, label %29

23:                                               ; preds = %17, %23
  %24 = phi i32 [ %26, %23 ], [ %9, %17 ]
  %25 = phi i32 [ %27, %23 ], [ %19, %17 ]
  %26 = lshr i32 %24, 1
  %27 = add i32 %25, 2
  %28 = icmp ugt i32 %26, %20
  br i1 %28, label %23, label %29, !llvm.loop !15

29:                                               ; preds = %23, %17
  %30 = phi i32 [ %19, %17 ], [ %27, %23 ]
  br i1 %16, label %35, label %31

31:                                               ; preds = %29
  %32 = add i32 %30, 1
  %33 = load i32, ptr %10, align 4, !tbaa !6
  %34 = add i32 %32, %33
  store i32 %34, ptr %10, align 4, !tbaa !6
  br label %35

35:                                               ; preds = %31, %29
  %36 = icmp ugt i32 %20, %2
  br i1 %36, label %17, label %37, !llvm.loop !16

37:                                               ; preds = %35, %5
  %38 = phi i32 [ 0, %5 ], [ %30, %35 ]
  %39 = call i32 @cq_measure_ui32(i32 noundef %38) #4
  %40 = shl i32 %39, 8
  %41 = load i32, ptr %10, align 4, !tbaa !6
  %42 = call i32 @cq_measure_ui32(i32 noundef %41) #4
  %43 = add i32 %42, %40
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  ret i32 %43
}

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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
