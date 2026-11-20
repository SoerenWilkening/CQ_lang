; ModuleID = 'div2exp.c'
source_filename = "div2exp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@limbs = local_unnamed_addr global [4 x i64] [i64 0, i64 0, i64 5, i64 8], align 16

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #3
  %6 = lshr i32 %5, 2
  %7 = tail call i32 @llvm.abs.i32(i32 %4, i1 true)
  %8 = icmp ult i32 %6, %7
  br i1 %8, label %9, label %11

9:                                                ; preds = %3
  %10 = icmp ult i32 %5, 4
  br i1 %10, label %23, label %16

11:                                               ; preds = %3
  %12 = icmp eq i32 %4, 0
  br label %34

13:                                               ; preds = %16
  %14 = add nuw nsw i32 %17, 1
  %15 = icmp eq i32 %14, %6
  br i1 %15, label %23, label %16, !llvm.loop !6

16:                                               ; preds = %9, %13
  %17 = phi i32 [ %14, %13 ], [ 0, %9 ]
  %18 = and i32 %17, 3
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [4 x i64], ptr @limbs, i64 0, i64 %19
  %21 = load i64, ptr %20, align 8, !tbaa !9
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %13, label %34

23:                                               ; preds = %13, %9
  %24 = and i32 %6, 3
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [4 x i64], ptr @limbs, i64 0, i64 %25
  %27 = load i64, ptr %26, align 8, !tbaa !9
  %28 = and i32 %5, 3
  %29 = zext nneg i32 %28 to i64
  %30 = shl nsw i64 -1, %29
  %31 = xor i64 %30, -1
  %32 = and i64 %27, %31
  %33 = icmp eq i64 %32, 0
  br label %34

34:                                               ; preds = %16, %23, %11
  %35 = phi i1 [ %12, %11 ], [ %33, %23 ], [ false, %16 ]
  %36 = zext i1 %35 to i32
  ret i32 %36
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
