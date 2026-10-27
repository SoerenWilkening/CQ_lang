; ModuleID = 'complex_ldouble_muldiv.c'
source_filename = "complex_ldouble_muldiv.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define { x86_fp80, x86_fp80 } @__mulxc3(x86_fp80 noundef %0, x86_fp80 noundef %1, x86_fp80 noundef %2, x86_fp80 noundef %3) local_unnamed_addr #0 {
  %5 = fmul x86_fp80 %0, %2
  %6 = fmul x86_fp80 %1, %3
  %7 = fmul x86_fp80 %0, %3
  %8 = fmul x86_fp80 %1, %2
  %9 = fsub x86_fp80 %5, %6
  %10 = fadd x86_fp80 %8, %7
  %11 = fcmp ord x86_fp80 %9, 0xK00000000000000000000
  %12 = fcmp ord x86_fp80 %10, 0xK00000000000000000000
  %13 = or i1 %11, %12
  br i1 %13, label %103, label %14

14:                                               ; preds = %4
  %15 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %0)
  %16 = fcmp oeq x86_fp80 %15, 0xK7FFF8000000000000000
  %17 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %18 = fcmp oeq x86_fp80 %17, 0xK7FFF8000000000000000
  %19 = or i1 %18, %16
  br i1 %19, label %20, label %33

20:                                               ; preds = %14
  %21 = uitofp i1 %16 to x86_fp80
  %22 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %21, x86_fp80 %0)
  %23 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %24 = fcmp oeq x86_fp80 %23, 0xK7FFF8000000000000000
  %25 = uitofp i1 %24 to x86_fp80
  %26 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %25, x86_fp80 %1)
  %27 = fcmp ord x86_fp80 %2, 0xK00000000000000000000
  %28 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %2)
  %29 = select i1 %27, x86_fp80 %2, x86_fp80 %28
  %30 = fcmp ord x86_fp80 %3, 0xK00000000000000000000
  %31 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %3)
  %32 = select i1 %30, x86_fp80 %3, x86_fp80 %31
  br label %33

33:                                               ; preds = %14, %20
  %34 = phi x86_fp80 [ %32, %20 ], [ %3, %14 ]
  %35 = phi x86_fp80 [ %29, %20 ], [ %2, %14 ]
  %36 = phi x86_fp80 [ %26, %20 ], [ %1, %14 ]
  %37 = phi x86_fp80 [ %22, %20 ], [ %0, %14 ]
  %38 = phi i32 [ 1, %20 ], [ 0, %14 ]
  %39 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %35)
  %40 = fcmp oeq x86_fp80 %39, 0xK7FFF8000000000000000
  %41 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %34)
  %42 = fcmp oeq x86_fp80 %41, 0xK7FFF8000000000000000
  %43 = or i1 %42, %40
  br i1 %43, label %44, label %57

44:                                               ; preds = %33
  %45 = uitofp i1 %40 to x86_fp80
  %46 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %45, x86_fp80 %35)
  %47 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %34)
  %48 = fcmp oeq x86_fp80 %47, 0xK7FFF8000000000000000
  %49 = uitofp i1 %48 to x86_fp80
  %50 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %49, x86_fp80 %34)
  %51 = fcmp ord x86_fp80 %37, 0xK00000000000000000000
  %52 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %37)
  %53 = select i1 %51, x86_fp80 %37, x86_fp80 %52
  %54 = fcmp ord x86_fp80 %36, 0xK00000000000000000000
  %55 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %36)
  %56 = select i1 %54, x86_fp80 %36, x86_fp80 %55
  br label %57

57:                                               ; preds = %33, %44
  %58 = phi x86_fp80 [ %50, %44 ], [ %34, %33 ]
  %59 = phi x86_fp80 [ %46, %44 ], [ %35, %33 ]
  %60 = phi x86_fp80 [ %56, %44 ], [ %36, %33 ]
  %61 = phi x86_fp80 [ %53, %44 ], [ %37, %33 ]
  %62 = phi i32 [ 1, %44 ], [ %38, %33 ]
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %64, label %89

