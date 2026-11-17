; HAND-WRITTEN. Rules: 26, 18, 8, 9, 4, 5.
; Checked: creal(q) + cimag(q), the returned double (the fadd rail %28 -> %29).
; Clean: every rail but the register re: the inline product chain (%8, %11, %13, %15, %16), the two fcmp uno flags (%17, %18)
; and their conjunction (%19), the __muldc3 clone's two result rails (%21, %22) and the two merge selects (%23, %24), the
; twice clone's two result rails (%26, %27); inside each clone its whole chain, every block flag and every seed rail.
; Kept: re (%6, the rotated register) and the sum (%28, measured).
; Rotations: (Ry, re, th, 1); nothing else (the clones have no rotation; every branch is a value arm).
; A `double complex` is two doubles: the parameters arrive as separate scalars, locals are two SSA values, and a complex
; return is the aggregate { double, double } of example 64. `z * w` is inlined by clang as four products and two sums; only
; when BOTH parts are NaN (a quantum condition: the two `fcmp uno` flags) does it call __muldc3, the compiler-rt body
; reproduced in the .c file. That call becomes a quantum clone (mask 1000: the real part of z is the only quantum argument)
; called unconditionally; its two result handles are merged with the fast-path values by two selects on the conjunction
; flag (06 + 04). Inside the clone every branch on a quantum condition is flattened: block merges become selects on the
; local branch flag, the three-way phis in %85/%99 select on the conjunction of the flags along the one differing path,
; and the `!recalc` edge needs a NOT bracket. Every block predicate is a branch flag (rule 8): a conjunction is
; cqrt_and_i1 and a disjunction cqrt_or_i1 into a fresh |0> rail, re-applied to uncompute; a classical disjunct (isinf(b),
; isinf(bd), isinf(bc), classical because b, c, d are classical) is lifted to a seed rail cqrt_alloc_i1(c) (rule 7)
; that is freed after the flag. The `select` templates read those flags as their condition handle (rule 9). Conditions that
; depend only on b, c, d stay classical IR. The clone copies both parts out, uncomputes its whole chain, and its _unc twin
; recomputes it to zero the two result rails (64). Also shown: `twice`, a clone taking two quantum scalars and returning an
; aggregate.
; The recalculation's two llvm.fmuladd.f64 calls (%94, %97) are UNFUSED (§2, cf. 14): an fmul into a fresh product rail,
; then an fadd of the product and the addend; the product is uncomputed right after the sum it fed (rule 5).
source_filename = "complex_double.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @complex_double(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = fmul double %2, 0.000000e+00    ; IR: %7 = fmul double %2, 0.0  (classical: im * 0 from im * I)
  %8 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %7)    ; IR: %8 = fadd double %7, %6  (real part of z; commutative, quantum operand first)
  %9 = fmul double %4, 0.000000e+00    ; IR: %9  (classical)
  %10 = fadd double %9, %3    ; IR: %10  (classical: real part of w)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %10)    ; IR: %11 = fmul double %10, %8
  %12 = fmul double %2, %4    ; IR: %12  (classical)
  %13 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %4)    ; IR: %13 = fmul double %8, %4
  %14 = fmul double %10, %2    ; IR: %14  (classical)
  %15 = call i32 @cq_template_fsub_f64_hl(i32 %11, double %12)    ; IR: %15 = fsub double %11, %12  (fast-path real part)
  %16 = call i32 @cq_template_fadd_f64_hl(i32 %13, double %14)    ; IR: %16 = fadd double %14, %13  (fast-path imaginary part)
  %17 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %15, double 0.000000e+00)    ; IR: %17 = fcmp uno %15, 0.0  [predicate of block %18]
  %18 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %16, double 0.000000e+00)    ; IR: %19 = fcmp uno %16, 0.0
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %20 = %17 & %19
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: br i1 %19 inside block %18: predicate = %17 & %19
  %20 = call fastcc { i32, i32 } @__cq_q___muldc3_1000(i32 %8, double %2, double %10, double %4)    ; IR: block %20: %21 = call @__muldc3(%8, %2, %10, %4), quantum clone (arg 0 quantum), called unconditionally
  %21 = extractvalue { i32, i32 } %20, 0    ; IR: %22 = extractvalue %21, 0  (handle; classical)
  %22 = extractvalue { i32, i32 } %20, 1    ; IR: %23 = extractvalue %21, 1  (handle; classical)
  %23 = call i32 @cq_template_select_f64(i32 %19, i32 %21, i32 %15)    ; IR: %25 = phi [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]  (merge on the %20 predicate)
  %24 = call i32 @cq_template_select_f64(i32 %19, i32 %22, i32 %16)    ; IR: %26 = phi [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]
  %25 = call fastcc { i32, i32 } @__cq_q_twice_11(i32 %23, i32 %24)    ; IR: %27 = call @twice(%25, %26), quantum clone (both quantum)
  %26 = extractvalue { i32, i32 } %25, 0    ; IR: %28 = extractvalue %27, 0  (handle)
  %27 = extractvalue { i32, i32 } %25, 1    ; IR: %29 = extractvalue %27, 1  (handle)
  %28 = call i32 @cq_template_fadd_f64(i32 %26, i32 %27)    ; IR: %30 = fadd double %28, %29  [result rail]
  call fastcc void @__cq_q_twice_11_unc(i32 %26, i32 %27, i32 %23, i32 %24)    ; IR: uncompute %28 and %29
  call void @cqrt_free(i32 %26)    ; IR: release the %28 rail (|0>)
  call void @cqrt_free(i32 %27)    ; IR: release the %29 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %24, i32 %19, i32 %22, i32 %16)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %19, i32 %21, i32 %15)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call fastcc void @__cq_q___muldc3_1000_unc(i32 %21, i32 %22, i32 %8, double %2, double %10, double %4)    ; IR: uncompute %22 and %23
  call void @cqrt_free(i32 %21)    ; IR: release the %22 rail (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the %23 rail (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: uncompute the %20 predicate
  call void @cqrt_free(i32 %19)    ; IR: release the %20 predicate (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %18, i32 %16, double 0.000000e+00)    ; IR: uncompute %19
  call void @cqrt_free(i32 %18)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %17, i32 %15, double 0.000000e+00)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %16, i32 %13, double %14)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fsub_f64_hl_unc(i32 %15, i32 %11, double %12)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %13, i32 %8, double %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %8, double %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %8, i32 %6, double %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %29 = call double @cqrt_measure_f64(i32 %28)    ; IR: %31 = cq_measure_f64(%30)
  ret double %29    ; IR: ret double %31
}

