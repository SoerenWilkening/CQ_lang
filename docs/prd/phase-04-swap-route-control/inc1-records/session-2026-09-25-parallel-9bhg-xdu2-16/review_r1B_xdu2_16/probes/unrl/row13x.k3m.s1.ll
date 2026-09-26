; ModuleID = 'row13x.k3.c'
source_filename = "row13x.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %40, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = zext nneg i32 %0 to i64
  br label %13

8:                                                ; preds = %13
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %10 = icmp ne i32 %9, 0
  %11 = icmp eq i32 %0, 3
  %12 = and i1 %11, %10
  br label %26

13:                                               ; preds = %3, %13
  %14 = phi i64 [ 0, %3 ], [ %18, %13 ]
  %15 = getelementptr inbounds i32, ptr %6, i64 %14
  %16 = trunc i64 %14 to i32
  %17 = add i32 %16, 3
  store i32 %17, ptr %15, align 4, !tbaa !6
  %18 = add nuw nsw i64 %14, 1
  %19 = icmp eq i64 %18, %7
  br i1 %19, label %8, label %13, !llvm.loop !10

20:                                               ; preds = %35
  %21 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %22 = tail call i32 @cq_measure_si32(i32 noundef %36) #4
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %37) #4
  %25 = add nsw i32 %23, %24
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %40

26:                                               ; preds = %8, %35
  %27 = phi i64 [ 0, %8 ], [ %38, %35 ]
  %28 = phi i32 [ 0, %8 ], [ %37, %35 ]
  %29 = phi i32 [ 0, %8 ], [ %36, %35 ]
  br i1 %12, label %30, label %35

30:                                               ; preds = %26
  %31 = getelementptr inbounds i32, ptr %6, i64 %27
  %32 = load i32, ptr %31, align 4, !tbaa !6
  %33 = add nsw i32 %32, %29
  %34 = sub nsw i32 %28, %32
  br label %35

35:                                               ; preds = %26, %30
  %36 = phi i32 [ %33, %30 ], [ %29, %26 ]
  %37 = phi i32 [ %34, %30 ], [ %28, %26 ]
  %38 = add nuw nsw i64 %27, 1
  %39 = icmp eq i64 %38, 3
  br i1 %39, label %20, label %26, !llvm.loop !13

40:                                               ; preds = %1, %20
  %41 = phi i32 [ %25, %20 ], [ 0, %1 ]
  ret i32 %41
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!12 = !{!"llvm.loop.unroll.full"}
!13 = distinct !{!13, !11, !12}
