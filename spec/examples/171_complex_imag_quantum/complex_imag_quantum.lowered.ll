; HAND-WRITTEN. Rules: 26, 18, 8, 9, 3, 4, 5 (and 1).
; Checked: creal(s) + cimag(s) + creal(c) - cimag(c) (measured, %29 -> %30).
; Clean: every flag, path-predicate and arithmetic rail of the entry and of the clone __cq_q___muldc3_1100 (the clone's
; two result rails are zeroed by its _unc twin and freed by the caller), all freed before the measurement.
; Kept: im (%6, the rotated register) and the measured result rail %29; nothing else.
; Rotations: (Ry, im, ti, 1); the clone holds none.
; The IMAGINARY part is the quantum one. Taint flows through clang's Annex G expansion exactly as rule 3 says: z = re +
; im*I makes the real part `im * 0 + re` quantum as well (%7, %8), so z * w reaches __muldc3 with mask 1100 (a =
; creal(z) and b = im quantum, c, d classical), one clone of the compiler-rt body; the fast path mixes two-handle and
; _hl templates. The two `fcmp uno` branches are flags conjoined into the %20 predicate (rule 8) and the clone's results
; are merged with the fast-path values by two selects on it (rule 9). conj(p) is representation only: -O1 folds `-
; cimag(conj p)` into `+ cimag(p)`, so the sum is five fadd templates. s = z + w is an _hl fadd per part. Everything but
; the result rail is uncomputed LIFO (the clone's copies through its _unc twin) before the measurement. The
; recalculation's two llvm.fmuladd.f64 calls (%94, %97) are UNFUSED (§2, cf. 14, 69): a fmul_f64 into a fresh product
; rail, then an fadd_f64 of the product and the addend; the product is uncomputed right after the sum it fed (rule 5,
; LIFO), in the clone and again in its _unc twin's recomputation.
source_filename = "complex_imag_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @complex_imag_quantum(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %6 = cq_theta_f64(%1, %2)  [register im]
  call void @cqrt_ry_f64(i32 %6, double %2)    ; IR: %6 = cq_theta_f64(%1, %2)  [Ry]
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %6, double 0.000000e+00)    ; IR: %7 = fmul %6, 0.0  (im * I: real part im*0, quantum)
  %8 = call i32 @cq_template_fadd_f64_hl(i32 %7, double %0)    ; IR: %8 = fadd %7, %0  (real part of z)
  %9 = fmul double %4, 0.000000e+00    ; IR: %9 = fmul %4, 0.0  (classical)
  %10 = fadd double %9, %3    ; IR: %10 = fadd %9, %3  (real part of w)  (classical)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %10)    ; IR: %11 = fmul %10, %8  (commutative, quantum operand first)
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %6, double %4)    ; IR: %12 = fmul %6, %4
  %13 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %4)    ; IR: %13 = fmul %8, %4
  %14 = call i32 @cq_template_fmul_f64_hl(i32 %6, double %10)    ; IR: %14 = fmul %10, %6  (commutative, quantum operand first)
  %15 = call i32 @cq_template_fsub_f64(i32 %11, i32 %12)    ; IR: %15 = fsub %11, %12  (fast-path real part)
  %16 = call i32 @cq_template_fadd_f64(i32 %14, i32 %13)    ; IR: %16 = fadd %14, %13  (fast-path imaginary part)
  %17 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %15, double 0.000000e+00)    ; IR: %17 = fcmp uno %15, 0.0  [predicate of block %18]
  %18 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %16, double 0.000000e+00)    ; IR: %19 = fcmp uno %16, 0.0
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P20 = path predicate of block %20 = %17 & %19  [fresh flag rail]
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: P20 = path predicate of block %20 = %17 & %19
  %20 = call fastcc { i32, i32 } @__cq_q___muldc3_1100(i32 %8, i32 %6, double %10, double %4)    ; IR: %21 = call @__muldc3(%8, %6, %10, %4), quantum clone (args 0 and 1 quantum), called unconditionally
  %21 = extractvalue { i32, i32 } %20, 0    ; IR: extractvalue %21, 0  (handle; classical)
  %22 = extractvalue { i32, i32 } %20, 1    ; IR: extractvalue %21, 1  (handle; classical)
  %23 = call i32 @cq_template_select_f64(i32 %19, i32 %21, i32 %15)    ; IR: %25 = phi [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]  (real part of p)
  %24 = call i32 @cq_template_select_f64(i32 %19, i32 %22, i32 %16)    ; IR: %26 = phi [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]  (imaginary part of p)
  %25 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %4)    ; IR: %27 = fadd %6, %4  (cimag(s))
  %26 = call i32 @cq_template_fadd_f64_hl(i32 %8, double %10)    ; IR: %28 = fadd %10, %8  (creal(s))  (commutative, quantum operand first)
  %27 = call i32 @cq_template_fadd_f64(i32 %25, i32 %26)    ; IR: %29 = fadd %27, %28
  %28 = call i32 @cq_template_fadd_f64(i32 %27, i32 %23)    ; IR: %30 = fadd %29, %25  (+ creal(conj p))
  %29 = call i32 @cq_template_fadd_f64(i32 %28, i32 %24)    ; IR: %31 = fadd %30, %26  (- cimag(conj p) = + cimag(p), folded by -O1)  [result rail]
  call void @cq_template_fadd_f64_unc(i32 %28, i32 %27, i32 %23)    ; IR: uncompute %30
  call void @cqrt_free(i32 %28)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %27, i32 %25, i32 %26)    ; IR: uncompute %29
  call void @cqrt_free(i32 %27)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %26, i32 %8, double %10)    ; IR: uncompute %28
  call void @cqrt_free(i32 %26)    ; IR: release the %28 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %25, i32 %6, double %4)    ; IR: uncompute %27
  call void @cqrt_free(i32 %25)    ; IR: release the %27 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %24, i32 %19, i32 %22, i32 %16)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %19, i32 %21, i32 %15)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call fastcc void @__cq_q___muldc3_1100_unc(i32 %21, i32 %22, i32 %8, i32 %6, double %10, double %4)    ; IR: uncompute the result rail(s) of %21
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: uncompute P20  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the P20 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %18, i32 %16, double 0.000000e+00)    ; IR: uncompute %19
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %17, i32 %15, double 0.000000e+00)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %16, i32 %14, i32 %13)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %15, i32 %11, i32 %12)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %14, i32 %6, double %10)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %13, i32 %8, double %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %12, i32 %6, double %4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %8, double %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %8, i32 %7, double %0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %6, double 0.000000e+00)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %30 = call double @cqrt_measure_f64(i32 %29)    ; IR: %32 = cq_measure_f64(%31)
  ret double %30    ; IR: ret double %32
}