define internal fastcc { i32, i32 } @__cq_q_twice_11(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_fadd_f64(i32 %0, i32 %0)    ; IR: %3 = fadd double %0, %0  (the same rail in both slots)
  %4 = call i32 @cq_template_fadd_f64(i32 %1, i32 %1)    ; IR: %4 = fadd double %1, %1
  %5 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %5 = insertvalue poison, %3, 0  [result rail: real]
  call void @cqrt_copy_f64(i32 %3, i32 %5)    ; IR: copy the real part out
  %6 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %6 = insertvalue %5, %4, 1  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %4, i32 %6)    ; IR: copy the imaginary part out
  call void @cq_template_fadd_f64_unc(i32 %4, i32 %1, i32 %1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %3, i32 %0, i32 %0)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  %7 = insertvalue { i32, i32 } poison, i32 %5, 0    ; IR: %5  (the aggregate carries handles)
  %8 = insertvalue { i32, i32 } %7, i32 %6, 1    ; IR: %6
  ret { i32, i32 } %8    ; IR: ret { double, double } %6
}

define internal fastcc void @__cq_q_twice_11_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_fadd_f64(i32 %2, i32 %2)    ; IR: recompute %3
  %6 = call i32 @cq_template_fadd_f64(i32 %3, i32 %3)    ; IR: recompute %4
  call void @cqrt_copy_f64(i32 %5, i32 %0)    ; IR: xor the real part out of the result rail
  call void @cqrt_copy_f64(i32 %6, i32 %1)    ; IR: xor the imaginary part out of the result rail
  call void @cq_template_fadd_f64_unc(i32 %6, i32 %3, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %5, i32 %2, i32 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  ret void
}

