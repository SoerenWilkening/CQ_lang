; ModuleID = 'complex_float_muldiv.c'
source_filename = "complex_float_muldiv.c"
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

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define <2 x float> @__divsc3(float noundef %0, float noundef %1, float noundef %2, float noundef %3) local_unnamed_addr #2 {
  %5 = tail call float @llvm.fabs.f32(float %2)
  %6 = tail call float @llvm.fabs.f32(float %3)
  %7 = tail call float @llvm.maxnum.f32(float %5, float %6)
  %8 = tail call float @logbf(float noundef %7) #6
  %9 = tail call float @llvm.fabs.f32(float %8)
  %10 = fcmp ueq float %9, 0x7FF0000000000000
  br i1 %10, label %16, label %11

11:                                               ; preds = %4
  %12 = fptosi float %8 to i32
  %13 = sub nsw i32 0, %12
  %14 = tail call float @scalbnf(float noundef %2, i32 noundef %13) #6
  %15 = tail call float @scalbnf(float noundef %3, i32 noundef %13) #6
  br label %16

16:                                               ; preds = %11, %4
  %17 = phi float [ %14, %11 ], [ %2, %4 ]
  %18 = phi float [ %15, %11 ], [ %3, %4 ]
  %19 = phi i32 [ %12, %11 ], [ 0, %4 ]
  %20 = fmul float %18, %18
  %21 = tail call float @llvm.fmuladd.f32(float %17, float %17, float %20)
  %22 = fmul float %18, %1
  %23 = tail call float @llvm.fmuladd.f32(float %0, float %17, float %22)
  %24 = fdiv float %23, %21
  %25 = sub nsw i32 0, %19
  %26 = tail call float @scalbnf(float noundef %24, i32 noundef %25) #6
  %27 = fneg float %18
  %28 = fmul float %27, %0
  %29 = tail call float @llvm.fmuladd.f32(float %1, float %17, float %28)
  %30 = fdiv float %29, %21
  %31 = tail call float @scalbnf(float noundef %30, i32 noundef %25) #6
  %32 = fcmp ord float %26, 0.000000e+00
  %33 = fcmp ord float %31, 0.000000e+00
  %34 = select i1 %32, i1 true, i1 %33
  br i1 %34, label %95, label %35

35:                                               ; preds = %16
  %36 = fcmp oeq float %21, 0.000000e+00
  br i1 %36, label %37, label %45

37:                                               ; preds = %35
  %38 = fcmp ord float %0, 0.000000e+00
  %39 = fcmp ord float %1, 0.000000e+00
  %40 = or i1 %38, %39
  br i1 %40, label %41, label %45

41:                                               ; preds = %37
  %42 = tail call float @llvm.copysign.f32(float 0x7FF0000000000000, float %17)
  %43 = fmul float %42, %0
  %44 = fmul float %42, %1
  br label %95

45:                                               ; preds = %37, %35
  %46 = tail call float @llvm.fabs.f32(float %0)
  %47 = fcmp oeq float %46, 0x7FF0000000000000
  %48 = xor i1 %47, true
  %49 = tail call float @llvm.fabs.f32(float %1)
  %50 = fcmp une float %49, 0x7FF0000000000000
  %51 = and i1 %50, %48
  %52 = tail call float @llvm.fabs.f32(float %17)
  %53 = fcmp ueq float %52, 0x7FF0000000000000
  %54 = select i1 %51, i1 true, i1 %53
  %55 = tail call float @llvm.fabs.f32(float %18)
  %56 = fcmp ueq float %55, 0x7FF0000000000000
  %57 = select i1 %54, i1 true, i1 %56
  br i1 %57, label %72, label %58

58:                                               ; preds = %45
  %59 = uitofp i1 %47 to float
  %60 = tail call float @llvm.copysign.f32(float %59, float %0)
  %61 = tail call float @llvm.fabs.f32(float %1)
  %62 = fcmp oeq float %61, 0x7FF0000000000000
  %63 = uitofp i1 %62 to float
  %64 = tail call float @llvm.copysign.f32(float %63, float %1)
  %65 = fmul float %64, %18
  %66 = tail call float @llvm.fmuladd.f32(float %60, float %17, float %65)
  %67 = fmul float %66, 0x7FF0000000000000
  %68 = fneg float %60
  %69 = fmul float %18, %68
  %70 = tail call float @llvm.fmuladd.f32(float %64, float %17, float %69)
  %71 = fmul float %70, 0x7FF0000000000000
  br label %95

