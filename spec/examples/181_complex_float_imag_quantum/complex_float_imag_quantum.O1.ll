; ModuleID = 'complex_float_imag_quantum.c'
source_filename = "complex_float_imag_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define <2 x float> @__mulsc3(float noundef %0, float noundef %1, float noundef %2, float noundef %3) local_unnamed_addr #0 {
  %5 = fmul float %0, %2
  %6 = fmul float %1, %3
  %7 = fmul float %0, %3
  %8 = fmul float %1, %2
  %9 = fsub float %5, %6
  %10 = fadd float %8, %7
  %11 = fcmp ord float %9, 0.000000e+00
  %12 = fcmp ord float %10, 0.000000e+00
  %13 = or i1 %11, %12
  br i1 %13, label %103, label %14

14:                                               ; preds = %4
  %15 = tail call float @llvm.fabs.f32(float %0)
  %16 = fcmp oeq float %15, 0x7FF0000000000000
  %17 = tail call float @llvm.fabs.f32(float %1)
  %18 = fcmp oeq float %17, 0x7FF0000000000000
  %19 = or i1 %18, %16
  br i1 %19, label %20, label %33

20:                                               ; preds = %14
  %21 = uitofp i1 %16 to float
  %22 = tail call float @llvm.copysign.f32(float %21, float %0)
  %23 = tail call float @llvm.fabs.f32(float %1)
  %24 = fcmp oeq float %23, 0x7FF0000000000000
  %25 = uitofp i1 %24 to float
  %26 = tail call float @llvm.copysign.f32(float %25, float %1)
  %27 = fcmp ord float %2, 0.000000e+00
  %28 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %2)
  %29 = select i1 %27, float %2, float %28
  %30 = fcmp ord float %3, 0.000000e+00
  %31 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %3)
  %32 = select i1 %30, float %3, float %31
  br label %33

33:                                               ; preds = %14, %20
  %34 = phi float [ %32, %20 ], [ %3, %14 ]
  %35 = phi float [ %29, %20 ], [ %2, %14 ]
  %36 = phi float [ %26, %20 ], [ %1, %14 ]
  %37 = phi float [ %22, %20 ], [ %0, %14 ]
  %38 = phi i32 [ 1, %20 ], [ 0, %14 ]
  %39 = tail call float @llvm.fabs.f32(float %35)
  %40 = fcmp oeq float %39, 0x7FF0000000000000
  %41 = tail call float @llvm.fabs.f32(float %34)
  %42 = fcmp oeq float %41, 0x7FF0000000000000
  %43 = or i1 %42, %40
  br i1 %43, label %44, label %57

44:                                               ; preds = %33
  %45 = uitofp i1 %40 to float
  %46 = tail call float @llvm.copysign.f32(float %45, float %35)
  %47 = tail call float @llvm.fabs.f32(float %34)
  %48 = fcmp oeq float %47, 0x7FF0000000000000
  %49 = uitofp i1 %48 to float
  %50 = tail call float @llvm.copysign.f32(float %49, float %34)
  %51 = fcmp ord float %37, 0.000000e+00
  %52 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %37)
  %53 = select i1 %51, float %37, float %52
  %54 = fcmp ord float %36, 0.000000e+00
  %55 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %36)
  %56 = select i1 %54, float %36, float %55
  br label %57

57:                                               ; preds = %33, %44
  %58 = phi float [ %50, %44 ], [ %34, %33 ]
  %59 = phi float [ %46, %44 ], [ %35, %33 ]
  %60 = phi float [ %56, %44 ], [ %36, %33 ]
  %61 = phi float [ %53, %44 ], [ %37, %33 ]
  %62 = phi i32 [ 1, %44 ], [ %38, %33 ]
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %64, label %89

