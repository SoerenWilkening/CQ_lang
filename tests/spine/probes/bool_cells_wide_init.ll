; cq-vq86: CR rule 20. A _Bool slot object initialised by one wide constant store (120's bool q[2][2] = {0}:
; store i32 0) is still _Bool cells (every byte 0 or 1): the cq_theta result's zext i1 -> i8 is the cell's
; view of the i1 rail, never a zext template (mem-slots stopped on it). From 120's register_grid.
source_filename = "multidim_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @register_grid(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = alloca [2 x [2 x i8]], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #3
  store i32 0, ptr %4, align 4
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %12

6:                                                ; preds = %3
  %7 = zext nneg i32 %1 to i64
  br label %8

8:                                                ; preds = %16, %6
  %9 = phi i64 [ 0, %6 ], [ %17, %16 ]
  %10 = shl nsw i64 %9, 4
  %11 = getelementptr inbounds i8, ptr %0, i64 %10
  br label %19

12:                                               ; preds = %16, %3
  %13 = icmp sgt i32 %1, 0
  br i1 %13, label %14, label %30

14:                                               ; preds = %12
  %15 = zext nneg i32 %1 to i64
  br label %34

16:                                               ; preds = %19
  %17 = add nuw nsw i64 %9, 1
  %18 = icmp eq i64 %17, %7
  br i1 %18, label %12, label %8, !llvm.loop !6

19:                                               ; preds = %19, %8
  %20 = phi i64 [ 0, %8 ], [ %28, %19 ]
  %21 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %9, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !9, !range !13, !noundef !14
  %23 = trunc nuw i8 %22 to i1
  %24 = getelementptr inbounds double, ptr %11, i64 %20
  %25 = load double, ptr %24, align 8, !tbaa !15
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef %25) #4
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %21, align 1, !tbaa !9
  %28 = add nuw nsw i64 %20, 1
  %29 = icmp eq i64 %20, 0
  br i1 %29, label %19, label %16, !llvm.loop !17

30:                                               ; preds = %45, %12
  %31 = getelementptr inbounds i8, ptr %4, i64 1
  %32 = load i8, ptr %31, align 1, !tbaa !9, !range !13, !noundef !14
  %33 = trunc nuw i8 %32 to i1
  br i1 %33, label %48, label %56

34:                                               ; preds = %45, %14
  %35 = phi i64 [ 0, %14 ], [ %46, %45 ]
  %36 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %35
  %37 = load i8, ptr %36, align 2, !tbaa !9, !range !13, !noundef !14
  %38 = trunc nuw i8 %37 to i1
  br i1 %38, label %39, label %45

39:                                               ; preds = %34
  %40 = getelementptr inbounds i8, ptr %36, i64 1
  %41 = load i8, ptr %40, align 1, !tbaa !9, !range !13, !noundef !14
  %42 = trunc nuw i8 %41 to i1
  %43 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %42, double noundef %2) #4
  %44 = zext i1 %43 to i8
  store i8 %44, ptr %40, align 1, !tbaa !9
  br label %45

45:                                               ; preds = %39, %34
  %46 = add nuw nsw i64 %35, 1
  %47 = icmp eq i64 %46, %15
  br i1 %47, label %30, label %34, !llvm.loop !18

48:                                               ; preds = %30
  %49 = add nsw i32 %1, -1
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %50, i64 1
  %52 = load i8, ptr %51, align 1, !tbaa !9, !range !13, !noundef !14
  %53 = trunc nuw i8 %52 to i1
  %54 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %53, double noundef %2) #4
  %55 = zext i1 %54 to i8
  store i8 %55, ptr %51, align 1, !tbaa !9
  br label %56

56:                                               ; preds = %48, %30
  %57 = load i8, ptr %31, align 1, !tbaa !9, !range !13, !noundef !14
  %58 = trunc nuw i8 %57 to i1
  %59 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %58) #3
  %60 = zext i1 %59 to i32
  %61 = add nsw i32 %1, -1
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %62, i64 1
  %64 = load i8, ptr %63, align 1, !tbaa !9, !range !13, !noundef !14
  %65 = trunc nuw i8 %64 to i1
  %66 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %65) #3
  %67 = zext i1 %66 to i32
  %68 = add nuw nsw i32 %67, %60
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #3
  ret i32 %68
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"_Bool", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = !{!16, !16, i64 0}
!16 = !{!"double", !11, i64 0}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
; CHECK-COUNT register_grid: @cq_template_zext_i1_to_i8( 0
; CHECK register_grid: call void @cqrt_ry_i1_controlled(
