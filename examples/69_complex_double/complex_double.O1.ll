; ModuleID = 'complex_double.c'
source_filename = "complex_double.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define { double, double } @__muldc3(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = fmul double %0, %2    ; C: __ac = __a * __c;
  %6 = fmul double %1, %3    ; C: __bd = __b * __d;
  %7 = fmul double %0, %3    ; C: __ad = __a * __d;
  %8 = fmul double %1, %2    ; C: __bc = __b * __c;
  %9 = fsub double %5, %6    ; C: __real__ z = __ac - __bd;
  %10 = fadd double %8, %7    ; C: __imag__ z = __ad + __bc;
  %11 = fcmp uno double %9, 0.000000e+00    ; C: __builtin_isnan(__real__ z)
  %12 = fcmp uno double %10, 0.000000e+00    ; C: __builtin_isnan(__imag__ z)
  %13 = and i1 %11, %12    ; C: if (isnan(real) && isnan(imag))
  br i1 %13, label %14, label %99    ; C: if (isnan(real) && isnan(imag))

14:                                               ; preds = %4
  %15 = tail call double @llvm.fabs.f64(double %0)    ; C: __builtin_isinf(__a)
  %16 = fcmp oeq double %15, 0x7FF0000000000000    ; C: __builtin_isinf(__a)
  %17 = tail call double @llvm.fabs.f64(double %1)    ; C: __builtin_isinf(__b)
  %18 = fcmp oeq double %17, 0x7FF0000000000000    ; C: __builtin_isinf(__b)
  %19 = or i1 %16, %18    ; C: if (isinf(__a) || isinf(__b))
  br i1 %19, label %20, label %31    ; C: if (isinf(__a) || isinf(__b))

20:                                               ; preds = %14
  %21 = uitofp i1 %16 to double    ; C: __builtin_isinf(__a) ? 1 : 0
  %22 = tail call double @llvm.copysign.f64(double %21, double %0)    ; C: __a = __builtin_copysign(..., __a);
  %23 = uitofp i1 %18 to double    ; C: __builtin_isinf(__b) ? 1 : 0
  %24 = tail call double @llvm.copysign.f64(double %23, double %1)    ; C: __b = __builtin_copysign(..., __b);
  %25 = fcmp uno double %2, 0.000000e+00    ; C: if (__builtin_isnan(__c))
  %26 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %2)    ; C: __builtin_copysign(0, __c)
  %27 = select i1 %25, double %26, double %2    ; C: __c = ... (folded if)
  %28 = fcmp uno double %3, 0.000000e+00    ; C: if (__builtin_isnan(__d))
  %29 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %3)    ; C: __builtin_copysign(0, __d)
  %30 = select i1 %28, double %29, double %3    ; C: __d = ... (folded if)
  br label %31    ; C: end of if (recalc = 1)

31:                                               ; preds = %14, %20
  %32 = phi double [ %30, %20 ], [ %3, %14 ]    ; C: __d after the first if
  %33 = phi double [ %27, %20 ], [ %2, %14 ]    ; C: __c after the first if
  %34 = phi double [ %24, %20 ], [ %1, %14 ]    ; C: __b after the first if
  %35 = phi double [ %22, %20 ], [ %0, %14 ]    ; C: __a after the first if
  %36 = phi i32 [ 1, %20 ], [ 0, %14 ]    ; C: __recalc after the first if
  %37 = tail call double @llvm.fabs.f64(double %33)    ; C: __builtin_isinf(__c)
  %38 = fcmp oeq double %37, 0x7FF0000000000000    ; C: __builtin_isinf(__c)
  %39 = tail call double @llvm.fabs.f64(double %32)    ; C: __builtin_isinf(__d)
  %40 = fcmp oeq double %39, 0x7FF0000000000000    ; C: __builtin_isinf(__d)
  %41 = or i1 %40, %38    ; C: if (isinf(__c) || isinf(__d))
  br i1 %41, label %42, label %53    ; C: if (isinf(__c) || isinf(__d))

