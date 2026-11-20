; ModuleID = 'glpk/build/lib/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

; Function Attrs: nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define range(i32 0, 7) i32 @glp_check_cnfsat(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = getelementptr inbounds i8, ptr %0, i64 56
  %3 = load i32, ptr %2, align 8, !tbaa !6
  %4 = getelementptr inbounds i8, ptr %0, i64 60
  %5 = load i32, ptr %4, align 4, !tbaa !13
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %34, label %7

7:                                                ; preds = %1
  %8 = getelementptr inbounds i8, ptr %0, i64 80
  %9 = load ptr, ptr %8, align 8, !tbaa !14
  %10 = add nuw i32 %5, 1
  %11 = zext i32 %10 to i64
  br label %15

12:                                               ; preds = %30
  %13 = add nuw nsw i64 %16, 1
  %14 = icmp eq i64 %13, %11
  br i1 %14, label %34, label %15, !llvm.loop !15

15:                                               ; preds = %12, %7
  %16 = phi i64 [ 1, %7 ], [ %13, %12 ]
  %17 = getelementptr inbounds ptr, ptr %9, i64 %16
  %18 = load ptr, ptr %17, align 8, !tbaa !18
  %19 = getelementptr inbounds i8, ptr %18, i64 24
  %20 = load i32, ptr %19, align 8, !tbaa !19
  %21 = icmp eq i32 %20, 2
  br i1 %21, label %22, label %98

22:                                               ; preds = %15
  %23 = getelementptr inbounds i8, ptr %18, i64 28
  %24 = load i32, ptr %23, align 4, !tbaa !21
  %25 = icmp eq i32 %24, 4
  br i1 %25, label %26, label %98

26:                                               ; preds = %22
  %27 = getelementptr inbounds i8, ptr %18, i64 32
  %28 = load double, ptr %27, align 8, !tbaa !22
  %29 = fcmp oeq double %28, 0.000000e+00
  br i1 %29, label %30, label %98

30:                                               ; preds = %26
  %31 = getelementptr inbounds i8, ptr %18, i64 40
  %32 = load double, ptr %31, align 8, !tbaa !23
  %33 = fcmp oeq double %32, 1.000000e+00
  br i1 %33, label %12, label %98

34:                                               ; preds = %12, %1
  %35 = getelementptr inbounds i8, ptr %0, i64 40
  %36 = load double, ptr %35, align 8, !tbaa !24
  %37 = fcmp une double %36, 0.000000e+00
  br i1 %37, label %98, label %38

38:                                               ; preds = %34
  %39 = icmp slt i32 %5, 1
  br i1 %39, label %48, label %40

40:                                               ; preds = %38
  %41 = getelementptr inbounds i8, ptr %0, i64 80
  %42 = load ptr, ptr %41, align 8, !tbaa !14
  %43 = add nuw i32 %5, 1
  %44 = zext i32 %43 to i64
  br label %55

45:                                               ; preds = %55
  %46 = add nuw nsw i64 %56, 1
  %47 = icmp eq i64 %46, %44
  br i1 %47, label %48, label %55, !llvm.loop !25

48:                                               ; preds = %45, %38
  %49 = icmp slt i32 %3, 1
  br i1 %49, label %98, label %50

50:                                               ; preds = %48
  %51 = getelementptr inbounds i8, ptr %0, i64 72
  %52 = load ptr, ptr %51, align 8, !tbaa !26
  %53 = add nuw i32 %3, 1
  %54 = zext i32 %53 to i64
  br label %65

55:                                               ; preds = %45, %40
  %56 = phi i64 [ 1, %40 ], [ %46, %45 ]
  %57 = getelementptr inbounds ptr, ptr %42, i64 %56
  %58 = load ptr, ptr %57, align 8, !tbaa !18
  %59 = getelementptr inbounds i8, ptr %58, i64 48
  %60 = load double, ptr %59, align 8, !tbaa !27
  %61 = fcmp une double %60, 0.000000e+00
  br i1 %61, label %98, label %45

62:                                               ; preds = %91
  %63 = add nuw nsw i64 %66, 1
  %64 = icmp eq i64 %63, %54
  br i1 %64, label %98, label %65, !llvm.loop !28

65:                                               ; preds = %62, %50
  %66 = phi i64 [ 1, %50 ], [ %63, %62 ]
  %67 = getelementptr inbounds ptr, ptr %52, i64 %66
  %68 = load ptr, ptr %67, align 8, !tbaa !18
  %69 = getelementptr inbounds i8, ptr %68, i64 32
  %70 = load i32, ptr %69, align 8, !tbaa !29
  %71 = icmp eq i32 %70, 2
  br i1 %71, label %72, label %98

72:                                               ; preds = %65
  %73 = getelementptr inbounds i8, ptr %68, i64 56
  %74 = load ptr, ptr %73, align 8, !tbaa !18
  %75 = icmp eq ptr %74, null
  br i1 %75, label %91, label %76

76:                                               ; preds = %86, %72
  %77 = phi ptr [ %89, %86 ], [ %74, %72 ]
  %78 = phi i32 [ %87, %86 ], [ 0, %72 ]
  %79 = getelementptr inbounds i8, ptr %77, i64 16
  %80 = load double, ptr %79, align 8, !tbaa !31
  %81 = fcmp oeq double %80, 1.000000e+00
  br i1 %81, label %86, label %82

82:                                               ; preds = %76
  %83 = fcmp oeq double %80, -1.000000e+00
  br i1 %83, label %84, label %98

84:                                               ; preds = %82
  %85 = add nsw i32 %78, 1
  br label %86

86:                                               ; preds = %84, %76
  %87 = phi i32 [ %78, %76 ], [ %85, %84 ]
  %88 = getelementptr inbounds i8, ptr %77, i64 32
  %89 = load ptr, ptr %88, align 8, !tbaa !18
  %90 = icmp eq ptr %89, null
  br i1 %90, label %91, label %76, !llvm.loop !33

91:                                               ; preds = %86, %72
  %92 = phi i32 [ 0, %72 ], [ %87, %86 ]
  %93 = getelementptr inbounds i8, ptr %68, i64 40
  %94 = load double, ptr %93, align 8, !tbaa !34
  %95 = sub nsw i32 1, %92
  %96 = sitofp i32 %95 to double
  %97 = fcmp une double %94, %96
  br i1 %97, label %98, label %62

98:                                               ; preds = %91, %82, %65, %62, %55, %48, %34, %30, %26, %22, %15
  %99 = phi i32 [ 2, %34 ], [ 0, %48 ], [ 5, %82 ], [ 0, %62 ], [ 6, %91 ], [ 4, %65 ], [ 3, %55 ], [ 1, %30 ], [ 1, %26 ], [ 1, %22 ], [ 1, %15 ]
  ret i32 %99
}

