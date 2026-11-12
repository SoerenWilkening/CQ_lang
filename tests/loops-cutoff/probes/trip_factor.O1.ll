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

; Function Attrs: nounwind ssp uwtable
define i32 @pc_choice(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
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
  br i1 %11, label %12, label %31

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp eq i32 %13, 0
  %15 = mul i32 %9, 3
  br label %16

16:                                               ; preds = %12, %26
  %17 = phi i32 [ %8, %12 ], [ %19, %26 ]
  %18 = phi i32 [ 1, %12 ], [ %29, %26 ]
  %19 = lshr i32 %17, 1
  br i1 %14, label %22, label %20

20:                                               ; preds = %16
  %21 = add i32 %19, %15
  call void @cq_phi(double noundef 2.500000e-01) #4
  br label %26

22:                                               ; preds = %16
  %23 = xor i32 %19, %9
  %24 = load i32, ptr %10, align 4, !tbaa !6
  %25 = add i32 %24, 2
  store i32 %25, ptr %10, align 4, !tbaa !6
  br label %26

26:                                               ; preds = %22, %20
  %27 = phi i32 [ %21, %20 ], [ %23, %22 ]
  %28 = mul i32 %18, 5
  %29 = add i32 %27, %28
  %30 = icmp ugt i32 %19, %2
  br i1 %30, label %16, label %31, !llvm.loop !17

31:                                               ; preds = %26, %5
  %32 = phi i32 [ 1, %5 ], [ %29, %26 ]
  %33 = call i32 @cq_measure_ui32(i32 noundef %32) #4
  %34 = shl i32 %33, 6
  %35 = load i32, ptr %10, align 4, !tbaa !6
  %36 = call i32 @cq_measure_ui32(i32 noundef %35) #4
  %37 = add i32 %36, %34
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  ret i32 %37
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @pd_csub(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %5, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #4
  store i32 0, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8)
  store volatile ptr %7, ptr %8, align 8, !tbaa !10
  %11 = load volatile ptr, ptr %8, align 8, !tbaa !10
  %12 = icmp ugt i32 %9, %2
  br i1 %12, label %13, label %55

13:                                               ; preds = %6
  %14 = and i32 %3, 1
  %15 = icmp eq i32 %14, 0
  %16 = and i32 %4, 3
  %17 = icmp eq i32 %16, 0
  %18 = and i32 %3, 2
  %19 = icmp eq i32 %18, 0
  %20 = and i32 %4, 3
  %21 = icmp eq i32 %20, 0
  %22 = or i1 %15, %17
  br label %23

23:                                               ; preds = %13, %51
  %24 = phi i32 [ %9, %13 ], [ %26, %51 ]
  %25 = phi i32 [ 0, %13 ], [ %53, %51 ]
  %26 = lshr i32 %24, 1
  br i1 %22, label %37, label %27

27:                                               ; preds = %23
  %28 = load i32, ptr %11, align 4, !tbaa !6
  br label %29

29:                                               ; preds = %27, %29
  %30 = phi i32 [ %28, %27 ], [ %33, %29 ]
  %31 = phi i32 [ 0, %27 ], [ %34, %29 ]
  %32 = xor i32 %31, %10
  %33 = add i32 %30, %32
  %34 = add nuw nsw i32 %31, 1
  %35 = icmp eq i32 %34, %16
  br i1 %35, label %36, label %29, !llvm.loop !18

36:                                               ; preds = %29
  store i32 %33, ptr %11, align 4, !tbaa !6
  br label %37

37:                                               ; preds = %23, %36
  %38 = icmp ule i32 %10, %26
  %39 = select i1 %19, i1 true, i1 %38
  %40 = or i1 %39, %21
  br i1 %40, label %51, label %41

41:                                               ; preds = %37
  %42 = load i32, ptr %11, align 4, !tbaa !6
  br label %43

43:                                               ; preds = %41, %43
  %44 = phi i32 [ %42, %41 ], [ %47, %43 ]
  %45 = phi i32 [ 0, %41 ], [ %48, %43 ]
  %46 = add nuw i32 %45, %26
  %47 = xor i32 %44, %46
  %48 = add nuw nsw i32 %45, 1
  %49 = icmp eq i32 %48, %16
  br i1 %49, label %50, label %43, !llvm.loop !19

50:                                               ; preds = %43
  store i32 %47, ptr %11, align 4, !tbaa !6
  br label %51

51:                                               ; preds = %37, %50
  %52 = mul i32 %25, 3
  %53 = add i32 %26, %52
  %54 = icmp ugt i32 %26, %2
  br i1 %54, label %23, label %55, !llvm.loop !20

55:                                               ; preds = %51, %6
  %56 = phi i32 [ 0, %6 ], [ %53, %51 ]
  %57 = call i32 @cq_measure_ui32(i32 noundef %56) #4
  %58 = shl i32 %57, 8
  %59 = load i32, ptr %11, align 4, !tbaa !6
  %60 = call i32 @cq_measure_ui32(i32 noundef %59) #4
  %61 = add i32 %60, %58
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #4
  ret i32 %61
}

; Function Attrs: nounwind ssp uwtable
define i32 @pe_arm(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  br label %5

5:                                                ; preds = %14, %3
  %6 = phi i32 [ 0, %3 ], [ %10, %14 ]
  %7 = phi i32 [ 1, %3 ], [ %9, %14 ]
  %8 = mul nsw i32 %7, 3
  %9 = add nsw i32 %8, %6
  %10 = add nuw nsw i32 %6, 1
  %11 = shl i32 512, %6
  %12 = and i32 %11, %4
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %18

14:                                               ; preds = %5
  %15 = shl i32 2, %6
  %16 = and i32 %15, %4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %31, label %5, !llvm.loop !21

18:                                               ; preds = %5
  %19 = and i32 %2, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %27, label %21

21:                                               ; preds = %18, %21
  %22 = phi i32 [ %26, %21 ], [ %10, %18 ]
  %23 = shl i32 65536, %22
  %24 = and i32 %23, %4
  %25 = icmp eq i32 %24, 0
  %26 = add nuw nsw i32 %22, 1
  br i1 %25, label %27, label %21, !llvm.loop !22

27:                                               ; preds = %21, %18
  %28 = phi i32 [ %10, %18 ], [ %22, %21 ]
  %29 = mul nsw i32 %28, 7
  %30 = add nsw i32 %29, %9
  br label %31

31:                                               ; preds = %14, %27
  %32 = phi i32 [ %30, %27 ], [ %9, %14 ]
  %33 = tail call i32 @cq_measure_si32(i32 noundef %32) #4
  ret i32 %33
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}
!21 = distinct !{!21, !13, !14}
!22 = distinct !{!22, !13, !14}
