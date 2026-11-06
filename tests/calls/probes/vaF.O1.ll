; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/vaF.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/vaF.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define i32 @sumA(i32 noundef %0, ...) local_unnamed_addr #0 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #5
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %10

4:                                                ; preds = %1
  %5 = load i32, ptr %2, align 16
  %6 = getelementptr inbounds i8, ptr %2, i64 8
  %7 = getelementptr inbounds i8, ptr %2, i64 16
  %8 = load ptr, ptr %7, align 16
  %9 = load ptr, ptr %6, align 8
  br label %12

10:                                               ; preds = %24, %1
  %11 = phi i32 [ 0, %1 ], [ %30, %24 ]
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #5
  ret i32 %11

12:                                               ; preds = %4, %24
  %13 = phi ptr [ %9, %4 ], [ %25, %24 ]
  %14 = phi i32 [ 0, %4 ], [ %31, %24 ]
  %15 = phi i32 [ 0, %4 ], [ %30, %24 ]
  %16 = phi i32 [ %5, %4 ], [ %26, %24 ]
  %17 = icmp ult i32 %16, 41
  br i1 %17, label %18, label %22

18:                                               ; preds = %12
  %19 = zext nneg i32 %16 to i64
  %20 = getelementptr i8, ptr %8, i64 %19
  %21 = add nuw nsw i32 %16, 8
  store i32 %21, ptr %2, align 16
  br label %24

22:                                               ; preds = %12
  %23 = getelementptr i8, ptr %13, i64 8
  store ptr %23, ptr %6, align 8
  br label %24

24:                                               ; preds = %22, %18
  %25 = phi ptr [ %13, %18 ], [ %23, %22 ]
  %26 = phi i32 [ %21, %18 ], [ %16, %22 ]
  %27 = phi ptr [ %20, %18 ], [ %13, %22 ]
  %28 = load ptr, ptr %27, align 8, !tbaa !6
  %29 = load i32, ptr %28, align 4, !tbaa !10
  %30 = add nsw i32 %29, %15
  %31 = add nuw nsw i32 %14, 1
  %32 = icmp eq i32 %31, %0
  br i1 %32, label %10, label %12, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define i32 @sumB(i32 noundef %0, ...) local_unnamed_addr #0 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #5
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %10

4:                                                ; preds = %1
  %5 = load i32, ptr %2, align 16
  %6 = getelementptr inbounds i8, ptr %2, i64 8
  %7 = getelementptr inbounds i8, ptr %2, i64 16
  %8 = load ptr, ptr %7, align 16
  %9 = load ptr, ptr %6, align 8
  br label %12

10:                                               ; preds = %24, %1
  %11 = phi i32 [ 100, %1 ], [ %30, %24 ]
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #5
  ret i32 %11

12:                                               ; preds = %4, %24
  %13 = phi ptr [ %9, %4 ], [ %25, %24 ]
  %14 = phi i32 [ 0, %4 ], [ %31, %24 ]
  %15 = phi i32 [ 100, %4 ], [ %30, %24 ]
  %16 = phi i32 [ %5, %4 ], [ %26, %24 ]
  %17 = icmp ult i32 %16, 41
  br i1 %17, label %18, label %22

18:                                               ; preds = %12
  %19 = zext nneg i32 %16 to i64
  %20 = getelementptr i8, ptr %8, i64 %19
  %21 = add nuw nsw i32 %16, 8
  store i32 %21, ptr %2, align 16
  br label %24

22:                                               ; preds = %12
  %23 = getelementptr i8, ptr %13, i64 8
  store ptr %23, ptr %6, align 8
  br label %24

24:                                               ; preds = %22, %18
  %25 = phi ptr [ %13, %18 ], [ %23, %22 ]
  %26 = phi i32 [ %21, %18 ], [ %16, %22 ]
  %27 = phi ptr [ %20, %18 ], [ %13, %22 ]
  %28 = load ptr, ptr %27, align 8, !tbaa !6
  %29 = load i32, ptr %28, align 4, !tbaa !10
  %30 = sub nsw i32 %15, %29
  %31 = add nuw nsw i32 %14, 1
  %32 = icmp eq i32 %31, %0
  br i1 %32, label %10, label %12, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @vaF(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #3 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #5
  %6 = add nsw i32 %1, 1
  store i32 %6, ptr %5, align 4, !tbaa !10
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #6
  %8 = and i32 %7, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, ptr @sumB, ptr @sumA
  store i32 %7, ptr %4, align 4, !tbaa !10
  %11 = call i32 (i32, ...) %10(i32 noundef 2, ptr noundef nonnull %4, ptr noundef nonnull %5) #5, !callees !16
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #5
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = !{ptr @sumA, ptr @sumB}