attributes #0 = { nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !11, i64 56}
!7 = !{!"glp_prob", !8, i64 0, !8, i64 8, !8, i64 16, !8, i64 24, !11, i64 32, !12, i64 40, !11, i64 48, !11, i64 52, !11, i64 56, !11, i64 60, !11, i64 64, !8, i64 72, !8, i64 80, !8, i64 88, !8, i64 96, !11, i64 104, !8, i64 112, !8, i64 120, !11, i64 128, !11, i64 132, !12, i64 136, !11, i64 144, !11, i64 148, !11, i64 152, !12, i64 160, !11, i64 168, !12, i64 176}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!"int", !9, i64 0}
!12 = !{!"double", !9, i64 0}
!13 = !{!7, !11, i64 60}
!14 = !{!7, !8, i64 80}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = !{!8, !8, i64 0}
!19 = !{!20, !11, i64 24}
!20 = !{!"GLPCOL", !11, i64 0, !8, i64 8, !8, i64 16, !11, i64 24, !11, i64 28, !12, i64 32, !12, i64 40, !12, i64 48, !8, i64 56, !12, i64 64, !11, i64 72, !11, i64 76, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !12, i64 112}
!21 = !{!20, !11, i64 28}
!22 = !{!20, !12, i64 32}
!23 = !{!20, !12, i64 40}
!24 = !{!7, !12, i64 40}
!25 = distinct !{!25, !16, !17}
!26 = !{!7, !8, i64 72}
!27 = !{!20, !12, i64 48}
!28 = distinct !{!28, !16, !17}
!29 = !{!30, !11, i64 32}
!30 = !{!"GLPROW", !11, i64 0, !8, i64 8, !8, i64 16, !11, i64 24, !9, i64 28, !9, i64 29, !11, i64 32, !12, i64 40, !12, i64 48, !8, i64 56, !12, i64 64, !11, i64 72, !11, i64 76, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !12, i64 112}
!31 = !{!32, !12, i64 16}
!32 = !{!"GLPAIJ", !8, i64 0, !8, i64 8, !12, i64 16, !8, i64 24, !8, i64 32, !8, i64 40, !8, i64 48}
!33 = distinct !{!33, !16, !17}
!34 = !{!30, !12, i64 40}
