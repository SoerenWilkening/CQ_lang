; ModuleID = 'nest_exits.c'
source_filename = "nest_exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noreturn nounwind ssp uwtable
define void @nest_cont(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #8
  store i32 0, ptr %3, align 4, !tbaa !6
  br label %5

5:                                                ; preds = %16, %2
  %6 = phi i32 [ 1, %2 ], [ %17, %16 ]
  %7 = phi i32 [ %4, %2 ], [ %12, %16 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #8
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %9

9:                                                ; preds = %9, %5
  %10 = phi i32 [ %7, %5 ], [ %12, %9 ]
  %11 = mul nsw i32 %10, 5
  %12 = add nsw i32 %11, 1
  %13 = and i32 %12, 3
  switch i32 %13, label %9 [
    i32 0, label %14
    i32 1, label %16
  ], !llvm.loop !10

14:                                               ; preds = %9
  %15 = add nsw i32 %6, 2
  br label %16

16:                                               ; preds = %9, %14
  %17 = phi i32 [ %15, %14 ], [ 0, %9 ]
  br label %5, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @tick(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  %4 = icmp eq i32 %3, 3
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @exit(i32 noundef 0) #9
  unreachable

6:                                                ; preds = %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @nest_cont_ret(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #4 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #7
  %5 = and i32 %1, 3
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %11, label %7

7:                                                ; preds = %3, %22
  %8 = phi i32 [ %18, %22 ], [ %4, %3 ]
  %9 = phi i32 [ %24, %22 ], [ 0, %3 ]
  %10 = phi i32 [ %23, %22 ], [ 1, %3 ]
  br label %15

11:                                               ; preds = %22, %3
  %12 = phi i32 [ 1, %3 ], [ %23, %22 ]
  %13 = phi i32 [ %4, %3 ], [ %18, %22 ]
  %14 = xor i32 %13, %12
  ret i32 %14

15:                                               ; preds = %7, %15
  %16 = phi i32 [ %18, %15 ], [ %8, %7 ]
  %17 = mul nsw i32 %16, 5
  %18 = add nsw i32 %17, 1
  %19 = and i32 %18, 3
  switch i32 %19, label %15 [
    i32 0, label %20
    i32 1, label %22
  ]

20:                                               ; preds = %15
  %21 = add nsw i32 %10, 2
  br label %22

22:                                               ; preds = %15, %20
  %23 = phi i32 [ %21, %20 ], [ 0, %15 ]
  %24 = add nuw nsw i32 %9, 1
  %25 = icmp eq i32 %24, %5
  br i1 %25, label %11, label %7, !llvm.loop !12
}

; Function Attrs: nounwind ssp uwtable
define i32 @nest_abort(i32 noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  br label %4

4:                                                ; preds = %2, %30
  %5 = phi i32 [ undef, %2 ], [ %29, %30 ]
  %6 = phi i32 [ 0, %2 ], [ %33, %30 ]
  %7 = phi i32 [ 0, %2 ], [ %32, %30 ]
  %8 = phi i32 [ %3, %2 ], [ %13, %30 ]
  br label %9

9:                                                ; preds = %4, %21
  %10 = phi i32 [ %13, %21 ], [ %8, %4 ]
  %11 = phi i32 [ %29, %21 ], [ %5, %4 ]
  %12 = mul nsw i32 %10, 3
  %13 = add nsw i32 %12, 1
  %14 = and i32 %13, 7
  %15 = icmp eq i32 %14, 5
  br i1 %15, label %16, label %21

16:                                               ; preds = %9
  %17 = and i32 %10, 2
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %20, label %19

19:                                               ; preds = %16
  tail call void @cq_phi(double noundef 2.500000e-01) #8
  br label %20

20:                                               ; preds = %19, %16
  tail call void @abort() #10
  unreachable

21:                                               ; preds = %9
  %22 = and i32 %13, 8
  %23 = icmp eq i32 %22, 0
  %24 = icmp eq i32 %14, 2
  %25 = zext i1 %24 to i32
  %26 = select i1 %23, i32 %25, i32 5
  %27 = and i32 %13, 15
  %28 = icmp eq i32 %27, 2
  %29 = select i1 %28, i32 %7, i32 %11
  switch i32 %26, label %35 [
    i32 0, label %9
    i32 5, label %30
  ], !llvm.loop !14

30:                                               ; preds = %21
  %31 = and i32 %13, 15
  %32 = add nuw nsw i32 %31, %7
  %33 = add nuw nsw i32 %6, 1
  %34 = icmp eq i32 %6, 0
  br i1 %34, label %4, label %35, !llvm.loop !15

35:                                               ; preds = %30, %21
  %36 = phi i32 [ %29, %21 ], [ %32, %30 ]
  ret i32 %36
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #5

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #6

attributes #0 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind }
attributes #9 = { noreturn nounwind }
attributes #10 = { cold noreturn nounwind }

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
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !13, !11}
!13 = !{!"llvm.loop.mustprogress"}
!14 = distinct !{!14, !11}
!15 = distinct !{!15, !13, !11}