define internal fastcc { i32, i32 } @__cq_q___muldc3_1000(i32 %0, double %1, double %2, double %3) {
  %5 = fmul double %1, %3    ; IR: %6 = fmul double %1, %3  (classical: b*d)
  %6 = fmul double %1, %2    ; IR: %8 = fmul double %1, %2  (classical: b*c)
  %7 = tail call double @llvm.fabs.f64(double %1)    ; IR: %17  (classical)
  %8 = fcmp oeq double %7, 0x7FF0000000000000    ; IR: %18 = isinf(b)  (classical)
  %9 = uitofp i1 %8 to double    ; IR: %23  (classical)
  %10 = tail call double @llvm.copysign.f64(double %9, double %1)    ; IR: %24  (classical)
  %11 = fcmp uno double %2, 0.000000e+00    ; IR: %25 = isnan(c)  (classical)
  %12 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %2)    ; IR: %26  (classical)
  %13 = select i1 %11, double %12, double %2    ; IR: %27  (classical)
  %14 = fcmp uno double %3, 0.000000e+00    ; IR: %28 = isnan(d)  (classical)
  %15 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %3)    ; IR: %29  (classical)
  %16 = select i1 %14, double %15, double %3    ; IR: %30  (classical)
  %17 = tail call double @llvm.fabs.f64(double %5)    ; IR: %63  (classical)
  %18 = fcmp oeq double %17, 0x7FF0000000000000    ; IR: %64 = isinf(bd)  (classical)
  %19 = tail call double @llvm.fabs.f64(double %6)    ; IR: %69  (classical)
  %20 = fcmp oeq double %19, 0x7FF0000000000000    ; IR: %70 = isinf(bc)  (classical)
  %21 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %2)    ; IR: %5 = fmul double %0, %2  (a*c)
  %22 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %3)    ; IR: %7 = fmul double %0, %3  (a*d)
  %23 = call i32 @cq_template_fsub_f64_hl(i32 %21, double %5)    ; IR: %9 = fsub double %5, %6  (real part of the fast product)
  %24 = call i32 @cq_template_fadd_f64_hl(i32 %22, double %6)    ; IR: %10 = fadd double %8, %7  (imaginary part; commutative, quantum operand first)
  %25 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %23, double 0.000000e+00)    ; IR: %11 = fcmp uno %9, 0.0  (isnan)
  %26 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %24, double 0.000000e+00)    ; IR: %12 = fcmp uno %10, 0.0
  %27 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %25, i32 %26, i32 %27)    ; IR: %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]
  %28 = call i32 @cq_template_fabs_f64(i32 %0)    ; IR: %15 = fabs(a)  (block %14)
  %29 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %28, double 0x7FF0000000000000)    ; IR: %16 = isinf(a)
  %30 = call i32 @cqrt_alloc_i1(i1 %8)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]  [the classical disjunct %8 as a seed rail, rule 7]
  %31 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %29, i32 %30, i32 %31)    ; IR: %19 = or i1 %16, %18  [predicate of block %20 within %14]
  %32 = call i32 @cq_template_uitofp_i1_to_f64(i32 %29)    ; IR: %21 = uitofp i1 %16  (block %20)
  %33 = call i32 @cq_template_copysign_f64(i32 %32, i32 %0)    ; IR: %22 = copysign(%21, a)
  %34 = call i32 @cq_template_select_f64_ll(i32 %31, double %16, double %3)    ; IR: %32 = phi [ %30, %20 ], [ %3, %14 ]  (merge of block %20 on its predicate %19)
  %35 = call i32 @cq_template_select_f64_ll(i32 %31, double %13, double %2)    ; IR: %33 = phi [ %27, %20 ], [ %2, %14 ]
  %36 = call i32 @cq_template_select_f64_ll(i32 %31, double %10, double %1)    ; IR: %34 = phi [ %24, %20 ], [ %1, %14 ]
  %37 = call i32 @cq_template_select_f64(i32 %31, i32 %33, i32 %0)    ; IR: %35 = phi [ %22, %20 ], [ %0, %14 ]
  %38 = call i32 @cq_template_select_i32_ll(i32 %31, i32 1, i32 0)    ; IR: %36 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %39 = call i32 @cq_template_fabs_f64(i32 %35)    ; IR: %37 = fabs(%33)  (block %31)
  %40 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %39, double 0x7FF0000000000000)    ; IR: %38 = isinf(%33)
  %41 = call i32 @cq_template_fabs_f64(i32 %34)    ; IR: %39 = fabs(%32)
  %42 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %41, double 0x7FF0000000000000)    ; IR: %40 = isinf(%32)
  %43 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %42, i32 %40, i32 %43)    ; IR: %41 = or i1 %40, %38  [predicate of block %42]
  %44 = call i32 @cq_template_uitofp_i1_to_f64(i32 %40)    ; IR: %43  (block %42)
  %45 = call i32 @cq_template_copysign_f64(i32 %44, i32 %35)    ; IR: %44 = copysign(%43, %33)
  %46 = call i32 @cq_template_uitofp_i1_to_f64(i32 %42)    ; IR: %45
  %47 = call i32 @cq_template_copysign_f64(i32 %46, i32 %34)    ; IR: %46 = copysign(%45, %32)
  %48 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %37, double 0.000000e+00)    ; IR: %47 = isnan(%35)
  %49 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %37)    ; IR: %48 = copysign(0, %35)
  %50 = call i32 @cq_template_select_f64(i32 %48, i32 %49, i32 %37)    ; IR: %49 = select %47, %48, %35
  %51 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %36, double 0.000000e+00)    ; IR: %50 = isnan(%34)
  %52 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %36)    ; IR: %51 = copysign(0, %34)
  %53 = call i32 @cq_template_select_f64(i32 %51, i32 %52, i32 %36)    ; IR: %52 = select %50, %51, %34
  %54 = call i32 @cq_template_select_f64(i32 %43, i32 %47, i32 %34)    ; IR: %54 = phi [ %46, %42 ], [ %32, %31 ]  (merge of block %42 on %41)
  %55 = call i32 @cq_template_select_f64(i32 %43, i32 %45, i32 %35)    ; IR: %55 = phi [ %44, %42 ], [ %33, %31 ]
  %56 = call i32 @cq_template_select_f64(i32 %43, i32 %53, i32 %36)    ; IR: %56 = phi [ %52, %42 ], [ %34, %31 ]
  %57 = call i32 @cq_template_select_f64(i32 %43, i32 %50, i32 %37)    ; IR: %57 = phi [ %49, %42 ], [ %35, %31 ]
  %58 = call i32 @cq_template_select_i32_lh(i32 %43, i32 1, i32 %38)    ; IR: %58 = phi [ 1, %42 ], [ %36, %31 ]  (__recalc)
  %59 = call i32 @cq_template_icmp_eq_i32_hl(i32 %58, i32 0)    ; IR: %59 = icmp eq %58, 0  [predicate of block %60: !__recalc]
  %60 = call i32 @cq_template_fabs_f64(i32 %21)    ; IR: %61 = fabs(%5)  (block %60)
  %61 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %60, double 0x7FF0000000000000)    ; IR: %62 = isinf(ac)
  %62 = call i32 @cqrt_alloc_i1(i1 %18)    ; IR: %65 = or i1 %62, %64  [the classical disjunct %18 as a seed rail, rule 7]
  %63 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %61, i32 %62, i32 %63)    ; IR: %65 = or i1 %62, %64
  %64 = call i32 @cq_template_fabs_f64(i32 %22)    ; IR: %66 = fabs(%7)
  %65 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %64, double 0x7FF0000000000000)    ; IR: %67 = isinf(ad)
  %66 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %65, i32 %63, i32 %66)    ; IR: %68 = or i1 %67, %65
  %67 = call i32 @cqrt_alloc_i1(i1 %20)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]  [the classical disjunct %20 as a seed rail, rule 7]
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %66, i32 %67, i32 %68)    ; IR: %71 = or i1 %70, %68  [predicate of block %72 within %60]
  %69 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %57, double 0.000000e+00)    ; IR: %73 = isnan(%57)  (block %72)
  %70 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %57)    ; IR: %74
  %71 = call i32 @cq_template_select_f64(i32 %69, i32 %70, i32 %57)    ; IR: %75
  %72 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %56, double 0.000000e+00)    ; IR: %76 = isnan(%56)
  %73 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %56)    ; IR: %77
  %74 = call i32 @cq_template_select_f64(i32 %72, i32 %73, i32 %56)    ; IR: %78
  %75 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %55, double 0.000000e+00)    ; IR: %79 = isnan(%55)
  %76 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %55)    ; IR: %80
  %77 = call i32 @cq_template_select_f64(i32 %75, i32 %76, i32 %55)    ; IR: %81
  %78 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %54, double 0.000000e+00)    ; IR: %82 = isnan(%54)
  %79 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %54)    ; IR: %83
  %80 = call i32 @cq_template_select_f64(i32 %78, i32 %79, i32 %54)    ; IR: %84
  %81 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %72 relative to %53: %59 & %71  [fresh flag rail]
  call void @cqrt_and_i1(i32 %59, i32 %68, i32 %81)    ; IR: path predicate of block %72 relative to %53: %59 & %71
  %82 = call i32 @cq_template_select_f64(i32 %81, i32 %80, i32 %54)    ; IR: %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (only the %72 path differs)
  %83 = call i32 @cq_template_select_f64(i32 %81, i32 %77, i32 %55)    ; IR: %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  %84 = call i32 @cq_template_select_f64(i32 %81, i32 %74, i32 %56)    ; IR: %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  %85 = call i32 @cq_template_select_f64(i32 %81, i32 %71, i32 %57)    ; IR: %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket: %90 is true only on the %60 -> %85 edge, i.e. %59 & NOT %71
  %86 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  = %59 & !%71  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %59, i32 %68, i32 %86)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  = %59 & !%71  [no recalculation]
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket
  %87 = call i32 @cq_template_fneg_f64(i32 %84)    ; IR: %92 = fneg %88  (block %91)
  %88 = call i32 @cq_template_fmul_f64(i32 %82, i32 %87)    ; IR: %93 = fmul %86, %92
  %89 = call i32 @cq_template_fmul_f64(i32 %85, i32 %83)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused product]
  %90 = call i32 @cq_template_fadd_f64(i32 %89, i32 %88)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %91 = call i32 @cq_template_fmul_f64_hl(i32 %90, double 0x7FF0000000000000)    ; IR: %95 = fmul %94, inf
  %92 = call i32 @cq_template_fmul_f64(i32 %83, i32 %84)    ; IR: %96 = fmul %87, %88
  %93 = call i32 @cq_template_fmul_f64(i32 %85, i32 %82)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused product]
  %94 = call i32 @cq_template_fadd_f64(i32 %93, i32 %92)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %95 = call i32 @cq_template_fmul_f64_hl(i32 %94, double 0x7FF0000000000000)    ; IR: %98 = fmul %97, inf
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket: block %91 runs iff %13 & NOT %90
  %96 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %91: %13 & !%90  [fresh flag rail]
  call void @cqrt_and_i1(i32 %27, i32 %86, i32 %96)    ; IR: path predicate of block %91: %13 & !%90
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket
  %97 = call i32 @cq_template_select_f64(i32 %96, i32 %91, i32 %23)    ; IR: %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  %98 = call i32 @cq_template_select_f64(i32 %96, i32 %95, i32 %24)    ; IR: %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  %99 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %102 = insertvalue poison, %101, 0  [result rail: real]
  call void @cqrt_copy_f64(i32 %97, i32 %99)    ; IR: copy the real part out
  %100 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %103 = insertvalue %102, %100, 1  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %98, i32 %100)    ; IR: copy the imaginary part out
  call void @cq_template_select_f64_unc(i32 %98, i32 %96, i32 %95, i32 %24)    ; IR: uncompute %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]
  call void @cqrt_free(i32 %98)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %97, i32 %96, i32 %91, i32 %23)    ; IR: uncompute %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]
  call void @cqrt_free(i32 %97)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket
  call void @cqrt_and_i1(i32 %27, i32 %86, i32 %96)    ; IR: uncompute path predicate of block %91: %13 & !%90  [self-inverse]
  call void @cqrt_free(i32 %96)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket: block %91 runs iff %13 & NOT %90
  call void @cq_template_fmul_f64_hl_unc(i32 %95, i32 %94, double 0x7FF0000000000000)    ; IR: uncompute %98 = fmul %97, inf
  call void @cqrt_free(i32 %95)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %94, i32 %93, i32 %92)    ; IR: uncompute %97 = fmuladd(%89, %86, %96)  [sum]
  call void @cqrt_free(i32 %94)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %93, i32 %85, i32 %82)    ; IR: uncompute %97 = fmuladd(%89, %86, %96)  [product]
  call void @cqrt_free(i32 %93)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %92, i32 %83, i32 %84)    ; IR: uncompute %96 = fmul %87, %88
  call void @cqrt_free(i32 %92)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %91, i32 %90, double 0x7FF0000000000000)    ; IR: uncompute %95 = fmul %94, inf
  call void @cqrt_free(i32 %91)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %90, i32 %89, i32 %88)    ; IR: uncompute %94 = fmuladd(%89, %87, %93)  [sum]
  call void @cqrt_free(i32 %90)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %89, i32 %85, i32 %83)    ; IR: uncompute %94 = fmuladd(%89, %87, %93)  [product]
  call void @cqrt_free(i32 %89)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %88, i32 %82, i32 %87)    ; IR: uncompute %93 = fmul %86, %92
  call void @cqrt_free(i32 %88)    ; IR: release it (|0>)
  call void @cq_template_fneg_f64_unc(i32 %87, i32 %84)    ; IR: uncompute %92 = fneg %88
  call void @cqrt_free(i32 %87)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket
  call void @cqrt_and_i1(i32 %59, i32 %68, i32 %86)    ; IR: uncompute %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  [self-inverse]
  call void @cqrt_free(i32 %86)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket: %90 is true only on the %60 -> %85 edge, i.e. %59 & NOT %71
  call void @cq_template_select_f64_unc(i32 %85, i32 %81, i32 %71, i32 %57)    ; IR: uncompute %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_free(i32 %85)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %84, i32 %81, i32 %74, i32 %56)    ; IR: uncompute %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  call void @cqrt_free(i32 %84)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %83, i32 %81, i32 %77, i32 %55)    ; IR: uncompute %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  call void @cqrt_free(i32 %83)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %81, i32 %80, i32 %54)    ; IR: uncompute %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]
  call void @cqrt_free(i32 %82)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %59, i32 %68, i32 %81)    ; IR: uncompute path predicate of block %72 relative to %53: %59 & %71  [self-inverse]
  call void @cqrt_free(i32 %81)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %80, i32 %78, i32 %79, i32 %54)    ; IR: uncompute %84
  call void @cqrt_free(i32 %80)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %79, double 0.000000e+00, i32 %54)    ; IR: uncompute %83
  call void @cqrt_free(i32 %79)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %78, i32 %54, double 0.000000e+00)    ; IR: uncompute %82 = isnan(%54)
  call void @cqrt_free(i32 %78)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %77, i32 %75, i32 %76, i32 %55)    ; IR: uncompute %81
  call void @cqrt_free(i32 %77)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %76, double 0.000000e+00, i32 %55)    ; IR: uncompute %80
  call void @cqrt_free(i32 %76)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %75, i32 %55, double 0.000000e+00)    ; IR: uncompute %79 = isnan(%55)
  call void @cqrt_free(i32 %75)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %74, i32 %72, i32 %73, i32 %56)    ; IR: uncompute %78
  call void @cqrt_free(i32 %74)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %73, double 0.000000e+00, i32 %56)    ; IR: uncompute %77
  call void @cqrt_free(i32 %73)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %72, i32 %56, double 0.000000e+00)    ; IR: uncompute %76 = isnan(%56)
  call void @cqrt_free(i32 %72)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %71, i32 %69, i32 %70, i32 %57)    ; IR: uncompute %75
  call void @cqrt_free(i32 %71)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %70, double 0.000000e+00, i32 %57)    ; IR: uncompute %74
  call void @cqrt_free(i32 %70)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %69, i32 %57, double 0.000000e+00)    ; IR: uncompute %73 = isnan(%57)
  call void @cqrt_free(i32 %69)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %66, i32 %67, i32 %68)    ; IR: uncompute %71 = or i1 %70, %68  [self-inverse]
  call void @cqrt_free(i32 %68)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %67)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %65, i32 %63, i32 %66)    ; IR: uncompute %68 = or i1 %67, %65  [self-inverse]
  call void @cqrt_free(i32 %66)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %65, i32 %64, double 0x7FF0000000000000)    ; IR: uncompute %67 = isinf(ad)
  call void @cqrt_free(i32 %65)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %64, i32 %22)    ; IR: uncompute %66 = fabs(%7)
  call void @cqrt_free(i32 %64)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %61, i32 %62, i32 %63)    ; IR: uncompute %65 = or i1 %62, %64  [self-inverse]
  call void @cqrt_free(i32 %63)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %62)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %61, i32 %60, double 0x7FF0000000000000)    ; IR: uncompute %62 = isinf(ac)
  call void @cqrt_free(i32 %61)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %60, i32 %21)    ; IR: uncompute %61 = fabs(%5)
  call void @cqrt_free(i32 %60)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %59, i32 %58, i32 0)    ; IR: uncompute %59 = icmp eq %58, 0
  call void @cqrt_free(i32 %59)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %58, i32 %43, i32 1, i32 %38)    ; IR: uncompute %58 = phi [ 1, %42 ], [ %36, %31 ]
  call void @cqrt_free(i32 %58)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %57, i32 %43, i32 %50, i32 %37)    ; IR: uncompute %57 = phi [ %49, %42 ], [ %35, %31 ]
  call void @cqrt_free(i32 %57)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %56, i32 %43, i32 %53, i32 %36)    ; IR: uncompute %56 = phi [ %52, %42 ], [ %34, %31 ]
  call void @cqrt_free(i32 %56)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %55, i32 %43, i32 %45, i32 %35)    ; IR: uncompute %55 = phi [ %44, %42 ], [ %33, %31 ]
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %54, i32 %43, i32 %47, i32 %34)    ; IR: uncompute %54 = phi [ %46, %42 ], [ %32, %31 ]
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %53, i32 %51, i32 %52, i32 %36)    ; IR: uncompute %52 = select %50, %51, %34
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %52, double 0.000000e+00, i32 %36)    ; IR: uncompute %51 = copysign(0, %34)
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %51, i32 %36, double 0.000000e+00)    ; IR: uncompute %50 = isnan(%34)
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %50, i32 %48, i32 %49, i32 %37)    ; IR: uncompute %49 = select %47, %48, %35
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %49, double 0.000000e+00, i32 %37)    ; IR: uncompute %48 = copysign(0, %35)
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %48, i32 %37, double 0.000000e+00)    ; IR: uncompute %47 = isnan(%35)
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %47, i32 %46, i32 %34)    ; IR: uncompute %46 = copysign(%45, %32)
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %46, i32 %42)    ; IR: uncompute %45
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %45, i32 %44, i32 %35)    ; IR: uncompute %44 = copysign(%43, %33)
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %44, i32 %40)    ; IR: uncompute %43
  call void @cqrt_free(i32 %44)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %42, i32 %40, i32 %43)    ; IR: uncompute %41 = or i1 %40, %38  [self-inverse]
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %42, i32 %41, double 0x7FF0000000000000)    ; IR: uncompute %40 = isinf(%32)
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %41, i32 %34)    ; IR: uncompute %39 = fabs(%32)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %40, i32 %39, double 0x7FF0000000000000)    ; IR: uncompute %38 = isinf(%33)
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %39, i32 %35)    ; IR: uncompute %37 = fabs(%33)
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %38, i32 %31, i32 1, i32 0)    ; IR: uncompute %36 = phi [ 1, %20 ], [ 0, %14 ]
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %37, i32 %31, i32 %33, i32 %0)    ; IR: uncompute %35 = phi [ %22, %20 ], [ %0, %14 ]
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %36, i32 %31, double %10, double %1)    ; IR: uncompute %34 = phi [ %24, %20 ], [ %1, %14 ]
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %35, i32 %31, double %13, double %2)    ; IR: uncompute %33 = phi [ %27, %20 ], [ %2, %14 ]
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %34, i32 %31, double %16, double %3)    ; IR: uncompute %32 = phi [ %30, %20 ], [ %3, %14 ]
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %33, i32 %32, i32 %0)    ; IR: uncompute %22 = copysign(%21, a)
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %32, i32 %29)    ; IR: uncompute %21 = uitofp i1 %16
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %29, i32 %30, i32 %31)    ; IR: uncompute %19 = or i1 %16, %18  [self-inverse]
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %30)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %29, i32 %28, double 0x7FF0000000000000)    ; IR: uncompute %16 = isinf(a)
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %28, i32 %0)    ; IR: uncompute %15 = fabs(a)
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %25, i32 %26, i32 %27)    ; IR: uncompute %13 = and i1 %11, %12  [self-inverse]
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %26, i32 %24, double 0.000000e+00)    ; IR: uncompute %12 = fcmp uno %10, 0.0
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %25, i32 %23, double 0.000000e+00)    ; IR: uncompute %11 = fcmp uno %9, 0.0
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %24, i32 %22, double %6)    ; IR: uncompute %10 = fadd double %8, %7
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_fsub_f64_hl_unc(i32 %23, i32 %21, double %5)    ; IR: uncompute %9 = fsub double %5, %6
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %22, i32 %0, double %3)    ; IR: uncompute %7 = fmul double %0, %3
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %21, i32 %0, double %2)    ; IR: uncompute %5 = fmul double %0, %2
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  %101 = insertvalue { i32, i32 } poison, i32 %99, 0    ; IR: %102  (the aggregate carries handles)
  %102 = insertvalue { i32, i32 } %101, i32 %100, 1    ; IR: %103
  ret { i32, i32 } %102    ; IR: ret { double, double } %103
}

