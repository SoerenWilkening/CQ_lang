; ModuleID = 'multidim_array.c'
source_filename = "multidim_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@GRID = internal unnamed_addr constant [4 x [4 x i32]] [[4 x i32] [i32 3, i32 1, i32 4, i32 1], [4 x i32] [i32 5, i32 9, i32 2, i32 6], [4 x i32] [i32 5, i32 3, i32 5, i32 8], [4 x i32] [i32 9, i32 7, i32 9, i32 3]], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @table_2d(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #3
  %7 = and i32 %5, 3
  %8 = zext nneg i32 %7 to i64
  %9 = and i32 %6, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x [4 x i32]], ptr @GRID, i64 0, i64 %8, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @register_grid(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x [2 x i8]], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 0, ptr %4, align 4
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %12

6:                                                ; preds = %3
  %7 = zext nneg i32 %1 to i64
  br label %8

8:                                                ; preds = %6, %16
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
  br i1 %18, label %12, label %8, !llvm.loop !10

19:                                               ; preds = %8, %19
  %20 = phi i64 [ 0, %8 ], [ %28, %19 ]
  %21 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %9, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !13, !range !15, !noundef !16
  %23 = trunc nuw i8 %22 to i1
  %24 = getelementptr inbounds double, ptr %11, i64 %20
  %25 = load double, ptr %24, align 8, !tbaa !17
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef %25) #3
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %21, align 1, !tbaa !13
  %28 = add nuw nsw i64 %20, 1
  %29 = icmp eq i64 %20, 0
  br i1 %29, label %19, label %16, !llvm.loop !19

30:                                               ; preds = %45, %12
  %31 = getelementptr inbounds i8, ptr %4, i64 1
  %32 = load i8, ptr %31, align 1, !tbaa !13, !range !15, !noundef !16
  %33 = trunc nuw i8 %32 to i1
  br i1 %33, label %48, label %56

34:                                               ; preds = %14, %45
  %35 = phi i64 [ 0, %14 ], [ %46, %45 ]
  %36 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %35
  %37 = load i8, ptr %36, align 2, !tbaa !13, !range !15, !noundef !16
  %38 = trunc nuw i8 %37 to i1
  br i1 %38, label %39, label %45

39:                                               ; preds = %34
  %40 = getelementptr inbounds i8, ptr %36, i64 1
  %41 = load i8, ptr %40, align 1, !tbaa !13, !range !15, !noundef !16
  %42 = trunc nuw i8 %41 to i1
  %43 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %42, double noundef %2) #3
  %44 = zext i1 %43 to i8
  store i8 %44, ptr %40, align 1, !tbaa !13
  br label %45

45:                                               ; preds = %34, %39
  %46 = add nuw nsw i64 %35, 1
  %47 = icmp eq i64 %46, %15
  br i1 %47, label %30, label %34, !llvm.loop !20

48:                                               ; preds = %30
  %49 = add nsw i32 %1, -1
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %50, i64 1
  %52 = load i8, ptr %51, align 1, !tbaa !13, !range !15, !noundef !16
  %53 = trunc nuw i8 %52 to i1
  %54 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %53, double noundef %2) #3
  %55 = zext i1 %54 to i8
  store i8 %55, ptr %51, align 1, !tbaa !13
  br label %56

56:                                               ; preds = %48, %30
  %57 = load i8, ptr %31, align 1, !tbaa !13, !range !15, !noundef !16
  %58 = trunc nuw i8 %57 to i1
  %59 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %58) #4
  %60 = zext i1 %59 to i32
  %61 = add nsw i32 %1, -1
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds [2 x [2 x i8]], ptr %4, i64 0, i64 %62, i64 1
  %64 = load i8, ptr %63, align 1, !tbaa !13, !range !15, !noundef !16
  %65 = trunc nuw i8 %64 to i1
  %66 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %65) #4
  %67 = zext i1 %66 to i32
  %68 = add nuw nsw i32 %67, %60
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %68
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
!13 = !{!14, !14, i64 0}
!14 = !{!"_Bool", !8, i64 0}
!15 = !{i8 0, i8 2}
!16 = !{}
!17 = !{!18, !18, i64 0}
!18 = !{!"double", !8, i64 0}
!19 = distinct !{!19, !11, !12}
!20 = distinct !{!20, !11, !12}