72:                                               ; preds = %45
  %73 = fcmp une float %8, 0x7FF0000000000000
  %74 = fcmp ueq float %46, 0x7FF0000000000000
  %75 = or i1 %74, %73
  %76 = tail call float @llvm.fabs.f32(float %1)
  %77 = fcmp ueq float %76, 0x7FF0000000000000
  %78 = or i1 %77, %75
  br i1 %78, label %95, label %79

79:                                               ; preds = %72
  %80 = tail call float @llvm.fabs.f32(float %17)
  %81 = fcmp oeq float %80, 0x7FF0000000000000
  %82 = uitofp i1 %81 to float
  %83 = tail call float @llvm.copysign.f32(float %82, float %17)
  %84 = tail call float @llvm.fabs.f32(float %18)
  %85 = fcmp oeq float %84, 0x7FF0000000000000
  %86 = uitofp i1 %85 to float
  %87 = tail call float @llvm.copysign.f32(float %86, float %18)
  %88 = fmul float %87, %1
  %89 = tail call float @llvm.fmuladd.f32(float %0, float %83, float %88)
  %90 = fmul float %89, 0.000000e+00
  %91 = fneg float %87
  %92 = fmul float %91, %0
  %93 = tail call float @llvm.fmuladd.f32(float %1, float %83, float %92)
  %94 = fmul float %93, 0.000000e+00
  br label %95

95:                                               ; preds = %41, %72, %79, %58, %16
  %96 = phi float [ %71, %58 ], [ %94, %79 ], [ %31, %72 ], [ %44, %41 ], [ %31, %16 ]
  %97 = phi float [ %67, %58 ], [ %90, %79 ], [ %26, %72 ], [ %43, %41 ], [ %26, %16 ]
  %98 = insertelement <2 x float> poison, float %97, i64 0
  %99 = insertelement <2 x float> %98, float %96, i64 1
  ret <2 x float> %99
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @logbf(float noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fabs.f32(float) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.maxnum.f32(float, float) #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @scalbnf(float noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define float @complex_float_muldiv(float noundef %0, double noundef %1, float noundef %2, float noundef %3, float noundef %4) local_unnamed_addr #4 {
  %6 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #7
  %7 = fmul float %2, 0.000000e+00
  %8 = fadd float %7, %6
  %9 = fmul float %4, 0.000000e+00
  %10 = fadd float %9, %3
  %11 = fmul float %10, %8
  %12 = fmul float %2, %4
  %13 = fmul float %8, %4
  %14 = fmul float %10, %2
  %15 = fsub float %11, %12
  %16 = fadd float %14, %13
  %17 = fcmp uno float %15, 0.000000e+00
  br i1 %17, label %18, label %24, !prof !6

18:                                               ; preds = %5
  %19 = fcmp uno float %16, 0.000000e+00
  br i1 %19, label %20, label %24, !prof !6

20:                                               ; preds = %18
  %21 = tail call <2 x float> @__mulsc3(float noundef %8, float noundef %2, float noundef %10, float noundef %4) #8
  %22 = extractelement <2 x float> %21, i64 0
  %23 = extractelement <2 x float> %21, i64 1
  br label %24

24:                                               ; preds = %20, %18, %5
  %25 = phi float [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]
  %26 = phi float [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]
  %27 = tail call <2 x float> @__divsc3(float noundef %25, float noundef %26, float noundef %10, float noundef %4) #8
  %28 = shufflevector <2 x float> %27, <2 x float> poison, <2 x i32> <i32 1, i32 poison>
  %29 = fadd <2 x float> %27, %28
  %30 = extractelement <2 x float> %29, i64 0
  %31 = tail call float @cq_measure_f32(float noundef %30) #8
  ret float %31
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #5

declare float @cq_measure_f32(float noundef) local_unnamed_addr #5

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind willreturn memory(none) }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!"branch_weights", i32 1, i32 1048575}