64:                                               ; preds = %57
  %65 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %5)
  %66 = fcmp une x86_fp80 %65, 0xK7FFF8000000000000000
  %67 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %6)
  %68 = fcmp une x86_fp80 %67, 0xK7FFF8000000000000000
  %69 = and i1 %66, %68
  %70 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %7)
  %71 = fcmp une x86_fp80 %70, 0xK7FFF8000000000000000
  %72 = and i1 %71, %69
  %73 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %8)
  %74 = fcmp une x86_fp80 %73, 0xK7FFF8000000000000000
  %75 = and i1 %74, %72
  br i1 %75, label %89, label %76

76:                                               ; preds = %64
  %77 = fcmp ord x86_fp80 %61, 0xK00000000000000000000
  %78 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %61)
  %79 = select i1 %77, x86_fp80 %61, x86_fp80 %78
  %80 = fcmp ord x86_fp80 %60, 0xK00000000000000000000
  %81 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %60)
  %82 = select i1 %80, x86_fp80 %60, x86_fp80 %81
  %83 = fcmp ord x86_fp80 %59, 0xK00000000000000000000
  %84 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %59)
  %85 = select i1 %83, x86_fp80 %59, x86_fp80 %84
  %86 = fcmp ord x86_fp80 %58, 0xK00000000000000000000
  %87 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %58)
  %88 = select i1 %86, x86_fp80 %58, x86_fp80 %87
  br label %89

89:                                               ; preds = %64, %76, %57
  %90 = phi x86_fp80 [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]
  %91 = phi x86_fp80 [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %92 = phi x86_fp80 [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %93 = phi x86_fp80 [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ]
  br i1 %94, label %103, label %95

95:                                               ; preds = %89
  %96 = fneg x86_fp80 %92
  %97 = fmul x86_fp80 %90, %96
  %98 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %93, x86_fp80 %91, x86_fp80 %97)
  %99 = fmul x86_fp80 %98, 0xK7FFF8000000000000000
  %100 = fmul x86_fp80 %91, %92
  %101 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %93, x86_fp80 %90, x86_fp80 %100)
  %102 = fmul x86_fp80 %101, 0xK7FFF8000000000000000
  br label %103

103:                                              ; preds = %89, %95, %4
  %104 = phi x86_fp80 [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]
  %105 = phi x86_fp80 [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]
  %106 = insertvalue { x86_fp80, x86_fp80 } poison, x86_fp80 %105, 0
  %107 = insertvalue { x86_fp80, x86_fp80 } %106, x86_fp80 %104, 1
  ret { x86_fp80, x86_fp80 } %107
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.copysign.f80(x86_fp80, x86_fp80) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80) #1

; Function Attrs: mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable
define { x86_fp80, x86_fp80 } @__divxc3(x86_fp80 noundef %0, x86_fp80 noundef %1, x86_fp80 noundef %2, x86_fp80 noundef %3) local_unnamed_addr #2 {
  %5 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %2)
  %6 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %3)
  %7 = tail call x86_fp80 @llvm.maxnum.f80(x86_fp80 %5, x86_fp80 %6)
  %8 = tail call x86_fp80 @logbl(x86_fp80 noundef %7) #6
  %9 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %8)
  %10 = fcmp ueq x86_fp80 %9, 0xK7FFF8000000000000000
  br i1 %10, label %16, label %11

11:                                               ; preds = %4
  %12 = fptosi x86_fp80 %8 to i32
  %13 = sub nsw i32 0, %12
  %14 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %2, i32 noundef %13) #6
  %15 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %3, i32 noundef %13) #6
  br label %16

