; HAND-WRITTEN. Rules: 26, 18, 19, 8, 9, 4, 5, 7 (and 3, 1).
; Checked: complex_mul_builtin: creal(p) + cimag(p) (the sum rail, measured); complex_div_builtin: creal(q) and cimag(q) (two
;   measurements of the clone's result copies, classical sum).
; Clean: every rail but the registers (re; c and d) and the measured result rails: every flag, seed, product, select and
;   clone-internal rail, and (first entry) the __muldc3 result copies after the _unc twin, all freed.
; Kept: nothing beyond the registers and the measured rails: neither clone holds a loop (no a_K) or a rotation.
; Rotations: Ry(th) on re (first entry); Ry(tc) on c, Ry(td) on d (second entry). The clones hold no rotation.
; Rule 18 with the REAL builtin bodies. The .c defines neither __muldc3 nor __divdc3, so clang's calls reach compiler-rt's
; pinned 19.1.7 bodies in the injection bundle (cq_bundle_v1: @__muldc3 lines 7-139, @__divdc3 lines 140-547), and those are
; the bodies lifted here value for value: __compiler_rt_logb / __compiler_rt_scalbn / fmax are INLINE in them (bit tests
; on the i64 pattern, llvm.ctlz.i64 for the subnormal case, llvm.sadd.sat.i32 for the saturated exponent, llvm.smax.i32,
; llvm.copysign, llvm.fabs; no libm call and no nested clone), unlike 169-174, whose .c files define musl-shaped helpers
; and so witness the lifted-musl shape instead (§7: a reference that depicts another body pins nothing).
; Taint. First entry: z's real part re is the register, so `__muldc3(re, im, a, b)` is reached with mask 1000 (arg 0
; quantum; im, a and the real part a + b*0 of w are classical) -> __cq_q___muldc3_1000. clang -O1 emits Annex G's inline
; formula first (%11-%16: ac, ad quantum, bd, bc classical; the products are fmul_hl, the differences fsub_hl / fadd_hl
; with the classical factor as the literal, rule 4) and calls __muldc3 only on the NaN path `isnan(real) && isnan(imag)`
; (%17, %19: two fcmp uno flags, both quantum). The callee body has no non-pure gate (no rotation, phase, store or tape),
; so by rule 19 it is called UNGUARDED and its results are merged by select under the path predicate P20 = %17 & %19 (one
; and_i1 flag, rule 8): the two phis of %24 become one select_f64 each, the complement (the inline value) in the else arm.
; Second entry: c and d are the registers, b*0 + a is classical, so `__divdc3(a, b, c + d*0, d)` is reached with mask 0011
; -> __cq_q___divdc3_0011 (clang never inlines a complex divide). Nothing calls a twin of that clone, since both result
; copies are measured directly (as 169's c_qq), so none is defined (§1.4); __cq_q___muldc3_1000_unc is defined and called.
; Inside the clones every op with a handle operand is an out-of-place template into a fresh rail (rule 4; _hl/_lh with the
; classical value as the literal, a commutative op with the handle first, compares never _lh), every op on classical
; operands only stays classical IR, and a phi whose two arms are both classical values but whose edge is a quantum flag is
; a select_f64_ll into a fresh rail (rule 9: %32-%34 of __muldc3). llvm.fmuladd is UNFUSED (§2, cf. 14, 69, 169): an fmul
; into a fresh product rail, then an fadd of the product and the addend. The fcmp predicates (uno, ord-free here: uno,
; oeq, olt, ueq, une) are templates; `select i1 %a, i1 true, i1 %b` is the disjunction or_i1 and `select i1 %a, i1 %b,
; i1 false` / `and i1` the conjunction and_i1 into a fresh |0> flag (rule 8); a negated conjunct is an X bracket (not_i1)
; around the gate; a classical conjunct of a mixed condition is a seed rail (rule 7, as 169); the i1 phi %90 of __muldc3
; (`[false, %53], [false, %72], [true, %60]`) is the flag %59 & !%71. A flag read as data (%16, %38, %40 feed uitofp i1)
; is the compare's own rail. llvm.ctlz.i64 (zero-is-poison: the template is total, §2), llvm.sadd.sat.i32 and llvm.smax.i32
; on handles are the ctlz_i64, sadd_sat_i32 and smax_i32_hl templates. Merges follow the CFG: an if/else-if ladder into one
; exit nests its selects on the local flags, the deepest else innermost (rule 9: the %35 logb merge on %14/%16/%18, the
; four scalbn merges %88/%137/%192/%244 on their %47-shaped / %64 / %70 flags, the %135 merge on %37); the five-incoming
; phis of %302 (__divdc3) and %85/%99 (__muldc3) whose arms sit on disjoint path predicates (P254, P288, P270; P72; P91)
; are one select per distinct incoming on and_i1 chains of those predicates, the complement value (the plain quotient /
; product) innermost. Rule 6 does not fire: no rotated register is updated (re + im*0, c + d*0 are fadds, not bijections),
; and the clones' dead integer intermediates are rule-5 garbage uncomputed LIFO like every other rail (nothing is kept).
; Each clone copies its two results into fresh rails, uncomputes its whole chain LIFO (rule 5) and returns the copies; the
; first entry runs the twin (recompute, copy_f64 the results out, uncompute) and frees the copies before measuring the
; merged sum, the second measures the two copies after uncomputing its own garbage (%12, %11).
source_filename = "complex_builtin_lifted.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @complex_mul_builtin(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = fmul double %2, 0.000000e+00    ; IR: %7 = fmul %2, 0.0  (im * I: real part im*0)  (classical)
  %8 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %7)    ; IR: %8 = fadd %7, %6  (real part of z; commutative, handle first)
  %9 = fmul double %4, 0.000000e+00    ; IR: %9 = fmul %4, 0.0  (classical)
  %10 = fadd double %9, %3    ; IR: %10 = fadd %9, %3  (real part of w)  (classical)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %10)    ; IR: %11 = fmul %10, %8  (ac; commutative, handle first)
  %12 = fmul double %2, %4    ; IR: %12 = fmul %2, %4  (bd)  (classical)
  %13 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %4)    ; IR: %13 = fmul %8, %4  (ad)
  %14 = fmul double %10, %2    ; IR: %14 = fmul %10, %2  (bc)  (classical)
  %15 = call i32 @cq_template_fsub_f64_hl(i32 %11, double %12)    ; IR: %15 = fsub %11, %12  (inline real part)
  %16 = call i32 @cq_template_fadd_f64_hl(i32 %13, double %14)    ; IR: %16 = fadd %14, %13  (inline imaginary part; commutative, handle first)
  %17 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %15, double 0.000000e+00)    ; IR: %17 = fcmp uno %15, 0  [br %17 -> block %18, else exit %24]
  %18 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %16, double 0.000000e+00)    ; IR: %19 = fcmp uno %16, 0  (block %18)  [br %19 -> block %20, else %24]
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P20 = path predicate of block %20 (the __muldc3 call): %17 & %19  [fresh flag rail]
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: P20 = path predicate of block %20 (the __muldc3 call): %17 & %19
  %20 = call fastcc { i32, i32 } @__cq_q___muldc3_1000(i32 %8, double %2, double %10, double %4)    ; IR: %21 = call @__muldc3(%8, %2, %10, %4) in block %20: the pinned compiler-rt body, lifted with mask 1000 (arg 0 quantum); no non-pure gate in the body, so it runs unguarded (rule 19) and P20 steers the merge
  %21 = extractvalue { i32, i32 } %20, 0    ; IR: extractvalue %21, 0  (handle; classical)
  %22 = extractvalue { i32, i32 } %20, 1    ; IR: extractvalue %21, 1  (handle; classical)
  %23 = call i32 @cq_template_select_f64(i32 %19, i32 %21, i32 %15)    ; IR: %25 = phi [ %15, %5 ], [ %15, %18 ], [ %22, %20 ]  (real part of p)
  %24 = call i32 @cq_template_select_f64(i32 %19, i32 %22, i32 %16)    ; IR: %26 = phi [ %16, %5 ], [ %16, %18 ], [ %23, %20 ]  (imaginary part of p)
  %25 = call i32 @cq_template_fadd_f64(i32 %23, i32 %24)    ; IR: %27 = fadd %25, %26  [result rail]
  call void @cq_template_select_f64_unc(i32 %24, i32 %19, i32 %22, i32 %16)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %19, i32 %21, i32 %15)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call fastcc void @__cq_q___muldc3_1000_unc(i32 %21, i32 %22, i32 %8, double %2, double %10, double %4)    ; IR: uncompute the result rails of %21 (the _unc twin recomputes and XORs them out)
  call void @cqrt_free(i32 %21)    ; IR: release the %21 result copy (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the %21 result copy (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %18, i32 %19)    ; IR: uncompute P20  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the P20 rail (|0>)
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
  %26 = call double @cqrt_measure_f64(i32 %25)    ; IR: %28 = cq_measure_f64(%27)
  ret double %26    ; IR: ret double %28
}

define double @complex_div_builtin(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_f64(double %2)    ; IR: %7 = cq_theta_f64(%2, %3)  [register c]
  call void @cqrt_ry_f64(i32 %7, double %3)    ; IR: %7 = cq_theta_f64(%2, %3)  [Ry]
  %8 = call i32 @cqrt_alloc_f64(double %4)    ; IR: %8 = cq_theta_f64(%4, %5)  [register d]
  call void @cqrt_ry_f64(i32 %8, double %5)    ; IR: %8 = cq_theta_f64(%4, %5)  [Ry]
  %9 = fmul double %1, 0.000000e+00    ; IR: %9 = fmul %1, 0.0  (classical)
  %10 = fadd double %9, %0    ; IR: %10 = fadd %9, %0  (real part of z)  (classical)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double 0.000000e+00)    ; IR: %11 = fmul %8, 0.0  (d * I: real part d*0)
  %12 = call i32 @cq_template_fadd_f64(i32 %7, i32 %11)    ; IR: %12 = fadd %7, %11  (real part of w)
  %13 = call fastcc { i32, i32 } @__cq_q___divdc3_0011(double %10, double %1, i32 %12, i32 %8)    ; IR: %13 = call @__divdc3(%10, %1, %12, %8): the pinned compiler-rt body, lifted with mask 0011 (args 2 and 3 quantum); both result rails are measured below, so the twin never runs
  %14 = extractvalue { i32, i32 } %13, 0    ; IR: extractvalue %13, 0  (handle; classical)
  %15 = extractvalue { i32, i32 } %13, 1    ; IR: extractvalue %13, 1  (handle; classical)
  call void @cq_template_fadd_f64_unc(i32 %12, i32 %7, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %8, double 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  %16 = call double @cqrt_measure_f64(i32 %14)    ; IR: %16 = cq_measure_f64(%14)
  %17 = call double @cqrt_measure_f64(i32 %15)    ; IR: %17 = cq_measure_f64(%15)
  %18 = fadd double %16, %17    ; IR: %18 = fadd %16, %17  (two outcomes)  (classical)
  ret double %18    ; IR: ret double %18
}

