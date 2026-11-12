; ModuleID = 'knest_cbr.c'
source_filename = "knest_cbr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @kc_reg(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !10
  %9 = load volatile ptr, ptr %7, align 8, !tbaa !10
  %10 = and i32 %4, 3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp eq i32 %13, 0
  br label %22

15:                                               ; preds = %35, %5
  %16 = phi i32 [ 0, %5 ], [ %38, %35 ]
  %17 = call i32 @cq_measure_ui32(i32 noundef %16) #4
  %18 = shl i32 %17, 8
  %19 = load i32, ptr %9, align 4, !tbaa !6
  %20 = call i32 @cq_measure_ui32(i32 noundef %19) #4
  %21 = add i32 %20, %18
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  ret i32 %21

22:                                               ; preds = %12, %35
  %23 = phi i32 [ 0, %12 ], [ %39, %35 ]
  %24 = phi i32 [ 0, %12 ], [ %38, %35 ]
  %25 = add i32 %23, %8
  %26 = icmp ugt i32 %25, %2
  br i1 %26, label %27, label %35

27:                                               ; preds = %22, %33
  %28 = phi i32 [ %29, %33 ], [ %25, %22 ]
  %29 = lshr i32 %28, 1
  br i1 %14, label %33, label %30

30:                                               ; preds = %27
  %31 = load i32, ptr %9, align 4, !tbaa !6
  %32 = xor i32 %31, %29
  store i32 %32, ptr %9, align 4, !tbaa !6
  br label %33

33:                                               ; preds = %30, %27
  %34 = icmp ugt i32 %29, %2
  br i1 %34, label %27, label %35, !llvm.loop !12

35:                                               ; preds = %33, %22
  %36 = phi i32 [ %25, %22 ], [ %29, %33 ]
  %37 = mul i32 %24, 3
  %38 = add i32 %36, %37
  %39 = add nuw nsw i32 %23, 1
  %40 = icmp eq i32 %39, %10
  br i1 %40, label %15, label %22, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @kc_sel(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #4
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !10
  %9 = load volatile ptr, ptr %7, align 8, !tbaa !10
  %10 = and i32 %4, 3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp eq i32 %13, 0
  br label %21

15:                                               ; preds = %33, %5
  %16 = call i32 @cq_measure_ui32(i32 noundef 0) #4
  %17 = shl i32 %16, 8
  %18 = load i32, ptr %9, align 4, !tbaa !6
  %19 = call i32 @cq_measure_ui32(i32 noundef %18) #4
  %20 = add i32 %19, %17
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #4
  ret i32 %20

21:                                               ; preds = %12, %33
  %22 = phi i32 [ 0, %12 ], [ %34, %33 ]
  %23 = add i32 %22, %8
  %24 = icmp ugt i32 %23, %2
  br i1 %24, label %25, label %33

25:                                               ; preds = %21, %31
  %26 = phi i32 [ %27, %31 ], [ %23, %21 ]
  %27 = lshr i32 %26, 1
  br i1 %14, label %31, label %28

28:                                               ; preds = %25
  %29 = load i32, ptr %9, align 4, !tbaa !6
  %30 = xor i32 %29, %27
  store i32 %30, ptr %9, align 4, !tbaa !6
  br label %31

31:                                               ; preds = %28, %25
  %32 = icmp ugt i32 %27, %2
  br i1 %32, label %25, label %33, !llvm.loop !16

33:                                               ; preds = %31, %21
  %34 = add nuw nsw i32 %22, 1
  %35 = icmp eq i32 %34, %10
  br i1 %35, label %15, label %21, !llvm.loop !17
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
!17 = distinct !{!17, !13, !14}