16:                                               ; preds = %11, %4
  %17 = phi i32 [ %12, %11 ], [ 0, %4 ]
  %18 = phi x86_fp80 [ %15, %11 ], [ %3, %4 ]
  %19 = phi x86_fp80 [ %14, %11 ], [ %2, %4 ]
  %20 = fmul x86_fp80 %18, %18
  %21 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %19, x86_fp80 %19, x86_fp80 %20)
  %22 = fmul x86_fp80 %18, %1
  %23 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %0, x86_fp80 %19, x86_fp80 %22)
  %24 = fdiv x86_fp80 %23, %21
  %25 = sub nsw i32 0, %17
  %26 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %24, i32 noundef %25) #6
  %27 = fneg x86_fp80 %18
  %28 = fmul x86_fp80 %27, %0
  %29 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %1, x86_fp80 %19, x86_fp80 %28)
  %30 = fdiv x86_fp80 %29, %21
  %31 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %30, i32 noundef %25) #6
  %32 = fcmp ord x86_fp80 %26, 0xK00000000000000000000
  %33 = fcmp ord x86_fp80 %31, 0xK00000000000000000000
  %34 = select i1 %32, i1 true, i1 %33
  br i1 %34, label %95, label %35

35:                                               ; preds = %16
  %36 = fcmp oeq x86_fp80 %21, 0xK00000000000000000000
  br i1 %36, label %37, label %45

37:                                               ; preds = %35
  %38 = fcmp ord x86_fp80 %0, 0xK00000000000000000000
  %39 = fcmp ord x86_fp80 %1, 0xK00000000000000000000
  %40 = or i1 %38, %39
  br i1 %40, label %41, label %45

41:                                               ; preds = %37
  %42 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK7FFF8000000000000000, x86_fp80 %19)
  %43 = fmul x86_fp80 %42, %0
  %44 = fmul x86_fp80 %42, %1
  br label %95

45:                                               ; preds = %37, %35
  %46 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %0)
  %47 = fcmp oeq x86_fp80 %46, 0xK7FFF8000000000000000
  %48 = xor i1 %47, true
  %49 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %50 = fcmp une x86_fp80 %49, 0xK7FFF8000000000000000
  %51 = and i1 %50, %48
  %52 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %19)
  %53 = fcmp ueq x86_fp80 %52, 0xK7FFF8000000000000000
  %54 = select i1 %51, i1 true, i1 %53
  %55 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %18)
  %56 = fcmp ueq x86_fp80 %55, 0xK7FFF8000000000000000
  %57 = select i1 %54, i1 true, i1 %56
  br i1 %57, label %72, label %58

58:                                               ; preds = %45
  %59 = uitofp i1 %47 to x86_fp80
  %60 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %59, x86_fp80 %0)
  %61 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %62 = fcmp oeq x86_fp80 %61, 0xK7FFF8000000000000000
  %63 = uitofp i1 %62 to x86_fp80
  %64 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %63, x86_fp80 %1)
  %65 = fmul x86_fp80 %64, %18
  %66 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %60, x86_fp80 %19, x86_fp80 %65)
  %67 = fmul x86_fp80 %66, 0xK7FFF8000000000000000
  %68 = fneg x86_fp80 %60
  %69 = fmul x86_fp80 %18, %68
  %70 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %64, x86_fp80 %19, x86_fp80 %69)
  %71 = fmul x86_fp80 %70, 0xK7FFF8000000000000000
  br label %95

72:                                               ; preds = %45
  %73 = fcmp une x86_fp80 %8, 0xK7FFF8000000000000000
  %74 = fcmp ueq x86_fp80 %46, 0xK7FFF8000000000000000
  %75 = or i1 %74, %73
  %76 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)
  %77 = fcmp ueq x86_fp80 %76, 0xK7FFF8000000000000000
  %78 = or i1 %77, %75
  br i1 %78, label %95, label %79