42:                                               ; preds = %31
  %43 = uitofp i1 %38 to double    ; C: __builtin_isinf(__c) ? 1 : 0
  %44 = tail call double @llvm.copysign.f64(double %43, double %33)    ; C: __c = __builtin_copysign(..., __c);
  %45 = uitofp i1 %40 to double    ; C: __builtin_isinf(__d) ? 1 : 0
  %46 = tail call double @llvm.copysign.f64(double %45, double %32)    ; C: __d = __builtin_copysign(..., __d);
  %47 = fcmp uno double %35, 0.000000e+00    ; C: if (__builtin_isnan(__a))
  %48 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %35)    ; C: __builtin_copysign(0, __a)
  %49 = select i1 %47, double %48, double %35    ; C: __a = ... (folded if)
  %50 = fcmp uno double %34, 0.000000e+00    ; C: if (__builtin_isnan(__b))
  %51 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %34)    ; C: __builtin_copysign(0, __b)
  %52 = select i1 %50, double %51, double %34    ; C: __b = ... (folded if)
  br label %53    ; C: end of if (recalc = 1)

53:                                               ; preds = %31, %42
  %54 = phi double [ %46, %42 ], [ %32, %31 ]    ; C: __d after the second if
  %55 = phi double [ %44, %42 ], [ %33, %31 ]    ; C: __c after the second if
  %56 = phi double [ %52, %42 ], [ %34, %31 ]    ; C: __b after the second if
  %57 = phi double [ %49, %42 ], [ %35, %31 ]    ; C: __a after the second if
  %58 = phi i32 [ 1, %42 ], [ %36, %31 ]    ; C: __recalc after the second if
  %59 = icmp eq i32 %58, 0    ; C: !__recalc
  br i1 %59, label %60, label %85    ; C: if (!__recalc && ...)

60:                                               ; preds = %53
  %61 = tail call double @llvm.fabs.f64(double %5)    ; C: __builtin_isinf(__ac)
  %62 = fcmp oeq double %61, 0x7FF0000000000000    ; C: __builtin_isinf(__ac)
  %63 = tail call double @llvm.fabs.f64(double %6)    ; C: __builtin_isinf(__bd)
  %64 = fcmp oeq double %63, 0x7FF0000000000000    ; C: __builtin_isinf(__bd)
  %65 = or i1 %62, %64    ; C: isinf(__ac) || isinf(__bd)
  %66 = tail call double @llvm.fabs.f64(double %7)    ; C: __builtin_isinf(__ad)
  %67 = fcmp oeq double %66, 0x7FF0000000000000    ; C: __builtin_isinf(__ad)
  %68 = or i1 %67, %65    ; C: ... || isinf(__ad)
  %69 = tail call double @llvm.fabs.f64(double %8)    ; C: __builtin_isinf(__bc)
  %70 = fcmp oeq double %69, 0x7FF0000000000000    ; C: __builtin_isinf(__bc)
  %71 = or i1 %70, %68    ; C: ... || isinf(__bc)
  br i1 %71, label %72, label %85    ; C: if (!__recalc && (...))

72:                                               ; preds = %60
  %73 = fcmp uno double %57, 0.000000e+00    ; C: if (__builtin_isnan(__a))
  %74 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %57)    ; C: __builtin_copysign(0, __a)
  %75 = select i1 %73, double %74, double %57    ; C: __a = ... (folded if)
  %76 = fcmp uno double %56, 0.000000e+00    ; C: if (__builtin_isnan(__b))
  %77 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %56)    ; C: __builtin_copysign(0, __b)
  %78 = select i1 %76, double %77, double %56    ; C: __b = ...
  %79 = fcmp uno double %55, 0.000000e+00    ; C: if (__builtin_isnan(__c))
  %80 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %55)    ; C: __builtin_copysign(0, __c)
  %81 = select i1 %79, double %80, double %55    ; C: __c = ...
  %82 = fcmp uno double %54, 0.000000e+00    ; C: if (__builtin_isnan(__d))
  %83 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %54)    ; C: __builtin_copysign(0, __d)
  %84 = select i1 %82, double %83, double %54    ; C: __d = ...
  br label %85    ; C: end of if (recalc = 1)

85:                                               ; preds = %60, %72, %53
  %86 = phi double [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]    ; C: __d after the third if
  %87 = phi double [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]    ; C: __c after the third if
  %88 = phi double [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]    ; C: __b after the third if
  %89 = phi double [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]    ; C: __a after the third if
  %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]    ; C: !__recalc (no recalculation at all)
  br i1 %90, label %99, label %91    ; C: if (__recalc)

