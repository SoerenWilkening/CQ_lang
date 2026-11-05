; ModuleID = 'bus_kloop.c'
source_filename = "bus_kloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.bk_node = type { i32, ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @scan_gt(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [6 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #4
  %6 = add i32 %5, %2
  br label %7

7:                                                ; preds = %3, %7
  %8 = phi i64 [ 0, %3 ], [ %13, %7 ]
  %9 = trunc nuw nsw i64 %8 to i32
  %10 = add i32 %6, %9
  %11 = and i32 %10, 7
  %12 = getelementptr inbounds [6 x i32], ptr %4, i64 0, i64 %8
  store i32 %11, ptr %12, align 4, !tbaa !6
  %13 = add nuw nsw i64 %8, 1
  %14 = icmp eq i64 %13, 6
  br i1 %14, label %15, label %7, !llvm.loop !10

15:                                               ; preds = %7, %15
  %16 = phi ptr [ %19, %15 ], [ %4, %7 ]
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = icmp sgt i32 %17, 3
  %19 = getelementptr inbounds i8, ptr %16, i64 4
  br i1 %18, label %15, label %20, !llvm.loop !13

20:                                               ; preds = %15
  %21 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #4
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @local_read(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  br label %9

6:                                                ; preds = %9
  %7 = and i32 %5, 7
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %17, label %20

9:                                                ; preds = %3, %9
  %10 = phi i64 [ 0, %3 ], [ %15, %9 ]
  %11 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %10
  %12 = trunc i64 %10 to i32
  %13 = mul i32 %12, %2
  %14 = add i32 %13, 1
  store i32 %14, ptr %11, align 4, !tbaa !6
  %15 = add nuw nsw i64 %10, 1
  %16 = icmp eq i64 %15, 4
  br i1 %16, label %6, label %9, !llvm.loop !14

17:                                               ; preds = %20, %6
  %18 = phi i32 [ 0, %6 ], [ %27, %20 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %19

20:                                               ; preds = %6, %20
  %21 = phi i32 [ %28, %20 ], [ 0, %6 ]
  %22 = phi i32 [ %27, %20 ], [ 0, %6 ]
  %23 = and i32 %21, 3
  %24 = zext nneg i32 %23 to i64
  %25 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %24
  %26 = load i32, ptr %25, align 4, !tbaa !6
  %27 = add nsw i32 %26, %22
  %28 = add nuw nsw i32 %21, 1
  %29 = icmp eq i32 %28, %7
  br i1 %29, label %17, label %20, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @do_scan(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [6 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #4
  br label %6

6:                                                ; preds = %3, %6
  %7 = phi i64 [ 0, %3 ], [ %13, %6 ]
  %8 = trunc i64 %7 to i32
  %9 = mul i32 %8, %2
  %10 = add i32 %9, %5
  %11 = and i32 %10, 3
  %12 = getelementptr inbounds [6 x i32], ptr %4, i64 0, i64 %7
  store i32 %11, ptr %12, align 4, !tbaa !6
  %13 = add nuw nsw i64 %7, 1
  %14 = icmp eq i64 %13, 6
  br i1 %14, label %15, label %6, !llvm.loop !16

15:                                               ; preds = %6, %15
  %16 = phi i64 [ %20, %15 ], [ 0, %6 ]
  %17 = phi i32 [ %19, %15 ], [ 0, %6 ]
  %18 = trunc nuw nsw i64 %16 to i32
  %19 = add nuw nsw i32 %17, %18
  %20 = add nuw nsw i64 %16, 1
  %21 = getelementptr inbounds [6 x i32], ptr %4, i64 0, i64 %20
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %24, label %15, !llvm.loop !17

24:                                               ; preds = %15
  %25 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #4
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @fill_until(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #4
  br label %11

6:                                                ; preds = %11
  %7 = and i32 %5, 7
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %18, label %9

9:                                                ; preds = %6
  %10 = zext nneg i32 %7 to i64
  br label %24

11:                                               ; preds = %3, %11
  %12 = phi i64 [ 0, %3 ], [ %16, %11 ]
  %13 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %12
  %14 = trunc i64 %12 to i32
  %15 = sub i32 %5, %14
  store i32 %15, ptr %13, align 4, !tbaa !6
  %16 = add nuw nsw i64 %12, 1
  %17 = icmp eq i64 %16, 8
  br i1 %17, label %6, label %11, !llvm.loop !18

18:                                               ; preds = %24, %6
  %19 = and i32 %5, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %20
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #4
  ret i32 %23

24:                                               ; preds = %9, %24
  %25 = phi i64 [ 0, %9 ], [ %29, %24 ]
  %26 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %25
  %27 = trunc i64 %25 to i32
  %28 = add i32 %27, %2
  store i32 %28, ptr %26, align 4, !tbaa !6
  %29 = add nuw nsw i64 %25, 1
  %30 = icmp eq i64 %29, %10
  br i1 %30, label %18, label %24, !llvm.loop !19
}

; Function Attrs: nounwind ssp uwtable
define i32 @chase(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.bk_node, align 8
  %5 = alloca %struct.bk_node, align 8
  %6 = alloca %struct.bk_node, align 8
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  %8 = and i32 %7, 3
  store i32 %8, ptr %4, align 8, !tbaa !20
  %9 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr null, ptr %9, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #4
  %10 = and i32 %7, 1
  store i32 %10, ptr %5, align 8, !tbaa !20
  %11 = getelementptr inbounds i8, ptr %5, i64 8
  store ptr %4, ptr %11, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6) #4
  %12 = and i32 %7, 2
  store i32 %12, ptr %6, align 8, !tbaa !20
  %13 = getelementptr inbounds i8, ptr %6, i64 8
  store ptr %5, ptr %13, align 8, !tbaa !23
  br label %14

14:                                               ; preds = %3, %19
  %15 = phi i32 [ 0, %3 ], [ %22, %19 ]
  %16 = phi ptr [ %6, %3 ], [ %21, %19 ]
  %17 = load i32, ptr %16, align 8, !tbaa !20
  %18 = icmp eq i32 %17, %2
  br i1 %18, label %24, label %19

19:                                               ; preds = %14
  %20 = getelementptr inbounds i8, ptr %16, i64 8
  %21 = load ptr, ptr %20, align 8, !tbaa !23
  %22 = add nuw nsw i32 %15, 1
  %23 = icmp eq ptr %21, null
  br i1 %23, label %24, label %14, !llvm.loop !24

24:                                               ; preds = %14, %19
  %25 = phi i32 [ %15, %14 ], [ %22, %19 ]
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @cb_overtaken(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %2, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  br label %10

8:                                                ; preds = %10
  %9 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  ret i32 %9

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %4, %3 ], [ %15, %10 ]
  %12 = phi i64 [ 0, %3 ], [ %16, %10 ]
  %13 = phi i32 [ 0, %3 ], [ %14, %10 ]
  %14 = add nsw i32 %11, %13
  %15 = add nsw i32 %14, 1
  %16 = add nuw nsw i64 %12, 1
  %17 = icmp eq i64 %16, %7
  br i1 %17, label %8, label %10, !llvm.loop !25
}

; Function Attrs: nounwind ssp uwtable
define i32 @cb_qexit(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  br label %10

6:                                                ; preds = %10
  %7 = and i32 %2, 3
  %8 = add nuw nsw i32 %7, 1
  %9 = zext nneg i32 %8 to i64
  br label %18

10:                                               ; preds = %3, %10
  %11 = phi i64 [ 0, %3 ], [ %16, %10 ]
  %12 = trunc nuw nsw i64 %11 to i32
  %13 = lshr i32 %5, %12
  %14 = and i32 %13, 1
  %15 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %11
  store i32 %14, ptr %15, align 4, !tbaa !6
  %16 = add nuw nsw i64 %11, 1
  %17 = icmp eq i64 %16, 4
  br i1 %17, label %6, label %10, !llvm.loop !26

18:                                               ; preds = %6, %23
  %19 = phi i64 [ 0, %6 ], [ %24, %23 ]
  %20 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !6
  %22 = icmp eq i32 %21, 1
  br i1 %22, label %26, label %23

23:                                               ; preds = %18
  %24 = add nuw nsw i64 %19, 1
  %25 = icmp eq i64 %24, %9
  br i1 %25, label %28, label %18, !llvm.loop !27

26:                                               ; preds = %18
  %27 = trunc nuw nsw i64 %19 to i32
  br label %28

28:                                               ; preds = %23, %26
  %29 = phi i32 [ %27, %26 ], [ -1, %23 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %30
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
!20 = !{!21, !7, i64 0}
!21 = !{!"bk_node", !7, i64 0, !22, i64 8}
!22 = !{!"any pointer", !8, i64 0}
!23 = !{!21, !22, i64 8}
!24 = distinct !{!24, !11, !12}
!25 = distinct !{!25, !11, !12}
!26 = distinct !{!26, !11, !12}
!27 = distinct !{!27, !11, !12}
