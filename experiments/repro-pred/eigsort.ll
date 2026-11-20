; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/experiments/gsl/build/repro/eigen/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str.116 = external hidden unnamed_addr constant [34 x i8], align 1
@.str.1.117 = external hidden unnamed_addr constant [25 x i8], align 1
@.str.2.118 = external hidden unnamed_addr constant [42 x i8], align 1
@.str.4.120 = external hidden unnamed_addr constant [18 x i8], align 1

declare void @gsl_error(ptr noundef, ptr noundef, i32 noundef, i32 noundef) local_unnamed_addr #0

declare i32 @gsl_matrix_complex_swap_columns(ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #0

; Function Attrs: nounwind ssp uwtable
define noundef i32 @gsl_eigen_nonsymmv_sort(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp eq ptr %1, null
  br i1 %4, label %15, label %5

5:                                                ; preds = %3
  %6 = load i64, ptr %1, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %1, i64 8
  %8 = load i64, ptr %7, align 8, !tbaa !13
  %9 = icmp eq i64 %6, %8
  br i1 %9, label %11, label %10

10:                                               ; preds = %5
  tail call void @gsl_error(ptr noundef nonnull @.str.116, ptr noundef nonnull @.str.1.117, i32 noundef 187, i32 noundef 20) #2
  br label %93

11:                                               ; preds = %5
  %12 = load i64, ptr %0, align 8, !tbaa !14
  %13 = icmp eq i64 %12, %6
  br i1 %13, label %15, label %14

14:                                               ; preds = %11
  tail call void @gsl_error(ptr noundef nonnull @.str.2.118, ptr noundef nonnull @.str.1.117, i32 noundef 191, i32 noundef 19) #2
  br label %93

15:                                               ; preds = %11, %3
  %16 = load i64, ptr %0, align 8, !tbaa !14
  %17 = add i64 %16, -1
  %18 = getelementptr inbounds i8, ptr %0, i64 16
  %19 = getelementptr inbounds i8, ptr %0, i64 8
  br label %20

20:                                               ; preds = %91, %15
  %21 = phi i64 [ 0, %15 ], [ %24, %91 ]
  %22 = icmp eq i64 %21, %17
  br i1 %22, label %93, label %23

23:                                               ; preds = %20
  %24 = add i64 %21, 1
  %25 = icmp ult i64 %24, %16
  br i1 %25, label %26, label %83

26:                                               ; preds = %23
  %27 = load ptr, ptr %18, align 8, !tbaa !16
  %28 = shl i64 %21, 1
  %29 = load i64, ptr %19, align 8, !tbaa !17
  %30 = mul i64 %28, %29
  %31 = getelementptr inbounds double, ptr %27, i64 %30
  %32 = getelementptr inbounds i8, ptr %31, i64 8
  %33 = load double, ptr %32, align 8, !tbaa !18
  %34 = load double, ptr %31, align 8
  br label %38

35:                                               ; preds = %78
  %36 = add nuw i64 %43, 1
  %37 = icmp ult i64 %36, %16
  br i1 %37, label %38, label %83, !llvm.loop !19

38:                                               ; preds = %35, %26
  %39 = phi i1 [ %37, %35 ], [ %25, %26 ]
  %40 = phi double [ %81, %35 ], [ %34, %26 ]
  %41 = phi double [ %80, %35 ], [ %33, %26 ]
  %42 = phi i64 [ %79, %35 ], [ %21, %26 ]
  %43 = phi i64 [ %36, %35 ], [ %24, %26 ]
  %44 = load ptr, ptr %18, align 8, !tbaa !16
  %45 = shl i64 %43, 1
  %46 = load i64, ptr %19, align 8, !tbaa !17
  %47 = mul i64 %45, %46
  %48 = getelementptr inbounds double, ptr %44, i64 %47
  %49 = load double, ptr %48, align 8
  %50 = getelementptr inbounds i8, ptr %48, i64 8
  %51 = load double, ptr %50, align 8, !tbaa !18
  switch i32 %2, label %72 [
    i32 2, label %52
    i32 3, label %56
    i32 0, label %60
    i32 1, label %66
  ]

52:                                               ; preds = %38
  %53 = tail call double @gsl_complex_abs(double %49, double %51) #2
  %54 = tail call double @gsl_complex_abs(double %40, double %41) #2
  %55 = fcmp olt double %53, %54
  br label %73

56:                                               ; preds = %38
  %57 = tail call double @gsl_complex_abs(double %49, double %51) #2
  %58 = tail call double @gsl_complex_abs(double %40, double %41) #2
  %59 = fcmp ogt double %57, %58
  br label %73

60:                                               ; preds = %38
  %61 = tail call i32 @gsl_fcmp(double noundef %49, double noundef %40, double noundef 0x3CB0000000000000) #2
  %62 = icmp eq i32 %61, 0
  %63 = fcmp olt double %51, %41
  %64 = fcmp olt double %49, %40
  %65 = select i1 %62, i1 %63, i1 %64
  br label %73

66:                                               ; preds = %38
  %67 = tail call i32 @gsl_fcmp(double noundef %40, double noundef %49, double noundef 0x3CB0000000000000) #2
  %68 = icmp eq i32 %67, 0
  %69 = fcmp olt double %41, %51
  %70 = fcmp olt double %40, %49
  %71 = select i1 %68, i1 %69, i1 %70
  br label %73

72:                                               ; preds = %38
  tail call void @gsl_error(ptr noundef nonnull @.str.4.120, ptr noundef nonnull @.str.1.117, i32 noundef 226, i32 noundef 4) #2
  br label %78

73:                                               ; preds = %66, %60, %56, %52
  %74 = phi i1 [ %71, %66 ], [ %65, %60 ], [ %59, %56 ], [ %55, %52 ]
  %75 = select i1 %74, i64 %43, i64 %42
  %76 = select i1 %74, double %51, double %41
  %77 = select i1 %74, double %49, double %40
  br label %78

78:                                               ; preds = %73, %72
  %79 = phi i64 [ %42, %72 ], [ %75, %73 ]
  %80 = phi double [ %41, %72 ], [ %76, %73 ]
  %81 = phi double [ %40, %72 ], [ %77, %73 ]
  %82 = phi i1 [ false, %72 ], [ true, %73 ]
  br i1 %82, label %35, label %91

83:                                               ; preds = %35, %23
  %84 = phi i64 [ %21, %23 ], [ %79, %35 ]
  %85 = phi i1 [ %25, %23 ], [ %37, %35 ]
  %86 = icmp eq i64 %84, %21
  br i1 %86, label %91, label %87

87:                                               ; preds = %83
  %88 = tail call i32 @gsl_vector_complex_swap_elements(ptr noundef nonnull %0, i64 noundef %21, i64 noundef %84) #2
  br i1 %4, label %91, label %89

89:                                               ; preds = %87
  %90 = tail call i32 @gsl_matrix_complex_swap_columns(ptr noundef nonnull %1, i64 noundef %21, i64 noundef %84) #2
  br label %91

91:                                               ; preds = %89, %87, %83, %78
  %92 = phi i1 [ %85, %83 ], [ %85, %89 ], [ %85, %87 ], [ %39, %78 ]
  br i1 %92, label %93, label %20, !llvm.loop !22

93:                                               ; preds = %91, %20, %14, %10
  %94 = phi i32 [ 20, %10 ], [ 19, %14 ], [ 4, %91 ], [ 0, %20 ]
  ret i32 %94
}

declare double @gsl_complex_abs(double, double) local_unnamed_addr #0

declare i32 @gsl_fcmp(double noundef, double noundef, double noundef) local_unnamed_addr #0

declare i32 @gsl_vector_complex_swap_elements(ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #0

attributes #0 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !8, i64 0}
!7 = !{!"", !8, i64 0, !8, i64 8, !8, i64 16, !11, i64 24, !11, i64 32, !12, i64 40}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!"any pointer", !9, i64 0}
!12 = !{!"int", !9, i64 0}
!13 = !{!7, !8, i64 8}
!14 = !{!15, !8, i64 0}
!15 = !{!"", !8, i64 0, !8, i64 8, !11, i64 16, !11, i64 24, !12, i64 32}
!16 = !{!15, !11, i64 16}
!17 = !{!15, !8, i64 8}
!18 = !{!9, !9, i64 0}
!19 = distinct !{!19, !20, !21}
!20 = !{!"llvm.loop.mustprogress"}
!21 = !{!"llvm.loop.unroll.disable"}
!22 = distinct !{!22, !20, !21}
