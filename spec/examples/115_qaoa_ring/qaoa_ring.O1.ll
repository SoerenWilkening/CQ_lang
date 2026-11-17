; ModuleID = 'qaoa_ring.c'
source_filename = "qaoa_ring.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @qaoa_ring(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3, i32 noundef %4, ptr nocapture noundef readonly %5, ptr nocapture noundef readonly %6) local_unnamed_addr #0 {
  %8 = zext i32 %0 to i64
  %9 = alloca i8, i64 %8, align 16
  %10 = icmp sgt i32 %0, 0
  br i1 %10, label %11, label %13

11:                                               ; preds = %7
  %12 = zext nneg i32 %0 to i64
  br label %21

13:                                               ; preds = %21, %7
  %14 = icmp sgt i32 %4, 0
  br i1 %14, label %15, label %32

15:                                               ; preds = %13
  %16 = icmp sgt i32 %1, 0
  %17 = icmp sgt i32 %0, 0
  %18 = zext nneg i32 %4 to i64
  %19 = zext nneg i32 %1 to i64
  %20 = zext nneg i32 %0 to i64
  br label %28

21:                                               ; preds = %11, %21
  %22 = phi i64 [ 0, %11 ], [ %26, %21 ]
  %23 = getelementptr inbounds i8, ptr %9, i64 %22
  store i8 0, ptr %23, align 1, !tbaa !6
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #2
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %23, align 1, !tbaa !6
  %26 = add nuw nsw i64 %22, 1
  %27 = icmp eq i64 %26, %12
  br i1 %27, label %13, label %21, !llvm.loop !10

28:                                               ; preds = %15, %58
  %29 = phi i64 [ 0, %15 ], [ %59, %58 ]
  br i1 %16, label %30, label %36

30:                                               ; preds = %28
  %31 = getelementptr inbounds double, ptr %5, i64 %29
  br label %39

32:                                               ; preds = %58, %13
  %33 = icmp sgt i32 %0, 0
  br i1 %33, label %34, label %76

34:                                               ; preds = %32
  %35 = zext nneg i32 %0 to i64
  br label %78

36:                                               ; preds = %55, %28
  br i1 %17, label %37, label %58

37:                                               ; preds = %36
  %38 = getelementptr inbounds double, ptr %6, i64 %29
  br label %61

39:                                               ; preds = %30, %55
  %40 = phi i64 [ 0, %30 ], [ %56, %55 ]
  %41 = getelementptr inbounds i32, ptr %2, i64 %40
  %42 = load i32, ptr %41, align 4, !tbaa !13
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds i8, ptr %9, i64 %43
  %45 = load i8, ptr %44, align 1, !tbaa !6, !range !15, !noundef !16
  %46 = getelementptr inbounds i32, ptr %3, i64 %40
  %47 = load i32, ptr %46, align 4, !tbaa !13
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds i8, ptr %9, i64 %48
  %50 = load i8, ptr %49, align 1, !tbaa !6, !range !15, !noundef !16
  %51 = icmp eq i8 %45, %50
  br i1 %51, label %55, label %52

52:                                               ; preds = %39
  %53 = load double, ptr %31, align 8, !tbaa !17
  %54 = fneg double %53
  tail call void @cq_phi(double noundef %54) #3
  br label %55

55:                                               ; preds = %39, %52
  %56 = add nuw nsw i64 %40, 1
  %57 = icmp eq i64 %56, %19
  br i1 %57, label %36, label %39, !llvm.loop !19

58:                                               ; preds = %73, %36
  %59 = add nuw nsw i64 %29, 1
  %60 = icmp eq i64 %59, %18
  br i1 %60, label %32, label %28, !llvm.loop !20

61:                                               ; preds = %37, %73
  %62 = phi i64 [ 0, %37 ], [ %74, %73 ]
  %63 = getelementptr inbounds i8, ptr %9, i64 %62
  %64 = load i8, ptr %63, align 1, !tbaa !6, !range !15, !noundef !16
  %65 = trunc nuw i8 %64 to i1
  br i1 %65, label %66, label %67

66:                                               ; preds = %61
  tail call void @cq_phi(double noundef 0x3FF921FB54442D18) #3
  br label %67

67:                                               ; preds = %66, %61
  %68 = load double, ptr %38, align 8, !tbaa !17
  %69 = fmul double %68, 2.000000e+00
  %70 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %65, double noundef %69) #2
  %71 = zext i1 %70 to i8
  store i8 %71, ptr %63, align 1, !tbaa !6
  br i1 %70, label %72, label %73

72:                                               ; preds = %67
  tail call void @cq_phi(double noundef 0xBFF921FB54442D18) #3
  br label %73

73:                                               ; preds = %67, %72
  %74 = add nuw nsw i64 %62, 1
  %75 = icmp eq i64 %74, %20
  br i1 %75, label %58, label %61, !llvm.loop !21

76:                                               ; preds = %78, %32
  %77 = phi i32 [ 0, %32 ], [ %88, %78 ]
  ret i32 %77

78:                                               ; preds = %34, %78
  %79 = phi i64 [ 0, %34 ], [ %89, %78 ]
  %80 = phi i32 [ 0, %34 ], [ %88, %78 ]
  %81 = getelementptr inbounds i8, ptr %9, i64 %79
  %82 = load i8, ptr %81, align 1, !tbaa !6, !range !15, !noundef !16
  %83 = trunc nuw i8 %82 to i1
  %84 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %83) #3
  %85 = zext i1 %84 to i32
  %86 = trunc nuw nsw i64 %79 to i32
  %87 = shl nuw i32 %85, %86
  %88 = or i32 %87, %80
  %89 = add nuw nsw i64 %79, 1
  %90 = icmp eq i64 %89, %35
  br i1 %90, label %76, label %78, !llvm.loop !22
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !8, i64 0}
!15 = !{i8 0, i8 2}
!16 = !{}
!17 = !{!18, !18, i64 0}
!18 = !{!"double", !8, i64 0}
!19 = distinct !{!19, !11, !12}
!20 = distinct !{!20, !11, !12}
!21 = distinct !{!21, !11, !12}
!22 = distinct !{!22, !11, !12}
