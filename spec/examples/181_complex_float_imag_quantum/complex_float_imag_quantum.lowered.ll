; HAND-WRITTEN. Rules: 26, 25, 18, 1, 3, 8, 9, 4, 5.
; Checked: crealf(s) + cimagf(s) + crealf(c) - cimagf(c) (measured, %31 -> %32).
; Clean: every flag, path-predicate and arithmetic rail of the entry and of the clone __cq_q___mulsc3_1100 (the clone's
; two lane result rails are zeroed by its _unc twin and freed by the caller), all freed before the measurement.
; Kept: im (%6, the rotated register) and the measured result rail %31; nothing else.
; Rotations: (Ry, im, ti, 1); the clone holds none.
; float _Complex with the IMAGINARY part quantum: 171's shape at float width on the <2 x float> ABI (173). Taint flows
; through clang's Annex G expansion exactly as rule 3 says: z = re + im*I makes the real part `im * 0 + re` quantum as
; well (%7, %8), so z * w reaches __mulsc3 with mask 1100 (a = crealf(z) and b = im quantum, c, d classical), NOT the
; 0100 the .c comment guesses: the mask is taken from the SSA values at the call. One clone of the compiler-rt body,
; returning the <2 x float> as { i32, i32 } (two lane handles); the extractelements are lane moves and get no gate. The
; body has 173's -O1 shape (fcmp ord + or into the early exit, the %64 chain as `fcmp une` + and, block %95 under !%13 &
; !%94): with both a and b quantum every fabs/isinf/copysign of the body is a template, the only classical values are
; the c/d NaN fixes (%27-%32), which enter the merges as literal arms of select_f32_ll. The entry's two `fcmp uno`
; branches conjoin into the P20 predicate (rule 8) and the clone's lanes are merged with the fast-path values by two
; selects on it (rule 9). conjf(p) is representation only: -O1 folds `- cimagf(conj p)` into `+ cimagf(p)`, so the sum
; is five fadd templates. Everything but the result rail is uncomputed LIFO (the clone's copies through its _unc twin)
; before the measurement. The recalculation's two llvm.fmuladd.f32 calls (%98, %101) are UNFUSED (§2, cf. 14, 69): a
; fmul_f32 into a fresh product rail, then an fadd_f32 of the product and the addend; the product is uncomputed right
; after the sum it fed (rule 5, LIFO), in the clone and again in its _unc twin's recomputation.
source_filename = "complex_float_imag_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define float @complex_float_imag_quantum(float noundef %0, float noundef %1, double noundef %2, float noundef %3, float noundef %4) {
  %6 = call i32 @cqrt_alloc_f32(float %1)    ; IR: %6 = cq_theta_f32(%1, %2)  [register im]
  call void @cqrt_ry_f32(i32 %6, double %2)    ; IR: %6 = cq_theta_f32(%1, %2)  [Ry]
  %7 = call i32 @cq_template_fmul_f32_hl(i32 %6, float 0.000000e+00)    ; IR: %7 = fmul %6, 0  (im * I: real part im*0, quantum by rule 3)
  %8 = call i32 @cq_template_fadd_f32_hl(i32 %7, float %0)    ; IR: %8 = fadd %7, %0  (real part of z)
  %9 = fmul float %4, 0.000000e+00    ; IR: %9 = fmul %4, 0  (classical)
  %10 = fadd float %9, %3    ; IR: %10 = fadd %9, %3  (real part of w)  (classical)
  %11 = call i32 @cq_template_fmul_f32_hl(i32 %8, float %10)    ; IR: %11 = fmul %10, %8  (commutative, quantum operand first)
  %12 = call i32 @cq_template_fmul_f32_hl(i32 %6, float %4)    ; IR: %12 = fmul %6, %4
  %13 = call i32 @cq_template_fmul_f32_hl(i32 %8, float %4)    ; IR: %13 = fmul %8, %4
  %14 = call i32 @cq_template_fmul_f32_hl(i32 %6, float %10)    ; IR: %14 = fmul %10, %6  (commutative, quantum operand first)
  %15 = call i32 @cq_template_fsub_f32(i32 %11, i32 %12)    ; IR: %15 = fsub %11, %12  (fast-path real part)
  %16 = call i32 @cq_template_fadd_f32(i32 %14, i32 %13)    ; IR: %16 = fadd %14, %13  (fast-path imaginary part)
  %17 = call i32 @cq_template_fcmp_uno_f32_hl(i32 %15, float 0.000000e+00)    ; IR: %17 = fcmp uno %15, 0  [predicate of block %18]
  %18 = call i32 @cq_template_fcmp_uno_f32_hl(i32 %16, float 0.000000e+00)    ; IR: %19 = fcmp uno %16, 0
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P20 = path predicate of block %20 = %17 & %19  [fresh flag rail]
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: P20 = path predicate of block %20 = %17 & %19
  %20 = call fastcc { i32, i32 } @__cq_q___mulsc3_1100(i32 %8, i32 %6, float %10, float %4)    ; IR: %21 = call @__mulsc3(%8, %6, %10, %4), quantum clone (args 0 and 1 quantum: mask 1100), called unconditionally
  %21 = extractvalue { i32, i32 } %20, 0    ; IR: extractelement/extractvalue %21, 0  (handle; a lane move, no gate)
  %22 = extractvalue { i32, i32 } %20, 1    ; IR: extractelement/extractvalue %21, 1  (handle; a lane move, no gate)
  %23 = call i32 @cq_template_select_f32(i32 %19, i32 %21, i32 %15)    ; IR: %25 = phi [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]  (real part of p)
  %24 = call i32 @cq_template_select_f32(i32 %19, i32 %22, i32 %16)    ; IR: %26 = phi [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]  (imaginary part of p)
  %25 = call i32 @cq_template_fadd_f32_hl(i32 %6, float %4)    ; IR: %27 = fadd %6, %4  (cimag(s))
  %26 = call i32 @cq_template_fadd_f32_hl(i32 %8, float %10)    ; IR: %28 = fadd %10, %8  (creal(s))  (commutative, quantum operand first)
  %27 = call i32 @cq_template_fadd_f32(i32 %25, i32 %26)    ; IR: %29 = fadd %27, %28
  %28 = call i32 @cq_template_fadd_f32(i32 %27, i32 %23)    ; IR: %30 = fadd %29, %25  (+ creal(conj p))
  %29 = call i32 @cq_template_fadd_f32(i32 %28, i32 %24)    ; IR: %31 = fadd %30, %26  (- cimag(conj p) = + cimag(p), folded by -O1)  [result rail]
  call void @cq_template_fadd_f32_unc(i32 %28, i32 %27, i32 %23)    ; IR: uncompute %30
  call void @cqrt_free(i32 %28)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %27, i32 %25, i32 %26)    ; IR: uncompute %29
  call void @cqrt_free(i32 %27)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fadd_f32_hl_unc(i32 %26, i32 %8, float %10)    ; IR: uncompute %28
  call void @cqrt_free(i32 %26)    ; IR: release the %28 rail (|0>)
  call void @cq_template_fadd_f32_hl_unc(i32 %25, i32 %6, float %4)    ; IR: uncompute %27
  call void @cqrt_free(i32 %25)    ; IR: release the %27 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %24, i32 %19, i32 %22, i32 %16)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %23, i32 %19, i32 %21, i32 %15)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call fastcc void @__cq_q___mulsc3_1100_unc(i32 %21, i32 %22, i32 %8, i32 %6, float %10, float %4)    ; IR: uncompute the result rails of %21 through the twin
  call void @cqrt_free(i32 %21)    ; IR: release the real-part result rail (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the imaginary-part result rail (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: uncompute P20  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the P20 rail (|0>)
  call void @cq_template_fcmp_uno_f32_hl_unc(i32 %18, i32 %16, float 0.000000e+00)    ; IR: uncompute %19
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_uno_f32_hl_unc(i32 %17, i32 %15, float 0.000000e+00)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %16, i32 %14, i32 %13)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fsub_f32_unc(i32 %15, i32 %11, i32 %12)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %14, i32 %6, float %10)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %13, i32 %8, float %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %12, i32 %6, float %4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %11, i32 %8, float %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f32_hl_unc(i32 %8, i32 %7, float %0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %7, i32 %6, float 0.000000e+00)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %30 = call float @cqrt_measure_f32(i32 %29)    ; IR: %32 = cq_measure_f32(%31)
  ret float %30    ; IR: ret %32
}

