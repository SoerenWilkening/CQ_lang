; ModuleID = 'heap_list.c'
source_filename = "heap_list.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @hl_index(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #3
  %8 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #3
  %9 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #3
  %10 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #3
  %11 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %12 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #4
  store i32 3, ptr %10, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %10, i64 8
  store ptr %9, ptr %14, align 8, !tbaa !12
  store i32 %11, ptr %9, align 8, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %9, i64 8
  store ptr %8, ptr %15, align 8, !tbaa !12
  store i32 5, ptr %8, align 8, !tbaa !6
  %16 = getelementptr inbounds i8, ptr %8, i64 8
  store ptr %7, ptr %16, align 8, !tbaa !12
  store i32 %12, ptr %7, align 8, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %7, i64 8
  store ptr null, ptr %17, align 8, !tbaa !12
  br label %18

18:                                               ; preds = %6, %23
  %19 = phi ptr [ %10, %6 ], [ %26, %23 ]
  %20 = phi i32 [ 0, %6 ], [ %24, %23 ]
  %21 = load i32, ptr %19, align 8, !tbaa !6
  %22 = icmp eq i32 %21, %13
  br i1 %22, label %28, label %23

23:                                               ; preds = %18
  %24 = add nuw nsw i32 %20, 1
  %25 = getelementptr inbounds i8, ptr %19, i64 8
  %26 = load ptr, ptr %25, align 8, !tbaa !12
  %27 = icmp eq ptr %26, null
  br i1 %27, label %28, label %18, !llvm.loop !13

28:                                               ; preds = %23, %18
  %29 = phi i32 [ -1, %23 ], [ %20, %18 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #5
  ret i32 %30
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @hl_sum(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call dereferenceable_or_null(24) ptr @malloc(i64 noundef 24) #3
  %5 = tail call dereferenceable_or_null(24) ptr @malloc(i64 noundef 24) #3
  %6 = tail call dereferenceable_or_null(24) ptr @malloc(i64 noundef 24) #3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  store i64 1, ptr %6, align 8, !tbaa !16
  %8 = getelementptr inbounds i8, ptr %6, i64 8
  store i32 %7, ptr %8, align 8, !tbaa !19
  %9 = getelementptr inbounds i8, ptr %6, i64 16
  store ptr %5, ptr %9, align 8, !tbaa !20
  store i64 2, ptr %5, align 8, !tbaa !16
  %10 = add nsw i32 %7, 4
  %11 = getelementptr inbounds i8, ptr %5, i64 8
  store i32 %10, ptr %11, align 8, !tbaa !19
  %12 = getelementptr inbounds i8, ptr %5, i64 16
  store ptr %4, ptr %12, align 8, !tbaa !20
  store i64 3, ptr %4, align 8, !tbaa !16
  %13 = getelementptr inbounds i8, ptr %4, i64 8
  store i32 9, ptr %13, align 8, !tbaa !19
  %14 = getelementptr inbounds i8, ptr %4, i64 16
  store ptr null, ptr %14, align 8, !tbaa !20
  br label %15

15:                                               ; preds = %21, %3
  %16 = phi i32 [ 0, %3 ], [ %22, %21 ]
  %17 = phi ptr [ %6, %3 ], [ %24, %21 ]
  %18 = getelementptr inbounds i8, ptr %17, i64 8
  %19 = load i32, ptr %18, align 8, !tbaa !19
  %20 = icmp slt i32 %19, %2
  br i1 %20, label %21, label %26

21:                                               ; preds = %15
  %22 = add nsw i32 %19, %16
  %23 = getelementptr inbounds i8, ptr %17, i64 16
  %24 = load ptr, ptr %23, align 8, !tbaa !20
  %25 = icmp eq ptr %24, null
  br i1 %25, label %26, label %15, !llvm.loop !21

26:                                               ; preds = %21, %15
  %27 = phi i32 [ %22, %21 ], [ %16, %15 ]
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #5
  ret i32 %28
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { allocsize(0) }
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
!7 = !{!"node", !8, i64 0, !11, i64 8}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!"any pointer", !9, i64 0}
!12 = !{!7, !11, i64 8}
!13 = distinct !{!13, !14, !15}
!14 = !{!"llvm.loop.mustprogress"}
!15 = !{!"llvm.loop.unroll.disable"}
!16 = !{!17, !18, i64 0}
!17 = !{!"rec", !18, i64 0, !8, i64 8, !11, i64 16}
!18 = !{!"long", !9, i64 0}
!19 = !{!17, !8, i64 8}
!20 = !{!17, !11, i64 16}
!21 = distinct !{!21, !14, !15}
