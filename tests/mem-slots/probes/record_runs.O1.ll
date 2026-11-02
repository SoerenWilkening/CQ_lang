; ModuleID = 'record_runs.c'
source_filename = "record_runs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, [4 x i32] }
%struct.P = type { i32, [2 x i32] }

; Function Attrs: nounwind ssp uwtable
define i32 @rec_rt(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.S, align 4
  call void @llvm.lifetime.start.p0(i64 20, ptr nonnull %4) #3
  store i32 3, ptr %4, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %4, i64 4
  br label %21

6:                                                ; preds = %21
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #4
  %8 = getelementptr inbounds i8, ptr %4, i64 4
  %9 = and i32 %0, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x i32], ptr %8, i64 0, i64 %10
  store i32 %7, ptr %11, align 4, !tbaa !11
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %13 = add nsw i32 %0, 1
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i32], ptr %8, i64 0, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !11
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %19 = add i32 %12, 3
  %20 = add i32 %19, %18
  call void @llvm.lifetime.end.p0(i64 20, ptr nonnull %4) #3
  ret i32 %20

21:                                               ; preds = %3, %21
  %22 = phi i64 [ 0, %3 ], [ %25, %21 ]
  %23 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %22
  %24 = trunc nuw nsw i64 %22 to i32
  store i32 %24, ptr %23, align 4, !tbaa !11
  %25 = add nuw nsw i64 %22, 1
  %26 = icmp eq i64 %25, 4
  br i1 %26, label %6, label %21, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @aos_nested(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [3 x %struct.P], align 16
  call void @llvm.lifetime.start.p0(i64 36, ptr nonnull %4) #3
  br label %18

5:                                                ; preds = %18
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #4
  %7 = srem i32 %0, 3
  %8 = sext i32 %7 to i64
  %9 = getelementptr inbounds [3 x %struct.P], ptr %4, i64 0, i64 %8, i32 1, i64 1
  store i32 %6, ptr %9, align 4, !tbaa !11
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %11 = add nsw i32 %0, 1
  %12 = srem i32 %11, 3
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds [3 x %struct.P], ptr %4, i64 0, i64 %13
  %15 = load i32, ptr %14, align 4, !tbaa !15
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %17 = add nsw i32 %16, %10
  call void @llvm.lifetime.end.p0(i64 36, ptr nonnull %4) #3
  ret i32 %17

18:                                               ; preds = %3, %18
  %19 = phi i64 [ 0, %3 ], [ %24, %18 ]
  %20 = getelementptr inbounds [3 x %struct.P], ptr %4, i64 0, i64 %19
  %21 = trunc nuw nsw i64 %19 to i32
  store i32 %21, ptr %20, align 4, !tbaa !15
  %22 = getelementptr inbounds i8, ptr %20, i64 4
  store i32 0, ptr %22, align 4, !tbaa !11
  %23 = getelementptr inbounds i8, ptr %20, i64 8
  store i32 1, ptr %23, align 4, !tbaa !11
  %24 = add nuw nsw i64 %19, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %5, label %18, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @rec_rt2(i32 noundef %0, i32 noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.S, align 4
  call void @llvm.lifetime.start.p0(i64 20, ptr nonnull %5) #3
  store i32 %3, ptr %5, align 4, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %5, i64 4
  br label %24

7:                                                ; preds = %24
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #4
  %9 = getelementptr inbounds i8, ptr %5, i64 4
  %10 = and i32 %0, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i32], ptr %9, i64 0, i64 %11
  store i32 %8, ptr %12, align 4, !tbaa !11
  %13 = and i32 %3, 3
  %14 = mul i32 %13, %3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %16 = add nsw i32 %0, 1
  %17 = and i32 %16, 3
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x i32], ptr %9, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !11
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = add i32 %15, %14
  %23 = add i32 %22, %21
  call void @llvm.lifetime.end.p0(i64 20, ptr nonnull %5) #3
  ret i32 %23

24:                                               ; preds = %4, %24
  %25 = phi i64 [ 0, %4 ], [ %28, %24 ]
  %26 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %25
  %27 = trunc nuw nsw i64 %25 to i32
  store i32 %27, ptr %26, align 4, !tbaa !11
  %28 = add nuw nsw i64 %25, 1
  %29 = icmp eq i64 %28, 4
  br i1 %29, label %7, label %24, !llvm.loop !18
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"S", !8, i64 0, !9, i64 4}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!8, !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = !{!16, !8, i64 0}
!16 = !{!"P", !8, i64 0, !9, i64 4}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
; USERCHECK rec_rt
; USERCHECK aos_nested
; USERCHECK rec_rt2