define internal fastcc { i32, i32 } @__cq_q___mulsc3_1100(i32 %0, i32 %1, float %2, float %3) {
  %5 = call i32 @cq_template_fmul_f32_hl(i32 %0, float %2)    ; IR: %5 = fmul %0, %2  (a*c)
  %6 = call i32 @cq_template_fmul_f32_hl(i32 %1, float %3)    ; IR: %6 = fmul %1, %3  (b*d)
  %7 = call i32 @cq_template_fmul_f32_hl(i32 %0, float %3)    ; IR: %7 = fmul %0, %3  (a*d)
  %8 = call i32 @cq_template_fmul_f32_hl(i32 %1, float %2)    ; IR: %8 = fmul %1, %2  (b*c)
  %9 = call i32 @cq_template_fsub_f32(i32 %5, i32 %6)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %10 = call i32 @cq_template_fadd_f32(i32 %8, i32 %7)    ; IR: %10 = fadd %8, %7  (imaginary part)
  %11 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %9, float 0.000000e+00)    ; IR: %11 = fcmp ord %9, 0  (!isnan)
  %12 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %10, float 0.000000e+00)    ; IR: %12 = fcmp ord %10, 0
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %11, i32 %12, i32 %13)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]
  %14 = call i32 @cq_template_fabs_f32(i32 %0)    ; IR: %15 = fabs(a)  (block %14)
  %15 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %14, float 0x7FF0000000000000)    ; IR: %16 = isinf(a)
  %16 = call i32 @cq_template_fabs_f32(i32 %1)    ; IR: %17 = fabs(b)
  %17 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %16, float 0x7FF0000000000000)    ; IR: %18 = isinf(b)
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %17, i32 %15, i32 %18)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]
  %19 = call i32 @cq_template_uitofp_i1_to_f32(i32 %15)    ; IR: %21 = uitofp i1 %16  (block %20)
  %20 = call i32 @cq_template_copysign_f32(i32 %19, i32 %0)    ; IR: %22 = copysign(%21, a)
  %21 = call i32 @cq_template_fabs_f32(i32 %1)    ; IR: %23 = fabs(b)  (recomputed by -O1 inside block %20)
  %22 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %21, float 0x7FF0000000000000)    ; IR: %24 = isinf(b)
  %23 = call i32 @cq_template_uitofp_i1_to_f32(i32 %22)    ; IR: %25 = uitofp i1 %24
  %24 = call i32 @cq_template_copysign_f32(i32 %23, i32 %1)    ; IR: %26 = copysign(%25, b)
  %25 = fcmp ord float %2, 0.000000e+00    ; IR: %27 = fcmp ord c, 0  (!isnan(c))  (classical)
  %26 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %2)    ; IR: %28 = copysign(0, c)  (classical)
  %27 = select i1 %25, float %2, float %26    ; IR: %29 = select %27, %2, %28  (classical)
  %28 = fcmp ord float %3, 0.000000e+00    ; IR: %30 = fcmp ord d, 0  (!isnan(d))  (classical)
  %29 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %3)    ; IR: %31 = copysign(0, d)  (classical)
  %30 = select i1 %28, float %3, float %29    ; IR: %32 = select %30, %3, %31  (classical)
  %31 = call i32 @cq_template_select_f32_ll(i32 %18, float %30, float %3)    ; IR: %34 = phi [ %32, %20 ], [ %3, %14 ]  (merge of block %20 on %19)
  %32 = call i32 @cq_template_select_f32_ll(i32 %18, float %27, float %2)    ; IR: %35 = phi [ %29, %20 ], [ %2, %14 ]
  %33 = call i32 @cq_template_select_f32(i32 %18, i32 %24, i32 %1)    ; IR: %36 = phi [ %26, %20 ], [ %1, %14 ]
  %34 = call i32 @cq_template_select_f32(i32 %18, i32 %20, i32 %0)    ; IR: %37 = phi [ %22, %20 ], [ %0, %14 ]
  %35 = call i32 @cq_template_select_i32_ll(i32 %18, i32 1, i32 0)    ; IR: %38 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %36 = call i32 @cq_template_fabs_f32(i32 %32)    ; IR: %39 = fabs(%35)  (block %33)
  %37 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %36, float 0x7FF0000000000000)    ; IR: %40 = isinf(%35)
  %38 = call i32 @cq_template_fabs_f32(i32 %31)    ; IR: %41 = fabs(%34)
  %39 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %38, float 0x7FF0000000000000)    ; IR: %42 = isinf(%34)
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %39, i32 %37, i32 %40)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]
  %41 = call i32 @cq_template_uitofp_i1_to_f32(i32 %37)    ; IR: %45 = uitofp i1 %40  (block %44)
  %42 = call i32 @cq_template_copysign_f32(i32 %41, i32 %32)    ; IR: %46 = copysign(%45, %35)
  %43 = call i32 @cq_template_fabs_f32(i32 %31)    ; IR: %47 = fabs(%34)
  %44 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %43, float 0x7FF0000000000000)    ; IR: %48 = isinf(%34)
  %45 = call i32 @cq_template_uitofp_i1_to_f32(i32 %44)    ; IR: %49 = uitofp i1 %48
  %46 = call i32 @cq_template_copysign_f32(i32 %45, i32 %31)    ; IR: %50 = copysign(%49, %34)
  %47 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %34, float 0.000000e+00)    ; IR: %51 = fcmp ord %37, 0
  %48 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %34)    ; IR: %52 = copysign(0, %37)
  %49 = call i32 @cq_template_select_f32(i32 %47, i32 %34, i32 %48)    ; IR: %53 = select %51, %37, %52
  %50 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %33, float 0.000000e+00)    ; IR: %54 = fcmp ord %36, 0
  %51 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %33)    ; IR: %55 = copysign(0, %36)
  %52 = call i32 @cq_template_select_f32(i32 %50, i32 %33, i32 %51)    ; IR: %56 = select %54, %36, %55
  %53 = call i32 @cq_template_select_f32(i32 %40, i32 %46, i32 %31)    ; IR: %58 = phi [ %50, %44 ], [ %34, %33 ]  (merge of block %44 on %43)
  %54 = call i32 @cq_template_select_f32(i32 %40, i32 %42, i32 %32)    ; IR: %59 = phi [ %46, %44 ], [ %35, %33 ]
  %55 = call i32 @cq_template_select_f32(i32 %40, i32 %52, i32 %33)    ; IR: %60 = phi [ %56, %44 ], [ %36, %33 ]
  %56 = call i32 @cq_template_select_f32(i32 %40, i32 %49, i32 %34)    ; IR: %61 = phi [ %53, %44 ], [ %37, %33 ]
  %57 = call i32 @cq_template_select_i32_lh(i32 %40, i32 1, i32 %35)    ; IR: %62 = phi [ 1, %44 ], [ %38, %33 ]  (__recalc)
  %58 = call i32 @cq_template_icmp_eq_i32_hl(i32 %57, i32 0)    ; IR: %63 = icmp eq %62, 0  [predicate of block %64: !__recalc]
  %59 = call i32 @cq_template_fabs_f32(i32 %5)    ; IR: %65 = fabs(%5)  (block %64)
  %60 = call i32 @cq_template_fcmp_une_f32_hl(i32 %59, float 0x7FF0000000000000)    ; IR: %66 = !isinf(ac)
  %61 = call i32 @cq_template_fabs_f32(i32 %6)    ; IR: %67 = fabs(%6)
  %62 = call i32 @cq_template_fcmp_une_f32_hl(i32 %61, float 0x7FF0000000000000)    ; IR: %68 = !isinf(bd)
  %63 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %69 = and i1 %66, %68  [fresh flag rail]
  call void @cqrt_and_i1(i32 %60, i32 %62, i32 %63)    ; IR: %69 = and i1 %66, %68
  %64 = call i32 @cq_template_fabs_f32(i32 %7)    ; IR: %70 = fabs(%7)
  %65 = call i32 @cq_template_fcmp_une_f32_hl(i32 %64, float 0x7FF0000000000000)    ; IR: %71 = !isinf(ad)
  %66 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %72 = and i1 %71, %69  [fresh flag rail]
  call void @cqrt_and_i1(i32 %65, i32 %63, i32 %66)    ; IR: %72 = and i1 %71, %69
  %67 = call i32 @cq_template_fabs_f32(i32 %8)    ; IR: %73 = fabs(%8)
  %68 = call i32 @cq_template_fcmp_une_f32_hl(i32 %67, float 0x7FF0000000000000)    ; IR: %74 = !isinf(bc)
  %69 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %68, i32 %66, i32 %69)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]
  %70 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %56, float 0.000000e+00)    ; IR: %77 = fcmp ord %61, 0  (block %76)
  %71 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %56)    ; IR: %78 = copysign(0, %61)
  %72 = call i32 @cq_template_select_f32(i32 %70, i32 %56, i32 %71)    ; IR: %79 = select %77, %61, %78
  %73 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %55, float 0.000000e+00)    ; IR: %80 = fcmp ord %60, 0
  %74 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %55)    ; IR: %81 = copysign(0, %60)
  %75 = call i32 @cq_template_select_f32(i32 %73, i32 %55, i32 %74)    ; IR: %82 = select %80, %60, %81
  %76 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %54, float 0.000000e+00)    ; IR: %83 = fcmp ord %59, 0
  %77 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %54)    ; IR: %84 = copysign(0, %59)
  %78 = call i32 @cq_template_select_f32(i32 %76, i32 %54, i32 %77)    ; IR: %85 = select %83, %59, %84
  %79 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %53, float 0.000000e+00)    ; IR: %86 = fcmp ord %58, 0
  %80 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %53)    ; IR: %87 = copysign(0, %58)
  %81 = call i32 @cq_template_select_f32(i32 %79, i32 %53, i32 %80)    ; IR: %88 = select %86, %58, %87
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket: P76 reads NOT %75
  %82 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75  [fresh flag rail]
  call void @cqrt_and_i1(i32 %58, i32 %69, i32 %82)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket (close): P76 reads NOT %75
  %83 = call i32 @cq_template_select_f32(i32 %82, i32 %81, i32 %53)    ; IR: %90 = phi [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]  (only the %76 path differs)
  %84 = call i32 @cq_template_select_f32(i32 %82, i32 %78, i32 %54)    ; IR: %91 = phi [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %85 = call i32 @cq_template_select_f32(i32 %82, i32 %75, i32 %55)    ; IR: %92 = phi [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %86 = call i32 @cq_template_select_f32(i32 %82, i32 %72, i32 %56)    ; IR: %93 = phi [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %87 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %58, i32 %69, i32 %87)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]
  %88 = call i32 @cq_template_fneg_f32(i32 %85)    ; IR: %96 = fneg %92  (block %95)
  %89 = call i32 @cq_template_fmul_f32(i32 %83, i32 %88)    ; IR: %97 = fmul %90, %96
  %90 = call i32 @cq_template_fmul_f32(i32 %86, i32 %84)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused product]
  %91 = call i32 @cq_template_fadd_f32(i32 %90, i32 %89)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused sum]
  %92 = call i32 @cq_template_fmul_f32_hl(i32 %91, float 0x7FF0000000000000)    ; IR: %99 = fmul %98, inf
  %93 = call i32 @cq_template_fmul_f32(i32 %84, i32 %85)    ; IR: %100 = fmul %91, %92
  %94 = call i32 @cq_template_fmul_f32(i32 %86, i32 %83)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused product]
  %95 = call i32 @cq_template_fadd_f32(i32 %94, i32 %93)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused sum]
  %96 = call i32 @cq_template_fmul_f32_hl(i32 %95, float 0x7FF0000000000000)    ; IR: %102 = fmul %101, inf
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket: P95 reads NOT %94
  %97 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P95 = path predicate of block %95: !%13 & !%94  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %87, i32 %97)    ; IR: P95 = path predicate of block %95: !%13 & !%94
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket (close): P95 reads NOT %94
  %98 = call i32 @cq_template_select_f32(i32 %97, i32 %92, i32 %9)    ; IR: %105 = phi [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]  (real result)
  %99 = call i32 @cq_template_select_f32(i32 %97, i32 %96, i32 %10)    ; IR: %104 = phi [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]  (imaginary result)
  %100 = call i32 @cqrt_alloc_f32(float 0.000000e+00)    ; IR: ret  [result rail: lane 0 (real)]
  call void @cqrt_copy_f32(i32 %98, i32 %100)    ; IR: copy lane 0 (real) out (rule 18)
  %101 = call i32 @cqrt_alloc_f32(float 0.000000e+00)    ; IR: ret  [result rail: lane 1 (imaginary)]
  call void @cqrt_copy_f32(i32 %99, i32 %101)    ; IR: copy lane 1 (imaginary) out (rule 18)
  call void @cq_template_select_f32_unc(i32 %99, i32 %97, i32 %96, i32 %10)    ; IR: uncompute %104
  call void @cqrt_free(i32 %99)    ; IR: release the %104 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %98, i32 %97, i32 %92, i32 %9)    ; IR: uncompute %105
  call void @cqrt_free(i32 %98)    ; IR: release the %105 rail (|0>)
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket: P95 reads NOT %94
  call void @cqrt_and_i1(i32 %13, i32 %87, i32 %97)    ; IR: uncompute P95  [self-inverse]
  call void @cqrt_free(i32 %97)    ; IR: release the P95 rail (|0>)
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket (close): P95 reads NOT %94
  call void @cq_template_fmul_f32_hl_unc(i32 %96, i32 %95, float 0x7FF0000000000000)    ; IR: uncompute %102
  call void @cqrt_free(i32 %96)    ; IR: release the %102 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %95, i32 %94, i32 %93)    ; IR: uncompute %101  [sum]
  call void @cqrt_free(i32 %95)    ; IR: release the %101 rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %94, i32 %86, i32 %83)    ; IR: uncompute %101  [product]
  call void @cqrt_free(i32 %94)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %93, i32 %84, i32 %85)    ; IR: uncompute %100
  call void @cqrt_free(i32 %93)    ; IR: release the %100 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %92, i32 %91, float 0x7FF0000000000000)    ; IR: uncompute %99
  call void @cqrt_free(i32 %92)    ; IR: release the %99 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %91, i32 %90, i32 %89)    ; IR: uncompute %98  [sum]
  call void @cqrt_free(i32 %91)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %90, i32 %86, i32 %84)    ; IR: uncompute %98  [product]
  call void @cqrt_free(i32 %90)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %89, i32 %83, i32 %88)    ; IR: uncompute %97
  call void @cqrt_free(i32 %89)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fneg_f32_unc(i32 %88, i32 %85)    ; IR: uncompute %96
  call void @cqrt_free(i32 %88)    ; IR: release the %96 rail (|0>)
  call void @cqrt_and_i1(i32 %58, i32 %69, i32 %87)    ; IR: uncompute %94  [self-inverse]
  call void @cqrt_free(i32 %87)    ; IR: release the %94 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %86, i32 %82, i32 %72, i32 %56)    ; IR: uncompute %93
  call void @cqrt_free(i32 %86)    ; IR: release the %93 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %85, i32 %82, i32 %75, i32 %55)    ; IR: uncompute %92
  call void @cqrt_free(i32 %85)    ; IR: release the %92 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %84, i32 %82, i32 %78, i32 %54)    ; IR: uncompute %91
  call void @cqrt_free(i32 %84)    ; IR: release the %91 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %83, i32 %82, i32 %81, i32 %53)    ; IR: uncompute %90
  call void @cqrt_free(i32 %83)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket: P76 reads NOT %75
  call void @cqrt_and_i1(i32 %58, i32 %69, i32 %82)    ; IR: uncompute P76  [self-inverse]
  call void @cqrt_free(i32 %82)    ; IR: release the P76 rail (|0>)
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket (close): P76 reads NOT %75
  call void @cq_template_select_f32_unc(i32 %81, i32 %79, i32 %53, i32 %80)    ; IR: uncompute %88
  call void @cqrt_free(i32 %81)    ; IR: release the %88 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %80, float 0.000000e+00, i32 %53)    ; IR: uncompute %87
  call void @cqrt_free(i32 %80)    ; IR: release the %87 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %79, i32 %53, float 0.000000e+00)    ; IR: uncompute %86
  call void @cqrt_free(i32 %79)    ; IR: release the %86 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %78, i32 %76, i32 %54, i32 %77)    ; IR: uncompute %85
  call void @cqrt_free(i32 %78)    ; IR: release the %85 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %77, float 0.000000e+00, i32 %54)    ; IR: uncompute %84
  call void @cqrt_free(i32 %77)    ; IR: release the %84 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %76, i32 %54, float 0.000000e+00)    ; IR: uncompute %83
  call void @cqrt_free(i32 %76)    ; IR: release the %83 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %75, i32 %73, i32 %55, i32 %74)    ; IR: uncompute %82
  call void @cqrt_free(i32 %75)    ; IR: release the %82 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %74, float 0.000000e+00, i32 %55)    ; IR: uncompute %81
  call void @cqrt_free(i32 %74)    ; IR: release the %81 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %73, i32 %55, float 0.000000e+00)    ; IR: uncompute %80
  call void @cqrt_free(i32 %73)    ; IR: release the %80 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %72, i32 %70, i32 %56, i32 %71)    ; IR: uncompute %79
  call void @cqrt_free(i32 %72)    ; IR: release the %79 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %71, float 0.000000e+00, i32 %56)    ; IR: uncompute %78
  call void @cqrt_free(i32 %71)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %70, i32 %56, float 0.000000e+00)    ; IR: uncompute %77
  call void @cqrt_free(i32 %70)    ; IR: release the %77 rail (|0>)
  call void @cqrt_and_i1(i32 %68, i32 %66, i32 %69)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %69)    ; IR: release the %75 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %68, i32 %67, float 0x7FF0000000000000)    ; IR: uncompute %74
  call void @cqrt_free(i32 %68)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %67, i32 %8)    ; IR: uncompute %73
  call void @cqrt_free(i32 %67)    ; IR: release the %73 rail (|0>)
  call void @cqrt_and_i1(i32 %65, i32 %63, i32 %66)    ; IR: uncompute %72  [self-inverse]
  call void @cqrt_free(i32 %66)    ; IR: release the %72 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %65, i32 %64, float 0x7FF0000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %65)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %64, i32 %7)    ; IR: uncompute %70
  call void @cqrt_free(i32 %64)    ; IR: release the %70 rail (|0>)
  call void @cqrt_and_i1(i32 %60, i32 %62, i32 %63)    ; IR: uncompute %69  [self-inverse]
  call void @cqrt_free(i32 %63)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %62, i32 %61, float 0x7FF0000000000000)    ; IR: uncompute %68
  call void @cqrt_free(i32 %62)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %61, i32 %6)    ; IR: uncompute %67
  call void @cqrt_free(i32 %61)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %60, i32 %59, float 0x7FF0000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %60)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %59, i32 %5)    ; IR: uncompute %65
  call void @cqrt_free(i32 %59)    ; IR: release the %65 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %58, i32 %57, i32 0)    ; IR: uncompute %63
  call void @cqrt_free(i32 %58)    ; IR: release the %63 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %57, i32 %40, i32 1, i32 %35)    ; IR: uncompute %62
  call void @cqrt_free(i32 %57)    ; IR: release the %62 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %56, i32 %40, i32 %49, i32 %34)    ; IR: uncompute %61
  call void @cqrt_free(i32 %56)    ; IR: release the %61 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %55, i32 %40, i32 %52, i32 %33)    ; IR: uncompute %60
  call void @cqrt_free(i32 %55)    ; IR: release the %60 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %54, i32 %40, i32 %42, i32 %32)    ; IR: uncompute %59
  call void @cqrt_free(i32 %54)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %53, i32 %40, i32 %46, i32 %31)    ; IR: uncompute %58
  call void @cqrt_free(i32 %53)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %52, i32 %50, i32 %33, i32 %51)    ; IR: uncompute %56
  call void @cqrt_free(i32 %52)    ; IR: release the %56 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %51, float 0.000000e+00, i32 %33)    ; IR: uncompute %55
  call void @cqrt_free(i32 %51)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %50, i32 %33, float 0.000000e+00)    ; IR: uncompute %54
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %49, i32 %47, i32 %34, i32 %48)    ; IR: uncompute %53
  call void @cqrt_free(i32 %49)    ; IR: release the %53 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %48, float 0.000000e+00, i32 %34)    ; IR: uncompute %52
  call void @cqrt_free(i32 %48)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %47, i32 %34, float 0.000000e+00)    ; IR: uncompute %51
  call void @cqrt_free(i32 %47)    ; IR: release the %51 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %46, i32 %45, i32 %31)    ; IR: uncompute %50
  call void @cqrt_free(i32 %46)    ; IR: release the %50 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %45, i32 %44)    ; IR: uncompute %49
  call void @cqrt_free(i32 %45)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %44, i32 %43, float 0x7FF0000000000000)    ; IR: uncompute %48
  call void @cqrt_free(i32 %44)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %43, i32 %31)    ; IR: uncompute %47
  call void @cqrt_free(i32 %43)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %42, i32 %41, i32 %32)    ; IR: uncompute %46
  call void @cqrt_free(i32 %42)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %41, i32 %37)    ; IR: uncompute %45
  call void @cqrt_free(i32 %41)    ; IR: release the %45 rail (|0>)
  call void @cqrt_or_i1(i32 %39, i32 %37, i32 %40)    ; IR: uncompute %43  [self-inverse]
  call void @cqrt_free(i32 %40)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %39, i32 %38, float 0x7FF0000000000000)    ; IR: uncompute %42
  call void @cqrt_free(i32 %39)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %38, i32 %31)    ; IR: uncompute %41
  call void @cqrt_free(i32 %38)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %37, i32 %36, float 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %37)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %36, i32 %32)    ; IR: uncompute %39
  call void @cqrt_free(i32 %36)    ; IR: release the %39 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %35, i32 %18, i32 1, i32 0)    ; IR: uncompute %38
  call void @cqrt_free(i32 %35)    ; IR: release the %38 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %34, i32 %18, i32 %20, i32 %0)    ; IR: uncompute %37
  call void @cqrt_free(i32 %34)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %33, i32 %18, i32 %24, i32 %1)    ; IR: uncompute %36
  call void @cqrt_free(i32 %33)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f32_ll_unc(i32 %32, i32 %18, float %27, float %2)    ; IR: uncompute %35
  call void @cqrt_free(i32 %32)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f32_ll_unc(i32 %31, i32 %18, float %30, float %3)    ; IR: uncompute %34
  call void @cqrt_free(i32 %31)    ; IR: release the %34 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %24, i32 %23, i32 %1)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %23, i32 %22)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %22, i32 %21, float 0x7FF0000000000000)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %21, i32 %1)    ; IR: uncompute %23
  call void @cqrt_free(i32 %21)    ; IR: release the %23 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %20, i32 %19, i32 %0)    ; IR: uncompute %22
  call void @cqrt_free(i32 %20)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %19, i32 %15)    ; IR: uncompute %21
  call void @cqrt_free(i32 %19)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %17, i32 %15, i32 %18)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %17, i32 %16, float 0x7FF0000000000000)    ; IR: uncompute %18
  call void @cqrt_free(i32 %17)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %16, i32 %1)    ; IR: uncompute %17
  call void @cqrt_free(i32 %16)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %15, i32 %14, float 0x7FF0000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %15)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %14, i32 %0)    ; IR: uncompute %15
  call void @cqrt_free(i32 %14)    ; IR: release the %15 rail (|0>)
  call void @cqrt_or_i1(i32 %11, i32 %12, i32 %13)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %12, i32 %10, float 0.000000e+00)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %11, i32 %9, float 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %10, i32 %8, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f32_unc(i32 %9, i32 %5, i32 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %8, i32 %1, float %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %7, i32 %0, float %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %6, i32 %1, float %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %5, i32 %0, float %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %102 = insertvalue { i32, i32 } poison, i32 %100, 0    ; IR: ret: field 0 (handle)
  %103 = insertvalue { i32, i32 } %102, i32 %101, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %103    ; IR: ret  (the aggregate carries the two lane handles)
}

