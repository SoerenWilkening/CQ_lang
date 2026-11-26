; ModuleID = 'fall_exit.c'
source_filename = "fall_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Op = type { i32, i32, i32 }

@__const.fe_fall.reg = private unnamed_addr constant [4 x i32] [i32 1, i32 0, i32 2, i32 0], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @fe_fall(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = alloca [8 x %struct.Op], align 16
  %3 = alloca [4 x i32], align 16
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 96, ptr nonnull %2) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, ptr noundef nonnull align 16 dereferenceable(16) @__const.fe_fall.reg, i64 16, i1 false)
  %5 = zext i8 %4 to i32
  br label %11

6:                                                ; preds = %11
  %7 = urem i8 %0, 9
  %8 = icmp eq i8 %7, 0
  br i1 %8, label %58, label %9

9:                                                ; preds = %6
  %10 = zext nneg i8 %7 to i64
  br label %25

11:                                               ; preds = %1, %11
  %12 = phi i64 [ 0, %1 ], [ %20, %11 ]
  %13 = trunc nuw nsw i64 %12 to i32
  %14 = lshr i32 %5, %13
  %15 = and i32 %14, 1
  %16 = getelementptr inbounds [8 x %struct.Op], ptr %2, i64 0, i64 %12
  store i32 %15, ptr %16, align 4, !tbaa !6
  %17 = trunc nuw nsw i64 %12 to i32
  %18 = and i32 %17, 3
  %19 = getelementptr inbounds i8, ptr %16, i64 4
  store i32 %18, ptr %19, align 4, !tbaa !11
  %20 = add nuw nsw i64 %12, 1
  %21 = trunc nuw nsw i64 %20 to i32
  %22 = and i32 %21, 3
  %23 = getelementptr inbounds i8, ptr %16, i64 8
  store i32 %22, ptr %23, align 4, !tbaa !12
  %24 = icmp eq i64 %20, 8
  br i1 %24, label %6, label %11, !llvm.loop !13

25:                                               ; preds = %9, %55
  %26 = phi i64 [ 0, %9 ], [ %56, %55 ]
  %27 = getelementptr inbounds [8 x %struct.Op], ptr %2, i64 0, i64 %26
  %28 = load i32, ptr %27, align 4, !tbaa !6
  switch i32 %28, label %58 [
    i32 0, label %29
    i32 1, label %42
  ]

29:                                               ; preds = %25
  %30 = getelementptr inbounds i8, ptr %27, i64 8
  %31 = load i32, ptr %30, align 4, !tbaa !12
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %32
  %34 = load i32, ptr %33, align 4, !tbaa !16
  %35 = add nsw i32 %34, 3
  store i32 %35, ptr %33, align 4, !tbaa !16
  %36 = getelementptr inbounds i8, ptr %27, i64 4
  %37 = load i32, ptr %36, align 4, !tbaa !11
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %38
  %40 = load i32, ptr %39, align 4, !tbaa !16
  %41 = icmp sgt i32 %40, 0
  br i1 %41, label %55, label %42

42:                                               ; preds = %29, %25
  %43 = getelementptr inbounds i8, ptr %27, i64 8
  %44 = load i32, ptr %43, align 4, !tbaa !12
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %45
  %47 = load i32, ptr %46, align 4, !tbaa !16
  %48 = add nsw i32 %47, 4
  store i32 %48, ptr %46, align 4, !tbaa !16
  %49 = getelementptr inbounds i8, ptr %27, i64 4
  %50 = load i32, ptr %49, align 4, !tbaa !11
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %51
  %53 = load i32, ptr %52, align 4, !tbaa !16
  %54 = icmp sgt i32 %53, 1
  br i1 %54, label %55, label %58

55:                                               ; preds = %29, %42
  %56 = add nuw nsw i64 %26, 1
  %57 = icmp ult i64 %56, %10
  br i1 %57, label %25, label %58, !llvm.loop !17

58:                                               ; preds = %55, %42, %25, %6
  %59 = phi i32 [ 0, %6 ], [ 0, %55 ], [ -1, %42 ], [ -1, %25 ]
  %60 = phi i32 [ 5, %6 ], [ 5, %55 ], [ 9, %42 ], [ 9, %25 ]
  switch i32 %60, label %73 [
    i32 5, label %61
    i32 9, label %61
  ]

61:                                               ; preds = %58, %58
  %62 = load i32, ptr %3, align 16, !tbaa !16
  %63 = add nsw i32 %62, %59
  %64 = getelementptr inbounds i8, ptr %3, i64 4
  %65 = load i32, ptr %64, align 4, !tbaa !16
  %66 = shl nsw i32 %65, 6
  %67 = add nsw i32 %63, %66
  %68 = getelementptr inbounds i8, ptr %3, i64 8
  %69 = load i32, ptr %68, align 8, !tbaa !16
  %70 = shl nsw i32 %69, 12
  %71 = add nsw i32 %67, %70
  %72 = tail call i32 @cq_measure_si32(i32 noundef %71) #5
  br label %73

73:                                               ; preds = %61, %58
  %74 = phi i32 [ undef, %58 ], [ %72, %61 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.lifetime.end.p0(i64 96, ptr nonnull %2) #5
  ret i32 %74
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!6 = !{!7, !8, i64 0}
!7 = !{!"Op", !8, i64 0, !8, i64 4, !8, i64 8}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
!12 = !{!7, !8, i64 8}
!13 = distinct !{!13, !14, !15}
!14 = !{!"llvm.loop.mustprogress"}
!15 = !{!"llvm.loop.unroll.disable"}
!16 = !{!8, !8, i64 0}
!17 = distinct !{!17, !14, !15}