define internal fastcc { i32, i32 } @__cq_q___muldc3_1100(i32 %0, i32 %1, double %2, double %3) {
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %2)    ; IR: %5 = fmul %0, %2  (a*c)
  %6 = call i32 @cq_template_fmul_f64_hl(i32 %1, double %3)    ; IR: %6 = fmul %1, %3  (b*d)
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %3)    ; IR: %7 = fmul %0, %3  (a*d)
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %1, double %2)    ; IR: %8 = fmul %1, %2  (b*c)
  %9 = call i32 @cq_template_fsub_f64(i32 %5, i32 %6)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %10 = call i32 @cq_template_fadd_f64(i32 %8, i32 %7)    ; IR: %10 = fadd %8, %7  (imaginary part)
  %11 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %9, double 0.000000e+00)    ; IR: %11 = fcmp uno %9, 0.0  (isnan)
  %12 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %10, double 0.000000e+00)    ; IR: %12 = fcmp uno %10, 0.0
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %13)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]
  %14 = call i32 @cq_template_fabs_f64(i32 %0)    ; IR: %15 = fabs(a)  (block %14)
  %15 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %14, double 0x7FF0000000000000)    ; IR: %16 = isinf(a)
  %16 = call i32 @cq_template_fabs_f64(i32 %1)    ; IR: %17 = fabs(b)
  %17 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %16, double 0x7FF0000000000000)    ; IR: %18 = isinf(b)
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %15, i32 %17, i32 %18)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]
  %19 = call i32 @cq_template_uitofp_i1_to_f64(i32 %15)    ; IR: %21 = uitofp i1 %16  (block %20)
  %20 = call i32 @cq_template_copysign_f64(i32 %19, i32 %0)    ; IR: %22 = copysign(%21, a)
  %21 = call i32 @cq_template_uitofp_i1_to_f64(i32 %17)    ; IR: %23 = uitofp i1 %18
  %22 = call i32 @cq_template_copysign_f64(i32 %21, i32 %1)    ; IR: %24 = copysign(%23, b)
  %23 = fcmp uno double %2, 0.000000e+00    ; IR: %25 = isnan(c)  (classical)
  %24 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %2)    ; IR: %26 = copysign(0, c)  (classical)
  %25 = select i1 %23, double %24, double %2    ; IR: %27 = select %25, %26, %2  (classical)
  %26 = fcmp uno double %3, 0.000000e+00    ; IR: %28 = isnan(d)  (classical)
  %27 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %3)    ; IR: %29 = copysign(0, d)  (classical)
  %28 = select i1 %26, double %27, double %3    ; IR: %30 = select %28, %29, %3  (classical)
  %29 = call i32 @cq_template_select_f64_ll(i32 %18, double %28, double %3)    ; IR: %32 = phi [ %30, %20 ], [ %3, %14 ]  (merge of block %20 on its predicate %19)
  %30 = call i32 @cq_template_select_f64_ll(i32 %18, double %25, double %2)    ; IR: %33 = phi [ %27, %20 ], [ %2, %14 ]
  %31 = call i32 @cq_template_select_f64(i32 %18, i32 %22, i32 %1)    ; IR: %34 = phi [ %24, %20 ], [ %1, %14 ]
  %32 = call i32 @cq_template_select_f64(i32 %18, i32 %20, i32 %0)    ; IR: %35 = phi [ %22, %20 ], [ %0, %14 ]
  %33 = call i32 @cq_template_select_i32_ll(i32 %18, i32 1, i32 0)    ; IR: %36 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %34 = call i32 @cq_template_fabs_f64(i32 %30)    ; IR: %37 = fabs(%33)  (block %31)
  %35 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %34, double 0x7FF0000000000000)    ; IR: %38 = isinf(%33)
  %36 = call i32 @cq_template_fabs_f64(i32 %29)    ; IR: %39 = fabs(%32)
  %37 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %36, double 0x7FF0000000000000)    ; IR: %40 = isinf(%32)
  %38 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %37, i32 %35, i32 %38)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]
  %39 = call i32 @cq_template_uitofp_i1_to_f64(i32 %35)    ; IR: %43 = uitofp i1 %38  (block %42)
  %40 = call i32 @cq_template_copysign_f64(i32 %39, i32 %30)    ; IR: %44 = copysign(%43, %33)
  %41 = call i32 @cq_template_uitofp_i1_to_f64(i32 %37)    ; IR: %45 = uitofp i1 %40
  %42 = call i32 @cq_template_copysign_f64(i32 %41, i32 %29)    ; IR: %46 = copysign(%45, %32)
  %43 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %32, double 0.000000e+00)    ; IR: %47 = isnan(%35)
  %44 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %32)    ; IR: %48 = copysign(0, %35)
  %45 = call i32 @cq_template_select_f64(i32 %43, i32 %44, i32 %32)    ; IR: %49 = select %47, %48, %35
  %46 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %31, double 0.000000e+00)    ; IR: %50 = isnan(%34)
  %47 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %31)    ; IR: %51 = copysign(0, %34)
  %48 = call i32 @cq_template_select_f64(i32 %46, i32 %47, i32 %31)    ; IR: %52 = select %50, %51, %34
  %49 = call i32 @cq_template_select_f64(i32 %38, i32 %42, i32 %29)    ; IR: %54 = phi [ %46, %42 ], [ %32, %31 ]  (merge of block %42 on %41)
  %50 = call i32 @cq_template_select_f64(i32 %38, i32 %40, i32 %30)    ; IR: %55 = phi [ %44, %42 ], [ %33, %31 ]
  %51 = call i32 @cq_template_select_f64(i32 %38, i32 %48, i32 %31)    ; IR: %56 = phi [ %52, %42 ], [ %34, %31 ]
  %52 = call i32 @cq_template_select_f64(i32 %38, i32 %45, i32 %32)    ; IR: %57 = phi [ %49, %42 ], [ %35, %31 ]
  %53 = call i32 @cq_template_select_i32_lh(i32 %38, i32 1, i32 %33)    ; IR: %58 = phi [ 1, %42 ], [ %36, %31 ]  (__recalc)
  %54 = call i32 @cq_template_icmp_eq_i32_hl(i32 %53, i32 0)    ; IR: %59 = icmp eq %58, 0  [predicate of block %60: !__recalc]
  %55 = call i32 @cq_template_fabs_f64(i32 %5)    ; IR: %61 = fabs(%5)  (block %60)
  %56 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %55, double 0x7FF0000000000000)    ; IR: %62 = isinf(ac)
  %57 = call i32 @cq_template_fabs_f64(i32 %6)    ; IR: %63 = fabs(%6)
  %58 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %57, double 0x7FF0000000000000)    ; IR: %64 = isinf(bd)
  %59 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %56, i32 %58, i32 %59)    ; IR: %65 = or i1 %62, %64
  %60 = call i32 @cq_template_fabs_f64(i32 %7)    ; IR: %66 = fabs(%7)
  %61 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %60, double 0x7FF0000000000000)    ; IR: %67 = isinf(ad)
  %62 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %61, i32 %59, i32 %62)    ; IR: %68 = or i1 %67, %65
  %63 = call i32 @cq_template_fabs_f64(i32 %8)    ; IR: %69 = fabs(%8)
  %64 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %63, double 0x7FF0000000000000)    ; IR: %70 = isinf(bc)
  %65 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %64, i32 %62, i32 %65)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]
  %66 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %52, double 0.000000e+00)    ; IR: %73 = isnan(%57)  (block %72)
  %67 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %52)    ; IR: %74 = copysign(0, %57)
  %68 = call i32 @cq_template_select_f64(i32 %66, i32 %67, i32 %52)    ; IR: %75 = select %73, %74, %57
  %69 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %51, double 0.000000e+00)    ; IR: %76 = isnan(%56)
  %70 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %51)    ; IR: %77 = copysign(0, %56)
  %71 = call i32 @cq_template_select_f64(i32 %69, i32 %70, i32 %51)    ; IR: %78 = select %76, %77, %56
  %72 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %50, double 0.000000e+00)    ; IR: %79 = isnan(%55)
  %73 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %50)    ; IR: %80 = copysign(0, %55)
  %74 = call i32 @cq_template_select_f64(i32 %72, i32 %73, i32 %50)    ; IR: %81 = select %79, %80, %55
  %75 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %49, double 0.000000e+00)    ; IR: %82 = isnan(%54)
  %76 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %49)    ; IR: %83 = copysign(0, %54)
  %77 = call i32 @cq_template_select_f64(i32 %75, i32 %76, i32 %49)    ; IR: %84 = select %82, %83, %54
  %78 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72 relative to %53: %59 & %71  [fresh flag rail]
  call void @cqrt_and_i1(i32 %54, i32 %65, i32 %78)    ; IR: P72 = path predicate of block %72 relative to %53: %59 & %71
  %79 = call i32 @cq_template_select_f64(i32 %78, i32 %77, i32 %49)    ; IR: %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (only the %72 path differs)
  %80 = call i32 @cq_template_select_f64(i32 %78, i32 %74, i32 %50)    ; IR: %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  %81 = call i32 @cq_template_select_f64(i32 %78, i32 %71, i32 %51)    ; IR: %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  %82 = call i32 @cq_template_select_f64(i32 %78, i32 %68, i32 %52)    ; IR: %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_not_i1(i32 %65)    ; IR: bracket: %90 reads NOT %65
  %83 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %54, i32 %65, i32 %83)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [no recalculation]
  call void @cqrt_not_i1(i32 %65)    ; IR: bracket (close): %90 reads NOT %65
  %84 = call i32 @cq_template_fneg_f64(i32 %81)    ; IR: %92 = fneg %88  (block %91)
  %85 = call i32 @cq_template_fmul_f64(i32 %79, i32 %84)    ; IR: %93 = fmul %86, %92
  %86 = call i32 @cq_template_fmul_f64(i32 %82, i32 %80)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused product]
  %87 = call i32 @cq_template_fadd_f64(i32 %86, i32 %85)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %88 = call i32 @cq_template_fmul_f64_hl(i32 %87, double 0x7FF0000000000000)    ; IR: %95 = fmul %94, inf
  %89 = call i32 @cq_template_fmul_f64(i32 %80, i32 %81)    ; IR: %96 = fmul %87, %88
  %90 = call i32 @cq_template_fmul_f64(i32 %82, i32 %79)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused product]
  %91 = call i32 @cq_template_fadd_f64(i32 %90, i32 %89)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %92 = call i32 @cq_template_fmul_f64_hl(i32 %91, double 0x7FF0000000000000)    ; IR: %98 = fmul %97, inf
  call void @cqrt_not_i1(i32 %83)    ; IR: bracket: P91 reads NOT %83
  %93 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P91 = path predicate of block %91: %13 & !%90  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %83, i32 %93)    ; IR: P91 = path predicate of block %91: %13 & !%90
  call void @cqrt_not_i1(i32 %83)    ; IR: bracket (close): P91 reads NOT %83
  %94 = call i32 @cq_template_select_f64(i32 %93, i32 %88, i32 %9)    ; IR: %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  %95 = call i32 @cq_template_select_f64(i32 %93, i32 %92, i32 %10)    ; IR: %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  %96 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f64(i32 %94, i32 %96)    ; IR: copy real out
  %97 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %95, i32 %97)    ; IR: copy imaginary out
  call void @cq_template_select_f64_unc(i32 %95, i32 %93, i32 %92, i32 %10)    ; IR: uncompute %100
  call void @cqrt_free(i32 %95)    ; IR: release the %100 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %94, i32 %93, i32 %88, i32 %9)    ; IR: uncompute %101
  call void @cqrt_free(i32 %94)    ; IR: release the %101 rail (|0>)
  call void @cqrt_not_i1(i32 %83)    ; IR: bracket: P91 reads NOT %83
  call void @cqrt_and_i1(i32 %13, i32 %83, i32 %93)    ; IR: uncompute P91  [self-inverse]
  call void @cqrt_free(i32 %93)    ; IR: release the P91 rail (|0>)
  call void @cqrt_not_i1(i32 %83)    ; IR: bracket (close): P91 reads NOT %83
  call void @cq_template_fmul_f64_hl_unc(i32 %92, i32 %91, double 0x7FF0000000000000)    ; IR: uncompute %98
  call void @cqrt_free(i32 %92)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %91, i32 %90, i32 %89)    ; IR: uncompute %97  [sum]
  call void @cqrt_free(i32 %91)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %90, i32 %82, i32 %79)    ; IR: uncompute %97  [product]
  call void @cqrt_free(i32 %90)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %89, i32 %80, i32 %81)    ; IR: uncompute %96
  call void @cqrt_free(i32 %89)    ; IR: release the %96 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %88, i32 %87, double 0x7FF0000000000000)    ; IR: uncompute %95
  call void @cqrt_free(i32 %88)    ; IR: release the %95 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %87, i32 %86, i32 %85)    ; IR: uncompute %94  [sum]
  call void @cqrt_free(i32 %87)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %86, i32 %82, i32 %80)    ; IR: uncompute %94  [product]
  call void @cqrt_free(i32 %86)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %85, i32 %79, i32 %84)    ; IR: uncompute %93
  call void @cqrt_free(i32 %85)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %84, i32 %81)    ; IR: uncompute %92
  call void @cqrt_free(i32 %84)    ; IR: release the %92 rail (|0>)
  call void @cqrt_not_i1(i32 %65)    ; IR: bracket: %90 reads NOT %65
  call void @cqrt_and_i1(i32 %54, i32 %65, i32 %83)    ; IR: uncompute %90  [self-inverse]
  call void @cqrt_free(i32 %83)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %65)    ; IR: bracket (close): %90 reads NOT %65
  call void @cq_template_select_f64_unc(i32 %82, i32 %78, i32 %68, i32 %52)    ; IR: uncompute %89
  call void @cqrt_free(i32 %82)    ; IR: release the %89 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %81, i32 %78, i32 %71, i32 %51)    ; IR: uncompute %88
  call void @cqrt_free(i32 %81)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %80, i32 %78, i32 %74, i32 %50)    ; IR: uncompute %87
  call void @cqrt_free(i32 %80)    ; IR: release the %87 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %79, i32 %78, i32 %77, i32 %49)    ; IR: uncompute %86
  call void @cqrt_free(i32 %79)    ; IR: release the %86 rail (|0>)
  call void @cqrt_and_i1(i32 %54, i32 %65, i32 %78)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %78)    ; IR: release the P72 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %77, i32 %75, i32 %76, i32 %49)    ; IR: uncompute %84
  call void @cqrt_free(i32 %77)    ; IR: release the %84 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %76, double 0.000000e+00, i32 %49)    ; IR: uncompute %83
  call void @cqrt_free(i32 %76)    ; IR: release the %83 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %75, i32 %49, double 0.000000e+00)    ; IR: uncompute %82
  call void @cqrt_free(i32 %75)    ; IR: release the %82 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %74, i32 %72, i32 %73, i32 %50)    ; IR: uncompute %81
  call void @cqrt_free(i32 %74)    ; IR: release the %81 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %73, double 0.000000e+00, i32 %50)    ; IR: uncompute %80
  call void @cqrt_free(i32 %73)    ; IR: release the %80 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %72, i32 %50, double 0.000000e+00)    ; IR: uncompute %79
  call void @cqrt_free(i32 %72)    ; IR: release the %79 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %71, i32 %69, i32 %70, i32 %51)    ; IR: uncompute %78
  call void @cqrt_free(i32 %71)    ; IR: release the %78 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %70, double 0.000000e+00, i32 %51)    ; IR: uncompute %77
  call void @cqrt_free(i32 %70)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %69, i32 %51, double 0.000000e+00)    ; IR: uncompute %76
  call void @cqrt_free(i32 %69)    ; IR: release the %76 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %68, i32 %66, i32 %67, i32 %52)    ; IR: uncompute %75
  call void @cqrt_free(i32 %68)    ; IR: release the %75 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %67, double 0.000000e+00, i32 %52)    ; IR: uncompute %74
  call void @cqrt_free(i32 %67)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %66, i32 %52, double 0.000000e+00)    ; IR: uncompute %73
  call void @cqrt_free(i32 %66)    ; IR: release the %73 rail (|0>)
  call void @cqrt_or_i1(i32 %64, i32 %62, i32 %65)    ; IR: uncompute %71  [self-inverse]
  call void @cqrt_free(i32 %65)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %64, i32 %63, double 0x7FF0000000000000)    ; IR: uncompute %70
  call void @cqrt_free(i32 %64)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %63, i32 %8)    ; IR: uncompute %69
  call void @cqrt_free(i32 %63)    ; IR: release the %69 rail (|0>)
  call void @cqrt_or_i1(i32 %61, i32 %59, i32 %62)    ; IR: uncompute %68  [self-inverse]
  call void @cqrt_free(i32 %62)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %61, i32 %60, double 0x7FF0000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %61)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %60, i32 %7)    ; IR: uncompute %66
  call void @cqrt_free(i32 %60)    ; IR: release the %66 rail (|0>)
  call void @cqrt_or_i1(i32 %56, i32 %58, i32 %59)    ; IR: uncompute %65  [self-inverse]
  call void @cqrt_free(i32 %59)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %58, i32 %57, double 0x7FF0000000000000)    ; IR: uncompute %64
  call void @cqrt_free(i32 %58)    ; IR: release the %64 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %57, i32 %6)    ; IR: uncompute %63
  call void @cqrt_free(i32 %57)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %56, i32 %55, double 0x7FF0000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %56)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %55, i32 %5)    ; IR: uncompute %61
  call void @cqrt_free(i32 %55)    ; IR: release the %61 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %54, i32 %53, i32 0)    ; IR: uncompute %59
  call void @cqrt_free(i32 %54)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %53, i32 %38, i32 1, i32 %33)    ; IR: uncompute %58
  call void @cqrt_free(i32 %53)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %52, i32 %38, i32 %45, i32 %32)    ; IR: uncompute %57
  call void @cqrt_free(i32 %52)    ; IR: release the %57 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %51, i32 %38, i32 %48, i32 %31)    ; IR: uncompute %56
  call void @cqrt_free(i32 %51)    ; IR: release the %56 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %50, i32 %38, i32 %40, i32 %30)    ; IR: uncompute %55
  call void @cqrt_free(i32 %50)    ; IR: release the %55 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %49, i32 %38, i32 %42, i32 %29)    ; IR: uncompute %54
  call void @cqrt_free(i32 %49)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %48, i32 %46, i32 %47, i32 %31)    ; IR: uncompute %52
  call void @cqrt_free(i32 %48)    ; IR: release the %52 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %47, double 0.000000e+00, i32 %31)    ; IR: uncompute %51
  call void @cqrt_free(i32 %47)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %46, i32 %31, double 0.000000e+00)    ; IR: uncompute %50
  call void @cqrt_free(i32 %46)    ; IR: release the %50 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %45, i32 %43, i32 %44, i32 %32)    ; IR: uncompute %49
  call void @cqrt_free(i32 %45)    ; IR: release the %49 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %44, double 0.000000e+00, i32 %32)    ; IR: uncompute %48
  call void @cqrt_free(i32 %44)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %43, i32 %32, double 0.000000e+00)    ; IR: uncompute %47
  call void @cqrt_free(i32 %43)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %42, i32 %41, i32 %29)    ; IR: uncompute %46
  call void @cqrt_free(i32 %42)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %41, i32 %37)    ; IR: uncompute %45
  call void @cqrt_free(i32 %41)    ; IR: release the %45 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %40, i32 %39, i32 %30)    ; IR: uncompute %44
  call void @cqrt_free(i32 %40)    ; IR: release the %44 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %39, i32 %35)    ; IR: uncompute %43
  call void @cqrt_free(i32 %39)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %37, i32 %35, i32 %38)    ; IR: uncompute %41  [self-inverse]
  call void @cqrt_free(i32 %38)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %37, i32 %36, double 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %37)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %36, i32 %29)    ; IR: uncompute %39
  call void @cqrt_free(i32 %36)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %35, i32 %34, double 0x7FF0000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %35)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %34, i32 %30)    ; IR: uncompute %37
  call void @cqrt_free(i32 %34)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %33, i32 %18, i32 1, i32 0)    ; IR: uncompute %36
  call void @cqrt_free(i32 %33)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %32, i32 %18, i32 %20, i32 %0)    ; IR: uncompute %35
  call void @cqrt_free(i32 %32)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %31, i32 %18, i32 %22, i32 %1)    ; IR: uncompute %34
  call void @cqrt_free(i32 %31)    ; IR: release the %34 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %30, i32 %18, double %25, double %2)    ; IR: uncompute %33
  call void @cqrt_free(i32 %30)    ; IR: release the %33 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %29, i32 %18, double %28, double %3)    ; IR: uncompute %32
  call void @cqrt_free(i32 %29)    ; IR: release the %32 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %22, i32 %21, i32 %1)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %21, i32 %17)    ; IR: uncompute %23
  call void @cqrt_free(i32 %21)    ; IR: release the %23 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %20, i32 %19, i32 %0)    ; IR: uncompute %22
  call void @cqrt_free(i32 %20)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %19, i32 %15)    ; IR: uncompute %21
  call void @cqrt_free(i32 %19)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %15, i32 %17, i32 %18)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %17, i32 %16, double 0x7FF0000000000000)    ; IR: uncompute %18
  call void @cqrt_free(i32 %17)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %16, i32 %1)    ; IR: uncompute %17
  call void @cqrt_free(i32 %16)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %15, i32 %14, double 0x7FF0000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %15)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %14, i32 %0)    ; IR: uncompute %15
  call void @cqrt_free(i32 %14)    ; IR: release the %15 rail (|0>)
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %13)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %12, i32 %10, double 0.000000e+00)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %11, i32 %9, double 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %10, i32 %8, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %9, i32 %5, i32 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %1, double %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %0, double %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %6, i32 %1, double %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %0, double %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %98 = insertvalue { i32, i32 } poison, i32 %96, 0    ; IR: ret: field 0 (handle)
  %99 = insertvalue { i32, i32 } %98, i32 %97, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %99    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc void @__cq_q___muldc3_1100_unc(i32 %0, i32 %1, i32 %2, i32 %3, double %4, double %5) {
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %4)    ; IR: %5 = fmul %0, %2  (a*c)
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %3, double %5)    ; IR: %6 = fmul %1, %3  (b*d)
  %9 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %5)    ; IR: %7 = fmul %0, %3  (a*d)
  %10 = call i32 @cq_template_fmul_f64_hl(i32 %3, double %4)    ; IR: %8 = fmul %1, %2  (b*c)
  %11 = call i32 @cq_template_fsub_f64(i32 %7, i32 %8)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %12 = call i32 @cq_template_fadd_f64(i32 %10, i32 %9)    ; IR: %10 = fadd %8, %7  (imaginary part)
  %13 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %11, double 0.000000e+00)    ; IR: %11 = fcmp uno %9, 0.0  (isnan)
  %14 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %12, double 0.000000e+00)    ; IR: %12 = fcmp uno %10, 0.0
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %14, i32 %15)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]
  %16 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %15 = fabs(a)  (block %14)
  %17 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %16, double 0x7FF0000000000000)    ; IR: %16 = isinf(a)
  %18 = call i32 @cq_template_fabs_f64(i32 %3)    ; IR: %17 = fabs(b)
  %19 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %18, double 0x7FF0000000000000)    ; IR: %18 = isinf(b)
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %17, i32 %19, i32 %20)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]
  %21 = call i32 @cq_template_uitofp_i1_to_f64(i32 %17)    ; IR: %21 = uitofp i1 %16  (block %20)
  %22 = call i32 @cq_template_copysign_f64(i32 %21, i32 %2)    ; IR: %22 = copysign(%21, a)
  %23 = call i32 @cq_template_uitofp_i1_to_f64(i32 %19)    ; IR: %23 = uitofp i1 %18
  %24 = call i32 @cq_template_copysign_f64(i32 %23, i32 %3)    ; IR: %24 = copysign(%23, b)
  %25 = fcmp uno double %4, 0.000000e+00    ; IR: %25 = isnan(c)  (classical)
  %26 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %4)    ; IR: %26 = copysign(0, c)  (classical)
  %27 = select i1 %25, double %26, double %4    ; IR: %27 = select %25, %26, %2  (classical)
  %28 = fcmp uno double %5, 0.000000e+00    ; IR: %28 = isnan(d)  (classical)
  %29 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %5)    ; IR: %29 = copysign(0, d)  (classical)
  %30 = select i1 %28, double %29, double %5    ; IR: %30 = select %28, %29, %3  (classical)
  %31 = call i32 @cq_template_select_f64_ll(i32 %20, double %30, double %5)    ; IR: %32 = phi [ %30, %20 ], [ %3, %14 ]  (merge of block %20 on its predicate %19)
  %32 = call i32 @cq_template_select_f64_ll(i32 %20, double %27, double %4)    ; IR: %33 = phi [ %27, %20 ], [ %2, %14 ]
  %33 = call i32 @cq_template_select_f64(i32 %20, i32 %24, i32 %3)    ; IR: %34 = phi [ %24, %20 ], [ %1, %14 ]
  %34 = call i32 @cq_template_select_f64(i32 %20, i32 %22, i32 %2)    ; IR: %35 = phi [ %22, %20 ], [ %0, %14 ]
  %35 = call i32 @cq_template_select_i32_ll(i32 %20, i32 1, i32 0)    ; IR: %36 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %36 = call i32 @cq_template_fabs_f64(i32 %32)    ; IR: %37 = fabs(%33)  (block %31)
  %37 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %36, double 0x7FF0000000000000)    ; IR: %38 = isinf(%33)
  %38 = call i32 @cq_template_fabs_f64(i32 %31)    ; IR: %39 = fabs(%32)
  %39 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %38, double 0x7FF0000000000000)    ; IR: %40 = isinf(%32)
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %39, i32 %37, i32 %40)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]
  %41 = call i32 @cq_template_uitofp_i1_to_f64(i32 %37)    ; IR: %43 = uitofp i1 %38  (block %42)
  %42 = call i32 @cq_template_copysign_f64(i32 %41, i32 %32)    ; IR: %44 = copysign(%43, %33)
  %43 = call i32 @cq_template_uitofp_i1_to_f64(i32 %39)    ; IR: %45 = uitofp i1 %40
  %44 = call i32 @cq_template_copysign_f64(i32 %43, i32 %31)    ; IR: %46 = copysign(%45, %32)
  %45 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %34, double 0.000000e+00)    ; IR: %47 = isnan(%35)
  %46 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %34)    ; IR: %48 = copysign(0, %35)
  %47 = call i32 @cq_template_select_f64(i32 %45, i32 %46, i32 %34)    ; IR: %49 = select %47, %48, %35
  %48 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %33, double 0.000000e+00)    ; IR: %50 = isnan(%34)
  %49 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %33)    ; IR: %51 = copysign(0, %34)
  %50 = call i32 @cq_template_select_f64(i32 %48, i32 %49, i32 %33)    ; IR: %52 = select %50, %51, %34
  %51 = call i32 @cq_template_select_f64(i32 %40, i32 %44, i32 %31)    ; IR: %54 = phi [ %46, %42 ], [ %32, %31 ]  (merge of block %42 on %41)
  %52 = call i32 @cq_template_select_f64(i32 %40, i32 %42, i32 %32)    ; IR: %55 = phi [ %44, %42 ], [ %33, %31 ]
  %53 = call i32 @cq_template_select_f64(i32 %40, i32 %50, i32 %33)    ; IR: %56 = phi [ %52, %42 ], [ %34, %31 ]
  %54 = call i32 @cq_template_select_f64(i32 %40, i32 %47, i32 %34)    ; IR: %57 = phi [ %49, %42 ], [ %35, %31 ]
  %55 = call i32 @cq_template_select_i32_lh(i32 %40, i32 1, i32 %35)    ; IR: %58 = phi [ 1, %42 ], [ %36, %31 ]  (__recalc)
  %56 = call i32 @cq_template_icmp_eq_i32_hl(i32 %55, i32 0)    ; IR: %59 = icmp eq %58, 0  [predicate of block %60: !__recalc]
  %57 = call i32 @cq_template_fabs_f64(i32 %7)    ; IR: %61 = fabs(%5)  (block %60)
  %58 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %57, double 0x7FF0000000000000)    ; IR: %62 = isinf(ac)
  %59 = call i32 @cq_template_fabs_f64(i32 %8)    ; IR: %63 = fabs(%6)
  %60 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %59, double 0x7FF0000000000000)    ; IR: %64 = isinf(bd)
  %61 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %58, i32 %60, i32 %61)    ; IR: %65 = or i1 %62, %64
  %62 = call i32 @cq_template_fabs_f64(i32 %9)    ; IR: %66 = fabs(%7)
  %63 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %62, double 0x7FF0000000000000)    ; IR: %67 = isinf(ad)
  %64 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %63, i32 %61, i32 %64)    ; IR: %68 = or i1 %67, %65
  %65 = call i32 @cq_template_fabs_f64(i32 %10)    ; IR: %69 = fabs(%8)
  %66 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %65, double 0x7FF0000000000000)    ; IR: %70 = isinf(bc)
  %67 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %66, i32 %64, i32 %67)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]
  %68 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %54, double 0.000000e+00)    ; IR: %73 = isnan(%57)  (block %72)
  %69 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %54)    ; IR: %74 = copysign(0, %57)
  %70 = call i32 @cq_template_select_f64(i32 %68, i32 %69, i32 %54)    ; IR: %75 = select %73, %74, %57
  %71 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %53, double 0.000000e+00)    ; IR: %76 = isnan(%56)
  %72 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %53)    ; IR: %77 = copysign(0, %56)
  %73 = call i32 @cq_template_select_f64(i32 %71, i32 %72, i32 %53)    ; IR: %78 = select %76, %77, %56
  %74 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %52, double 0.000000e+00)    ; IR: %79 = isnan(%55)
  %75 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %52)    ; IR: %80 = copysign(0, %55)
  %76 = call i32 @cq_template_select_f64(i32 %74, i32 %75, i32 %52)    ; IR: %81 = select %79, %80, %55
  %77 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %51, double 0.000000e+00)    ; IR: %82 = isnan(%54)
  %78 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %51)    ; IR: %83 = copysign(0, %54)
  %79 = call i32 @cq_template_select_f64(i32 %77, i32 %78, i32 %51)    ; IR: %84 = select %82, %83, %54
  %80 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72 relative to %53: %59 & %71  [fresh flag rail]
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %80)    ; IR: P72 = path predicate of block %72 relative to %53: %59 & %71
  %81 = call i32 @cq_template_select_f64(i32 %80, i32 %79, i32 %51)    ; IR: %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (only the %72 path differs)
  %82 = call i32 @cq_template_select_f64(i32 %80, i32 %76, i32 %52)    ; IR: %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  %83 = call i32 @cq_template_select_f64(i32 %80, i32 %73, i32 %53)    ; IR: %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  %84 = call i32 @cq_template_select_f64(i32 %80, i32 %70, i32 %54)    ; IR: %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_not_i1(i32 %67)    ; IR: bracket: %90 reads NOT %67
  %85 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %85)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [no recalculation]
  call void @cqrt_not_i1(i32 %67)    ; IR: bracket (close): %90 reads NOT %67
  %86 = call i32 @cq_template_fneg_f64(i32 %83)    ; IR: %92 = fneg %88  (block %91)
  %87 = call i32 @cq_template_fmul_f64(i32 %81, i32 %86)    ; IR: %93 = fmul %86, %92
  %88 = call i32 @cq_template_fmul_f64(i32 %84, i32 %82)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused product]
  %89 = call i32 @cq_template_fadd_f64(i32 %88, i32 %87)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %90 = call i32 @cq_template_fmul_f64_hl(i32 %89, double 0x7FF0000000000000)    ; IR: %95 = fmul %94, inf
  %91 = call i32 @cq_template_fmul_f64(i32 %82, i32 %83)    ; IR: %96 = fmul %87, %88
  %92 = call i32 @cq_template_fmul_f64(i32 %84, i32 %81)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused product]
  %93 = call i32 @cq_template_fadd_f64(i32 %92, i32 %91)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %94 = call i32 @cq_template_fmul_f64_hl(i32 %93, double 0x7FF0000000000000)    ; IR: %98 = fmul %97, inf
  call void @cqrt_not_i1(i32 %85)    ; IR: bracket: P91 reads NOT %85
  %95 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P91 = path predicate of block %91: %13 & !%90  [fresh flag rail]
  call void @cqrt_and_i1(i32 %15, i32 %85, i32 %95)    ; IR: P91 = path predicate of block %91: %13 & !%90
  call void @cqrt_not_i1(i32 %85)    ; IR: bracket (close): P91 reads NOT %85
  %96 = call i32 @cq_template_select_f64(i32 %95, i32 %90, i32 %11)    ; IR: %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  %97 = call i32 @cq_template_select_f64(i32 %95, i32 %94, i32 %12)    ; IR: %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  call void @cqrt_copy_f64(i32 %96, i32 %0)    ; IR: xor real out of the result rail
  call void @cqrt_copy_f64(i32 %97, i32 %1)    ; IR: xor imaginary out of the result rail
  call void @cq_template_select_f64_unc(i32 %97, i32 %95, i32 %94, i32 %12)    ; IR: uncompute %100
  call void @cqrt_free(i32 %97)    ; IR: release the %100 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %96, i32 %95, i32 %90, i32 %11)    ; IR: uncompute %101
  call void @cqrt_free(i32 %96)    ; IR: release the %101 rail (|0>)
  call void @cqrt_not_i1(i32 %85)    ; IR: bracket: P91 reads NOT %85
  call void @cqrt_and_i1(i32 %15, i32 %85, i32 %95)    ; IR: uncompute P91  [self-inverse]
  call void @cqrt_free(i32 %95)    ; IR: release the P91 rail (|0>)
  call void @cqrt_not_i1(i32 %85)    ; IR: bracket (close): P91 reads NOT %85
  call void @cq_template_fmul_f64_hl_unc(i32 %94, i32 %93, double 0x7FF0000000000000)    ; IR: uncompute %98
  call void @cqrt_free(i32 %94)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %93, i32 %92, i32 %91)    ; IR: uncompute %97  [sum]
  call void @cqrt_free(i32 %93)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %92, i32 %84, i32 %81)    ; IR: uncompute %97  [product]
  call void @cqrt_free(i32 %92)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %91, i32 %82, i32 %83)    ; IR: uncompute %96
  call void @cqrt_free(i32 %91)    ; IR: release the %96 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %90, i32 %89, double 0x7FF0000000000000)    ; IR: uncompute %95
  call void @cqrt_free(i32 %90)    ; IR: release the %95 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %89, i32 %88, i32 %87)    ; IR: uncompute %94  [sum]
  call void @cqrt_free(i32 %89)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %88, i32 %84, i32 %82)    ; IR: uncompute %94  [product]
  call void @cqrt_free(i32 %88)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %87, i32 %81, i32 %86)    ; IR: uncompute %93
  call void @cqrt_free(i32 %87)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %86, i32 %83)    ; IR: uncompute %92
  call void @cqrt_free(i32 %86)    ; IR: release the %92 rail (|0>)
  call void @cqrt_not_i1(i32 %67)    ; IR: bracket: %90 reads NOT %67
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %85)    ; IR: uncompute %90  [self-inverse]
  call void @cqrt_free(i32 %85)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %67)    ; IR: bracket (close): %90 reads NOT %67
  call void @cq_template_select_f64_unc(i32 %84, i32 %80, i32 %70, i32 %54)    ; IR: uncompute %89
  call void @cqrt_free(i32 %84)    ; IR: release the %89 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %83, i32 %80, i32 %73, i32 %53)    ; IR: uncompute %88
  call void @cqrt_free(i32 %83)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %80, i32 %76, i32 %52)    ; IR: uncompute %87
  call void @cqrt_free(i32 %82)    ; IR: release the %87 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %81, i32 %80, i32 %79, i32 %51)    ; IR: uncompute %86
  call void @cqrt_free(i32 %81)    ; IR: release the %86 rail (|0>)
  call void @cqrt_and_i1(i32 %56, i32 %67, i32 %80)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %80)    ; IR: release the P72 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %79, i32 %77, i32 %78, i32 %51)    ; IR: uncompute %84
  call void @cqrt_free(i32 %79)    ; IR: release the %84 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %78, double 0.000000e+00, i32 %51)    ; IR: uncompute %83
  call void @cqrt_free(i32 %78)    ; IR: release the %83 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %77, i32 %51, double 0.000000e+00)    ; IR: uncompute %82
  call void @cqrt_free(i32 %77)    ; IR: release the %82 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %76, i32 %74, i32 %75, i32 %52)    ; IR: uncompute %81
  call void @cqrt_free(i32 %76)    ; IR: release the %81 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %75, double 0.000000e+00, i32 %52)    ; IR: uncompute %80
  call void @cqrt_free(i32 %75)    ; IR: release the %80 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %74, i32 %52, double 0.000000e+00)    ; IR: uncompute %79
  call void @cqrt_free(i32 %74)    ; IR: release the %79 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %73, i32 %71, i32 %72, i32 %53)    ; IR: uncompute %78
  call void @cqrt_free(i32 %73)    ; IR: release the %78 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %72, double 0.000000e+00, i32 %53)    ; IR: uncompute %77
  call void @cqrt_free(i32 %72)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %71, i32 %53, double 0.000000e+00)    ; IR: uncompute %76
  call void @cqrt_free(i32 %71)    ; IR: release the %76 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %70, i32 %68, i32 %69, i32 %54)    ; IR: uncompute %75
  call void @cqrt_free(i32 %70)    ; IR: release the %75 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %69, double 0.000000e+00, i32 %54)    ; IR: uncompute %74
  call void @cqrt_free(i32 %69)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %68, i32 %54, double 0.000000e+00)    ; IR: uncompute %73
  call void @cqrt_free(i32 %68)    ; IR: release the %73 rail (|0>)
  call void @cqrt_or_i1(i32 %66, i32 %64, i32 %67)    ; IR: uncompute %71  [self-inverse]
  call void @cqrt_free(i32 %67)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %66, i32 %65, double 0x7FF0000000000000)    ; IR: uncompute %70
  call void @cqrt_free(i32 %66)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %65, i32 %10)    ; IR: uncompute %69
  call void @cqrt_free(i32 %65)    ; IR: release the %69 rail (|0>)
  call void @cqrt_or_i1(i32 %63, i32 %61, i32 %64)    ; IR: uncompute %68  [self-inverse]
  call void @cqrt_free(i32 %64)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %63, i32 %62, double 0x7FF0000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %63)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %62, i32 %9)    ; IR: uncompute %66
  call void @cqrt_free(i32 %62)    ; IR: release the %66 rail (|0>)
  call void @cqrt_or_i1(i32 %58, i32 %60, i32 %61)    ; IR: uncompute %65  [self-inverse]
  call void @cqrt_free(i32 %61)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %60, i32 %59, double 0x7FF0000000000000)    ; IR: uncompute %64
  call void @cqrt_free(i32 %60)    ; IR: release the %64 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %59, i32 %8)    ; IR: uncompute %63
  call void @cqrt_free(i32 %59)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %58, i32 %57, double 0x7FF0000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %58)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %57, i32 %7)    ; IR: uncompute %61
  call void @cqrt_free(i32 %57)    ; IR: release the %61 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %56, i32 %55, i32 0)    ; IR: uncompute %59
  call void @cqrt_free(i32 %56)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %55, i32 %40, i32 1, i32 %35)    ; IR: uncompute %58
  call void @cqrt_free(i32 %55)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %54, i32 %40, i32 %47, i32 %34)    ; IR: uncompute %57
  call void @cqrt_free(i32 %54)    ; IR: release the %57 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %53, i32 %40, i32 %50, i32 %33)    ; IR: uncompute %56
  call void @cqrt_free(i32 %53)    ; IR: release the %56 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %52, i32 %40, i32 %42, i32 %32)    ; IR: uncompute %55
  call void @cqrt_free(i32 %52)    ; IR: release the %55 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %51, i32 %40, i32 %44, i32 %31)    ; IR: uncompute %54
  call void @cqrt_free(i32 %51)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %50, i32 %48, i32 %49, i32 %33)    ; IR: uncompute %52
  call void @cqrt_free(i32 %50)    ; IR: release the %52 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %49, double 0.000000e+00, i32 %33)    ; IR: uncompute %51
  call void @cqrt_free(i32 %49)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %48, i32 %33, double 0.000000e+00)    ; IR: uncompute %50
  call void @cqrt_free(i32 %48)    ; IR: release the %50 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %47, i32 %45, i32 %46, i32 %34)    ; IR: uncompute %49
  call void @cqrt_free(i32 %47)    ; IR: release the %49 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %46, double 0.000000e+00, i32 %34)    ; IR: uncompute %48
  call void @cqrt_free(i32 %46)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %45, i32 %34, double 0.000000e+00)    ; IR: uncompute %47
  call void @cqrt_free(i32 %45)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %44, i32 %43, i32 %31)    ; IR: uncompute %46
  call void @cqrt_free(i32 %44)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %43, i32 %39)    ; IR: uncompute %45
  call void @cqrt_free(i32 %43)    ; IR: release the %45 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %42, i32 %41, i32 %32)    ; IR: uncompute %44
  call void @cqrt_free(i32 %42)    ; IR: release the %44 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %41, i32 %37)    ; IR: uncompute %43
  call void @cqrt_free(i32 %41)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %39, i32 %37, i32 %40)    ; IR: uncompute %41  [self-inverse]
  call void @cqrt_free(i32 %40)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %39, i32 %38, double 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %39)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %38, i32 %31)    ; IR: uncompute %39
  call void @cqrt_free(i32 %38)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %37, i32 %36, double 0x7FF0000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %37)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %36, i32 %32)    ; IR: uncompute %37
  call void @cqrt_free(i32 %36)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %35, i32 %20, i32 1, i32 0)    ; IR: uncompute %36
  call void @cqrt_free(i32 %35)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %34, i32 %20, i32 %22, i32 %2)    ; IR: uncompute %35
  call void @cqrt_free(i32 %34)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %20, i32 %24, i32 %3)    ; IR: uncompute %34
  call void @cqrt_free(i32 %33)    ; IR: release the %34 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %32, i32 %20, double %27, double %4)    ; IR: uncompute %33
  call void @cqrt_free(i32 %32)    ; IR: release the %33 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %31, i32 %20, double %30, double %5)    ; IR: uncompute %32
  call void @cqrt_free(i32 %31)    ; IR: release the %32 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %24, i32 %23, i32 %3)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %23, i32 %19)    ; IR: uncompute %23
  call void @cqrt_free(i32 %23)    ; IR: release the %23 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %22, i32 %21, i32 %2)    ; IR: uncompute %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %21, i32 %17)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %17, i32 %19, i32 %20)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %20)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %19, i32 %18, double 0x7FF0000000000000)    ; IR: uncompute %18
  call void @cqrt_free(i32 %19)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %18, i32 %3)    ; IR: uncompute %17
  call void @cqrt_free(i32 %18)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %17, i32 %16, double 0x7FF0000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %17)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %16, i32 %2)    ; IR: uncompute %15
  call void @cqrt_free(i32 %16)    ; IR: release the %15 rail (|0>)
  call void @cqrt_and_i1(i32 %13, i32 %14, i32 %15)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %14, i32 %12, double 0.000000e+00)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %13, i32 %11, double 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %12, i32 %10, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %11, i32 %7, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %10, i32 %3, double %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %9, i32 %2, double %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %3, double %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %2, double %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_uno_f64_hl(i32, double)
declare void @cq_template_fcmp_uno_f64_hl_unc(i32, i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_fcmp_oeq_f64_hl(i32, double)
declare void @cq_template_fcmp_oeq_f64_hl_unc(i32, i32, double)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_uitofp_i1_to_f64(i32)
declare void @cq_template_uitofp_i1_to_f64_unc(i32, i32)
declare i32 @cq_template_copysign_f64(i32, i32)
declare void @cq_template_copysign_f64_unc(i32, i32, i32)
declare double @llvm.copysign.f64(double, double)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_copysign_f64_lh(double, i32)
declare void @cq_template_copysign_f64_lh_unc(i32, double, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_fneg_f64(i32)
declare void @cq_template_fneg_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare void @cqrt_copy_f64(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
