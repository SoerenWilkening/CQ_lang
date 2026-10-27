; HAND-WRITTEN. Rules: 26, 25, 18, 1, 3, 8, 9, 4, 5, 7, 20.
; Checked: creall(q) + cimagl(q) (measured, %28 -> %29).
; Clean: every flag, path-predicate, seed and arithmetic rail of the entry and of the clones __cq_q___mulxc3_1000,
; __cq_q___divxc3_1100 and __cq_q_scalbnl_10 (each clone's result rails are zeroed by its _unc twin and freed by the
; caller), all freed before the measurement.
; Kept: re (%6, the rotated register) and the measured result rail %28; nothing else.
; Rotations: (Ry, re, th, 1); the clones hold none.
; long double _Complex: the parts are x86_fp80 scalars here (the entry takes and the helpers take scalar parts, so no byval
; slot pair as in 70) and __mulxc3 / __divxc3 return the aggregate { x86_fp80, x86_fp80 }, lowered as { i32, i32 }. Every
; f80 op is a template of width f80 with x86_fp80 literals (rule 25). The bodies are the compiler-rt ones reproduced in the
; .c: __mulxc3 lifted with mask 1000 (its -O1 shape is 173's: fcmp ord + or into an early exit, `fcmp une` + and in %64),
; __divxc3 with mask 1100 (here -O1 orders the %16 phis ilogbw, d, c). logbl and the scalbnl of c, d have classical
; arguments and stay plain calls; the scalbnl of the quotient is the clone __cq_q_scalbnl_10 of the injected musl scalbnl
; body (clang -O1): its `union ldshape` write of the exponent field is a bit view of the x87 pattern (rule 20, as 63):
; trunc / add i16 / zext to i80 / shl 64 / or with the explicit integer bit / bitcast to x86_fp80, all classical (n is
; classical). Its conditions test only n, so they are classical branches inside the clone (rule 8): the scaling blocks
; compute _hl fmul templates, %22 merges the handles by a classical phi, and after the copy-out a mirror re-branches on
; the same conditions to uncompute the scalings that ran (as 173's scalbnf). Flags, path predicates and the five-incoming merges are
; as in 173 (P58, P79, P41, complement innermost). Every llvm.fmuladd of the clones is UNFUSED (§2, cf. 14, 69): an fmul
; into a fresh product rail, then an fadd into a fresh rail, the product uncomputed by its fmul _unc right after the sum
; (the twins recompute and uncompute both) and freed (rule 5). Everything but the result rail is uncomputed LIFO before the measurement.
source_filename = "complex_ldouble_muldiv.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define x86_fp80 @complex_ldouble_muldiv(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2, x86_fp80 noundef %3, x86_fp80 noundef %4) {
  %6 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %6 = cq_theta_f80(%0, %1)  [register re]
  call void @cqrt_ry_f80(i32 %6, double %1)    ; IR: %6 = cq_theta_f80(%0, %1)  [Ry]
  %7 = fmul x86_fp80 %2, 0xK00000000000000000000    ; IR: %7 = fmul %2, 0  (im * I: real part im*0)  (classical)
  %8 = call i32 @cq_template_fadd_f80_hl(i32 %6, x86_fp80 %7)    ; IR: %8 = fadd %7, %6  (real part of z)  (commutative, quantum operand first)
  %9 = fmul x86_fp80 %4, 0xK00000000000000000000    ; IR: %9 = fmul %4, 0  (classical)
  %10 = fadd x86_fp80 %9, %3    ; IR: %10 = fadd %9, %3  (real part of w)  (classical)
  %11 = call i32 @cq_template_fmul_f80_hl(i32 %8, x86_fp80 %10)    ; IR: %11 = fmul %10, %8  (commutative, quantum operand first)
  %12 = fmul x86_fp80 %2, %4    ; IR: %12 = fmul %2, %4  (classical)
  %13 = call i32 @cq_template_fmul_f80_hl(i32 %8, x86_fp80 %4)    ; IR: %13 = fmul %8, %4
  %14 = fmul x86_fp80 %10, %2    ; IR: %14 = fmul %10, %2  (classical)
  %15 = call i32 @cq_template_fsub_f80_hl(i32 %11, x86_fp80 %12)    ; IR: %15 = fsub %11, %12  (fast-path real part of p)
  %16 = call i32 @cq_template_fadd_f80_hl(i32 %13, x86_fp80 %14)    ; IR: %16 = fadd %14, %13  (fast-path imaginary part of p)  (commutative, quantum operand first)
  %17 = call i32 @cq_template_fcmp_uno_f80_hl(i32 %15, x86_fp80 0xK00000000000000000000)    ; IR: %17 = fcmp uno %15, 0  [predicate of block %18]
  %18 = call i32 @cq_template_fcmp_uno_f80_hl(i32 %16, x86_fp80 0xK00000000000000000000)    ; IR: %19 = fcmp uno %16, 0
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P20 = path predicate of block %20 = %17 & %19  [fresh flag rail]
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: P20 = path predicate of block %20 = %17 & %19
  %20 = call fastcc { i32, i32 } @__cq_q___mulxc3_1000(i32 %8, x86_fp80 %2, x86_fp80 %10, x86_fp80 %4)    ; IR: %21 = call @__mulxc3(%8, %2, %10, %4), quantum clone (arg 0 quantum), called unconditionally; returns { x86_fp80, x86_fp80 } as a pair of handles
  %21 = extractvalue { i32, i32 } %20, 0    ; IR: extractvalue %21, 0  (handle; classical)
  %22 = extractvalue { i32, i32 } %20, 1    ; IR: extractvalue %21, 1  (handle; classical)
  %23 = call i32 @cq_template_select_f80(i32 %19, i32 %21, i32 %15)    ; IR: %25 = phi [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]  (real part of p)
  %24 = call i32 @cq_template_select_f80(i32 %19, i32 %22, i32 %16)    ; IR: %26 = phi [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]  (imaginary part of p)
  %25 = call fastcc { i32, i32 } @__cq_q___divxc3_1100(i32 %23, i32 %24, x86_fp80 %10, x86_fp80 %4)    ; IR: %27 = call @__divxc3(%25, %26, %10, %4), quantum clone (args 0 and 1 quantum); returns { x86_fp80, x86_fp80 } as a pair of handles
  %26 = extractvalue { i32, i32 } %25, 0    ; IR: extractvalue %27, 0  (handle; classical)
  %27 = extractvalue { i32, i32 } %25, 1    ; IR: extractvalue %27, 1  (handle; classical)
  %28 = call i32 @cq_template_fadd_f80(i32 %26, i32 %27)    ; IR: %30 = fadd %28, %29  (creall(q) + cimagl(q))  [result rail]
  call fastcc void @__cq_q___divxc3_1100_unc(i32 %26, i32 %27, i32 %23, i32 %24, x86_fp80 %10, x86_fp80 %4)    ; IR: uncompute the result rail(s) of %27
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_select_f80_unc(i32 %24, i32 %19, i32 %22, i32 %16)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %23, i32 %19, i32 %21, i32 %15)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call fastcc void @__cq_q___mulxc3_1000_unc(i32 %21, i32 %22, i32 %8, x86_fp80 %2, x86_fp80 %10, x86_fp80 %4)    ; IR: uncompute the result rail(s) of %21
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: uncompute P20  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the P20 rail (|0>)
  call void @cq_template_fcmp_uno_f80_hl_unc(i32 %18, i32 %16, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_uno_f80_hl_unc(i32 %17, i32 %15, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fadd_f80_hl_unc(i32 %16, i32 %13, x86_fp80 %14)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fsub_f80_hl_unc(i32 %15, i32 %11, x86_fp80 %12)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %13, i32 %8, x86_fp80 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %11, i32 %8, x86_fp80 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f80_hl_unc(i32 %8, i32 %6, x86_fp80 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %29 = call x86_fp80 @cqrt_measure_f80(i32 %28)    ; IR: %31 = cq_measure_f80(%30)
  ret x86_fp80 %29    ; IR: ret x86_fp80 %31
}

define internal fastcc { i32, i32 } @__cq_q___mulxc3_1000(i32 %0, x86_fp80 %1, x86_fp80 %2, x86_fp80 %3) {
  %5 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %2)    ; IR: %5 = fmul %0, %2  (a*c)
  %6 = fmul x86_fp80 %1, %3    ; IR: %6 = fmul %1, %3  (b*d)  (classical)
  %7 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %3)    ; IR: %7 = fmul %0, %3  (a*d)
  %8 = fmul x86_fp80 %1, %2    ; IR: %8 = fmul %1, %2  (b*c)  (classical)
  %9 = call i32 @cq_template_fsub_f80_hl(i32 %5, x86_fp80 %6)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %10 = call i32 @cq_template_fadd_f80_hl(i32 %7, x86_fp80 %8)    ; IR: %10 = fadd %8, %7  (imaginary part)  (commutative, quantum operand first)
  %11 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %9, x86_fp80 0xK00000000000000000000)    ; IR: %11 = fcmp ord %9, 0  (!isnan)
  %12 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %10, x86_fp80 0xK00000000000000000000)    ; IR: %12 = fcmp ord %10, 0
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %11, i32 %12, i32 %13)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]
  %14 = call i32 @cq_template_fabs_f80(i32 %0)    ; IR: %15 = fabs(a)  (block %14)
  %15 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %14, x86_fp80 0xK7FFF8000000000000000)    ; IR: %16 = isinf(a)
  %16 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)    ; IR: %17 = fabs(b)  (classical)
  %17 = fcmp oeq x86_fp80 %16, 0xK7FFF8000000000000000    ; IR: %18 = isinf(b)  (classical)
  %18 = call i32 @cqrt_alloc_i1(i1 %17)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [the classical conjunct %17 as a seed rail, rule 7]
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %18, i32 %15, i32 %19)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]
  %20 = call i32 @cq_template_uitofp_i1_to_f80(i32 %15)    ; IR: %21 = uitofp i1 %16  (block %20)
  %21 = call i32 @cq_template_copysign_f80(i32 %20, i32 %0)    ; IR: %22 = copysign(%21, a)
  %22 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %1)    ; IR: %23 = fabs(b)  (classical)
  %23 = fcmp oeq x86_fp80 %22, 0xK7FFF8000000000000000    ; IR: %24 = isinf(b)  (classical)
  %24 = uitofp i1 %23 to x86_fp80    ; IR: %25 = uitofp i1 %24  (classical)
  %25 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %24, x86_fp80 %1)    ; IR: %26 = copysign(%25, b)  (classical)
  %26 = fcmp ord x86_fp80 %2, 0xK00000000000000000000    ; IR: %27 = fcmp ord c, 0  (!isnan(c))  (classical)
  %27 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %2)    ; IR: %28 = copysign(0, c)  (classical)
  %28 = select i1 %26, x86_fp80 %2, x86_fp80 %27    ; IR: %29 = select %27, %2, %28  (classical)
  %29 = fcmp ord x86_fp80 %3, 0xK00000000000000000000    ; IR: %30 = fcmp ord d, 0  (classical)
  %30 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %3)    ; IR: %31 = copysign(0, d)  (classical)
  %31 = select i1 %29, x86_fp80 %3, x86_fp80 %30    ; IR: %32 = select %30, %3, %31  (classical)
  %32 = call i32 @cq_template_select_f80_ll(i32 %19, x86_fp80 %31, x86_fp80 %3)    ; IR: %34 = phi [ %32, %20 ], [ %3, %14 ]  (merge of block %20 on %19)
  %33 = call i32 @cq_template_select_f80_ll(i32 %19, x86_fp80 %28, x86_fp80 %2)    ; IR: %35 = phi [ %29, %20 ], [ %2, %14 ]
  %34 = call i32 @cq_template_select_f80_ll(i32 %19, x86_fp80 %25, x86_fp80 %1)    ; IR: %36 = phi [ %26, %20 ], [ %1, %14 ]
  %35 = call i32 @cq_template_select_f80(i32 %19, i32 %21, i32 %0)    ; IR: %37 = phi [ %22, %20 ], [ %0, %14 ]
  %36 = call i32 @cq_template_select_i32_ll(i32 %19, i32 1, i32 0)    ; IR: %38 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %37 = call i32 @cq_template_fabs_f80(i32 %33)    ; IR: %39 = fabs(%35)  (block %33)
  %38 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %37, x86_fp80 0xK7FFF8000000000000000)    ; IR: %40 = isinf(%35)
  %39 = call i32 @cq_template_fabs_f80(i32 %32)    ; IR: %41 = fabs(%34)
  %40 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %39, x86_fp80 0xK7FFF8000000000000000)    ; IR: %42 = isinf(%34)
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %40, i32 %38, i32 %41)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]
  %42 = call i32 @cq_template_uitofp_i1_to_f80(i32 %38)    ; IR: %45 = uitofp i1 %40  (block %44)
  %43 = call i32 @cq_template_copysign_f80(i32 %42, i32 %33)    ; IR: %46 = copysign(%45, %35)
  %44 = call i32 @cq_template_fabs_f80(i32 %32)    ; IR: %47 = fabs(%34)
  %45 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: %48 = isinf(%34)
  %46 = call i32 @cq_template_uitofp_i1_to_f80(i32 %45)    ; IR: %49 = uitofp i1 %48
  %47 = call i32 @cq_template_copysign_f80(i32 %46, i32 %32)    ; IR: %50 = copysign(%49, %34)
  %48 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %35, x86_fp80 0xK00000000000000000000)    ; IR: %51 = fcmp ord %37, 0
  %49 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %35)    ; IR: %52 = copysign(0, %37)
  %50 = call i32 @cq_template_select_f80(i32 %48, i32 %35, i32 %49)    ; IR: %53 = select %51, %37, %52
  %51 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %34, x86_fp80 0xK00000000000000000000)    ; IR: %54 = fcmp ord %36, 0
  %52 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %34)    ; IR: %55 = copysign(0, %36)
  %53 = call i32 @cq_template_select_f80(i32 %51, i32 %34, i32 %52)    ; IR: %56 = select %54, %36, %55
  %54 = call i32 @cq_template_select_f80(i32 %41, i32 %47, i32 %32)    ; IR: %58 = phi [ %50, %44 ], [ %34, %33 ]  (merge of block %44 on %43)
  %55 = call i32 @cq_template_select_f80(i32 %41, i32 %43, i32 %33)    ; IR: %59 = phi [ %46, %44 ], [ %35, %33 ]
  %56 = call i32 @cq_template_select_f80(i32 %41, i32 %53, i32 %34)    ; IR: %60 = phi [ %56, %44 ], [ %36, %33 ]
  %57 = call i32 @cq_template_select_f80(i32 %41, i32 %50, i32 %35)    ; IR: %61 = phi [ %53, %44 ], [ %37, %33 ]
  %58 = call i32 @cq_template_select_i32_lh(i32 %41, i32 1, i32 %36)    ; IR: %62 = phi [ 1, %44 ], [ %38, %33 ]  (__recalc)
  %59 = call i32 @cq_template_icmp_eq_i32_hl(i32 %58, i32 0)    ; IR: %63 = icmp eq %62, 0  [predicate of block %64: !__recalc]
  %60 = call i32 @cq_template_fabs_f80(i32 %5)    ; IR: %65 = fabs(%5)  (block %64)
  %61 = call i32 @cq_template_fcmp_une_f80_hl(i32 %60, x86_fp80 0xK7FFF8000000000000000)    ; IR: %66 = !isinf(ac)
  %62 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %6)    ; IR: %67 = fabs(%6)  (classical)
  %63 = fcmp une x86_fp80 %62, 0xK7FFF8000000000000000    ; IR: %68 = !isinf(bd)  (classical)
  %64 = call i32 @cqrt_alloc_i1(i1 %63)    ; IR: %69 = and i1 %66, %68  [the classical conjunct %63 as a seed rail, rule 7]
  %65 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %69 = and i1 %66, %68  [fresh flag rail]
  call void @cqrt_and_i1(i32 %61, i32 %64, i32 %65)    ; IR: %69 = and i1 %66, %68
  %66 = call i32 @cq_template_fabs_f80(i32 %7)    ; IR: %70 = fabs(%7)
  %67 = call i32 @cq_template_fcmp_une_f80_hl(i32 %66, x86_fp80 0xK7FFF8000000000000000)    ; IR: %71 = !isinf(ad)
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %72 = and i1 %71, %69  [fresh flag rail]
  call void @cqrt_and_i1(i32 %67, i32 %65, i32 %68)    ; IR: %72 = and i1 %71, %69
  %69 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %8)    ; IR: %73 = fabs(%8)  (classical)
  %70 = fcmp une x86_fp80 %69, 0xK7FFF8000000000000000    ; IR: %74 = !isinf(bc)  (classical)
  %71 = call i32 @cqrt_alloc_i1(i1 %70)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [the classical conjunct %70 as a seed rail, rule 7]
  %72 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %71, i32 %68, i32 %72)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]
  %73 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %57, x86_fp80 0xK00000000000000000000)    ; IR: %77 = fcmp ord %61, 0  (block %76)
  %74 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %57)    ; IR: %78 = copysign(0, %61)
  %75 = call i32 @cq_template_select_f80(i32 %73, i32 %57, i32 %74)    ; IR: %79 = select %77, %61, %78
  %76 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %56, x86_fp80 0xK00000000000000000000)    ; IR: %80 = fcmp ord %60, 0
  %77 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %56)    ; IR: %81 = copysign(0, %60)
  %78 = call i32 @cq_template_select_f80(i32 %76, i32 %56, i32 %77)    ; IR: %82 = select %80, %60, %81
  %79 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %55, x86_fp80 0xK00000000000000000000)    ; IR: %83 = fcmp ord %59, 0
  %80 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %55)    ; IR: %84 = copysign(0, %59)
  %81 = call i32 @cq_template_select_f80(i32 %79, i32 %55, i32 %80)    ; IR: %85 = select %83, %59, %84
  %82 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %54, x86_fp80 0xK00000000000000000000)    ; IR: %86 = fcmp ord %58, 0
  %83 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %54)    ; IR: %87 = copysign(0, %58)
  %84 = call i32 @cq_template_select_f80(i32 %82, i32 %54, i32 %83)    ; IR: %88 = select %86, %58, %87
  call void @cqrt_not_i1(i32 %72)    ; IR: bracket: P76 reads NOT %72
  %85 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75  [fresh flag rail]
  call void @cqrt_and_i1(i32 %59, i32 %72, i32 %85)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75
  call void @cqrt_not_i1(i32 %72)    ; IR: bracket (close): P76 reads NOT %72
  %86 = call i32 @cq_template_select_f80(i32 %85, i32 %84, i32 %54)    ; IR: %90 = phi [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]  (only the %76 path differs)
  %87 = call i32 @cq_template_select_f80(i32 %85, i32 %81, i32 %55)    ; IR: %91 = phi [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %88 = call i32 @cq_template_select_f80(i32 %85, i32 %78, i32 %56)    ; IR: %92 = phi [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %89 = call i32 @cq_template_select_f80(i32 %85, i32 %75, i32 %57)    ; IR: %93 = phi [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %90 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %59, i32 %72, i32 %90)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]
  %91 = call i32 @cq_template_fneg_f80(i32 %88)    ; IR: %96 = fneg %92  (block %95)
  %92 = call i32 @cq_template_fmul_f80(i32 %86, i32 %91)    ; IR: %97 = fmul %90, %96
  %93 = call i32 @cq_template_fmul_f80(i32 %89, i32 %87)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused product]
  %94 = call i32 @cq_template_fadd_f80(i32 %93, i32 %92)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused sum]
  %95 = call i32 @cq_template_fmul_f80_hl(i32 %94, x86_fp80 0xK7FFF8000000000000000)    ; IR: %99 = fmul %98, inf
  %96 = call i32 @cq_template_fmul_f80(i32 %87, i32 %88)    ; IR: %100 = fmul %91, %92
  %97 = call i32 @cq_template_fmul_f80(i32 %89, i32 %86)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused product]
  %98 = call i32 @cq_template_fadd_f80(i32 %97, i32 %96)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused sum]
  %99 = call i32 @cq_template_fmul_f80_hl(i32 %98, x86_fp80 0xK7FFF8000000000000000)    ; IR: %102 = fmul %101, inf
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %90)    ; IR: bracket: P95 reads NOT %90
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P95 = path predicate of block %95: !%13 & !%94  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %90, i32 %100)    ; IR: P95 = path predicate of block %95: !%13 & !%94
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %90)    ; IR: bracket (close): P95 reads NOT %90
  %101 = call i32 @cq_template_select_f80(i32 %100, i32 %95, i32 %9)    ; IR: %105 = phi [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]  (real result)
  %102 = call i32 @cq_template_select_f80(i32 %100, i32 %99, i32 %10)    ; IR: %104 = phi [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]  (imaginary result)
  %103 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f80(i32 %101, i32 %103)    ; IR: copy real out
  %104 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f80(i32 %102, i32 %104)    ; IR: copy imaginary out
  call void @cq_template_select_f80_unc(i32 %102, i32 %100, i32 %99, i32 %10)    ; IR: uncompute %104
  call void @cqrt_free(i32 %102)    ; IR: release the %104 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %101, i32 %100, i32 %95, i32 %9)    ; IR: uncompute %105
  call void @cqrt_free(i32 %101)    ; IR: release the %105 rail (|0>)
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: P95 reads NOT %13
  call void @cqrt_not_i1(i32 %90)    ; IR: bracket: P95 reads NOT %90
  call void @cqrt_and_i1(i32 %13, i32 %90, i32 %100)    ; IR: uncompute P95  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P95 rail (|0>)
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket (close): P95 reads NOT %13
  call void @cqrt_not_i1(i32 %90)    ; IR: bracket (close): P95 reads NOT %90
  call void @cq_template_fmul_f80_hl_unc(i32 %99, i32 %98, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %102
  call void @cqrt_free(i32 %99)    ; IR: release the %102 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %98, i32 %97, i32 %96)    ; IR: uncompute %101  [sum]
  call void @cqrt_free(i32 %98)    ; IR: release the %101 rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %97, i32 %89, i32 %86)    ; IR: uncompute %101  [product]
  call void @cqrt_free(i32 %97)    ; IR: release the %101 product rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %96, i32 %87, i32 %88)    ; IR: uncompute %100
  call void @cqrt_free(i32 %96)    ; IR: release the %100 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %95, i32 %94, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %99
  call void @cqrt_free(i32 %95)    ; IR: release the %99 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %94, i32 %93, i32 %92)    ; IR: uncompute %98  [sum]
  call void @cqrt_free(i32 %94)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %93, i32 %89, i32 %87)    ; IR: uncompute %98  [product]
  call void @cqrt_free(i32 %93)    ; IR: release the %98 product rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %92, i32 %86, i32 %91)    ; IR: uncompute %97
  call void @cqrt_free(i32 %92)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fneg_f80_unc(i32 %91, i32 %88)    ; IR: uncompute %96
  call void @cqrt_free(i32 %91)    ; IR: release the %96 rail (|0>)
  call void @cqrt_and_i1(i32 %59, i32 %72, i32 %90)    ; IR: uncompute %94  [self-inverse]
  call void @cqrt_free(i32 %90)    ; IR: release the %94 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %89, i32 %85, i32 %75, i32 %57)    ; IR: uncompute %93
  call void @cqrt_free(i32 %89)    ; IR: release the %93 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %88, i32 %85, i32 %78, i32 %56)    ; IR: uncompute %92
  call void @cqrt_free(i32 %88)    ; IR: release the %92 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %87, i32 %85, i32 %81, i32 %55)    ; IR: uncompute %91
  call void @cqrt_free(i32 %87)    ; IR: release the %91 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %86, i32 %85, i32 %84, i32 %54)    ; IR: uncompute %90
  call void @cqrt_free(i32 %86)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %72)    ; IR: bracket: P76 reads NOT %72
  call void @cqrt_and_i1(i32 %59, i32 %72, i32 %85)    ; IR: uncompute P76  [self-inverse]
  call void @cqrt_free(i32 %85)    ; IR: release the P76 rail (|0>)
  call void @cqrt_not_i1(i32 %72)    ; IR: bracket (close): P76 reads NOT %72
  call void @cq_template_select_f80_unc(i32 %84, i32 %82, i32 %54, i32 %83)    ; IR: uncompute %88
  call void @cqrt_free(i32 %84)    ; IR: release the %88 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %83, x86_fp80 0xK00000000000000000000, i32 %54)    ; IR: uncompute %87
  call void @cqrt_free(i32 %83)    ; IR: release the %87 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %82, i32 %54, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %86
  call void @cqrt_free(i32 %82)    ; IR: release the %86 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %81, i32 %79, i32 %55, i32 %80)    ; IR: uncompute %85
  call void @cqrt_free(i32 %81)    ; IR: release the %85 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %80, x86_fp80 0xK00000000000000000000, i32 %55)    ; IR: uncompute %84
  call void @cqrt_free(i32 %80)    ; IR: release the %84 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %79, i32 %55, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %83
  call void @cqrt_free(i32 %79)    ; IR: release the %83 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %78, i32 %76, i32 %56, i32 %77)    ; IR: uncompute %82
  call void @cqrt_free(i32 %78)    ; IR: release the %82 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %77, x86_fp80 0xK00000000000000000000, i32 %56)    ; IR: uncompute %81
  call void @cqrt_free(i32 %77)    ; IR: release the %81 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %76, i32 %56, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %80
  call void @cqrt_free(i32 %76)    ; IR: release the %80 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %75, i32 %73, i32 %57, i32 %74)    ; IR: uncompute %79
  call void @cqrt_free(i32 %75)    ; IR: release the %79 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %74, x86_fp80 0xK00000000000000000000, i32 %57)    ; IR: uncompute %78
  call void @cqrt_free(i32 %74)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %73, i32 %57, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %77
  call void @cqrt_free(i32 %73)    ; IR: release the %77 rail (|0>)
  call void @cqrt_and_i1(i32 %71, i32 %68, i32 %72)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %72)    ; IR: release the %75 rail (|0>)
  call void @cqrt_free(i32 %71)    ; IR: release the seed rail (basis state)
  call void @cqrt_and_i1(i32 %67, i32 %65, i32 %68)    ; IR: uncompute %72  [self-inverse]
  call void @cqrt_free(i32 %68)    ; IR: release the %72 rail (|0>)
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %67, i32 %66, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %67)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %66, i32 %7)    ; IR: uncompute %70
  call void @cqrt_free(i32 %66)    ; IR: release the %70 rail (|0>)
  call void @cqrt_and_i1(i32 %61, i32 %64, i32 %65)    ; IR: uncompute %69  [self-inverse]
  call void @cqrt_free(i32 %65)    ; IR: release the %69 rail (|0>)
  call void @cqrt_free(i32 %64)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %61, i32 %60, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %61)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %60, i32 %5)    ; IR: uncompute %65
  call void @cqrt_free(i32 %60)    ; IR: release the %65 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %59, i32 %58, i32 0)    ; IR: uncompute %63
  call void @cqrt_free(i32 %59)    ; IR: release the %63 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %58, i32 %41, i32 1, i32 %36)    ; IR: uncompute %62
  call void @cqrt_free(i32 %58)    ; IR: release the %62 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %57, i32 %41, i32 %50, i32 %35)    ; IR: uncompute %61
  call void @cqrt_free(i32 %57)    ; IR: release the %61 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %56, i32 %41, i32 %53, i32 %34)    ; IR: uncompute %60
  call void @cqrt_free(i32 %56)    ; IR: release the %60 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %55, i32 %41, i32 %43, i32 %33)    ; IR: uncompute %59
  call void @cqrt_free(i32 %55)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %54, i32 %41, i32 %47, i32 %32)    ; IR: uncompute %58
  call void @cqrt_free(i32 %54)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %53, i32 %51, i32 %34, i32 %52)    ; IR: uncompute %56
  call void @cqrt_free(i32 %53)    ; IR: release the %56 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %52, x86_fp80 0xK00000000000000000000, i32 %34)    ; IR: uncompute %55
  call void @cqrt_free(i32 %52)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %51, i32 %34, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %54
  call void @cqrt_free(i32 %51)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %50, i32 %48, i32 %35, i32 %49)    ; IR: uncompute %53
  call void @cqrt_free(i32 %50)    ; IR: release the %53 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %49, x86_fp80 0xK00000000000000000000, i32 %35)    ; IR: uncompute %52
  call void @cqrt_free(i32 %49)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %48, i32 %35, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %51
  call void @cqrt_free(i32 %48)    ; IR: release the %51 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %47, i32 %46, i32 %32)    ; IR: uncompute %50
  call void @cqrt_free(i32 %47)    ; IR: release the %50 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %46, i32 %45)    ; IR: uncompute %49
  call void @cqrt_free(i32 %46)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %45, i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %48
  call void @cqrt_free(i32 %45)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %44, i32 %32)    ; IR: uncompute %47
  call void @cqrt_free(i32 %44)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %43, i32 %42, i32 %33)    ; IR: uncompute %46
  call void @cqrt_free(i32 %43)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %42, i32 %38)    ; IR: uncompute %45
  call void @cqrt_free(i32 %42)    ; IR: release the %45 rail (|0>)
  call void @cqrt_or_i1(i32 %40, i32 %38, i32 %41)    ; IR: uncompute %43  [self-inverse]
  call void @cqrt_free(i32 %41)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %40, i32 %39, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %42
  call void @cqrt_free(i32 %40)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %39, i32 %32)    ; IR: uncompute %41
  call void @cqrt_free(i32 %39)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %38, i32 %37, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %38)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %37, i32 %33)    ; IR: uncompute %39
  call void @cqrt_free(i32 %37)    ; IR: release the %39 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %36, i32 %19, i32 1, i32 0)    ; IR: uncompute %38
  call void @cqrt_free(i32 %36)    ; IR: release the %38 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %35, i32 %19, i32 %21, i32 %0)    ; IR: uncompute %37
  call void @cqrt_free(i32 %35)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %34, i32 %19, x86_fp80 %25, x86_fp80 %1)    ; IR: uncompute %36
  call void @cqrt_free(i32 %34)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %33, i32 %19, x86_fp80 %28, x86_fp80 %2)    ; IR: uncompute %35
  call void @cqrt_free(i32 %33)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %32, i32 %19, x86_fp80 %31, x86_fp80 %3)    ; IR: uncompute %34
  call void @cqrt_free(i32 %32)    ; IR: release the %34 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %21, i32 %20, i32 %0)    ; IR: uncompute %22
  call void @cqrt_free(i32 %21)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %20, i32 %15)    ; IR: uncompute %21
  call void @cqrt_free(i32 %20)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %18, i32 %15, i32 %19)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cqrt_free(i32 %18)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %15, i32 %14, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %15)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %14, i32 %0)    ; IR: uncompute %15
  call void @cqrt_free(i32 %14)    ; IR: release the %15 rail (|0>)
  call void @cqrt_or_i1(i32 %11, i32 %12, i32 %13)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %12, i32 %10, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %11, i32 %9, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f80_hl_unc(i32 %10, i32 %7, x86_fp80 %8)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f80_hl_unc(i32 %9, i32 %5, x86_fp80 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %7, i32 %0, x86_fp80 %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %5, i32 %0, x86_fp80 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %105 = insertvalue { i32, i32 } poison, i32 %103, 0    ; IR: ret: field 0 (handle)
  %106 = insertvalue { i32, i32 } %105, i32 %104, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %106    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc void @__cq_q___mulxc3_1000_unc(i32 %0, i32 %1, i32 %2, x86_fp80 %3, x86_fp80 %4, x86_fp80 %5) {
  %7 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %4)    ; IR: %5 = fmul %0, %2  (a*c)
  %8 = fmul x86_fp80 %3, %5    ; IR: %6 = fmul %1, %3  (b*d)  (classical)
  %9 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %5)    ; IR: %7 = fmul %0, %3  (a*d)
  %10 = fmul x86_fp80 %3, %4    ; IR: %8 = fmul %1, %2  (b*c)  (classical)
  %11 = call i32 @cq_template_fsub_f80_hl(i32 %7, x86_fp80 %8)    ; IR: %9 = fsub %5, %6  (real part of the fast product)
  %12 = call i32 @cq_template_fadd_f80_hl(i32 %9, x86_fp80 %10)    ; IR: %10 = fadd %8, %7  (imaginary part)  (commutative, quantum operand first)
  %13 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %11, x86_fp80 0xK00000000000000000000)    ; IR: %11 = fcmp ord %9, 0  (!isnan)
  %14 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %12, x86_fp80 0xK00000000000000000000)    ; IR: %12 = fcmp ord %10, 0
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %13, i32 %14, i32 %15)    ; IR: %13 = or i1 %11, %12  [br %13 -> exit %103; block %14 runs under !%13]
  %16 = call i32 @cq_template_fabs_f80(i32 %2)    ; IR: %15 = fabs(a)  (block %14)
  %17 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %16, x86_fp80 0xK7FFF8000000000000000)    ; IR: %16 = isinf(a)
  %18 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %3)    ; IR: %17 = fabs(b)  (classical)
  %19 = fcmp oeq x86_fp80 %18, 0xK7FFF8000000000000000    ; IR: %18 = isinf(b)  (classical)
  %20 = call i32 @cqrt_alloc_i1(i1 %19)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [the classical conjunct %19 as a seed rail, rule 7]
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %20, i32 %17, i32 %21)    ; IR: %19 = or i1 %18, %16  [predicate of block %20 within %14]
  %22 = call i32 @cq_template_uitofp_i1_to_f80(i32 %17)    ; IR: %21 = uitofp i1 %16  (block %20)
  %23 = call i32 @cq_template_copysign_f80(i32 %22, i32 %2)    ; IR: %22 = copysign(%21, a)
  %24 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %3)    ; IR: %23 = fabs(b)  (classical)
  %25 = fcmp oeq x86_fp80 %24, 0xK7FFF8000000000000000    ; IR: %24 = isinf(b)  (classical)
  %26 = uitofp i1 %25 to x86_fp80    ; IR: %25 = uitofp i1 %24  (classical)
  %27 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %26, x86_fp80 %3)    ; IR: %26 = copysign(%25, b)  (classical)
  %28 = fcmp ord x86_fp80 %4, 0xK00000000000000000000    ; IR: %27 = fcmp ord c, 0  (!isnan(c))  (classical)
  %29 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %4)    ; IR: %28 = copysign(0, c)  (classical)
  %30 = select i1 %28, x86_fp80 %4, x86_fp80 %29    ; IR: %29 = select %27, %2, %28  (classical)
  %31 = fcmp ord x86_fp80 %5, 0xK00000000000000000000    ; IR: %30 = fcmp ord d, 0  (classical)
  %32 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK00000000000000000000, x86_fp80 %5)    ; IR: %31 = copysign(0, d)  (classical)
  %33 = select i1 %31, x86_fp80 %5, x86_fp80 %32    ; IR: %32 = select %30, %3, %31  (classical)
  %34 = call i32 @cq_template_select_f80_ll(i32 %21, x86_fp80 %33, x86_fp80 %5)    ; IR: %34 = phi [ %32, %20 ], [ %3, %14 ]  (merge of block %20 on %19)
  %35 = call i32 @cq_template_select_f80_ll(i32 %21, x86_fp80 %30, x86_fp80 %4)    ; IR: %35 = phi [ %29, %20 ], [ %2, %14 ]
  %36 = call i32 @cq_template_select_f80_ll(i32 %21, x86_fp80 %27, x86_fp80 %3)    ; IR: %36 = phi [ %26, %20 ], [ %1, %14 ]
  %37 = call i32 @cq_template_select_f80(i32 %21, i32 %23, i32 %2)    ; IR: %37 = phi [ %22, %20 ], [ %0, %14 ]
  %38 = call i32 @cq_template_select_i32_ll(i32 %21, i32 1, i32 0)    ; IR: %38 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %39 = call i32 @cq_template_fabs_f80(i32 %35)    ; IR: %39 = fabs(%35)  (block %33)
  %40 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %39, x86_fp80 0xK7FFF8000000000000000)    ; IR: %40 = isinf(%35)
  %41 = call i32 @cq_template_fabs_f80(i32 %34)    ; IR: %41 = fabs(%34)
  %42 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %41, x86_fp80 0xK7FFF8000000000000000)    ; IR: %42 = isinf(%34)
  %43 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %42, i32 %40, i32 %43)    ; IR: %43 = or i1 %42, %40  [predicate of block %44]
  %44 = call i32 @cq_template_uitofp_i1_to_f80(i32 %40)    ; IR: %45 = uitofp i1 %40  (block %44)
  %45 = call i32 @cq_template_copysign_f80(i32 %44, i32 %35)    ; IR: %46 = copysign(%45, %35)
  %46 = call i32 @cq_template_fabs_f80(i32 %34)    ; IR: %47 = fabs(%34)
  %47 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %46, x86_fp80 0xK7FFF8000000000000000)    ; IR: %48 = isinf(%34)
  %48 = call i32 @cq_template_uitofp_i1_to_f80(i32 %47)    ; IR: %49 = uitofp i1 %48
  %49 = call i32 @cq_template_copysign_f80(i32 %48, i32 %34)    ; IR: %50 = copysign(%49, %34)
  %50 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %37, x86_fp80 0xK00000000000000000000)    ; IR: %51 = fcmp ord %37, 0
  %51 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %37)    ; IR: %52 = copysign(0, %37)
  %52 = call i32 @cq_template_select_f80(i32 %50, i32 %37, i32 %51)    ; IR: %53 = select %51, %37, %52
  %53 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %36, x86_fp80 0xK00000000000000000000)    ; IR: %54 = fcmp ord %36, 0
  %54 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %36)    ; IR: %55 = copysign(0, %36)
  %55 = call i32 @cq_template_select_f80(i32 %53, i32 %36, i32 %54)    ; IR: %56 = select %54, %36, %55
  %56 = call i32 @cq_template_select_f80(i32 %43, i32 %49, i32 %34)    ; IR: %58 = phi [ %50, %44 ], [ %34, %33 ]  (merge of block %44 on %43)
  %57 = call i32 @cq_template_select_f80(i32 %43, i32 %45, i32 %35)    ; IR: %59 = phi [ %46, %44 ], [ %35, %33 ]
  %58 = call i32 @cq_template_select_f80(i32 %43, i32 %55, i32 %36)    ; IR: %60 = phi [ %56, %44 ], [ %36, %33 ]
  %59 = call i32 @cq_template_select_f80(i32 %43, i32 %52, i32 %37)    ; IR: %61 = phi [ %53, %44 ], [ %37, %33 ]
  %60 = call i32 @cq_template_select_i32_lh(i32 %43, i32 1, i32 %38)    ; IR: %62 = phi [ 1, %44 ], [ %38, %33 ]  (__recalc)
  %61 = call i32 @cq_template_icmp_eq_i32_hl(i32 %60, i32 0)    ; IR: %63 = icmp eq %62, 0  [predicate of block %64: !__recalc]
  %62 = call i32 @cq_template_fabs_f80(i32 %7)    ; IR: %65 = fabs(%5)  (block %64)
  %63 = call i32 @cq_template_fcmp_une_f80_hl(i32 %62, x86_fp80 0xK7FFF8000000000000000)    ; IR: %66 = !isinf(ac)
  %64 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %8)    ; IR: %67 = fabs(%6)  (classical)
  %65 = fcmp une x86_fp80 %64, 0xK7FFF8000000000000000    ; IR: %68 = !isinf(bd)  (classical)
  %66 = call i32 @cqrt_alloc_i1(i1 %65)    ; IR: %69 = and i1 %66, %68  [the classical conjunct %65 as a seed rail, rule 7]
  %67 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %69 = and i1 %66, %68  [fresh flag rail]
  call void @cqrt_and_i1(i32 %63, i32 %66, i32 %67)    ; IR: %69 = and i1 %66, %68
  %68 = call i32 @cq_template_fabs_f80(i32 %9)    ; IR: %70 = fabs(%7)
  %69 = call i32 @cq_template_fcmp_une_f80_hl(i32 %68, x86_fp80 0xK7FFF8000000000000000)    ; IR: %71 = !isinf(ad)
  %70 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %72 = and i1 %71, %69  [fresh flag rail]
  call void @cqrt_and_i1(i32 %69, i32 %67, i32 %70)    ; IR: %72 = and i1 %71, %69
  %71 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %10)    ; IR: %73 = fabs(%8)  (classical)
  %72 = fcmp une x86_fp80 %71, 0xK7FFF8000000000000000    ; IR: %74 = !isinf(bc)  (classical)
  %73 = call i32 @cqrt_alloc_i1(i1 %72)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [the classical conjunct %72 as a seed rail, rule 7]
  %74 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %73, i32 %70, i32 %74)    ; IR: %75 = and i1 %74, %72  [br %75 -> %89; block %76 runs under %63 & !%75]
  %75 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %59, x86_fp80 0xK00000000000000000000)    ; IR: %77 = fcmp ord %61, 0  (block %76)
  %76 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %59)    ; IR: %78 = copysign(0, %61)
  %77 = call i32 @cq_template_select_f80(i32 %75, i32 %59, i32 %76)    ; IR: %79 = select %77, %61, %78
  %78 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %58, x86_fp80 0xK00000000000000000000)    ; IR: %80 = fcmp ord %60, 0
  %79 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %58)    ; IR: %81 = copysign(0, %60)
  %80 = call i32 @cq_template_select_f80(i32 %78, i32 %58, i32 %79)    ; IR: %82 = select %80, %60, %81
  %81 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %57, x86_fp80 0xK00000000000000000000)    ; IR: %83 = fcmp ord %59, 0
  %82 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %57)    ; IR: %84 = copysign(0, %59)
  %83 = call i32 @cq_template_select_f80(i32 %81, i32 %57, i32 %82)    ; IR: %85 = select %83, %59, %84
  %84 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %56, x86_fp80 0xK00000000000000000000)    ; IR: %86 = fcmp ord %58, 0
  %85 = call i32 @cq_template_copysign_f80_lh(x86_fp80 0xK00000000000000000000, i32 %56)    ; IR: %87 = copysign(0, %58)
  %86 = call i32 @cq_template_select_f80(i32 %84, i32 %56, i32 %85)    ; IR: %88 = select %86, %58, %87
  call void @cqrt_not_i1(i32 %74)    ; IR: bracket: P76 reads NOT %74
  %87 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75  [fresh flag rail]
  call void @cqrt_and_i1(i32 %61, i32 %74, i32 %87)    ; IR: P76 = path predicate of block %76 relative to %57: %63 & !%75
  call void @cqrt_not_i1(i32 %74)    ; IR: bracket (close): P76 reads NOT %74
  %88 = call i32 @cq_template_select_f80(i32 %87, i32 %86, i32 %56)    ; IR: %90 = phi [ %58, %57 ], [ %88, %76 ], [ %58, %64 ]  (only the %76 path differs)
  %89 = call i32 @cq_template_select_f80(i32 %87, i32 %83, i32 %57)    ; IR: %91 = phi [ %59, %57 ], [ %85, %76 ], [ %59, %64 ]
  %90 = call i32 @cq_template_select_f80(i32 %87, i32 %80, i32 %58)    ; IR: %92 = phi [ %60, %57 ], [ %82, %76 ], [ %60, %64 ]
  %91 = call i32 @cq_template_select_f80(i32 %87, i32 %77, i32 %59)    ; IR: %93 = phi [ %61, %57 ], [ %79, %76 ], [ %61, %64 ]
  %92 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %61, i32 %74, i32 %92)    ; IR: %94 = phi i1 [ false, %57 ], [ false, %76 ], [ true, %64 ] = %63 & %75  [no recalculation]
  %93 = call i32 @cq_template_fneg_f80(i32 %90)    ; IR: %96 = fneg %92  (block %95)
  %94 = call i32 @cq_template_fmul_f80(i32 %88, i32 %93)    ; IR: %97 = fmul %90, %96
  %95 = call i32 @cq_template_fmul_f80(i32 %91, i32 %89)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused product]
  %96 = call i32 @cq_template_fadd_f80(i32 %95, i32 %94)    ; IR: %98 = fmuladd(%93, %91, %97)  [unfused sum]
  %97 = call i32 @cq_template_fmul_f80_hl(i32 %96, x86_fp80 0xK7FFF8000000000000000)    ; IR: %99 = fmul %98, inf
  %98 = call i32 @cq_template_fmul_f80(i32 %89, i32 %90)    ; IR: %100 = fmul %91, %92
  %99 = call i32 @cq_template_fmul_f80(i32 %91, i32 %88)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused product]
  %100 = call i32 @cq_template_fadd_f80(i32 %99, i32 %98)    ; IR: %101 = fmuladd(%93, %90, %100)  [unfused sum]
  %101 = call i32 @cq_template_fmul_f80_hl(i32 %100, x86_fp80 0xK7FFF8000000000000000)    ; IR: %102 = fmul %101, inf
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: P95 reads NOT %15
  call void @cqrt_not_i1(i32 %92)    ; IR: bracket: P95 reads NOT %92
  %102 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P95 = path predicate of block %95: !%13 & !%94  [fresh flag rail]
  call void @cqrt_and_i1(i32 %15, i32 %92, i32 %102)    ; IR: P95 = path predicate of block %95: !%13 & !%94
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket (close): P95 reads NOT %15
  call void @cqrt_not_i1(i32 %92)    ; IR: bracket (close): P95 reads NOT %92
  %103 = call i32 @cq_template_select_f80(i32 %102, i32 %97, i32 %11)    ; IR: %105 = phi [ %9, %4 ], [ %99, %95 ], [ %9, %89 ]  (real result)
  %104 = call i32 @cq_template_select_f80(i32 %102, i32 %101, i32 %12)    ; IR: %104 = phi [ %10, %4 ], [ %102, %95 ], [ %10, %89 ]  (imaginary result)
  call void @cqrt_copy_f80(i32 %103, i32 %0)    ; IR: xor real out of the result rail
  call void @cqrt_copy_f80(i32 %104, i32 %1)    ; IR: xor imaginary out of the result rail
  call void @cq_template_select_f80_unc(i32 %104, i32 %102, i32 %101, i32 %12)    ; IR: uncompute %104
  call void @cqrt_free(i32 %104)    ; IR: release the %104 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %103, i32 %102, i32 %97, i32 %11)    ; IR: uncompute %105
  call void @cqrt_free(i32 %103)    ; IR: release the %105 rail (|0>)
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: P95 reads NOT %15
  call void @cqrt_not_i1(i32 %92)    ; IR: bracket: P95 reads NOT %92
  call void @cqrt_and_i1(i32 %15, i32 %92, i32 %102)    ; IR: uncompute P95  [self-inverse]
  call void @cqrt_free(i32 %102)    ; IR: release the P95 rail (|0>)
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket (close): P95 reads NOT %15
  call void @cqrt_not_i1(i32 %92)    ; IR: bracket (close): P95 reads NOT %92
  call void @cq_template_fmul_f80_hl_unc(i32 %101, i32 %100, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %102
  call void @cqrt_free(i32 %101)    ; IR: release the %102 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %100, i32 %99, i32 %98)    ; IR: uncompute %101  [sum]
  call void @cqrt_free(i32 %100)    ; IR: release the %101 rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %99, i32 %91, i32 %88)    ; IR: uncompute %101  [product]
  call void @cqrt_free(i32 %99)    ; IR: release the %101 product rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %98, i32 %89, i32 %90)    ; IR: uncompute %100
  call void @cqrt_free(i32 %98)    ; IR: release the %100 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %97, i32 %96, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %99
  call void @cqrt_free(i32 %97)    ; IR: release the %99 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %96, i32 %95, i32 %94)    ; IR: uncompute %98  [sum]
  call void @cqrt_free(i32 %96)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %95, i32 %91, i32 %89)    ; IR: uncompute %98  [product]
  call void @cqrt_free(i32 %95)    ; IR: release the %98 product rail (|0>)
  call void @cq_template_fmul_f80_unc(i32 %94, i32 %88, i32 %93)    ; IR: uncompute %97
  call void @cqrt_free(i32 %94)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fneg_f80_unc(i32 %93, i32 %90)    ; IR: uncompute %96
  call void @cqrt_free(i32 %93)    ; IR: release the %96 rail (|0>)
  call void @cqrt_and_i1(i32 %61, i32 %74, i32 %92)    ; IR: uncompute %94  [self-inverse]
  call void @cqrt_free(i32 %92)    ; IR: release the %94 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %91, i32 %87, i32 %77, i32 %59)    ; IR: uncompute %93
  call void @cqrt_free(i32 %91)    ; IR: release the %93 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %90, i32 %87, i32 %80, i32 %58)    ; IR: uncompute %92
  call void @cqrt_free(i32 %90)    ; IR: release the %92 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %89, i32 %87, i32 %83, i32 %57)    ; IR: uncompute %91
  call void @cqrt_free(i32 %89)    ; IR: release the %91 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %88, i32 %87, i32 %86, i32 %56)    ; IR: uncompute %90
  call void @cqrt_free(i32 %88)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %74)    ; IR: bracket: P76 reads NOT %74
  call void @cqrt_and_i1(i32 %61, i32 %74, i32 %87)    ; IR: uncompute P76  [self-inverse]
  call void @cqrt_free(i32 %87)    ; IR: release the P76 rail (|0>)
  call void @cqrt_not_i1(i32 %74)    ; IR: bracket (close): P76 reads NOT %74
  call void @cq_template_select_f80_unc(i32 %86, i32 %84, i32 %56, i32 %85)    ; IR: uncompute %88
  call void @cqrt_free(i32 %86)    ; IR: release the %88 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %85, x86_fp80 0xK00000000000000000000, i32 %56)    ; IR: uncompute %87
  call void @cqrt_free(i32 %85)    ; IR: release the %87 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %84, i32 %56, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %86
  call void @cqrt_free(i32 %84)    ; IR: release the %86 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %83, i32 %81, i32 %57, i32 %82)    ; IR: uncompute %85
  call void @cqrt_free(i32 %83)    ; IR: release the %85 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %82, x86_fp80 0xK00000000000000000000, i32 %57)    ; IR: uncompute %84
  call void @cqrt_free(i32 %82)    ; IR: release the %84 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %81, i32 %57, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %83
  call void @cqrt_free(i32 %81)    ; IR: release the %83 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %80, i32 %78, i32 %58, i32 %79)    ; IR: uncompute %82
  call void @cqrt_free(i32 %80)    ; IR: release the %82 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %79, x86_fp80 0xK00000000000000000000, i32 %58)    ; IR: uncompute %81
  call void @cqrt_free(i32 %79)    ; IR: release the %81 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %78, i32 %58, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %80
  call void @cqrt_free(i32 %78)    ; IR: release the %80 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %77, i32 %75, i32 %59, i32 %76)    ; IR: uncompute %79
  call void @cqrt_free(i32 %77)    ; IR: release the %79 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %76, x86_fp80 0xK00000000000000000000, i32 %59)    ; IR: uncompute %78
  call void @cqrt_free(i32 %76)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %75, i32 %59, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %77
  call void @cqrt_free(i32 %75)    ; IR: release the %77 rail (|0>)
  call void @cqrt_and_i1(i32 %73, i32 %70, i32 %74)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %74)    ; IR: release the %75 rail (|0>)
  call void @cqrt_free(i32 %73)    ; IR: release the seed rail (basis state)
  call void @cqrt_and_i1(i32 %69, i32 %67, i32 %70)    ; IR: uncompute %72  [self-inverse]
  call void @cqrt_free(i32 %70)    ; IR: release the %72 rail (|0>)
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %69, i32 %68, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %69)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %68, i32 %9)    ; IR: uncompute %70
  call void @cqrt_free(i32 %68)    ; IR: release the %70 rail (|0>)
  call void @cqrt_and_i1(i32 %63, i32 %66, i32 %67)    ; IR: uncompute %69  [self-inverse]
  call void @cqrt_free(i32 %67)    ; IR: release the %69 rail (|0>)
  call void @cqrt_free(i32 %66)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %63, i32 %62, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %63)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %62, i32 %7)    ; IR: uncompute %65
  call void @cqrt_free(i32 %62)    ; IR: release the %65 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %61, i32 %60, i32 0)    ; IR: uncompute %63
  call void @cqrt_free(i32 %61)    ; IR: release the %63 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %60, i32 %43, i32 1, i32 %38)    ; IR: uncompute %62
  call void @cqrt_free(i32 %60)    ; IR: release the %62 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %59, i32 %43, i32 %52, i32 %37)    ; IR: uncompute %61
  call void @cqrt_free(i32 %59)    ; IR: release the %61 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %58, i32 %43, i32 %55, i32 %36)    ; IR: uncompute %60
  call void @cqrt_free(i32 %58)    ; IR: release the %60 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %57, i32 %43, i32 %45, i32 %35)    ; IR: uncompute %59
  call void @cqrt_free(i32 %57)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %56, i32 %43, i32 %49, i32 %34)    ; IR: uncompute %58
  call void @cqrt_free(i32 %56)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %55, i32 %53, i32 %36, i32 %54)    ; IR: uncompute %56
  call void @cqrt_free(i32 %55)    ; IR: release the %56 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %54, x86_fp80 0xK00000000000000000000, i32 %36)    ; IR: uncompute %55
  call void @cqrt_free(i32 %54)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %53, i32 %36, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %54
  call void @cqrt_free(i32 %53)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %52, i32 %50, i32 %37, i32 %51)    ; IR: uncompute %53
  call void @cqrt_free(i32 %52)    ; IR: release the %53 rail (|0>)
  call void @cq_template_copysign_f80_lh_unc(i32 %51, x86_fp80 0xK00000000000000000000, i32 %37)    ; IR: uncompute %52
  call void @cqrt_free(i32 %51)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %50, i32 %37, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %51
  call void @cqrt_free(i32 %50)    ; IR: release the %51 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %49, i32 %48, i32 %34)    ; IR: uncompute %50
  call void @cqrt_free(i32 %49)    ; IR: release the %50 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %48, i32 %47)    ; IR: uncompute %49
  call void @cqrt_free(i32 %48)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %47, i32 %46, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %48
  call void @cqrt_free(i32 %47)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %46, i32 %34)    ; IR: uncompute %47
  call void @cqrt_free(i32 %46)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %45, i32 %44, i32 %35)    ; IR: uncompute %46
  call void @cqrt_free(i32 %45)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %44, i32 %40)    ; IR: uncompute %45
  call void @cqrt_free(i32 %44)    ; IR: release the %45 rail (|0>)
  call void @cqrt_or_i1(i32 %42, i32 %40, i32 %43)    ; IR: uncompute %43  [self-inverse]
  call void @cqrt_free(i32 %43)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %42, i32 %41, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %42
  call void @cqrt_free(i32 %42)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %41, i32 %34)    ; IR: uncompute %41
  call void @cqrt_free(i32 %41)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %40, i32 %39, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %40)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %39, i32 %35)    ; IR: uncompute %39
  call void @cqrt_free(i32 %39)    ; IR: release the %39 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %38, i32 %21, i32 1, i32 0)    ; IR: uncompute %38
  call void @cqrt_free(i32 %38)    ; IR: release the %38 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %37, i32 %21, i32 %23, i32 %2)    ; IR: uncompute %37
  call void @cqrt_free(i32 %37)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %36, i32 %21, x86_fp80 %27, x86_fp80 %3)    ; IR: uncompute %36
  call void @cqrt_free(i32 %36)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %35, i32 %21, x86_fp80 %30, x86_fp80 %4)    ; IR: uncompute %35
  call void @cqrt_free(i32 %35)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f80_ll_unc(i32 %34, i32 %21, x86_fp80 %33, x86_fp80 %5)    ; IR: uncompute %34
  call void @cqrt_free(i32 %34)    ; IR: release the %34 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %23, i32 %22, i32 %2)    ; IR: uncompute %22
  call void @cqrt_free(i32 %23)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %22, i32 %17)    ; IR: uncompute %21
  call void @cqrt_free(i32 %22)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %20, i32 %17, i32 %21)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %21)    ; IR: release the %19 rail (|0>)
  call void @cqrt_free(i32 %20)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %17, i32 %16, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %16
  call void @cqrt_free(i32 %17)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %16, i32 %2)    ; IR: uncompute %15
  call void @cqrt_free(i32 %16)    ; IR: release the %15 rail (|0>)
  call void @cqrt_or_i1(i32 %13, i32 %14, i32 %15)    ; IR: uncompute %13  [self-inverse]
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %14, i32 %12, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %13, i32 %11, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f80_hl_unc(i32 %12, i32 %9, x86_fp80 %10)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f80_hl_unc(i32 %11, i32 %7, x86_fp80 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %9, i32 %2, x86_fp80 %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %7, i32 %2, x86_fp80 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

define internal fastcc { i32, i32 } @__cq_q___divxc3_1100(i32 %0, i32 %1, x86_fp80 %2, x86_fp80 %3) {
  %5 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %2)    ; IR: %5 = fabs(c)  (classical)
  %6 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %3)    ; IR: %6 = fabs(d)  (classical)
  %7 = tail call x86_fp80 @llvm.maxnum.f80(x86_fp80 %5, x86_fp80 %6)    ; IR: %7 = maxnum(%5, %6)  (fmax)  (classical)
  %8 = tail call x86_fp80 @logbl(x86_fp80 noundef %7)    ; IR: %8 = logbl(%7)  (classical)
  %9 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %8)    ; IR: %9 = fabs(%8)  (classical)
  %10 = fcmp ueq x86_fp80 %9, 0xK7FFF8000000000000000    ; IR: %10 = fcmp ueq %9, inf  (!isfinite(logbw))  [br %10 -> %16, else block %11]  (classical)
  %11 = fptosi x86_fp80 %8 to i32    ; IR: %12 = fptosi %8 to i32  (block %11)  (classical)
  %12 = sub i32 0, %11    ; IR: %13 = sub nsw 0, %12  (classical)
  %13 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %2, i32 noundef %12)    ; IR: %14 = scalbnl(c, %13)  (classical)
  %14 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %3, i32 noundef %12)    ; IR: %15 = scalbnl(d, %13)  (classical)
  %15 = select i1 %10, i32 0, i32 %11    ; IR: %17 = phi [ %12, %11 ], [ 0, %4 ]  (ilogbw)  (classical)
  %16 = select i1 %10, x86_fp80 %3, x86_fp80 %14    ; IR: %18 = phi [ %15, %11 ], [ %3, %4 ]  (d)  (classical)
  %17 = select i1 %10, x86_fp80 %2, x86_fp80 %13    ; IR: %19 = phi [ %14, %11 ], [ %2, %4 ]  (c; the %10 edge keeps c)  (classical)
  %18 = fmul x86_fp80 %16, %16    ; IR: %20 = fmul %18, %18  (classical)
  %19 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %17, x86_fp80 %17, x86_fp80 %18)    ; IR: %21 = fmuladd(%19, %19, %20)  (denom)  (classical)
  %20 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 %16)    ; IR: %22 = fmul %18, %1  (commutative, quantum operand first)
  %21 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %17)    ; IR: %23 = fmuladd(%0, %19, %22)  [unfused product]
  %22 = call i32 @cq_template_fadd_f80(i32 %21, i32 %20)    ; IR: %23 = fmuladd(%0, %19, %22)  [unfused sum]
  %23 = call i32 @cq_template_fdiv_f80_hl(i32 %22, x86_fp80 %19)    ; IR: %24 = fdiv %23, %21
  %24 = sub i32 0, %15    ; IR: %25 = sub nsw 0, %17  (classical)
  %25 = call fastcc i32 @__cq_q_scalbnl_10(i32 %23, i32 %24)    ; IR: %26 = scalbnl(%24, %25)  (real z), quantum clone (mask 10, injected musl body)
  %26 = fneg x86_fp80 %16    ; IR: %27 = fneg %18  (classical)
  %27 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %26)    ; IR: %28 = fmul %27, %0  (commutative, quantum operand first)
  %28 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 %17)    ; IR: %29 = fmuladd(%1, %19, %28)  [unfused product]
  %29 = call i32 @cq_template_fadd_f80(i32 %28, i32 %27)    ; IR: %29 = fmuladd(%1, %19, %28)  [unfused sum]
  %30 = call i32 @cq_template_fdiv_f80_hl(i32 %29, x86_fp80 %19)    ; IR: %30 = fdiv %29, %21
  %31 = call fastcc i32 @__cq_q_scalbnl_10(i32 %30, i32 %24)    ; IR: %31 = scalbnl(%30, %25)  (imag z), quantum clone (mask 10, injected musl body)
  %32 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %25, x86_fp80 0xK00000000000000000000)    ; IR: %32 = fcmp ord %26, 0
  %33 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %31, x86_fp80 0xK00000000000000000000)    ; IR: %33 = fcmp ord %31, 0
  %34 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %95; block %35 runs under !%34]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %32, i32 %33, i32 %34)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %95; block %35 runs under !%34]
  %35 = fcmp oeq x86_fp80 %19, 0xK00000000000000000000    ; IR: %36 = fcmp oeq %21, 0  (denom == 0; block %35)  (classical)
  %36 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %0, x86_fp80 0xK00000000000000000000)    ; IR: %38 = fcmp ord %0, 0  (block %37)
  %37 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %1, x86_fp80 0xK00000000000000000000)    ; IR: %39 = fcmp ord %1, 0
  %38 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %40 = or i1 %38, %39  [fresh flag rail]
  call void @cqrt_or_i1(i32 %36, i32 %37, i32 %38)    ; IR: %40 = or i1 %38, %39
  %39 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK7FFF8000000000000000, x86_fp80 %17)    ; IR: %42 = copysign(inf, %19)  (block %41)  (classical)
  %40 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %39)    ; IR: %43 = fmul %42, %0  (commutative, quantum operand first)
  %41 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 %39)    ; IR: %44 = fmul %42, %1  (commutative, quantum operand first)
  %42 = call i32 @cq_template_fabs_f80(i32 %0)    ; IR: %46 = fabs(a)  (block %45)
  %43 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %42, x86_fp80 0xK7FFF8000000000000000)    ; IR: %47 = isinf(a)
  %44 = call i32 @cq_template_fabs_f80(i32 %1)    ; IR: %49 = fabs(b)
  %45 = call i32 @cq_template_fcmp_une_f80_hl(i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: %50 = !isinf(b)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket: %51 reads NOT %41
  %46 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %51 = and i1 %50, %48  (%48 = xor i1 %47, true: NOT %47)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %45, i32 %43, i32 %46)    ; IR: %51 = and i1 %50, %48  (%48 = xor i1 %47, true: NOT %47)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket (close): %51 reads NOT %41
  %47 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %17)    ; IR: %52 = fabs(%19)  (classical)
  %48 = fcmp ueq x86_fp80 %47, 0xK7FFF8000000000000000    ; IR: %53 = !isfinite(%19)  (classical)
  %49 = call i32 @cqrt_alloc_i1(i1 %48)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53  [the classical conjunct %46 as a seed rail, rule 7]
  %50 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53  [fresh flag rail]
  call void @cqrt_or_i1(i32 %46, i32 %49, i32 %50)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53
  %51 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %16)    ; IR: %55 = fabs(%18)  (classical)
  %52 = fcmp ueq x86_fp80 %51, 0xK7FFF8000000000000000    ; IR: %56 = !isfinite(%18)  (classical)
  %53 = call i32 @cqrt_alloc_i1(i1 %52)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]  [the classical conjunct %50 as a seed rail, rule 7]
  %54 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %50, i32 %53, i32 %54)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]
  %55 = call i32 @cq_template_uitofp_i1_to_f80(i32 %43)    ; IR: %59 = uitofp i1 %47  (block %58)
  %56 = call i32 @cq_template_copysign_f80(i32 %55, i32 %0)    ; IR: %60 = copysign(%59, a)
  %57 = call i32 @cq_template_fabs_f80(i32 %1)    ; IR: %61 = fabs(b)
  %58 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %57, x86_fp80 0xK7FFF8000000000000000)    ; IR: %62 = isinf(b)
  %59 = call i32 @cq_template_uitofp_i1_to_f80(i32 %58)    ; IR: %63 = uitofp i1 %62
  %60 = call i32 @cq_template_copysign_f80(i32 %59, i32 %1)    ; IR: %64 = copysign(%63, b)
  %61 = call i32 @cq_template_fmul_f80_hl(i32 %60, x86_fp80 %16)    ; IR: %65 = fmul %64, %18
  %62 = call i32 @cq_template_fmul_f80_hl(i32 %56, x86_fp80 %17)    ; IR: %66 = fmuladd(%60, %19, %65)  [unfused product]
  %63 = call i32 @cq_template_fadd_f80(i32 %62, i32 %61)    ; IR: %66 = fmuladd(%60, %19, %65)  [unfused sum]
  %64 = call i32 @cq_template_fmul_f80_hl(i32 %63, x86_fp80 0xK7FFF8000000000000000)    ; IR: %67 = fmul %66, inf
  %65 = call i32 @cq_template_fneg_f80(i32 %56)    ; IR: %68 = fneg %60
  %66 = call i32 @cq_template_fmul_f80_hl(i32 %65, x86_fp80 %16)    ; IR: %69 = fmul %18, %68  (commutative, quantum operand first)
  %67 = call i32 @cq_template_fmul_f80_hl(i32 %60, x86_fp80 %17)    ; IR: %70 = fmuladd(%64, %19, %69)  [unfused product]
  %68 = call i32 @cq_template_fadd_f80(i32 %67, i32 %66)    ; IR: %70 = fmuladd(%64, %19, %69)  [unfused sum]
  %69 = call i32 @cq_template_fmul_f80_hl(i32 %68, x86_fp80 0xK7FFF8000000000000000)    ; IR: %71 = fmul %70, inf
  %70 = fcmp une x86_fp80 %8, 0xK7FFF8000000000000000    ; IR: %73 = fcmp une %8, inf  (block %72)  (classical)
  %71 = call i32 @cq_template_fcmp_ueq_f80_hl(i32 %42, x86_fp80 0xK7FFF8000000000000000)    ; IR: %74 = fcmp ueq %46, inf
  %72 = call i32 @cqrt_alloc_i1(i1 %70)    ; IR: %75 = or i1 %74, %73  [the classical conjunct %66 as a seed rail, rule 7]
  %73 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = or i1 %74, %73  [fresh flag rail]
  call void @cqrt_or_i1(i32 %71, i32 %72, i32 %73)    ; IR: %75 = or i1 %74, %73
  %74 = call i32 @cq_template_fabs_f80(i32 %1)    ; IR: %76 = fabs(b)
  %75 = call i32 @cq_template_fcmp_ueq_f80_hl(i32 %74, x86_fp80 0xK7FFF8000000000000000)    ; IR: %77 = fcmp ueq %76, inf
  %76 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %78 = or i1 %77, %75  [br %78 -> exit %95, else block %79]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %75, i32 %73, i32 %76)    ; IR: %78 = or i1 %77, %75  [br %78 -> exit %95, else block %79]
  %77 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %17)    ; IR: %80 = fabs(%19)  (block %79)  (classical)
  %78 = fcmp oeq x86_fp80 %77, 0xK7FFF8000000000000000    ; IR: %81 = isinf(%19)  (classical)
  %79 = uitofp i1 %78 to x86_fp80    ; IR: %82 = uitofp i1 %81  (classical)
  %80 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %79, x86_fp80 %17)    ; IR: %83 = copysign(%82, %19)  (classical)
  %81 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %16)    ; IR: %84 = fabs(%18)  (classical)
  %82 = fcmp oeq x86_fp80 %81, 0xK7FFF8000000000000000    ; IR: %85 = isinf(%18)  (classical)
  %83 = uitofp i1 %82 to x86_fp80    ; IR: %86 = uitofp i1 %85  (classical)
  %84 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %83, x86_fp80 %16)    ; IR: %87 = copysign(%86, %18)  (classical)
  %85 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 %84)    ; IR: %88 = fmul %87, %1  (commutative, quantum operand first)
  %86 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %80)    ; IR: %89 = fmuladd(%0, %83, %88)  [unfused product]
  %87 = call i32 @cq_template_fadd_f80(i32 %86, i32 %85)    ; IR: %89 = fmuladd(%0, %83, %88)  [unfused sum]
  %88 = call i32 @cq_template_fmul_f80_hl(i32 %87, x86_fp80 0xK00000000000000000000)    ; IR: %90 = fmul %89, 0
  %89 = fneg x86_fp80 %84    ; IR: %91 = fneg %87  (classical)
  %90 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 %89)    ; IR: %92 = fmul %91, %0  (commutative, quantum operand first)
  %91 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 %80)    ; IR: %93 = fmuladd(%1, %83, %92)  [unfused product]
  %92 = call i32 @cq_template_fadd_f80(i32 %91, i32 %90)    ; IR: %93 = fmuladd(%1, %83, %92)  [unfused sum]
  %93 = call i32 @cq_template_fmul_f80_hl(i32 %92, x86_fp80 0xK00000000000000000000)    ; IR: %94 = fmul %93, 0
  %94 = call i32 @cqrt_alloc_i1(i1 %35)    ; IR: P37 = path predicate of block %37: !%34 & %36  [the classical conjunct %33 as a seed rail, rule 7]
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P37 reads NOT %32
  %95 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P37 = path predicate of block %37: !%34 & %36  [fresh flag rail]
  call void @cqrt_and_i1(i32 %34, i32 %94, i32 %95)    ; IR: P37 = path predicate of block %37: !%34 & %36
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P37 reads NOT %32
  %96 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P41 = path predicate of block %41: P37 & %40  [fresh flag rail]
  call void @cqrt_and_i1(i32 %95, i32 %38, i32 %96)    ; IR: P41 = path predicate of block %41: P37 & %40
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %96)    ; IR: bracket: P45 reads NOT %90
  %97 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %34, i32 %96, i32 %97)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %96)    ; IR: bracket (close): P45 reads NOT %90
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket: P58 reads NOT %52
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P58 = path predicate of block %58: P45 & !%57  [fresh flag rail]
  call void @cqrt_and_i1(i32 %97, i32 %54, i32 %98)    ; IR: P58 = path predicate of block %58: P45 & !%57
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket (close): P58 reads NOT %52
  %99 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72: P45 & %57  [fresh flag rail]
  call void @cqrt_and_i1(i32 %97, i32 %54, i32 %99)    ; IR: P72 = path predicate of block %72: P45 & %57
  call void @cqrt_not_i1(i32 %76)    ; IR: bracket: P79 reads NOT %72
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P79 = path predicate of block %79: P72 & !%78  [fresh flag rail]
  call void @cqrt_and_i1(i32 %99, i32 %76, i32 %100)    ; IR: P79 = path predicate of block %79: P72 & !%78
  call void @cqrt_not_i1(i32 %76)    ; IR: bracket (close): P79 reads NOT %72
  %101 = call i32 @cq_template_select_f80(i32 %96, i32 %41, i32 %31)    ; IR: %96 = phi [ %71, %58 ], [ %94, %79 ], [ %31, %72 ], [ %44, %41 ], [ %31, %16 ]: innermost select, the %41 arm against the complement %31
  %102 = call i32 @cq_template_select_f80(i32 %100, i32 %93, i32 %101)    ; IR: %96 = phi (imag result): the %79 arm
  %103 = call i32 @cq_template_select_f80(i32 %98, i32 %69, i32 %102)    ; IR: %96 = phi (imag result): the %58 arm
  %104 = call i32 @cq_template_select_f80(i32 %96, i32 %40, i32 %25)    ; IR: %97 = phi [ %67, %58 ], [ %90, %79 ], [ %26, %72 ], [ %43, %41 ], [ %26, %16 ]: innermost select, the %41 arm against the complement %26
  %105 = call i32 @cq_template_select_f80(i32 %100, i32 %88, i32 %104)    ; IR: %97 = phi (real result): the %79 arm
  %106 = call i32 @cq_template_select_f80(i32 %98, i32 %64, i32 %105)    ; IR: %97 = phi (real result): the %58 arm
  %107 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f80(i32 %106, i32 %107)    ; IR: copy real out
  %108 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f80(i32 %103, i32 %108)    ; IR: copy imaginary out
  call void @cq_template_select_f80_unc(i32 %106, i32 %98, i32 %64, i32 %105)    ; IR: uncompute %97
  call void @cqrt_free(i32 %106)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %105, i32 %100, i32 %88, i32 %104)    ; IR: uncompute %97
  call void @cqrt_free(i32 %105)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %104, i32 %96, i32 %40, i32 %25)    ; IR: uncompute %97
  call void @cqrt_free(i32 %104)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %103, i32 %98, i32 %69, i32 %102)    ; IR: uncompute %96
  call void @cqrt_free(i32 %103)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %102, i32 %100, i32 %93, i32 %101)    ; IR: uncompute %96
  call void @cqrt_free(i32 %102)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %101, i32 %96, i32 %41, i32 %31)    ; IR: uncompute %96
  call void @cqrt_free(i32 %101)    ; IR: release the %96 rail (|0>)
  call void @cqrt_not_i1(i32 %76)    ; IR: bracket: P79 reads NOT %72
  call void @cqrt_and_i1(i32 %99, i32 %76, i32 %100)    ; IR: uncompute P79  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P79 rail (|0>)
  call void @cqrt_not_i1(i32 %76)    ; IR: bracket (close): P79 reads NOT %72
  call void @cqrt_and_i1(i32 %97, i32 %54, i32 %99)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %99)    ; IR: release the P72 rail (|0>)
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket: P58 reads NOT %52
  call void @cqrt_and_i1(i32 %97, i32 %54, i32 %98)    ; IR: uncompute P58  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release the P58 rail (|0>)
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket (close): P58 reads NOT %52
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %96)    ; IR: bracket: P45 reads NOT %90
  call void @cqrt_and_i1(i32 %34, i32 %96, i32 %97)    ; IR: uncompute P45  [self-inverse]
  call void @cqrt_free(i32 %97)    ; IR: release the P45 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %96)    ; IR: bracket (close): P45 reads NOT %90
  call void @cqrt_and_i1(i32 %95, i32 %38, i32 %96)    ; IR: uncompute P41  [self-inverse]
  call void @cqrt_free(i32 %96)    ; IR: release the P41 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P37 reads NOT %32
  call void @cqrt_and_i1(i32 %34, i32 %94, i32 %95)    ; IR: uncompute P37  [self-inverse]
  call void @cqrt_free(i32 %95)    ; IR: release the P37 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P37 reads NOT %32
  call void @cqrt_free(i32 %94)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f80_hl_unc(i32 %93, i32 %92, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %94
  call void @cqrt_free(i32 %93)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %92, i32 %91, i32 %90)    ; IR: uncompute %93  [sum]
  call void @cqrt_free(i32 %92)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %91, i32 %1, x86_fp80 %80)    ; IR: uncompute %93  [product]
  call void @cqrt_free(i32 %91)    ; IR: release the %93 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %90, i32 %0, x86_fp80 %89)    ; IR: uncompute %92
  call void @cqrt_free(i32 %90)    ; IR: release the %92 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %88, i32 %87, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %90
  call void @cqrt_free(i32 %88)    ; IR: release the %90 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %87, i32 %86, i32 %85)    ; IR: uncompute %89  [sum]
  call void @cqrt_free(i32 %87)    ; IR: release the %89 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %86, i32 %0, x86_fp80 %80)    ; IR: uncompute %89  [product]
  call void @cqrt_free(i32 %86)    ; IR: release the %89 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %85, i32 %1, x86_fp80 %84)    ; IR: uncompute %88
  call void @cqrt_free(i32 %85)    ; IR: release the %88 rail (|0>)
  call void @cqrt_or_i1(i32 %75, i32 %73, i32 %76)    ; IR: uncompute %78  [self-inverse]
  call void @cqrt_free(i32 %76)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ueq_f80_hl_unc(i32 %75, i32 %74, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %77
  call void @cqrt_free(i32 %75)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %74, i32 %1)    ; IR: uncompute %76
  call void @cqrt_free(i32 %74)    ; IR: release the %76 rail (|0>)
  call void @cqrt_or_i1(i32 %71, i32 %72, i32 %73)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %73)    ; IR: release the %75 rail (|0>)
  call void @cqrt_free(i32 %72)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ueq_f80_hl_unc(i32 %71, i32 %42, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %74
  call void @cqrt_free(i32 %71)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %69, i32 %68, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %69)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %68, i32 %67, i32 %66)    ; IR: uncompute %70  [sum]
  call void @cqrt_free(i32 %68)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %67, i32 %60, x86_fp80 %17)    ; IR: uncompute %70  [product]
  call void @cqrt_free(i32 %67)    ; IR: release the %70 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %66, i32 %65, x86_fp80 %16)    ; IR: uncompute %69
  call void @cqrt_free(i32 %66)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fneg_f80_unc(i32 %65, i32 %56)    ; IR: uncompute %68
  call void @cqrt_free(i32 %65)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %64, i32 %63, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %64)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %63, i32 %62, i32 %61)    ; IR: uncompute %66  [sum]
  call void @cqrt_free(i32 %63)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %62, i32 %56, x86_fp80 %17)    ; IR: uncompute %66  [product]
  call void @cqrt_free(i32 %62)    ; IR: release the %66 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %61, i32 %60, x86_fp80 %16)    ; IR: uncompute %65
  call void @cqrt_free(i32 %61)    ; IR: release the %65 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %60, i32 %59, i32 %1)    ; IR: uncompute %64
  call void @cqrt_free(i32 %60)    ; IR: release the %64 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %59, i32 %58)    ; IR: uncompute %63
  call void @cqrt_free(i32 %59)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %58, i32 %57, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %58)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %57, i32 %1)    ; IR: uncompute %61
  call void @cqrt_free(i32 %57)    ; IR: release the %61 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %56, i32 %55, i32 %0)    ; IR: uncompute %60
  call void @cqrt_free(i32 %56)    ; IR: release the %60 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %55, i32 %43)    ; IR: uncompute %59
  call void @cqrt_free(i32 %55)    ; IR: release the %59 rail (|0>)
  call void @cqrt_or_i1(i32 %50, i32 %53, i32 %54)    ; IR: uncompute %57  [self-inverse]
  call void @cqrt_free(i32 %54)    ; IR: release the %57 rail (|0>)
  call void @cqrt_free(i32 %53)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %46, i32 %49, i32 %50)    ; IR: uncompute %54  [self-inverse]
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cqrt_free(i32 %49)    ; IR: release the seed rail (basis state)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket: %51 reads NOT %41
  call void @cqrt_and_i1(i32 %45, i32 %43, i32 %46)    ; IR: uncompute %51  [self-inverse]
  call void @cqrt_free(i32 %46)    ; IR: release the %51 rail (|0>)
  call void @cqrt_not_i1(i32 %43)    ; IR: bracket (close): %51 reads NOT %41
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %45, i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %50
  call void @cqrt_free(i32 %45)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %44, i32 %1)    ; IR: uncompute %49
  call void @cqrt_free(i32 %44)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %43, i32 %42, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %47
  call void @cqrt_free(i32 %43)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %42, i32 %0)    ; IR: uncompute %46
  call void @cqrt_free(i32 %42)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %41, i32 %1, x86_fp80 %39)    ; IR: uncompute %44
  call void @cqrt_free(i32 %41)    ; IR: release the %44 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %40, i32 %0, x86_fp80 %39)    ; IR: uncompute %43
  call void @cqrt_free(i32 %40)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %36, i32 %37, i32 %38)    ; IR: uncompute %40  [self-inverse]
  call void @cqrt_free(i32 %38)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %37, i32 %1, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %39
  call void @cqrt_free(i32 %37)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %36, i32 %0, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %36)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %32, i32 %33, i32 %34)    ; IR: uncompute %34  [self-inverse]
  call void @cqrt_free(i32 %34)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %33, i32 %31, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %33
  call void @cqrt_free(i32 %33)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %32, i32 %25, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %32
  call void @cqrt_free(i32 %32)    ; IR: release the %32 rail (|0>)
  call fastcc void @__cq_q_scalbnl_10_unc(i32 %31, i32 %30, i32 %24)    ; IR: uncompute the result rail(s) of %31
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f80_hl_unc(i32 %30, i32 %29, x86_fp80 %19)    ; IR: uncompute %30
  call void @cqrt_free(i32 %30)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %29, i32 %28, i32 %27)    ; IR: uncompute %29  [sum]
  call void @cqrt_free(i32 %29)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %28, i32 %1, x86_fp80 %17)    ; IR: uncompute %29  [product]
  call void @cqrt_free(i32 %28)    ; IR: release the %29 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %27, i32 %0, x86_fp80 %26)    ; IR: uncompute %28
  call void @cqrt_free(i32 %27)    ; IR: release the %28 rail (|0>)
  call fastcc void @__cq_q_scalbnl_10_unc(i32 %25, i32 %23, i32 %24)    ; IR: uncompute the result rail(s) of %26
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f80_hl_unc(i32 %23, i32 %22, x86_fp80 %19)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %22, i32 %21, i32 %20)    ; IR: uncompute %23  [sum]
  call void @cqrt_free(i32 %22)    ; IR: release the %23 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %21, i32 %0, x86_fp80 %17)    ; IR: uncompute %23  [product]
  call void @cqrt_free(i32 %21)    ; IR: release the %23 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %20, i32 %1, x86_fp80 %16)    ; IR: uncompute %22
  call void @cqrt_free(i32 %20)    ; IR: release the %22 rail (|0>)
  %109 = insertvalue { i32, i32 } poison, i32 %107, 0    ; IR: ret: field 0 (handle)
  %110 = insertvalue { i32, i32 } %109, i32 %108, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %110    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc void @__cq_q___divxc3_1100_unc(i32 %0, i32 %1, i32 %2, i32 %3, x86_fp80 %4, x86_fp80 %5) {
  %7 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %4)    ; IR: %5 = fabs(c)  (classical)
  %8 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %5)    ; IR: %6 = fabs(d)  (classical)
  %9 = tail call x86_fp80 @llvm.maxnum.f80(x86_fp80 %7, x86_fp80 %8)    ; IR: %7 = maxnum(%5, %6)  (fmax)  (classical)
  %10 = tail call x86_fp80 @logbl(x86_fp80 noundef %9)    ; IR: %8 = logbl(%7)  (classical)
  %11 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %10)    ; IR: %9 = fabs(%8)  (classical)
  %12 = fcmp ueq x86_fp80 %11, 0xK7FFF8000000000000000    ; IR: %10 = fcmp ueq %9, inf  (!isfinite(logbw))  [br %10 -> %16, else block %11]  (classical)
  %13 = fptosi x86_fp80 %10 to i32    ; IR: %12 = fptosi %8 to i32  (block %11)  (classical)
  %14 = sub i32 0, %13    ; IR: %13 = sub nsw 0, %12  (classical)
  %15 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %4, i32 noundef %14)    ; IR: %14 = scalbnl(c, %13)  (classical)
  %16 = tail call x86_fp80 @scalbnl(x86_fp80 noundef %5, i32 noundef %14)    ; IR: %15 = scalbnl(d, %13)  (classical)
  %17 = select i1 %12, i32 0, i32 %13    ; IR: %17 = phi [ %12, %11 ], [ 0, %4 ]  (ilogbw)  (classical)
  %18 = select i1 %12, x86_fp80 %5, x86_fp80 %16    ; IR: %18 = phi [ %15, %11 ], [ %3, %4 ]  (d)  (classical)
  %19 = select i1 %12, x86_fp80 %4, x86_fp80 %15    ; IR: %19 = phi [ %14, %11 ], [ %2, %4 ]  (c; the %10 edge keeps c)  (classical)
  %20 = fmul x86_fp80 %18, %18    ; IR: %20 = fmul %18, %18  (classical)
  %21 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %19, x86_fp80 %19, x86_fp80 %20)    ; IR: %21 = fmuladd(%19, %19, %20)  (denom)  (classical)
  %22 = call i32 @cq_template_fmul_f80_hl(i32 %3, x86_fp80 %18)    ; IR: %22 = fmul %18, %1  (commutative, quantum operand first)
  %23 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %19)    ; IR: %23 = fmuladd(%0, %19, %22)  [unfused product]
  %24 = call i32 @cq_template_fadd_f80(i32 %23, i32 %22)    ; IR: %23 = fmuladd(%0, %19, %22)  [unfused sum]
  %25 = call i32 @cq_template_fdiv_f80_hl(i32 %24, x86_fp80 %21)    ; IR: %24 = fdiv %23, %21
  %26 = sub i32 0, %17    ; IR: %25 = sub nsw 0, %17  (classical)
  %27 = call fastcc i32 @__cq_q_scalbnl_10(i32 %25, i32 %26)    ; IR: %26 = scalbnl(%24, %25)  (real z), quantum clone (mask 10, injected musl body)
  %28 = fneg x86_fp80 %18    ; IR: %27 = fneg %18  (classical)
  %29 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %28)    ; IR: %28 = fmul %27, %0  (commutative, quantum operand first)
  %30 = call i32 @cq_template_fmul_f80_hl(i32 %3, x86_fp80 %19)    ; IR: %29 = fmuladd(%1, %19, %28)  [unfused product]
  %31 = call i32 @cq_template_fadd_f80(i32 %30, i32 %29)    ; IR: %29 = fmuladd(%1, %19, %28)  [unfused sum]
  %32 = call i32 @cq_template_fdiv_f80_hl(i32 %31, x86_fp80 %21)    ; IR: %30 = fdiv %29, %21
  %33 = call fastcc i32 @__cq_q_scalbnl_10(i32 %32, i32 %26)    ; IR: %31 = scalbnl(%30, %25)  (imag z), quantum clone (mask 10, injected musl body)
  %34 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %27, x86_fp80 0xK00000000000000000000)    ; IR: %32 = fcmp ord %26, 0
  %35 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %33, x86_fp80 0xK00000000000000000000)    ; IR: %33 = fcmp ord %31, 0
  %36 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %95; block %35 runs under !%34]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %34, i32 %35, i32 %36)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %95; block %35 runs under !%34]
  %37 = fcmp oeq x86_fp80 %21, 0xK00000000000000000000    ; IR: %36 = fcmp oeq %21, 0  (denom == 0; block %35)  (classical)
  %38 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %2, x86_fp80 0xK00000000000000000000)    ; IR: %38 = fcmp ord %0, 0  (block %37)
  %39 = call i32 @cq_template_fcmp_ord_f80_hl(i32 %3, x86_fp80 0xK00000000000000000000)    ; IR: %39 = fcmp ord %1, 0
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %40 = or i1 %38, %39  [fresh flag rail]
  call void @cqrt_or_i1(i32 %38, i32 %39, i32 %40)    ; IR: %40 = or i1 %38, %39
  %41 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 0xK7FFF8000000000000000, x86_fp80 %19)    ; IR: %42 = copysign(inf, %19)  (block %41)  (classical)
  %42 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %41)    ; IR: %43 = fmul %42, %0  (commutative, quantum operand first)
  %43 = call i32 @cq_template_fmul_f80_hl(i32 %3, x86_fp80 %41)    ; IR: %44 = fmul %42, %1  (commutative, quantum operand first)
  %44 = call i32 @cq_template_fabs_f80(i32 %2)    ; IR: %46 = fabs(a)  (block %45)
  %45 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: %47 = isinf(a)
  %46 = call i32 @cq_template_fabs_f80(i32 %3)    ; IR: %49 = fabs(b)
  %47 = call i32 @cq_template_fcmp_une_f80_hl(i32 %46, x86_fp80 0xK7FFF8000000000000000)    ; IR: %50 = !isinf(b)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket: %51 reads NOT %43
  %48 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %51 = and i1 %50, %48  (%48 = xor i1 %47, true: NOT %47)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %47, i32 %45, i32 %48)    ; IR: %51 = and i1 %50, %48  (%48 = xor i1 %47, true: NOT %47)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket (close): %51 reads NOT %43
  %49 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %19)    ; IR: %52 = fabs(%19)  (classical)
  %50 = fcmp ueq x86_fp80 %49, 0xK7FFF8000000000000000    ; IR: %53 = !isfinite(%19)  (classical)
  %51 = call i32 @cqrt_alloc_i1(i1 %50)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53  [the classical conjunct %48 as a seed rail, rule 7]
  %52 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53  [fresh flag rail]
  call void @cqrt_or_i1(i32 %48, i32 %51, i32 %52)    ; IR: %54 = select i1 %51, true, %53 = %51 | %53
  %53 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %18)    ; IR: %55 = fabs(%18)  (classical)
  %54 = fcmp ueq x86_fp80 %53, 0xK7FFF8000000000000000    ; IR: %56 = !isfinite(%18)  (classical)
  %55 = call i32 @cqrt_alloc_i1(i1 %54)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]  [the classical conjunct %52 as a seed rail, rule 7]
  %56 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %52, i32 %55, i32 %56)    ; IR: %57 = select i1 %54, true, %56 = %54 | %56  [br %57 -> %72, else block %58]
  %57 = call i32 @cq_template_uitofp_i1_to_f80(i32 %45)    ; IR: %59 = uitofp i1 %47  (block %58)
  %58 = call i32 @cq_template_copysign_f80(i32 %57, i32 %2)    ; IR: %60 = copysign(%59, a)
  %59 = call i32 @cq_template_fabs_f80(i32 %3)    ; IR: %61 = fabs(b)
  %60 = call i32 @cq_template_fcmp_oeq_f80_hl(i32 %59, x86_fp80 0xK7FFF8000000000000000)    ; IR: %62 = isinf(b)
  %61 = call i32 @cq_template_uitofp_i1_to_f80(i32 %60)    ; IR: %63 = uitofp i1 %62
  %62 = call i32 @cq_template_copysign_f80(i32 %61, i32 %3)    ; IR: %64 = copysign(%63, b)
  %63 = call i32 @cq_template_fmul_f80_hl(i32 %62, x86_fp80 %18)    ; IR: %65 = fmul %64, %18
  %64 = call i32 @cq_template_fmul_f80_hl(i32 %58, x86_fp80 %19)    ; IR: %66 = fmuladd(%60, %19, %65)  [unfused product]
  %65 = call i32 @cq_template_fadd_f80(i32 %64, i32 %63)    ; IR: %66 = fmuladd(%60, %19, %65)  [unfused sum]
  %66 = call i32 @cq_template_fmul_f80_hl(i32 %65, x86_fp80 0xK7FFF8000000000000000)    ; IR: %67 = fmul %66, inf
  %67 = call i32 @cq_template_fneg_f80(i32 %58)    ; IR: %68 = fneg %60
  %68 = call i32 @cq_template_fmul_f80_hl(i32 %67, x86_fp80 %18)    ; IR: %69 = fmul %18, %68  (commutative, quantum operand first)
  %69 = call i32 @cq_template_fmul_f80_hl(i32 %62, x86_fp80 %19)    ; IR: %70 = fmuladd(%64, %19, %69)  [unfused product]
  %70 = call i32 @cq_template_fadd_f80(i32 %69, i32 %68)    ; IR: %70 = fmuladd(%64, %19, %69)  [unfused sum]
  %71 = call i32 @cq_template_fmul_f80_hl(i32 %70, x86_fp80 0xK7FFF8000000000000000)    ; IR: %71 = fmul %70, inf
  %72 = fcmp une x86_fp80 %10, 0xK7FFF8000000000000000    ; IR: %73 = fcmp une %8, inf  (block %72)  (classical)
  %73 = call i32 @cq_template_fcmp_ueq_f80_hl(i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: %74 = fcmp ueq %46, inf
  %74 = call i32 @cqrt_alloc_i1(i1 %72)    ; IR: %75 = or i1 %74, %73  [the classical conjunct %68 as a seed rail, rule 7]
  %75 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %75 = or i1 %74, %73  [fresh flag rail]
  call void @cqrt_or_i1(i32 %73, i32 %74, i32 %75)    ; IR: %75 = or i1 %74, %73
  %76 = call i32 @cq_template_fabs_f80(i32 %3)    ; IR: %76 = fabs(b)
  %77 = call i32 @cq_template_fcmp_ueq_f80_hl(i32 %76, x86_fp80 0xK7FFF8000000000000000)    ; IR: %77 = fcmp ueq %76, inf
  %78 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %78 = or i1 %77, %75  [br %78 -> exit %95, else block %79]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %77, i32 %75, i32 %78)    ; IR: %78 = or i1 %77, %75  [br %78 -> exit %95, else block %79]
  %79 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %19)    ; IR: %80 = fabs(%19)  (block %79)  (classical)
  %80 = fcmp oeq x86_fp80 %79, 0xK7FFF8000000000000000    ; IR: %81 = isinf(%19)  (classical)
  %81 = uitofp i1 %80 to x86_fp80    ; IR: %82 = uitofp i1 %81  (classical)
  %82 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %81, x86_fp80 %19)    ; IR: %83 = copysign(%82, %19)  (classical)
  %83 = tail call x86_fp80 @llvm.fabs.f80(x86_fp80 %18)    ; IR: %84 = fabs(%18)  (classical)
  %84 = fcmp oeq x86_fp80 %83, 0xK7FFF8000000000000000    ; IR: %85 = isinf(%18)  (classical)
  %85 = uitofp i1 %84 to x86_fp80    ; IR: %86 = uitofp i1 %85  (classical)
  %86 = tail call x86_fp80 @llvm.copysign.f80(x86_fp80 %85, x86_fp80 %18)    ; IR: %87 = copysign(%86, %18)  (classical)
  %87 = call i32 @cq_template_fmul_f80_hl(i32 %3, x86_fp80 %86)    ; IR: %88 = fmul %87, %1  (commutative, quantum operand first)
  %88 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %82)    ; IR: %89 = fmuladd(%0, %83, %88)  [unfused product]
  %89 = call i32 @cq_template_fadd_f80(i32 %88, i32 %87)    ; IR: %89 = fmuladd(%0, %83, %88)  [unfused sum]
  %90 = call i32 @cq_template_fmul_f80_hl(i32 %89, x86_fp80 0xK00000000000000000000)    ; IR: %90 = fmul %89, 0
  %91 = fneg x86_fp80 %86    ; IR: %91 = fneg %87  (classical)
  %92 = call i32 @cq_template_fmul_f80_hl(i32 %2, x86_fp80 %91)    ; IR: %92 = fmul %91, %0  (commutative, quantum operand first)
  %93 = call i32 @cq_template_fmul_f80_hl(i32 %3, x86_fp80 %82)    ; IR: %93 = fmuladd(%1, %83, %92)  [unfused product]
  %94 = call i32 @cq_template_fadd_f80(i32 %93, i32 %92)    ; IR: %93 = fmuladd(%1, %83, %92)  [unfused sum]
  %95 = call i32 @cq_template_fmul_f80_hl(i32 %94, x86_fp80 0xK00000000000000000000)    ; IR: %94 = fmul %93, 0
  %96 = call i32 @cqrt_alloc_i1(i1 %37)    ; IR: P37 = path predicate of block %37: !%34 & %36  [the classical conjunct %35 as a seed rail, rule 7]
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P37 reads NOT %34
  %97 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P37 = path predicate of block %37: !%34 & %36  [fresh flag rail]
  call void @cqrt_and_i1(i32 %36, i32 %96, i32 %97)    ; IR: P37 = path predicate of block %37: !%34 & %36
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P37 reads NOT %34
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P41 = path predicate of block %41: P37 & %40  [fresh flag rail]
  call void @cqrt_and_i1(i32 %97, i32 %40, i32 %98)    ; IR: P41 = path predicate of block %41: P37 & %40
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P45 reads NOT %34
  call void @cqrt_not_i1(i32 %98)    ; IR: bracket: P45 reads NOT %92
  %99 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %36, i32 %98, i32 %99)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P45 reads NOT %34
  call void @cqrt_not_i1(i32 %98)    ; IR: bracket (close): P45 reads NOT %92
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket: P58 reads NOT %54
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P58 = path predicate of block %58: P45 & !%57  [fresh flag rail]
  call void @cqrt_and_i1(i32 %99, i32 %56, i32 %100)    ; IR: P58 = path predicate of block %58: P45 & !%57
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket (close): P58 reads NOT %54
  %101 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72: P45 & %57  [fresh flag rail]
  call void @cqrt_and_i1(i32 %99, i32 %56, i32 %101)    ; IR: P72 = path predicate of block %72: P45 & %57
  call void @cqrt_not_i1(i32 %78)    ; IR: bracket: P79 reads NOT %74
  %102 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P79 = path predicate of block %79: P72 & !%78  [fresh flag rail]
  call void @cqrt_and_i1(i32 %101, i32 %78, i32 %102)    ; IR: P79 = path predicate of block %79: P72 & !%78
  call void @cqrt_not_i1(i32 %78)    ; IR: bracket (close): P79 reads NOT %74
  %103 = call i32 @cq_template_select_f80(i32 %98, i32 %43, i32 %33)    ; IR: %96 = phi [ %71, %58 ], [ %94, %79 ], [ %31, %72 ], [ %44, %41 ], [ %31, %16 ]: innermost select, the %41 arm against the complement %31
  %104 = call i32 @cq_template_select_f80(i32 %102, i32 %95, i32 %103)    ; IR: %96 = phi (imag result): the %79 arm
  %105 = call i32 @cq_template_select_f80(i32 %100, i32 %71, i32 %104)    ; IR: %96 = phi (imag result): the %58 arm
  %106 = call i32 @cq_template_select_f80(i32 %98, i32 %42, i32 %27)    ; IR: %97 = phi [ %67, %58 ], [ %90, %79 ], [ %26, %72 ], [ %43, %41 ], [ %26, %16 ]: innermost select, the %41 arm against the complement %26
  %107 = call i32 @cq_template_select_f80(i32 %102, i32 %90, i32 %106)    ; IR: %97 = phi (real result): the %79 arm
  %108 = call i32 @cq_template_select_f80(i32 %100, i32 %66, i32 %107)    ; IR: %97 = phi (real result): the %58 arm
  call void @cqrt_copy_f80(i32 %108, i32 %0)    ; IR: xor real out of the result rail
  call void @cqrt_copy_f80(i32 %105, i32 %1)    ; IR: xor imaginary out of the result rail
  call void @cq_template_select_f80_unc(i32 %108, i32 %100, i32 %66, i32 %107)    ; IR: uncompute %97
  call void @cqrt_free(i32 %108)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %107, i32 %102, i32 %90, i32 %106)    ; IR: uncompute %97
  call void @cqrt_free(i32 %107)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %106, i32 %98, i32 %42, i32 %27)    ; IR: uncompute %97
  call void @cqrt_free(i32 %106)    ; IR: release the %97 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %105, i32 %100, i32 %71, i32 %104)    ; IR: uncompute %96
  call void @cqrt_free(i32 %105)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %104, i32 %102, i32 %95, i32 %103)    ; IR: uncompute %96
  call void @cqrt_free(i32 %104)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f80_unc(i32 %103, i32 %98, i32 %43, i32 %33)    ; IR: uncompute %96
  call void @cqrt_free(i32 %103)    ; IR: release the %96 rail (|0>)
  call void @cqrt_not_i1(i32 %78)    ; IR: bracket: P79 reads NOT %74
  call void @cqrt_and_i1(i32 %101, i32 %78, i32 %102)    ; IR: uncompute P79  [self-inverse]
  call void @cqrt_free(i32 %102)    ; IR: release the P79 rail (|0>)
  call void @cqrt_not_i1(i32 %78)    ; IR: bracket (close): P79 reads NOT %74
  call void @cqrt_and_i1(i32 %99, i32 %56, i32 %101)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %101)    ; IR: release the P72 rail (|0>)
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket: P58 reads NOT %54
  call void @cqrt_and_i1(i32 %99, i32 %56, i32 %100)    ; IR: uncompute P58  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P58 rail (|0>)
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket (close): P58 reads NOT %54
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P45 reads NOT %34
  call void @cqrt_not_i1(i32 %98)    ; IR: bracket: P45 reads NOT %92
  call void @cqrt_and_i1(i32 %36, i32 %98, i32 %99)    ; IR: uncompute P45  [self-inverse]
  call void @cqrt_free(i32 %99)    ; IR: release the P45 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P45 reads NOT %34
  call void @cqrt_not_i1(i32 %98)    ; IR: bracket (close): P45 reads NOT %92
  call void @cqrt_and_i1(i32 %97, i32 %40, i32 %98)    ; IR: uncompute P41  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release the P41 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P37 reads NOT %34
  call void @cqrt_and_i1(i32 %36, i32 %96, i32 %97)    ; IR: uncompute P37  [self-inverse]
  call void @cqrt_free(i32 %97)    ; IR: release the P37 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P37 reads NOT %34
  call void @cqrt_free(i32 %96)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f80_hl_unc(i32 %95, i32 %94, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %94
  call void @cqrt_free(i32 %95)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %94, i32 %93, i32 %92)    ; IR: uncompute %93  [sum]
  call void @cqrt_free(i32 %94)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %93, i32 %3, x86_fp80 %82)    ; IR: uncompute %93  [product]
  call void @cqrt_free(i32 %93)    ; IR: release the %93 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %92, i32 %2, x86_fp80 %91)    ; IR: uncompute %92
  call void @cqrt_free(i32 %92)    ; IR: release the %92 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %90, i32 %89, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %90
  call void @cqrt_free(i32 %90)    ; IR: release the %90 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %89, i32 %88, i32 %87)    ; IR: uncompute %89  [sum]
  call void @cqrt_free(i32 %89)    ; IR: release the %89 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %88, i32 %2, x86_fp80 %82)    ; IR: uncompute %89  [product]
  call void @cqrt_free(i32 %88)    ; IR: release the %89 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %87, i32 %3, x86_fp80 %86)    ; IR: uncompute %88
  call void @cqrt_free(i32 %87)    ; IR: release the %88 rail (|0>)
  call void @cqrt_or_i1(i32 %77, i32 %75, i32 %78)    ; IR: uncompute %78  [self-inverse]
  call void @cqrt_free(i32 %78)    ; IR: release the %78 rail (|0>)
  call void @cq_template_fcmp_ueq_f80_hl_unc(i32 %77, i32 %76, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %77
  call void @cqrt_free(i32 %77)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %76, i32 %3)    ; IR: uncompute %76
  call void @cqrt_free(i32 %76)    ; IR: release the %76 rail (|0>)
  call void @cqrt_or_i1(i32 %73, i32 %74, i32 %75)    ; IR: uncompute %75  [self-inverse]
  call void @cqrt_free(i32 %75)    ; IR: release the %75 rail (|0>)
  call void @cqrt_free(i32 %74)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ueq_f80_hl_unc(i32 %73, i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %74
  call void @cqrt_free(i32 %73)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %71, i32 %70, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %71
  call void @cqrt_free(i32 %71)    ; IR: release the %71 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %70, i32 %69, i32 %68)    ; IR: uncompute %70  [sum]
  call void @cqrt_free(i32 %70)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %69, i32 %62, x86_fp80 %19)    ; IR: uncompute %70  [product]
  call void @cqrt_free(i32 %69)    ; IR: release the %70 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %68, i32 %67, x86_fp80 %18)    ; IR: uncompute %69
  call void @cqrt_free(i32 %68)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fneg_f80_unc(i32 %67, i32 %58)    ; IR: uncompute %68
  call void @cqrt_free(i32 %67)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %66, i32 %65, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %66)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %65, i32 %64, i32 %63)    ; IR: uncompute %66  [sum]
  call void @cqrt_free(i32 %65)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %64, i32 %58, x86_fp80 %19)    ; IR: uncompute %66  [product]
  call void @cqrt_free(i32 %64)    ; IR: release the %66 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %63, i32 %62, x86_fp80 %18)    ; IR: uncompute %65
  call void @cqrt_free(i32 %63)    ; IR: release the %65 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %62, i32 %61, i32 %3)    ; IR: uncompute %64
  call void @cqrt_free(i32 %62)    ; IR: release the %64 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %61, i32 %60)    ; IR: uncompute %63
  call void @cqrt_free(i32 %61)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %60, i32 %59, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %60)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %59, i32 %3)    ; IR: uncompute %61
  call void @cqrt_free(i32 %59)    ; IR: release the %61 rail (|0>)
  call void @cq_template_copysign_f80_unc(i32 %58, i32 %57, i32 %2)    ; IR: uncompute %60
  call void @cqrt_free(i32 %58)    ; IR: release the %60 rail (|0>)
  call void @cq_template_uitofp_i1_to_f80_unc(i32 %57, i32 %45)    ; IR: uncompute %59
  call void @cqrt_free(i32 %57)    ; IR: release the %59 rail (|0>)
  call void @cqrt_or_i1(i32 %52, i32 %55, i32 %56)    ; IR: uncompute %57  [self-inverse]
  call void @cqrt_free(i32 %56)    ; IR: release the %57 rail (|0>)
  call void @cqrt_free(i32 %55)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %48, i32 %51, i32 %52)    ; IR: uncompute %54  [self-inverse]
  call void @cqrt_free(i32 %52)    ; IR: release the %54 rail (|0>)
  call void @cqrt_free(i32 %51)    ; IR: release the seed rail (basis state)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket: %51 reads NOT %43
  call void @cqrt_and_i1(i32 %47, i32 %45, i32 %48)    ; IR: uncompute %51  [self-inverse]
  call void @cqrt_free(i32 %48)    ; IR: release the %51 rail (|0>)
  call void @cqrt_not_i1(i32 %45)    ; IR: bracket (close): %51 reads NOT %43
  call void @cq_template_fcmp_une_f80_hl_unc(i32 %47, i32 %46, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %50
  call void @cqrt_free(i32 %47)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %46, i32 %3)    ; IR: uncompute %49
  call void @cqrt_free(i32 %46)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fcmp_oeq_f80_hl_unc(i32 %45, i32 %44, x86_fp80 0xK7FFF8000000000000000)    ; IR: uncompute %47
  call void @cqrt_free(i32 %45)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fabs_f80_unc(i32 %44, i32 %2)    ; IR: uncompute %46
  call void @cqrt_free(i32 %44)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %43, i32 %3, x86_fp80 %41)    ; IR: uncompute %44
  call void @cqrt_free(i32 %43)    ; IR: release the %44 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %42, i32 %2, x86_fp80 %41)    ; IR: uncompute %43
  call void @cqrt_free(i32 %42)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %38, i32 %39, i32 %40)    ; IR: uncompute %40  [self-inverse]
  call void @cqrt_free(i32 %40)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %39, i32 %3, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %39
  call void @cqrt_free(i32 %39)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %38, i32 %2, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %38)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %34, i32 %35, i32 %36)    ; IR: uncompute %34  [self-inverse]
  call void @cqrt_free(i32 %36)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %35, i32 %33, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %33
  call void @cqrt_free(i32 %35)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fcmp_ord_f80_hl_unc(i32 %34, i32 %27, x86_fp80 0xK00000000000000000000)    ; IR: uncompute %32
  call void @cqrt_free(i32 %34)    ; IR: release the %32 rail (|0>)
  call fastcc void @__cq_q_scalbnl_10_unc(i32 %33, i32 %32, i32 %26)    ; IR: uncompute the result rail(s) of %31
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f80_hl_unc(i32 %32, i32 %31, x86_fp80 %21)    ; IR: uncompute %30
  call void @cqrt_free(i32 %32)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %31, i32 %30, i32 %29)    ; IR: uncompute %29  [sum]
  call void @cqrt_free(i32 %31)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %30, i32 %3, x86_fp80 %19)    ; IR: uncompute %29  [product]
  call void @cqrt_free(i32 %30)    ; IR: release the %29 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %29, i32 %2, x86_fp80 %28)    ; IR: uncompute %28
  call void @cqrt_free(i32 %29)    ; IR: release the %28 rail (|0>)
  call fastcc void @__cq_q_scalbnl_10_unc(i32 %27, i32 %25, i32 %26)    ; IR: uncompute the result rail(s) of %26
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f80_hl_unc(i32 %25, i32 %24, x86_fp80 %21)    ; IR: uncompute %24
  call void @cqrt_free(i32 %25)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fadd_f80_unc(i32 %24, i32 %23, i32 %22)    ; IR: uncompute %23  [sum]
  call void @cqrt_free(i32 %24)    ; IR: release the %23 rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %23, i32 %2, x86_fp80 %19)    ; IR: uncompute %23  [product]
  call void @cqrt_free(i32 %23)    ; IR: release the %23 product rail (|0>)
  call void @cq_template_fmul_f80_hl_unc(i32 %22, i32 %3, x86_fp80 %18)    ; IR: uncompute %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

