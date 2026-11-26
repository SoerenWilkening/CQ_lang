; ModuleID = 'mid_abort.c'
source_filename = "mid_abort.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global [8 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @ma_sum(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 31
  %6 = and i32 %2, 3
  br label %7

7:                                                ; preds = %20, %3
  %8 = phi i32 [ %5, %3 ], [ %22, %20 ]
  %9 = phi i32 [ 0, %3 ], [ %21, %20 ]
  %10 = phi i32 [ 0, %3 ], [ %23, %20 ]
  switch i32 %8, label %12 [
    i32 0, label %24
    i32 6, label %11
  ]

11:                                               ; preds = %7
  tail call void @abort() #4
  unreachable

12:                                               ; preds = %7
  %13 = and i32 %8, 7
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = add nsw i32 %16, 1
  store i32 %17, ptr %15, align 4, !tbaa !6
  %18 = icmp eq i32 %10, %6
  br i1 %18, label %19, label %20

19:                                               ; preds = %12
  tail call void @abort() #4
  unreachable

20:                                               ; preds = %12
  %21 = add nuw nsw i32 %9, %8
  %22 = lshr i32 %8, 1
  %23 = add nuw nsw i32 %10, 1
  br label %7, !llvm.loop !10

24:                                               ; preds = %7
  %25 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %26 = add nsw i32 %25, %9
  %27 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %28 = shl nsw i32 %27, 1
  %29 = add nsw i32 %26, %28
  ret i32 %29
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noreturn nounwind
declare void @abort() local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { noreturn nounwind }

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
