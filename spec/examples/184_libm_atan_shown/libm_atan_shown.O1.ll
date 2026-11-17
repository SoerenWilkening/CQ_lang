; ModuleID = 'libm_atan_shown.c'
source_filename = "libm_atan_shown.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@atanhi = internal unnamed_addr constant [4 x double] [double 0x3FDDAC670561BB4F, double 0x3FE921FB54442D18, double 0x3FEF730BD281F69B, double 0x3FF921FB54442D18], align 16
@atanlo = internal unnamed_addr constant [4 x double] [double 0x3C7A2B7F222F65E2, double 0x3C81A62633145C07, double 0x3C7007887AF0CBBD, double 0x3C91A62633145C07], align 16

; Function Attrs: nounwind ssp uwtable
define double @libm_atan_shown(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %5 = bitcast double %4 to i64
  %6 = lshr i64 %5, 32
  %7 = trunc nuw i64 %6 to i32
  %8 = and i32 %7, 2147483647
  %9 = icmp ugt i32 %8, 1141899263
  br i1 %9, label %10, label %14

10:                                               ; preds = %3
  %11 = fcmp uno double %4, 0.000000e+00
  br i1 %11, label %72, label %12

12:                                               ; preds = %10
  %13 = tail call double @llvm.copysign.f64(double 0x3FF921FB54442D18, double %4)
  br label %72

14:                                               ; preds = %3
  %15 = icmp ult i32 %8, 1071382528
  br i1 %15, label %16, label %18

16:                                               ; preds = %14
  %17 = icmp ult i32 %8, 1044381696
  br i1 %17, label %72, label %39

18:                                               ; preds = %14
  %19 = tail call double @llvm.fabs.f64(double %4)
  %20 = icmp ult i32 %8, 1072889856
  br i1 %20, label %21, label %31

21:                                               ; preds = %18
  %22 = icmp ult i32 %8, 1072037888
  br i1 %22, label %23, label %27

23:                                               ; preds = %21
  %24 = tail call double @llvm.fmuladd.f64(double %19, double 2.000000e+00, double -1.000000e+00)
  %25 = fadd double %19, 2.000000e+00
  %26 = fdiv double %24, %25
  br label %39

27:                                               ; preds = %21
  %28 = fadd double %19, -1.000000e+00
  %29 = fadd double %19, 1.000000e+00
  %30 = fdiv double %28, %29
  br label %39

31:                                               ; preds = %18
  %32 = icmp ult i32 %8, 1073971200
  br i1 %32, label %33, label %37

33:                                               ; preds = %31
  %34 = fadd double %19, -1.500000e+00
  %35 = tail call double @llvm.fmuladd.f64(double %19, double 1.500000e+00, double 1.000000e+00)
  %36 = fdiv double %34, %35
  br label %39

37:                                               ; preds = %31
  %38 = fdiv double -1.000000e+00, %19
  br label %39

39:                                               ; preds = %37, %33, %27, %23, %16
  %40 = phi double [ %26, %23 ], [ %30, %27 ], [ %36, %33 ], [ %38, %37 ], [ %4, %16 ]
  %41 = phi i64 [ 0, %23 ], [ 1, %27 ], [ 2, %33 ], [ 3, %37 ], [ 4294967295, %16 ]
  %42 = fmul double %40, %40
  %43 = fmul double %42, %42
  %44 = tail call double @llvm.fmuladd.f64(double %43, double 0x3F90AD3AE322DA11, double 0x3FA97B4B24760DEB)
  %45 = tail call double @llvm.fmuladd.f64(double %43, double %44, double 0x3FB10D66A0D03D51)
  %46 = tail call double @llvm.fmuladd.f64(double %43, double %45, double 0x3FB745CDC54C206E)
  %47 = tail call double @llvm.fmuladd.f64(double %43, double %46, double 0x3FC24924920083FF)
  %48 = tail call double @llvm.fmuladd.f64(double %43, double %47, double 0x3FD555555555550D)
  %49 = fmul double %42, %48
  %50 = tail call double @llvm.fmuladd.f64(double %43, double 0xBFA2B4442C6A6C2F, double 0xBFADDE2D52DEFD9A)
  %51 = tail call double @llvm.fmuladd.f64(double %43, double %50, double 0xBFB3B0F2AF749A6D)
  %52 = tail call double @llvm.fmuladd.f64(double %43, double %51, double 0xBFBC71C6FE231671)
  %53 = tail call double @llvm.fmuladd.f64(double %43, double %52, double 0xBFC999999998EBC4)
  %54 = fmul double %43, %53
  br i1 %15, label %55, label %59

55:                                               ; preds = %39
  %56 = fadd double %54, %49
  %57 = fneg double %40
  %58 = tail call double @llvm.fmuladd.f64(double %57, double %56, double %40)
  br label %72

59:                                               ; preds = %39
  %60 = getelementptr inbounds [4 x double], ptr @atanhi, i64 0, i64 %41
  %61 = load double, ptr %60, align 8, !tbaa !6
  %62 = fadd double %54, %49
  %63 = getelementptr inbounds [4 x double], ptr @atanlo, i64 0, i64 %41
  %64 = load double, ptr %63, align 8, !tbaa !6
  %65 = fneg double %64
  %66 = tail call double @llvm.fmuladd.f64(double %40, double %62, double %65)
  %67 = fsub double %66, %40
  %68 = fsub double %61, %67
  %69 = fneg double %68
  %70 = icmp slt i64 %5, 0
  %71 = select i1 %70, double %69, double %68
  br label %72

72:                                               ; preds = %10, %12, %16, %55, %59
  %73 = phi double [ %13, %12 ], [ %58, %55 ], [ %71, %59 ], [ %4, %10 ], [ %4, %16 ]
  %74 = fmul double %73, %2
  %75 = tail call double @cq_measure_f64(double noundef %74) #5
  ret double %75
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #3

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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