define internal fastcc void @__cq_q___mulsc3_1100_unc(i32 %0, i32 %1, i32 %2, i32 %3, float %4, float %5) {
  %7 = call i32 @cq_template_fmul_f32_hl(i32 %2, float %4)    ; IR: %5 = fmul %0, %2  (a*c)
  %8 = call i32 @cq_template_fmul_f32_hl(i32 %3, float %5)    ; IR: %6 = fmul %1, %3  (b*d)
  %9 = call i32 @cq_template_fmul_f32_hl(i32 %2, float %5)    ; IR: %7 = fmul %0, %3  (a*d)
  %10 = call i32 @cq_template_fmul_f32_hl(i32 %3, float %4)    ; IR: %8 = fmul %1, %2  (b*c)
  %11 = call i32 @cq_template_fsub_f32(i32 %7, i32 %8)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %12 = call i32 @cq_template_fadd_f32(i32 %10, i32 %9)    ; IR: %10 = fadd %8, %7  (imaginary part)
  %13 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %11, float 0.000000e+00)    ; IR: %11 = fcmp ord %9, 0  (!isnan)
  %14 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %12, float 0.000000e+00)    ; IR: %12 = fcmp ord %10, 0
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %13, i32 %14, i32 %15)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]
  %16 = call i32 @cq_template_fabs_f32(i32 %2)    ; IR: %15 = fabs(a)  (block %14)
  %17 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %16, float 0x7FF0000000000000)    ; IR: %16 = isinf(a)
  %18 = call i32 @cq_template_fabs_f32(i32 %3)    ; IR: %17 = fabs(b)
  %19 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %18, float 0x7FF0000000000000)    ; IR: %18 = isinf(b)
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %19, i32 %17, i32 %20)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]
  %21 = call i32 @cq_template_uitofp_i1_to_f32(i32 %17)    ; IR: %21 = uitofp i1 %16  (block %20)
  %22 = call i32 @cq_template_copysign_f32(i32 %21, i32 %2)    ; IR: %22 = copysign(%21, a)
  %23 = call i32 @cq_template_fabs_f32(i32 %3)    ; IR: %23 = fabs(b)  (recomputed by -O1 inside block %20)
  %24 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %23, float 0x7FF0000000000000)    ; IR: %24 = isinf(b)
  %25 = call i32 @cq_template_uitofp_i1_to_f32(i32 %24)    ; IR: %25 = uitofp i1 %24
  %26 = call i32 @cq_template_copysign_f32(i32 %25, i32 %3)    ; IR: %26 = copysign(%25, b)
  %27 = fcmp ord float %4, 0.000000e+00    ; IR: %27 = fcmp ord c, 0  (!isnan(c))  (classical)
  %28 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %4)    ; IR: %28 = copysign(0, c)  (classical)
  %29 = select i1 %27, float %4, float %28    ; IR: %29 = select %27, %2, %28  (classical)
  %30 = fcmp ord float %5, 0.000000e+00    ; IR: %30 = fcmp ord d, 0  (!isnan(d))  (classical)
  %31 = tail call float @llvm.copysign.f32(float 0.000000e+00, float %5)    ; IR: %31 = copysign(0, d)  (classical)
  %32 = select i1 %30, float %5, float %31    ; IR: %32 = select %30, %3, %31  (classical)
  %33 = call i32 @cq_template_select_f32_ll(i32 %20, float %32, float %5)    ; IR: %34 = phi [ %32, %20 ], [ %3, %14 ]  (merge of block %20 on %19)
  %34 = call i32 @cq_template_select_f32_ll(i32 %20, float %29, float %4)    ; IR: %35 = phi [ %29, %20 ], [ %2, %14 ]
  %35 = call i32 @cq_template_select_f32(i32 %20, i32 %26, i32 %3)    ; IR: %36 = phi [ %26, %20 ], [ %1, %14 ]
  %36 = call i32 @cq_template_select_f32(i32 %20, i32 %22, i32 %2)    ; IR: %37 = phi [ %22, %20 ], [ %0, %14 ]
  %37 = call i32 @cq_template_select_i32_ll(i32 %20, i32 1, i32 0)    ; IR: %38 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %38 = call i32 @cq_template_fabs_f32(i32 %34)    ; IR: %39 = fabs(%35)  (block %33)
  %39 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %38, float 0x7FF0000000000000)    ; IR: %40 = isinf(%35)
  %40 = call i32 @cq_template_fabs_f32(i32 %33)    ; IR: %41 = fabs(%34)
  %41 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %40, float 0x7FF0000000000000)    ; IR: %42 = isinf(%34)
  %42 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %41, i32 %39, i32 %42)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]
  %43 = call i32 @cq_template_uitofp_i1_to_f32(i32 %39)    ; IR: %45 = uitofp i1 %40  (block %44)
  %44 = call i32 @cq_template_copysign_f32(i32 %43, i32 %34)    ; IR: %46 = copysign(%45, %35)
  %45 = call i32 @cq_template_fabs_f32(i32 %33)    ; IR: %47 = fabs(%34)
  %46 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %45, float 0x7FF0000000000000)    ; IR: %48 = isinf(%34)
  %47 = call i32 @cq_template_uitofp_i1_to_f32(i32 %46)    ; IR: %49 = uitofp i1 %48
  %48 = call i32 @cq_template_copysign_f32(i32 %47, i32 %33)    ; IR: %50 = copysign(%49, %34)
  %49 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %36, float 0.000000e+00)    ; IR: %51 = fcmp ord %37, 0
  %50 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %36)    ; IR: %52 = copysign(0, %37)
  %51 = call i32 @cq_template_select_f32(i32 %49, i32 %36, i32 %50)    ; IR: %53 = select %51, %37, %52
  %52 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %35, float 0.000000e+00)    ; IR: %54 = fcmp ord %36, 0
  %53 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %35)    ; IR: %55 = copysign(0, %36)
  %54 = call i32 @cq_template_select_f32(i32 %52, i32 %35, i32 %53)    ; IR: %56 = select %54, %36, %55
  %55 = call i32 @cq_template_select_f32(i32 %42, i32 %48, i32 %33)    ; IR: %58 = phi [ %50, %44 ], [ %34, %33 ]  (merge of block %44 on %43)
  %56 = call i32 @cq_template_select_f32(i32 %42, i32 %44, i32 %34)    ; IR: %59 = phi [ %46, %44 ], [ %35, %33 ]
  %57 = call i32 @cq_template_select_f32(i32 %42, i32 %54, i32 %35)    ; IR: %60 = phi [ %56, %44 ], [ %36, %33 ]
  %58 = call i32 @cq_template_select_f32(i32 %42, i32 %51, i32 %36)    ; IR: %61 = phi [ %53, %44 ], [ %37, %33 ]
  %59 = call i32 @cq_template_select_i32_lh(i32 %42, i32 1, i32 %37)    ; IR: %62 = phi [ 1, %44 ], [ %38, %33 ]  (__recalc)
  %60 = call i32 @cq_template_icmp_eq_i32_hl(i32 %59, i32 0)    ; IR: %63 = icmp eq %62, 0  [predicate of block %64: !__recalc]
  %61 = call i32 @cq_template_fabs_f32(i32 %7)    ; IR: %65 = fabs(%5)  (block %64)
  %62 = call i32 @cq_template_fcmp_une_f32_hl(i32 %61, float 0x7FF0000000000000)    ; IR: %66 = !isinf(ac)
  %63 = call i32 @cq_template_fabs_f32(i32 %8)    ; IR: %67 = fabs(%6)
  %64 = call i32 @cq_template_fcmp_une_f32_hl(i32 %63, float 0x7FF0000000000000)    ; IR: %68 = !isinf(bd)
  %65 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %69 = and i1 %66, %68  [fresh flag rail]
  call void @cqrt_and_i1(i32 %62, i32 %64, i32 %65)    ; IR: %69 = and i1 %66, %68
  %66 = call i32 @cq_template_fabs_f32(i32 %9)    ; IR: %70 = fabs(%7)
  %67 = call i32 @cq_template_fcmp_une_f32_hl(i32 %66, float 0x7FF0000000000000)    ; IR: %71 = !isinf(ad)
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %72 = and i1 %71, %69  [fresh flag rail]
  call void @cqrt_and_i1(i32 %67, i32 %65, i32 %68)    ; IR: %72 = and i1 %71, %69
  %69 = call i32 @cq_template_fabs_f32(i32 %10)    ; IR: %73 = fabs(%8)
  %70 = call i32 @cq_template_fcmp_une_f32_hl(i32 %69, float 0x7FF0000000000000)    ; IR: %74 = !isinf(bc)
  %71 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %70, i32 %68, i32 %71)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]
  %72 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %58, float 0.000000e+00)    ; IR: %77 = fcmp ord %61, 0  (block %76)
  %73 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %58)    ; IR: %78 = copysign(0, %61)
  %74 = call i32 @cq_template_select_f32(i32 %72, i32 %58, i32 %73)    ; IR: %79 = select %77, %61, %78
  %75 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %57, float 0.000000e+00)    ; IR: %80 = fcmp ord %60, 0
  %76 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %57)    ; IR: %81 = copysign(0, %60)
  %77 = call i32 @cq_template_select_f32(i32 %75, i32 %57, i32 %76)    ; IR: %82 = select %80, %60, %81
  %78 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %56, float 0.000000e+00)    ; IR: %83 = fcmp ord %59, 0
  %79 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %56)    ; IR: %84 = copysign(0, %59)
  %80 = call i32 @cq_template_select_f32(i32 %78, i32 %56, i32 %79)    ; IR: %85 = select %83, %59, %84
  %81 = call i32 @cq_template_fcmp_ord_f32_hl(i32 %55, float 0.000000e+00)    ; IR: %86 = fcmp ord %58, 0
  %82 = call i32 @cq_template_copysign_f32_lh(float 0.000000e+00, i32 %55)    ; IR: %87 = copysign(0, %58)
  %83 = call i32 @cq_template_select_f32(i32 %81, i32 %55, i32 %82)    ; IR: %88 = select %86, %58, %87
  call void @cqrt_not_i1(i32 %71)    ; IR: bracket: P76 reads NOT %75
  %84 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75  [fresh flag rail]
  call void @cqrt_and_i1(i32 %60, i32 %71, i32 %84)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75
  call void @cqrt_not_i1(i32 %71)    ; IR: bracket (close): P76 reads NOT %75
  %85 = call i32 @cq_template_select_f32(i32 %84, i32 %83, i32 %55)    ; IR: %90 = phi [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]  (only the %76 path differs)
  %86 = call i32 @cq_template_select_f32(i32 %84, i32 %80, i32 %56)    ; IR: %91 = phi [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %87 = call i32 @cq_template_select_f32(i32 %84, i32 %77, i32 %57)    ; IR: %92 = phi [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %88 = call i32 @cq_template_select_f32(i32 %84, i32 %74, i32 %58)    ; IR: %93 = phi [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %89 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %60, i32 %71, i32 %89)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]
  %90 = call i32 @cq_template_fneg_f32(i32 %87)    ; IR: %96 = fneg %92  (block %95)
  %91 = call i32 @cq_template_fmul_f32(i32 %85, i32 %90)    ; IR: %97 = fmul %90, %96
  %92 = call i32 @cq_template_fmul_f32(i32 %88, i32 %86)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused product]
  %93 = call i32 @cq_template_fadd_f32(i32 %92, i32 %91)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused sum]
  %94 = call i32 @cq_template_fmul_f32_hl(i32 %93, float 0x7FF0000000000000)    ; IR: %99 = fmul %98, inf
  %95 = call i32 @cq_template_fmul_f32(i32 %86, i32 %87)    ; IR: %100 = fmul %91, %92
  %96 = call i32 @cq_template_fmul_f32(i32 %88, i32 %85)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused product]
  %97 = call i32 @cq_template_fadd_f32(i32 %96, i32 %95)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused sum]
  %98 = call i32 @cq_template_fmul_f32_hl(i32 %97, float 0x7FF0000000000000)    ; IR: %102 = fmul %101, inf
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %89)    ; IR: bracket: P95 reads NOT %94
  %99 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P95 = path predicate of block %95: !%13 & !%94  [fresh flag rail]
  call void @cqrt_and_i1(i32 %15, i32 %89, i32 %99)    ; IR: P95 = path predicate of block %95: !%13 & !%94
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %89)    ; IR: bracket (close): P95 reads NOT %94
  %100 = call i32 @cq_template_select_f32(i32 %99, i32 %94, i32 %11)    ; IR: %105 = phi [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]  (real result)
  %101 = call i32 @cq_template_select_f32(i32 %99, i32 %98, i32 %12)    ; IR: %104 = phi [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]  (imaginary result)
  call void @cqrt_copy_f32(i32 %100, i32 %0)    ; IR: xor lane 0 (real) out of the result rail (returns it to |0>)
  call void @cqrt_copy_f32(i32 %101, i32 %1)    ; IR: xor lane 1 (imaginary) out of the result rail (returns it to |0>)
  call void @cq_template_select_f32_unc(i32 %101, i32 %99, i32 %98, i32 %12)    ; IR: uncompute %104
  call void @cqrt_free(i32 %101)    ; IR: release the %104 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %100, i32 %99, i32 %94, i32 %11)    ; IR: uncompute %105
  call void @cqrt_free(i32 %100)    ; IR: release the %105 rail (|0>)
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %89)    ; IR: bracket: P95 reads NOT %94
  call void @cqrt_and_i1(i32 %15, i32 %89, i32 %99)    ; IR: uncompute P95  [self-inverse]
  call void @cqrt_free(i32 %99)    ; IR: release the P95 rail (|0>)
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %89)    ; IR: bracket (close): P95 reads NOT %94
  call void @cq_template_fmul_f32_hl_unc(i32 %98, i32 %97, float 0x7FF0000000000000)    ; IR: uncompute %102
  call void @cqrt_free(i32 %98)    ; IR: release the %102 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %97, i32 %96, i32 %95)    ; IR: uncompute %101  [sum]
  call void @cqrt_free(i32 %97)    ; IR: release the %101 rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %96, i32 %88, i32 %85)    ; IR: uncompute %101  [product]
  call void @cqrt_free(i32 %96)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %95, i32 %86, i32 %87)    ; IR: uncompute %100
  call void @cqrt_free(i32 %95)    ; IR: release the %100 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %94, i32 %93, float 0x7FF0000000000000)    ; IR: uncompute %99
  call void @cqrt_free(i32 %94)    ; IR: release the %99 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %93, i32 %92, i32 %91)    ; IR: uncompute %98  [sum]
  call void @cqrt_free(i32 %93)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %92, i32 %88, i32 %86)    ; IR: uncompute %98  [product]
  call void @cqrt_free(i32 %92)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f32_unc(i32 %91, i32 %85, i32 %90)    ; IR: uncompute %97
  call void @cqrt_free(i32 %91)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fneg_f32_unc(i32 %90, i32 %87)    ; IR: uncompute %96
  call void @cqrt_free(i32 %90)    ; IR: release the %96 rail (|0>)
  call void @cqrt_and_i1(i32 %60, i32 %71, i32 %89)    ; IR: uncompute %94  [self-inverse]
  call void @cqrt_free(i32 %89)    ; IR: release the %94 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %88, i32 %84, i32 %74, i32 %58)    ; IR: uncompute %93
  call void @cqrt_free(i32 %88)    ; IR: release the %93 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %87, i32 %84, i32 %77, i32 %57)    ; IR: uncompute %92
  call void @cqrt_free(i32 %87)    ; IR: release the %92 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %86, i32 %84, i32 %80, i32 %56)    ; IR: uncompute %91
  call void @cqrt_free(i32 %86)    ; IR: release the %91 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %85, i32 %84, i32 %83, i32 %55)    ; IR: uncompute %90
  call void @cqrt_free(i32 %85)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %71)    ; IR: bracket: P76 reads NOT %75
  call void @cqrt_and_i1(i32 %60, i32 %71, i32 %84)    ; IR: uncompute P76  [self-inverse]
  call void @cqrt_free(i32 %84)    ; IR: release the P76 rail (|0>)
  call void @cqrt_not_i1(i32 %71)    ; IR: bracket (close): P76 reads NOT %75
  call void @cq_template_select_f32_unc(i32 %83, i32 %81, i32 %55, i32 %82)    ; IR: uncompute %88
  call void @cqrt_free(i32 %83)    ; IR: release the %88 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %82, float 0.000000e+00, i32 %55)    ; IR: uncompute %87
  call void @cqrt_free(i32 %82)    ; IR: release the %87 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %81, i32 %55, float 0.000000e+00)    ; IR: uncompute %86
  call void @cqrt_free(i32 %81)    ; IR: release the %86 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %80, i32 %78, i32 %56, i32 %79)    ; IR: uncompute %85
  call void @cqrt_free(i32 %80)    ; IR: release the %85 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %79, float 0.000000e+00, i32 %56)    ; IR: uncompute %84
  call void @cqrt_free(i32 %79)    ; IR: release the %84 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %78, i32 %56, float 0.000000e+00)    ; IR: uncompute %83
  call void @cqrt_free(i32 %78)    ; IR: release the %83 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %77, i32 %75, i32 %57, i32 %76)    ; IR: uncompute %82
  call void @cqrt_free(i32 %77)    ; IR: release the %82 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %76, float 0.000000e+00, i32 %57)    ; IR: uncompute %81
  call void @cqrt_free(i32 %76)    ; IR: release the %81 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %75, i32 %57, float 0.000000e+00)    ; IR: uncompute %80
  call void @cqrt_free(i32 %75)    ; IR: release the %80 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %74, i32 %72, i32 %58, i32 %73)    ; IR: uncompute %79
  call void @cqrt_free(i32 %74)    ; IR: release the %79 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %73, float 0.000000e+00, i32 %58)    ; IR: uncompute %78
  call void @cqrt_free(i32 %73)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %72, i32 %58, float 0.000000e+00)    ; IR: uncompute %77
  call void @cqrt_free(i32 %72)    ; IR: release the %77 rail (|0>)
  call void @cqrt_and_i1(i32 %70, i32 %68, i32 %71)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %71)    ; IR: release the %75 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %70, i32 %69, float 0x7FF0000000000000)    ; IR: uncompute %74
  call void @cqrt_free(i32 %70)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %69, i32 %10)    ; IR: uncompute %73
  call void @cqrt_free(i32 %69)    ; IR: release the %73 rail (|0>)
  call void @cqrt_and_i1(i32 %67, i32 %65, i32 %68)    ; IR: uncompute %72  [self-inverse]
  call void @cqrt_free(i32 %68)    ; IR: release the %72 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %67, i32 %66, float 0x7FF0000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %67)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %66, i32 %9)    ; IR: uncompute %70
  call void @cqrt_free(i32 %66)    ; IR: release the %70 rail (|0>)
  call void @cqrt_and_i1(i32 %62, i32 %64, i32 %65)    ; IR: uncompute %69  [self-inverse]
  call void @cqrt_free(i32 %65)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %64, i32 %63, float 0x7FF0000000000000)    ; IR: uncompute %68
  call void @cqrt_free(i32 %64)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %63, i32 %8)    ; IR: uncompute %67
  call void @cqrt_free(i32 %63)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fcmp_une_f32_hl_unc(i32 %62, i32 %61, float 0x7FF0000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %62)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %61, i32 %7)    ; IR: uncompute %65
  call void @cqrt_free(i32 %61)    ; IR: release the %65 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %60, i32 %59, i32 0)    ; IR: uncompute %63
  call void @cqrt_free(i32 %60)    ; IR: release the %63 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %59, i32 %42, i32 1, i32 %37)    ; IR: uncompute %62
  call void @cqrt_free(i32 %59)    ; IR: release the %62 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %58, i32 %42, i32 %51, i32 %36)    ; IR: uncompute %61
  call void @cqrt_free(i32 %58)    ; IR: release the %61 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %57, i32 %42, i32 %54, i32 %35)    ; IR: uncompute %60
  call void @cqrt_free(i32 %57)    ; IR: release the %60 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %56, i32 %42, i32 %44, i32 %34)    ; IR: uncompute %59
  call void @cqrt_free(i32 %56)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %55, i32 %42, i32 %48, i32 %33)    ; IR: uncompute %58
  call void @cqrt_free(i32 %55)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %54, i32 %52, i32 %35, i32 %53)    ; IR: uncompute %56
  call void @cqrt_free(i32 %54)    ; IR: release the %56 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %53, float 0.000000e+00, i32 %35)    ; IR: uncompute %55
  call void @cqrt_free(i32 %53)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %52, i32 %35, float 0.000000e+00)    ; IR: uncompute %54
  call void @cqrt_free(i32 %52)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %51, i32 %49, i32 %36, i32 %50)    ; IR: uncompute %53
  call void @cqrt_free(i32 %51)    ; IR: release the %53 rail (|0>)
  call void @cq_template_copysign_f32_lh_unc(i32 %50, float 0.000000e+00, i32 %36)    ; IR: uncompute %52
  call void @cqrt_free(i32 %50)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %49, i32 %36, float 0.000000e+00)    ; IR: uncompute %51
  call void @cqrt_free(i32 %49)    ; IR: release the %51 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %48, i32 %47, i32 %33)    ; IR: uncompute %50
  call void @cqrt_free(i32 %48)    ; IR: release the %50 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %47, i32 %46)    ; IR: uncompute %49
  call void @cqrt_free(i32 %47)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %46, i32 %45, float 0x7FF0000000000000)    ; IR: uncompute %48
  call void @cqrt_free(i32 %46)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %45, i32 %33)    ; IR: uncompute %47
  call void @cqrt_free(i32 %45)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %44, i32 %43, i32 %34)    ; IR: uncompute %46
  call void @cqrt_free(i32 %44)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %43, i32 %39)    ; IR: uncompute %45
  call void @cqrt_free(i32 %43)    ; IR: release the %45 rail (|0>)
  call void @cqrt_or_i1(i32 %41, i32 %39, i32 %42)    ; IR: uncompute %43  [self-inverse]
  call void @cqrt_free(i32 %42)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %41, i32 %40, float 0x7FF0000000000000)    ; IR: uncompute %42
  call void @cqrt_free(i32 %41)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %40, i32 %33)    ; IR: uncompute %41
  call void @cqrt_free(i32 %40)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %39, i32 %38, float 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %39)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %38, i32 %34)    ; IR: uncompute %39
  call void @cqrt_free(i32 %38)    ; IR: release the %39 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %37, i32 %20, i32 1, i32 0)    ; IR: uncompute %38
  call void @cqrt_free(i32 %37)    ; IR: release the %38 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %36, i32 %20, i32 %22, i32 %2)    ; IR: uncompute %37
  call void @cqrt_free(i32 %36)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_f32_unc(i32 %35, i32 %20, i32 %26, i32 %3)    ; IR: uncompute %36
  call void @cqrt_free(i32 %35)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f32_ll_unc(i32 %34, i32 %20, float %29, float %4)    ; IR: uncompute %35
  call void @cqrt_free(i32 %34)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f32_ll_unc(i32 %33, i32 %20, float %32, float %5)    ; IR: uncompute %34
  call void @cqrt_free(i32 %33)    ; IR: release the %34 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %26, i32 %25, i32 %3)    ; IR: uncompute %26
  call void @cqrt_free(i32 %26)    ; IR: release the %26 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %25, i32 %24)    ; IR: uncompute %25
  call void @cqrt_free(i32 %25)    ; IR: release the %25 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %24, i32 %23, float 0x7FF0000000000000)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %23, i32 %3)    ; IR: uncompute %23
  call void @cqrt_free(i32 %23)    ; IR: release the %23 rail (|0>)
  call void @cq_template_copysign_f32_unc(i32 %22, i32 %21, i32 %2)    ; IR: uncompute %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f32_unc(i32 %21, i32 %17)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %19, i32 %17, i32 %20)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %20)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %19, i32 %18, float 0x7FF0000000000000)    ; IR: uncompute %18
  call void @cqrt_free(i32 %19)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %18, i32 %3)    ; IR: uncompute %17
  call void @cqrt_free(i32 %18)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %17, i32 %16, float 0x7FF0000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %17)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %16, i32 %2)    ; IR: uncompute %15
  call void @cqrt_free(i32 %16)    ; IR: release the %15 rail (|0>)
  call void @cqrt_or_i1(i32 %13, i32 %14, i32 %15)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %14, i32 %12, float 0.000000e+00)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_ord_f32_hl_unc(i32 %13, i32 %11, float 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f32_unc(i32 %12, i32 %10, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f32_unc(i32 %11, i32 %7, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %10, i32 %3, float %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %9, i32 %2, float %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %8, i32 %3, float %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %7, i32 %2, float %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

declare void @cqrt_free(i32)
declare i32 @cqrt_alloc_f32(float)
declare void @cqrt_ry_f32(i32, double)
declare i32 @cq_template_fmul_f32_hl(i32, float)
declare void @cq_template_fmul_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fadd_f32_hl(i32, float)
declare void @cq_template_fadd_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fsub_f32(i32, i32)
declare void @cq_template_fsub_f32_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f32(i32, i32)
declare void @cq_template_fadd_f32_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_uno_f32_hl(i32, float)
declare void @cq_template_fcmp_uno_f32_hl_unc(i32, i32, float)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_select_f32(i32, i32, i32)
declare void @cq_template_select_f32_unc(i32, i32, i32, i32)
declare float @cqrt_measure_f32(i32)
declare i32 @cq_template_fcmp_ord_f32_hl(i32, float)
declare void @cq_template_fcmp_ord_f32_hl_unc(i32, i32, float)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_fabs_f32(i32)
declare void @cq_template_fabs_f32_unc(i32, i32)
declare i32 @cq_template_fcmp_oeq_f32_hl(i32, float)
declare void @cq_template_fcmp_oeq_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_uitofp_i1_to_f32(i32)
declare void @cq_template_uitofp_i1_to_f32_unc(i32, i32)
declare i32 @cq_template_copysign_f32(i32, i32)
declare void @cq_template_copysign_f32_unc(i32, i32, i32)
declare i32 @cq_template_select_f32_ll(i32, float, float)
declare void @cq_template_select_f32_ll_unc(i32, i32, float, float)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_copysign_f32_lh(float, i32)
declare void @cq_template_copysign_f32_lh_unc(i32, float, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_une_f32_hl(i32, float)
declare void @cq_template_fcmp_une_f32_hl_unc(i32, i32, float)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_fneg_f32(i32)
declare void @cq_template_fneg_f32_unc(i32, i32)
declare i32 @cq_template_fmul_f32(i32, i32)
declare void @cq_template_fmul_f32_unc(i32, i32, i32)
declare void @cqrt_copy_f32(i32, i32)
declare float @llvm.copysign.f32(float, float)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
