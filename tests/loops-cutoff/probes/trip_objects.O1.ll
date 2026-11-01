; ModuleID = 'trip_objects.c'
source_filename = "trip_objects.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @to_last(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 3
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %9, %2
  %7 = phi ptr [ null, %2 ], [ %11, %9 ]
  %8 = icmp eq ptr %7, null
  br i1 %8, label %19, label %16

9:                                                ; preds = %2, %9
  %10 = phi i32 [ %14, %9 ], [ 0, %2 ]
  %11 = tail call dereferenceable_or_null(1) ptr @malloc(i64 noundef 1) #4
  %12 = add i32 %10, %3
  %13 = trunc i32 %12 to i8
  store i8 %13, ptr %11, align 1, !tbaa !6
  %14 = add nuw nsw i32 %10, 1
  %15 = icmp eq i32 %14, %4
  br i1 %15, label %6, label %9, !llvm.loop !9

16:                                               ; preds = %6
  %17 = load i8, ptr %7, align 1, !tbaa !6
  %18 = zext i8 %17 to i32
  br label %19

19:                                               ; preds = %6, %16
  %20 = phi i32 [ %18, %16 ], [ 7, %6 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  ret i32 %21
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @to_cells(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 3
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %9, %2
  %7 = phi ptr [ null, %2 ], [ %11, %9 ]
  %8 = icmp eq ptr %7, null
  br i1 %8, label %27, label %20

9:                                                ; preds = %2, %9
  %10 = phi i32 [ %18, %9 ], [ 0, %2 ]
  %11 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #4
  %12 = add i32 %10, %3
  %13 = trunc i32 %12 to i8
  store i8 %13, ptr %11, align 1, !tbaa !6
  %14 = add nuw nsw i32 %10, 5
  %15 = xor i32 %14, %3
  %16 = trunc i32 %15 to i8
  %17 = getelementptr inbounds i8, ptr %11, i64 2
  store i8 %16, ptr %17, align 1, !tbaa !6
  %18 = add nuw nsw i32 %10, 1
  %19 = icmp eq i32 %18, %4
  br i1 %19, label %6, label %9, !llvm.loop !12

20:                                               ; preds = %6
  %21 = getelementptr inbounds i8, ptr %7, i64 2
  %22 = load i8, ptr %21, align 1, !tbaa !6
  %23 = zext i8 %22 to i32
  %24 = load i8, ptr %7, align 1, !tbaa !6
  %25 = zext i8 %24 to i32
  %26 = add nuw nsw i32 %25, %23
  br label %27

27:                                               ; preds = %6, %20
  %28 = phi i32 [ %26, %20 ], [ 9, %6 ]
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #5
  ret i32 %29
}

; Function Attrs: nounwind ssp uwtable
define i32 @to_ne(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 3
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %10, %3
  %8 = phi ptr [ null, %3 ], [ %12, %10 ]
  %9 = icmp eq ptr %8, null
  br i1 %9, label %19, label %17

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %3 ]
  %12 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #4
  %13 = mul i32 %11, %4
  %14 = add nsw i32 %13, %2
  store i32 %14, ptr %12, align 4, !tbaa !13
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %5
  br i1 %16, label %7, label %10, !llvm.loop !15

17:                                               ; preds = %7
  %18 = load i32, ptr %8, align 4, !tbaa !13
  br label %19

19:                                               ; preds = %17, %7
  %20 = phi i32 [ %18, %17 ], [ -1, %7 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  ret i32 %21
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { allocsize(0) }
attributes #5 = { nounwind }

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
!12 = distinct !{!12, !10, !11}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !7, i64 0}
!15 = distinct !{!15, !10, !11}
