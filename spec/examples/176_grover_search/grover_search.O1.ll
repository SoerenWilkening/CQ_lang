; ModuleID = 'grover_search.c'
source_filename = "grover_search.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @grover_search(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %0 to i64
  %5 = alloca i8, i64 %4, align 16
  %6 = icmp sgt i32 %0, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = zext nneg i32 %0 to i64
  br label %17

9:                                                ; preds = %17, %3
  %10 = icmp sgt i32 %2, 0
  br i1 %10, label %11, label %24

11:                                               ; preds = %9
  %12 = icmp sgt i32 %0, 0
  %13 = icmp sgt i32 %0, 0
  %14 = icmp sgt i32 %0, 0
  %15 = zext nneg i32 %0 to i64
  %16 = zext nneg i32 %0 to i64
  br label %28

17:                                               ; preds = %7, %17
  %18 = phi i64 [ 0, %7 ], [ %22, %17 ]
  %19 = getelementptr inbounds i8, ptr %5, i64 %18
  store i8 0, ptr %19, align 1, !tbaa !6
  %20 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #2
  %21 = zext i1 %20 to i8
  store i8 %21, ptr %19, align 1, !tbaa !6
  %22 = add nuw nsw i64 %18, 1
  %23 = icmp eq i64 %22, %8
  br i1 %23, label %9, label %17, !llvm.loop !10

24:                                               ; preds = %72, %9
  %25 = icmp sgt i32 %0, 0
  br i1 %25, label %26, label %84

26:                                               ; preds = %24
  %27 = zext nneg i32 %0 to i64
  br label %86

28:                                               ; preds = %11, %72
  %29 = phi i32 [ 0, %11 ], [ %73, %72 ]
  br i1 %12, label %30, label %41

30:                                               ; preds = %28, %30
  %31 = phi i64 [ %39, %30 ], [ 0, %28 ]
  %32 = phi i32 [ %38, %30 ], [ 0, %28 ]
  %33 = getelementptr inbounds i8, ptr %5, i64 %31
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !13, !noundef !14
  %35 = zext nneg i8 %34 to i32
  %36 = trunc nuw nsw i64 %31 to i32
  %37 = shl nuw i32 %35, %36
  %38 = or i32 %37, %32
  %39 = add nuw nsw i64 %31, 1
  %40 = icmp eq i64 %39, %4
  br i1 %40, label %41, label %30, !llvm.loop !15

41:                                               ; preds = %30, %28
  %42 = phi i32 [ 0, %28 ], [ %38, %30 ]
  %43 = icmp eq i32 %42, %1
  br i1 %43, label %44, label %45

44:                                               ; preds = %41
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %45

45:                                               ; preds = %44, %41
  br i1 %13, label %61, label %46

46:                                               ; preds = %61, %45
  br i1 %12, label %47, label %58

47:                                               ; preds = %46, %47
  %48 = phi i64 [ %56, %47 ], [ 0, %46 ]
  %49 = phi i32 [ %55, %47 ], [ 0, %46 ]
  %50 = getelementptr inbounds i8, ptr %5, i64 %48
  %51 = load i8, ptr %50, align 1, !tbaa !6, !range !13, !noundef !14
  %52 = zext nneg i8 %51 to i32
  %53 = trunc nuw nsw i64 %48 to i32
  %54 = shl nuw i32 %52, %53
  %55 = or i32 %54, %49
  %56 = add nuw nsw i64 %48, 1
  %57 = icmp eq i64 %56, %4
  br i1 %57, label %58, label %47, !llvm.loop !15

58:                                               ; preds = %47, %46
  %59 = phi i32 [ 0, %46 ], [ %55, %47 ]
  %60 = icmp eq i32 %59, 0
  br i1 %60, label %71, label %70

61:                                               ; preds = %45, %61
  %62 = phi i64 [ %68, %61 ], [ 0, %45 ]
  %63 = getelementptr inbounds i8, ptr %5, i64 %62
  %64 = load i8, ptr %63, align 1, !tbaa !6, !range !13, !noundef !14
  %65 = trunc nuw i8 %64 to i1
  %66 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %65, double noundef 0xBFF921FB54442D18) #2
  %67 = zext i1 %66 to i8
  store i8 %67, ptr %63, align 1, !tbaa !6
  %68 = add nuw nsw i64 %62, 1
  %69 = icmp eq i64 %68, %15
  br i1 %69, label %46, label %61, !llvm.loop !16

70:                                               ; preds = %58
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %71

71:                                               ; preds = %70, %58
  br i1 %14, label %75, label %72

72:                                               ; preds = %75, %71
  %73 = add nuw nsw i32 %29, 1
  %74 = icmp eq i32 %73, %2
  br i1 %74, label %24, label %28, !llvm.loop !17

75:                                               ; preds = %71, %75
  %76 = phi i64 [ %82, %75 ], [ 0, %71 ]
  %77 = getelementptr inbounds i8, ptr %5, i64 %76
  %78 = load i8, ptr %77, align 1, !tbaa !6, !range !13, !noundef !14
  %79 = trunc nuw i8 %78 to i1
  %80 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %79, double noundef 0x3FF921FB54442D18) #2
  %81 = zext i1 %80 to i8
  store i8 %81, ptr %77, align 1, !tbaa !6
  %82 = add nuw nsw i64 %76, 1
  %83 = icmp eq i64 %82, %16
  br i1 %83, label %72, label %75, !llvm.loop !18

84:                                               ; preds = %86, %24
  %85 = phi i32 [ 0, %24 ], [ %96, %86 ]
  ret i32 %85

86:                                               ; preds = %26, %86
  %87 = phi i64 [ 0, %26 ], [ %97, %86 ]
  %88 = phi i32 [ 0, %26 ], [ %96, %86 ]
  %89 = getelementptr inbounds i8, ptr %5, i64 %87
  %90 = load i8, ptr %89, align 1, !tbaa !6, !range !13, !noundef !14
  %91 = trunc nuw i8 %90 to i1
  %92 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %91) #3
  %93 = zext i1 %92 to i32
  %94 = trunc nuw nsw i64 %87 to i32
  %95 = shl nuw i32 %93, %94
  %96 = or i32 %95, %88
  %97 = add nuw nsw i64 %87, 1
  %98 = icmp eq i64 %97, %27
  br i1 %98, label %84, label %86, !llvm.loop !19
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
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
