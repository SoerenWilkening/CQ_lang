; ModuleID = 'multi_exit.c'
source_filename = "multi_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @me_cmp(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca [3 x i8], align 1
  %8 = alloca [3 x i8], align 1
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %10 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #4
  %11 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %4, double noundef %5) #4
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %7) #5
  store i8 %10, ptr %7, align 1, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %7, i64 1
  store i8 %11, ptr %12, align 1, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %7, i64 2
  store i8 %11, ptr %13, align 1, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %8) #5
  store i8 %10, ptr %8, align 1, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %8, i64 1
  store i8 %10, ptr %14, align 1, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %8, i64 2
  store i8 %11, ptr %15, align 1, !tbaa !6
  %16 = and i32 %9, 3
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %36, label %18

18:                                               ; preds = %6
  %19 = zext nneg i32 %16 to i64
  br label %20

20:                                               ; preds = %18, %27
  %21 = phi i64 [ %28, %27 ], [ %19, %18 ]
  %22 = phi ptr [ %30, %27 ], [ %8, %18 ]
  %23 = phi ptr [ %29, %27 ], [ %7, %18 ]
  %24 = load i8, ptr %23, align 1, !tbaa !6
  %25 = load i8, ptr %22, align 1, !tbaa !6
  %26 = icmp eq i8 %24, %25
  br i1 %26, label %27, label %32

27:                                               ; preds = %20
  %28 = add nsw i64 %21, -1
  %29 = getelementptr inbounds i8, ptr %23, i64 1
  %30 = getelementptr inbounds i8, ptr %22, i64 1
  %31 = icmp eq i64 %28, 0
  br i1 %31, label %36, label %20, !llvm.loop !9

32:                                               ; preds = %20
  %33 = zext i8 %24 to i32
  %34 = zext i8 %25 to i32
  %35 = sub nsw i32 %33, %34
  br label %36