91:                                               ; preds = %85
  %92 = fneg double %88    ; C: - __b * __d
  %93 = fmul double %86, %92    ; C: __b * __d (negated)
  %94 = tail call double @llvm.fmuladd.f64(double %89, double %87, double %93)    ; C: __a * __c - __b * __d
  %95 = fmul double %94, 0x7FF0000000000000    ; C: __real__ z = __builtin_huge_val() * (...);
  %96 = fmul double %87, %88    ; C: __b * __c
  %97 = tail call double @llvm.fmuladd.f64(double %89, double %86, double %96)    ; C: __a * __d + __b * __c
  %98 = fmul double %97, 0x7FF0000000000000    ; C: __imag__ z = __builtin_huge_val() * (...);
  br label %99    ; C: end of if

99:                                               ; preds = %85, %91, %4
  %100 = phi double [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]    ; C: __imag__ z (final)
  %101 = phi double [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]    ; C: __real__ z (final)
  %102 = insertvalue { double, double } poison, double %101, 0    ; C: return z;
  %103 = insertvalue { double, double } %102, double %100, 1    ; C: return z;
  ret { double, double } %103    ; C: return z;
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define double @complex_double(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #2 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #6    ; C: cq_theta(&re, th);
  %7 = fmul double %2, 0.000000e+00    ; C: im * I  (imaginary unit times im: real part im*0)
  %8 = fadd double %7, %6    ; C: double complex z = re + im * I;  (real part)
  %9 = fmul double %4, 0.000000e+00    ; C: b * I
  %10 = fadd double %9, %3    ; C: double complex w = a + b * I;  (real part)
  %11 = fmul double %10, %8    ; C: z * w: re(z)*re(w)
  %12 = fmul double %2, %4    ; C: z * w: im(z)*im(w)
  %13 = fmul double %8, %4    ; C: z * w: re(z)*im(w)
  %14 = fmul double %10, %2    ; C: z * w: re(w)*im(z)
  %15 = fsub double %11, %12    ; C: real part of z * w (fast path)
  %16 = fadd double %14, %13    ; C: imaginary part of z * w (fast path)
  %17 = fcmp uno double %15, 0.000000e+00    ; C: z * w: is the real part NaN?
  br i1 %17, label %18, label %24, !prof !6    ; C: z * w: NaN check

18:                                               ; preds = %5
  %19 = fcmp uno double %16, 0.000000e+00    ; C: z * w: is the imaginary part NaN?
  br i1 %19, label %20, label %24, !prof !6    ; C: z * w: NaN check

20:                                               ; preds = %18
  %21 = tail call { double, double } @__muldc3(double noundef %8, double noundef %2, double noundef %10, double noundef %4) #7    ; C: z * w: __muldc3 (both parts NaN)
  %22 = extractvalue { double, double } %21, 0    ; C: real part from __muldc3
  %23 = extractvalue { double, double } %21, 1    ; C: imaginary part from __muldc3
  br label %24    ; C: end of z * w

24:                                               ; preds = %20, %18, %5
  %25 = phi double [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]    ; C: double complex p = z * w;  (real)
  %26 = phi double [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]    ; C: double complex p = z * w;  (imaginary)
  %27 = tail call fastcc { double, double } @twice(double noundef %25, double noundef %26)    ; C: double complex q = twice(p);
  %28 = extractvalue { double, double } %27, 0    ; C: creal(q)
  %29 = extractvalue { double, double } %27, 1    ; C: cimag(q)
  %30 = fadd double %28, %29    ; C: creal(q) + cimag(q)
  %31 = tail call double @cq_measure_f64(double noundef %30) #7    ; C: cq_measure(creal(q) + cimag(q))
  ret double %31    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc { double, double } @twice(double noundef %0, double noundef %1) unnamed_addr #4 {
  %3 = fadd double %0, %0    ; C: z + z  (real)
  %4 = fadd double %1, %1    ; C: z + z  (imaginary)
  %5 = insertvalue { double, double } poison, double %3, 0    ; C: return z + z;
  %6 = insertvalue { double, double } %5, double %4, 1    ; C: return z + z;
  ret { double, double } %6    ; C: return z + z;
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #5

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!"branch_weights", i32 1, i32 1048575}