64:                                               ; preds = %57
  %65 = tail call float @llvm.fabs.f32(float %5)
  %66 = fcmp une float %65, 0x7FF0000000000000
  %67 = tail call float @llvm.fabs.f32(float %6)
  %68 = fcmp une float %67, 0x7FF0000000000000
  %69 = and i1 %66, %68
  %70 = tail call float @llvm.fabs.f32(float %7)
  %71 = fcmp une float %70, 0x7FF0000000000000
  %72 = and i1 %71, %69
  %73 = tail call float @llvm.fabs.f32(float %8)
  %74 = fcmp une float %73, 0x7FF0000000000000
  %75 = and i1 %74, %72
  br i1 %75, label %89, label %76

76:                                               ; preds = %64
  %77 = fcmp ord float %61, 0.000000e+00
  %78 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %61)
  %79 = select i1 %77, float %61, float %78
  %80 = fcmp ord float %60, 0.000000e+00
  %81 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %60)
  %82 = select i1 %80, float %60, float %81
  %83 = fcmp ord float %59, 0.000000e+00
  %84 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %59)
  %85 = select i1 %83, float %59, float %84
  %86 = fcmp ord float %58, 0.000000e+00
  %87 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %58)
  %88 = select i1 %86, float %58, float %87
  br label %89

89:                                               ; preds = %64, %76, %57
  %90 = phi float [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]
  %91 = phi float [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %92 = phi float [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %93 = phi float [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ]
  br i1 %94, label %103, label %95

95:                                               ; preds = %89
  %96 = fneg float %92
  %97 = fmul float %90, %96
  %98 = tail call float @llvm.fmuladd.f32(float %93, float %91, float %97)
  %99 = fmul float %98, 0x7FF0000000000000
  %100 = fmul float %91, %92
  %101 = tail call float @llvm.fmuladd.f32(float %93, float %90, float %100)
  %102 = fmul float %101, 0x7FF0000000000000
  br label %103

103:                                              ; preds = %89, %95, %4
  %104 = phi float [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]
  %105 = phi float [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]
  %106 = insertelement <2 x float> poison, float %105, i64 0
  %107 = insertelement <2 x float> %106, float %104, i64 1
  ret <2 x float> %107
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.copysign.f32(float, float) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: nounwind ssp uwtable
define float @complex_float_imag_quantum(float noundef %0, float noundef %1, double noundef %2, float noundef %3, float noundef %4) local_unnamed_addr #2 {
  %6 = tail call float @cq_theta_f32(float noundef %1, double noundef %2) #4
  %7 = fmul float %6, 0.000000e+00
  %8 = fadd float %7, %0
  %9 = fmul float %4, 0.000000e+00
  %10 = fadd float %9, %3
  %11 = fmul float %10, %8
  %12 = fmul float %6, %4
  %13 = fmul float %8, %4
  %14 = fmul float %10, %6
  %15 = fsub float %11, %12
  %16 = fadd float %14, %13
  %17 = fcmp uno float %15, 0.000000e+00
  br i1 %17, label %18, label %24, !prof !6

18:                                               ; preds = %5
  %19 = fcmp uno float %16, 0.000000e+00
  br i1 %19, label %20, label %24, !prof !6

20:                                               ; preds = %18
  %21 = tail call <2 x float> @__mulsc3(float noundef %8, float noundef %6, float noundef %10, float noundef %4) #5
  %22 = extractelement <2 x float> %21, i64 0
  %23 = extractelement <2 x float> %21, i64 1
  br label %24

24:                                               ; preds = %20, %18, %5
  %25 = phi float [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]
  %26 = phi float [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]
  %27 = fadd float %6, %4
  %28 = fadd float %10, %8
  %29 = fadd float %27, %28
  %30 = fadd float %29, %25
  %31 = fadd float %30, %26
  %32 = tail call float @cq_measure_f32(float noundef %31) #5
  ret float %32
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #3

declare float @cq_measure_f32(float noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fabs.f32(float) #1

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!"branch_weights", i32 1, i32 1048575}