36:                                               ; preds = %27, %6, %32
  %37 = phi i32 [ %35, %32 ], [ 0, %6 ], [ 0, %27 ]
  %38 = tail call i32 @cq_measure_si32(i32 noundef %37) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %8) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %7) #5
  ret i32 %38
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define range(i32 -255, 256) i32 @me_cmpfn(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, i64 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i64 %2, 0
  br i1 %4, label %21, label %5

5:                                                ; preds = %3, %12
  %6 = phi i64 [ %13, %12 ], [ %2, %3 ]
  %7 = phi ptr [ %15, %12 ], [ %1, %3 ]
  %8 = phi ptr [ %14, %12 ], [ %0, %3 ]
  %9 = load i8, ptr %8, align 1, !tbaa !6
  %10 = load i8, ptr %7, align 1, !tbaa !6
  %11 = icmp eq i8 %9, %10
  br i1 %11, label %12, label %17

12:                                               ; preds = %5
  %13 = add i64 %6, -1
  %14 = getelementptr inbounds i8, ptr %8, i64 1
  %15 = getelementptr inbounds i8, ptr %7, i64 1
  %16 = icmp eq i64 %13, 0
  br i1 %16, label %21, label %5, !llvm.loop !12

17:                                               ; preds = %5
  %18 = zext i8 %9 to i32
  %19 = zext i8 %10 to i32
  %20 = sub nsw i32 %18, %19
  br label %21

21:                                               ; preds = %12, %3, %17
  %22 = phi i32 [ %20, %17 ], [ 0, %3 ], [ 0, %12 ]
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @me_clone(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca [3 x i8], align 1
  %8 = alloca [3 x i8], align 1
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %10 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #4
  %11 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %4, double noundef %5) #4
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %7) #5
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %7, i64 1
  store i8 %10, ptr %12, align 1, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %7, i64 2
  store i8 %10, ptr %13, align 1, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %8) #5
  store i8 %11, ptr %8, align 1, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %8, i64 1
  store i8 %10, ptr %14, align 1, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %8, i64 2
  store i8 %11, ptr %15, align 1, !tbaa !6
  %16 = and i32 %9, 3
  %17 = zext nneg i32 %16 to i64
  %18 = call i32 @me_cmpfn(ptr noundef nonnull %7, ptr noundef nonnull %8, i64 noundef %17)
  %19 = ashr i32 %18, 31
  %20 = icmp ne i32 %18, 0
  %21 = zext i1 %20 to i32
  %22 = or i32 %19, %21
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %8) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %7) #5
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i32 @me_walk(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #5
  store i8 %4, ptr %3, align 1, !tbaa !6
  %5 = and i8 %4, 1
  %6 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 %5, ptr %6, align 1, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 0, ptr %7, align 1, !tbaa !6
  %8 = icmp eq i8 %4, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %12, %2
  %10 = phi i32 [ 0, %2 ], [ %15, %12 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #5
  ret i32 %11

12:                                               ; preds = %2, %12
  %13 = phi ptr [ %16, %12 ], [ %3, %2 ]
  %14 = phi i32 [ %15, %12 ], [ 0, %2 ]
  %15 = add nuw nsw i32 %14, 2
  %16 = getelementptr inbounds i8, ptr %13, i64 1
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = icmp eq i8 %17, 0
  br i1 %18, label %9, label %12, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @me_dead(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %22, %3
  %7 = phi i32 [ 2, %3 ], [ %23, %22 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  ret i32 %8

9:                                                ; preds = %3, %22
  %10 = phi i32 [ %24, %22 ], [ 0, %3 ]
  %11 = phi i32 [ %23, %22 ], [ 2, %3 ]
  %12 = shl nuw nsw i32 %10, 1
  %13 = ashr i32 %4, %12
  %14 = and i32 %13, 3
  switch i32 %14, label %21 [
    i32 0, label %15
    i32 1, label %17
    i32 2, label %19
    i32 3, label %22
  ]

15:                                               ; preds = %9
  %16 = add nsw i32 %11, 1
  br label %22

17:                                               ; preds = %9
  %18 = sub nsw i32 %11, %10
  br label %22

19:                                               ; preds = %9
  %20 = xor i32 %11, 6
  br label %22

21:                                               ; preds = %9
  unreachable

22:                                               ; preds = %15, %17, %19, %9
  %23 = phi i32 [ %11, %9 ], [ %20, %19 ], [ %18, %17 ], [ %16, %15 ]
  %24 = add nuw nsw i32 %10, 1
  %25 = icmp eq i32 %24, %2
  br i1 %25, label %6, label %9, !llvm.loop !14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @me_c3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = and i32 %2, 7
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %15, label %7

7:                                                ; preds = %3, %12
  %8 = phi i32 [ %13, %12 ], [ 0, %3 ]
  %9 = shl nuw i32 1, %8
  %10 = and i32 %9, %4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %15, label %12

12:                                               ; preds = %7
  %13 = add nuw nsw i32 %8, 1
  %14 = icmp eq i32 %13, %5
  br i1 %14, label %15, label %7, !llvm.loop !15

15:                                               ; preds = %7, %12, %3
  %16 = phi i32 [ 0, %3 ], [ %8, %7 ], [ %5, %12 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @me_join4(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = and i32 %3, 7
  %5 = lshr i32 %3, 3
  %6 = and i32 %5, 3
  %7 = and i32 %3, 32
  %8 = icmp eq i32 %7, 0
  %9 = icmp ugt i32 %4, 1
  br i1 %8, label %18, label %10

10:                                               ; preds = %2
  br i1 %9, label %11, label %29

11:                                               ; preds = %10, %11
  %12 = phi i32 [ %15, %11 ], [ 1, %10 ]
  %13 = phi i32 [ %16, %11 ], [ %4, %10 ]
  %14 = mul i32 %12, 3
  %15 = add i32 %14, %6
  %16 = add i32 %13, -1
  %17 = icmp ugt i32 %16, 1
  br i1 %17, label %11, label %29, !llvm.loop !16

18:                                               ; preds = %2
  br i1 %9, label %19, label %29

19:                                               ; preds = %18, %19
  %20 = phi i32 [ %26, %19 ], [ %6, %18 ]
  %21 = phi i32 [ %27, %19 ], [ %4, %18 ]
  %22 = mul i32 %20, 5
  %23 = add i32 %22, 1
  %24 = icmp ugt i32 %23, 40
  %25 = add i32 %22, -6
  %26 = select i1 %24, i32 %25, i32 %23
  %27 = add nsw i32 %21, -1
  %28 = icmp ugt i32 %27, 1
  br i1 %28, label %19, label %29, !llvm.loop !17

29:                                               ; preds = %11, %19, %18, %10
  %30 = phi i32 [ 5, %10 ], [ 9, %18 ], [ %20, %19 ], [ %12, %11 ]
  %31 = tail call i32 @cq_measure_ui32(i32 noundef %30) #5
  ret i32 %31
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @me_join5(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = lshr i32 %3, 3
  %5 = and i32 %4, 3
  %6 = and i32 %3, 32
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %21, label %8

8:                                                ; preds = %2
  %9 = and i32 %3, 7
  %10 = icmp ugt i32 %9, 1
  br i1 %10, label %11, label %18

11:                                               ; preds = %8, %11
  %12 = phi i32 [ %15, %11 ], [ 1, %8 ]
  %13 = phi i32 [ %16, %11 ], [ %9, %8 ]
  %14 = mul i32 %12, 3
  %15 = add i32 %14, %5
  %16 = add i32 %13, -1
  %17 = icmp ugt i32 %16, 1
  br i1 %17, label %11, label %24, !llvm.loop !18

18:                                               ; preds = %8
  %19 = mul nuw nsw i32 %5, 7
  %20 = add nuw nsw i32 %19, 1
  br label %24

21:                                               ; preds = %2
  %22 = mul nuw nsw i32 %5, 11
  %23 = add nuw nsw i32 %22, 1
  br label %24

24:                                               ; preds = %11, %18, %21
  %25 = phi i32 [ %20, %18 ], [ %23, %21 ], [ %12, %11 ]
  %26 = tail call i32 @cq_measure_ui32(i32 noundef %25) #5
  ret i32 %26
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
!13 = distinct !{!13, !10, !11}
!14 = distinct !{!14, !10, !11}
!15 = distinct !{!15, !10, !11}
!16 = distinct !{!16, !10, !11}
!17 = distinct !{!17, !10, !11}
!18 = distinct !{!18, !10, !11}
