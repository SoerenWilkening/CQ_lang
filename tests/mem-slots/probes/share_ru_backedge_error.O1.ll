; ModuleID = 'share_ru_backedge_error.c'
source_filename = "share_ru_backedge_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @share_ru_backedge(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #3
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #4
  %6 = and i32 %0, 3
  store i32 %5, ptr %3, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 0, ptr %7, align 4, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 1, ptr %8, align 8, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 0, ptr %9, align 4, !tbaa !6
  %10 = icmp eq i32 %6, 0
  %11 = zext nneg i32 %6 to i64
  br label %12

12:                                               ; preds = %2, %24
  %13 = phi i64 [ 0, %2 ], [ %27, %24 ]
  br i1 %10, label %24, label %29

14:                                               ; preds = %24
  %15 = and i32 %1, 1
  %16 = load i32, ptr %3, align 16, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %18 = zext nneg i32 %15 to i64
  %19 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = shl nsw i32 %21, 1
  %23 = add nsw i32 %22, %17
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #3
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #3
  ret i32 %23

24:                                               ; preds = %29, %12
  %25 = load i32, ptr %3, align 16, !tbaa !6
  %26 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %13
  store i32 %25, ptr %26, align 4, !tbaa !6
  %27 = add nuw nsw i64 %13, 1
  %28 = icmp eq i64 %13, 0
  br i1 %28, label %12, label %14, !llvm.loop !10

29:                                               ; preds = %12, %29
  %30 = phi i64 [ %31, %29 ], [ 0, %12 ]
  %31 = add nuw nsw i64 %30, 1
  %32 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %31
  %33 = load i32, ptr %32, align 4, !tbaa !6
  %34 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %30
  %35 = load i32, ptr %34, align 4, !tbaa !6
  %36 = xor i32 %35, %33
  store i32 %36, ptr %34, align 4, !tbaa !6
  %37 = icmp eq i64 %31, %11
  br i1 %37, label %24, label %29, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
; EXPECT-ERROR: may run again after the store and free that rail (cq-zgw3)
