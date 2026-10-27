; ModuleID = 'qpe_counting.c'
source_filename = "qpe_counting.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @qpe_counting(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = zext i32 %1 to i64
  %6 = alloca i8, i64 %5, align 16
  %7 = zext i32 %0 to i64
  %8 = alloca i8, i64 %7, align 16
  %9 = icmp sgt i32 %1, 0
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = zext nneg i32 %1 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %6, i8 0, i64 %11, i1 false), !tbaa !6
  br label %12

12:                                               ; preds = %10, %4
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %16

14:                                               ; preds = %12
  %15 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %8, i8 0, i64 %15, i1 false), !tbaa !6
  br label %16

16:                                               ; preds = %14, %12
  %17 = icmp sgt i32 %1, 0
  br i1 %17, label %18, label %20

18:                                               ; preds = %16
  %19 = zext nneg i32 %1 to i64
  br label %24

20:                                               ; preds = %24, %16
  %21 = icmp sgt i32 %0, 0
  br i1 %21, label %22, label %33

22:                                               ; preds = %20
  %23 = zext nneg i32 %0 to i64
  br label %37

24:                                               ; preds = %18, %24
  %25 = phi i64 [ 0, %18 ], [ %31, %24 ]
  %26 = getelementptr inbounds i8, ptr %6, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef 0x3FF921FB54442D18) #5
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  %31 = add nuw nsw i64 %25, 1
  %32 = icmp eq i64 %31, %19
  br i1 %32, label %20, label %24, !llvm.loop !12

33:                                               ; preds = %37, %20
  %34 = icmp sgt i32 %1, 0
  br i1 %34, label %35, label %56

35:                                               ; preds = %33
  %36 = zext nneg i32 %1 to i64
  br label %46

37:                                               ; preds = %22, %37
  %38 = phi i64 [ 0, %22 ], [ %44, %37 ]
  %39 = getelementptr inbounds i8, ptr %8, i64 %38
  %40 = load i8, ptr %39, align 1, !tbaa !6, !range !10, !noundef !11
  %41 = trunc nuw i8 %40 to i1
  %42 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %41, double noundef 0x3FF921FB54442D18) #5
  %43 = zext i1 %42 to i8
  store i8 %43, ptr %39, align 1, !tbaa !6
  %44 = add nuw nsw i64 %38, 1
  %45 = icmp eq i64 %44, %23
  br i1 %45, label %33, label %37, !llvm.loop !15

46:                                               ; preds = %35, %62
  %47 = phi i64 [ 0, %35 ], [ %63, %62 ]
  %48 = icmp eq i64 %47, 31
  br i1 %48, label %62, label %49

49:                                               ; preds = %46
  %50 = trunc nuw nsw i64 %47 to i32
  %51 = shl nuw i32 1, %50
  %52 = getelementptr inbounds i8, ptr %6, i64 %47
  %53 = load i8, ptr %52, align 1, !tbaa !6, !range !10, !noundef !11
  %54 = trunc nuw i8 %53 to i1
  %55 = tail call i32 @llvm.smax.i32(i32 %51, i32 1)
  br label %65

56:                                               ; preds = %62, %33
  %57 = add i32 %1, -1
  %58 = icmp sgt i32 %1, 0
  br i1 %58, label %59, label %77

59:                                               ; preds = %56
  %60 = zext i32 %57 to i64
  %61 = sext i32 %57 to i64
  br label %71

62:                                               ; preds = %68, %46
  %63 = add nuw nsw i64 %47, 1
  %64 = icmp eq i64 %63, %36
  br i1 %64, label %56, label %46, !llvm.loop !16

65:                                               ; preds = %49, %68
  %66 = phi i32 [ 0, %49 ], [ %69, %68 ]
  br i1 %54, label %67, label %68

67:                                               ; preds = %65
  call fastcc void @grover(ptr noundef nonnull %8, i32 noundef %0, ptr noundef %2, i32 noundef %3)
  br label %68

68:                                               ; preds = %65, %67
  %69 = add nuw nsw i32 %66, 1
  %70 = icmp eq i32 %69, %55
  br i1 %70, label %62, label %65, !llvm.loop !17

71:                                               ; preds = %59, %104
  %72 = phi i64 [ %60, %59 ], [ %107, %104 ]
  %73 = icmp slt i64 %72, %61
  br i1 %73, label %74, label %81

