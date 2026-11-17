; ModuleID = 'heap_linked_list.c'
source_filename = "heap_linked_list.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @list_search(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #6
  %7 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #6
  %8 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #7
  store i32 %9, ptr %8, align 8, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %8, i64 8
  store ptr %7, ptr %11, align 8, !tbaa !12
  store i32 %10, ptr %7, align 8, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %7, i64 8
  store ptr %6, ptr %12, align 8, !tbaa !12
  store i32 7, ptr %6, align 8, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %6, i64 8
  store ptr null, ptr %13, align 8, !tbaa !12
  br label %14

14:                                               ; preds = %5, %19
  %15 = phi ptr [ %8, %5 ], [ %22, %19 ]
  %16 = phi i32 [ 0, %5 ], [ %20, %19 ]
  %17 = load i32, ptr %15, align 8, !tbaa !6
  %18 = icmp eq i32 %17, %4
  br i1 %18, label %24, label %19

19:                                               ; preds = %14
  %20 = add nuw nsw i32 %16, 1
  %21 = getelementptr inbounds i8, ptr %15, i64 8
  %22 = load ptr, ptr %21, align 8, !tbaa !12
  %23 = icmp eq ptr %22, null
  br i1 %23, label %24, label %14, !llvm.loop !13

24:                                               ; preds = %19, %14
  %25 = phi i32 [ -1, %19 ], [ %16, %14 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #8
  ret i32 %26
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @calloc_aligned(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #7
  %8 = tail call dereferenceable_or_null(16) ptr @calloc(i64 noundef 4, i64 noundef 4) #9
  %9 = tail call align 16 dereferenceable_or_null(16) ptr @aligned_alloc(i64 noundef 16, i64 noundef 16) #10
  %10 = and i32 %6, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i32, ptr %8, i64 %11
  store i32 %7, ptr %12, align 4, !tbaa !16
  %13 = getelementptr inbounds i8, ptr %8, i64 4
  %14 = load i32, ptr %13, align 4, !tbaa !16
  store i32 %14, ptr %9, align 16, !tbaa !16
  %15 = add nsw i32 %7, 1
  %16 = getelementptr inbounds i8, ptr %9, i64 4
  store i32 %15, ptr %16, align 4, !tbaa !16
  %17 = and i32 %4, 1
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %9, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !16
  %21 = add nsw i32 %20, 1
  tail call void @free(ptr noundef %8)
  tail call void @free(ptr noundef %9)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #8
  ret i32 %22
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @calloc(i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @aligned_alloc(i64 allocalign noundef, i64 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { allocsize(0) }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind }
attributes #9 = { allocsize(0,1) }
attributes #10 = { allocsize(1) }

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
!16 = !{!8, !8, i64 0}
