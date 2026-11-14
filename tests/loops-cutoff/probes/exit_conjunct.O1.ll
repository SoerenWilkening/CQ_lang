; ModuleID = 'exit_conjunct.c'
source_filename = "exit_conjunct.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ec_while(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #4
  store i32 0, ptr %5, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  store volatile ptr %5, ptr %6, align 8, !tbaa !10
  %8 = load volatile ptr, ptr %6, align 8, !tbaa !10
  %9 = and i32 %3, 1
  %10 = icmp ne i32 %9, 0
  %11 = icmp ugt i32 %7, %2
  %12 = select i1 %10, i1 %11, i1 false
  br i1 %12, label %13, label %25

13:                                               ; preds = %4
  %14 = load i32, ptr %8, align 4, !tbaa !6
  br label %15

15:                                               ; preds = %13, %15
  %16 = phi i32 [ %14, %13 ], [ %21, %15 ]
  %17 = phi i32 [ %7, %13 ], [ %19, %15 ]
  %18 = phi i32 [ 0, %13 ], [ %20, %15 ]
  %19 = lshr i32 %17, 1
  %20 = add i32 %18, 3
  %21 = add i32 %16, %20
  %22 = icmp ugt i32 %19, %2
  %23 = select i1 %10, i1 %22, i1 false
  br i1 %23, label %15, label %24, !llvm.loop !12

24:                                               ; preds = %15
  store i32 %21, ptr %8, align 4, !tbaa !6
  br label %25

25:                                               ; preds = %24, %4
  %26 = phi i32 [ %20, %24 ], [ 0, %4 ]
  %27 = phi i32 [ %19, %24 ], [ %7, %4 ]
  %28 = call i32 @cq_measure_ui32(i32 noundef %27) #4
  %29 = shl i32 %28, 8
  %30 = call i32 @cq_measure_ui32(i32 noundef %26) #4
  %31 = shl i32 %30, 4
  %32 = add i32 %31, %29
  %33 = load i32, ptr %8, align 4, !tbaa !6
  %34 = call i32 @cq_measure_ui32(i32 noundef %33) #4
  %35 = add i32 %32, %34
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #4
  ret i32 %35
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @ec_do(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 0, ptr %4, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  store volatile ptr %4, ptr %5, align 8, !tbaa !10
  %7 = load volatile ptr, ptr %5, align 8, !tbaa !10
  %8 = load i32, ptr %7, align 4, !tbaa !6
  br label %9

9:                                                ; preds = %9, %3
  %10 = phi i32 [ %8, %3 ], [ %17, %9 ]
  %11 = phi i32 [ 0, %3 ], [ %18, %9 ]
  %12 = phi i32 [ 1, %3 ], [ %15, %9 ]
  %13 = phi i32 [ %6, %3 ], [ %16, %9 ]
  %14 = mul i32 %12, 3
  %15 = add i32 %14, %13
  %16 = lshr i32 %13, 1
  %17 = xor i32 %10, %15
  %18 = add i32 %11, 1
  %19 = shl nuw i32 1, %18
  %20 = and i32 %19, %2
  %21 = icmp ne i32 %20, 0
  %22 = and i32 %13, 2
  %23 = icmp ne i32 %22, 0
  %24 = select i1 %21, i1 %23, i1 false
  br i1 %24, label %9, label %25, !llvm.loop !15

25:                                               ; preds = %9
  store i32 %17, ptr %7, align 4, !tbaa !6
  %26 = call i32 @cq_measure_ui32(i32 noundef %15) #4
  %27 = shl i32 %26, 8
  %28 = load i32, ptr %7, align 4, !tbaa !6
  %29 = call i32 @cq_measure_ui32(i32 noundef %28) #4
  %30 = add i32 %29, %27
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %30
}

; Function Attrs: nounwind ssp uwtable
define i32 @ec_vary(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %2, 1
  %6 = icmp ne i32 %5, 0
  %7 = icmp ugt i32 %4, 2
  %8 = select i1 %6, i1 %7, i1 false
  br i1 %8, label %9, label %22

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %16, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %15, %9 ], [ 0, %3 ]
  %12 = phi i32 [ %13, %9 ], [ %4, %3 ]
  %13 = add i32 %12, -3
  %14 = mul i32 %11, 5
  %15 = add i32 %14, %10
  %16 = add nuw nsw i32 %10, 1
  %17 = shl nuw i32 2, %10
  %18 = and i32 %17, %2
  %19 = icmp ne i32 %18, 0
  %20 = icmp ugt i32 %13, 2
  %21 = select i1 %19, i1 %20, i1 false
  br i1 %21, label %9, label %22, !llvm.loop !16

22:                                               ; preds = %9, %3
  %23 = phi i32 [ %4, %3 ], [ %13, %9 ]
  %24 = phi i32 [ 0, %3 ], [ %15, %9 ]
  %25 = tail call i32 @cq_measure_ui32(i32 noundef %23) #4
  %26 = shl i32 %25, 6
  %27 = tail call i32 @cq_measure_ui32(i32 noundef %24) #4
  %28 = add i32 %26, %27
  ret i32 %28
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
