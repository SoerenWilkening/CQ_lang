; ModuleID = 'dicke_n.c'
source_filename = "dicke_n.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @dicke_n(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = sub nsw i32 %0, %1
  %8 = sext i32 %7 to i64
  %9 = zext nneg i32 %0 to i64
  br label %15

10:                                               ; preds = %15, %2
  %11 = getelementptr i8, ptr %4, i64 -2
  %12 = icmp sgt i32 %0, 1
  br i1 %12, label %13, label %24

13:                                               ; preds = %10
  %14 = zext nneg i32 %0 to i64
  br label %28

15:                                               ; preds = %6, %15
  %16 = phi i64 [ 0, %6 ], [ %20, %15 ]
  %17 = icmp sge i64 %16, %8
  %18 = getelementptr inbounds i8, ptr %4, i64 %16
  %19 = zext i1 %17 to i8
  store i8 %19, ptr %18, align 1, !tbaa !6
  %20 = add nuw nsw i64 %16, 1
  %21 = icmp eq i64 %20, %9
  br i1 %21, label %10, label %15, !llvm.loop !10

22:                                               ; preds = %86, %50
  %23 = icmp sgt i64 %29, 2
  br i1 %23, label %28, label %24, !llvm.loop !13

24:                                               ; preds = %22, %10
  %25 = icmp sgt i32 %0, 0
  br i1 %25, label %26, label %93

26:                                               ; preds = %24
  %27 = zext nneg i32 %0 to i64
  br label %95

28:                                               ; preds = %13, %22
  %29 = phi i64 [ %14, %13 ], [ %30, %22 ]
  %30 = add nsw i64 %29, -1
  %31 = trunc nuw nsw i64 %30 to i32
  %32 = tail call i32 @llvm.smin.i32(i32 %31, i32 %1)
  %33 = getelementptr i8, ptr %11, i64 %29
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %35 = getelementptr inbounds i8, ptr %4, i64 %30
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %37 = icmp ne i8 %36, %34
  %38 = zext i1 %37 to i8
  store i8 %38, ptr %35, align 1, !tbaa !6
  br i1 %37, label %39, label %50

39:                                               ; preds = %28
  %40 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %41 = trunc nuw i8 %40 to i1
  %42 = trunc nuw nsw i64 %29 to i32
  %43 = uitofp nneg i32 %42 to double
  %44 = fdiv double 1.000000e+00, %43
  %45 = tail call double @llvm.sqrt.f64(double %44)
  %46 = tail call double @llvm.acos.f64(double %45)
  %47 = fmul double %46, 2.000000e+00
  %48 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %41, double noundef %47) #4
  %49 = zext i1 %48 to i8
  store i8 %49, ptr %33, align 1, !tbaa !6
  br label %50

50:                                               ; preds = %39, %28
  %51 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %52 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %53 = icmp ne i8 %52, %51
  %54 = zext i1 %53 to i8
  store i8 %54, ptr %35, align 1, !tbaa !6
  %55 = icmp slt i32 %32, 2
  br i1 %55, label %22, label %56

56:                                               ; preds = %50
  %57 = trunc nuw nsw i64 %29 to i32
  %58 = uitofp nneg i32 %57 to double
  %59 = zext nneg i32 %32 to i64
  br label %60

60:                                               ; preds = %56, %86
  %61 = phi i64 [ 2, %56 ], [ %91, %86 ]
  %62 = sub nsw i64 %30, %61
  %63 = getelementptr inbounds i8, ptr %4, i64 %62
  %64 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %65 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %66 = icmp ne i8 %65, %64
  %67 = zext i1 %66 to i8
  store i8 %67, ptr %35, align 1, !tbaa !6
  %68 = select i1 %66, i32 2, i32 0
  %69 = sub nsw i64 %29, %61
  %70 = getelementptr inbounds i8, ptr %4, i64 %69
  %71 = load i8, ptr %70, align 1, !tbaa !6, !range !14, !noundef !15
  %72 = zext nneg i8 %71 to i32
  %73 = or disjoint i32 %68, %72
  %74 = icmp eq i32 %73, 3
  br i1 %74, label %75, label %86

75:                                               ; preds = %60
  %76 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %77 = trunc nuw i8 %76 to i1
  %78 = trunc nuw nsw i64 %61 to i32
  %79 = uitofp nneg i32 %78 to double
  %80 = fdiv double %79, %58
  %81 = tail call double @llvm.sqrt.f64(double %80)
  %82 = tail call double @llvm.acos.f64(double %81)
  %83 = fmul double %82, 2.000000e+00
  %84 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %77, double noundef %83) #4
  %85 = zext i1 %84 to i8
  store i8 %85, ptr %63, align 1, !tbaa !6
  br label %86

86:                                               ; preds = %75, %60
  %87 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %88 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %89 = icmp ne i8 %88, %87
  %90 = zext i1 %89 to i8
  store i8 %90, ptr %35, align 1, !tbaa !6
  %91 = add nuw nsw i64 %61, 1
  %92 = icmp ult i64 %61, %59
  br i1 %92, label %60, label %22, !llvm.loop !16

93:                                               ; preds = %95, %24
  %94 = phi i32 [ 0, %24 ], [ %105, %95 ]
  ret i32 %94

95:                                               ; preds = %26, %95
  %96 = phi i64 [ 0, %26 ], [ %106, %95 ]
  %97 = phi i32 [ 0, %26 ], [ %105, %95 ]
  %98 = getelementptr inbounds i8, ptr %4, i64 %96
  %99 = load i8, ptr %98, align 1, !tbaa !6, !range !14, !noundef !15
  %100 = trunc nuw i8 %99 to i1
  %101 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %100) #5
  %102 = zext i1 %101 to i32
  %103 = trunc nuw nsw i64 %96 to i32
  %104 = shl nuw i32 %102, %103
  %105 = or i32 %104, %97
  %106 = add nuw nsw i64 %96, 1
  %107 = icmp eq i64 %106, %27
  br i1 %107, label %93, label %95, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
!13 = distinct !{!13, !11, !12}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