define internal fastcc { i32, i32 } @__cq_q___muldc3_1000(i32 %0, double %1, double %2, double %3) {
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %2)    ; IR: %5 = fmul a, c  (ac)
  %6 = fmul double %1, %3    ; IR: %6 = fmul b, d  (bd)  (classical)
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %3)    ; IR: %7 = fmul a, d  (ad)
  %8 = fmul double %1, %2    ; IR: %8 = fmul b, c  (bc)  (classical)
  %9 = call i32 @cq_template_fsub_f64_hl(i32 %5, double %6)    ; IR: %9 = fsub %5, %6  (ac - bd)
  %10 = call i32 @cq_template_fadd_f64_hl(i32 %7, double %8)    ; IR: %10 = fadd %8, %7  (ad + bc; commutative, handle first)
  %11 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %9, double 0.000000e+00)    ; IR: %11 = fcmp uno %9, 0  (isnan(real))
  %12 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %10, double 0.000000e+00)    ; IR: %12 = fcmp uno %10, 0  (isnan(imag))
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = and i1 %11, %12  [br %13 -> block %14 (recover), else exit %99]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %13)    ; IR: %13 = and i1 %11, %12  [br %13 -> block %14 (recover), else exit %99]
  %14 = call i32 @cq_template_fabs_f64(i32 %0)    ; IR: %15 = fabs(a)  (block %14)
  %15 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %14, double 0x7FF0000000000000)    ; IR: %16 = fcmp oeq %15, inf  (isinf(a); a flag read as data by %21 too)
  %16 = tail call double @llvm.fabs.f64(double %1)    ; IR: %17 = fabs(b)  (classical)
  %17 = fcmp oeq double %16, 0x7FF0000000000000    ; IR: %18 = fcmp oeq %17, inf  (isinf(b))  (classical)
  %18 = call i32 @cqrt_alloc_i1(i1 %17)    ; IR: %19 = or i1 %16, %18: the classical disjunct %18  [the classical conjunct as a seed rail, rule 7]
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %16, %18  [br %19 -> block %20, else %31]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %15, i32 %18, i32 %19)    ; IR: %19 = or i1 %16, %18  [br %19 -> block %20, else %31]
  %20 = call i32 @cq_template_uitofp_i1_to_f64(i32 %15)    ; IR: %21 = uitofp i1 %16 to double  (block %20)
  %21 = call i32 @cq_template_copysign_f64(i32 %20, i32 %0)    ; IR: %22 = copysign(%21, a)
  %22 = uitofp i1 %17 to double    ; IR: %23 = uitofp i1 %18 to double  (classical)
  %23 = tail call double @llvm.copysign.f64(double %22, double %1)    ; IR: %24 = copysign(%23, b)  (classical)
  %24 = fcmp uno double %2, 0.000000e+00    ; IR: %25 = fcmp uno c, 0  (classical)
  %25 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %2)    ; IR: %26 = copysign(0, c)  (classical)
  %26 = select i1 %24, double %25, double %2    ; IR: %27 = select %25, %26, c  (classical)
  %27 = fcmp uno double %3, 0.000000e+00    ; IR: %28 = fcmp uno d, 0  (classical)
  %28 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %3)    ; IR: %29 = copysign(0, d)  (classical)
  %29 = select i1 %27, double %28, double %3    ; IR: %30 = select %28, %29, d  (classical)
  %30 = call i32 @cq_template_select_f64_ll(i32 %19, double %29, double %3)    ; IR: %32 = phi [ %30, %20 ], [ %3, %14 ]  (d after step 1; two classical arms under a quantum flag)
  %31 = call i32 @cq_template_select_f64_ll(i32 %19, double %26, double %2)    ; IR: %33 = phi [ %27, %20 ], [ %2, %14 ]  (c after step 1)
  %32 = call i32 @cq_template_select_f64_ll(i32 %19, double %23, double %1)    ; IR: %34 = phi [ %24, %20 ], [ %1, %14 ]  (b after step 1)
  %33 = call i32 @cq_template_select_f64(i32 %19, i32 %21, i32 %0)    ; IR: %35 = phi [ %22, %20 ], [ %0, %14 ]  (a after step 1)
  %34 = call i32 @cq_template_select_i32_ll(i32 %19, i32 1, i32 0)    ; IR: %36 = phi i32 [ 1, %20 ], [ 0, %14 ]  (recalc)
  %35 = call i32 @cq_template_fabs_f64(i32 %31)    ; IR: %37 = fabs(%33)
  %36 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %35, double 0x7FF0000000000000)    ; IR: %38 = fcmp oeq %37, inf  (isinf(c))
  %37 = call i32 @cq_template_fabs_f64(i32 %30)    ; IR: %39 = fabs(%32)
  %38 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %37, double 0x7FF0000000000000)    ; IR: %40 = fcmp oeq %39, inf  (isinf(d))
  %39 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = or i1 %40, %38  [br %41 -> block %42, else %53]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %38, i32 %36, i32 %39)    ; IR: %41 = or i1 %40, %38  [br %41 -> block %42, else %53]
  %40 = call i32 @cq_template_uitofp_i1_to_f64(i32 %36)    ; IR: %43 = uitofp i1 %38 to double  (block %42)
  %41 = call i32 @cq_template_copysign_f64(i32 %40, i32 %31)    ; IR: %44 = copysign(%43, %33)
  %42 = call i32 @cq_template_uitofp_i1_to_f64(i32 %38)    ; IR: %45 = uitofp i1 %40 to double
  %43 = call i32 @cq_template_copysign_f64(i32 %42, i32 %30)    ; IR: %46 = copysign(%45, %32)
  %44 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %33, double 0.000000e+00)    ; IR: %47 = fcmp uno %35, 0
  %45 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %33)    ; IR: %48 = copysign(0, %35)
  %46 = call i32 @cq_template_select_f64(i32 %44, i32 %45, i32 %33)    ; IR: %49 = select %47, %48, %35
  %47 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %32, double 0.000000e+00)    ; IR: %50 = fcmp uno %34, 0
  %48 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %32)    ; IR: %51 = copysign(0, %34)
  %49 = call i32 @cq_template_select_f64(i32 %47, i32 %48, i32 %32)    ; IR: %52 = select %50, %51, %34
  %50 = call i32 @cq_template_select_f64(i32 %39, i32 %43, i32 %30)    ; IR: %54 = phi [ %46, %42 ], [ %32, %31 ]  (d after step 2)
  %51 = call i32 @cq_template_select_f64(i32 %39, i32 %41, i32 %31)    ; IR: %55 = phi [ %44, %42 ], [ %33, %31 ]  (c after step 2)
  %52 = call i32 @cq_template_select_f64(i32 %39, i32 %49, i32 %32)    ; IR: %56 = phi [ %52, %42 ], [ %34, %31 ]  (b after step 2)
  %53 = call i32 @cq_template_select_f64(i32 %39, i32 %46, i32 %33)    ; IR: %57 = phi [ %49, %42 ], [ %35, %31 ]  (a after step 2)
  %54 = call i32 @cq_template_select_i32_lh(i32 %39, i32 1, i32 %34)    ; IR: %58 = phi i32 [ 1, %42 ], [ %36, %31 ]  (recalc)
  %55 = call i32 @cq_template_icmp_eq_i32_hl(i32 %54, i32 0)    ; IR: %59 = icmp eq %58, 0  (!recalc)  [br %59 -> block %60, else %85]
  %56 = call i32 @cq_template_fabs_f64(i32 %5)    ; IR: %61 = fabs(%5)  (block %60)
  %57 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %56, double 0x7FF0000000000000)    ; IR: %62 = fcmp oeq %61, inf  (isinf(ac))
  %58 = tail call double @llvm.fabs.f64(double %6)    ; IR: %63 = fabs(%6)  (classical)
  %59 = fcmp oeq double %58, 0x7FF0000000000000    ; IR: %64 = fcmp oeq %63, inf  (isinf(bd))  (classical)
  %60 = call i32 @cqrt_alloc_i1(i1 %59)    ; IR: %65 = or i1 %62, %64: the classical disjunct %64  [the classical conjunct as a seed rail, rule 7]
  %61 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %57, i32 %60, i32 %61)    ; IR: %65 = or i1 %62, %64
  %62 = call i32 @cq_template_fabs_f64(i32 %7)    ; IR: %66 = fabs(%7)
  %63 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %62, double 0x7FF0000000000000)    ; IR: %67 = fcmp oeq %66, inf  (isinf(ad))
  %64 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %63, i32 %61, i32 %64)    ; IR: %68 = or i1 %67, %65
  %65 = tail call double @llvm.fabs.f64(double %8)    ; IR: %69 = fabs(%8)  (classical)
  %66 = fcmp oeq double %65, 0x7FF0000000000000    ; IR: %70 = fcmp oeq %69, inf  (isinf(bc))  (classical)
  %67 = call i32 @cqrt_alloc_i1(i1 %66)    ; IR: %71 = or i1 %70, %68: the classical disjunct %70  [the classical conjunct as a seed rail, rule 7]
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %71 = or i1 %70, %68  [br %71 -> block %72, else %85]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %64, i32 %67, i32 %68)    ; IR: %71 = or i1 %70, %68  [br %71 -> block %72, else %85]
  %69 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %53, double 0.000000e+00)    ; IR: %73 = fcmp uno %57, 0  (block %72)
  %70 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %53)    ; IR: %74 = copysign(0, %57)
  %71 = call i32 @cq_template_select_f64(i32 %69, i32 %70, i32 %53)    ; IR: %75 = select %73, %74, %57
  %72 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %52, double 0.000000e+00)    ; IR: %76 = fcmp uno %56, 0
  %73 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %52)    ; IR: %77 = copysign(0, %56)
  %74 = call i32 @cq_template_select_f64(i32 %72, i32 %73, i32 %52)    ; IR: %78 = select %76, %77, %56
  %75 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %51, double 0.000000e+00)    ; IR: %79 = fcmp uno %55, 0
  %76 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %51)    ; IR: %80 = copysign(0, %55)
  %77 = call i32 @cq_template_select_f64(i32 %75, i32 %76, i32 %51)    ; IR: %81 = select %79, %80, %55
  %78 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %50, double 0.000000e+00)    ; IR: %82 = fcmp uno %54, 0
  %79 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %50)    ; IR: %83 = copysign(0, %54)
  %80 = call i32 @cq_template_select_f64(i32 %78, i32 %79, i32 %50)    ; IR: %84 = select %82, %83, %54
  %81 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72: %59 & %71  (the phis of %85 take the %72 value under it, the %53 and %60 edges agree)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %55, i32 %68, i32 %81)    ; IR: P72 = path predicate of block %72: %59 & %71  (the phis of %85 take the %72 value under it, the %53 and %60 edges agree)
  %82 = call i32 @cq_template_select_f64(i32 %81, i32 %80, i32 %50)    ; IR: %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (d after step 3)
  %83 = call i32 @cq_template_select_f64(i32 %81, i32 %77, i32 %51)    ; IR: %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]  (c after step 3)
  %84 = call i32 @cq_template_select_f64(i32 %81, i32 %74, i32 %52)    ; IR: %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]  (b after step 3)
  %85 = call i32 @cq_template_select_f64(i32 %81, i32 %71, i32 %53)    ; IR: %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]  (a after step 3)
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket: %90 reads NOT %68
  %86 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [br %90 -> exit %99, else block %91]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %55, i32 %68, i32 %86)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [br %90 -> exit %99, else block %91]
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket (close): %90 reads NOT %68
  %87 = call i32 @cq_template_fneg_f64(i32 %84)    ; IR: %92 = fneg %88  (block %91)
  %88 = call i32 @cq_template_fmul_f64(i32 %82, i32 %87)    ; IR: %93 = fmul %86, %92
  %89 = call i32 @cq_template_fmul_f64(i32 %85, i32 %83)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused product]
  %90 = call i32 @cq_template_fadd_f64(i32 %89, i32 %88)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %91 = call i32 @cq_template_fmul_f64_hl(i32 %90, double 0x7FF0000000000000)    ; IR: %95 = fmul %94, inf  (real result of the recovery)
  %92 = call i32 @cq_template_fmul_f64(i32 %83, i32 %84)    ; IR: %96 = fmul %87, %88
  %93 = call i32 @cq_template_fmul_f64(i32 %85, i32 %82)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused product]
  %94 = call i32 @cq_template_fadd_f64(i32 %93, i32 %92)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %95 = call i32 @cq_template_fmul_f64_hl(i32 %94, double 0x7FF0000000000000)    ; IR: %98 = fmul %97, inf  (imaginary result of the recovery)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket: P91 reads NOT %86
  %96 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P91 = path predicate of block %91: %13 & !%90  (the %4 and %85 edges keep the plain products)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %86, i32 %96)    ; IR: P91 = path predicate of block %91: %13 & !%90  (the %4 and %85 edges keep the plain products)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket (close): P91 reads NOT %86
  %97 = call i32 @cq_template_select_f64(i32 %96, i32 %95, i32 %10)    ; IR: %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  %98 = call i32 @cq_template_select_f64(i32 %96, i32 %91, i32 %9)    ; IR: %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  %99 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f64(i32 %98, i32 %99)    ; IR: copy real (%101) out
  %100 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %97, i32 %100)    ; IR: copy imaginary (%100) out
  call void @cq_template_select_f64_unc(i32 %98, i32 %96, i32 %91, i32 %9)    ; IR: uncompute %101
  call void @cqrt_free(i32 %98)    ; IR: release the %101 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %97, i32 %96, i32 %95, i32 %10)    ; IR: uncompute %100
  call void @cqrt_free(i32 %97)    ; IR: release the %100 rail (|0>)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket: P91 reads NOT %86
  call void @cqrt_and_i1(i32 %13, i32 %86, i32 %96)    ; IR: uncompute P91  [self-inverse]
  call void @cqrt_free(i32 %96)    ; IR: release the P91 rail (|0>)
  call void @cqrt_not_i1(i32 %86)    ; IR: bracket (close): P91 reads NOT %86
  call void @cq_template_fmul_f64_hl_unc(i32 %95, i32 %94, double 0x7FF0000000000000)    ; IR: uncompute %98
  call void @cqrt_free(i32 %95)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %94, i32 %93, i32 %92)    ; IR: uncompute %97
  call void @cqrt_free(i32 %94)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %93, i32 %85, i32 %82)    ; IR: uncompute %97
  call void @cqrt_free(i32 %93)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %92, i32 %83, i32 %84)    ; IR: uncompute %96
  call void @cqrt_free(i32 %92)    ; IR: release the %96 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %91, i32 %90, double 0x7FF0000000000000)    ; IR: uncompute %95
  call void @cqrt_free(i32 %91)    ; IR: release the %95 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %90, i32 %89, i32 %88)    ; IR: uncompute %94
  call void @cqrt_free(i32 %90)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %89, i32 %85, i32 %83)    ; IR: uncompute %94
  call void @cqrt_free(i32 %89)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %88, i32 %82, i32 %87)    ; IR: uncompute %93
  call void @cqrt_free(i32 %88)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %87, i32 %84)    ; IR: uncompute %92
  call void @cqrt_free(i32 %87)    ; IR: release the %92 rail (|0>)
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket: %90 reads NOT %68
  call void @cqrt_and_i1(i32 %55, i32 %68, i32 %86)    ; IR: uncompute %90  [self-inverse]
  call void @cqrt_free(i32 %86)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %68)    ; IR: bracket (close): %90 reads NOT %68
  call void @cq_template_select_f64_unc(i32 %85, i32 %81, i32 %71, i32 %53)    ; IR: uncompute %89
  call void @cqrt_free(i32 %85)    ; IR: release the %89 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %84, i32 %81, i32 %74, i32 %52)    ; IR: uncompute %88
  call void @cqrt_free(i32 %84)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %83, i32 %81, i32 %77, i32 %51)    ; IR: uncompute %87
  call void @cqrt_free(i32 %83)    ; IR: release the %87 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %81, i32 %80, i32 %50)    ; IR: uncompute %86
  call void @cqrt_free(i32 %82)    ; IR: release the %86 rail (|0>)
  call void @cqrt_and_i1(i32 %55, i32 %68, i32 %81)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %81)    ; IR: release the P72 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %80, i32 %78, i32 %79, i32 %50)    ; IR: uncompute %84
  call void @cqrt_free(i32 %80)    ; IR: release the %84 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %79, double 0.000000e+00, i32 %50)    ; IR: uncompute %83
  call void @cqrt_free(i32 %79)    ; IR: release the %83 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %78, i32 %50, double 0.000000e+00)    ; IR: uncompute %82
  call void @cqrt_free(i32 %78)    ; IR: release the %82 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %77, i32 %75, i32 %76, i32 %51)    ; IR: uncompute %81
  call void @cqrt_free(i32 %77)    ; IR: release the %81 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %76, double 0.000000e+00, i32 %51)    ; IR: uncompute %80
  call void @cqrt_free(i32 %76)    ; IR: release the %80 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %75, i32 %51, double 0.000000e+00)    ; IR: uncompute %79
  call void @cqrt_free(i32 %75)    ; IR: release the %79 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %74, i32 %72, i32 %73, i32 %52)    ; IR: uncompute %78
  call void @cqrt_free(i32 %74)    ; IR: release the %78 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %73, double 0.000000e+00, i32 %52)    ; IR: uncompute %77
  call void @cqrt_free(i32 %73)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %72, i32 %52, double 0.000000e+00)    ; IR: uncompute %76
  call void @cqrt_free(i32 %72)    ; IR: release the %76 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %71, i32 %69, i32 %70, i32 %53)    ; IR: uncompute %75
  call void @cqrt_free(i32 %71)    ; IR: release the %75 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %70, double 0.000000e+00, i32 %53)    ; IR: uncompute %74
  call void @cqrt_free(i32 %70)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %69, i32 %53, double 0.000000e+00)    ; IR: uncompute %73
  call void @cqrt_free(i32 %69)    ; IR: release the %73 rail (|0>)
  call void @cqrt_or_i1(i32 %64, i32 %67, i32 %68)    ; IR: uncompute %71  [self-inverse]
  call void @cqrt_free(i32 %68)    ; IR: release the %71 rail (|0>)
  call void @cqrt_free(i32 %67)    ; IR: release the seed rail of %71 (basis state)
  call void @cqrt_or_i1(i32 %63, i32 %61, i32 %64)    ; IR: uncompute %68  [self-inverse]
  call void @cqrt_free(i32 %64)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %63, i32 %62, double 0x7FF0000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %63)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %62, i32 %7)    ; IR: uncompute %66
  call void @cqrt_free(i32 %62)    ; IR: release the %66 rail (|0>)
  call void @cqrt_or_i1(i32 %57, i32 %60, i32 %61)    ; IR: uncompute %65  [self-inverse]
  call void @cqrt_free(i32 %61)    ; IR: release the %65 rail (|0>)
  call void @cqrt_free(i32 %60)    ; IR: release the seed rail of %65 (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %57, i32 %56, double 0x7FF0000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %57)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %56, i32 %5)    ; IR: uncompute %61
  call void @cqrt_free(i32 %56)    ; IR: release the %61 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %55, i32 %54, i32 0)    ; IR: uncompute %59
  call void @cqrt_free(i32 %55)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %54, i32 %39, i32 1, i32 %34)    ; IR: uncompute %58
  call void @cqrt_free(i32 %54)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %53, i32 %39, i32 %46, i32 %33)    ; IR: uncompute %57
  call void @cqrt_free(i32 %53)    ; IR: release the %57 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %52, i32 %39, i32 %49, i32 %32)    ; IR: uncompute %56
  call void @cqrt_free(i32 %52)    ; IR: release the %56 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %51, i32 %39, i32 %41, i32 %31)    ; IR: uncompute %55
  call void @cqrt_free(i32 %51)    ; IR: release the %55 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %50, i32 %39, i32 %43, i32 %30)    ; IR: uncompute %54
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %49, i32 %47, i32 %48, i32 %32)    ; IR: uncompute %52
  call void @cqrt_free(i32 %49)    ; IR: release the %52 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %48, double 0.000000e+00, i32 %32)    ; IR: uncompute %51
  call void @cqrt_free(i32 %48)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %47, i32 %32, double 0.000000e+00)    ; IR: uncompute %50
  call void @cqrt_free(i32 %47)    ; IR: release the %50 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %46, i32 %44, i32 %45, i32 %33)    ; IR: uncompute %49
  call void @cqrt_free(i32 %46)    ; IR: release the %49 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %45, double 0.000000e+00, i32 %33)    ; IR: uncompute %48
  call void @cqrt_free(i32 %45)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %44, i32 %33, double 0.000000e+00)    ; IR: uncompute %47
  call void @cqrt_free(i32 %44)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %43, i32 %42, i32 %30)    ; IR: uncompute %46
  call void @cqrt_free(i32 %43)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %42, i32 %38)    ; IR: uncompute %45
  call void @cqrt_free(i32 %42)    ; IR: release the %45 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %41, i32 %40, i32 %31)    ; IR: uncompute %44
  call void @cqrt_free(i32 %41)    ; IR: release the %44 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %40, i32 %36)    ; IR: uncompute %43
  call void @cqrt_free(i32 %40)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %38, i32 %36, i32 %39)    ; IR: uncompute %41  [self-inverse]
  call void @cqrt_free(i32 %39)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %38, i32 %37, double 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %38)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %37, i32 %30)    ; IR: uncompute %39
  call void @cqrt_free(i32 %37)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %36, i32 %35, double 0x7FF0000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %36)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %35, i32 %31)    ; IR: uncompute %37
  call void @cqrt_free(i32 %35)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %34, i32 %19, i32 1, i32 0)    ; IR: uncompute %36
  call void @cqrt_free(i32 %34)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %19, i32 %21, i32 %0)    ; IR: uncompute %35
  call void @cqrt_free(i32 %33)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %32, i32 %19, double %23, double %1)    ; IR: uncompute %34
  call void @cqrt_free(i32 %32)    ; IR: release the %34 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %31, i32 %19, double %26, double %2)    ; IR: uncompute %33
  call void @cqrt_free(i32 %31)    ; IR: release the %33 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %30, i32 %19, double %29, double %3)    ; IR: uncompute %32
  call void @cqrt_free(i32 %30)    ; IR: release the %32 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %21, i32 %20, i32 %0)    ; IR: uncompute %22
  call void @cqrt_free(i32 %21)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %20, i32 %15)    ; IR: uncompute %21
  call void @cqrt_free(i32 %20)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %15, i32 %18, i32 %19)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cqrt_free(i32 %18)    ; IR: release the seed rail of %19 (basis state)
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
  call void @cq_template_fadd_f64_hl_unc(i32 %10, i32 %7, double %8)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f64_hl_unc(i32 %9, i32 %5, double %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %0, double %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %0, double %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %101 = insertvalue { i32, i32 } poison, i32 %99, 0    ; IR: ret: field 0 (handle, real)
  %102 = insertvalue { i32, i32 } %101, i32 %100, 1    ; IR: ret: field 1 (handle, imaginary)
  ret { i32, i32 } %102    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc void @__cq_q___muldc3_1000_unc(i32 %0, i32 %1, i32 %2, double %3, double %4, double %5) {
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %4)    ; IR: %5 = fmul a, c  (ac)
  %8 = fmul double %3, %5    ; IR: %6 = fmul b, d  (bd)  (classical)
  %9 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %5)    ; IR: %7 = fmul a, d  (ad)
  %10 = fmul double %3, %4    ; IR: %8 = fmul b, c  (bc)  (classical)
  %11 = call i32 @cq_template_fsub_f64_hl(i32 %7, double %8)    ; IR: %9 = fsub %5, %6  (ac - bd)
  %12 = call i32 @cq_template_fadd_f64_hl(i32 %9, double %10)    ; IR: %10 = fadd %8, %7  (ad + bc; commutative, handle first)
  %13 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %11, double 0.000000e+00)    ; IR: %11 = fcmp uno %9, 0  (isnan(real))
  %14 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %12, double 0.000000e+00)    ; IR: %12 = fcmp uno %10, 0  (isnan(imag))
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %13 = and i1 %11, %12  [br %13 -> block %14 (recover), else exit %99]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %13, i32 %14, i32 %15)    ; IR: %13 = and i1 %11, %12  [br %13 -> block %14 (recover), else exit %99]
  %16 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %15 = fabs(a)  (block %14)
  %17 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %16, double 0x7FF0000000000000)    ; IR: %16 = fcmp oeq %15, inf  (isinf(a); a flag read as data by %21 too)
  %18 = tail call double @llvm.fabs.f64(double %3)    ; IR: %17 = fabs(b)  (classical)
  %19 = fcmp oeq double %18, 0x7FF0000000000000    ; IR: %18 = fcmp oeq %17, inf  (isinf(b))  (classical)
  %20 = call i32 @cqrt_alloc_i1(i1 %19)    ; IR: %19 = or i1 %16, %18: the classical disjunct %18  [the classical conjunct as a seed rail, rule 7]
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = or i1 %16, %18  [br %19 -> block %20, else %31]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %17, i32 %20, i32 %21)    ; IR: %19 = or i1 %16, %18  [br %19 -> block %20, else %31]
  %22 = call i32 @cq_template_uitofp_i1_to_f64(i32 %17)    ; IR: %21 = uitofp i1 %16 to double  (block %20)
  %23 = call i32 @cq_template_copysign_f64(i32 %22, i32 %2)    ; IR: %22 = copysign(%21, a)
  %24 = uitofp i1 %19 to double    ; IR: %23 = uitofp i1 %18 to double  (classical)
  %25 = tail call double @llvm.copysign.f64(double %24, double %3)    ; IR: %24 = copysign(%23, b)  (classical)
  %26 = fcmp uno double %4, 0.000000e+00    ; IR: %25 = fcmp uno c, 0  (classical)
  %27 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %4)    ; IR: %26 = copysign(0, c)  (classical)
  %28 = select i1 %26, double %27, double %4    ; IR: %27 = select %25, %26, c  (classical)
  %29 = fcmp uno double %5, 0.000000e+00    ; IR: %28 = fcmp uno d, 0  (classical)
  %30 = tail call double @llvm.copysign.f64(double 0.000000e+00, double %5)    ; IR: %29 = copysign(0, d)  (classical)
  %31 = select i1 %29, double %30, double %5    ; IR: %30 = select %28, %29, d  (classical)
  %32 = call i32 @cq_template_select_f64_ll(i32 %21, double %31, double %5)    ; IR: %32 = phi [ %30, %20 ], [ %3, %14 ]  (d after step 1; two classical arms under a quantum flag)
  %33 = call i32 @cq_template_select_f64_ll(i32 %21, double %28, double %4)    ; IR: %33 = phi [ %27, %20 ], [ %2, %14 ]  (c after step 1)
  %34 = call i32 @cq_template_select_f64_ll(i32 %21, double %25, double %3)    ; IR: %34 = phi [ %24, %20 ], [ %1, %14 ]  (b after step 1)
  %35 = call i32 @cq_template_select_f64(i32 %21, i32 %23, i32 %2)    ; IR: %35 = phi [ %22, %20 ], [ %0, %14 ]  (a after step 1)
  %36 = call i32 @cq_template_select_i32_ll(i32 %21, i32 1, i32 0)    ; IR: %36 = phi i32 [ 1, %20 ], [ 0, %14 ]  (recalc)
  %37 = call i32 @cq_template_fabs_f64(i32 %33)    ; IR: %37 = fabs(%33)
  %38 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %37, double 0x7FF0000000000000)    ; IR: %38 = fcmp oeq %37, inf  (isinf(c))
  %39 = call i32 @cq_template_fabs_f64(i32 %32)    ; IR: %39 = fabs(%32)
  %40 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %39, double 0x7FF0000000000000)    ; IR: %40 = fcmp oeq %39, inf  (isinf(d))
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = or i1 %40, %38  [br %41 -> block %42, else %53]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %40, i32 %38, i32 %41)    ; IR: %41 = or i1 %40, %38  [br %41 -> block %42, else %53]
  %42 = call i32 @cq_template_uitofp_i1_to_f64(i32 %38)    ; IR: %43 = uitofp i1 %38 to double  (block %42)
  %43 = call i32 @cq_template_copysign_f64(i32 %42, i32 %33)    ; IR: %44 = copysign(%43, %33)
  %44 = call i32 @cq_template_uitofp_i1_to_f64(i32 %40)    ; IR: %45 = uitofp i1 %40 to double
  %45 = call i32 @cq_template_copysign_f64(i32 %44, i32 %32)    ; IR: %46 = copysign(%45, %32)
  %46 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %35, double 0.000000e+00)    ; IR: %47 = fcmp uno %35, 0
  %47 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %35)    ; IR: %48 = copysign(0, %35)
  %48 = call i32 @cq_template_select_f64(i32 %46, i32 %47, i32 %35)    ; IR: %49 = select %47, %48, %35
  %49 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %34, double 0.000000e+00)    ; IR: %50 = fcmp uno %34, 0
  %50 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %34)    ; IR: %51 = copysign(0, %34)
  %51 = call i32 @cq_template_select_f64(i32 %49, i32 %50, i32 %34)    ; IR: %52 = select %50, %51, %34
  %52 = call i32 @cq_template_select_f64(i32 %41, i32 %45, i32 %32)    ; IR: %54 = phi [ %46, %42 ], [ %32, %31 ]  (d after step 2)
  %53 = call i32 @cq_template_select_f64(i32 %41, i32 %43, i32 %33)    ; IR: %55 = phi [ %44, %42 ], [ %33, %31 ]  (c after step 2)
  %54 = call i32 @cq_template_select_f64(i32 %41, i32 %51, i32 %34)    ; IR: %56 = phi [ %52, %42 ], [ %34, %31 ]  (b after step 2)
  %55 = call i32 @cq_template_select_f64(i32 %41, i32 %48, i32 %35)    ; IR: %57 = phi [ %49, %42 ], [ %35, %31 ]  (a after step 2)
  %56 = call i32 @cq_template_select_i32_lh(i32 %41, i32 1, i32 %36)    ; IR: %58 = phi i32 [ 1, %42 ], [ %36, %31 ]  (recalc)
  %57 = call i32 @cq_template_icmp_eq_i32_hl(i32 %56, i32 0)    ; IR: %59 = icmp eq %58, 0  (!recalc)  [br %59 -> block %60, else %85]
  %58 = call i32 @cq_template_fabs_f64(i32 %7)    ; IR: %61 = fabs(%5)  (block %60)
  %59 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %58, double 0x7FF0000000000000)    ; IR: %62 = fcmp oeq %61, inf  (isinf(ac))
  %60 = tail call double @llvm.fabs.f64(double %8)    ; IR: %63 = fabs(%6)  (classical)
  %61 = fcmp oeq double %60, 0x7FF0000000000000    ; IR: %64 = fcmp oeq %63, inf  (isinf(bd))  (classical)
  %62 = call i32 @cqrt_alloc_i1(i1 %61)    ; IR: %65 = or i1 %62, %64: the classical disjunct %64  [the classical conjunct as a seed rail, rule 7]
  %63 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = or i1 %62, %64  [fresh flag rail]
  call void @cqrt_or_i1(i32 %59, i32 %62, i32 %63)    ; IR: %65 = or i1 %62, %64
  %64 = call i32 @cq_template_fabs_f64(i32 %9)    ; IR: %66 = fabs(%7)
  %65 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %64, double 0x7FF0000000000000)    ; IR: %67 = fcmp oeq %66, inf  (isinf(ad))
  %66 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %68 = or i1 %67, %65  [fresh flag rail]
  call void @cqrt_or_i1(i32 %65, i32 %63, i32 %66)    ; IR: %68 = or i1 %67, %65
  %67 = tail call double @llvm.fabs.f64(double %10)    ; IR: %69 = fabs(%8)  (classical)
  %68 = fcmp oeq double %67, 0x7FF0000000000000    ; IR: %70 = fcmp oeq %69, inf  (isinf(bc))  (classical)
  %69 = call i32 @cqrt_alloc_i1(i1 %68)    ; IR: %71 = or i1 %70, %68: the classical disjunct %70  [the classical conjunct as a seed rail, rule 7]
  %70 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %71 = or i1 %70, %68  [br %71 -> block %72, else %85]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %66, i32 %69, i32 %70)    ; IR: %71 = or i1 %70, %68  [br %71 -> block %72, else %85]
  %71 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %55, double 0.000000e+00)    ; IR: %73 = fcmp uno %57, 0  (block %72)
  %72 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %55)    ; IR: %74 = copysign(0, %57)
  %73 = call i32 @cq_template_select_f64(i32 %71, i32 %72, i32 %55)    ; IR: %75 = select %73, %74, %57
  %74 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %54, double 0.000000e+00)    ; IR: %76 = fcmp uno %56, 0
  %75 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %54)    ; IR: %77 = copysign(0, %56)
  %76 = call i32 @cq_template_select_f64(i32 %74, i32 %75, i32 %54)    ; IR: %78 = select %76, %77, %56
  %77 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %53, double 0.000000e+00)    ; IR: %79 = fcmp uno %55, 0
  %78 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %53)    ; IR: %80 = copysign(0, %55)
  %79 = call i32 @cq_template_select_f64(i32 %77, i32 %78, i32 %53)    ; IR: %81 = select %79, %80, %55
  %80 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %52, double 0.000000e+00)    ; IR: %82 = fcmp uno %54, 0
  %81 = call i32 @cq_template_copysign_f64_lh(double 0.000000e+00, i32 %52)    ; IR: %83 = copysign(0, %54)
  %82 = call i32 @cq_template_select_f64(i32 %80, i32 %81, i32 %52)    ; IR: %84 = select %82, %83, %54
  %83 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P72 = path predicate of block %72: %59 & %71  (the phis of %85 take the %72 value under it, the %53 and %60 edges agree)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %57, i32 %70, i32 %83)    ; IR: P72 = path predicate of block %72: %59 & %71  (the phis of %85 take the %72 value under it, the %53 and %60 edges agree)
  %84 = call i32 @cq_template_select_f64(i32 %83, i32 %82, i32 %52)    ; IR: %86 = phi [ %54, %53 ], [ %84, %72 ], [ %54, %60 ]  (d after step 3)
  %85 = call i32 @cq_template_select_f64(i32 %83, i32 %79, i32 %53)    ; IR: %87 = phi [ %55, %53 ], [ %81, %72 ], [ %55, %60 ]  (c after step 3)
  %86 = call i32 @cq_template_select_f64(i32 %83, i32 %76, i32 %54)    ; IR: %88 = phi [ %56, %53 ], [ %78, %72 ], [ %56, %60 ]  (b after step 3)
  %87 = call i32 @cq_template_select_f64(i32 %83, i32 %73, i32 %55)    ; IR: %89 = phi [ %57, %53 ], [ %75, %72 ], [ %57, %60 ]  (a after step 3)
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket: %90 reads NOT %70
  %88 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [br %90 -> exit %99, else block %91]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %57, i32 %70, i32 %88)    ; IR: %90 = phi i1 [ false, %53 ], [ false, %72 ], [ true, %60 ] = %59 & !%71  [br %90 -> exit %99, else block %91]
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket (close): %90 reads NOT %70
  %89 = call i32 @cq_template_fneg_f64(i32 %86)    ; IR: %92 = fneg %88  (block %91)
  %90 = call i32 @cq_template_fmul_f64(i32 %84, i32 %89)    ; IR: %93 = fmul %86, %92
  %91 = call i32 @cq_template_fmul_f64(i32 %87, i32 %85)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused product]
  %92 = call i32 @cq_template_fadd_f64(i32 %91, i32 %90)    ; IR: %94 = fmuladd(%89, %87, %93)  [unfused sum]
  %93 = call i32 @cq_template_fmul_f64_hl(i32 %92, double 0x7FF0000000000000)    ; IR: %95 = fmul %94, inf  (real result of the recovery)
  %94 = call i32 @cq_template_fmul_f64(i32 %85, i32 %86)    ; IR: %96 = fmul %87, %88
  %95 = call i32 @cq_template_fmul_f64(i32 %87, i32 %84)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused product]
  %96 = call i32 @cq_template_fadd_f64(i32 %95, i32 %94)    ; IR: %97 = fmuladd(%89, %86, %96)  [unfused sum]
  %97 = call i32 @cq_template_fmul_f64_hl(i32 %96, double 0x7FF0000000000000)    ; IR: %98 = fmul %97, inf  (imaginary result of the recovery)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket: P91 reads NOT %88
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P91 = path predicate of block %91: %13 & !%90  (the %4 and %85 edges keep the plain products)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %15, i32 %88, i32 %98)    ; IR: P91 = path predicate of block %91: %13 & !%90  (the %4 and %85 edges keep the plain products)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket (close): P91 reads NOT %88
  %99 = call i32 @cq_template_select_f64(i32 %98, i32 %97, i32 %12)    ; IR: %100 = phi [ %10, %4 ], [ %98, %91 ], [ %10, %85 ]  (imaginary result)
  %100 = call i32 @cq_template_select_f64(i32 %98, i32 %93, i32 %11)    ; IR: %101 = phi [ %9, %4 ], [ %95, %91 ], [ %9, %85 ]  (real result)
  call void @cqrt_copy_f64(i32 %100, i32 %0)    ; IR: xor real (%101) out of the result rail
  call void @cqrt_copy_f64(i32 %99, i32 %1)    ; IR: xor imaginary (%100) out of the result rail
  call void @cq_template_select_f64_unc(i32 %100, i32 %98, i32 %93, i32 %11)    ; IR: uncompute %101
  call void @cqrt_free(i32 %100)    ; IR: release the %101 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %99, i32 %98, i32 %97, i32 %12)    ; IR: uncompute %100
  call void @cqrt_free(i32 %99)    ; IR: release the %100 rail (|0>)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket: P91 reads NOT %88
  call void @cqrt_and_i1(i32 %15, i32 %88, i32 %98)    ; IR: uncompute P91  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release the P91 rail (|0>)
  call void @cqrt_not_i1(i32 %88)    ; IR: bracket (close): P91 reads NOT %88
  call void @cq_template_fmul_f64_hl_unc(i32 %97, i32 %96, double 0x7FF0000000000000)    ; IR: uncompute %98
  call void @cqrt_free(i32 %97)    ; IR: release the %98 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %96, i32 %95, i32 %94)    ; IR: uncompute %97
  call void @cqrt_free(i32 %96)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %95, i32 %87, i32 %84)    ; IR: uncompute %97
  call void @cqrt_free(i32 %95)    ; IR: release the %97 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %94, i32 %85, i32 %86)    ; IR: uncompute %96
  call void @cqrt_free(i32 %94)    ; IR: release the %96 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %93, i32 %92, double 0x7FF0000000000000)    ; IR: uncompute %95
  call void @cqrt_free(i32 %93)    ; IR: release the %95 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %92, i32 %91, i32 %90)    ; IR: uncompute %94
  call void @cqrt_free(i32 %92)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %91, i32 %87, i32 %85)    ; IR: uncompute %94
  call void @cqrt_free(i32 %91)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %90, i32 %84, i32 %89)    ; IR: uncompute %93
  call void @cqrt_free(i32 %90)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %89, i32 %86)    ; IR: uncompute %92
  call void @cqrt_free(i32 %89)    ; IR: release the %92 rail (|0>)
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket: %90 reads NOT %70
  call void @cqrt_and_i1(i32 %57, i32 %70, i32 %88)    ; IR: uncompute %90  [self-inverse]
  call void @cqrt_free(i32 %88)    ; IR: release the %90 rail (|0>)
  call void @cqrt_not_i1(i32 %70)    ; IR: bracket (close): %90 reads NOT %70
  call void @cq_template_select_f64_unc(i32 %87, i32 %83, i32 %73, i32 %55)    ; IR: uncompute %89
  call void @cqrt_free(i32 %87)    ; IR: release the %89 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %86, i32 %83, i32 %76, i32 %54)    ; IR: uncompute %88
  call void @cqrt_free(i32 %86)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %85, i32 %83, i32 %79, i32 %53)    ; IR: uncompute %87
  call void @cqrt_free(i32 %85)    ; IR: release the %87 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %84, i32 %83, i32 %82, i32 %52)    ; IR: uncompute %86
  call void @cqrt_free(i32 %84)    ; IR: release the %86 rail (|0>)
  call void @cqrt_and_i1(i32 %57, i32 %70, i32 %83)    ; IR: uncompute P72  [self-inverse]
  call void @cqrt_free(i32 %83)    ; IR: release the P72 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %80, i32 %81, i32 %52)    ; IR: uncompute %84
  call void @cqrt_free(i32 %82)    ; IR: release the %84 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %81, double 0.000000e+00, i32 %52)    ; IR: uncompute %83
  call void @cqrt_free(i32 %81)    ; IR: release the %83 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %80, i32 %52, double 0.000000e+00)    ; IR: uncompute %82
  call void @cqrt_free(i32 %80)    ; IR: release the %82 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %79, i32 %77, i32 %78, i32 %53)    ; IR: uncompute %81
  call void @cqrt_free(i32 %79)    ; IR: release the %81 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %78, double 0.000000e+00, i32 %53)    ; IR: uncompute %80
  call void @cqrt_free(i32 %78)    ; IR: release the %80 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %77, i32 %53, double 0.000000e+00)    ; IR: uncompute %79
  call void @cqrt_free(i32 %77)    ; IR: release the %79 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %76, i32 %74, i32 %75, i32 %54)    ; IR: uncompute %78
  call void @cqrt_free(i32 %76)    ; IR: release the %78 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %75, double 0.000000e+00, i32 %54)    ; IR: uncompute %77
  call void @cqrt_free(i32 %75)    ; IR: release the %77 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %74, i32 %54, double 0.000000e+00)    ; IR: uncompute %76
  call void @cqrt_free(i32 %74)    ; IR: release the %76 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %73, i32 %71, i32 %72, i32 %55)    ; IR: uncompute %75
  call void @cqrt_free(i32 %73)    ; IR: release the %75 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %72, double 0.000000e+00, i32 %55)    ; IR: uncompute %74
  call void @cqrt_free(i32 %72)    ; IR: release the %74 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %71, i32 %55, double 0.000000e+00)    ; IR: uncompute %73
  call void @cqrt_free(i32 %71)    ; IR: release the %73 rail (|0>)
  call void @cqrt_or_i1(i32 %66, i32 %69, i32 %70)    ; IR: uncompute %71  [self-inverse]
  call void @cqrt_free(i32 %70)    ; IR: release the %71 rail (|0>)
  call void @cqrt_free(i32 %69)    ; IR: release the seed rail of %71 (basis state)
  call void @cqrt_or_i1(i32 %65, i32 %63, i32 %66)    ; IR: uncompute %68  [self-inverse]
  call void @cqrt_free(i32 %66)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %65, i32 %64, double 0x7FF0000000000000)    ; IR: uncompute %67
  call void @cqrt_free(i32 %65)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %64, i32 %9)    ; IR: uncompute %66
  call void @cqrt_free(i32 %64)    ; IR: release the %66 rail (|0>)
  call void @cqrt_or_i1(i32 %59, i32 %62, i32 %63)    ; IR: uncompute %65  [self-inverse]
  call void @cqrt_free(i32 %63)    ; IR: release the %65 rail (|0>)
  call void @cqrt_free(i32 %62)    ; IR: release the seed rail of %65 (basis state)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %59, i32 %58, double 0x7FF0000000000000)    ; IR: uncompute %62
  call void @cqrt_free(i32 %59)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %58, i32 %7)    ; IR: uncompute %61
  call void @cqrt_free(i32 %58)    ; IR: release the %61 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %57, i32 %56, i32 0)    ; IR: uncompute %59
  call void @cqrt_free(i32 %57)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %56, i32 %41, i32 1, i32 %36)    ; IR: uncompute %58
  call void @cqrt_free(i32 %56)    ; IR: release the %58 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %55, i32 %41, i32 %48, i32 %35)    ; IR: uncompute %57
  call void @cqrt_free(i32 %55)    ; IR: release the %57 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %54, i32 %41, i32 %51, i32 %34)    ; IR: uncompute %56
  call void @cqrt_free(i32 %54)    ; IR: release the %56 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %53, i32 %41, i32 %43, i32 %33)    ; IR: uncompute %55
  call void @cqrt_free(i32 %53)    ; IR: release the %55 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %52, i32 %41, i32 %45, i32 %32)    ; IR: uncompute %54
  call void @cqrt_free(i32 %52)    ; IR: release the %54 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %51, i32 %49, i32 %50, i32 %34)    ; IR: uncompute %52
  call void @cqrt_free(i32 %51)    ; IR: release the %52 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %50, double 0.000000e+00, i32 %34)    ; IR: uncompute %51
  call void @cqrt_free(i32 %50)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %49, i32 %34, double 0.000000e+00)    ; IR: uncompute %50
  call void @cqrt_free(i32 %49)    ; IR: release the %50 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %48, i32 %46, i32 %47, i32 %35)    ; IR: uncompute %49
  call void @cqrt_free(i32 %48)    ; IR: release the %49 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %47, double 0.000000e+00, i32 %35)    ; IR: uncompute %48
  call void @cqrt_free(i32 %47)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %46, i32 %35, double 0.000000e+00)    ; IR: uncompute %47
  call void @cqrt_free(i32 %46)    ; IR: release the %47 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %45, i32 %44, i32 %32)    ; IR: uncompute %46
  call void @cqrt_free(i32 %45)    ; IR: release the %46 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %44, i32 %40)    ; IR: uncompute %45
  call void @cqrt_free(i32 %44)    ; IR: release the %45 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %43, i32 %42, i32 %33)    ; IR: uncompute %44
  call void @cqrt_free(i32 %43)    ; IR: release the %44 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %42, i32 %38)    ; IR: uncompute %43
  call void @cqrt_free(i32 %42)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %40, i32 %38, i32 %41)    ; IR: uncompute %41  [self-inverse]
  call void @cqrt_free(i32 %41)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %40, i32 %39, double 0x7FF0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %40)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %39, i32 %32)    ; IR: uncompute %39
  call void @cqrt_free(i32 %39)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %38, i32 %37, double 0x7FF0000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %38)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %37, i32 %33)    ; IR: uncompute %37
  call void @cqrt_free(i32 %37)    ; IR: release the %37 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %36, i32 %21, i32 1, i32 0)    ; IR: uncompute %36
  call void @cqrt_free(i32 %36)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %35, i32 %21, i32 %23, i32 %2)    ; IR: uncompute %35
  call void @cqrt_free(i32 %35)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %34, i32 %21, double %25, double %3)    ; IR: uncompute %34
  call void @cqrt_free(i32 %34)    ; IR: release the %34 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %33, i32 %21, double %28, double %4)    ; IR: uncompute %33
  call void @cqrt_free(i32 %33)    ; IR: release the %33 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %32, i32 %21, double %31, double %5)    ; IR: uncompute %32
  call void @cqrt_free(i32 %32)    ; IR: release the %32 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %23, i32 %22, i32 %2)    ; IR: uncompute %22
  call void @cqrt_free(i32 %23)    ; IR: release the %22 rail (|0>)
  call void @cq_template_uitofp_i1_to_f64_unc(i32 %22, i32 %17)    ; IR: uncompute %21
  call void @cqrt_free(i32 %22)    ; IR: release the %21 rail (|0>)
  call void @cqrt_or_i1(i32 %17, i32 %20, i32 %21)    ; IR: uncompute %19  [self-inverse]
  call void @cqrt_free(i32 %21)    ; IR: release the %19 rail (|0>)
  call void @cqrt_free(i32 %20)    ; IR: release the seed rail of %19 (basis state)
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
  call void @cq_template_fadd_f64_hl_unc(i32 %12, i32 %9, double %10)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fsub_f64_hl_unc(i32 %11, i32 %7, double %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %9, i32 %2, double %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %2, double %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

define internal fastcc { i32, i32 } @__cq_q___divdc3_0011(double %0, double %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %5 = fabs(c)
  %6 = call i32 @cq_template_fabs_f64(i32 %3)    ; IR: %6 = fabs(d)
  %7 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %2, double 0.000000e+00)    ; IR: %7 = fcmp uno c, 0  (isnan(c); fmax inlined)
  %8 = call i32 @cq_template_fcmp_olt_f64(i32 %5, i32 %6)    ; IR: %8 = fcmp olt %5, %6
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %9 = or i1 %7, %8  (the fmax select condition)  [fresh flag rail]
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: %9 = or i1 %7, %8  (the fmax select condition)
  %10 = call i32 @cq_template_select_f64(i32 %9, i32 %6, i32 %5)    ; IR: %10 = select %9, %6, %5  (fmax(|c|, |d|))
  %11 = call i32 @cq_template_bitcast_f64_to_i64(i32 %10)    ; IR: %11 = bitcast %10 to i64  (__compiler_rt_logb inlined)
  %12 = call i32 @cq_template_lshr_i64_hl(i32 %11, i64 52)    ; IR: %12 = lshr %11, 52
  %13 = call i32 @cq_template_trunc_i64_to_i32(i32 %12)    ; IR: %13 = trunc %12 to i32  (biased exponent)
  %14 = call i32 @cq_template_icmp_eq_i64_hl(i32 %12, i64 2047)    ; IR: %14 = icmp eq %12, 2047  (inf or nan: logb = x)  [br %14 -> the merge %34, else block %15]
  %15 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %10, double 0.000000e+00)    ; IR: %16 = fcmp oeq %10, 0  (logb(0) = -inf; block %15)  [br %16 -> %34, else block %17]
  %16 = call i32 @cq_template_icmp_ult_i64_hl(i32 %11, i64 4503599627370496)    ; IR: %18 = icmp ult %11, 0x10000000000000  (subnormal; block %17)  [br %18 -> block %22, else %19]
  %17 = call i32 @cq_template_add_i32_hl(i32 %13, i32 -1023)    ; IR: %20 = add %13, -1023  (block %19: the normal exponent)
  %18 = call i32 @cq_template_sitofp_i32_to_f64(i32 %17)    ; IR: %21 = sitofp %20 to double
  %19 = call i32 @cq_template_ctlz_i64(i32 %11)    ; IR: %23 = ctlz(%11)  (block %22: the subnormal exponent)
  %20 = call i32 @cq_template_trunc_i64_to_i32(i32 %19)    ; IR: %24 = trunc %23 to i32
  %21 = call i32 @cq_template_add_i64_hl(i32 %19, i64 4294967285)    ; IR: %25 = add %23, 4294967285
  %22 = call i32 @cq_template_and_i64_hl(i32 %21, i64 4294967295)    ; IR: %26 = and %25, 4294967295
  %23 = call i32 @cq_template_shl_i64(i32 %11, i32 %22)    ; IR: %27 = shl %11, %26
  %24 = call i32 @cq_template_lshr_i64_hl(i32 %23, i64 52)    ; IR: %28 = lshr %27, 52
  %25 = call i32 @cq_template_trunc_i64_to_i32(i32 %24)    ; IR: %29 = trunc %28 to i32
  %26 = call i32 @cq_template_and_i32_hl(i32 %25, i32 2047)    ; IR: %30 = and %29, 2047
  %27 = call i32 @cq_template_sub_i32(i32 %26, i32 %20)    ; IR: %31 = sub %30, %24
  %28 = call i32 @cq_template_add_i32_hl(i32 %27, i32 -1012)    ; IR: %32 = add %31, -1012
  %29 = call i32 @cq_template_sitofp_i32_to_f64(i32 %28)    ; IR: %33 = sitofp %32 to double
  %30 = call i32 @cq_template_select_f64(i32 %16, i32 %29, i32 %18)    ; IR: %35 = phi [ %21, %19 ], [ %33, %22 ], ...: the %17 subtree on %18
  %31 = call i32 @cq_template_select_f64_lh(i32 %15, double 0xFFF0000000000000, i32 %30)    ; IR: %35 = phi ..., [ -inf, %15 ], ...: the %15 subtree on %16
  %32 = call i32 @cq_template_select_f64(i32 %14, i32 %10, i32 %31)    ; IR: %35 = phi [ %10, %4 ], ...: the top split on %14 (logbw)
  %33 = call i32 @cq_template_fabs_f64(i32 %32)    ; IR: %36 = fabs(%35)
  %34 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %33, double 0x7FF0000000000000)    ; IR: %37 = fcmp ueq %36, inf  (!isfinite(logbw))  [br %37 -> the merge %135 keeps c, d, ilogbw = 0, else block %38]
  %35 = call i32 @cq_template_fptosi_f64_to_i32(i32 %32)    ; IR: %39 = fptosi %35 to i32  (ilogbw; block %38)
  %36 = call i32 @cq_template_sub_i32_lh(i32 0, i32 %35)    ; IR: %40 = sub 0, %39  (-ilogbw)
  %37 = call i32 @cq_template_bitcast_f64_to_i64(i32 %2)    ; IR: %41 = bitcast c to i64  (scalbn(c, %40))
  %38 = call i32 @cq_template_lshr_i64_hl(i32 %37, i64 52)    ; IR: %42 = lshr %41, 52
  %39 = call i32 @cq_template_trunc_i64_to_i32(i32 %38)    ; IR: %43 = trunc %42 to i32
  %40 = call i32 @cq_template_and_i32_hl(i32 %39, i32 2047)    ; IR: %44 = and %43, 2047  (biased exponent)
  %41 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %2, double 0.000000e+00)    ; IR: %45 = fcmp oeq c, 0
  %42 = call i32 @cq_template_icmp_eq_i32_hl(i32 %40, i32 2047)    ; IR: %46 = icmp eq %44, 2047  (inf or nan)
  %43 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %47 = select i1 %45, i1 true, i1 %46 = %45 | %46  [br %47 -> the merge %87 keeps c, else block %48]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %41, i32 %42, i32 %43)    ; IR: %47 = select i1 %45, i1 true, i1 %46 = %45 | %46  [br %47 -> the merge %87 keeps c, else block %48]
  %44 = call i32 @cq_template_and_i64_hl(i32 %37, i64 4503599627370495)    ; IR: %49 = and %41, 0xFFFFFFFFFFFFF  (mantissa; block %48)
  %45 = call i32 @cq_template_icmp_eq_i32_hl(i32 %40, i32 0)    ; IR: %50 = icmp eq %44, 0  (subnormal)  [br %50 -> block %51, else %59]
  %46 = call i32 @cq_template_ctlz_i64(i32 %44)    ; IR: %52 = ctlz(%49)  (block %51: normalise the subnormal)
  %47 = call i32 @cq_template_trunc_i64_to_i32(i32 %46)    ; IR: %53 = trunc %52 to i32
  %48 = call i32 @cq_template_add_i64_hl(i32 %46, i64 4294967285)    ; IR: %54 = add %52, 4294967285  (shift = clz - 11, as the i32 wrap of the bundle)
  %49 = call i32 @cq_template_and_i64_hl(i32 %48, i64 4294967295)    ; IR: %55 = and %54, 4294967295
  %50 = call i32 @cq_template_shl_i64(i32 %44, i32 %49)    ; IR: %56 = shl %49, %55
  %51 = call i32 @cq_template_sub_i32_lh(i32 12, i32 %47)    ; IR: %57 = sub 12, %53  (exponent of the normalised mantissa)
  %52 = call i32 @cq_template_and_i64_hl(i32 %50, i64 -4503599627370497)    ; IR: %58 = and %56, ~0x10000000000000
  %53 = call i32 @cq_template_select_i64(i32 %45, i32 %52, i32 %44)    ; IR: %60 = phi i64 [ %58, %51 ], [ %49, %48 ]  (mantissa)
  %54 = call i32 @cq_template_select_i32(i32 %45, i32 %51, i32 %40)    ; IR: %61 = phi i32 [ %57, %51 ], [ %44, %48 ]  (exponent)
  %55 = call i32 @cq_template_sadd_sat_i32(i32 %54, i32 %36)    ; IR: %62 = llvm.sadd.sat.i32(%61, %40)  (new exponent, saturated)
  %56 = call i32 @cq_template_and_i64_hl(i32 %37, i64 -9223372036854775808)    ; IR: %63 = and %41, 0x8000000000000000  (sign)
  %57 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %55, i32 2046)    ; IR: %64 = icmp sgt %62, 2046  (overflow)  [br %64 -> block %65, else %69]
  %58 = call i32 @cq_template_or_i64_hl(i32 %56, i64 9214364837600034816)    ; IR: %66 = or %63, 0x7FE0000000000000  (block %65: signed 2^1023)
  %59 = call i32 @cq_template_bitcast_i64_to_f64(i32 %58)    ; IR: %67 = bitcast %66 to double
  %60 = call i32 @cq_template_fmul_f64_hl(i32 %59, double 2.000000e+00)    ; IR: %68 = fmul %67, 2.0  (signed inf)
  %61 = call i32 @cq_template_icmp_slt_i32_hl(i32 %55, i32 1)    ; IR: %70 = icmp slt %62, 1  (underflow)  (block %69)  [br %70 -> block %71, else %81]
  %62 = call i32 @cq_template_or_i64(i32 %53, i32 %56)    ; IR: %72 = or %60, %63  (block %71)
  %63 = call i32 @cq_template_or_i64_hl(i32 %62, i64 4503599627370496)    ; IR: %73 = or %72, 0x10000000000000  (exponent 1)
  %64 = call i32 @cq_template_bitcast_i64_to_f64(i32 %63)    ; IR: %74 = bitcast %73 to double
  %65 = call i32 @cq_template_smax_i32_hl(i32 %55, i32 -1021)    ; IR: %75 = llvm.smax.i32(%62, -1021)
  %66 = call i32 @cq_template_add_i32_hl(i32 %65, i32 1022)    ; IR: %76 = add %75, 1022
  %67 = call i32 @cq_template_zext_i32_to_i64(i32 %66)    ; IR: %77 = zext %76 to i64
  %68 = call i32 @cq_template_shl_i64_hl(i32 %67, i64 52)    ; IR: %78 = shl %77, 52
  %69 = call i32 @cq_template_bitcast_i64_to_f64(i32 %68)    ; IR: %79 = bitcast %78 to double  (2^(e - 1))
  %70 = call i32 @cq_template_fmul_f64(i32 %64, i32 %69)    ; IR: %80 = fmul %74, %79  (the subnormal result)
  %71 = call i32 @cq_template_zext_i32_to_i64(i32 %55)    ; IR: %82 = zext %62 to i64  (block %81: the normal result)
  %72 = call i32 @cq_template_shl_i64_hl(i32 %71, i64 52)    ; IR: %83 = shl %82, 52
  %73 = call i32 @cq_template_or_i64(i32 %56, i32 %72)    ; IR: %84 = or %63, %83
  %74 = call i32 @cq_template_or_i64(i32 %73, i32 %53)    ; IR: %85 = or %84, %60
  %75 = call i32 @cq_template_bitcast_i64_to_f64(i32 %74)    ; IR: %86 = bitcast %85 to double
  %76 = call i32 @cq_template_select_f64(i32 %61, i32 %70, i32 %75)    ; IR: %88 = phi [ %80, %71 ], [ %86, %81 ]: the %69 subtree on %70
  %77 = call i32 @cq_template_select_f64(i32 %57, i32 %60, i32 %76)    ; IR: %88 = phi ..., [ %68, %65 ]: the %59 subtree on %64
  %78 = call i32 @cq_template_select_f64(i32 %43, i32 %2, i32 %77)    ; IR: %88 = phi [ c, %38 ], ...: the top split on %47 (scalbn(c, %40))
  %79 = call i32 @cq_template_bitcast_f64_to_i64(i32 %3)    ; IR: %89 = bitcast d to i64  (scalbn(d, %40))
  %80 = call i32 @cq_template_lshr_i64_hl(i32 %79, i64 52)    ; IR: %90 = lshr %89, 52
  %81 = call i32 @cq_template_trunc_i64_to_i32(i32 %80)    ; IR: %91 = trunc %90 to i32
  %82 = call i32 @cq_template_and_i32_hl(i32 %81, i32 2047)    ; IR: %92 = and %91, 2047  (biased exponent)
  %83 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %3, double 0.000000e+00)    ; IR: %93 = fcmp oeq d, 0
  %84 = call i32 @cq_template_icmp_eq_i32_hl(i32 %82, i32 2047)    ; IR: %94 = icmp eq %92, 2047  (inf or nan)
  %85 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %95 = select i1 %93, i1 true, i1 %94 = %93 | %94  [br %95 -> the merge %135 keeps d, else block %96]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %83, i32 %84, i32 %85)    ; IR: %95 = select i1 %93, i1 true, i1 %94 = %93 | %94  [br %95 -> the merge %135 keeps d, else block %96]
  %86 = call i32 @cq_template_and_i64_hl(i32 %79, i64 4503599627370495)    ; IR: %97 = and %89, 0xFFFFFFFFFFFFF  (mantissa; block %96)
  %87 = call i32 @cq_template_icmp_eq_i32_hl(i32 %82, i32 0)    ; IR: %98 = icmp eq %92, 0  (subnormal)  [br %98 -> block %99, else %107]
  %88 = call i32 @cq_template_ctlz_i64(i32 %86)    ; IR: %100 = ctlz(%97)  (block %99: normalise the subnormal)
  %89 = call i32 @cq_template_trunc_i64_to_i32(i32 %88)    ; IR: %101 = trunc %100 to i32
  %90 = call i32 @cq_template_add_i64_hl(i32 %88, i64 4294967285)    ; IR: %102 = add %100, 4294967285  (shift = clz - 11, as the i32 wrap of the bundle)
  %91 = call i32 @cq_template_and_i64_hl(i32 %90, i64 4294967295)    ; IR: %103 = and %102, 4294967295
  %92 = call i32 @cq_template_shl_i64(i32 %86, i32 %91)    ; IR: %104 = shl %97, %103
  %93 = call i32 @cq_template_sub_i32_lh(i32 12, i32 %89)    ; IR: %105 = sub 12, %101  (exponent of the normalised mantissa)
  %94 = call i32 @cq_template_and_i64_hl(i32 %92, i64 -4503599627370497)    ; IR: %106 = and %104, ~0x10000000000000
  %95 = call i32 @cq_template_select_i64(i32 %87, i32 %94, i32 %86)    ; IR: %108 = phi i64 [ %106, %99 ], [ %97, %96 ]  (mantissa)
  %96 = call i32 @cq_template_select_i32(i32 %87, i32 %93, i32 %82)    ; IR: %109 = phi i32 [ %105, %99 ], [ %92, %96 ]  (exponent)
  %97 = call i32 @cq_template_sadd_sat_i32(i32 %96, i32 %36)    ; IR: %110 = llvm.sadd.sat.i32(%109, %40)  (new exponent, saturated)
  %98 = call i32 @cq_template_and_i64_hl(i32 %79, i64 -9223372036854775808)    ; IR: %111 = and %89, 0x8000000000000000  (sign)
  %99 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %97, i32 2046)    ; IR: %112 = icmp sgt %110, 2046  (overflow)  [br %112 -> block %113, else %117]
  %100 = call i32 @cq_template_or_i64_hl(i32 %98, i64 9214364837600034816)    ; IR: %114 = or %111, 0x7FE0000000000000  (block %113: signed 2^1023)
  %101 = call i32 @cq_template_bitcast_i64_to_f64(i32 %100)    ; IR: %115 = bitcast %114 to double
  %102 = call i32 @cq_template_fmul_f64_hl(i32 %101, double 2.000000e+00)    ; IR: %116 = fmul %115, 2.0  (signed inf)
  %103 = call i32 @cq_template_icmp_slt_i32_hl(i32 %97, i32 1)    ; IR: %118 = icmp slt %110, 1  (underflow)  (block %117)  [br %118 -> block %119, else %129]
  %104 = call i32 @cq_template_or_i64(i32 %95, i32 %98)    ; IR: %120 = or %108, %111  (block %119)
  %105 = call i32 @cq_template_or_i64_hl(i32 %104, i64 4503599627370496)    ; IR: %121 = or %120, 0x10000000000000  (exponent 1)
  %106 = call i32 @cq_template_bitcast_i64_to_f64(i32 %105)    ; IR: %122 = bitcast %121 to double
  %107 = call i32 @cq_template_smax_i32_hl(i32 %97, i32 -1021)    ; IR: %123 = llvm.smax.i32(%110, -1021)
  %108 = call i32 @cq_template_add_i32_hl(i32 %107, i32 1022)    ; IR: %124 = add %123, 1022
  %109 = call i32 @cq_template_zext_i32_to_i64(i32 %108)    ; IR: %125 = zext %124 to i64
  %110 = call i32 @cq_template_shl_i64_hl(i32 %109, i64 52)    ; IR: %126 = shl %125, 52
  %111 = call i32 @cq_template_bitcast_i64_to_f64(i32 %110)    ; IR: %127 = bitcast %126 to double  (2^(e - 1))
  %112 = call i32 @cq_template_fmul_f64(i32 %106, i32 %111)    ; IR: %128 = fmul %122, %127  (the subnormal result)
  %113 = call i32 @cq_template_zext_i32_to_i64(i32 %97)    ; IR: %130 = zext %110 to i64  (block %129: the normal result)
  %114 = call i32 @cq_template_shl_i64_hl(i32 %113, i64 52)    ; IR: %131 = shl %130, 52
  %115 = call i32 @cq_template_or_i64(i32 %98, i32 %114)    ; IR: %132 = or %111, %131
  %116 = call i32 @cq_template_or_i64(i32 %115, i32 %95)    ; IR: %133 = or %132, %108
  %117 = call i32 @cq_template_bitcast_i64_to_f64(i32 %116)    ; IR: %134 = bitcast %133 to double
  %118 = call i32 @cq_template_select_f64(i32 %103, i32 %112, i32 %117)    ; IR: %136 = phi [ %128, %119 ], [ %134, %129 ]: the %117 subtree on %118
  %119 = call i32 @cq_template_select_f64(i32 %99, i32 %102, i32 %118)    ; IR: %136 = phi ..., [ %116, %113 ]: the %107 subtree on %112
  %120 = call i32 @cq_template_select_f64(i32 %85, i32 %3, i32 %119)    ; IR: %137 = phi ..., [ %3, %87 ], [ %116, %113 ], [ %128, %119 ], [ %134, %129 ]: scalbn(d, %40), the %87 split on %95
  %121 = call i32 @cq_template_select_f64(i32 %34, i32 %2, i32 %78)    ; IR: %136 = phi [ %2, %34 ], [ %88, %87 ], [ %88, %113 ], [ %88, %119 ], [ %88, %129 ]  (c scaled): the top split on %37
  %122 = call i32 @cq_template_select_f64(i32 %34, i32 %3, i32 %120)    ; IR: %137 = phi [ %3, %34 ], ...  (d scaled): the top split on %37
  %123 = call i32 @cq_template_select_i32_lh(i32 %34, i32 0, i32 %35)    ; IR: %138 = phi i32 [ 0, %34 ], [ %39, %87 ], [ %39, %113 ], [ %39, %119 ], [ %39, %129 ]  (ilogbw)
  %124 = call i32 @cq_template_fmul_f64(i32 %122, i32 %122)    ; IR: %139 = fmul %137, %137
  %125 = call i32 @cq_template_fmul_f64(i32 %121, i32 %121)    ; IR: %140 = fmuladd(%136, %136, %139)  (denom)  [unfused product]
  %126 = call i32 @cq_template_fadd_f64(i32 %125, i32 %124)    ; IR: %140 = fmuladd(%136, %136, %139)  (denom)  [unfused sum]
  %127 = call i32 @cq_template_fmul_f64_hl(i32 %122, double %1)    ; IR: %141 = fmul %137, b
  %128 = call i32 @cq_template_fmul_f64_hl(i32 %121, double %0)    ; IR: %142 = fmuladd(a, %136, %141)  (commutative product, handle first)  [unfused product]
  %129 = call i32 @cq_template_fadd_f64(i32 %128, i32 %127)    ; IR: %142 = fmuladd(a, %136, %141)  [unfused sum]
  %130 = call i32 @cq_template_fdiv_f64(i32 %129, i32 %126)    ; IR: %143 = fdiv %142, %140  (real quotient before the rescale)
  %131 = call i32 @cq_template_sub_i32_lh(i32 0, i32 %123)    ; IR: %144 = sub 0, %138  (-ilogbw)
  %132 = call i32 @cq_template_bitcast_f64_to_i64(i32 %130)    ; IR: %145 = bitcast %143 to i64  (scalbn(%143, %144))
  %133 = call i32 @cq_template_lshr_i64_hl(i32 %132, i64 52)    ; IR: %146 = lshr %145, 52
  %134 = call i32 @cq_template_trunc_i64_to_i32(i32 %133)    ; IR: %147 = trunc %146 to i32
  %135 = call i32 @cq_template_and_i32_hl(i32 %134, i32 2047)    ; IR: %148 = and %147, 2047  (biased exponent)
  %136 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %130, double 0.000000e+00)    ; IR: %149 = fcmp oeq %143, 0
  %137 = call i32 @cq_template_icmp_eq_i32_hl(i32 %135, i32 2047)    ; IR: %150 = icmp eq %148, 2047  (inf or nan)
  %138 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %151 = select i1 %149, i1 true, i1 %150 = %149 | %150  [br %151 -> the merge %191 keeps %143, else block %152]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %136, i32 %137, i32 %138)    ; IR: %151 = select i1 %149, i1 true, i1 %150 = %149 | %150  [br %151 -> the merge %191 keeps %143, else block %152]
  %139 = call i32 @cq_template_and_i64_hl(i32 %132, i64 4503599627370495)    ; IR: %153 = and %145, 0xFFFFFFFFFFFFF  (mantissa; block %152)
  %140 = call i32 @cq_template_icmp_eq_i32_hl(i32 %135, i32 0)    ; IR: %154 = icmp eq %148, 0  (subnormal)  [br %154 -> block %155, else %163]
  %141 = call i32 @cq_template_ctlz_i64(i32 %139)    ; IR: %156 = ctlz(%153)  (block %155: normalise the subnormal)
  %142 = call i32 @cq_template_trunc_i64_to_i32(i32 %141)    ; IR: %157 = trunc %156 to i32
  %143 = call i32 @cq_template_add_i64_hl(i32 %141, i64 4294967285)    ; IR: %158 = add %156, 4294967285  (shift = clz - 11, as the i32 wrap of the bundle)
  %144 = call i32 @cq_template_and_i64_hl(i32 %143, i64 4294967295)    ; IR: %159 = and %158, 4294967295
  %145 = call i32 @cq_template_shl_i64(i32 %139, i32 %144)    ; IR: %160 = shl %153, %159
  %146 = call i32 @cq_template_sub_i32_lh(i32 12, i32 %142)    ; IR: %161 = sub 12, %157  (exponent of the normalised mantissa)
  %147 = call i32 @cq_template_and_i64_hl(i32 %145, i64 -4503599627370497)    ; IR: %162 = and %160, ~0x10000000000000
  %148 = call i32 @cq_template_select_i64(i32 %140, i32 %147, i32 %139)    ; IR: %164 = phi i64 [ %162, %155 ], [ %153, %152 ]  (mantissa)
  %149 = call i32 @cq_template_select_i32(i32 %140, i32 %146, i32 %135)    ; IR: %165 = phi i32 [ %161, %155 ], [ %148, %152 ]  (exponent)
  %150 = call i32 @cq_template_sadd_sat_i32(i32 %149, i32 %131)    ; IR: %166 = llvm.sadd.sat.i32(%165, %144)  (new exponent, saturated)
  %151 = call i32 @cq_template_and_i64_hl(i32 %132, i64 -9223372036854775808)    ; IR: %167 = and %145, 0x8000000000000000  (sign)
  %152 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %150, i32 2046)    ; IR: %168 = icmp sgt %166, 2046  (overflow)  [br %168 -> block %169, else %173]
  %153 = call i32 @cq_template_or_i64_hl(i32 %151, i64 9214364837600034816)    ; IR: %170 = or %167, 0x7FE0000000000000  (block %169: signed 2^1023)
  %154 = call i32 @cq_template_bitcast_i64_to_f64(i32 %153)    ; IR: %171 = bitcast %170 to double
  %155 = call i32 @cq_template_fmul_f64_hl(i32 %154, double 2.000000e+00)    ; IR: %172 = fmul %171, 2.0  (signed inf)
  %156 = call i32 @cq_template_icmp_slt_i32_hl(i32 %150, i32 1)    ; IR: %174 = icmp slt %166, 1  (underflow)  (block %173)  [br %174 -> block %175, else %185]
  %157 = call i32 @cq_template_or_i64(i32 %148, i32 %151)    ; IR: %176 = or %164, %167  (block %175)
  %158 = call i32 @cq_template_or_i64_hl(i32 %157, i64 4503599627370496)    ; IR: %177 = or %176, 0x10000000000000  (exponent 1)
  %159 = call i32 @cq_template_bitcast_i64_to_f64(i32 %158)    ; IR: %178 = bitcast %177 to double
  %160 = call i32 @cq_template_smax_i32_hl(i32 %150, i32 -1021)    ; IR: %179 = llvm.smax.i32(%166, -1021)
  %161 = call i32 @cq_template_add_i32_hl(i32 %160, i32 1022)    ; IR: %180 = add %179, 1022
  %162 = call i32 @cq_template_zext_i32_to_i64(i32 %161)    ; IR: %181 = zext %180 to i64
  %163 = call i32 @cq_template_shl_i64_hl(i32 %162, i64 52)    ; IR: %182 = shl %181, 52
  %164 = call i32 @cq_template_bitcast_i64_to_f64(i32 %163)    ; IR: %183 = bitcast %182 to double  (2^(e - 1))
  %165 = call i32 @cq_template_fmul_f64(i32 %159, i32 %164)    ; IR: %184 = fmul %178, %183  (the subnormal result)
  %166 = call i32 @cq_template_zext_i32_to_i64(i32 %150)    ; IR: %186 = zext %166 to i64  (block %185: the normal result)
  %167 = call i32 @cq_template_shl_i64_hl(i32 %166, i64 52)    ; IR: %187 = shl %186, 52
  %168 = call i32 @cq_template_or_i64(i32 %151, i32 %167)    ; IR: %188 = or %167, %187
  %169 = call i32 @cq_template_or_i64(i32 %168, i32 %148)    ; IR: %189 = or %188, %164
  %170 = call i32 @cq_template_bitcast_i64_to_f64(i32 %169)    ; IR: %190 = bitcast %189 to double
  %171 = call i32 @cq_template_select_f64(i32 %156, i32 %165, i32 %170)    ; IR: %192 = phi [ %184, %175 ], [ %190, %185 ]: the %173 subtree on %174
  %172 = call i32 @cq_template_select_f64(i32 %152, i32 %155, i32 %171)    ; IR: %192 = phi ..., [ %172, %169 ]: the %163 subtree on %168
  %173 = call i32 @cq_template_select_f64(i32 %138, i32 %130, i32 %172)    ; IR: %192 = phi [ %143, %142 ], ...: the top split on %151 (scalbn(%143, %144))
  %174 = call i32 @cq_template_fneg_f64(i32 %122)    ; IR: %193 = fneg %137
  %175 = call i32 @cq_template_fmul_f64_hl(i32 %174, double %0)    ; IR: %194 = fmul %193, a
  %176 = call i32 @cq_template_fmul_f64_hl(i32 %121, double %1)    ; IR: %195 = fmuladd(b, %136, %194)  (commutative product, handle first)  [unfused product]
  %177 = call i32 @cq_template_fadd_f64(i32 %176, i32 %175)    ; IR: %195 = fmuladd(b, %136, %194)  [unfused sum]
  %178 = call i32 @cq_template_fdiv_f64(i32 %177, i32 %126)    ; IR: %196 = fdiv %195, %140  (imaginary quotient before the rescale)
  %179 = call i32 @cq_template_bitcast_f64_to_i64(i32 %178)    ; IR: %197 = bitcast %196 to i64  (scalbn(%196, %144))
  %180 = call i32 @cq_template_lshr_i64_hl(i32 %179, i64 52)    ; IR: %198 = lshr %197, 52
  %181 = call i32 @cq_template_trunc_i64_to_i32(i32 %180)    ; IR: %199 = trunc %198 to i32
  %182 = call i32 @cq_template_and_i32_hl(i32 %181, i32 2047)    ; IR: %200 = and %199, 2047  (biased exponent)
  %183 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %178, double 0.000000e+00)    ; IR: %201 = fcmp oeq %196, 0
  %184 = call i32 @cq_template_icmp_eq_i32_hl(i32 %182, i32 2047)    ; IR: %202 = icmp eq %200, 2047  (inf or nan)
  %185 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %203 = select i1 %201, i1 true, i1 %202 = %201 | %202  [br %203 -> the merge %243 keeps %196, else block %204]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %183, i32 %184, i32 %185)    ; IR: %203 = select i1 %201, i1 true, i1 %202 = %201 | %202  [br %203 -> the merge %243 keeps %196, else block %204]
  %186 = call i32 @cq_template_and_i64_hl(i32 %179, i64 4503599627370495)    ; IR: %205 = and %197, 0xFFFFFFFFFFFFF  (mantissa; block %204)
  %187 = call i32 @cq_template_icmp_eq_i32_hl(i32 %182, i32 0)    ; IR: %206 = icmp eq %200, 0  (subnormal)  [br %206 -> block %207, else %215]
  %188 = call i32 @cq_template_ctlz_i64(i32 %186)    ; IR: %208 = ctlz(%205)  (block %207: normalise the subnormal)
  %189 = call i32 @cq_template_trunc_i64_to_i32(i32 %188)    ; IR: %209 = trunc %208 to i32
  %190 = call i32 @cq_template_add_i64_hl(i32 %188, i64 4294967285)    ; IR: %210 = add %208, 4294967285  (shift = clz - 11, as the i32 wrap of the bundle)
  %191 = call i32 @cq_template_and_i64_hl(i32 %190, i64 4294967295)    ; IR: %211 = and %210, 4294967295
  %192 = call i32 @cq_template_shl_i64(i32 %186, i32 %191)    ; IR: %212 = shl %205, %211
  %193 = call i32 @cq_template_sub_i32_lh(i32 12, i32 %189)    ; IR: %213 = sub 12, %209  (exponent of the normalised mantissa)
  %194 = call i32 @cq_template_and_i64_hl(i32 %192, i64 -4503599627370497)    ; IR: %214 = and %212, ~0x10000000000000
  %195 = call i32 @cq_template_select_i64(i32 %187, i32 %194, i32 %186)    ; IR: %216 = phi i64 [ %214, %207 ], [ %205, %204 ]  (mantissa)
  %196 = call i32 @cq_template_select_i32(i32 %187, i32 %193, i32 %182)    ; IR: %217 = phi i32 [ %213, %207 ], [ %200, %204 ]  (exponent)
  %197 = call i32 @cq_template_sadd_sat_i32(i32 %196, i32 %131)    ; IR: %218 = llvm.sadd.sat.i32(%217, %144)  (new exponent, saturated)
  %198 = call i32 @cq_template_and_i64_hl(i32 %179, i64 -9223372036854775808)    ; IR: %219 = and %197, 0x8000000000000000  (sign)
  %199 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %197, i32 2046)    ; IR: %220 = icmp sgt %218, 2046  (overflow)  [br %220 -> block %221, else %225]
  %200 = call i32 @cq_template_or_i64_hl(i32 %198, i64 9214364837600034816)    ; IR: %222 = or %219, 0x7FE0000000000000  (block %221: signed 2^1023)
  %201 = call i32 @cq_template_bitcast_i64_to_f64(i32 %200)    ; IR: %223 = bitcast %222 to double
  %202 = call i32 @cq_template_fmul_f64_hl(i32 %201, double 2.000000e+00)    ; IR: %224 = fmul %223, 2.0  (signed inf)
  %203 = call i32 @cq_template_icmp_slt_i32_hl(i32 %197, i32 1)    ; IR: %226 = icmp slt %218, 1  (underflow)  (block %225)  [br %226 -> block %227, else %237]
  %204 = call i32 @cq_template_or_i64(i32 %195, i32 %198)    ; IR: %228 = or %216, %219  (block %227)
  %205 = call i32 @cq_template_or_i64_hl(i32 %204, i64 4503599627370496)    ; IR: %229 = or %228, 0x10000000000000  (exponent 1)
  %206 = call i32 @cq_template_bitcast_i64_to_f64(i32 %205)    ; IR: %230 = bitcast %229 to double
  %207 = call i32 @cq_template_smax_i32_hl(i32 %197, i32 -1021)    ; IR: %231 = llvm.smax.i32(%218, -1021)
  %208 = call i32 @cq_template_add_i32_hl(i32 %207, i32 1022)    ; IR: %232 = add %231, 1022
  %209 = call i32 @cq_template_zext_i32_to_i64(i32 %208)    ; IR: %233 = zext %232 to i64
  %210 = call i32 @cq_template_shl_i64_hl(i32 %209, i64 52)    ; IR: %234 = shl %233, 52
  %211 = call i32 @cq_template_bitcast_i64_to_f64(i32 %210)    ; IR: %235 = bitcast %234 to double  (2^(e - 1))
  %212 = call i32 @cq_template_fmul_f64(i32 %206, i32 %211)    ; IR: %236 = fmul %230, %235  (the subnormal result)
  %213 = call i32 @cq_template_zext_i32_to_i64(i32 %197)    ; IR: %238 = zext %218 to i64  (block %237: the normal result)
  %214 = call i32 @cq_template_shl_i64_hl(i32 %213, i64 52)    ; IR: %239 = shl %238, 52
  %215 = call i32 @cq_template_or_i64(i32 %198, i32 %214)    ; IR: %240 = or %219, %239
  %216 = call i32 @cq_template_or_i64(i32 %215, i32 %195)    ; IR: %241 = or %240, %216
  %217 = call i32 @cq_template_bitcast_i64_to_f64(i32 %216)    ; IR: %242 = bitcast %241 to double
  %218 = call i32 @cq_template_select_f64(i32 %203, i32 %212, i32 %217)    ; IR: %244 = phi [ %236, %227 ], [ %242, %237 ]: the %225 subtree on %226
  %219 = call i32 @cq_template_select_f64(i32 %199, i32 %202, i32 %218)    ; IR: %244 = phi ..., [ %224, %221 ]: the %215 subtree on %220
  %220 = call i32 @cq_template_select_f64(i32 %185, i32 %178, i32 %219)    ; IR: %244 = phi [ %196, %194 ], ...: the top split on %203 (scalbn(%196, %144))
  %221 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %173, double 0.000000e+00)    ; IR: %245 = fcmp uno %192, 0  (isnan(real))
  %222 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %220, double 0.000000e+00)    ; IR: %246 = fcmp uno %244, 0  (isnan(imag))
  %223 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %247 = select i1 %245, i1 %246, i1 false = %245 & %246  [br %247 -> block %248 (recover), else exit %302]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %221, i32 %222, i32 %223)    ; IR: %247 = select i1 %245, i1 %246, i1 false = %245 & %246  [br %247 -> block %248 (recover), else exit %302]
  %224 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %126, double 0.000000e+00)    ; IR: %249 = fcmp oeq %140, 0  (denom == 0; block %248)  [br %249 -> block %250, else %258]
  %225 = fcmp uno double %0, 0.000000e+00    ; IR: %251 = fcmp uno a, 0  (block %250)  (classical)
  %226 = fcmp uno double %1, 0.000000e+00    ; IR: %252 = fcmp uno b, 0  (classical)
  %227 = and i1 %225, %226    ; IR: %253 = and i1 %251, %252  (isnan(a) && isnan(b))  [br %253 -> %258, else block %254]  (classical)
  %228 = call i32 @cq_template_copysign_f64_lh(double 0x7FF0000000000000, i32 %121)    ; IR: %255 = copysign(inf, %136)  (block %254)
  %229 = call i32 @cq_template_fmul_f64_hl(i32 %228, double %0)    ; IR: %256 = fmul %255, a
  %230 = call i32 @cq_template_fmul_f64_hl(i32 %228, double %1)    ; IR: %257 = fmul %255, b
  %231 = tail call double @llvm.fabs.f64(double %0)    ; IR: %259 = fabs(a)  (block %258)  (classical)
  %232 = fcmp une double %231, 0x7FF0000000000000    ; IR: %260 = fcmp une %259, inf  (!isinf(a))  (classical)
  %233 = tail call double @llvm.fabs.f64(double %1)    ; IR: %261 = fabs(b)  (classical)
  %234 = fcmp une double %233, 0x7FF0000000000000    ; IR: %262 = fcmp une %261, inf  (!isinf(b))  (classical)
  %235 = and i1 %232, %234    ; IR: %263 = and i1 %260, %262  (classical)
  %236 = call i32 @cq_template_fabs_f64(i32 %121)    ; IR: %264 = fabs(%136)
  %237 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %236, double 0x7FF0000000000000)    ; IR: %265 = fcmp ueq %264, inf  (!isfinite(c))
  %238 = call i32 @cqrt_alloc_i1(i1 %235)    ; IR: %266 = select i1 %263, i1 true, i1 %265: the classical disjunct %263  [the classical conjunct as a seed rail, rule 7]
  %239 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %266 = select i1 %263, i1 true, i1 %265 = %263 | %265  [fresh flag rail]
  call void @cqrt_or_i1(i32 %237, i32 %238, i32 %239)    ; IR: %266 = select i1 %263, i1 true, i1 %265 = %263 | %265
  %240 = call i32 @cq_template_fabs_f64(i32 %122)    ; IR: %267 = fabs(%137)
  %241 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %240, double 0x7FF0000000000000)    ; IR: %268 = fcmp ueq %267, inf  (!isfinite(d))
  %242 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %269 = select i1 %266, i1 true, i1 %268 = %266 | %268  [br %269 -> block %282, else %270]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %239, i32 %241, i32 %242)    ; IR: %269 = select i1 %266, i1 true, i1 %268 = %266 | %268  [br %269 -> block %282, else %270]
  %243 = select i1 %232, double 0.000000e+00, double 1.000000e+00    ; IR: %271 = select %260, 0.0, 1.0  (block %270)  (classical)
  %244 = tail call double @llvm.copysign.f64(double %243, double %0)    ; IR: %272 = copysign(%271, a)  (classical)
  %245 = select i1 %234, double 0.000000e+00, double 1.000000e+00    ; IR: %273 = select %262, 0.0, 1.0  (classical)
  %246 = tail call double @llvm.copysign.f64(double %245, double %1)    ; IR: %274 = copysign(%273, b)  (classical)
  %247 = call i32 @cq_template_fmul_f64_hl(i32 %122, double %246)    ; IR: %275 = fmul %274, %137  (commutative, handle first)
  %248 = call i32 @cq_template_fmul_f64_hl(i32 %121, double %244)    ; IR: %276 = fmuladd(%272, %136, %275)  (commutative product, handle first)  [unfused product]
  %249 = call i32 @cq_template_fadd_f64(i32 %248, i32 %247)    ; IR: %276 = fmuladd(%272, %136, %275)  [unfused sum]
  %250 = call i32 @cq_template_fmul_f64_hl(i32 %249, double 0x7FF0000000000000)    ; IR: %277 = fmul %276, inf
  %251 = fneg double %244    ; IR: %278 = fneg %272  (classical)
  %252 = call i32 @cq_template_fmul_f64_hl(i32 %122, double %251)    ; IR: %279 = fmul %137, %278
  %253 = call i32 @cq_template_fmul_f64_hl(i32 %121, double %246)    ; IR: %280 = fmuladd(%274, %136, %279)  (commutative product, handle first)  [unfused product]
  %254 = call i32 @cq_template_fadd_f64(i32 %253, i32 %252)    ; IR: %280 = fmuladd(%274, %136, %279)  [unfused sum]
  %255 = call i32 @cq_template_fmul_f64_hl(i32 %254, double 0x7FF0000000000000)    ; IR: %281 = fmul %280, inf
  %256 = call i32 @cq_template_fcmp_une_f64_hl(i32 %32, double 0x7FF0000000000000)    ; IR: %283 = fcmp une %35, inf  (!(isinf(logbw) && logbw > 0); block %282)
  %257 = fcmp ueq double %231, 0x7FF0000000000000    ; IR: %284 = fcmp ueq %259, inf  (!isfinite(a))  (classical)
  %258 = call i32 @cqrt_alloc_i1(i1 %257)    ; IR: %285 = or i1 %284, %283: the classical disjunct %284  [the classical conjunct as a seed rail, rule 7]
  %259 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %285 = or i1 %284, %283  [fresh flag rail]
  call void @cqrt_or_i1(i32 %256, i32 %258, i32 %259)    ; IR: %285 = or i1 %284, %283
  %260 = fcmp ueq double %233, 0x7FF0000000000000    ; IR: %286 = fcmp ueq %261, inf  (!isfinite(b))  (classical)
  %261 = call i32 @cqrt_alloc_i1(i1 %260)    ; IR: %287 = or i1 %286, %285: the classical disjunct %286  [the classical conjunct as a seed rail, rule 7]
  %262 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %287 = or i1 %286, %285  [br %287 -> exit %302, else block %288]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %259, i32 %261, i32 %262)    ; IR: %287 = or i1 %286, %285  [br %287 -> exit %302, else block %288]
  %263 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %236, double 0x7FF0000000000000)    ; IR: %289 = fcmp oeq %264, inf  (isinf(c); block %288)
  %264 = call i32 @cq_template_select_f64_ll(i32 %263, double 1.000000e+00, double 0.000000e+00)    ; IR: %290 = select %289, 1.0, 0.0
  %265 = call i32 @cq_template_copysign_f64(i32 %264, i32 %121)    ; IR: %291 = copysign(%290, %136)
  %266 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %240, double 0x7FF0000000000000)    ; IR: %292 = fcmp oeq %267, inf  (isinf(d))
  %267 = call i32 @cq_template_select_f64_ll(i32 %266, double 1.000000e+00, double 0.000000e+00)    ; IR: %293 = select %292, 1.0, 0.0
  %268 = call i32 @cq_template_copysign_f64(i32 %267, i32 %122)    ; IR: %294 = copysign(%293, %137)
  %269 = call i32 @cq_template_fmul_f64_hl(i32 %268, double %1)    ; IR: %295 = fmul %294, b
  %270 = call i32 @cq_template_fmul_f64_hl(i32 %265, double %0)    ; IR: %296 = fmuladd(a, %291, %295)  (commutative product, handle first)  [unfused product]
  %271 = call i32 @cq_template_fadd_f64(i32 %270, i32 %269)    ; IR: %296 = fmuladd(a, %291, %295)  [unfused sum]
  %272 = call i32 @cq_template_fmul_f64_hl(i32 %271, double 0.000000e+00)    ; IR: %297 = fmul %296, 0.0
  %273 = call i32 @cq_template_fneg_f64(i32 %268)    ; IR: %298 = fneg %294
  %274 = call i32 @cq_template_fmul_f64_hl(i32 %273, double %0)    ; IR: %299 = fmul %298, a
  %275 = call i32 @cq_template_fmul_f64_hl(i32 %265, double %1)    ; IR: %300 = fmuladd(b, %291, %299)  (commutative product, handle first)  [unfused product]
  %276 = call i32 @cq_template_fadd_f64(i32 %275, i32 %274)    ; IR: %300 = fmuladd(b, %291, %299)  [unfused sum]
  %277 = call i32 @cq_template_fmul_f64_hl(i32 %276, double 0.000000e+00)    ; IR: %301 = fmul %300, 0.0
  %278 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P250 = path predicate of block %250: %247 & %249  [fresh flag rail]
  call void @cqrt_and_i1(i32 %223, i32 %224, i32 %278)    ; IR: P250 = path predicate of block %250: %247 & %249
  %279 = xor i1 %227, true    ; IR: !%253 = xor i1 %253, true  (the classical conjunct of block %254)  (classical)
  %280 = call i32 @cqrt_alloc_i1(i1 %279)    ; IR: P254 = P250 & !%253: the classical conjunct !%253  [the classical conjunct as a seed rail, rule 7]
  %281 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P254 = path predicate of block %254: P250 & !%253  [fresh flag rail]
  call void @cqrt_and_i1(i32 %278, i32 %280, i32 %281)    ; IR: P254 = path predicate of block %254: P250 & !%253
  call void @cqrt_not_i1(i32 %281)    ; IR: bracket: P258 reads NOT %281
  %282 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P258 = path predicate of block %258: %247 & !P254  (reached from %248 on !%249 or from %250 on %253)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %223, i32 %281, i32 %282)    ; IR: P258 = path predicate of block %258: %247 & !P254  (reached from %248 on !%249 or from %250 on %253)
  call void @cqrt_not_i1(i32 %281)    ; IR: bracket (close): P258 reads NOT %281
  call void @cqrt_not_i1(i32 %242)    ; IR: bracket: P270 reads NOT %242
  %283 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P270 = path predicate of block %270: P258 & !%269  [fresh flag rail]
  call void @cqrt_and_i1(i32 %282, i32 %242, i32 %283)    ; IR: P270 = path predicate of block %270: P258 & !%269
  call void @cqrt_not_i1(i32 %242)    ; IR: bracket (close): P270 reads NOT %242
  %284 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P282 = path predicate of block %282: P258 & %269  [fresh flag rail]
  call void @cqrt_and_i1(i32 %282, i32 %242, i32 %284)    ; IR: P282 = path predicate of block %282: P258 & %269
  call void @cqrt_not_i1(i32 %262)    ; IR: bracket: P288 reads NOT %262
  %285 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P288 = path predicate of block %288: P282 & !%287  [fresh flag rail]
  call void @cqrt_and_i1(i32 %284, i32 %262, i32 %285)    ; IR: P288 = path predicate of block %288: P282 & !%287
  call void @cqrt_not_i1(i32 %262)    ; IR: bracket (close): P288 reads NOT %262
  %286 = call i32 @cq_template_select_f64(i32 %281, i32 %229, i32 %173)    ; IR: %304 = phi [ %277, %270 ], [ %297, %288 ], [ %192, %282 ], [ %256, %254 ], [ %192, %243 ]: innermost select, the %254 arm against the complement %192
  %287 = call i32 @cq_template_select_f64(i32 %285, i32 %272, i32 %286)    ; IR: %304 = phi (real result): the %288 arm
  %288 = call i32 @cq_template_select_f64(i32 %283, i32 %250, i32 %287)    ; IR: %304 = phi (real result): the %270 arm
  %289 = call i32 @cq_template_select_f64(i32 %281, i32 %230, i32 %220)    ; IR: %303 = phi [ %281, %270 ], [ %301, %288 ], [ %244, %282 ], [ %257, %254 ], [ %244, %243 ]: innermost select, the %254 arm against the complement %244
  %290 = call i32 @cq_template_select_f64(i32 %285, i32 %277, i32 %289)    ; IR: %303 = phi (imaginary result): the %288 arm
  %291 = call i32 @cq_template_select_f64(i32 %283, i32 %255, i32 %290)    ; IR: %303 = phi (imaginary result): the %270 arm
  %292 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f64(i32 %288, i32 %292)    ; IR: copy real (%304) out
  %293 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %291, i32 %293)    ; IR: copy imaginary (%303) out
  call void @cq_template_select_f64_unc(i32 %291, i32 %283, i32 %255, i32 %290)    ; IR: uncompute %303
  call void @cqrt_free(i32 %291)    ; IR: release the %303 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %290, i32 %285, i32 %277, i32 %289)    ; IR: uncompute %303
  call void @cqrt_free(i32 %290)    ; IR: release the %303 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %289, i32 %281, i32 %230, i32 %220)    ; IR: uncompute %303
  call void @cqrt_free(i32 %289)    ; IR: release the %303 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %288, i32 %283, i32 %250, i32 %287)    ; IR: uncompute %304
  call void @cqrt_free(i32 %288)    ; IR: release the %304 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %287, i32 %285, i32 %272, i32 %286)    ; IR: uncompute %304
  call void @cqrt_free(i32 %287)    ; IR: release the %304 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %286, i32 %281, i32 %229, i32 %173)    ; IR: uncompute %304
  call void @cqrt_free(i32 %286)    ; IR: release the %304 rail (|0>)
  call void @cqrt_not_i1(i32 %262)    ; IR: bracket: P288 reads NOT %262
  call void @cqrt_and_i1(i32 %284, i32 %262, i32 %285)    ; IR: uncompute P288  [self-inverse]
  call void @cqrt_free(i32 %285)    ; IR: release the P288 rail (|0>)
  call void @cqrt_not_i1(i32 %262)    ; IR: bracket (close): P288 reads NOT %262
  call void @cqrt_and_i1(i32 %282, i32 %242, i32 %284)    ; IR: uncompute P282  [self-inverse]
  call void @cqrt_free(i32 %284)    ; IR: release the P282 rail (|0>)
  call void @cqrt_not_i1(i32 %242)    ; IR: bracket: P270 reads NOT %242
  call void @cqrt_and_i1(i32 %282, i32 %242, i32 %283)    ; IR: uncompute P270  [self-inverse]
  call void @cqrt_free(i32 %283)    ; IR: release the P270 rail (|0>)
  call void @cqrt_not_i1(i32 %242)    ; IR: bracket (close): P270 reads NOT %242
  call void @cqrt_not_i1(i32 %281)    ; IR: bracket: P258 reads NOT %281
  call void @cqrt_and_i1(i32 %223, i32 %281, i32 %282)    ; IR: uncompute P258  [self-inverse]
  call void @cqrt_free(i32 %282)    ; IR: release the P258 rail (|0>)
  call void @cqrt_not_i1(i32 %281)    ; IR: bracket (close): P258 reads NOT %281
  call void @cqrt_and_i1(i32 %278, i32 %280, i32 %281)    ; IR: uncompute P254  [self-inverse]
  call void @cqrt_free(i32 %281)    ; IR: release the P254 rail (|0>)
  call void @cqrt_free(i32 %280)    ; IR: release the seed rail of P254 (basis state)
  call void @cqrt_and_i1(i32 %223, i32 %224, i32 %278)    ; IR: uncompute P250  [self-inverse]
  call void @cqrt_free(i32 %278)    ; IR: release the P250 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %277, i32 %276, double 0.000000e+00)    ; IR: uncompute %301
  call void @cqrt_free(i32 %277)    ; IR: release the %301 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %276, i32 %275, i32 %274)    ; IR: uncompute %300
  call void @cqrt_free(i32 %276)    ; IR: release the %300 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %275, i32 %265, double %1)    ; IR: uncompute %300
  call void @cqrt_free(i32 %275)    ; IR: release the %300 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %274, i32 %273, double %0)    ; IR: uncompute %299
  call void @cqrt_free(i32 %274)    ; IR: release the %299 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %273, i32 %268)    ; IR: uncompute %298
  call void @cqrt_free(i32 %273)    ; IR: release the %298 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %272, i32 %271, double 0.000000e+00)    ; IR: uncompute %297
  call void @cqrt_free(i32 %272)    ; IR: release the %297 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %271, i32 %270, i32 %269)    ; IR: uncompute %296
  call void @cqrt_free(i32 %271)    ; IR: release the %296 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %270, i32 %265, double %0)    ; IR: uncompute %296
  call void @cqrt_free(i32 %270)    ; IR: release the %296 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %269, i32 %268, double %1)    ; IR: uncompute %295
  call void @cqrt_free(i32 %269)    ; IR: release the %295 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %268, i32 %267, i32 %122)    ; IR: uncompute %294
  call void @cqrt_free(i32 %268)    ; IR: release the %294 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %267, i32 %266, double 1.000000e+00, double 0.000000e+00)    ; IR: uncompute %293
  call void @cqrt_free(i32 %267)    ; IR: release the %293 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %266, i32 %240, double 0x7FF0000000000000)    ; IR: uncompute %292
  call void @cqrt_free(i32 %266)    ; IR: release the %292 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %265, i32 %264, i32 %121)    ; IR: uncompute %291
  call void @cqrt_free(i32 %265)    ; IR: release the %291 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %264, i32 %263, double 1.000000e+00, double 0.000000e+00)    ; IR: uncompute %290
  call void @cqrt_free(i32 %264)    ; IR: release the %290 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %263, i32 %236, double 0x7FF0000000000000)    ; IR: uncompute %289
  call void @cqrt_free(i32 %263)    ; IR: release the %289 rail (|0>)
  call void @cqrt_or_i1(i32 %259, i32 %261, i32 %262)    ; IR: uncompute %287  [self-inverse]
  call void @cqrt_free(i32 %262)    ; IR: release the %287 rail (|0>)
  call void @cqrt_free(i32 %261)    ; IR: release the seed rail of %287 (basis state)
  call void @cqrt_or_i1(i32 %256, i32 %258, i32 %259)    ; IR: uncompute %285  [self-inverse]
  call void @cqrt_free(i32 %259)    ; IR: release the %285 rail (|0>)
  call void @cqrt_free(i32 %258)    ; IR: release the seed rail of %285 (basis state)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %256, i32 %32, double 0x7FF0000000000000)    ; IR: uncompute %283
  call void @cqrt_free(i32 %256)    ; IR: release the %283 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %255, i32 %254, double 0x7FF0000000000000)    ; IR: uncompute %281
  call void @cqrt_free(i32 %255)    ; IR: release the %281 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %254, i32 %253, i32 %252)    ; IR: uncompute %280
  call void @cqrt_free(i32 %254)    ; IR: release the %280 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %253, i32 %121, double %246)    ; IR: uncompute %280
  call void @cqrt_free(i32 %253)    ; IR: release the %280 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %252, i32 %122, double %251)    ; IR: uncompute %279
  call void @cqrt_free(i32 %252)    ; IR: release the %279 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %250, i32 %249, double 0x7FF0000000000000)    ; IR: uncompute %277
  call void @cqrt_free(i32 %250)    ; IR: release the %277 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %249, i32 %248, i32 %247)    ; IR: uncompute %276
  call void @cqrt_free(i32 %249)    ; IR: release the %276 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %248, i32 %121, double %244)    ; IR: uncompute %276
  call void @cqrt_free(i32 %248)    ; IR: release the %276 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %247, i32 %122, double %246)    ; IR: uncompute %275
  call void @cqrt_free(i32 %247)    ; IR: release the %275 rail (|0>)
  call void @cqrt_or_i1(i32 %239, i32 %241, i32 %242)    ; IR: uncompute %269  [self-inverse]
  call void @cqrt_free(i32 %242)    ; IR: release the %269 rail (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %241, i32 %240, double 0x7FF0000000000000)    ; IR: uncompute %268
  call void @cqrt_free(i32 %241)    ; IR: release the %268 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %240, i32 %122)    ; IR: uncompute %267
  call void @cqrt_free(i32 %240)    ; IR: release the %267 rail (|0>)
  call void @cqrt_or_i1(i32 %237, i32 %238, i32 %239)    ; IR: uncompute %266  [self-inverse]
  call void @cqrt_free(i32 %239)    ; IR: release the %266 rail (|0>)
  call void @cqrt_free(i32 %238)    ; IR: release the seed rail of %266 (basis state)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %237, i32 %236, double 0x7FF0000000000000)    ; IR: uncompute %265
  call void @cqrt_free(i32 %237)    ; IR: release the %265 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %236, i32 %121)    ; IR: uncompute %264
  call void @cqrt_free(i32 %236)    ; IR: release the %264 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %230, i32 %228, double %1)    ; IR: uncompute %257
  call void @cqrt_free(i32 %230)    ; IR: release the %257 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %229, i32 %228, double %0)    ; IR: uncompute %256
  call void @cqrt_free(i32 %229)    ; IR: release the %256 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %228, double 0x7FF0000000000000, i32 %121)    ; IR: uncompute %255
  call void @cqrt_free(i32 %228)    ; IR: release the %255 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %224, i32 %126, double 0.000000e+00)    ; IR: uncompute %249
  call void @cqrt_free(i32 %224)    ; IR: release the %249 rail (|0>)
  call void @cqrt_and_i1(i32 %221, i32 %222, i32 %223)    ; IR: uncompute %247  [self-inverse]
  call void @cqrt_free(i32 %223)    ; IR: release the %247 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %222, i32 %220, double 0.000000e+00)    ; IR: uncompute %246
  call void @cqrt_free(i32 %222)    ; IR: release the %246 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %221, i32 %173, double 0.000000e+00)    ; IR: uncompute %245
  call void @cqrt_free(i32 %221)    ; IR: release the %245 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %220, i32 %185, i32 %178, i32 %219)    ; IR: uncompute %244
  call void @cqrt_free(i32 %220)    ; IR: release the %244 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %219, i32 %199, i32 %202, i32 %218)    ; IR: uncompute %244
  call void @cqrt_free(i32 %219)    ; IR: release the %244 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %218, i32 %203, i32 %212, i32 %217)    ; IR: uncompute %244
  call void @cqrt_free(i32 %218)    ; IR: release the %244 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %217, i32 %216)    ; IR: uncompute %242
  call void @cqrt_free(i32 %217)    ; IR: release the %242 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %216, i32 %215, i32 %195)    ; IR: uncompute %241
  call void @cqrt_free(i32 %216)    ; IR: release the %241 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %215, i32 %198, i32 %214)    ; IR: uncompute %240
  call void @cqrt_free(i32 %215)    ; IR: release the %240 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %214, i32 %213, i64 52)    ; IR: uncompute %239
  call void @cqrt_free(i32 %214)    ; IR: release the %239 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %213, i32 %197)    ; IR: uncompute %238
  call void @cqrt_free(i32 %213)    ; IR: release the %238 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %212, i32 %206, i32 %211)    ; IR: uncompute %236
  call void @cqrt_free(i32 %212)    ; IR: release the %236 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %211, i32 %210)    ; IR: uncompute %235
  call void @cqrt_free(i32 %211)    ; IR: release the %235 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %210, i32 %209, i64 52)    ; IR: uncompute %234
  call void @cqrt_free(i32 %210)    ; IR: release the %234 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %209, i32 %208)    ; IR: uncompute %233
  call void @cqrt_free(i32 %209)    ; IR: release the %233 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %208, i32 %207, i32 1022)    ; IR: uncompute %232
  call void @cqrt_free(i32 %208)    ; IR: release the %232 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %207, i32 %197, i32 -1021)    ; IR: uncompute %231
  call void @cqrt_free(i32 %207)    ; IR: release the %231 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %206, i32 %205)    ; IR: uncompute %230
  call void @cqrt_free(i32 %206)    ; IR: release the %230 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %205, i32 %204, i64 4503599627370496)    ; IR: uncompute %229
  call void @cqrt_free(i32 %205)    ; IR: release the %229 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %204, i32 %195, i32 %198)    ; IR: uncompute %228
  call void @cqrt_free(i32 %204)    ; IR: release the %228 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %203, i32 %197, i32 1)    ; IR: uncompute %226
  call void @cqrt_free(i32 %203)    ; IR: release the %226 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %202, i32 %201, double 2.000000e+00)    ; IR: uncompute %224
  call void @cqrt_free(i32 %202)    ; IR: release the %224 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %201, i32 %200)    ; IR: uncompute %223
  call void @cqrt_free(i32 %201)    ; IR: release the %223 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %200, i32 %198, i64 9214364837600034816)    ; IR: uncompute %222
  call void @cqrt_free(i32 %200)    ; IR: release the %222 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %199, i32 %197, i32 2046)    ; IR: uncompute %220
  call void @cqrt_free(i32 %199)    ; IR: release the %220 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %198, i32 %179, i64 -9223372036854775808)    ; IR: uncompute %219
  call void @cqrt_free(i32 %198)    ; IR: release the %219 rail (|0>)
  call void @cq_template_sadd_sat_i32_unc(i32 %197, i32 %196, i32 %131)    ; IR: uncompute %218
  call void @cqrt_free(i32 %197)    ; IR: release the %218 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %196, i32 %187, i32 %193, i32 %182)    ; IR: uncompute %217
  call void @cqrt_free(i32 %196)    ; IR: release the %217 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %195, i32 %187, i32 %194, i32 %186)    ; IR: uncompute %216
  call void @cqrt_free(i32 %195)    ; IR: release the %216 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %194, i32 %192, i64 -4503599627370497)    ; IR: uncompute %214
  call void @cqrt_free(i32 %194)    ; IR: release the %214 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %193, i32 12, i32 %189)    ; IR: uncompute %213
  call void @cqrt_free(i32 %193)    ; IR: release the %213 rail (|0>)
  call void @cq_template_shl_i64_unc(i32 %192, i32 %186, i32 %191)    ; IR: uncompute %212
  call void @cqrt_free(i32 %192)    ; IR: release the %212 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %191, i32 %190, i64 4294967295)    ; IR: uncompute %211
  call void @cqrt_free(i32 %191)    ; IR: release the %211 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %190, i32 %188, i64 4294967285)    ; IR: uncompute %210
  call void @cqrt_free(i32 %190)    ; IR: release the %210 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %189, i32 %188)    ; IR: uncompute %209
  call void @cqrt_free(i32 %189)    ; IR: release the %209 rail (|0>)
  call void @cq_template_ctlz_i64_unc(i32 %188, i32 %186)    ; IR: uncompute %208
  call void @cqrt_free(i32 %188)    ; IR: release the %208 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %187, i32 %182, i32 0)    ; IR: uncompute %206
  call void @cqrt_free(i32 %187)    ; IR: release the %206 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %186, i32 %179, i64 4503599627370495)    ; IR: uncompute %205
  call void @cqrt_free(i32 %186)    ; IR: release the %205 rail (|0>)
  call void @cqrt_or_i1(i32 %183, i32 %184, i32 %185)    ; IR: uncompute %203  [self-inverse]
  call void @cqrt_free(i32 %185)    ; IR: release the %203 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %184, i32 %182, i32 2047)    ; IR: uncompute %202
  call void @cqrt_free(i32 %184)    ; IR: release the %202 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %183, i32 %178, double 0.000000e+00)    ; IR: uncompute %201
  call void @cqrt_free(i32 %183)    ; IR: release the %201 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %182, i32 %181, i32 2047)    ; IR: uncompute %200
  call void @cqrt_free(i32 %182)    ; IR: release the %200 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %181, i32 %180)    ; IR: uncompute %199
  call void @cqrt_free(i32 %181)    ; IR: release the %199 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %180, i32 %179, i64 52)    ; IR: uncompute %198
  call void @cqrt_free(i32 %180)    ; IR: release the %198 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %179, i32 %178)    ; IR: uncompute %197
  call void @cqrt_free(i32 %179)    ; IR: release the %197 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %178, i32 %177, i32 %126)    ; IR: uncompute %196
  call void @cqrt_free(i32 %178)    ; IR: release the %196 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %177, i32 %176, i32 %175)    ; IR: uncompute %195
  call void @cqrt_free(i32 %177)    ; IR: release the %195 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %176, i32 %121, double %1)    ; IR: uncompute %195
  call void @cqrt_free(i32 %176)    ; IR: release the %195 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %175, i32 %174, double %0)    ; IR: uncompute %194
  call void @cqrt_free(i32 %175)    ; IR: release the %194 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %174, i32 %122)    ; IR: uncompute %193
  call void @cqrt_free(i32 %174)    ; IR: release the %193 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %173, i32 %138, i32 %130, i32 %172)    ; IR: uncompute %192
  call void @cqrt_free(i32 %173)    ; IR: release the %192 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %172, i32 %152, i32 %155, i32 %171)    ; IR: uncompute %192
  call void @cqrt_free(i32 %172)    ; IR: release the %192 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %171, i32 %156, i32 %165, i32 %170)    ; IR: uncompute %192
  call void @cqrt_free(i32 %171)    ; IR: release the %192 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %170, i32 %169)    ; IR: uncompute %190
  call void @cqrt_free(i32 %170)    ; IR: release the %190 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %169, i32 %168, i32 %148)    ; IR: uncompute %189
  call void @cqrt_free(i32 %169)    ; IR: release the %189 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %168, i32 %151, i32 %167)    ; IR: uncompute %188
  call void @cqrt_free(i32 %168)    ; IR: release the %188 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %167, i32 %166, i64 52)    ; IR: uncompute %187
  call void @cqrt_free(i32 %167)    ; IR: release the %187 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %166, i32 %150)    ; IR: uncompute %186
  call void @cqrt_free(i32 %166)    ; IR: release the %186 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %165, i32 %159, i32 %164)    ; IR: uncompute %184
  call void @cqrt_free(i32 %165)    ; IR: release the %184 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %164, i32 %163)    ; IR: uncompute %183
  call void @cqrt_free(i32 %164)    ; IR: release the %183 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %163, i32 %162, i64 52)    ; IR: uncompute %182
  call void @cqrt_free(i32 %163)    ; IR: release the %182 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %162, i32 %161)    ; IR: uncompute %181
  call void @cqrt_free(i32 %162)    ; IR: release the %181 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %161, i32 %160, i32 1022)    ; IR: uncompute %180
  call void @cqrt_free(i32 %161)    ; IR: release the %180 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %160, i32 %150, i32 -1021)    ; IR: uncompute %179
  call void @cqrt_free(i32 %160)    ; IR: release the %179 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %159, i32 %158)    ; IR: uncompute %178
  call void @cqrt_free(i32 %159)    ; IR: release the %178 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %158, i32 %157, i64 4503599627370496)    ; IR: uncompute %177
  call void @cqrt_free(i32 %158)    ; IR: release the %177 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %157, i32 %148, i32 %151)    ; IR: uncompute %176
  call void @cqrt_free(i32 %157)    ; IR: release the %176 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %156, i32 %150, i32 1)    ; IR: uncompute %174
  call void @cqrt_free(i32 %156)    ; IR: release the %174 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %155, i32 %154, double 2.000000e+00)    ; IR: uncompute %172
  call void @cqrt_free(i32 %155)    ; IR: release the %172 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %154, i32 %153)    ; IR: uncompute %171
  call void @cqrt_free(i32 %154)    ; IR: release the %171 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %153, i32 %151, i64 9214364837600034816)    ; IR: uncompute %170
  call void @cqrt_free(i32 %153)    ; IR: release the %170 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %152, i32 %150, i32 2046)    ; IR: uncompute %168
  call void @cqrt_free(i32 %152)    ; IR: release the %168 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %151, i32 %132, i64 -9223372036854775808)    ; IR: uncompute %167
  call void @cqrt_free(i32 %151)    ; IR: release the %167 rail (|0>)
  call void @cq_template_sadd_sat_i32_unc(i32 %150, i32 %149, i32 %131)    ; IR: uncompute %166
  call void @cqrt_free(i32 %150)    ; IR: release the %166 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %149, i32 %140, i32 %146, i32 %135)    ; IR: uncompute %165
  call void @cqrt_free(i32 %149)    ; IR: release the %165 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %148, i32 %140, i32 %147, i32 %139)    ; IR: uncompute %164
  call void @cqrt_free(i32 %148)    ; IR: release the %164 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %147, i32 %145, i64 -4503599627370497)    ; IR: uncompute %162
  call void @cqrt_free(i32 %147)    ; IR: release the %162 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %146, i32 12, i32 %142)    ; IR: uncompute %161
  call void @cqrt_free(i32 %146)    ; IR: release the %161 rail (|0>)
  call void @cq_template_shl_i64_unc(i32 %145, i32 %139, i32 %144)    ; IR: uncompute %160
  call void @cqrt_free(i32 %145)    ; IR: release the %160 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %144, i32 %143, i64 4294967295)    ; IR: uncompute %159
  call void @cqrt_free(i32 %144)    ; IR: release the %159 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %143, i32 %141, i64 4294967285)    ; IR: uncompute %158
  call void @cqrt_free(i32 %143)    ; IR: release the %158 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %142, i32 %141)    ; IR: uncompute %157
  call void @cqrt_free(i32 %142)    ; IR: release the %157 rail (|0>)
  call void @cq_template_ctlz_i64_unc(i32 %141, i32 %139)    ; IR: uncompute %156
  call void @cqrt_free(i32 %141)    ; IR: release the %156 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %140, i32 %135, i32 0)    ; IR: uncompute %154
  call void @cqrt_free(i32 %140)    ; IR: release the %154 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %139, i32 %132, i64 4503599627370495)    ; IR: uncompute %153
  call void @cqrt_free(i32 %139)    ; IR: release the %153 rail (|0>)
  call void @cqrt_or_i1(i32 %136, i32 %137, i32 %138)    ; IR: uncompute %151  [self-inverse]
  call void @cqrt_free(i32 %138)    ; IR: release the %151 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %137, i32 %135, i32 2047)    ; IR: uncompute %150
  call void @cqrt_free(i32 %137)    ; IR: release the %150 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %136, i32 %130, double 0.000000e+00)    ; IR: uncompute %149
  call void @cqrt_free(i32 %136)    ; IR: release the %149 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %135, i32 %134, i32 2047)    ; IR: uncompute %148
  call void @cqrt_free(i32 %135)    ; IR: release the %148 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %134, i32 %133)    ; IR: uncompute %147
  call void @cqrt_free(i32 %134)    ; IR: release the %147 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %133, i32 %132, i64 52)    ; IR: uncompute %146
  call void @cqrt_free(i32 %133)    ; IR: release the %146 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %132, i32 %130)    ; IR: uncompute %145
  call void @cqrt_free(i32 %132)    ; IR: release the %145 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %131, i32 0, i32 %123)    ; IR: uncompute %144
  call void @cqrt_free(i32 %131)    ; IR: release the %144 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %130, i32 %129, i32 %126)    ; IR: uncompute %143
  call void @cqrt_free(i32 %130)    ; IR: release the %143 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %129, i32 %128, i32 %127)    ; IR: uncompute %142
  call void @cqrt_free(i32 %129)    ; IR: release the %142 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %128, i32 %121, double %0)    ; IR: uncompute %142
  call void @cqrt_free(i32 %128)    ; IR: release the %142 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %127, i32 %122, double %1)    ; IR: uncompute %141
  call void @cqrt_free(i32 %127)    ; IR: release the %141 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %126, i32 %125, i32 %124)    ; IR: uncompute %140
  call void @cqrt_free(i32 %126)    ; IR: release the %140 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %125, i32 %121, i32 %121)    ; IR: uncompute %140
  call void @cqrt_free(i32 %125)    ; IR: release the %140 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %124, i32 %122, i32 %122)    ; IR: uncompute %139
  call void @cqrt_free(i32 %124)    ; IR: release the %139 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %123, i32 %34, i32 0, i32 %35)    ; IR: uncompute %138
  call void @cqrt_free(i32 %123)    ; IR: release the %138 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %122, i32 %34, i32 %3, i32 %120)    ; IR: uncompute %137
  call void @cqrt_free(i32 %122)    ; IR: release the %137 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %121, i32 %34, i32 %2, i32 %78)    ; IR: uncompute %136
  call void @cqrt_free(i32 %121)    ; IR: release the %136 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %120, i32 %85, i32 %3, i32 %119)    ; IR: uncompute %137
  call void @cqrt_free(i32 %120)    ; IR: release the %137 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %119, i32 %99, i32 %102, i32 %118)    ; IR: uncompute %136
  call void @cqrt_free(i32 %119)    ; IR: release the %136 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %118, i32 %103, i32 %112, i32 %117)    ; IR: uncompute %136
  call void @cqrt_free(i32 %118)    ; IR: release the %136 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %117, i32 %116)    ; IR: uncompute %134
  call void @cqrt_free(i32 %117)    ; IR: release the %134 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %116, i32 %115, i32 %95)    ; IR: uncompute %133
  call void @cqrt_free(i32 %116)    ; IR: release the %133 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %115, i32 %98, i32 %114)    ; IR: uncompute %132
  call void @cqrt_free(i32 %115)    ; IR: release the %132 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %114, i32 %113, i64 52)    ; IR: uncompute %131
  call void @cqrt_free(i32 %114)    ; IR: release the %131 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %113, i32 %97)    ; IR: uncompute %130
  call void @cqrt_free(i32 %113)    ; IR: release the %130 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %112, i32 %106, i32 %111)    ; IR: uncompute %128
  call void @cqrt_free(i32 %112)    ; IR: release the %128 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %111, i32 %110)    ; IR: uncompute %127
  call void @cqrt_free(i32 %111)    ; IR: release the %127 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %110, i32 %109, i64 52)    ; IR: uncompute %126
  call void @cqrt_free(i32 %110)    ; IR: release the %126 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %109, i32 %108)    ; IR: uncompute %125
  call void @cqrt_free(i32 %109)    ; IR: release the %125 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %108, i32 %107, i32 1022)    ; IR: uncompute %124
  call void @cqrt_free(i32 %108)    ; IR: release the %124 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %107, i32 %97, i32 -1021)    ; IR: uncompute %123
  call void @cqrt_free(i32 %107)    ; IR: release the %123 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %106, i32 %105)    ; IR: uncompute %122
  call void @cqrt_free(i32 %106)    ; IR: release the %122 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %105, i32 %104, i64 4503599627370496)    ; IR: uncompute %121
  call void @cqrt_free(i32 %105)    ; IR: release the %121 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %104, i32 %95, i32 %98)    ; IR: uncompute %120
  call void @cqrt_free(i32 %104)    ; IR: release the %120 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %103, i32 %97, i32 1)    ; IR: uncompute %118
  call void @cqrt_free(i32 %103)    ; IR: release the %118 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %102, i32 %101, double 2.000000e+00)    ; IR: uncompute %116
  call void @cqrt_free(i32 %102)    ; IR: release the %116 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %101, i32 %100)    ; IR: uncompute %115
  call void @cqrt_free(i32 %101)    ; IR: release the %115 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %100, i32 %98, i64 9214364837600034816)    ; IR: uncompute %114
  call void @cqrt_free(i32 %100)    ; IR: release the %114 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %99, i32 %97, i32 2046)    ; IR: uncompute %112
  call void @cqrt_free(i32 %99)    ; IR: release the %112 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %98, i32 %79, i64 -9223372036854775808)    ; IR: uncompute %111
  call void @cqrt_free(i32 %98)    ; IR: release the %111 rail (|0>)
  call void @cq_template_sadd_sat_i32_unc(i32 %97, i32 %96, i32 %36)    ; IR: uncompute %110
  call void @cqrt_free(i32 %97)    ; IR: release the %110 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %96, i32 %87, i32 %93, i32 %82)    ; IR: uncompute %109
  call void @cqrt_free(i32 %96)    ; IR: release the %109 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %95, i32 %87, i32 %94, i32 %86)    ; IR: uncompute %108
  call void @cqrt_free(i32 %95)    ; IR: release the %108 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %94, i32 %92, i64 -4503599627370497)    ; IR: uncompute %106
  call void @cqrt_free(i32 %94)    ; IR: release the %106 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %93, i32 12, i32 %89)    ; IR: uncompute %105
  call void @cqrt_free(i32 %93)    ; IR: release the %105 rail (|0>)
  call void @cq_template_shl_i64_unc(i32 %92, i32 %86, i32 %91)    ; IR: uncompute %104
  call void @cqrt_free(i32 %92)    ; IR: release the %104 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %91, i32 %90, i64 4294967295)    ; IR: uncompute %103
  call void @cqrt_free(i32 %91)    ; IR: release the %103 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %90, i32 %88, i64 4294967285)    ; IR: uncompute %102
  call void @cqrt_free(i32 %90)    ; IR: release the %102 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %89, i32 %88)    ; IR: uncompute %101
  call void @cqrt_free(i32 %89)    ; IR: release the %101 rail (|0>)
  call void @cq_template_ctlz_i64_unc(i32 %88, i32 %86)    ; IR: uncompute %100
  call void @cqrt_free(i32 %88)    ; IR: release the %100 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %87, i32 %82, i32 0)    ; IR: uncompute %98
  call void @cqrt_free(i32 %87)    ; IR: release the %98 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %86, i32 %79, i64 4503599627370495)    ; IR: uncompute %97
  call void @cqrt_free(i32 %86)    ; IR: release the %97 rail (|0>)
  call void @cqrt_or_i1(i32 %83, i32 %84, i32 %85)    ; IR: uncompute %95  [self-inverse]
  call void @cqrt_free(i32 %85)    ; IR: release the %95 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %84, i32 %82, i32 2047)    ; IR: uncompute %94
  call void @cqrt_free(i32 %84)    ; IR: release the %94 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %83, i32 %3, double 0.000000e+00)    ; IR: uncompute %93
  call void @cqrt_free(i32 %83)    ; IR: release the %93 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %82, i32 %81, i32 2047)    ; IR: uncompute %92
  call void @cqrt_free(i32 %82)    ; IR: release the %92 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %81, i32 %80)    ; IR: uncompute %91
  call void @cqrt_free(i32 %81)    ; IR: release the %91 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %80, i32 %79, i64 52)    ; IR: uncompute %90
  call void @cqrt_free(i32 %80)    ; IR: release the %90 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %79, i32 %3)    ; IR: uncompute %89
  call void @cqrt_free(i32 %79)    ; IR: release the %89 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %78, i32 %43, i32 %2, i32 %77)    ; IR: uncompute %88
  call void @cqrt_free(i32 %78)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %77, i32 %57, i32 %60, i32 %76)    ; IR: uncompute %88
  call void @cqrt_free(i32 %77)    ; IR: release the %88 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %76, i32 %61, i32 %70, i32 %75)    ; IR: uncompute %88
  call void @cqrt_free(i32 %76)    ; IR: release the %88 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %75, i32 %74)    ; IR: uncompute %86
  call void @cqrt_free(i32 %75)    ; IR: release the %86 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %74, i32 %73, i32 %53)    ; IR: uncompute %85
  call void @cqrt_free(i32 %74)    ; IR: release the %85 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %73, i32 %56, i32 %72)    ; IR: uncompute %84
  call void @cqrt_free(i32 %73)    ; IR: release the %84 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %72, i32 %71, i64 52)    ; IR: uncompute %83
  call void @cqrt_free(i32 %72)    ; IR: release the %83 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %71, i32 %55)    ; IR: uncompute %82
  call void @cqrt_free(i32 %71)    ; IR: release the %82 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %70, i32 %64, i32 %69)    ; IR: uncompute %80
  call void @cqrt_free(i32 %70)    ; IR: release the %80 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %69, i32 %68)    ; IR: uncompute %79
  call void @cqrt_free(i32 %69)    ; IR: release the %79 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %68, i32 %67, i64 52)    ; IR: uncompute %78
  call void @cqrt_free(i32 %68)    ; IR: release the %78 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %67, i32 %66)    ; IR: uncompute %77
  call void @cqrt_free(i32 %67)    ; IR: release the %77 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %66, i32 %65, i32 1022)    ; IR: uncompute %76
  call void @cqrt_free(i32 %66)    ; IR: release the %76 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %65, i32 %55, i32 -1021)    ; IR: uncompute %75
  call void @cqrt_free(i32 %65)    ; IR: release the %75 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %64, i32 %63)    ; IR: uncompute %74
  call void @cqrt_free(i32 %64)    ; IR: release the %74 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %63, i32 %62, i64 4503599627370496)    ; IR: uncompute %73
  call void @cqrt_free(i32 %63)    ; IR: release the %73 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %62, i32 %53, i32 %56)    ; IR: uncompute %72
  call void @cqrt_free(i32 %62)    ; IR: release the %72 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %61, i32 %55, i32 1)    ; IR: uncompute %70
  call void @cqrt_free(i32 %61)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %60, i32 %59, double 2.000000e+00)    ; IR: uncompute %68
  call void @cqrt_free(i32 %60)    ; IR: release the %68 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %59, i32 %58)    ; IR: uncompute %67
  call void @cqrt_free(i32 %59)    ; IR: release the %67 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %58, i32 %56, i64 9214364837600034816)    ; IR: uncompute %66
  call void @cqrt_free(i32 %58)    ; IR: release the %66 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %57, i32 %55, i32 2046)    ; IR: uncompute %64
  call void @cqrt_free(i32 %57)    ; IR: release the %64 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %56, i32 %37, i64 -9223372036854775808)    ; IR: uncompute %63
  call void @cqrt_free(i32 %56)    ; IR: release the %63 rail (|0>)
  call void @cq_template_sadd_sat_i32_unc(i32 %55, i32 %54, i32 %36)    ; IR: uncompute %62
  call void @cqrt_free(i32 %55)    ; IR: release the %62 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %54, i32 %45, i32 %51, i32 %40)    ; IR: uncompute %61
  call void @cqrt_free(i32 %54)    ; IR: release the %61 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %53, i32 %45, i32 %52, i32 %44)    ; IR: uncompute %60
  call void @cqrt_free(i32 %53)    ; IR: release the %60 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %52, i32 %50, i64 -4503599627370497)    ; IR: uncompute %58
  call void @cqrt_free(i32 %52)    ; IR: release the %58 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %51, i32 12, i32 %47)    ; IR: uncompute %57
  call void @cqrt_free(i32 %51)    ; IR: release the %57 rail (|0>)
  call void @cq_template_shl_i64_unc(i32 %50, i32 %44, i32 %49)    ; IR: uncompute %56
  call void @cqrt_free(i32 %50)    ; IR: release the %56 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %49, i32 %48, i64 4294967295)    ; IR: uncompute %55
  call void @cqrt_free(i32 %49)    ; IR: release the %55 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %48, i32 %46, i64 4294967285)    ; IR: uncompute %54
  call void @cqrt_free(i32 %48)    ; IR: release the %54 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %47, i32 %46)    ; IR: uncompute %53
  call void @cqrt_free(i32 %47)    ; IR: release the %53 rail (|0>)
  call void @cq_template_ctlz_i64_unc(i32 %46, i32 %44)    ; IR: uncompute %52
  call void @cqrt_free(i32 %46)    ; IR: release the %52 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %45, i32 %40, i32 0)    ; IR: uncompute %50
  call void @cqrt_free(i32 %45)    ; IR: release the %50 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %44, i32 %37, i64 4503599627370495)    ; IR: uncompute %49
  call void @cqrt_free(i32 %44)    ; IR: release the %49 rail (|0>)
  call void @cqrt_or_i1(i32 %41, i32 %42, i32 %43)    ; IR: uncompute %47  [self-inverse]
  call void @cqrt_free(i32 %43)    ; IR: release the %47 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %42, i32 %40, i32 2047)    ; IR: uncompute %46
  call void @cqrt_free(i32 %42)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %41, i32 %2, double 0.000000e+00)    ; IR: uncompute %45
  call void @cqrt_free(i32 %41)    ; IR: release the %45 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %40, i32 %39, i32 2047)    ; IR: uncompute %44
  call void @cqrt_free(i32 %40)    ; IR: release the %44 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %39, i32 %38)    ; IR: uncompute %43
  call void @cqrt_free(i32 %39)    ; IR: release the %43 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %38, i32 %37, i64 52)    ; IR: uncompute %42
  call void @cqrt_free(i32 %38)    ; IR: release the %42 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %37, i32 %2)    ; IR: uncompute %41
  call void @cqrt_free(i32 %37)    ; IR: release the %41 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %36, i32 0, i32 %35)    ; IR: uncompute %40
  call void @cqrt_free(i32 %36)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %35, i32 %32)    ; IR: uncompute %39
  call void @cqrt_free(i32 %35)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %34, i32 %33, double 0x7FF0000000000000)    ; IR: uncompute %37
  call void @cqrt_free(i32 %34)    ; IR: release the %37 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %33, i32 %32)    ; IR: uncompute %36
  call void @cqrt_free(i32 %33)    ; IR: release the %36 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %32, i32 %14, i32 %10, i32 %31)    ; IR: uncompute %35
  call void @cqrt_free(i32 %32)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %31, i32 %15, double 0xFFF0000000000000, i32 %30)    ; IR: uncompute %35
  call void @cqrt_free(i32 %31)    ; IR: release the %35 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %30, i32 %16, i32 %29, i32 %18)    ; IR: uncompute %35
  call void @cqrt_free(i32 %30)    ; IR: release the %35 rail (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %29, i32 %28)    ; IR: uncompute %33
  call void @cqrt_free(i32 %29)    ; IR: release the %33 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %28, i32 %27, i32 -1012)    ; IR: uncompute %32
  call void @cqrt_free(i32 %28)    ; IR: release the %32 rail (|0>)
  call void @cq_template_sub_i32_unc(i32 %27, i32 %26, i32 %20)    ; IR: uncompute %31
  call void @cqrt_free(i32 %27)    ; IR: release the %31 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %26, i32 %25, i32 2047)    ; IR: uncompute %30
  call void @cqrt_free(i32 %26)    ; IR: release the %30 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %25, i32 %24)    ; IR: uncompute %29
  call void @cqrt_free(i32 %25)    ; IR: release the %29 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %24, i32 %23, i64 52)    ; IR: uncompute %28
  call void @cqrt_free(i32 %24)    ; IR: release the %28 rail (|0>)
  call void @cq_template_shl_i64_unc(i32 %23, i32 %11, i32 %22)    ; IR: uncompute %27
  call void @cqrt_free(i32 %23)    ; IR: release the %27 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %22, i32 %21, i64 4294967295)    ; IR: uncompute %26
  call void @cqrt_free(i32 %22)    ; IR: release the %26 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %19, i64 4294967285)    ; IR: uncompute %25
  call void @cqrt_free(i32 %21)    ; IR: release the %25 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %20, i32 %19)    ; IR: uncompute %24
  call void @cqrt_free(i32 %20)    ; IR: release the %24 rail (|0>)
  call void @cq_template_ctlz_i64_unc(i32 %19, i32 %11)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %18, i32 %17)    ; IR: uncompute %21
  call void @cqrt_free(i32 %18)    ; IR: release the %21 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %13, i32 -1023)    ; IR: uncompute %20
  call void @cqrt_free(i32 %17)    ; IR: release the %20 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %16, i32 %11, i64 4503599627370496)    ; IR: uncompute %18
  call void @cqrt_free(i32 %16)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %15, i32 %10, double 0.000000e+00)    ; IR: uncompute %16
  call void @cqrt_free(i32 %15)    ; IR: release the %16 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %14, i32 %12, i64 2047)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %13, i32 %12)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %12, i32 %11, i64 52)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %11, i32 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %10, i32 %9, i32 %6, i32 %5)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: uncompute %9  [self-inverse]
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fcmp_olt_f64_unc(i32 %8, i32 %5, i32 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %7, i32 %2, double 0.000000e+00)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %6, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %5, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %294 = insertvalue { i32, i32 } poison, i32 %292, 0    ; IR: ret: field 0 (handle, real)
  %295 = insertvalue { i32, i32 } %294, i32 %293, 1    ; IR: ret: field 1 (handle, imaginary)
  ret { i32, i32 } %295    ; IR: ret  (the aggregate carries handles)
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fsub_f64_hl(i32, double)
declare void @cq_template_fsub_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmp_uno_f64_hl(i32, double)
declare void @cq_template_fcmp_uno_f64_hl_unc(i32, i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_fcmp_oeq_f64_hl(i32, double)
declare void @cq_template_fcmp_oeq_f64_hl_unc(i32, i32, double)
declare double @llvm.fabs.f64(double)
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
declare i32 @cq_template_fcmp_olt_f64(i32, i32)
declare void @cq_template_fcmp_olt_f64_unc(i32, i32, i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_ult_i64_hl(i32, i64)
declare void @cq_template_icmp_ult_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_ctlz_i64(i32)
declare void @cq_template_ctlz_i64_unc(i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_shl_i64(i32, i32)
declare void @cq_template_shl_i64_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_f64_lh(i32, double, i32)
declare void @cq_template_select_f64_lh_unc(i32, i32, double, i32)
declare i32 @cq_template_fcmp_ueq_f64_hl(i32, double)
declare void @cq_template_fcmp_ueq_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fptosi_f64_to_i32(i32)
declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)
declare i32 @cq_template_sub_i32_lh(i32, i32)
declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_sadd_sat_i32(i32, i32)
declare void @cq_template_sadd_sat_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i64_hl(i32, i64)
declare void @cq_template_or_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_bitcast_i64_to_f64(i32)
declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i64(i32, i32)
declare void @cq_template_or_i64_unc(i32, i32, i32)
declare i32 @cq_template_smax_i32_hl(i32, i32)
declare void @cq_template_smax_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fdiv_f64(i32, i32)
declare void @cq_template_fdiv_f64_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_une_f64_hl(i32, double)
declare void @cq_template_fcmp_une_f64_hl_unc(i32, i32, double)
