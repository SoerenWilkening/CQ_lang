; ModuleID = 'arm_once.c'
source_filename = "arm_once.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.sink = type { ptr, i32, ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @ao_write(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  %4 = alloca [8 x i8], align 8
  %5 = alloca %struct.sink, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  store i32 1684234849, ptr %3, align 4
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #6
  %7 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 %6, ptr %7, align 1, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5
  store i64 0, ptr %4, align 8
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #5
  store ptr %4, ptr %5, align 8, !tbaa !9
  %8 = getelementptr inbounds i8, ptr %5, i64 8
  store i32 0, ptr %8, align 8, !tbaa !13
  %9 = getelementptr inbounds i8, ptr %5, i64 16
  store ptr @sink_write, ptr %9, align 8, !tbaa !14
  %10 = call fastcc i32 @fwritex(ptr noundef nonnull %3, ptr noundef nonnull %5)
  %11 = load i32, ptr %8, align 8, !tbaa !13
  %12 = shl nsw i32 %11, 4
  %13 = add nsw i32 %12, %10
  %14 = load i8, ptr %4, align 8, !tbaa !6
  %15 = zext i8 %14 to i32
  %16 = getelementptr inbounds i8, ptr %4, i64 1
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = zext i8 %17 to i32
  %19 = add nuw nsw i32 %18, %15
  %20 = getelementptr inbounds i8, ptr %4, i64 2
  %21 = load i8, ptr %20, align 2, !tbaa !6
  %22 = zext i8 %21 to i32
  %23 = add nuw nsw i32 %19, %22
  %24 = getelementptr inbounds i8, ptr %4, i64 3
  %25 = load i8, ptr %24, align 1, !tbaa !6
  %26 = zext i8 %25 to i32
  %27 = add nuw nsw i32 %23, %26
  %28 = shl nuw nsw i32 %27, 6
  %29 = add nsw i32 %13, %28
  %30 = call i32 @cq_measure_si32(i32 noundef %29) #5
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  ret i32 %30
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable
define internal noundef i32 @sink_write(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i32 noundef returned %2) #3 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  br label %14

7:                                                ; preds = %14, %3
  %8 = load ptr, ptr %0, align 8, !tbaa !9
  %9 = sext i32 %2 to i64
  %10 = getelementptr inbounds i8, ptr %8, i64 %9
  store ptr %10, ptr %0, align 8, !tbaa !9
  %11 = getelementptr inbounds i8, ptr %0, i64 8
  %12 = load i32, ptr %11, align 8, !tbaa !13
  %13 = add nsw i32 %12, %2
  store i32 %13, ptr %11, align 8, !tbaa !13
  ret i32 %2

14:                                               ; preds = %5, %14
  %15 = phi i64 [ 0, %5 ], [ %20, %14 ]
  %16 = getelementptr inbounds i8, ptr %1, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = load ptr, ptr %0, align 8, !tbaa !9
  %19 = getelementptr inbounds i8, ptr %18, i64 %15
  store i8 %17, ptr %19, align 1, !tbaa !6
  %20 = add nuw nsw i64 %15, 1
  %21 = icmp eq i64 %20, %6
  br i1 %21, label %7, label %14, !llvm.loop !15
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @fwritex(ptr noundef %0, ptr noundef %1) unnamed_addr #4 {
  br label %3

3:                                                ; preds = %2, %9
  %4 = phi i64 [ 4, %2 ], [ %10, %9 ]
  %5 = getelementptr i8, ptr %0, i64 %4
  %6 = getelementptr i8, ptr %5, i64 -1
  %7 = load i8, ptr %6, align 1, !tbaa !6
  %8 = icmp eq i8 %7, 10
  br i1 %8, label %12, label %9

9:                                                ; preds = %3
  %10 = add nsw i64 %4, -1
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %21, label %3, !llvm.loop !18

12:                                               ; preds = %3
  %13 = trunc nuw nsw i64 %4 to i32
  %14 = getelementptr inbounds i8, ptr %1, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !14
  %16 = tail call i32 %15(ptr noundef %1, ptr noundef %0, i32 noundef %13) #5
  %17 = icmp slt i32 %16, %13
  %18 = sub nsw i32 4, %13
  %19 = select i1 %17, i32 4, i32 %18
  %20 = select i1 %17, ptr %0, ptr %5
  br i1 %17, label %41, label %21

21:                                               ; preds = %9, %12
  %22 = phi i32 [ %13, %12 ], [ 0, %9 ]
  %23 = phi i32 [ %19, %12 ], [ 4, %9 ]
  %24 = phi ptr [ %20, %12 ], [ %0, %9 ]
  %25 = icmp sgt i32 %23, 0
  br i1 %25, label %26, label %28

26:                                               ; preds = %21
  %27 = zext nneg i32 %23 to i64
  br label %33

28:                                               ; preds = %33, %21
  %29 = load ptr, ptr %1, align 8, !tbaa !9
  %30 = sext i32 %23 to i64
  %31 = getelementptr inbounds i8, ptr %29, i64 %30
  store ptr %31, ptr %1, align 8, !tbaa !9
  %32 = add nsw i32 %23, %22
  br label %41

33:                                               ; preds = %26, %33
  %34 = phi i64 [ 0, %26 ], [ %39, %33 ]
  %35 = getelementptr inbounds i8, ptr %24, i64 %34
  %36 = load i8, ptr %35, align 1, !tbaa !6
  %37 = load ptr, ptr %1, align 8, !tbaa !9
  %38 = getelementptr inbounds i8, ptr %37, i64 %34
  store i8 %36, ptr %38, align 1, !tbaa !6
  %39 = add nuw nsw i64 %34, 1
  %40 = icmp eq i64 %39, %27
  br i1 %40, label %28, label %33, !llvm.loop !19

41:                                               ; preds = %12, %28
  %42 = phi i32 [ %32, %28 ], [ %16, %12 ]
  ret i32 %42
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
!9 = !{!10, !11, i64 0}
!10 = !{!"sink", !11, i64 0, !12, i64 8, !11, i64 16}
!11 = !{!"any pointer", !7, i64 0}
!12 = !{!"int", !7, i64 0}
!13 = !{!10, !12, i64 8}
!14 = !{!10, !11, i64 16}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = distinct !{!18, !16, !17}
!19 = distinct !{!19, !16, !17}