74:                                               ; preds = %71
  %75 = getelementptr inbounds i8, ptr %6, i64 %72
  %76 = trunc nuw nsw i64 %72 to i32
  br label %85

77:                                               ; preds = %104, %56
  %78 = icmp sgt i32 %1, 0
  br i1 %78, label %79, label %109

79:                                               ; preds = %77
  %80 = zext nneg i32 %1 to i64
  br label %111

81:                                               ; preds = %99, %71
  %82 = getelementptr inbounds i8, ptr %6, i64 %72
  %83 = load i8, ptr %82, align 1, !tbaa !6, !range !10, !noundef !11
  %84 = trunc nuw i8 %83 to i1
  br i1 %84, label %103, label %104

85:                                               ; preds = %74, %99
  %86 = phi i32 [ %57, %74 ], [ %100, %99 ]
  %87 = zext nneg i32 %86 to i64
  %88 = getelementptr inbounds i8, ptr %6, i64 %87
  %89 = load i8, ptr %88, align 1, !tbaa !6, !range !10, !noundef !11
  %90 = trunc nuw i8 %89 to i1
  br i1 %90, label %91, label %99

91:                                               ; preds = %85
  %92 = load i8, ptr %75, align 1, !tbaa !6, !range !10, !noundef !11
  %93 = trunc nuw i8 %92 to i1
  br i1 %93, label %94, label %99

94:                                               ; preds = %91
  %95 = sub nsw i32 %86, %76
  %96 = shl nuw i32 1, %95
  %97 = sitofp i32 %96 to double
  %98 = fdiv double 0xC00921FB54442D18, %97
  tail call void @cq_phi(double noundef %98) #6
  br label %99

99:                                               ; preds = %85, %91, %94
  %100 = add nsw i32 %86, -1
  %101 = sext i32 %100 to i64
  %102 = icmp slt i64 %72, %101
  br i1 %102, label %85, label %81, !llvm.loop !18

103:                                              ; preds = %81
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %104

104:                                              ; preds = %103, %81
  %105 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %84, double noundef 0x3FF921FB54442D18) #5
  %106 = zext i1 %105 to i8
  store i8 %106, ptr %82, align 1, !tbaa !6
  %107 = add nsw i64 %72, -1
  %108 = icmp sgt i64 %72, 0
  br i1 %108, label %71, label %77, !llvm.loop !19

109:                                              ; preds = %111, %77
  %110 = phi i32 [ 0, %77 ], [ %122, %111 ]
  ret i32 %110

111:                                              ; preds = %79, %111
  %112 = phi i64 [ 0, %79 ], [ %123, %111 ]
  %113 = phi i32 [ 0, %79 ], [ %122, %111 ]
  %114 = getelementptr inbounds i8, ptr %6, i64 %112
  %115 = load i8, ptr %114, align 1, !tbaa !6, !range !10, !noundef !11
  %116 = trunc nuw i8 %115 to i1
  %117 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %116) #6
  %118 = zext i1 %117 to i32
  %119 = trunc i64 %112 to i32
  %120 = sub i32 %57, %119
  %121 = shl nuw i32 %118, %120
  %122 = or i32 %121, %113
  %123 = add nuw nsw i64 %112, 1
  %124 = icmp eq i64 %123, %80
  br i1 %124, label %109, label %111, !llvm.loop !20
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @grover(ptr nocapture noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) unnamed_addr #2 {
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %19

6:                                                ; preds = %4
  %7 = zext nneg i32 %1 to i64
  br label %8

8:                                                ; preds = %8, %6
  %9 = phi i64 [ 0, %6 ], [ %17, %8 ]
  %10 = phi i32 [ 0, %6 ], [ %16, %8 ]
  %11 = getelementptr inbounds i8, ptr %0, i64 %9
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = zext nneg i8 %12 to i32
  %14 = trunc nuw nsw i64 %9 to i32
  %15 = shl nuw i32 %13, %14
  %16 = or i32 %15, %10
  %17 = add nuw nsw i64 %9, 1
  %18 = icmp eq i64 %17, %7
  br i1 %18, label %19, label %8, !llvm.loop !21

19:                                               ; preds = %8, %4
  %20 = phi i32 [ 0, %4 ], [ %16, %8 ]
  %21 = icmp sgt i32 %3, 0
  br i1 %21, label %22, label %36

