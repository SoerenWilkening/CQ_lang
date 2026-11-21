; ModuleID = 'sw4.c'
source_filename = "sw4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Op = type { i32, i32, i32 }

; Function Attrs: nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i32 @interp(ptr nocapture noundef readonly %0, i32 noundef %1, ptr nocapture noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %96

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %7

7:                                                ; preds = %90, %5
  %8 = phi i64 [ 0, %5 ], [ %93, %90 ]
  %9 = phi i32 [ 0, %5 ], [ %91, %90 ]
  %10 = getelementptr inbounds %struct.Op, ptr %0, i64 %8
  %11 = load i32, ptr %10, align 4, !tbaa !6
  switch i32 %11, label %90 [
    i32 0, label %12
    i32 1, label %34
    i32 2, label %52
    i32 3, label %70
  ]

12:                                               ; preds = %7
  %13 = getelementptr inbounds i8, ptr %10, i64 4
  %14 = load i32, ptr %13, align 4, !tbaa !11
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %2, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !12
  %18 = icmp sgt i32 %17, 0
  br i1 %18, label %19, label %27

19:                                               ; preds = %12
  %20 = mul nsw i32 %14, 3
  %21 = getelementptr inbounds i8, ptr %10, i64 8
  %22 = load i32, ptr %21, align 4, !tbaa !13
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds i32, ptr %2, i64 %23
  %25 = load i32, ptr %24, align 4, !tbaa !12
  %26 = add nsw i32 %25, %20
  store i32 %26, ptr %24, align 4, !tbaa !12
  br label %88

27:                                               ; preds = %12
  %28 = getelementptr inbounds i8, ptr %10, i64 8
  %29 = load i32, ptr %28, align 4, !tbaa !13
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds i32, ptr %2, i64 %30
  %32 = load i32, ptr %31, align 4, !tbaa !12
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %90, label %88

34:                                               ; preds = %7
  %35 = getelementptr inbounds i8, ptr %10, i64 4
  %36 = load i32, ptr %35, align 4, !tbaa !11
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds i32, ptr %2, i64 %37
  %39 = load i32, ptr %38, align 4, !tbaa !12
  %40 = icmp sgt i32 %39, 1
  %41 = getelementptr inbounds i8, ptr %10, i64 8
  %42 = load i32, ptr %41, align 4, !tbaa !13
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds i32, ptr %2, i64 %43
  %45 = load i32, ptr %44, align 4, !tbaa !12
  br i1 %40, label %46, label %49

46:                                               ; preds = %34
  %47 = shl nsw i32 %36, 2
  %48 = add nsw i32 %45, %47
  store i32 %48, ptr %44, align 4, !tbaa !12
  br label %88

49:                                               ; preds = %34
  %50 = xor i32 %9, 1
  %51 = icmp eq i32 %45, 1
  br i1 %51, label %90, label %88

52:                                               ; preds = %7
  %53 = getelementptr inbounds i8, ptr %10, i64 4
  %54 = load i32, ptr %53, align 4, !tbaa !11
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds i32, ptr %2, i64 %55
  %57 = load i32, ptr %56, align 4, !tbaa !12
  %58 = icmp sgt i32 %57, 2
  %59 = getelementptr inbounds i8, ptr %10, i64 8
  %60 = load i32, ptr %59, align 4, !tbaa !13
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds i32, ptr %2, i64 %61
  %63 = load i32, ptr %62, align 4, !tbaa !12
  br i1 %58, label %64, label %67

64:                                               ; preds = %52
  %65 = mul nsw i32 %54, 5
  %66 = add nsw i32 %63, %65
  store i32 %66, ptr %62, align 4, !tbaa !12
  br label %88

67:                                               ; preds = %52
  %68 = xor i32 %9, 2
  %69 = icmp eq i32 %63, 2
  br i1 %69, label %90, label %88

70:                                               ; preds = %7
  %71 = getelementptr inbounds i8, ptr %10, i64 4
  %72 = load i32, ptr %71, align 4, !tbaa !11
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds i32, ptr %2, i64 %73
  %75 = load i32, ptr %74, align 4, !tbaa !12
  %76 = icmp sgt i32 %75, 3
  %77 = getelementptr inbounds i8, ptr %10, i64 8
  %78 = load i32, ptr %77, align 4, !tbaa !13
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds i32, ptr %2, i64 %79
  %81 = load i32, ptr %80, align 4, !tbaa !12
  br i1 %76, label %82, label %85

82:                                               ; preds = %70
  %83 = mul nsw i32 %72, 6
  %84 = add nsw i32 %81, %83
  store i32 %84, ptr %80, align 4, !tbaa !12
  br label %88

85:                                               ; preds = %70
  %86 = xor i32 %9, 3
  %87 = icmp eq i32 %81, 3
  br i1 %87, label %90, label %88

88:                                               ; preds = %82, %85, %64, %67, %46, %49, %19, %27
  %89 = phi i32 [ %9, %82 ], [ %86, %85 ], [ %9, %64 ], [ %68, %67 ], [ %9, %46 ], [ %50, %49 ], [ %9, %19 ], [ %9, %27 ]
  br label %90

90:                                               ; preds = %7, %85, %67, %49, %27, %88
  %91 = phi i32 [ %89, %88 ], [ %9, %27 ], [ %50, %49 ], [ %68, %67 ], [ %86, %85 ], [ -1, %7 ]
  %92 = phi i1 [ false, %88 ], [ true, %27 ], [ true, %49 ], [ true, %67 ], [ true, %85 ], [ true, %7 ]
  %93 = add nuw nsw i64 %8, 1
  %94 = icmp eq i64 %93, %6
  %95 = select i1 %92, i1 true, i1 %94
  br i1 %95, label %96, label %7, !llvm.loop !14

96:                                               ; preds = %90, %3
  %97 = phi i32 [ 0, %3 ], [ %91, %90 ]
  ret i32 %97
}

attributes #0 = { nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"Op", !8, i64 0, !8, i64 4, !8, i64 8}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
!12 = !{!8, !8, i64 0}
!13 = !{!7, !8, i64 8}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