define internal fastcc i32 @__cq_q_scalbnl_10(i32 %0, i32 %1) {
  %3 = icmp sgt i32 %1, 16383    ; IR: %3 = icmp sgt n, 16383  (classical)
  br i1 %3, label %4, label %12    ; IR: br i1 %3, label %4, label %12  (classical branch, rule 8)
4:
  %5 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 0xK7FFE8000000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %6 = add nsw i32 %1, -16383    ; IR: %6 = add nsw n, -16383  (classical)
  %7 = icmp sgt i32 %1, 32766    ; IR: %7 = icmp sgt n, 32766  (classical)
  br i1 %7, label %8, label %22    ; IR: br i1 %7, label %8, label %22  (classical branch)
8:
  %9 = call i32 @cq_template_fmul_f80_hl(i32 %5, x86_fp80 0xK7FFE8000000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %10 = tail call i32 @llvm.smin.i32(i32 %1, i32 49149)    ; IR: %10 = smin(n, 49149)  (classical)
  %11 = add nsw i32 %10, -32766    ; IR: %11 = add nsw %10, -32766  (classical)
  br label %22    ; IR: br label %22
12:
  %13 = icmp slt i32 %1, -16382    ; IR: %13 = icmp slt n, -16382  (classical)
  br i1 %13, label %14, label %22    ; IR: br i1 %13, label %14, label %22  (classical branch)
14:
  %15 = call i32 @cq_template_fmul_f80_hl(i32 %0, x86_fp80 0xK00728000000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %16 = add nuw nsw i32 %1, 16269    ; IR: %16 = add nuw nsw n, 16269  (classical)
  %17 = icmp slt i32 %1, -32651    ; IR: %17 = icmp slt n, -32651  (classical)
  br i1 %17, label %18, label %22    ; IR: br i1 %17, label %18, label %22  (classical branch)
18:
  %19 = call i32 @cq_template_fmul_f80_hl(i32 %15, x86_fp80 0xK00728000000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %20 = tail call i32 @llvm.smax.i32(i32 %1, i32 -48920)    ; IR: %20 = smax(n, -48920)  (classical)
  %21 = add nsw i32 %20, 32538    ; IR: %21 = add nsw %20, 32538  (classical)
  br label %22    ; IR: br label %22
22:
  %23 = phi i32 [ %11, %8 ], [ %6, %4 ], [ %21, %18 ], [ %16, %14 ], [ %1, %12 ]    ; IR: %23 = phi i32 (n after the clamps)  (classical)
  %24 = phi i32 [ %9, %8 ], [ %5, %4 ], [ %19, %18 ], [ %15, %14 ], [ %0, %12 ]    ; IR: %24 = phi (y after the scalings): a classical phi of handles
  %25 = phi i32 [ %5, %8 ], [ %5, %4 ], [ poison, %18 ], [ poison, %14 ], [ poison, %12 ]    ; IR: %5 kept for the mirror (defined on the %4 paths only)
  %26 = phi i32 [ %9, %8 ], [ poison, %4 ], [ poison, %18 ], [ poison, %14 ], [ poison, %12 ]    ; IR: %9 kept for the mirror (defined on the %8 path only)
  %27 = phi i32 [ poison, %8 ], [ poison, %4 ], [ %15, %18 ], [ %15, %14 ], [ poison, %12 ]    ; IR: %15 kept for the mirror (defined on the %14 paths only)
  %28 = phi i32 [ poison, %8 ], [ poison, %4 ], [ %19, %18 ], [ poison, %14 ], [ poison, %12 ]    ; IR: %19 kept for the mirror (defined on the %18 path only)
  %29 = trunc i32 %23 to i16    ; IR: %25 = trunc %23 to i16  (u.i.se)  (classical)
  %30 = add i16 %29, 16383    ; IR: %26 = add i16 %25, 16383  (classical)
  %31 = zext i16 %30 to i80    ; IR: %27 = zext i16 %26 to i80  (classical)
  %32 = shl nuw i80 %31, 64    ; IR: %28 = shl nuw i80 %27, 64  (se at bit 64)  (classical)
  %33 = or disjoint i80 %32, 9223372036854775808    ; IR: %29 = or disjoint i80 %28, 1 << 63  (the explicit integer bit of 1.0)  (classical)
  %34 = bitcast i80 %33 to x86_fp80    ; IR: %30 = bitcast i80 %29 to x86_fp80  (u.f = 2^n)  (classical)
  %35 = call i32 @cq_template_fmul_f80_hl(i32 %24, x86_fp80 %34)    ; IR: %31 = fmul %24, u.f  (y * 2^n)
  %36 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: ret  [result rail: scalbnl(x, n)]
  call void @cqrt_copy_f80(i32 %35, i32 %36)    ; IR: copy scalbnl(x, n) out
  call void @cq_template_fmul_f80_hl_unc(i32 %35, i32 %24, x86_fp80 %34)    ; IR: uncompute %31
  call void @cqrt_free(i32 %35)    ; IR: release the %31 rail (|0>)
  br i1 %3, label %37, label %41    ; IR: mirror: the same classical branch on %3
37:
  %38 = icmp sgt i32 %1, 32766    ; IR: %7 recomputed for the mirror  (classical)
  br i1 %38, label %39, label %40    ; IR: mirror: classical branch on %7
39:
  call void @cq_template_fmul_f80_hl_unc(i32 %26, i32 %25, x86_fp80 0xK7FFE8000000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %26)    ; IR: release the %9 rail (|0>)
  br label %40    ; IR: mirror: join (no gate)
40:
  call void @cq_template_fmul_f80_hl_unc(i32 %25, i32 %0, x86_fp80 0xK7FFE8000000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %25)    ; IR: release the %5 rail (|0>)
  br label %47    ; IR: mirror: join (no gate)
41:
  %42 = icmp slt i32 %1, -16382    ; IR: %13 recomputed for the mirror  (classical)
  br i1 %42, label %43, label %47    ; IR: mirror: classical branch on %13
43:
  %44 = icmp slt i32 %1, -32651    ; IR: %17 recomputed for the mirror  (classical)
  br i1 %44, label %45, label %46    ; IR: mirror: classical branch on %17
45:
  call void @cq_template_fmul_f80_hl_unc(i32 %28, i32 %27, x86_fp80 0xK00728000000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %28)    ; IR: release the %19 rail (|0>)
  br label %46    ; IR: mirror: join (no gate)
46:
  call void @cq_template_fmul_f80_hl_unc(i32 %27, i32 %0, x86_fp80 0xK00728000000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %27)    ; IR: release the %15 rail (|0>)
  br label %47    ; IR: mirror: join (no gate)
47:
  ret i32 %36    ; IR: ret  (the result handle)
}

define internal fastcc void @__cq_q_scalbnl_10_unc(i32 %0, i32 %1, i32 %2) {
  %4 = icmp sgt i32 %2, 16383    ; IR: %3 = icmp sgt n, 16383  (classical)
  br i1 %4, label %5, label %13    ; IR: br i1 %3, label %4, label %12  (classical branch, rule 8)
5:
  %6 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 0xK7FFE8000000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %7 = add nsw i32 %2, -16383    ; IR: %6 = add nsw n, -16383  (classical)
  %8 = icmp sgt i32 %2, 32766    ; IR: %7 = icmp sgt n, 32766  (classical)
  br i1 %8, label %9, label %23    ; IR: br i1 %7, label %8, label %22  (classical branch)
9:
  %10 = call i32 @cq_template_fmul_f80_hl(i32 %6, x86_fp80 0xK7FFE8000000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %11 = tail call i32 @llvm.smin.i32(i32 %2, i32 49149)    ; IR: %10 = smin(n, 49149)  (classical)
  %12 = add nsw i32 %11, -32766    ; IR: %11 = add nsw %10, -32766  (classical)
  br label %23    ; IR: br label %22
13:
  %14 = icmp slt i32 %2, -16382    ; IR: %13 = icmp slt n, -16382  (classical)
  br i1 %14, label %15, label %23    ; IR: br i1 %13, label %14, label %22  (classical branch)
15:
  %16 = call i32 @cq_template_fmul_f80_hl(i32 %1, x86_fp80 0xK00728000000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %17 = add nuw nsw i32 %2, 16269    ; IR: %16 = add nuw nsw n, 16269  (classical)
  %18 = icmp slt i32 %2, -32651    ; IR: %17 = icmp slt n, -32651  (classical)
  br i1 %18, label %19, label %23    ; IR: br i1 %17, label %18, label %22  (classical branch)
19:
  %20 = call i32 @cq_template_fmul_f80_hl(i32 %16, x86_fp80 0xK00728000000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %21 = tail call i32 @llvm.smax.i32(i32 %2, i32 -48920)    ; IR: %20 = smax(n, -48920)  (classical)
  %22 = add nsw i32 %21, 32538    ; IR: %21 = add nsw %20, 32538  (classical)
  br label %23    ; IR: br label %22
23:
  %24 = phi i32 [ %12, %9 ], [ %7, %5 ], [ %22, %19 ], [ %17, %15 ], [ %2, %13 ]    ; IR: %23 = phi i32 (n after the clamps)  (classical)
  %25 = phi i32 [ %10, %9 ], [ %6, %5 ], [ %20, %19 ], [ %16, %15 ], [ %1, %13 ]    ; IR: %24 = phi (y after the scalings): a classical phi of handles
  %26 = phi i32 [ %6, %9 ], [ %6, %5 ], [ poison, %19 ], [ poison, %15 ], [ poison, %13 ]    ; IR: %5 kept for the mirror (defined on the %4 paths only)
  %27 = phi i32 [ %10, %9 ], [ poison, %5 ], [ poison, %19 ], [ poison, %15 ], [ poison, %13 ]    ; IR: %9 kept for the mirror (defined on the %8 path only)
  %28 = phi i32 [ poison, %9 ], [ poison, %5 ], [ %16, %19 ], [ %16, %15 ], [ poison, %13 ]    ; IR: %15 kept for the mirror (defined on the %14 paths only)
  %29 = phi i32 [ poison, %9 ], [ poison, %5 ], [ %20, %19 ], [ poison, %15 ], [ poison, %13 ]    ; IR: %19 kept for the mirror (defined on the %18 path only)
  %30 = trunc i32 %24 to i16    ; IR: %25 = trunc %23 to i16  (u.i.se)  (classical)
  %31 = add i16 %30, 16383    ; IR: %26 = add i16 %25, 16383  (classical)
  %32 = zext i16 %31 to i80    ; IR: %27 = zext i16 %26 to i80  (classical)
  %33 = shl nuw i80 %32, 64    ; IR: %28 = shl nuw i80 %27, 64  (se at bit 64)  (classical)
  %34 = or disjoint i80 %33, 9223372036854775808    ; IR: %29 = or disjoint i80 %28, 1 << 63  (the explicit integer bit of 1.0)  (classical)
  %35 = bitcast i80 %34 to x86_fp80    ; IR: %30 = bitcast i80 %29 to x86_fp80  (u.f = 2^n)  (classical)
  %36 = call i32 @cq_template_fmul_f80_hl(i32 %25, x86_fp80 %35)    ; IR: %31 = fmul %24, u.f  (y * 2^n)
  call void @cqrt_copy_f80(i32 %36, i32 %0)    ; IR: xor scalbnl(x, n) out of the result rail
  call void @cq_template_fmul_f80_hl_unc(i32 %36, i32 %25, x86_fp80 %35)    ; IR: uncompute %31
  call void @cqrt_free(i32 %36)    ; IR: release the %31 rail (|0>)
  br i1 %4, label %37, label %41    ; IR: mirror: the same classical branch on %3
37:
  %38 = icmp sgt i32 %2, 32766    ; IR: %7 recomputed for the mirror  (classical)
  br i1 %38, label %39, label %40    ; IR: mirror: classical branch on %7
39:
  call void @cq_template_fmul_f80_hl_unc(i32 %27, i32 %26, x86_fp80 0xK7FFE8000000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %27)    ; IR: release the %9 rail (|0>)
  br label %40    ; IR: mirror: join (no gate)
40:
  call void @cq_template_fmul_f80_hl_unc(i32 %26, i32 %1, x86_fp80 0xK7FFE8000000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %26)    ; IR: release the %5 rail (|0>)
  br label %47    ; IR: mirror: join (no gate)
41:
  %42 = icmp slt i32 %2, -16382    ; IR: %13 recomputed for the mirror  (classical)
  br i1 %42, label %43, label %47    ; IR: mirror: classical branch on %13
43:
  %44 = icmp slt i32 %2, -32651    ; IR: %17 recomputed for the mirror  (classical)
  br i1 %44, label %45, label %46    ; IR: mirror: classical branch on %17
45:
  call void @cq_template_fmul_f80_hl_unc(i32 %29, i32 %28, x86_fp80 0xK00728000000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %29)    ; IR: release the %19 rail (|0>)
  br label %46    ; IR: mirror: join (no gate)
46:
  call void @cq_template_fmul_f80_hl_unc(i32 %28, i32 %1, x86_fp80 0xK00728000000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %28)    ; IR: release the %15 rail (|0>)
  br label %47    ; IR: mirror: join (no gate)
47:
  ret void    ; IR: ret  (the twin returns nothing)
}

declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_ry_f80(i32, double)
declare i32 @cq_template_fadd_f80_hl(i32, x86_fp80)
declare void @cq_template_fadd_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @cq_template_fmul_f80_hl(i32, x86_fp80)
declare void @cq_template_fmul_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @cq_template_fsub_f80_hl(i32, x86_fp80)
declare void @cq_template_fsub_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @cq_template_fcmp_uno_f80_hl(i32, x86_fp80)
declare void @cq_template_fcmp_uno_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_select_f80(i32, i32, i32)
declare void @cq_template_select_f80_unc(i32, i32, i32, i32)
declare i32 @cq_template_fadd_f80(i32, i32)
declare void @cq_template_fadd_f80_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare x86_fp80 @cqrt_measure_f80(i32)
declare i32 @cq_template_fcmp_ord_f80_hl(i32, x86_fp80)
declare void @cq_template_fcmp_ord_f80_hl_unc(i32, i32, x86_fp80)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_fabs_f80(i32)
declare void @cq_template_fabs_f80_unc(i32, i32)
declare i32 @cq_template_fcmp_oeq_f80_hl(i32, x86_fp80)
declare void @cq_template_fcmp_oeq_f80_hl_unc(i32, i32, x86_fp80)
declare x86_fp80 @llvm.fabs.f80(x86_fp80)
declare i32 @cq_template_uitofp_i1_to_f80(i32)
declare void @cq_template_uitofp_i1_to_f80_unc(i32, i32)
declare i32 @cq_template_copysign_f80(i32, i32)
declare void @cq_template_copysign_f80_unc(i32, i32, i32)
declare x86_fp80 @llvm.copysign.f80(x86_fp80, x86_fp80)
declare i32 @cq_template_select_f80_ll(i32, x86_fp80, x86_fp80)
declare void @cq_template_select_f80_ll_unc(i32, i32, x86_fp80, x86_fp80)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_copysign_f80_lh(x86_fp80, i32)
declare void @cq_template_copysign_f80_lh_unc(i32, x86_fp80, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_une_f80_hl(i32, x86_fp80)
declare void @cq_template_fcmp_une_f80_hl_unc(i32, i32, x86_fp80)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_fneg_f80(i32)
declare void @cq_template_fneg_f80_unc(i32, i32)
declare i32 @cq_template_fmul_f80(i32, i32)
declare void @cq_template_fmul_f80_unc(i32, i32, i32)
declare void @cqrt_copy_f80(i32, i32)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80, x86_fp80)
declare x86_fp80 @logbl(x86_fp80)
declare x86_fp80 @scalbnl(x86_fp80, i32)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80)
declare i32 @cq_template_fdiv_f80_hl(i32, x86_fp80)
declare void @cq_template_fdiv_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @cq_template_fcmp_ueq_f80_hl(i32, x86_fp80)
declare void @cq_template_fcmp_ueq_f80_hl_unc(i32, i32, x86_fp80)
declare i32 @llvm.smin.i32(i32, i32)
declare i32 @llvm.smax.i32(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