define internal fastcc void @__cq_q___muldc3_1000_unc(i32 %0, i32 %1, i32 %2, double %3, double %4, double %5) {
  %7 = fmul double %3, %5    ; IR: %6 = fmul double %1, %3  (classical: b*d)
  %8 = fmul double %3, %4    ; IR: %8 = fmul double %1, %2  (classical: b*c)
  %9 = tail call double @llvm.fabs.f64(double %3)    ; IR: %17  (classical)
  %10 = fcmp oeq double %9, 0x7FF0000000000000    ; IR: %18 = isinf(b)  (classical)
  %11 = uitofp i1 %10 to double    ; IR: %23  (classical)
  %12 = tail call double @llvm.copysign.f64(double %11, double %3)    ; IR: %24  (classical)
  %13 = fcmp uno double %4, 0.000000e+00    ; IR: %25 = isnan(c)  (classical)
  %14 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %4)    ; IR: %26  (classical)
  %15 = select i1 %13, double %14, double %4    ; IR: %27  (classical)
  %16 = fcmp uno double %5, 0.000000e+00    ; IR: %28 = isnan(d)  (classical)
  %17 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %5)    ; IR: %29  (classical)
  %18 = select i1 %16, double %17, double %5    ; IR: %30  (classical)
  %19 = tail call double @llvm.fabs.f64(double %7)    ; IR: %63  (classical)
  %20 = fcmp oeq double %19, 0x7FF0000000000000    ; IR: %64 = isinf(bd)  (classical)
  %21 = tail call double @llvm.fabs.f64(double %8)    ; IR: %69  (classical)
  %22 = fcmp oeq double %21, 0x7FF0000000000000    ; IR: %70 = isinf(bc)  (classical)
  %23 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %4)    ; IR: recompute %5 = fmul double %0, %2  (a*c)
  %24 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %5)    ; IR: recompute %7 = fmul double %0, %3  (a*d)
  %25 = call i32 @cq_template_fsub_f64_hl(i32 %23, double %7)    ; IR: recompute %9 = fsub double %5, %6  (real part of the fast product)
  %26 = call i32 @cq_template_fadd_f64_hl(i32 %24, double %8)    ; IR: recompute %10 = fadd double %8, %7  (imaginary part; commutative, quantum operand first)
  %27 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %25, double 0.000000e+00)    ; IR: recompute %11 = fcmp uno %9, 0.0  (isnan)
  %28 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %26, double 0.000000e+00)    ; IR: recompute %12 = fcmp uno %10, 0.0
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %27, i32 %28, i32 %29)    ; IR: recompute %13 = and i1 %11, %12  [predicate of block %14: both parts NaN]
  %30 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: recompute %15 = fabs(a)  (block %14)
  %31 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %30, double 0x7FF0000000000000)    ; IR: recompute %16 = isinf(a)
  %32 = call i32 @cqrt_alloc_i1(i1 %10)    ; IR: recompute %19 = or i1 %16, %18  [predicate of block %20 within %14]  [the classical disjunct %10 as a seed rail, rule 7]
  %33 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %19 = or i1 %16, %18  [predicate of block %20 within %14]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %31, i32 %32, i32 %33)    ; IR: recompute %19 = or i1 %16, %18  [predicate of block %20 within %14]
  %34 = call i32 @cq_template_uitofp_i1_to_f64(i32 %31)    ; IR: recompute %21 = uitofp i1 %16  (block %20)
  %35 = call i32 @cq_template_copysign_f64(i32 %34, i32 %2)    ; IR: recompute %22 = copysign(%21, a)
  %36 = call i32 @cq_template_select_f64_ll(i32 %33, double %18, double %5)    ; IR: recompute %32 = phi [ %30, %20 ], [ %3, %14 ]  (merge of block %20 on its predicate %19)
  %37 = call i32 @cq_template_select_f64_ll(i32 %33, double %15, double %4)    ; IR: recompute %33 = phi [ %27, %20 ], [ %2, %14 ]
  %38 = call i32 @cq_template_select_f64_ll(i32 %33, double %12, double %3)    ; IR: recompute %34 = phi [ %24, %20 ], [ %1, %14 ]
  %39 = call i32 @cq_template_select_f64(i32 %33, i32 %35, i32 %2)    ; IR: recompute %35 = phi [ %22, %20 ], [ %0, %14 ]
  %40 = call i32 @cq_template_select_i32_ll(i32 %33, i32 1, i32 0)    ; IR: recompute %36 = phi [ 1, %20 ], [ 0, %14 ]  (__recalc)
  %41 = call i32 @cq_template_fabs_f64(i32 %37)    ; IR: recompute %37 = fabs(%33)  (block %31)
  %42 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %41, double 0x7FF0000000000000)    ; IR: recompute %38 = isinf(%33)
  %43 = call i32 @cq_template_fabs_f64(i32 %36)    ; IR: recompute %39 = fabs(%32)
  %44 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %43, double 0x7FF0000000000000)    ; IR: recompute %40 = isinf(%32)
  %45 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %41 = or i1 %40, %38  [predicate of block %42]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %44, i32 %42, i32 %45)    ; IR: recompute %41 = or i1 %40, %38  [predicate of block %42]
  %46 = call i32 @cq_template_uitofp_i1_to_f64(i32 %42)    ; IR: recompute %43  (block %42)
  %47 = call i32 @cq_template_copysign_f64(i32 %46, i32 %37)    ; IR: recompute %44 = copysign(%43, %33)
  %48 = call i32 @cq_template_uitofp_i1_to_f64(i32 %44)    ; IR: recompute %45
  %49 = call i32 @cq_template_copysign_f64(i32 %48, i32 %36)    ; IR: recompute %46 = copysign(%45, %32)
  %50 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %39, double 0.000000e+00)    ; IR: recompute %47 = isnan(%35)
  %51 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %39)    ; IR: recompute %48 = copysign(0, %35)
  %52 = call i32 @cq_template_select_f64(i32 %50, i32 %51, i32 %39)    ; IR: recompute %49 = select %47, %48, %35
  %53 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %38, double 0.000000e+00)    ; IR: recompute %50 = isnan(%34)
  %54 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %38)    ; IR: recompute %51 = copysign(0, %34)
  %55 = call i32 @cq_template_select_f64(i32 %53, i32 %54, i32 %38)    ; IR: recompute %52 = select %50, %51, %34
  %56 = call i32 @cq_template_select_f64(i32 %45, i32 %49, i32 %36)    ; IR: recompute %54 = phi [ %46, %42 ], [ %32, %31 ]  (merge of block %42 on %41)
  %57 = call i32 @cq_template_select_f64(i32 %45, i32 %47, i32 %37)    ; IR: recompute %55 = phi [ %44, %42 ], [ %33, %31 ]
  %58 = call i32 @cq_template_select_f64(i32 %45, i32 %55, i32 %38)    ; IR: recompute %56 = phi [ %52, %42 ], [ %34, %31 ]
  %59 = call i32 @cq_template_select_f64(i32 %45, i32 %52, i32 %39)    ; IR: recompute %57 = phi [ %49, %42 ], [ %35, %31 ]
  %60 = call i32 @cq_template_select_i32_lh(i32 %45, i32 1, i32 %40)    ; IR: recompute %58 = phi [ 1, %42 ], [ %36, %31 ]  (__recalc)
  %61 = call i32 @cq_template_icmp_eq_i32_hl(i32 %60, i32 0)    ; IR: recompute %59 = icmp eq %58, 0  [predicate of block %60: !__recalc]
  %62 = call i32 @cq_template_fabs_f64(i32 %23)    ; IR: recompute %61 = fabs(%5)  (block %60)
  %63 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %62, double 0x7FF0000000000000)    ; IR: recompute %62 = isinf(ac)
  %64 = call i32 @cqrt_alloc_i1(i1 %20)    ; IR: recompute %65 = or i1 %62, %64  [the classical disjunct %20 as a seed rail, rule 7]
  %65 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %63, i32 %64, i32 %65)    ; IR: recompute %65 = or i1 %62, %64
  %66 = call i32 @cq_template_fabs_f64(i32 %24)    ; IR: recompute %66 = fabs(%7)
  %67 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %66, double 0x7FF0000000000000)    ; IR: recompute %67 = isinf(ad)
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %67, i32 %65, i32 %68)    ; IR: recompute %68 = or i1 %67, %65
  %69 = call i32 @cqrt_alloc_i1(i1 %22)    ; IR: recompute %71 = or i1 %70, %68  [predicate of block %72 within %60]  [the classical disjunct %22 as a seed rail, rule 7]
  %70 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %71 = or i1 %70, %68  [predicate of block %72 within %60]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %68, i32 %69, i32 %70)    ; IR: recompute %71 = or i1 %70, %68  [predicate of block %72 within %60]
  %71 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %59, double 0.000000e+00)    ; IR: recompute %73 = isnan(%57)  (block %72)
  %72 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %59)    ; IR: recompute %74
  %73 = call i32 @cq_template_select_f64(i32 %71, i32 %72, i32 %59)    ; IR: recompute %75
  %74 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %58, double 0.000000e+00)    ; IR: recompute %76 = isnan(%56)
  %75 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %58)    ; IR: recompute %77
  %76 = call i32 @cq_template_select_f64(i32 %74, i32 %75, i32 %58)    ; IR: recompute %78
  %77 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %57, double 0.000000e+00)    ; IR: recompute %79 = isnan(%55)
  %78 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %57)    ; IR: recompute %80
  %79 = call i32 @cq_template_select_f64(i32 %77, i32 %78, i32 %57)    ; IR: recompute %81
  %80 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %56, double 0.000000e+00)    ; IR: recompute %82 = isnan(%54)
  %81 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %56)    ; IR: recompute %83
  %82 = call i32 @cq_template_select_f64(i32 %80, i32 %81, i32 %56)    ; IR: recompute %84
  %83 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %72 relative to %53: %59 & %71  [fresh flag rail]
  call void @cqrt_and_i1(i32 %61, i32 %70, i32 %83)    ; IR: path predicate of block %72 relative to %53: %59 & %71
  %84 = call i32 @cq_template_select_f64(i32 %83, i32 %82, i32 %56)    ; IR: recompute %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (only the %72 path differs)
  %85 = call i32 @cq_template_select_f64(i32 %83, i32 %79, i32 %57)    ; IR: recompute %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  %86 = call i32 @cq_template_select_f64(i32 %83, i32 %76, i32 %58)    ; IR: recompute %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  %87 = call i32 @cq_template_select_f64(i32 %83, i32 %73, i32 %59)    ; IR: recompute %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket: %90 is true only on the %60 -> %85 edge, i.e. %59 & NOT %71
  %88 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  = %59 & !%71  [no recalculation]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %61, i32 %70, i32 %88)    ; IR: recompute %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  = %59 & !%71  [no recalculation]
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket
  %89 = call i32 @cq_template_fneg_f64(i32 %86)    ; IR: recompute %92 = fneg %88  (block %91)
  %90 = call i32 @cq_template_fmul_f64(i32 %84, i32 %89)    ; IR: recompute %93 = fmul %86, %92
  %91 = call i32 @cq_template_fmul_f64(i32 %87, i32 %85)    ; IR: recompute %94 = fmuladd(%89, %87, %93)  [unfused product]
  %92 = call i32 @cq_template_fadd_f64(i32 %91, i32 %90)    ; IR: recompute %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %93 = call i32 @cq_template_fmul_f64_hl(i32 %92, double 0x7FF0000000000000)    ; IR: recompute %95 = fmul %94, inf
  %94 = call i32 @cq_template_fmul_f64(i32 %85, i32 %86)    ; IR: recompute %96 = fmul %87, %88
  %95 = call i32 @cq_template_fmul_f64(i32 %87, i32 %84)    ; IR: recompute %97 = fmuladd(%89, %86, %96)  [unfused product]
  %96 = call i32 @cq_template_fadd_f64(i32 %95, i32 %94)    ; IR: recompute %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %97 = call i32 @cq_template_fmul_f64_hl(i32 %96, double 0x7FF0000000000000)    ; IR: recompute %98 = fmul %97, inf
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket: block %91 runs iff %13 & NOT %90
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %91: %13 & !%90  [fresh flag rail]
  call void @cqrt_and_i1(i32 %29, i32 %88, i32 %98)    ; IR: path predicate of block %91: %13 & !%90
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket
  %99 = call i32 @cq_template_select_f64(i32 %98, i32 %93, i32 %25)    ; IR: recompute %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  %100 = call i32 @cq_template_select_f64(i32 %98, i32 %97, i32 %26)    ; IR: recompute %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  call void @cqrt_copy_f64(i32 %99, i32 %0)    ; IR: xor the real part out of the result rail
  call void @cqrt_copy_f64(i32 %100, i32 %1)    ; IR: xor the imaginary part out of the result rail
  call void @cq_template_select_f64_unc(i32 %100, i32 %98, i32 %97, i32 %26)    ; IR: uncompute %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]
  call void @cqrt_free(i32 %100)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %99, i32 %98, i32 %93, i32 %25)    ; IR: uncompute %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]
  call void @cqrt_free(i32 %99)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket
  call void @cqrt_and_i1(i32 %29, i32 %88, i32 %98)    ; IR: uncompute path predicate of block %91: %13 & !%90  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket: block %91 runs iff %13 & NOT %90
  call void @cq_template_fmul_f64_hl_unc(i32 %97, i32 %96, double 0x7FF0000000000000)    ; IR: uncompute %98 = fmul %97, inf
  call void @cqrt_free(i32 %97)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %96, i32 %95, i32 %94)    ; IR: uncompute %97 = fmuladd(%89, %86, %96)  [sum]
  call void @cqrt_free(i32 %96)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %95, i32 %87, i32 %84)    ; IR: uncompute %97 = fmuladd(%89, %86, %96)  [product]
  call void @cqrt_free(i32 %95)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %94, i32 %85, i32 %86)    ; IR: uncompute %96 = fmul %87, %88
  call void @cqrt_free(i32 %94)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %93, i32 %92, double 0x7FF0000000000000)    ; IR: uncompute %95 = fmul %94, inf
  call void @cqrt_free(i32 %93)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %92, i32 %91, i32 %90)    ; IR: uncompute %94 = fmuladd(%89, %87, %93)  [sum]
  call void @cqrt_free(i32 %92)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %91, i32 %87, i32 %85)    ; IR: uncompute %94 = fmuladd(%89, %87, %93)  [product]
  call void @cqrt_free(i32 %91)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %90, i32 %84, i32 %89)    ; IR: uncompute %93 = fmul %86, %92
  call void @cqrt_free(i32 %90)    ; IR: release it (|0>)
  call void @cq_template_fneg_f64_unc(i32 %89, i32 %86)    ; IR: uncompute %92 = fneg %88
  call void @cqrt_free(i32 %89)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket
  call void @cqrt_and_i1(i32 %61, i32 %70, i32 %88)    ; IR: uncompute %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ]  [self-inverse]
  call void @cqrt_free(i32 %88)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket: %90 is true only on the %60 -> %85 edge, i.e. %59 & NOT %71
  call void @cq_template_select_f64_unc(i32 %87, i32 %83, i32 %73, i32 %59)    ; IR: uncompute %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]
  call void @cqrt_free(i32 %87)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %86, i32 %83, i32 %76, i32 %58)    ; IR: uncompute %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]
  call void @cqrt_free(i32 %86)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %85, i32 %83, i32 %79, i32 %57)    ; IR: uncompute %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]
  call void @cqrt_free(i32 %85)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %84, i32 %83, i32 %82, i32 %56)    ; IR: uncompute %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]
  call void @cqrt_free(i32 %84)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %61, i32 %70, i32 %83)    ; IR: uncompute path predicate of block %72 relative to %53: %59 & %71  [self-inverse]
  call void @cqrt_free(i32 %83)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %80, i32 %81, i32 %56)    ; IR: uncompute %84
  call void @cqrt_free(i32 %82)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %81, double 0.000000e+00, i32 %56)    ; IR: uncompute %83
  call void @cqrt_free(i32 %81)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %80, i32 %56, double 0.000000e+00)    ; IR: uncompute %82 = isnan(%54)
  call void @cqrt_free(i32 %80)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %79, i32 %77, i32 %78, i32 %57)    ; IR: uncompute %81
  call void @cqrt_free(i32 %79)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %78, double 0.000000e+00, i32 %57)    ; IR: uncompute %80
  call void @cqrt_free(i32 %78)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %77, i32 %57, double 0.000000e+00)    ; IR: uncompute %79 = isnan(%55)
  call void @cqrt_free(i32 %77)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %76, i32 %74, i32 %75, i32 %58)    ; IR: uncompute %78
  call void @cqrt_free(i32 %76)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %75, double 0.000000e+00, i32 %58)    ; IR: uncompute %77
  call void @cqrt_free(i32 %75)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %74, i32 %58, double 0.000000e+00)    ; IR: uncompute %76 = isnan(%56)
  call void @cqrt_free(i32 %74)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %73, i32 %71, i32 %72, i32 %59)    ; IR: uncompute %75
  call void @cqrt_free(i32 %73)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %72, double 0.000000e+00, i32 %59)    ; IR: uncompute %74
  call void @cqrt_free(i32 %72)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %71, i32 %59, double 0.000000e+00)    ; IR: uncompute %73 = isnan(%57)
  call void @cqrt_free(i32 %71)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %68, i32 %69, i32 %70)    ; IR: uncompute %71 = or i1 %70, %68  [self-inverse]
  call void @cqrt_free(i32 %70)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %69)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %67, i32 %65, i32 %68)    ; IR: uncompute %68 = or i1 %67, %65  [self-inverse]
  call void @cqrt_free(i32 %68)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %67, i32 %66, double 0x7FF0000000000000)    ; IR: uncompute %67 = isinf(ad)
  call void @cqrt_free(i32 %67)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %66, i32 %24)    ; IR: uncompute %66 = fabs(%7)
  call void @cqrt_free(i32 %66)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %63, i32 %64, i32 %65)    ; IR: uncompute %65 = or i1 %62, %64  [self-inverse]
  call void @cqrt_free(i32 %65)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %64)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %63, i32 %62, double 0x7FF0000000000000)    ; IR: uncompute %62 = isinf(ac)
  call void @cqrt_free(i32 %63)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %62, i32 %23)    ; IR: uncompute %61 = fabs(%5)
  call void @cqrt_free(i32 %62)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %61, i32 %60, i32 0)    ; IR: uncompute %59 = icmp eq %58, 0
  call void @cqrt_free(i32 %61)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %60, i32 %45, i32 1, i32 %40)    ; IR: uncompute %58 = phi [ 1, %42 ], [ %36, %31 ]
  call void @cqrt_free(i32 %60)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %59, i32 %45, i32 %52, i32 %39)    ; IR: uncompute %57 = phi [ %49, %42 ], [ %35, %31 ]
  call void @cqrt_free(i32 %59)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %58, i32 %45, i32 %55, i32 %38)    ; IR: uncompute %56 = phi [ %52, %42 ], [ %34, %31 ]
  call void @cqrt_free(i32 %58)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %57, i32 %45, i32 %47, i32 %37)    ; IR: uncompute %55 = phi [ %44, %42 ], [ %33, %31 ]
  call void @cqrt_free(i32 %57)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %56, i32 %45, i32 %49, i32 %36)    ; IR: uncompute %54 = phi [ %46, %42 ], [ %32, %31 ]
  call void @cqrt_free(i32 %56)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %55, i32 %53, i32 %54, i32 %38)    ; IR: uncompute %52 = select %50, %51, %34
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %54, double 0.000000e+00, i32 %38)    ; IR: uncompute %51 = copysign(0, %34)
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %53, i32 %38, double 0.000000e+00)    ; IR: uncompute %50 = isnan(%34)
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %52, i32 %50, i32 %51, i32 %39)    ; IR: uncompute %49 = select %47, %48, %35
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %51, double 0.000000e+00, i32 %39)    ; IR: uncompute %48 = copysign(0, %35)
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %50, i32 %39, double 0.000000e+00)    ; IR: uncompute %47 = isnan(%35)
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %49, i32 %48, i32 %36)    ; IR: uncompute %46 = copysign(%45, %32)
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %48, i32 %44)    ; IR: uncompute %45
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %47, i32 %46, i32 %37)    ; IR: uncompute %44 = copysign(%43, %33)
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %46, i32 %42)    ; IR: uncompute %43
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %44, i32 %42, i32 %45)    ; IR: uncompute %41 = or i1 %40, %38  [self-inverse]
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %44, i32 %43, double 0x7FF0000000000000)    ; IR: uncompute %40 = isinf(%32)
  call void @cqrt_free(i32 %44)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %43, i32 %36)    ; IR: uncompute %39 = fabs(%32)
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %42, i32 %41, double 0x7FF0000000000000)    ; IR: uncompute %38 = isinf(%33)
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %41, i32 %37)    ; IR: uncompute %37 = fabs(%33)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %40, i32 %33, i32 1, i32 0)    ; IR: uncompute %36 = phi [ 1, %20 ], [ 0, %14 ]
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %39, i32 %33, i32 %35, i32 %2)    ; IR: uncompute %35 = phi [ %22, %20 ], [ %0, %14 ]
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %38, i32 %33, double %12, double %3)    ; IR: uncompute %34 = phi [ %24, %20 ], [ %1, %14 ]
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %37, i32 %33, double %15, double %4)    ; IR: uncompute %33 = phi [ %27, %20 ], [ %2, %14 ]
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %36, i32 %33, double %18, double %5)    ; IR: uncompute %32 = phi [ %30, %20 ], [ %3, %14 ]
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cq_template_copysign_f64_unc(i32 %35, i32 %34, i32 %2)    ; IR: uncompute %22 = copysign(%21, a)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %34, i32 %31)    ; IR: uncompute %21 = uitofp i1 %16
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %31, i32 %32, i32 %33)    ; IR: uncompute %19 = or i1 %16, %18  [self-inverse]
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %32)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %31, i32 %30, double 0x7FF0000000000000)    ; IR: uncompute %16 = isinf(a)
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %30, i32 %2)    ; IR: uncompute %15 = fabs(a)
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %27, i32 %28, i32 %29)    ; IR: uncompute %13 = and i1 %11, %12  [self-inverse]
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %28, i32 %26, double 0.000000e+00)    ; IR: uncompute %12 = fcmp uno %10, 0.0
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %27, i32 %25, double 0.000000e+00)    ; IR: uncompute %11 = fcmp uno %9, 0.0
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %26, i32 %24, double %8)    ; IR: uncompute %10 = fadd double %8, %7
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_fsub_f64_hl_unc(i32 %25, i32 %23, double %7)    ; IR: uncompute %9 = fsub double %5, %6
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %24, i32 %2, double %5)    ; IR: uncompute %7 = fmul double %0, %3
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %23, i32 %2, double %4)    ; IR: uncompute %5 = fmul double %0, %2
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  ret void
}

