; ModuleID = 'tests/bus-alloc/probes/alloc_nobuiltin.c'
source_filename = "tests/bus-alloc/probes/alloc_nobuiltin.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @n_calloc_count(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = and i32 %4, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  %8 = tail call ptr @calloc(i64 noundef %7, i64 noundef 4) #6
  %9 = icmp eq ptr %8, null
  br i1 %9, label %15, label %10

10:                                               ; preds = %3
  %11 = zext nneg i32 %5 to i64
  %12 = getelementptr inbounds i32, ptr %8, i64 %11
  store i32 %2, ptr %12, align 4, !tbaa !6
  %13 = load i32, ptr %8, align 4, !tbaa !6
  %14 = add nsw i32 %13, %2
  tail call void @free(ptr noundef nonnull %8) #7
  br label %15

15:                                               ; preds = %3, %10
  %16 = phi i32 [ %14, %10 ], [ -1, %3 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #7
  ret i32 %17
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: allocsize(0,1)
declare ptr @calloc(i64 noundef, i64 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @free(ptr noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @n_calloc_size(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = and i32 %4, 7
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  %8 = tail call ptr @calloc(i64 noundef 2, i64 noundef %7) #6
  %9 = icmp eq ptr %8, null
  br i1 %9, label %17, label %10

10:                                               ; preds = %3
  %11 = trunc i32 %2 to i8
  %12 = and i32 %4, 1
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds i8, ptr %8, i64 %13
  store i8 %11, ptr %14, align 1, !tbaa !10
  %15 = load i8, ptr %8, align 1, !tbaa !10
  %16 = zext i8 %15 to i32
  tail call void @free(ptr noundef nonnull %8) #7
  br label %17

17:                                               ; preds = %3, %10
  %18 = phi i32 [ %16, %10 ], [ -1, %3 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #7
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @n_calloc_both(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = and i32 %4, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  %8 = lshr i32 %4, 2
  %9 = and i32 %8, 3
  %10 = add nuw nsw i32 %9, 1
  %11 = zext nneg i32 %10 to i64
  %12 = tail call ptr @calloc(i64 noundef %7, i64 noundef %11) #6
  %13 = icmp eq ptr %12, null
  br i1 %13, label %22, label %14

14:                                               ; preds = %3
  %15 = trunc i32 %2 to i8
  store i8 %15, ptr %12, align 1, !tbaa !10
  %16 = and i32 %2, 255
  %17 = zext nneg i32 %5 to i64
  %18 = getelementptr inbounds i8, ptr %12, i64 %17
  %19 = load i8, ptr %18, align 1, !tbaa !10
  %20 = zext i8 %19 to i32
  %21 = add nuw nsw i32 %16, %20
  tail call void @free(ptr noundef nonnull %12) #7
  br label %22

22:                                               ; preds = %3, %14
  %23 = phi i32 [ %21, %14 ], [ -1, %3 ]
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #7
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @n_calloc_wide(i16 noundef zeroext %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %0, double noundef %1) #5
  %5 = zext i16 %4 to i64
  %6 = tail call ptr @calloc(i64 noundef %5, i64 noundef 1) #6
  %7 = icmp eq ptr %6, null
  br i1 %7, label %15, label %8

8:                                                ; preds = %3
  %9 = icmp eq i16 %4, 0
  br i1 %9, label %13, label %10

10:                                               ; preds = %8
  %11 = trunc i32 %2 to i8
  store i8 %11, ptr %6, align 1, !tbaa !10
  %12 = and i32 %2, 255
  br label %13

13:                                               ; preds = %8, %10
  %14 = phi i32 [ %12, %10 ], [ -2, %8 ]
  tail call void @free(ptr noundef nonnull %6) #7
  br label %15

15:                                               ; preds = %3, %13
  %16 = phi i32 [ %14, %13 ], [ -1, %3 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #7
  ret i32 %17
}

declare zeroext i16 @cq_theta_ui16(i16 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @n_malloc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = and i32 %4, 3
  %6 = shl nuw nsw i32 %5, 2
  %7 = add nuw nsw i32 %6, 4
  %8 = zext nneg i32 %7 to i64
  %9 = tail call ptr @malloc(i64 noundef %8) #8
  %10 = icmp eq ptr %9, null
  br i1 %10, label %15, label %11

11:                                               ; preds = %3
  %12 = add nsw i32 %4, %2
  %13 = zext nneg i32 %5 to i64
  %14 = getelementptr inbounds i32, ptr %9, i64 %13
  store i32 %12, ptr %14, align 4, !tbaa !6
  tail call void @free(ptr noundef nonnull %9) #7
  br label %15

15:                                               ; preds = %3, %11
  %16 = phi i32 [ %12, %11 ], [ -1, %3 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #7
  ret i32 %17
}

; Function Attrs: allocsize(0)
declare ptr @malloc(i64 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @n_realloc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #8
  %6 = icmp eq ptr %5, null
  br i1 %6, label %19, label %7

7:                                                ; preds = %3
  store i32 %2, ptr %5, align 4, !tbaa !6
  %8 = and i32 %4, 3
  %9 = shl nuw nsw i32 %8, 2
  %10 = add nuw nsw i32 %9, 4
  %11 = zext nneg i32 %10 to i64
  %12 = tail call ptr @realloc(ptr noundef nonnull %5, i64 noundef %11) #9
  %13 = icmp eq ptr %12, null
  br i1 %13, label %19, label %14

14:                                               ; preds = %7
  %15 = zext nneg i32 %8 to i64
  %16 = getelementptr inbounds i32, ptr %12, i64 %15
  store i32 1, ptr %16, align 4, !tbaa !6
  %17 = load i32, ptr %12, align 4, !tbaa !6
  %18 = add nsw i32 %17, 1
  tail call void @free(ptr noundef nonnull %12) #7
  br label %19

19:                                               ; preds = %7, %3, %14
  %20 = phi i32 [ %18, %14 ], [ -1, %3 ], [ -1, %7 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #7
  ret i32 %21
}

; Function Attrs: allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { allocsize(0,1) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { allocsize(0) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { allocsize(1) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nobuiltin nomerge nounwind "no-builtins" }
attributes #6 = { nobuiltin nounwind allocsize(0,1) "no-builtins" }
attributes #7 = { nobuiltin nounwind "no-builtins" }
attributes #8 = { nobuiltin nounwind allocsize(0) "no-builtins" }
attributes #9 = { nobuiltin nounwind allocsize(1) "no-builtins" }

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
!10 = !{!8, !8, i64 0}