79:                                               ; preds = %72
  %80 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %19)
  %81 = fcmp oeq x86_fp80 %80, 0xK7FFF8000000000000000
  %82 = uitofp i1 %81 to x86_fp80
  %83 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %82, x86_fp80 %19)
  %84 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %18)
  %85 = fcmp oeq x86_fp80 %84, 0xK7FFF8000000000000000
  %86 = uitofp i1 %85 to x86_fp80
  %87 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %86, x86_fp80 %18)
  %88 = fmul x86_fp80 %87, %1
  %89 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %0, x86_fp80 %83, x86_fp80 %88)
  %90 = fmul x86_fp80 %89, 0xK00000000000000000000
  %91 = fneg x86_fp80 %87
  %92 = fmul x86_fp80 %91, %0
  %93 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %1, x86_fp80 %83, x86_fp80 %92)
  %94 = fmul x86_fp80 %93, 0xK00000000000000000000
  br label %95

95:                                               ; preds = %41, %72, %79, %58, %16
  %96 = phi x86_fp80 [ %71, %58 ], [ %94, %79 ], [ %31, %72 ], [ %44, %41 ], [ %31, %16 ]
  %97 = phi x86_fp80 [ %67, %58 ], [ %90, %79 ], [ %26, %72 ], [ %43, %41 ], [ %26, %16 ]
  %98 = insertvalue { x86_fp80, x86_fp80 } poison, x86_fp80 %97, 0
  %99 = insertvalue { x86_fp80, x86_fp80 } %98, x86_fp80 %96, 1
  ret { x86_fp80, x86_fp80 } %99
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare x86_fp80 @logbl(x86_fp80 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.fabs.f80(x86_fp80) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80, x86_fp80) #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare x86_fp80 @scalbnl(x86_fp80 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @complex_ldouble_muldiv(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2, x86_fp80 noundef %3, x86_fp80 noundef %4) local_unnamed_addr #4 {
  %6 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef %1) #7
  %7 = fmul x86_fp80 %2, 0xK00000000000000000000
  %8 = fadd x86_fp80 %7, %6
  %9 = fmul x86_fp80 %4, 0xK00000000000000000000
  %10 = fadd x86_fp80 %9, %3
  %11 = fmul x86_fp80 %10, %8
  %12 = fmul x86_fp80 %2, %4
  %13 = fmul x86_fp80 %8, %4
  %14 = fmul x86_fp80 %10, %2
  %15 = fsub x86_fp80 %11, %12
  %16 = fadd x86_fp80 %14, %13
  %17 = fcmp uno x86_fp80 %15, 0xK00000000000000000000
  br i1 %17, label %18, label %24, !prof !6

18:                                               ; preds = %5
  %19 = fcmp uno x86_fp80 %16, 0xK00000000000000000000
  br i1 %19, label %20, label %24, !prof !6

20:                                               ; preds = %18
  %21 = tail call { x86_fp80, x86_fp80 } @__mulxc3(x86_fp80 noundef %8, x86_fp80 noundef %2, x86_fp80 noundef %10, x86_fp80 noundef %4) #8
  %22 = extractvalue { x86_fp80, x86_fp80 } %21, 0
  %23 = extractvalue { x86_fp80, x86_fp80 } %21, 1
  br label %24

24:                                               ; preds = %20, %18, %5
  %25 = phi x86_fp80 [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]
  %26 = phi x86_fp80 [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]
  %27 = tail call { x86_fp80, x86_fp80 } @__divxc3(x86_fp80 noundef %25, x86_fp80 noundef %26, x86_fp80 noundef %10, x86_fp80 noundef %4) #8
  %28 = extractvalue { x86_fp80, x86_fp80 } %27, 0
  %29 = extractvalue { x86_fp80, x86_fp80 } %27, 1
  %30 = fadd x86_fp80 %28, %29
  %31 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %30) #8
  ret x86_fp80 %31
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #5

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #5

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { mustprogress nofree nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