declare void @cqrt_or_i1(i32, i32, i32)

declare i32 @cqrt_alloc_f64(double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare double @llvm.fabs.f64(double)
declare double @llvm.copysign.f64(double, double)
declare i32 @cq_template_copysign_f64(i32, i32)
declare i32 @cq_template_copysign_f64_lh(double, i32)
declare i32 @cq_template_fabs_f64(i32)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare i32 @cq_template_fcmp_oeq_f64_hl(i32, double)
declare i32 @cq_template_fcmp_uno_f64_hl(i32, double)
declare i32 @cq_template_fmul_f64(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare i32 @cq_template_fneg_f64(i32)
declare i32 @cq_template_fsub_f64_hl(i32, double)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare i32 @cq_template_uitofp_i1_to_f64(i32)
declare void @cq_template_copysign_f64_lh_unc(i32, double, i32)
declare void @cq_template_copysign_f64_unc(i32, i32, i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare void @cq_template_fcmp_oeq_f64_hl_unc(i32, i32, double)
declare void @cq_template_fcmp_uno_f64_hl_unc(i32, i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare void @cq_template_fneg_f64_unc(i32, i32)
declare void @cq_template_fsub_f64_hl_unc(i32, i32, double)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare void @cq_template_uitofp_i1_to_f64_unc(i32, i32)
