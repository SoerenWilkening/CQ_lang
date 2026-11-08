; ModuleID = 'arm_tail.c'
source_filename = "arm_tail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [5 x i8] c"%\00.$\00", align 1
@at_errno = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @arm_tail(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [10 x i32], align 16
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 40, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(40) %2, i8 0, i64 40, i1 false)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  store i32 3014753, ptr %3, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #6
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [10 x i32], ptr %2, i64 0, i64 %6
  store i32 1, ptr %7, align 4, !tbaa !6
  %8 = lshr i32 %4, 3
  %9 = and i32 %8, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [5 x i8], ptr @.str, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !10
  %13 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 %12, ptr %13, align 1, !tbaa !10
  %14 = call fastcc i32 @scan(ptr noundef nonnull %3, ptr noundef nonnull %2)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  call void @llvm.lifetime.end.p0(i64 40, ptr nonnull %2) #5
  ret i32 %15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: read, inaccessiblemem: none) uwtable
define internal fastcc noundef i32 @scan(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1) unnamed_addr #4 {
  br label %3

3:                                                ; preds = %16, %2
  %4 = phi ptr [ %0, %2 ], [ %17, %16 ]
  %5 = phi i32 [ 0, %2 ], [ %18, %16 ]
  %6 = load i8, ptr %4, align 1, !tbaa !10
  switch i8 %6, label %9 [
    i8 46, label %16
    i8 0, label %7
    i8 36, label %8
  ]

7:                                                ; preds = %3
  br label %16

8:                                                ; preds = %3
  br label %9

9:                                                ; preds = %3, %8
  %10 = phi i32 [ 1, %8 ], [ %5, %3 ]
  %11 = icmp ne i8 %6, 37
  %12 = zext i1 %11 to i64
  %13 = getelementptr inbounds i8, ptr %4, i64 %12
  %14 = xor i1 %11, true
  %15 = zext i1 %14 to i32
  br label %16

16:                                               ; preds = %9, %3, %7
  %17 = phi ptr [ %4, %7 ], [ %4, %3 ], [ %13, %9 ]
  %18 = phi i32 [ %5, %7 ], [ %5, %3 ], [ %10, %9 ]
  %19 = phi i32 [ 4, %7 ], [ 2, %3 ], [ %15, %9 ]
  switch i32 %19, label %31 [
    i32 0, label %3
    i32 2, label %20
    i32 4, label %30
  ], !llvm.loop !11

20:                                               ; preds = %16
  %21 = icmp eq i32 %18, 0
  br i1 %21, label %31, label %25

22:                                               ; preds = %25
  %23 = add nuw nsw i64 %26, 1
  %24 = icmp eq i64 %23, 10
  br i1 %24, label %31, label %25, !llvm.loop !13

25:                                               ; preds = %20, %22
  %26 = phi i64 [ %23, %22 ], [ 1, %20 ]
  %27 = getelementptr inbounds i32, ptr %1, i64 %26
  %28 = load i32, ptr %27, align 4, !tbaa !6
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %22, label %30

30:                                               ; preds = %16, %25
  store i32 22, ptr @at_errno, align 4, !tbaa !6
  br label %31

31:                                               ; preds = %16, %22, %20, %30
  %32 = phi i32 [ -1, %30 ], [ 2, %20 ], [ 1, %22 ], [ 0, %16 ]
  ret i32 %32
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
!11 = distinct !{!11, !12}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !14, !12}
!14 = !{!"llvm.loop.mustprogress"}
