; ModuleID = 'split_cells.c'
source_filename = "split_cells.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @split_cells(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #4
  store i32 65537, ptr %5, align 4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %8, label %13

8:                                                ; preds = %4
  %9 = add nsw i32 %2, -1
  %10 = tail call i32 @llvm.umin.i32(i32 %9, i32 3)
  %11 = add nuw nsw i32 %10, 1
  %12 = zext nneg i32 %11 to i64
  br label %27

13:                                               ; preds = %27, %4
  %14 = and i32 %3, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = zext i8 %17 to i32
  %19 = add nsw i32 %3, 1
  %20 = and i32 %19, 3
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !6
  %24 = zext i8 %23 to i32
  %25 = add nuw nsw i32 %24, %18
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #4
  ret i32 %26

27:                                               ; preds = %8, %27
  %28 = phi i64 [ 0, %8 ], [ %33, %27 ]
  %29 = trunc nuw nsw i64 %28 to i32
  %30 = add i32 %6, %29
  %31 = trunc i32 %30 to i8
  %32 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %28
  store i8 %31, ptr %32, align 1, !tbaa !6
  %33 = add nuw nsw i64 %28, 1
  %34 = icmp eq i64 %33, %12
  br i1 %34, label %13, label %27, !llvm.loop !9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
