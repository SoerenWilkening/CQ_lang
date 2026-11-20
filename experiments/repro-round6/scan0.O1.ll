; ModuleID = 'scan0.c'
source_filename = "scan0.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@limbs = local_unnamed_addr global [6 x i64] [i64 0, i64 65280, i64 -1, i64 -1, i64 65536, i64 0], align 16

; Function Attrs: nounwind ssp uwtable
define i64 @f(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #2
  %6 = and i32 %5, 3
  %7 = icmp sgt i32 %4, -1
  %8 = zext nneg i32 %6 to i64
  %9 = getelementptr inbounds [6 x i64], ptr @limbs, i64 0, i64 %8
  %10 = load i64, ptr %9, align 8, !tbaa !6
  br i1 %7, label %11, label %30

11:                                               ; preds = %3
  %12 = icmp eq i64 %10, -1
  br i1 %12, label %13, label %26

13:                                               ; preds = %11
  %14 = and i32 %5, 3
  %15 = zext nneg i32 %14 to i64
  br label %16

16:                                               ; preds = %13, %20
  %17 = phi i64 [ %15, %13 ], [ %18, %20 ]
  %18 = add nuw nsw i64 %17, 1
  %19 = icmp eq i64 %18, 5
  br i1 %19, label %76, label %20

20:                                               ; preds = %16
  %21 = getelementptr inbounds [6 x i64], ptr @limbs, i64 0, i64 %18
  %22 = load i64, ptr %21, align 8, !tbaa !6
  %23 = icmp eq i64 %22, -1
  br i1 %23, label %16, label %24, !llvm.loop !10

24:                                               ; preds = %20
  %25 = trunc nuw nsw i64 %18 to i32
  br label %26

26:                                               ; preds = %24, %11
  %27 = phi i64 [ %10, %11 ], [ %22, %24 ]
  %28 = phi i32 [ %6, %11 ], [ %25, %24 ]
  %29 = xor i64 %27, -1
  br label %55

30:                                               ; preds = %3
  %31 = lshr i32 %5, 2
  %32 = zext nneg i32 %31 to i64
  %33 = and i64 %10, %32
  %34 = icmp eq i64 %33, 0
  br i1 %34, label %35, label %55

35:                                               ; preds = %30
  %36 = and i32 %5, 3
  %37 = zext nneg i32 %36 to i64
  br label %38

38:                                               ; preds = %35, %41
  %39 = phi i64 [ %37, %35 ], [ %42, %41 ]
  %40 = icmp eq i64 %39, 4
  br i1 %40, label %48, label %41

41:                                               ; preds = %38
  %42 = add nuw nsw i64 %39, 1
  %43 = getelementptr inbounds [6 x i64], ptr @limbs, i64 0, i64 %42
  %44 = load i64, ptr %43, align 8, !tbaa !6
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %38, label %46, !llvm.loop !13

46:                                               ; preds = %41
  %47 = trunc nuw nsw i64 %39 to i32
  br label %48

48:                                               ; preds = %38, %46
  %49 = phi i32 [ %47, %46 ], [ 4, %38 ]
  %50 = add nuw nsw i32 %49, 1
  %51 = zext nneg i32 %50 to i64
  %52 = getelementptr inbounds [6 x i64], ptr @limbs, i64 0, i64 %51
  %53 = load i64, ptr %52, align 8, !tbaa !6
  %54 = icmp eq i64 %53, 0
  br i1 %54, label %76, label %55

55:                                               ; preds = %30, %48, %26
  %56 = phi i64 [ %29, %26 ], [ %53, %48 ], [ %33, %30 ]
  %57 = phi i32 [ %28, %26 ], [ %49, %48 ], [ %6, %30 ]
  %58 = and i64 %56, 255
  %59 = icmp eq i64 %58, 0
  br i1 %59, label %60, label %69

60:                                               ; preds = %55, %60
  %61 = phi i32 [ %64, %60 ], [ 0, %55 ]
  %62 = phi i64 [ %63, %60 ], [ %56, %55 ]
  %63 = lshr exact i64 %62, 8
  %64 = add nuw nsw i32 %61, 8
  %65 = and i64 %63, 255
  %66 = icmp eq i64 %65, 0
  %67 = icmp ult i32 %61, 48
  %68 = select i1 %66, i1 %67, i1 false
  br i1 %68, label %60, label %69, !llvm.loop !14

69:                                               ; preds = %60, %55
  %70 = phi i32 [ 0, %55 ], [ %64, %60 ]
  %71 = phi i64 [ %58, %55 ], [ %65, %60 ]
  %72 = shl nuw nsw i32 %57, 6
  %73 = add nuw i32 %70, %72
  %74 = zext i32 %73 to i64
  %75 = add nuw nsw i64 %71, %74
  br label %76

76:                                               ; preds = %16, %48, %69
  %77 = phi i64 [ %75, %69 ], [ -1, %48 ], [ 320, %16 ]
  ret i64 %77
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