22:                                               ; preds = %19
  %23 = zext nneg i32 %3 to i64
  %24 = load i32, ptr %2, align 4, !tbaa !22
  %25 = icmp eq i32 %24, %20
  br i1 %25, label %38, label %26

26:                                               ; preds = %22, %30
  %27 = phi i64 [ %28, %30 ], [ 0, %22 ]
  %28 = add nuw nsw i64 %27, 1
  %29 = icmp eq i64 %28, %23
  br i1 %29, label %34, label %30, !llvm.loop !24

30:                                               ; preds = %26
  %31 = getelementptr inbounds i32, ptr %2, i64 %28
  %32 = load i32, ptr %31, align 4, !tbaa !22
  %33 = icmp eq i32 %32, %20
  br i1 %33, label %34, label %26, !llvm.loop !24

34:                                               ; preds = %26, %30
  %35 = icmp ult i64 %28, %23
  br label %36

36:                                               ; preds = %34, %19
  %37 = phi i1 [ %21, %19 ], [ %35, %34 ]
  br i1 %37, label %38, label %39

38:                                               ; preds = %22, %36
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %39

39:                                               ; preds = %38, %36
  %40 = icmp sgt i32 %1, 0
  br i1 %40, label %41, label %43

41:                                               ; preds = %39
  %42 = zext nneg i32 %1 to i64
  br label %59

43:                                               ; preds = %59, %39
  br i1 %5, label %44, label %69

44:                                               ; preds = %43
  %45 = zext nneg i32 %1 to i64
  br label %46

46:                                               ; preds = %46, %44
  %47 = phi i64 [ 0, %44 ], [ %55, %46 ]
  %48 = phi i32 [ 0, %44 ], [ %54, %46 ]
  %49 = getelementptr inbounds i8, ptr %0, i64 %47
  %50 = load i8, ptr %49, align 1, !tbaa !6, !range !10, !noundef !11
  %51 = zext nneg i8 %50 to i32
  %52 = trunc nuw nsw i64 %47 to i32
  %53 = shl nuw i32 %51, %52
  %54 = or i32 %53, %48
  %55 = add nuw nsw i64 %47, 1
  %56 = icmp eq i64 %55, %45
  br i1 %56, label %57, label %46, !llvm.loop !21

57:                                               ; preds = %46
  %58 = icmp eq i32 %54, 0
  br i1 %58, label %69, label %68

59:                                               ; preds = %41, %59
  %60 = phi i64 [ 0, %41 ], [ %66, %59 ]
  %61 = getelementptr inbounds i8, ptr %0, i64 %60
  %62 = load i8, ptr %61, align 1, !tbaa !6, !range !10, !noundef !11
  %63 = trunc nuw i8 %62 to i1
  %64 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %63, double noundef 0xBFF921FB54442D18) #5
  %65 = zext i1 %64 to i8
  store i8 %65, ptr %61, align 1, !tbaa !6
  %66 = add nuw nsw i64 %60, 1
  %67 = icmp eq i64 %66, %42
  br i1 %67, label %43, label %59, !llvm.loop !25

68:                                               ; preds = %57
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %69

69:                                               ; preds = %43, %68, %57
  %70 = icmp sgt i32 %1, 0
  br i1 %70, label %71, label %73

71:                                               ; preds = %69
  %72 = zext nneg i32 %1 to i64
  br label %74

73:                                               ; preds = %74, %69
  ret void

74:                                               ; preds = %71, %74
  %75 = phi i64 [ 0, %71 ], [ %81, %74 ]
  %76 = getelementptr inbounds i8, ptr %0, i64 %75
  %77 = load i8, ptr %76, align 1, !tbaa !6, !range !10, !noundef !11
  %78 = trunc nuw i8 %77 to i1
  %79 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %78, double noundef 0x3FF921FB54442D18) #5
  %80 = zext i1 %79 to i8
  store i8 %80, ptr %76, align 1, !tbaa !6
  %81 = add nuw nsw i64 %75, 1
  %82 = icmp eq i64 %81, %72
  br i1 %82, label %73, label %74, !llvm.loop !26
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}
!21 = distinct !{!21, !13, !14}
!22 = !{!23, !23, i64 0}
!23 = !{!"int", !8, i64 0}
!24 = distinct !{!24, !13, !14}
!25 = distinct !{!25, !13, !14}
!26 = distinct !{!26, !13, !14}
