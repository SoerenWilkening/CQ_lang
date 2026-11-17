; HAND-WRITTEN. Rules: 26, 18, 8, 9, 4, 5, 7, 13, 14, 19, 23, 24 (and 3, 1).
; Checked: complex_div_q_c: creal(q) + cimag(q) (measured); complex_div_c_qq: creal(q) and cimag(q) (two measurements, classical sum).
; Clean: every rail but the registers (re; c and d), the measured result rails and the one Kept rail below; this includes
;   the fenv rails of the strictfp ilogb clone (the caller's empty flags rail, the two INVALID selects, the two ORed flags
;   states, the flags phi of logb and both clones' returned flags copies: fenv state the program never reads, dropped).
; Kept: a_K of __cq_q_ilogb_1_ctl (ilogb's subnormal-loop exit test i<<1 >= 0 evaluated after the K-th body, ANDed with
;   trip K's predicate a_4; rule 14: a_K = 1 iff the loop would run a (K+1)-th trip, an exact-K exit reads 0; the shl
;   recurrence has no LLVM range bound below K, so it is kept; the clone's predicate seeds the chain, so a_K reads 0
;   where logb does not call ilogb): one rail per ACTIVATION of the loop (rule 14, as a nested
;   loop keeps one inner a_K per outer trip): __cq_q___divdc3_0011 runs __cq_q_logb_1 forward once and its twin once, and
;   the twin re-runs the forward ilogb clone (strictfp ilogb cannot be inlined into it), so complex_div_c_qq keeps two;
;   __cq_q_ilogb_1_ctl_unc itself keeps nothing).
; Rotations: Ry(th) on re (first entry); Ry(tc) on c, Ry(td) on d (second entry). The clones hold no rotation.
; Complex division has no inline fast path: clang always calls __divdc3, the compiler-rt body reproduced in the .c file, so the
; whole divide is one lifted call (rule 18). The two entries reach it with different taint: mask 1000 (a = creal(z) quantum,
; b, c, d classical) and mask 0011 (c, d quantum), one clone each; every classical op of the body stays classical IR and every
; op with a handle operand is an out-of-place template (rule 4, the _hl/_lh shapes with the classical value as a literal). The
; libm calls inside the body follow the same taint: logb/scalbn with classical arguments are the plain calls of the O1.ll,
; a quantum argument makes them clones of the injected musl bodies (rule 18): __cq_q_scalbn_10 and __cq_q_scalbn_11
; (musl scalbn.c), __cq_q_logb_1 (musl logb.c) and __cq_q_ilogb_1_ctl (musl ilogb.c). The PINNED SOURCE AS BUILT is normative
; for every function the .c does not define (owner ruling 2026-10-29, cq-ezan): the bundle's clang -O1 IR of musl b1efda5,
; whose values the `; IR:` comments of the clones name. ilogb.c carries `#pragma STDC FENV_ACCESS ON`, so its IR is
; strictfp: it cannot be inlined into logb (no pragma) and its clone follows 82's fenv ABI (rule 23): the caller's mode
; and flags rail as two trailing parameters, { result, flags' } returned, both copied into fresh rails before the body is
; uncomputed, the _unc twin taking both returned handles first. __divdc3 has no FENV_ACCESS, so its environment is the
; default: __cq_q___divdc3_0011 passes the mode literal 0 (FE_TONEAREST) and mints an EMPTY flags rail (|0>, rule 7) that
; it frees directly after the twins; the returned flags are fenv state the program never reads and are dropped (uncomputed
; by the twin, freed). logb calls ilogb only in its finite-nonzero block, under a quantum predicate. ilogb holds a
; quantum-exit loop whose a_K is kept, so the callee is its _ctl clone (rule 19): __cq_q_ilogb_1_ctl(P, x, mode, flags)
; with P the predicate of logb's block %11 (!%3 & !%7), and the twin __cq_q_ilogb_1_ctl_unc(P, outs, args). P only seeds
; the loop's chain; the templates and the copy-out run unguarded (§1.4) and are merged, so logb's result phi AND its
; flags phi are the same nested
; selects, the flags arms of the blocks that do not call ilogb being the caller's flags. In __cq_q_ilogb_1_ctl the subnormal
; loop `for (e = -0x3ff; i>>63 == 0; e--, i<<=1);` has a quantum exit: it is rule 14's ROLLED loop of K = 4 trips (lines
; tagged [K]: the trip counter against the literal 4), its chain seeded by P & the arm predicate (e == 0 & i<<12 != 0),
; the pre-header guard %12 being trip 0 of the latch test %21, so each trip is test then body (as 05). i advances by a
; select on the trip predicate. e is an affine induction (start -1023, step -1): its value in a trip is the classical
; -1023 - (trip index + 1), recomputed from the trip index in the forward and in the reverse loop and never pushed; only
; its exit value is a carried rail, advancing by a select on the trip predicate (rule 14). Each trip pushes the handles
; its _uncs read; the reverse loop pops K trips. After the K-th body the latch test is evaluated once more and
; a_K = a_4 & test is kept; that test is uncomputed at once, and every
; trip predicate a_1..a_4 (the K-th body's included) by the reverse loop. The two FORCE_EVAL(0/0.0f) of ilogb (the zero arm,
; block %13 under S0 & i<<12 == 0, and the inf/nan arm, block %22 under S2047) are constrained.sitofp(0) = 0.0f and
; constrained.fdiv(0.0f, 0.0f): two literals, so the quotient is a classical NaN stored volatile to a dead local (no gate,
; rule 24), and its INVALID bit is fenv state: flags' = flags | select(pred, FE_INVALID = 1, 0) (65's spelling); the mode
; is passed but not read (a NaN in every rounding mode). The `switch` on the exponent field is one equality flag per case
; and the default is the complement (rule 13). fabs/fmax(maxnum)/copysign/fptosi/sitofp and every fcmp predicate (ueq = !isfinite, une, ord, uno) are templates.
; Every tainted branch is a flag (rule 8): `select i1 %a, i1 true, i1 %b` is the disjunction or_i1, `and i1` the
; conjunction and_i1, a negated conjunct an X bracket (not_i1) around the gate, a classical conjunct a seed rail (rule 7).
; Path predicates of the nested if/else-if ladder (P37, P41, P45, P57, P71, P78) are and_i1 chains; the two five-incoming
; phis of %94 are three select templates each on the disjoint path predicates P57, P78, P41 with the complement value (%31 /
; %26, the plain result) innermost (rule 9); the two-incoming phis merge on the local flag with the arms in flag order.
; llvm.fmuladd is UNFUSED (§2, cf. 14, 69): an fmul into a fresh product rail, then an fadd of the product and the addend
; into a fresh rail; the product is uncomputed by its fmul _unc right after the sum it fed and freed (rule 5). A classical
; product (both factors classical, quantum addend) is a classical fmul and an fadd_hl with the addend's handle first
; (commutative); otherwise the product factors are commutable, so a handle is put first (fmul _hl). Each clone copies its two results into fresh rails,
; uncomputes its chain LIFO and returns the copies; the caller runs the _unc twin and frees the copies (q_c), or measures the
; two copies directly (c_qq: nothing calls a twin of __cq_q___divdc3_0011, so none is defined (§1.4); the copies are the
; results). The garbage of the caller is uncomputed
; before the measurement (rule 5).
source_filename = "complex_div.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @complex_div_q_c(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = fmul double %2, 0.000000e+00    ; IR: %7 = fmul %2, 0.0  (im * I: real part im*0)  (classical)
  %8 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %7)    ; IR: %8 = fadd %7, %6  (real part of z)  (commutative, quantum operand first)
  %9 = fmul double %4, 0.000000e+00    ; IR: %9 = fmul %4, 0.0  (classical)
  %10 = fadd double %9, %3    ; IR: %10 = fadd %9, %3  (real part of w)  (classical)
  %11 = call fastcc { i32, i32 } @__cq_q___divdc3_1000(i32 %8, double %2, double %10, double %4)    ; IR: %11 = call @__divdc3(%8, %2, %10, %4), quantum clone (arg 0 quantum), the whole complex divide
  %12 = extractvalue { i32, i32 } %11, 0    ; IR: extractvalue %11, 0  (handle; classical)
  %13 = extractvalue { i32, i32 } %11, 1    ; IR: extractvalue %11, 1  (handle; classical)
  %14 = call i32 @cq_template_fadd_f64(i32 %12, i32 %13)    ; IR: %14 = fadd %12, %13  [result rail]
  call fastcc void @__cq_q___divdc3_1000_unc(i32 %12, i32 %13, i32 %8, double %2, double %10, double %4)    ; IR: uncompute the result rail(s) of %11
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %8, i32 %6, double %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %15 = call double @cqrt_measure_f64(i32 %14)    ; IR: %15 = cq_measure_f64(%14)
  ret double %15    ; IR: ret double %15
}

define double @complex_div_c_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_f64(double %2)    ; IR: %7 = cq_theta_f64(%2, %3)  [register c]
  call void @cqrt_ry_f64(i32 %7, double %3)    ; IR: %7 = cq_theta_f64(%2, %3)  [Ry]
  %8 = call i32 @cqrt_alloc_f64(double %4)    ; IR: %8 = cq_theta_f64(%4, %5)  [register d]
  call void @cqrt_ry_f64(i32 %8, double %5)    ; IR: %8 = cq_theta_f64(%4, %5)  [Ry]
  %9 = fmul double %1, 0.000000e+00    ; IR: %9 = fmul %1, 0.0  (classical)
  %10 = fadd double %9, %0    ; IR: %10 = fadd %9, %0  (real part of z)  (classical)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double 0.000000e+00)    ; IR: %11 = fmul %8, 0.0  (d * I: real part d*0)
  %12 = call i32 @cq_template_fadd_f64(i32 %7, i32 %11)    ; IR: %12 = fadd %7, %11  (real part of w)
  %13 = call fastcc { i32, i32 } @__cq_q___divdc3_0011(double %10, double %1, i32 %12, i32 %8)    ; IR: %13 = call @__divdc3(%10, %1, %12, %8), quantum clone (args 2 and 3 quantum); both result rails are measured below, so the twin never runs
  %14 = extractvalue { i32, i32 } %13, 0    ; IR: extractvalue %13, 0  (handle; classical)
  %15 = extractvalue { i32, i32 } %13, 1    ; IR: extractvalue %13, 1  (handle; classical)
  call void @cq_template_fadd_f64_unc(i32 %12, i32 %7, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %8, double 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  %16 = call double @cqrt_measure_f64(i32 %14)    ; IR: %16 = cq_measure_f64(%14)
  %17 = call double @cqrt_measure_f64(i32 %15)    ; IR: %17 = cq_measure_f64(%15)
  %18 = fadd double %16, %17    ; IR: %18 = fadd %16, %17  (classical: two outcomes)  (classical)
  ret double %18    ; IR: ret double %18
}

define internal fastcc { i32, i32 } @__cq_q___divdc3_1000(i32 %0, double %1, double %2, double %3) {
  %5 = tail call double @llvm.fabs.f64(double %2)    ; IR: %5 = fabs(c)  (classical)
  %6 = tail call double @llvm.fabs.f64(double %3)    ; IR: %6 = fabs(d)  (classical)
  %7 = tail call double @llvm.maxnum.f64(double %5, double %6)    ; IR: %7 = maxnum(%5, %6)  (fmax)  (classical)
  %8 = tail call double @logb(double noundef %7)    ; IR: %8 = logb(%7)  (classical)
  %9 = tail call double @llvm.fabs.f64(double %8)    ; IR: %9 = fabs(%8)  (classical)
  %10 = fcmp ueq double %9, 0x7FF0000000000000    ; IR: %10 = fcmp ueq %9, inf  (!isfinite(logbw))  [br %10 -> %16, else block %11]  (classical)
  %11 = fptosi double %8 to i32    ; IR: %12 = fptosi %8 to i32  (block %11)  (classical)
  %12 = sub i32 0, %11    ; IR: %13 = sub nsw 0, %12  (classical)
  %13 = tail call double @scalbn(double noundef %2, i32 noundef %12)    ; IR: %14 = scalbn(c, %13)  (classical)
  %14 = tail call double @scalbn(double noundef %3, i32 noundef %12)    ; IR: %15 = scalbn(d, %13)  (classical)
  %15 = select i1 %10, double %2, double %13    ; IR: %17 = phi [ %14, %11 ], [ %2, %4 ]  (c; the %10 edge keeps c)  (classical)
  %16 = select i1 %10, double %3, double %14    ; IR: %18 = phi [ %15, %11 ], [ %3, %4 ]  (d)  (classical)
  %17 = select i1 %10, i32 0, i32 %11    ; IR: %19 = phi [ %12, %11 ], [ 0, %4 ]  (ilogbw)  (classical)
  %18 = fmul double %16, %16    ; IR: %20 = fmul %18, %18  (classical)
  %19 = tail call double @llvm.fmuladd.f64(double %15, double %15, double %18)    ; IR: %21 = fmuladd(%17, %17, %20)  (denom)  (classical)
  %20 = fmul double %16, %1    ; IR: %22 = fmul %18, %1  (classical)
  %21 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %15)    ; IR: %23 = fmuladd(%0, %17, %22)  [unfused product]
  %22 = call i32 @cq_template_fadd_f64_hl(i32 %21, double %20)    ; IR: %23 = fmuladd(%0, %17, %22)  [unfused sum]
  %23 = call i32 @cq_template_fdiv_f64_hl(i32 %22, double %19)    ; IR: %24 = fdiv %23, %21
  %24 = sub i32 0, %17    ; IR: %25 = sub nsw 0, %19  (classical)
  %25 = call fastcc i32 @__cq_q_scalbn_10(i32 %23, i32 %24)    ; IR: %26 = scalbn(%24, %25)  (real z), quantum clone (mask 10, injected musl body)
  %26 = fneg double %16    ; IR: %27 = fneg %18  (classical)
  %27 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %26)    ; IR: %28 = fmul %27, %0  (commutative, quantum operand first)
  %28 = fmul double %1, %15    ; IR: %29 = fmuladd(%1, %17, %28)  [unfused product]  (classical)
  %29 = call i32 @cq_template_fadd_f64_hl(i32 %27, double %28)    ; IR: %29 = fmuladd(%1, %17, %28)  [unfused sum]  (commutative, quantum operand first)
  %30 = call i32 @cq_template_fdiv_f64_hl(i32 %29, double %19)    ; IR: %30 = fdiv %29, %21
  %31 = call fastcc i32 @__cq_q_scalbn_10(i32 %30, i32 %24)    ; IR: %31 = scalbn(%30, %25)  (imag z), quantum clone (mask 10, injected musl body)
  %32 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %25, double 0.000000e+00)    ; IR: %32 = fcmp ord %26, 0
  %33 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %31, double 0.000000e+00)    ; IR: %33 = fcmp ord %31, 0
  %34 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %32, i32 %33, i32 %34)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]
  %35 = fcmp oeq double %19, 0.000000e+00    ; IR: %36 = fcmp oeq %21, 0  (denom == 0; block %35)  (classical)
  %36 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %0, double 0.000000e+00)    ; IR: %38 = fcmp ord %0, 0  (block %37)
  %37 = fcmp ord double %1, 0.000000e+00    ; IR: %39 = fcmp ord %1, 0  (classical)
  %38 = call i32 @cqrt_alloc_i1(i1 %37)    ; IR: %40 = or i1 %38, %39  [the classical conjunct %35 as a seed rail, rule 7]
  %39 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %40 = or i1 %38, %39  [fresh flag rail]
  call void @cqrt_or_i1(i32 %36, i32 %38, i32 %39)    ; IR: %40 = or i1 %38, %39
  %40 = tail call double @llvm.copysign.f64(double 0x7FF0000000000000, double %15)    ; IR: %42 = copysign(inf, %17)  (block %41)  (classical)
  %41 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %40)    ; IR: %43 = fmul %42, %0  (commutative, quantum operand first)
  %42 = fmul double %40, %1    ; IR: %44 = fmul %42, %1  (classical)
  %43 = call i32 @cq_template_fabs_f64(i32 %0)    ; IR: %46 = fabs(a)  (block %45)
  %44 = call i32 @cq_template_fcmp_une_f64_hl(i32 %43, double 0x7FF0000000000000)    ; IR: %47 = !isinf(a)
  %45 = tail call double @llvm.fabs.f64(double %1)    ; IR: %48 = fabs(b)  (classical)
  %46 = fcmp une double %45, 0x7FF0000000000000    ; IR: %49 = !isinf(b)  (classical)
  %47 = call i32 @cqrt_alloc_i1(i1 %46)    ; IR: %50 = and i1 %47, %49  [the classical conjunct %44 as a seed rail, rule 7]
  %48 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %50 = and i1 %47, %49  [fresh flag rail]
  call void @cqrt_and_i1(i32 %44, i32 %47, i32 %48)    ; IR: %50 = and i1 %47, %49
  %49 = tail call double @llvm.fabs.f64(double %15)    ; IR: %51 = fabs(%17)  (classical)
  %50 = fcmp ueq double %49, 0x7FF0000000000000    ; IR: %52 = !isfinite(%17)  (classical)
  %51 = call i32 @cqrt_alloc_i1(i1 %50)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [the classical conjunct %48 as a seed rail, rule 7]
  %52 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [fresh flag rail]
  call void @cqrt_or_i1(i32 %48, i32 %51, i32 %52)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52
  %53 = tail call double @llvm.fabs.f64(double %16)    ; IR: %54 = fabs(%18)  (classical)
  %54 = fcmp ueq double %53, 0x7FF0000000000000    ; IR: %55 = !isfinite(%18)  (classical)
  %55 = call i32 @cqrt_alloc_i1(i1 %54)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]  [the classical conjunct %52 as a seed rail, rule 7]
  %56 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %52, i32 %55, i32 %56)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]
  %57 = call i32 @cq_template_select_f64_ll(i32 %44, double 0.000000e+00, double 1.000000e+00)    ; IR: %58 = select %47, 0.0, 1.0  (block %57)
  %58 = call i32 @cq_template_copysign_f64(i32 %57, i32 %0)    ; IR: %59 = copysign(%58, a)
  %59 = tail call double @llvm.fabs.f64(double %1)    ; IR: %60 = fabs(b)  (classical)
  %60 = fcmp une double %59, 0x7FF0000000000000    ; IR: %61 = !isinf(b)  (classical)
  %61 = select i1 %60, double 0.000000e+00, double 1.000000e+00    ; IR: %62 = select %61, 0.0, 1.0  (classical)
  %62 = tail call double @llvm.copysign.f64(double %61, double %1)    ; IR: %63 = copysign(%62, b)  (classical)
  %63 = fmul double %62, %16    ; IR: %64 = fmul %63, %18  (classical)
  %64 = call i32 @cq_template_fmul_f64_hl(i32 %58, double %15)    ; IR: %65 = fmuladd(%59, %17, %64)  [unfused product]
  %65 = call i32 @cq_template_fadd_f64_hl(i32 %64, double %63)    ; IR: %65 = fmuladd(%59, %17, %64)  [unfused sum]
  %66 = call i32 @cq_template_fmul_f64_hl(i32 %65, double 0x7FF0000000000000)    ; IR: %66 = fmul %65, inf
  %67 = call i32 @cq_template_fneg_f64(i32 %58)    ; IR: %67 = fneg %59
  %68 = call i32 @cq_template_fmul_f64_hl(i32 %67, double %16)    ; IR: %68 = fmul %18, %67  (commutative, quantum operand first)
  %69 = fmul double %62, %15    ; IR: %69 = fmuladd(%63, %17, %68)  [unfused product]  (classical)
  %70 = call i32 @cq_template_fadd_f64_hl(i32 %68, double %69)    ; IR: %69 = fmuladd(%63, %17, %68)  [unfused sum]  (commutative, quantum operand first)
  %71 = call i32 @cq_template_fmul_f64_hl(i32 %70, double 0x7FF0000000000000)    ; IR: %70 = fmul %69, inf
  %72 = fcmp une double %8, 0x7FF0000000000000    ; IR: %72 = fcmp une %8, inf  (block %71)  (classical)
  %73 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %43, double 0x7FF0000000000000)    ; IR: %73 = fcmp ueq %46, inf
  %74 = call i32 @cqrt_alloc_i1(i1 %72)    ; IR: %74 = or i1 %73, %72  [the classical conjunct %68 as a seed rail, rule 7]
  %75 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %74 = or i1 %73, %72  [fresh flag rail]
  call void @cqrt_or_i1(i32 %73, i32 %74, i32 %75)    ; IR: %74 = or i1 %73, %72
  %76 = tail call double @llvm.fabs.f64(double %1)    ; IR: %75 = fabs(b)  (classical)
  %77 = fcmp ueq double %76, 0x7FF0000000000000    ; IR: %76 = fcmp ueq %75, inf  (classical)
  %78 = call i32 @cqrt_alloc_i1(i1 %77)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [the classical conjunct %73 as a seed rail, rule 7]
  %79 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %78, i32 %75, i32 %79)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]
  %80 = tail call double @llvm.fabs.f64(double %15)    ; IR: %79 = fabs(%17)  (block %78)  (classical)
  %81 = fcmp une double %80, 0x7FF0000000000000    ; IR: %80 = !isinf(%17)  (classical)
  %82 = select i1 %81, double 0.000000e+00, double 1.000000e+00    ; IR: %81 = select %80, 0.0, 1.0  (classical)
  %83 = tail call double @llvm.copysign.f64(double %82, double %15)    ; IR: %82 = copysign(%81, %17)  (classical)
  %84 = tail call double @llvm.fabs.f64(double %16)    ; IR: %83 = fabs(%18)  (classical)
  %85 = fcmp une double %84, 0x7FF0000000000000    ; IR: %84 = !isinf(%18)  (classical)
  %86 = select i1 %85, double 0.000000e+00, double 1.000000e+00    ; IR: %85 = select %84, 0.0, 1.0  (classical)
  %87 = tail call double @llvm.copysign.f64(double %86, double %16)    ; IR: %86 = copysign(%85, %18)  (classical)
  %88 = fmul double %87, %1    ; IR: %87 = fmul %86, %1  (classical)
  %89 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %83)    ; IR: %88 = fmuladd(%0, %82, %87)  [unfused product]
  %90 = call i32 @cq_template_fadd_f64_hl(i32 %89, double %88)    ; IR: %88 = fmuladd(%0, %82, %87)  [unfused sum]
  %91 = call i32 @cq_template_fmul_f64_hl(i32 %90, double 0.000000e+00)    ; IR: %89 = fmul %88, 0.0
  %92 = fneg double %87    ; IR: %90 = fneg %86  (classical)
  %93 = call i32 @cq_template_fmul_f64_hl(i32 %0, double %92)    ; IR: %91 = fmul %90, %0  (commutative, quantum operand first)
  %94 = fmul double %1, %83    ; IR: %92 = fmuladd(%1, %82, %91)  [unfused product]  (classical)
  %95 = call i32 @cq_template_fadd_f64_hl(i32 %93, double %94)    ; IR: %92 = fmuladd(%1, %82, %91)  [unfused sum]  (commutative, quantum operand first)
  %96 = call i32 @cq_template_fmul_f64_hl(i32 %95, double 0.000000e+00)    ; IR: %93 = fmul %92, 0.0
  %97 = call i32 @cqrt_alloc_i1(i1 %35)    ; IR: P37 = path predicate of block %37: !%34 & %36  [the classical conjunct %33 as a seed rail, rule 7]
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P37 reads NOT %32
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P37 = path predicate of block %37: !%34 & %36  [fresh flag rail]
  call void @cqrt_and_i1(i32 %34, i32 %97, i32 %98)    ; IR: P37 = path predicate of block %37: !%34 & %36
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P37 reads NOT %32
  %99 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P41 = path predicate of block %41: P37 & %40  [fresh flag rail]
  call void @cqrt_and_i1(i32 %98, i32 %39, i32 %99)    ; IR: P41 = path predicate of block %41: P37 & %40
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %99)    ; IR: bracket: P45 reads NOT %93
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %34, i32 %99, i32 %100)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %99)    ; IR: bracket (close): P45 reads NOT %93
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket: P57 reads NOT %54
  %101 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P57 = path predicate of block %57: P45 & !%56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %100, i32 %56, i32 %101)    ; IR: P57 = path predicate of block %57: P45 & !%56
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket (close): P57 reads NOT %54
  %102 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P71 = path predicate of block %71: P45 & %56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %100, i32 %56, i32 %102)    ; IR: P71 = path predicate of block %71: P45 & %56
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket: P78 reads NOT %75
  %103 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P78 = path predicate of block %78: P71 & !%77  [fresh flag rail]
  call void @cqrt_and_i1(i32 %102, i32 %79, i32 %103)    ; IR: P78 = path predicate of block %78: P71 & !%77
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket (close): P78 reads NOT %75
  %104 = call i32 @cq_template_select_f64_lh(i32 %99, double %42, i32 %31)    ; IR: %95 = phi [ %70, %57 ], [ %93, %78 ], [ %31, %71 ], [ %44, %41 ], [ %31, %16 ]: innermost select, the %41 arm against the complement %31
  %105 = call i32 @cq_template_select_f64(i32 %103, i32 %96, i32 %104)    ; IR: %95 = phi (imag result): the %78 arm
  %106 = call i32 @cq_template_select_f64(i32 %101, i32 %71, i32 %105)    ; IR: %95 = phi (imag result): the %57 arm
  %107 = call i32 @cq_template_select_f64(i32 %99, i32 %41, i32 %25)    ; IR: %96 = phi [ %66, %57 ], [ %89, %78 ], [ %26, %71 ], [ %43, %41 ], [ %26, %16 ]: innermost select, the %41 arm against the complement %26
  %108 = call i32 @cq_template_select_f64(i32 %103, i32 %91, i32 %107)    ; IR: %96 = phi (real result): the %78 arm
  %109 = call i32 @cq_template_select_f64(i32 %101, i32 %66, i32 %108)    ; IR: %96 = phi (real result): the %57 arm
  %110 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f64(i32 %109, i32 %110)    ; IR: copy real out
  %111 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %106, i32 %111)    ; IR: copy imaginary out
  call void @cq_template_select_f64_unc(i32 %109, i32 %101, i32 %66, i32 %108)    ; IR: uncompute %96
  call void @cqrt_free(i32 %109)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %108, i32 %103, i32 %91, i32 %107)    ; IR: uncompute %96
  call void @cqrt_free(i32 %108)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %107, i32 %99, i32 %41, i32 %25)    ; IR: uncompute %96
  call void @cqrt_free(i32 %107)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %106, i32 %101, i32 %71, i32 %105)    ; IR: uncompute %95
  call void @cqrt_free(i32 %106)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %105, i32 %103, i32 %96, i32 %104)    ; IR: uncompute %95
  call void @cqrt_free(i32 %105)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %104, i32 %99, double %42, i32 %31)    ; IR: uncompute %95
  call void @cqrt_free(i32 %104)    ; IR: release the %95 rail (|0>)
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket: P78 reads NOT %75
  call void @cqrt_and_i1(i32 %102, i32 %79, i32 %103)    ; IR: uncompute P78  [self-inverse]
  call void @cqrt_free(i32 %103)    ; IR: release the P78 rail (|0>)
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket (close): P78 reads NOT %75
  call void @cqrt_and_i1(i32 %100, i32 %56, i32 %102)    ; IR: uncompute P71  [self-inverse]
  call void @cqrt_free(i32 %102)    ; IR: release the P71 rail (|0>)
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket: P57 reads NOT %54
  call void @cqrt_and_i1(i32 %100, i32 %56, i32 %101)    ; IR: uncompute P57  [self-inverse]
  call void @cqrt_free(i32 %101)    ; IR: release the P57 rail (|0>)
  call void @cqrt_not_i1(i32 %56)    ; IR: bracket (close): P57 reads NOT %54
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %99)    ; IR: bracket: P45 reads NOT %93
  call void @cqrt_and_i1(i32 %34, i32 %99, i32 %100)    ; IR: uncompute P45  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P45 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %99)    ; IR: bracket (close): P45 reads NOT %93
  call void @cqrt_and_i1(i32 %98, i32 %39, i32 %99)    ; IR: uncompute P41  [self-inverse]
  call void @cqrt_free(i32 %99)    ; IR: release the P41 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket: P37 reads NOT %32
  call void @cqrt_and_i1(i32 %34, i32 %97, i32 %98)    ; IR: uncompute P37  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release the P37 rail (|0>)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket (close): P37 reads NOT %32
  call void @cqrt_free(i32 %97)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f64_hl_unc(i32 %96, i32 %95, double 0.000000e+00)    ; IR: uncompute %93
  call void @cqrt_free(i32 %96)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %95, i32 %93, double %94)    ; IR: uncompute %92  [sum]
  call void @cqrt_free(i32 %95)    ; IR: release the %92 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %93, i32 %0, double %92)    ; IR: uncompute %91
  call void @cqrt_free(i32 %93)    ; IR: release the %91 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %91, i32 %90, double 0.000000e+00)    ; IR: uncompute %89
  call void @cqrt_free(i32 %91)    ; IR: release the %89 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %90, i32 %89, double %88)    ; IR: uncompute %88  [sum]
  call void @cqrt_free(i32 %90)    ; IR: release the %88 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %89, i32 %0, double %83)    ; IR: uncompute %88  [product]
  call void @cqrt_free(i32 %89)    ; IR: release the %88 product rail (|0>)
  call void @cqrt_or_i1(i32 %78, i32 %75, i32 %79)    ; IR: uncompute %77  [self-inverse]
  call void @cqrt_free(i32 %79)    ; IR: release the %77 rail (|0>)
  call void @cqrt_free(i32 %78)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %73, i32 %74, i32 %75)    ; IR: uncompute %74  [self-inverse]
  call void @cqrt_free(i32 %75)    ; IR: release the %74 rail (|0>)
  call void @cqrt_free(i32 %74)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %73, i32 %43, double 0x7FF0000000000000)    ; IR: uncompute %73
  call void @cqrt_free(i32 %73)    ; IR: release the %73 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %71, i32 %70, double 0x7FF0000000000000)    ; IR: uncompute %70
  call void @cqrt_free(i32 %71)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %70, i32 %68, double %69)    ; IR: uncompute %69  [sum]
  call void @cqrt_free(i32 %70)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %68, i32 %67, double %16)    ; IR: uncompute %68
  call void @cqrt_free(i32 %68)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %67, i32 %58)    ; IR: uncompute %67
  call void @cqrt_free(i32 %67)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %66, i32 %65, double 0x7FF0000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %66)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %65, i32 %64, double %63)    ; IR: uncompute %65  [sum]
  call void @cqrt_free(i32 %65)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %64, i32 %58, double %15)    ; IR: uncompute %65  [product]
  call void @cqrt_free(i32 %64)    ; IR: release the %65 product rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %58, i32 %57, i32 %0)    ; IR: uncompute %59
  call void @cqrt_free(i32 %58)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %57, i32 %44, double 0.000000e+00, double 1.000000e+00)    ; IR: uncompute %58
  call void @cqrt_free(i32 %57)    ; IR: release the %58 rail (|0>)
  call void @cqrt_or_i1(i32 %52, i32 %55, i32 %56)    ; IR: uncompute %56  [self-inverse]
  call void @cqrt_free(i32 %56)    ; IR: release the %56 rail (|0>)
  call void @cqrt_free(i32 %55)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %48, i32 %51, i32 %52)    ; IR: uncompute %53  [self-inverse]
  call void @cqrt_free(i32 %52)    ; IR: release the %53 rail (|0>)
  call void @cqrt_free(i32 %51)    ; IR: release the seed rail (basis state)
  call void @cqrt_and_i1(i32 %44, i32 %47, i32 %48)    ; IR: uncompute %50  [self-inverse]
  call void @cqrt_free(i32 %48)    ; IR: release the %50 rail (|0>)
  call void @cqrt_free(i32 %47)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %44, i32 %43, double 0x7FF0000000000000)    ; IR: uncompute %47
  call void @cqrt_free(i32 %44)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %43, i32 %0)    ; IR: uncompute %46
  call void @cqrt_free(i32 %43)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %41, i32 %0, double %40)    ; IR: uncompute %43
  call void @cqrt_free(i32 %41)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %36, i32 %38, i32 %39)    ; IR: uncompute %40  [self-inverse]
  call void @cqrt_free(i32 %39)    ; IR: release the %40 rail (|0>)
  call void @cqrt_free(i32 %38)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %36, i32 %0, double 0.000000e+00)    ; IR: uncompute %38
  call void @cqrt_free(i32 %36)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %32, i32 %33, i32 %34)    ; IR: uncompute %34  [self-inverse]
  call void @cqrt_free(i32 %34)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %33, i32 %31, double 0.000000e+00)    ; IR: uncompute %33
  call void @cqrt_free(i32 %33)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %32, i32 %25, double 0.000000e+00)    ; IR: uncompute %32
  call void @cqrt_free(i32 %32)    ; IR: release the %32 rail (|0>)
  call fastcc void @__cq_q_scalbn_10_unc(i32 %31, i32 %30, i32 %24)    ; IR: uncompute the result rail(s) of %31
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_hl_unc(i32 %30, i32 %29, double %19)    ; IR: uncompute %30
  call void @cqrt_free(i32 %30)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %29, i32 %27, double %28)    ; IR: uncompute %29  [sum]
  call void @cqrt_free(i32 %29)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %27, i32 %0, double %26)    ; IR: uncompute %28
  call void @cqrt_free(i32 %27)    ; IR: release the %28 rail (|0>)
  call fastcc void @__cq_q_scalbn_10_unc(i32 %25, i32 %23, i32 %24)    ; IR: uncompute the result rail(s) of %26
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_hl_unc(i32 %23, i32 %22, double %19)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %22, i32 %21, double %20)    ; IR: uncompute %23  [sum]
  call void @cqrt_free(i32 %22)    ; IR: release the %23 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %21, i32 %0, double %15)    ; IR: uncompute %23  [product]
  call void @cqrt_free(i32 %21)    ; IR: release the %23 product rail (|0>)
  %112 = insertvalue { i32, i32 } poison, i32 %110, 0    ; IR: ret: field 0 (handle)
  %113 = insertvalue { i32, i32 } %112, i32 %111, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %113    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc void @__cq_q___divdc3_1000_unc(i32 %0, i32 %1, i32 %2, double %3, double %4, double %5) {
  %7 = tail call double @llvm.fabs.f64(double %4)    ; IR: %5 = fabs(c)  (classical)
  %8 = tail call double @llvm.fabs.f64(double %5)    ; IR: %6 = fabs(d)  (classical)
  %9 = tail call double @llvm.maxnum.f64(double %7, double %8)    ; IR: %7 = maxnum(%5, %6)  (fmax)  (classical)
  %10 = tail call double @logb(double noundef %9)    ; IR: %8 = logb(%7)  (classical)
  %11 = tail call double @llvm.fabs.f64(double %10)    ; IR: %9 = fabs(%8)  (classical)
  %12 = fcmp ueq double %11, 0x7FF0000000000000    ; IR: %10 = fcmp ueq %9, inf  (!isfinite(logbw))  [br %10 -> %16, else block %11]  (classical)
  %13 = fptosi double %10 to i32    ; IR: %12 = fptosi %8 to i32  (block %11)  (classical)
  %14 = sub i32 0, %13    ; IR: %13 = sub nsw 0, %12  (classical)
  %15 = tail call double @scalbn(double noundef %4, i32 noundef %14)    ; IR: %14 = scalbn(c, %13)  (classical)
  %16 = tail call double @scalbn(double noundef %5, i32 noundef %14)    ; IR: %15 = scalbn(d, %13)  (classical)
  %17 = select i1 %12, double %4, double %15    ; IR: %17 = phi [ %14, %11 ], [ %2, %4 ]  (c; the %10 edge keeps c)  (classical)
  %18 = select i1 %12, double %5, double %16    ; IR: %18 = phi [ %15, %11 ], [ %3, %4 ]  (d)  (classical)
  %19 = select i1 %12, i32 0, i32 %13    ; IR: %19 = phi [ %12, %11 ], [ 0, %4 ]  (ilogbw)  (classical)
  %20 = fmul double %18, %18    ; IR: %20 = fmul %18, %18  (classical)
  %21 = tail call double @llvm.fmuladd.f64(double %17, double %17, double %20)    ; IR: %21 = fmuladd(%17, %17, %20)  (denom)  (classical)
  %22 = fmul double %18, %3    ; IR: %22 = fmul %18, %1  (classical)
  %23 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %17)    ; IR: %23 = fmuladd(%0, %17, %22)  [unfused product]
  %24 = call i32 @cq_template_fadd_f64_hl(i32 %23, double %22)    ; IR: %23 = fmuladd(%0, %17, %22)  [unfused sum]
  %25 = call i32 @cq_template_fdiv_f64_hl(i32 %24, double %21)    ; IR: %24 = fdiv %23, %21
  %26 = sub i32 0, %19    ; IR: %25 = sub nsw 0, %19  (classical)
  %27 = call fastcc i32 @__cq_q_scalbn_10(i32 %25, i32 %26)    ; IR: %26 = scalbn(%24, %25)  (real z), quantum clone (mask 10, injected musl body)
  %28 = fneg double %18    ; IR: %27 = fneg %18  (classical)
  %29 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %28)    ; IR: %28 = fmul %27, %0  (commutative, quantum operand first)
  %30 = fmul double %3, %17    ; IR: %29 = fmuladd(%1, %17, %28)  [unfused product]  (classical)
  %31 = call i32 @cq_template_fadd_f64_hl(i32 %29, double %30)    ; IR: %29 = fmuladd(%1, %17, %28)  [unfused sum]  (commutative, quantum operand first)
  %32 = call i32 @cq_template_fdiv_f64_hl(i32 %31, double %21)    ; IR: %30 = fdiv %29, %21
  %33 = call fastcc i32 @__cq_q_scalbn_10(i32 %32, i32 %26)    ; IR: %31 = scalbn(%30, %25)  (imag z), quantum clone (mask 10, injected musl body)
  %34 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %27, double 0.000000e+00)    ; IR: %32 = fcmp ord %26, 0
  %35 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %33, double 0.000000e+00)    ; IR: %33 = fcmp ord %31, 0
  %36 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %34, i32 %35, i32 %36)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]
  %37 = fcmp oeq double %21, 0.000000e+00    ; IR: %36 = fcmp oeq %21, 0  (denom == 0; block %35)  (classical)
  %38 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %2, double 0.000000e+00)    ; IR: %38 = fcmp ord %0, 0  (block %37)
  %39 = fcmp ord double %3, 0.000000e+00    ; IR: %39 = fcmp ord %1, 0  (classical)
  %40 = call i32 @cqrt_alloc_i1(i1 %39)    ; IR: %40 = or i1 %38, %39  [the classical conjunct %37 as a seed rail, rule 7]
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %40 = or i1 %38, %39  [fresh flag rail]
  call void @cqrt_or_i1(i32 %38, i32 %40, i32 %41)    ; IR: %40 = or i1 %38, %39
  %42 = tail call double @llvm.copysign.f64(double 0x7FF0000000000000, double %17)    ; IR: %42 = copysign(inf, %17)  (block %41)  (classical)
  %43 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %42)    ; IR: %43 = fmul %42, %0  (commutative, quantum operand first)
  %44 = fmul double %42, %3    ; IR: %44 = fmul %42, %1  (classical)
  %45 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %46 = fabs(a)  (block %45)
  %46 = call i32 @cq_template_fcmp_une_f64_hl(i32 %45, double 0x7FF0000000000000)    ; IR: %47 = !isinf(a)
  %47 = tail call double @llvm.fabs.f64(double %3)    ; IR: %48 = fabs(b)  (classical)
  %48 = fcmp une double %47, 0x7FF0000000000000    ; IR: %49 = !isinf(b)  (classical)
  %49 = call i32 @cqrt_alloc_i1(i1 %48)    ; IR: %50 = and i1 %47, %49  [the classical conjunct %46 as a seed rail, rule 7]
  %50 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %50 = and i1 %47, %49  [fresh flag rail]
  call void @cqrt_and_i1(i32 %46, i32 %49, i32 %50)    ; IR: %50 = and i1 %47, %49
  %51 = tail call double @llvm.fabs.f64(double %17)    ; IR: %51 = fabs(%17)  (classical)
  %52 = fcmp ueq double %51, 0x7FF0000000000000    ; IR: %52 = !isfinite(%17)  (classical)
  %53 = call i32 @cqrt_alloc_i1(i1 %52)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [the classical conjunct %50 as a seed rail, rule 7]
  %54 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [fresh flag rail]
  call void @cqrt_or_i1(i32 %50, i32 %53, i32 %54)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52
  %55 = tail call double @llvm.fabs.f64(double %18)    ; IR: %54 = fabs(%18)  (classical)
  %56 = fcmp ueq double %55, 0x7FF0000000000000    ; IR: %55 = !isfinite(%18)  (classical)
  %57 = call i32 @cqrt_alloc_i1(i1 %56)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]  [the classical conjunct %54 as a seed rail, rule 7]
  %58 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %54, i32 %57, i32 %58)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]
  %59 = call i32 @cq_template_select_f64_ll(i32 %46, double 0.000000e+00, double 1.000000e+00)    ; IR: %58 = select %47, 0.0, 1.0  (block %57)
  %60 = call i32 @cq_template_copysign_f64(i32 %59, i32 %2)    ; IR: %59 = copysign(%58, a)
  %61 = tail call double @llvm.fabs.f64(double %3)    ; IR: %60 = fabs(b)  (classical)
  %62 = fcmp une double %61, 0x7FF0000000000000    ; IR: %61 = !isinf(b)  (classical)
  %63 = select i1 %62, double 0.000000e+00, double 1.000000e+00    ; IR: %62 = select %61, 0.0, 1.0  (classical)
  %64 = tail call double @llvm.copysign.f64(double %63, double %3)    ; IR: %63 = copysign(%62, b)  (classical)
  %65 = fmul double %64, %18    ; IR: %64 = fmul %63, %18  (classical)
  %66 = call i32 @cq_template_fmul_f64_hl(i32 %60, double %17)    ; IR: %65 = fmuladd(%59, %17, %64)  [unfused product]
  %67 = call i32 @cq_template_fadd_f64_hl(i32 %66, double %65)    ; IR: %65 = fmuladd(%59, %17, %64)  [unfused sum]
  %68 = call i32 @cq_template_fmul_f64_hl(i32 %67, double 0x7FF0000000000000)    ; IR: %66 = fmul %65, inf
  %69 = call i32 @cq_template_fneg_f64(i32 %60)    ; IR: %67 = fneg %59
  %70 = call i32 @cq_template_fmul_f64_hl(i32 %69, double %18)    ; IR: %68 = fmul %18, %67  (commutative, quantum operand first)
  %71 = fmul double %64, %17    ; IR: %69 = fmuladd(%63, %17, %68)  [unfused product]  (classical)
  %72 = call i32 @cq_template_fadd_f64_hl(i32 %70, double %71)    ; IR: %69 = fmuladd(%63, %17, %68)  [unfused sum]  (commutative, quantum operand first)
  %73 = call i32 @cq_template_fmul_f64_hl(i32 %72, double 0x7FF0000000000000)    ; IR: %70 = fmul %69, inf
  %74 = fcmp une double %10, 0x7FF0000000000000    ; IR: %72 = fcmp une %8, inf  (block %71)  (classical)
  %75 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %45, double 0x7FF0000000000000)    ; IR: %73 = fcmp ueq %46, inf
  %76 = call i32 @cqrt_alloc_i1(i1 %74)    ; IR: %74 = or i1 %73, %72  [the classical conjunct %70 as a seed rail, rule 7]
  %77 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %74 = or i1 %73, %72  [fresh flag rail]
  call void @cqrt_or_i1(i32 %75, i32 %76, i32 %77)    ; IR: %74 = or i1 %73, %72
  %78 = tail call double @llvm.fabs.f64(double %3)    ; IR: %75 = fabs(b)  (classical)
  %79 = fcmp ueq double %78, 0x7FF0000000000000    ; IR: %76 = fcmp ueq %75, inf  (classical)
  %80 = call i32 @cqrt_alloc_i1(i1 %79)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [the classical conjunct %75 as a seed rail, rule 7]
  %81 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %80, i32 %77, i32 %81)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]
  %82 = tail call double @llvm.fabs.f64(double %17)    ; IR: %79 = fabs(%17)  (block %78)  (classical)
  %83 = fcmp une double %82, 0x7FF0000000000000    ; IR: %80 = !isinf(%17)  (classical)
  %84 = select i1 %83, double 0.000000e+00, double 1.000000e+00    ; IR: %81 = select %80, 0.0, 1.0  (classical)
  %85 = tail call double @llvm.copysign.f64(double %84, double %17)    ; IR: %82 = copysign(%81, %17)  (classical)
  %86 = tail call double @llvm.fabs.f64(double %18)    ; IR: %83 = fabs(%18)  (classical)
  %87 = fcmp une double %86, 0x7FF0000000000000    ; IR: %84 = !isinf(%18)  (classical)
  %88 = select i1 %87, double 0.000000e+00, double 1.000000e+00    ; IR: %85 = select %84, 0.0, 1.0  (classical)
  %89 = tail call double @llvm.copysign.f64(double %88, double %18)    ; IR: %86 = copysign(%85, %18)  (classical)
  %90 = fmul double %89, %3    ; IR: %87 = fmul %86, %1  (classical)
  %91 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %85)    ; IR: %88 = fmuladd(%0, %82, %87)  [unfused product]
  %92 = call i32 @cq_template_fadd_f64_hl(i32 %91, double %90)    ; IR: %88 = fmuladd(%0, %82, %87)  [unfused sum]
  %93 = call i32 @cq_template_fmul_f64_hl(i32 %92, double 0.000000e+00)    ; IR: %89 = fmul %88, 0.0
  %94 = fneg double %89    ; IR: %90 = fneg %86  (classical)
  %95 = call i32 @cq_template_fmul_f64_hl(i32 %2, double %94)    ; IR: %91 = fmul %90, %0  (commutative, quantum operand first)
  %96 = fmul double %3, %85    ; IR: %92 = fmuladd(%1, %82, %91)  [unfused product]  (classical)
  %97 = call i32 @cq_template_fadd_f64_hl(i32 %95, double %96)    ; IR: %92 = fmuladd(%1, %82, %91)  [unfused sum]  (commutative, quantum operand first)
  %98 = call i32 @cq_template_fmul_f64_hl(i32 %97, double 0.000000e+00)    ; IR: %93 = fmul %92, 0.0
  %99 = call i32 @cqrt_alloc_i1(i1 %37)    ; IR: P37 = path predicate of block %37: !%34 & %36  [the classical conjunct %35 as a seed rail, rule 7]
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P37 reads NOT %34
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P37 = path predicate of block %37: !%34 & %36  [fresh flag rail]
  call void @cqrt_and_i1(i32 %36, i32 %99, i32 %100)    ; IR: P37 = path predicate of block %37: !%34 & %36
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P37 reads NOT %34
  %101 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P41 = path predicate of block %41: P37 & %40  [fresh flag rail]
  call void @cqrt_and_i1(i32 %100, i32 %41, i32 %101)    ; IR: P41 = path predicate of block %41: P37 & %40
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P45 reads NOT %34
  call void @cqrt_not_i1(i32 %101)    ; IR: bracket: P45 reads NOT %95
  %102 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %36, i32 %101, i32 %102)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P45 reads NOT %34
  call void @cqrt_not_i1(i32 %101)    ; IR: bracket (close): P45 reads NOT %95
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket: P57 reads NOT %56
  %103 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P57 = path predicate of block %57: P45 & !%56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %102, i32 %58, i32 %103)    ; IR: P57 = path predicate of block %57: P45 & !%56
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket (close): P57 reads NOT %56
  %104 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P71 = path predicate of block %71: P45 & %56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %102, i32 %58, i32 %104)    ; IR: P71 = path predicate of block %71: P45 & %56
  call void @cqrt_not_i1(i32 %81)    ; IR: bracket: P78 reads NOT %77
  %105 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P78 = path predicate of block %78: P71 & !%77  [fresh flag rail]
  call void @cqrt_and_i1(i32 %104, i32 %81, i32 %105)    ; IR: P78 = path predicate of block %78: P71 & !%77
  call void @cqrt_not_i1(i32 %81)    ; IR: bracket (close): P78 reads NOT %77
  %106 = call i32 @cq_template_select_f64_lh(i32 %101, double %44, i32 %33)    ; IR: %95 = phi [ %70, %57 ], [ %93, %78 ], [ %31, %71 ], [ %44, %41 ], [ %31, %16 ]: innermost select, the %41 arm against the complement %31
  %107 = call i32 @cq_template_select_f64(i32 %105, i32 %98, i32 %106)    ; IR: %95 = phi (imag result): the %78 arm
  %108 = call i32 @cq_template_select_f64(i32 %103, i32 %73, i32 %107)    ; IR: %95 = phi (imag result): the %57 arm
  %109 = call i32 @cq_template_select_f64(i32 %101, i32 %43, i32 %27)    ; IR: %96 = phi [ %66, %57 ], [ %89, %78 ], [ %26, %71 ], [ %43, %41 ], [ %26, %16 ]: innermost select, the %41 arm against the complement %26
  %110 = call i32 @cq_template_select_f64(i32 %105, i32 %93, i32 %109)    ; IR: %96 = phi (real result): the %78 arm
  %111 = call i32 @cq_template_select_f64(i32 %103, i32 %68, i32 %110)    ; IR: %96 = phi (real result): the %57 arm
  call void @cqrt_copy_f64(i32 %111, i32 %0)    ; IR: xor real out of the result rail
  call void @cqrt_copy_f64(i32 %108, i32 %1)    ; IR: xor imaginary out of the result rail
  call void @cq_template_select_f64_unc(i32 %111, i32 %103, i32 %68, i32 %110)    ; IR: uncompute %96
  call void @cqrt_free(i32 %111)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %110, i32 %105, i32 %93, i32 %109)    ; IR: uncompute %96
  call void @cqrt_free(i32 %110)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %109, i32 %101, i32 %43, i32 %27)    ; IR: uncompute %96
  call void @cqrt_free(i32 %109)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %108, i32 %103, i32 %73, i32 %107)    ; IR: uncompute %95
  call void @cqrt_free(i32 %108)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %107, i32 %105, i32 %98, i32 %106)    ; IR: uncompute %95
  call void @cqrt_free(i32 %107)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %106, i32 %101, double %44, i32 %33)    ; IR: uncompute %95
  call void @cqrt_free(i32 %106)    ; IR: release the %95 rail (|0>)
  call void @cqrt_not_i1(i32 %81)    ; IR: bracket: P78 reads NOT %77
  call void @cqrt_and_i1(i32 %104, i32 %81, i32 %105)    ; IR: uncompute P78  [self-inverse]
  call void @cqrt_free(i32 %105)    ; IR: release the P78 rail (|0>)
  call void @cqrt_not_i1(i32 %81)    ; IR: bracket (close): P78 reads NOT %77
  call void @cqrt_and_i1(i32 %102, i32 %58, i32 %104)    ; IR: uncompute P71  [self-inverse]
  call void @cqrt_free(i32 %104)    ; IR: release the P71 rail (|0>)
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket: P57 reads NOT %56
  call void @cqrt_and_i1(i32 %102, i32 %58, i32 %103)    ; IR: uncompute P57  [self-inverse]
  call void @cqrt_free(i32 %103)    ; IR: release the P57 rail (|0>)
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket (close): P57 reads NOT %56
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P45 reads NOT %34
  call void @cqrt_not_i1(i32 %101)    ; IR: bracket: P45 reads NOT %95
  call void @cqrt_and_i1(i32 %36, i32 %101, i32 %102)    ; IR: uncompute P45  [self-inverse]
  call void @cqrt_free(i32 %102)    ; IR: release the P45 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P45 reads NOT %34
  call void @cqrt_not_i1(i32 %101)    ; IR: bracket (close): P45 reads NOT %95
  call void @cqrt_and_i1(i32 %100, i32 %41, i32 %101)    ; IR: uncompute P41  [self-inverse]
  call void @cqrt_free(i32 %101)    ; IR: release the P41 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket: P37 reads NOT %34
  call void @cqrt_and_i1(i32 %36, i32 %99, i32 %100)    ; IR: uncompute P37  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P37 rail (|0>)
  call void @cqrt_not_i1(i32 %36)    ; IR: bracket (close): P37 reads NOT %34
  call void @cqrt_free(i32 %99)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f64_hl_unc(i32 %98, i32 %97, double 0.000000e+00)    ; IR: uncompute %93
  call void @cqrt_free(i32 %98)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %97, i32 %95, double %96)    ; IR: uncompute %92  [sum]
  call void @cqrt_free(i32 %97)    ; IR: release the %92 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %95, i32 %2, double %94)    ; IR: uncompute %91
  call void @cqrt_free(i32 %95)    ; IR: release the %91 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %93, i32 %92, double 0.000000e+00)    ; IR: uncompute %89
  call void @cqrt_free(i32 %93)    ; IR: release the %89 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %92, i32 %91, double %90)    ; IR: uncompute %88  [sum]
  call void @cqrt_free(i32 %92)    ; IR: release the %88 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %91, i32 %2, double %85)    ; IR: uncompute %88  [product]
  call void @cqrt_free(i32 %91)    ; IR: release the %88 product rail (|0>)
  call void @cqrt_or_i1(i32 %80, i32 %77, i32 %81)    ; IR: uncompute %77  [self-inverse]
  call void @cqrt_free(i32 %81)    ; IR: release the %77 rail (|0>)
  call void @cqrt_free(i32 %80)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %75, i32 %76, i32 %77)    ; IR: uncompute %74  [self-inverse]
  call void @cqrt_free(i32 %77)    ; IR: release the %74 rail (|0>)
  call void @cqrt_free(i32 %76)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %75, i32 %45, double 0x7FF0000000000000)    ; IR: uncompute %73
  call void @cqrt_free(i32 %75)    ; IR: release the %73 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %73, i32 %72, double 0x7FF0000000000000)    ; IR: uncompute %70
  call void @cqrt_free(i32 %73)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %72, i32 %70, double %71)    ; IR: uncompute %69  [sum]
  call void @cqrt_free(i32 %72)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %70, i32 %69, double %18)    ; IR: uncompute %68
  call void @cqrt_free(i32 %70)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %69, i32 %60)    ; IR: uncompute %67
  call void @cqrt_free(i32 %69)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %68, i32 %67, double 0x7FF0000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %68)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %67, i32 %66, double %65)    ; IR: uncompute %65  [sum]
  call void @cqrt_free(i32 %67)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %66, i32 %60, double %17)    ; IR: uncompute %65  [product]
  call void @cqrt_free(i32 %66)    ; IR: release the %65 product rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %60, i32 %59, i32 %2)    ; IR: uncompute %59
  call void @cqrt_free(i32 %60)    ; IR: release the %59 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %59, i32 %46, double 0.000000e+00, double 1.000000e+00)    ; IR: uncompute %58
  call void @cqrt_free(i32 %59)    ; IR: release the %58 rail (|0>)
  call void @cqrt_or_i1(i32 %54, i32 %57, i32 %58)    ; IR: uncompute %56  [self-inverse]
  call void @cqrt_free(i32 %58)    ; IR: release the %56 rail (|0>)
  call void @cqrt_free(i32 %57)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %50, i32 %53, i32 %54)    ; IR: uncompute %53  [self-inverse]
  call void @cqrt_free(i32 %54)    ; IR: release the %53 rail (|0>)
  call void @cqrt_free(i32 %53)    ; IR: release the seed rail (basis state)
  call void @cqrt_and_i1(i32 %46, i32 %49, i32 %50)    ; IR: uncompute %50  [self-inverse]
  call void @cqrt_free(i32 %50)    ; IR: release the %50 rail (|0>)
  call void @cqrt_free(i32 %49)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %46, i32 %45, double 0x7FF0000000000000)    ; IR: uncompute %47
  call void @cqrt_free(i32 %46)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %45, i32 %2)    ; IR: uncompute %46
  call void @cqrt_free(i32 %45)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %43, i32 %2, double %42)    ; IR: uncompute %43
  call void @cqrt_free(i32 %43)    ; IR: release the %43 rail (|0>)
  call void @cqrt_or_i1(i32 %38, i32 %40, i32 %41)    ; IR: uncompute %40  [self-inverse]
  call void @cqrt_free(i32 %41)    ; IR: release the %40 rail (|0>)
  call void @cqrt_free(i32 %40)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %38, i32 %2, double 0.000000e+00)    ; IR: uncompute %38
  call void @cqrt_free(i32 %38)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %34, i32 %35, i32 %36)    ; IR: uncompute %34  [self-inverse]
  call void @cqrt_free(i32 %36)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %35, i32 %33, double 0.000000e+00)    ; IR: uncompute %33
  call void @cqrt_free(i32 %35)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %34, i32 %27, double 0.000000e+00)    ; IR: uncompute %32
  call void @cqrt_free(i32 %34)    ; IR: release the %32 rail (|0>)
  call fastcc void @__cq_q_scalbn_10_unc(i32 %33, i32 %32, i32 %26)    ; IR: uncompute the result rail(s) of %31
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_hl_unc(i32 %32, i32 %31, double %21)    ; IR: uncompute %30
  call void @cqrt_free(i32 %32)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %31, i32 %29, double %30)    ; IR: uncompute %29  [sum]
  call void @cqrt_free(i32 %31)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %29, i32 %2, double %28)    ; IR: uncompute %28
  call void @cqrt_free(i32 %29)    ; IR: release the %28 rail (|0>)
  call fastcc void @__cq_q_scalbn_10_unc(i32 %27, i32 %25, i32 %26)    ; IR: uncompute the result rail(s) of %26
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_hl_unc(i32 %25, i32 %24, double %21)    ; IR: uncompute %24
  call void @cqrt_free(i32 %25)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %24, i32 %23, double %22)    ; IR: uncompute %23  [sum]
  call void @cqrt_free(i32 %24)    ; IR: release the %23 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %23, i32 %2, double %17)    ; IR: uncompute %23  [product]
  call void @cqrt_free(i32 %23)    ; IR: release the %23 product rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

define internal fastcc { i32, i32 } @__cq_q___divdc3_0011(double %0, double %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %5 = fabs(c)
  %6 = call i32 @cq_template_fabs_f64(i32 %3)    ; IR: %6 = fabs(d)
  %7 = call i32 @cq_template_fmax_f64(i32 %5, i32 %6)    ; IR: %7 = maxnum(%5, %6)  (fmax)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: the caller's flags rail for the fenv ABI of the strictfp callee (82): __divdc3 has no FENV_ACCESS, so its environment is the default: an EMPTY flags rail (|0>, rule 7) and the default mode literal 0 (FE_TONEAREST)
  %9 = call fastcc { i32, i32 } @__cq_q_logb_1(i32 %7, i32 0, i32 %8)    ; IR: %8 = logb(%7), quantum clone (mask 1, injected musl logb.c; it calls the strictfp ilogb clone) + mode + flags
  %10 = extractvalue { i32, i32 } %9, 0    ; IR: %8  [result rail]
  %11 = extractvalue { i32, i32 } %9, 1    ; IR: %8: the flags after logb (fenv state the program never reads: dropped below)
  %12 = call i32 @cq_template_fabs_f64(i32 %10)    ; IR: %9 = fabs(%8)
  %13 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %12, double 0x7FF0000000000000)    ; IR: %10 = fcmp ueq %9, inf  (!isfinite(logbw))  [br %10 -> %16, else block %11]
  %14 = call i32 @cq_template_fptosi_f64_to_i32(i32 %10)    ; IR: %12 = fptosi %8 to i32  (block %11)
  %15 = call i32 @cq_template_sub_i32_lh(i32 0, i32 %14)    ; IR: %13 = sub nsw 0, %12
  %16 = call fastcc i32 @__cq_q_scalbn_11(i32 %2, i32 %15)    ; IR: %14 = scalbn(c, %13), quantum clone (mask 11, injected musl body)
  %17 = call fastcc i32 @__cq_q_scalbn_11(i32 %3, i32 %15)    ; IR: %15 = scalbn(d, %13), quantum clone (mask 11, injected musl body)
  %18 = call i32 @cq_template_select_f64(i32 %13, i32 %2, i32 %16)    ; IR: %17 = phi [ %14, %11 ], [ %2, %4 ]  (c; the %10 edge keeps c)
  %19 = call i32 @cq_template_select_f64(i32 %13, i32 %3, i32 %17)    ; IR: %18 = phi [ %15, %11 ], [ %3, %4 ]  (d)
  %20 = call i32 @cq_template_select_i32_lh(i32 %13, i32 0, i32 %14)    ; IR: %19 = phi [ %12, %11 ], [ 0, %4 ]  (ilogbw)
  %21 = call i32 @cq_template_fmul_f64(i32 %19, i32 %19)    ; IR: %20 = fmul %18, %18
  %22 = call i32 @cq_template_fmul_f64(i32 %18, i32 %18)    ; IR: %21 = fmuladd(%17, %17, %20)  (denom)  [unfused product]
  %23 = call i32 @cq_template_fadd_f64(i32 %22, i32 %21)    ; IR: %21 = fmuladd(%17, %17, %20)  (denom)  [unfused sum]
  %24 = call i32 @cq_template_fmul_f64_hl(i32 %19, double %1)    ; IR: %22 = fmul %18, %1
  %25 = call i32 @cq_template_fmul_f64_hl(i32 %18, double %0)    ; IR: %23 = fmuladd(%0, %17, %22)  (commutative product, quantum factor first)  [unfused product]
  %26 = call i32 @cq_template_fadd_f64(i32 %25, i32 %24)    ; IR: %23 = fmuladd(%0, %17, %22)  (commutative product, quantum factor first)  [unfused sum]
  %27 = call i32 @cq_template_fdiv_f64(i32 %26, i32 %23)    ; IR: %24 = fdiv %23, %21
  %28 = call i32 @cq_template_sub_i32_lh(i32 0, i32 %20)    ; IR: %25 = sub nsw 0, %19
  %29 = call fastcc i32 @__cq_q_scalbn_11(i32 %27, i32 %28)    ; IR: %26 = scalbn(%24, %25)  (real z), quantum clone (mask 11, injected musl body)
  %30 = call i32 @cq_template_fneg_f64(i32 %19)    ; IR: %27 = fneg %18
  %31 = call i32 @cq_template_fmul_f64_hl(i32 %30, double %0)    ; IR: %28 = fmul %27, %0
  %32 = call i32 @cq_template_fmul_f64_hl(i32 %18, double %1)    ; IR: %29 = fmuladd(%1, %17, %28)  (commutative product, quantum factor first)  [unfused product]
  %33 = call i32 @cq_template_fadd_f64(i32 %32, i32 %31)    ; IR: %29 = fmuladd(%1, %17, %28)  (commutative product, quantum factor first)  [unfused sum]
  %34 = call i32 @cq_template_fdiv_f64(i32 %33, i32 %23)    ; IR: %30 = fdiv %29, %21
  %35 = call fastcc i32 @__cq_q_scalbn_11(i32 %34, i32 %28)    ; IR: %31 = scalbn(%30, %25)  (imag z), quantum clone (mask 11, injected musl body)
  %36 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %29, double 0.000000e+00)    ; IR: %32 = fcmp ord %26, 0
  %37 = call i32 @cq_template_fcmp_ord_f64_hl(i32 %35, double 0.000000e+00)    ; IR: %33 = fcmp ord %31, 0
  %38 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %36, i32 %37, i32 %38)    ; IR: %34 = select i1 %32, true, %33 = %32 | %33  [br %34 -> exit %94; block %35 runs under !%34]
  %39 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %23, double 0.000000e+00)    ; IR: %36 = fcmp oeq %21, 0  (denom == 0; block %35)
  %40 = fcmp ord double %0, 0.000000e+00    ; IR: %38 = fcmp ord %0, 0  (block %37)  (classical)
  %41 = fcmp ord double %1, 0.000000e+00    ; IR: %39 = fcmp ord %1, 0  (classical)
  %42 = or i1 %40, %41    ; IR: %40 = or i1 %38, %39  (classical)
  %43 = call i32 @cq_template_copysign_f64_lh(double 0x7FF0000000000000, i32 %18)    ; IR: %42 = copysign(inf, %17)  (block %41)
  %44 = call i32 @cq_template_fmul_f64_hl(i32 %43, double %0)    ; IR: %43 = fmul %42, %0
  %45 = call i32 @cq_template_fmul_f64_hl(i32 %43, double %1)    ; IR: %44 = fmul %42, %1
  %46 = tail call double @llvm.fabs.f64(double %0)    ; IR: %46 = fabs(a)  (block %45)  (classical)
  %47 = fcmp une double %46, 0x7FF0000000000000    ; IR: %47 = !isinf(a)  (classical)
  %48 = tail call double @llvm.fabs.f64(double %1)    ; IR: %48 = fabs(b)  (classical)
  %49 = fcmp une double %48, 0x7FF0000000000000    ; IR: %49 = !isinf(b)  (classical)
  %50 = and i1 %47, %49    ; IR: %50 = and i1 %47, %49  (classical)
  %51 = call i32 @cq_template_fabs_f64(i32 %18)    ; IR: %51 = fabs(%17)
  %52 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %51, double 0x7FF0000000000000)    ; IR: %52 = !isfinite(%17)
  %53 = call i32 @cqrt_alloc_i1(i1 %50)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [the classical conjunct %44 as a seed rail, rule 7]
  %54 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52  [fresh flag rail]
  call void @cqrt_or_i1(i32 %53, i32 %52, i32 %54)    ; IR: %53 = select i1 %50, true, %52 = %50 | %52
  %55 = call i32 @cq_template_fabs_f64(i32 %19)    ; IR: %54 = fabs(%18)
  %56 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %55, double 0x7FF0000000000000)    ; IR: %55 = !isfinite(%18)
  %57 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %54, i32 %56, i32 %57)    ; IR: %56 = select i1 %53, true, %55 = %53 | %55  [br %56 -> %71, else block %57]
  %58 = select i1 %47, double 0.000000e+00, double 1.000000e+00    ; IR: %58 = select %47, 0.0, 1.0  (block %57)  (classical)
  %59 = tail call double @llvm.copysign.f64(double %58, double %0)    ; IR: %59 = copysign(%58, a)  (classical)
  %60 = tail call double @llvm.fabs.f64(double %1)    ; IR: %60 = fabs(b)  (classical)
  %61 = fcmp une double %60, 0x7FF0000000000000    ; IR: %61 = !isinf(b)  (classical)
  %62 = select i1 %61, double 0.000000e+00, double 1.000000e+00    ; IR: %62 = select %61, 0.0, 1.0  (classical)
  %63 = tail call double @llvm.copysign.f64(double %62, double %1)    ; IR: %63 = copysign(%62, b)  (classical)
  %64 = call i32 @cq_template_fmul_f64_hl(i32 %19, double %63)    ; IR: %64 = fmul %63, %18  (commutative, quantum operand first)
  %65 = call i32 @cq_template_fmul_f64_hl(i32 %18, double %59)    ; IR: %65 = fmuladd(%59, %17, %64)  (commutative product, quantum factor first)  [unfused product]
  %66 = call i32 @cq_template_fadd_f64(i32 %65, i32 %64)    ; IR: %65 = fmuladd(%59, %17, %64)  (commutative product, quantum factor first)  [unfused sum]
  %67 = call i32 @cq_template_fmul_f64_hl(i32 %66, double 0x7FF0000000000000)    ; IR: %66 = fmul %65, inf
  %68 = fneg double %59    ; IR: %67 = fneg %59  (classical)
  %69 = call i32 @cq_template_fmul_f64_hl(i32 %19, double %68)    ; IR: %68 = fmul %18, %67
  %70 = call i32 @cq_template_fmul_f64_hl(i32 %18, double %63)    ; IR: %69 = fmuladd(%63, %17, %68)  (commutative product, quantum factor first)  [unfused product]
  %71 = call i32 @cq_template_fadd_f64(i32 %70, i32 %69)    ; IR: %69 = fmuladd(%63, %17, %68)  (commutative product, quantum factor first)  [unfused sum]
  %72 = call i32 @cq_template_fmul_f64_hl(i32 %71, double 0x7FF0000000000000)    ; IR: %70 = fmul %69, inf
  %73 = call i32 @cq_template_fcmp_une_f64_hl(i32 %10, double 0x7FF0000000000000)    ; IR: %72 = fcmp une %8, inf  (block %71)
  %74 = fcmp ueq double %46, 0x7FF0000000000000    ; IR: %73 = fcmp ueq %46, inf  (classical)
  %75 = call i32 @cqrt_alloc_i1(i1 %74)    ; IR: %74 = or i1 %73, %72  [the classical conjunct %66 as a seed rail, rule 7]
  %76 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %74 = or i1 %73, %72  [fresh flag rail]
  call void @cqrt_or_i1(i32 %75, i32 %73, i32 %76)    ; IR: %74 = or i1 %73, %72
  %77 = tail call double @llvm.fabs.f64(double %1)    ; IR: %75 = fabs(b)  (classical)
  %78 = fcmp ueq double %77, 0x7FF0000000000000    ; IR: %76 = fcmp ueq %75, inf  (classical)
  %79 = call i32 @cqrt_alloc_i1(i1 %78)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [the classical conjunct %70 as a seed rail, rule 7]
  %80 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %79, i32 %76, i32 %80)    ; IR: %77 = or i1 %76, %74  [br %77 -> exit %94, else block %78]
  %81 = call i32 @cq_template_fabs_f64(i32 %18)    ; IR: %79 = fabs(%17)  (block %78)
  %82 = call i32 @cq_template_fcmp_une_f64_hl(i32 %81, double 0x7FF0000000000000)    ; IR: %80 = !isinf(%17)
  %83 = call i32 @cq_template_select_f64_ll(i32 %82, double 0.000000e+00, double 1.000000e+00)    ; IR: %81 = select %80, 0.0, 1.0
  %84 = call i32 @cq_template_copysign_f64(i32 %83, i32 %18)    ; IR: %82 = copysign(%81, %17)
  %85 = call i32 @cq_template_fabs_f64(i32 %19)    ; IR: %83 = fabs(%18)
  %86 = call i32 @cq_template_fcmp_une_f64_hl(i32 %85, double 0x7FF0000000000000)    ; IR: %84 = !isinf(%18)
  %87 = call i32 @cq_template_select_f64_ll(i32 %86, double 0.000000e+00, double 1.000000e+00)    ; IR: %85 = select %84, 0.0, 1.0
  %88 = call i32 @cq_template_copysign_f64(i32 %87, i32 %19)    ; IR: %86 = copysign(%85, %18)
  %89 = call i32 @cq_template_fmul_f64_hl(i32 %88, double %1)    ; IR: %87 = fmul %86, %1
  %90 = call i32 @cq_template_fmul_f64_hl(i32 %84, double %0)    ; IR: %88 = fmuladd(%0, %82, %87)  (commutative product, quantum factor first)  [unfused product]
  %91 = call i32 @cq_template_fadd_f64(i32 %90, i32 %89)    ; IR: %88 = fmuladd(%0, %82, %87)  (commutative product, quantum factor first)  [unfused sum]
  %92 = call i32 @cq_template_fmul_f64_hl(i32 %91, double 0.000000e+00)    ; IR: %89 = fmul %88, 0.0
  %93 = call i32 @cq_template_fneg_f64(i32 %88)    ; IR: %90 = fneg %86
  %94 = call i32 @cq_template_fmul_f64_hl(i32 %93, double %0)    ; IR: %91 = fmul %90, %0
  %95 = call i32 @cq_template_fmul_f64_hl(i32 %84, double %1)    ; IR: %92 = fmuladd(%1, %82, %91)  (commutative product, quantum factor first)  [unfused product]
  %96 = call i32 @cq_template_fadd_f64(i32 %95, i32 %94)    ; IR: %92 = fmuladd(%1, %82, %91)  (commutative product, quantum factor first)  [unfused sum]
  %97 = call i32 @cq_template_fmul_f64_hl(i32 %96, double 0.000000e+00)    ; IR: %93 = fmul %92, 0.0
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket: P37 reads NOT %32
  %98 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P37 = path predicate of block %37: !%34 & %36  [fresh flag rail]
  call void @cqrt_and_i1(i32 %38, i32 %39, i32 %98)    ; IR: P37 = path predicate of block %37: !%34 & %36
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket (close): P37 reads NOT %32
  %99 = call i32 @cqrt_alloc_i1(i1 %42)    ; IR: P41 = path predicate of block %41: P37 & %40  [the classical conjunct %36 as a seed rail, rule 7]
  %100 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P41 = path predicate of block %41: P37 & %40  [fresh flag rail]
  call void @cqrt_and_i1(i32 %98, i32 %99, i32 %100)    ; IR: P41 = path predicate of block %41: P37 & %40
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %100)    ; IR: bracket: P45 reads NOT %90
  %101 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %38, i32 %100, i32 %101)    ; IR: P45 = path predicate of block %45: !%34 & !P41  (reached from %35 on !%36 or from %37 on !%40)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %100)    ; IR: bracket (close): P45 reads NOT %90
  call void @cqrt_not_i1(i32 %57)    ; IR: bracket: P57 reads NOT %51
  %102 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P57 = path predicate of block %57: P45 & !%56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %101, i32 %57, i32 %102)    ; IR: P57 = path predicate of block %57: P45 & !%56
  call void @cqrt_not_i1(i32 %57)    ; IR: bracket (close): P57 reads NOT %51
  %103 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P71 = path predicate of block %71: P45 & %56  [fresh flag rail]
  call void @cqrt_and_i1(i32 %101, i32 %57, i32 %103)    ; IR: P71 = path predicate of block %71: P45 & %56
  call void @cqrt_not_i1(i32 %80)    ; IR: bracket: P78 reads NOT %72
  %104 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P78 = path predicate of block %78: P71 & !%77  [fresh flag rail]
  call void @cqrt_and_i1(i32 %103, i32 %80, i32 %104)    ; IR: P78 = path predicate of block %78: P71 & !%77
  call void @cqrt_not_i1(i32 %80)    ; IR: bracket (close): P78 reads NOT %72
  %105 = call i32 @cq_template_select_f64(i32 %100, i32 %45, i32 %35)    ; IR: %95 = phi [ %70, %57 ], [ %93, %78 ], [ %31, %71 ], [ %44, %41 ], [ %31, %16 ]: innermost select, the %41 arm against the complement %31
  %106 = call i32 @cq_template_select_f64(i32 %104, i32 %97, i32 %105)    ; IR: %95 = phi (imag result): the %78 arm
  %107 = call i32 @cq_template_select_f64(i32 %102, i32 %72, i32 %106)    ; IR: %95 = phi (imag result): the %57 arm
  %108 = call i32 @cq_template_select_f64(i32 %100, i32 %44, i32 %29)    ; IR: %96 = phi [ %66, %57 ], [ %89, %78 ], [ %26, %71 ], [ %43, %41 ], [ %26, %16 ]: innermost select, the %41 arm against the complement %26
  %109 = call i32 @cq_template_select_f64(i32 %104, i32 %92, i32 %108)    ; IR: %96 = phi (real result): the %78 arm
  %110 = call i32 @cq_template_select_f64(i32 %102, i32 %67, i32 %109)    ; IR: %96 = phi (real result): the %57 arm
  %111 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: real]
  call void @cqrt_copy_f64(i32 %110, i32 %111)    ; IR: copy real out
  %112 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: imaginary]
  call void @cqrt_copy_f64(i32 %107, i32 %112)    ; IR: copy imaginary out
  call void @cq_template_select_f64_unc(i32 %110, i32 %102, i32 %67, i32 %109)    ; IR: uncompute %96
  call void @cqrt_free(i32 %110)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %109, i32 %104, i32 %92, i32 %108)    ; IR: uncompute %96
  call void @cqrt_free(i32 %109)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %108, i32 %100, i32 %44, i32 %29)    ; IR: uncompute %96
  call void @cqrt_free(i32 %108)    ; IR: release the %96 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %107, i32 %102, i32 %72, i32 %106)    ; IR: uncompute %95
  call void @cqrt_free(i32 %107)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %106, i32 %104, i32 %97, i32 %105)    ; IR: uncompute %95
  call void @cqrt_free(i32 %106)    ; IR: release the %95 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %105, i32 %100, i32 %45, i32 %35)    ; IR: uncompute %95
  call void @cqrt_free(i32 %105)    ; IR: release the %95 rail (|0>)
  call void @cqrt_not_i1(i32 %80)    ; IR: bracket: P78 reads NOT %72
  call void @cqrt_and_i1(i32 %103, i32 %80, i32 %104)    ; IR: uncompute P78  [self-inverse]
  call void @cqrt_free(i32 %104)    ; IR: release the P78 rail (|0>)
  call void @cqrt_not_i1(i32 %80)    ; IR: bracket (close): P78 reads NOT %72
  call void @cqrt_and_i1(i32 %101, i32 %57, i32 %103)    ; IR: uncompute P71  [self-inverse]
  call void @cqrt_free(i32 %103)    ; IR: release the P71 rail (|0>)
  call void @cqrt_not_i1(i32 %57)    ; IR: bracket: P57 reads NOT %51
  call void @cqrt_and_i1(i32 %101, i32 %57, i32 %102)    ; IR: uncompute P57  [self-inverse]
  call void @cqrt_free(i32 %102)    ; IR: release the P57 rail (|0>)
  call void @cqrt_not_i1(i32 %57)    ; IR: bracket (close): P57 reads NOT %51
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket: P45 reads NOT %32
  call void @cqrt_not_i1(i32 %100)    ; IR: bracket: P45 reads NOT %90
  call void @cqrt_and_i1(i32 %38, i32 %100, i32 %101)    ; IR: uncompute P45  [self-inverse]
  call void @cqrt_free(i32 %101)    ; IR: release the P45 rail (|0>)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket (close): P45 reads NOT %32
  call void @cqrt_not_i1(i32 %100)    ; IR: bracket (close): P45 reads NOT %90
  call void @cqrt_and_i1(i32 %98, i32 %99, i32 %100)    ; IR: uncompute P41  [self-inverse]
  call void @cqrt_free(i32 %100)    ; IR: release the P41 rail (|0>)
  call void @cqrt_free(i32 %99)    ; IR: release the seed rail (basis state)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket: P37 reads NOT %32
  call void @cqrt_and_i1(i32 %38, i32 %39, i32 %98)    ; IR: uncompute P37  [self-inverse]
  call void @cqrt_free(i32 %98)    ; IR: release the P37 rail (|0>)
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket (close): P37 reads NOT %32
  call void @cq_template_fmul_f64_hl_unc(i32 %97, i32 %96, double 0.000000e+00)    ; IR: uncompute %93
  call void @cqrt_free(i32 %97)    ; IR: release the %93 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %96, i32 %95, i32 %94)    ; IR: uncompute %92  [sum]
  call void @cqrt_free(i32 %96)    ; IR: release the %92 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %95, i32 %84, double %1)    ; IR: uncompute %92  [product]
  call void @cqrt_free(i32 %95)    ; IR: release the %92 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %94, i32 %93, double %0)    ; IR: uncompute %91
  call void @cqrt_free(i32 %94)    ; IR: release the %91 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %93, i32 %88)    ; IR: uncompute %90
  call void @cqrt_free(i32 %93)    ; IR: release the %90 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %92, i32 %91, double 0.000000e+00)    ; IR: uncompute %89
  call void @cqrt_free(i32 %92)    ; IR: release the %89 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %91, i32 %90, i32 %89)    ; IR: uncompute %88  [sum]
  call void @cqrt_free(i32 %91)    ; IR: release the %88 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %90, i32 %84, double %0)    ; IR: uncompute %88  [product]
  call void @cqrt_free(i32 %90)    ; IR: release the %88 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %89, i32 %88, double %1)    ; IR: uncompute %87
  call void @cqrt_free(i32 %89)    ; IR: release the %87 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %88, i32 %87, i32 %19)    ; IR: uncompute %86
  call void @cqrt_free(i32 %88)    ; IR: release the %86 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %87, i32 %86, double 0.000000e+00, double 1.000000e+00)    ; IR: uncompute %85
  call void @cqrt_free(i32 %87)    ; IR: release the %85 rail (|0>)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %86, i32 %85, double 0x7FF0000000000000)    ; IR: uncompute %84
  call void @cqrt_free(i32 %86)    ; IR: release the %84 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %85, i32 %19)    ; IR: uncompute %83
  call void @cqrt_free(i32 %85)    ; IR: release the %83 rail (|0>)
  call void @cq_template_copysign_f64_unc(i32 %84, i32 %83, i32 %18)    ; IR: uncompute %82
  call void @cqrt_free(i32 %84)    ; IR: release the %82 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %83, i32 %82, double 0.000000e+00, double 1.000000e+00)    ; IR: uncompute %81
  call void @cqrt_free(i32 %83)    ; IR: release the %81 rail (|0>)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %82, i32 %81, double 0x7FF0000000000000)    ; IR: uncompute %80
  call void @cqrt_free(i32 %82)    ; IR: release the %80 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %81, i32 %18)    ; IR: uncompute %79
  call void @cqrt_free(i32 %81)    ; IR: release the %79 rail (|0>)
  call void @cqrt_or_i1(i32 %79, i32 %76, i32 %80)    ; IR: uncompute %77  [self-inverse]
  call void @cqrt_free(i32 %80)    ; IR: release the %77 rail (|0>)
  call void @cqrt_free(i32 %79)    ; IR: release the seed rail (basis state)
  call void @cqrt_or_i1(i32 %75, i32 %73, i32 %76)    ; IR: uncompute %74  [self-inverse]
  call void @cqrt_free(i32 %76)    ; IR: release the %74 rail (|0>)
  call void @cqrt_free(i32 %75)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_une_f64_hl_unc(i32 %73, i32 %10, double 0x7FF0000000000000)    ; IR: uncompute %72
  call void @cqrt_free(i32 %73)    ; IR: release the %72 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %72, i32 %71, double 0x7FF0000000000000)    ; IR: uncompute %70
  call void @cqrt_free(i32 %72)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %71, i32 %70, i32 %69)    ; IR: uncompute %69  [sum]
  call void @cqrt_free(i32 %71)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %70, i32 %18, double %63)    ; IR: uncompute %69  [product]
  call void @cqrt_free(i32 %70)    ; IR: release the %69 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %69, i32 %19, double %68)    ; IR: uncompute %68
  call void @cqrt_free(i32 %69)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %67, i32 %66, double 0x7FF0000000000000)    ; IR: uncompute %66
  call void @cqrt_free(i32 %67)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %66, i32 %65, i32 %64)    ; IR: uncompute %65  [sum]
  call void @cqrt_free(i32 %66)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %65, i32 %18, double %59)    ; IR: uncompute %65  [product]
  call void @cqrt_free(i32 %65)    ; IR: release the %65 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %64, i32 %19, double %63)    ; IR: uncompute %64
  call void @cqrt_free(i32 %64)    ; IR: release the %64 rail (|0>)
  call void @cqrt_or_i1(i32 %54, i32 %56, i32 %57)    ; IR: uncompute %56  [self-inverse]
  call void @cqrt_free(i32 %57)    ; IR: release the %56 rail (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %56, i32 %55, double 0x7FF0000000000000)    ; IR: uncompute %55
  call void @cqrt_free(i32 %56)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %55, i32 %19)    ; IR: uncompute %54
  call void @cqrt_free(i32 %55)    ; IR: release the %54 rail (|0>)
  call void @cqrt_or_i1(i32 %53, i32 %52, i32 %54)    ; IR: uncompute %53  [self-inverse]
  call void @cqrt_free(i32 %54)    ; IR: release the %53 rail (|0>)
  call void @cqrt_free(i32 %53)    ; IR: release the seed rail (basis state)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %52, i32 %51, double 0x7FF0000000000000)    ; IR: uncompute %52
  call void @cqrt_free(i32 %52)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %51, i32 %18)    ; IR: uncompute %51
  call void @cqrt_free(i32 %51)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %45, i32 %43, double %1)    ; IR: uncompute %44
  call void @cqrt_free(i32 %45)    ; IR: release the %44 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %44, i32 %43, double %0)    ; IR: uncompute %43
  call void @cqrt_free(i32 %44)    ; IR: release the %43 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %43, double 0x7FF0000000000000, i32 %18)    ; IR: uncompute %42
  call void @cqrt_free(i32 %43)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %39, i32 %23, double 0.000000e+00)    ; IR: uncompute %36
  call void @cqrt_free(i32 %39)    ; IR: release the %36 rail (|0>)
  call void @cqrt_or_i1(i32 %36, i32 %37, i32 %38)    ; IR: uncompute %34  [self-inverse]
  call void @cqrt_free(i32 %38)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %37, i32 %35, double 0.000000e+00)    ; IR: uncompute %33
  call void @cqrt_free(i32 %37)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fcmp_ord_f64_hl_unc(i32 %36, i32 %29, double 0.000000e+00)    ; IR: uncompute %32
  call void @cqrt_free(i32 %36)    ; IR: release the %32 rail (|0>)
  call fastcc void @__cq_q_scalbn_11_unc(i32 %35, i32 %34, i32 %28)    ; IR: uncompute the result rail(s) of %31
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %34, i32 %33, i32 %23)    ; IR: uncompute %30
  call void @cqrt_free(i32 %34)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %33, i32 %32, i32 %31)    ; IR: uncompute %29  [sum]
  call void @cqrt_free(i32 %33)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %32, i32 %18, double %1)    ; IR: uncompute %29  [product]
  call void @cqrt_free(i32 %32)    ; IR: release the %29 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %31, i32 %30, double %0)    ; IR: uncompute %28
  call void @cqrt_free(i32 %31)    ; IR: release the %28 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %30, i32 %19)    ; IR: uncompute %27
  call void @cqrt_free(i32 %30)    ; IR: release the %27 rail (|0>)
  call fastcc void @__cq_q_scalbn_11_unc(i32 %29, i32 %27, i32 %28)    ; IR: uncompute the result rail(s) of %26
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %28, i32 0, i32 %20)    ; IR: uncompute %25
  call void @cqrt_free(i32 %28)    ; IR: release the %25 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %27, i32 %26, i32 %23)    ; IR: uncompute %24
  call void @cqrt_free(i32 %27)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %26, i32 %25, i32 %24)    ; IR: uncompute %23  [sum]
  call void @cqrt_free(i32 %26)    ; IR: release the %23 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %25, i32 %18, double %0)    ; IR: uncompute %23  [product]
  call void @cqrt_free(i32 %25)    ; IR: release the %23 product rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %24, i32 %19, double %1)    ; IR: uncompute %22
  call void @cqrt_free(i32 %24)    ; IR: release the %22 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %23, i32 %22, i32 %21)    ; IR: uncompute %21  [sum]
  call void @cqrt_free(i32 %23)    ; IR: release the %21 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %22, i32 %18, i32 %18)    ; IR: uncompute %21  [product]
  call void @cqrt_free(i32 %22)    ; IR: release the %21 product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %21, i32 %19, i32 %19)    ; IR: uncompute %20
  call void @cqrt_free(i32 %21)    ; IR: release the %20 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %13, i32 0, i32 %14)    ; IR: uncompute %19
  call void @cqrt_free(i32 %20)    ; IR: release the %19 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %19, i32 %13, i32 %3, i32 %17)    ; IR: uncompute %18
  call void @cqrt_free(i32 %19)    ; IR: release the %18 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %18, i32 %13, i32 %2, i32 %16)    ; IR: uncompute %17
  call void @cqrt_free(i32 %18)    ; IR: release the %17 rail (|0>)
  call fastcc void @__cq_q_scalbn_11_unc(i32 %17, i32 %3, i32 %15)    ; IR: uncompute the result rail(s) of %15
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call fastcc void @__cq_q_scalbn_11_unc(i32 %16, i32 %2, i32 %15)    ; IR: uncompute the result rail(s) of %14
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %15, i32 0, i32 %14)    ; IR: uncompute %13
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fptosi_f64_to_i32_unc(i32 %14, i32 %10)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %13, i32 %12, double 0x7FF0000000000000)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %12, i32 %10)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_logb_1_unc(i32 %10, i32 %11, i32 %7, i32 0, i32 %8)    ; IR: uncompute the result rail and the dropped flags rail of %8
  call void @cqrt_free(i32 %10)    ; IR: release the result rail (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the dropped flags rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the empty incoming flags rail (never written, rule 7)
  call void @cq_template_fmax_f64_unc(i32 %7, i32 %5, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %6, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %5, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %113 = insertvalue { i32, i32 } poison, i32 %111, 0    ; IR: ret: field 0 (handle)
  %114 = insertvalue { i32, i32 } %113, i32 %112, 1    ; IR: ret: field 1 (handle)
  ret { i32, i32 } %114    ; IR: ret  (the aggregate carries handles)
}

define internal fastcc { i32, i32 } @__cq_q_ilogb_1_ctl(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_bitcast_f64_to_i64(i32 %1)    ; IR: %4 = bitcast x to i64  (u.i)
  %6 = call i32 @cq_template_lshr_i64_hl(i32 %5, i64 52)    ; IR: %5 = lshr %4, 52
  %7 = call i32 @cq_template_trunc_i64_to_i32(i32 %6)    ; IR: %6 = trunc nuw nsw %5 to i32
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 2047)    ; IR: %7 = and %6, 2047  (e)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 0)    ; IR: S0 = switch %7: case 0 -> block %8  (rule 13: one equality flag per reachable case)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 2047)    ; IR: S2047 = switch %7: case 2047 -> block %22; the default %28 is the complement
  %11 = call i32 @cq_template_shl_i64_hl(i32 %5, i64 12)    ; IR: %9 = shl %4, 12  (block %8: i <<= 12)
  %12 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 0)    ; IR: %10 = icmp eq %9, 0  [br %10 -> block %13 (FP_ILOGB0), else block %11]
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %13 = S0 & %10  (FORCE_EVAL(0/0.0f): constrained sitofp(0) = 0.0f and fdiv(0.0f, 0.0f), two literals)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %9, i32 %12, i32 %13)    ; IR: predicate of block %13 = S0 & %10  (FORCE_EVAL(0/0.0f): constrained sitofp(0) = 0.0f and fdiv(0.0f, 0.0f), two literals)
  %14 = call i32 @cq_template_select_i32_ll(i32 %13, i32 1, i32 0)    ; IR: %15 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict): its exception bits, INVALID (FE_INVALID = 1) where block %13 runs; the NaN quotient is stored volatile to a dead local: no gate (rule 24); the mode is not read (a NaN in every mode)
  %15 = call i32 @cq_template_or_i32(i32 %3, i32 %14)    ; IR: flags after block %13 = the caller's flags | %15's exception bits  [flags rail]
  %16 = call i32 @cq_template_select_i32_ll(i32 %10, i32 1, i32 0)    ; IR: %24 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict) in block %22: INVALID where the case-2047 arm runs (its predicate is S2047 itself)
  %17 = call i32 @cq_template_or_i32(i32 %15, i32 %16)    ; IR: flags after block %22 = flags | %24's exception bits  [flags' rail: the returned fenv state]
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %11 (the loop sits in this arm): S0 & !%10  [the arm flag]  [fresh flag rail]
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket: the conjunct is the negated IR %10
  call void @cqrt_and_i1(i32 %9, i32 %12, i32 %18)    ; IR: predicate of block %11 (the loop sits in this arm): S0 & !%10  [the arm flag]
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket (close)
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the loop guard %12 = the clone's predicate & the arm flag  [chain seed: a _ctl clone seeds the chain with its predicate (§1.4, rule 14)]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %19)    ; IR: chain seed = pred & (S0 & !%10)
  %20 = call i32 @cqrt_alloc_i32(i32 -1023)    ; IR: incoming -1023 of phi %17 / %31  [e's exit value before trip 0: a seed (rule 7)]
  br label %21    ; IR: br i1 %12, label %16, label %30  (the pre-header guard is trip 0 of the chain)

21:
  %22 = phi i32 [ 0, %4 ], [ %32, %21 ]    ; IR: trip index, bounded by K  [K]
  %23 = phi i32 [ %11, %4 ], [ %31, %21 ]    ; IR: %18 = phi i64 [ %20, %16 ], [ %9, %11 ]  (i: a handle)
  %24 = phi i32 [ %20, %4 ], [ %30, %21 ]    ; IR: the exit value of e (%31's incomings [ -1023, %11 ], [ %19, %16 ]): the carried rail kept for the read after the loop (rule 14)
  %25 = phi i32 [ %19, %4 ], [ %27, %21 ]    ; IR: predicate of reaching this trip's test
  %26 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %23, i64 -1)    ; IR: %12 = icmp sgt %9, -1 (trip 0: the pre-header guard = trip 0 of the latch test) / %21 = icmp sgt %20, -1  [K]
  %27 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip, a_j = a_(j-1) & cond_j  [K]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %25, i32 %26, i32 %27)    ; IR: br i1 %12 (trip 0) / br i1 %21 taken  [K]
  %28 = sub i32 -1024, %22    ; IR: %19 = add nsw %17, -1 of this trip: -1023 - (trip index + 1)  (classical: an affine induction is not carried, rule 14; no nsw)
  %29 = call i32 @cq_template_shl_i64_hl(i32 %23, i64 1)    ; IR: %20 = shl nuw %18, 1  (i <<= 1)
  %30 = call i32 @cq_template_select_i32_lh(i32 %27, i32 %28, i32 %24)    ; IR: the exit value of e after this trip = a ? %19 : e
  %31 = call i32 @cq_template_select_i64(i32 %27, i32 %29, i32 %23)    ; IR: next %18 = a ? %20 : %18
  call void @cqrt_push(i32 %23)    ; IR: %18 of this trip (trip 0: %9), for the reverse loop (rule 14)
  call void @cqrt_push(i32 %24)    ; IR: the exit value of e before this trip (trip 0: the seed)
  call void @cqrt_push(i32 %25)    ; IR: the predicate of reaching this trip's test (trip 0: the chain seed)
  call void @cqrt_push(i32 %26)    ; IR: %12 / %21 of this trip
  call void @cqrt_push(i32 %29)    ; IR: %20 of this trip
  %32 = add nuw nsw i32 %22, 1
  %33 = icmp ult i32 %32, 4    ; IR: K-bounded br i1 %21, label %16, label %30  [K]
  br i1 %33, label %21, label %34

34:
  %35 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %31, i64 -1)    ; IR: %21 = icmp sgt %20, -1 after trip K: the exit test that would admit a (K+1)-th trip  [K]
  %36 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = a_4 & that test  [output rail, kept, rule 14]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %27, i32 %35, i32 %36)    ; IR: a_K = a_4 & that test  [output rail, kept, rule 14]
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %35, i32 %31, i64 -1)    ; IR: uncompute that test
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  %37 = call i32 @cq_template_and_i64_hl(i32 %5, i64 4503599627370495)    ; IR: %25 = and %4, 0xfffffffffffff  (block %22: the mantissa)
  %38 = call i32 @cq_template_icmp_eq_i64_hl(i32 %37, i64 0)    ; IR: %26 = icmp eq %25, 0
  %39 = call i32 @cq_template_select_i32_ll(i32 %38, i32 2147483647, i32 -2147483648)    ; IR: %27 = select %26, INT_MAX, FP_ILOGBNAN
  %40 = call i32 @cq_template_add_i32_hl(i32 %8, i32 -1023)    ; IR: %29 = add nsw %7, -1023  (block %28: e - 0x3ff)
  %41 = call i32 @cq_template_select_i32_lh(i32 %12, i32 -2147483648, i32 %30)    ; IR: %31 = phi i32 [ %27, %22 ], [ %29, %28 ], [ FP_ILOGB0, %13 ], [ -1023, %11 ], [ %19, %16 ]: the case-0 subtree on %10 (the loop arm's e, -1023 when the guard fails)
  %42 = call i32 @cq_template_select_i32(i32 %10, i32 %39, i32 %40)    ; IR: %31 = phi i32: the case-2047 arm against the default %28
  %43 = call i32 @cq_template_select_i32(i32 %9, i32 %41, i32 %42)    ; IR: %31 = phi i32: the case-0 subtree against the rest  [the result e]
  %44 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %31  [result rail of the call]
  call void @cqrt_copy_i32(i32 %43, i32 %44)    ; IR: copy e out
  %45 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %31  [the returned flags rail: the second result, copied out too (rule 18, 82)]
  call void @cqrt_copy_i32(i32 %17, i32 %45)    ; IR: copy flags' out
  call void @cq_template_select_i32_unc(i32 %43, i32 %9, i32 %41, i32 %42)    ; IR: uncompute %31 = phi i32: the case-0 subtree against the rest
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %42, i32 %10, i32 %39, i32 %40)    ; IR: uncompute %31 = phi i32: the case-2047 arm against the default %28
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %41, i32 %12, i32 -2147483648, i32 %30)    ; IR: uncompute %31 = phi i32 [ %27, %22 ], [ %29, %28 ], [ FP_ILOGB0, %13 ], [ -1023, %11 ], [ %19, %16 ]: the case-0 subtree on %10 (the loop arm's e, -1023 when the guard fails)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %40, i32 %8, i32 -1023)    ; IR: uncompute %29 = add nsw %7, -1023
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %39, i32 %38, i32 2147483647, i32 -2147483648)    ; IR: uncompute %27 = select %26, INT_MAX, FP_ILOGBNAN
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %38, i32 %37, i64 0)    ; IR: uncompute %26 = icmp eq %25, 0
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %37, i32 %5, i64 4503599627370495)    ; IR: uncompute %25 = and %4, 0xfffffffffffff
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  br label %46    ; IR: the reverse loop (rule 14)

46:
  %47 = phi i32 [ 0, %34 ], [ %58, %46 ]    ; IR: reverse trip index
  %48 = phi i32 [ %31, %34 ], [ %55, %46 ]    ; IR: %18 written by this trip
  %49 = phi i32 [ %30, %34 ], [ %54, %46 ]    ; IR: the exit value of e written by this trip
  %50 = phi i32 [ %27, %34 ], [ %53, %46 ]    ; IR: predicate of this trip
  %51 = call i32 @cqrt_pop()    ; IR: %20 of this trip
  %52 = call i32 @cqrt_pop()    ; IR: %12 / %21 of this trip
  %53 = call i32 @cqrt_pop()    ; IR: the predicate of reaching this trip's test
  %54 = call i32 @cqrt_pop()    ; IR: the exit value of e before this trip
  %55 = call i32 @cqrt_pop()    ; IR: %18 of this trip
  call void @cq_template_select_i64_unc(i32 %48, i32 %50, i32 %51, i32 %55)    ; IR: uncompute next %18
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  %56 = sub i32 3, %47    ; IR: the index of the trip being undone, K - 1 - reverse index  [K]
  %57 = sub i32 -1024, %56    ; IR: %19 of that trip, recomputed from the trip index (rule 14: never pushed)
  call void @cq_template_select_i32_lh_unc(i32 %49, i32 %50, i32 %57, i32 %54)    ; IR: uncompute the exit value of e written by this trip
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %51, i32 %55, i64 1)    ; IR: uncompute %20 = shl nuw %18, 1
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %53, i32 %52, i32 %50)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)  [self-inverse]
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %52, i32 %55, i64 -1)    ; IR: uncompute %12 / %21 of this trip
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  %58 = add nuw nsw i32 %47, 1
  %59 = icmp ult i32 %58, 4    ; IR: K  [K]
  br i1 %59, label %46, label %60

60:
  call void @cqrt_free(i32 %20)    ; IR: release the -1023 seed directly (rule 7: known basis state)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %19)    ; IR: uncompute the chain seed = pred & (S0 & !%10)  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket: the conjunct is the negated IR %10
  call void @cqrt_and_i1(i32 %9, i32 %12, i32 %18)    ; IR: uncompute the predicate of block %11: S0 & !%10  [self-inverse]
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket (close)
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %17, i32 %15, i32 %16)    ; IR: uncompute flags after block %22 = flags | %24's exception bits
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %16, i32 %10, i32 1, i32 0)    ; IR: uncompute %24 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict) in block %22: INVALID where the case-2047 arm runs (its predicate is S2047 itself)
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %15, i32 %3, i32 %14)    ; IR: uncompute flags after block %13 = the caller's flags | %15's exception bits
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %14, i32 %13, i32 1, i32 0)    ; IR: uncompute %15 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict): its exception bits, INVALID (FE_INVALID = 1) where block %13 runs; the NaN quotient is stored volatile to a dead local: no gate (rule 24); the mode is not read (a NaN in every mode)
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %9, i32 %12, i32 %13)    ; IR: uncompute predicate of block %13 = S0 & %10  [self-inverse]
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %12, i32 %11, i64 0)    ; IR: uncompute %10 = icmp eq %9, 0
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %11, i32 %5, i64 12)    ; IR: uncompute %9 = shl %4, 12
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %8, i32 2047)    ; IR: uncompute S2047 = switch %7: case 2047 -> block %22; the default %28 is the complement
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 0)    ; IR: uncompute S0 = switch %7: case 0 -> block %8
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 2047)    ; IR: uncompute %7 = and %6, 2047
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %7, i32 %6)    ; IR: uncompute %6 = trunc nuw nsw %5 to i32
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %6, i32 %5, i64 52)    ; IR: uncompute %5 = lshr %4, 52
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %5, i32 %1)    ; IR: uncompute %4 = bitcast x to i64
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  %61 = insertvalue { i32, i32 } poison, i32 %44, 0    ; IR: ret i32 %31: the result handle
  %62 = insertvalue { i32, i32 } %61, i32 %45, 1    ; IR: and the new flags handle
  ret { i32, i32 } %62    ; IR: ret i32 %31
}

define internal fastcc void @__cq_q_ilogb_1_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = call i32 @cq_template_bitcast_f64_to_i64(i32 %3)    ; IR: %4 = bitcast x to i64  (u.i)
  %8 = call i32 @cq_template_lshr_i64_hl(i32 %7, i64 52)    ; IR: %5 = lshr %4, 52
  %9 = call i32 @cq_template_trunc_i64_to_i32(i32 %8)    ; IR: %6 = trunc nuw nsw %5 to i32
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 2047)    ; IR: %7 = and %6, 2047  (e)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 0)    ; IR: S0 = switch %7: case 0 -> block %8  (rule 13: one equality flag per reachable case)
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 2047)    ; IR: S2047 = switch %7: case 2047 -> block %22; the default %28 is the complement
  %13 = call i32 @cq_template_shl_i64_hl(i32 %7, i64 12)    ; IR: %9 = shl %4, 12  (block %8: i <<= 12)
  %14 = call i32 @cq_template_icmp_eq_i64_hl(i32 %13, i64 0)    ; IR: %10 = icmp eq %9, 0  [br %10 -> block %13 (FP_ILOGB0), else block %11]
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %13 = S0 & %10  (FORCE_EVAL(0/0.0f): constrained sitofp(0) = 0.0f and fdiv(0.0f, 0.0f), two literals)  [fresh flag rail]
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: predicate of block %13 = S0 & %10  (FORCE_EVAL(0/0.0f): constrained sitofp(0) = 0.0f and fdiv(0.0f, 0.0f), two literals)
  %16 = call i32 @cq_template_select_i32_ll(i32 %15, i32 1, i32 0)    ; IR: %15 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict): its exception bits, INVALID (FE_INVALID = 1) where block %13 runs; the NaN quotient is stored volatile to a dead local: no gate (rule 24); the mode is not read (a NaN in every mode)
  %17 = call i32 @cq_template_or_i32(i32 %5, i32 %16)    ; IR: flags after block %13 = the caller's flags | %15's exception bits  [flags rail]
  %18 = call i32 @cq_template_select_i32_ll(i32 %12, i32 1, i32 0)    ; IR: %24 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict) in block %22: INVALID where the case-2047 arm runs (its predicate is S2047 itself)
  %19 = call i32 @cq_template_or_i32(i32 %17, i32 %18)    ; IR: flags after block %22 = flags | %24's exception bits  [flags' rail: the returned fenv state]
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %11 (the loop sits in this arm): S0 & !%10  [the arm flag]  [fresh flag rail]
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket: the conjunct is the negated IR %10
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %20)    ; IR: predicate of block %11 (the loop sits in this arm): S0 & !%10  [the arm flag]
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket (close)
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the loop guard %12 = the clone's predicate & the arm flag  [chain seed: a _ctl clone seeds the chain with its predicate (§1.4, rule 14)]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %21)    ; IR: chain seed = pred & (S0 & !%10)
  %22 = call i32 @cqrt_alloc_i32(i32 -1023)    ; IR: incoming -1023 of phi %17 / %31  [e's exit value before trip 0: a seed (rule 7)]
  br label %23    ; IR: br i1 %12, label %16, label %30  (the pre-header guard is trip 0 of the chain)

23:
  %24 = phi i32 [ 0, %6 ], [ %34, %23 ]    ; IR: trip index, bounded by K  [K]
  %25 = phi i32 [ %13, %6 ], [ %33, %23 ]    ; IR: %18 = phi i64 [ %20, %16 ], [ %9, %11 ]  (i: a handle)
  %26 = phi i32 [ %22, %6 ], [ %32, %23 ]    ; IR: the exit value of e (%31's incomings [ -1023, %11 ], [ %19, %16 ]): the carried rail kept for the read after the loop (rule 14)
  %27 = phi i32 [ %21, %6 ], [ %29, %23 ]    ; IR: predicate of reaching this trip's test
  %28 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %25, i64 -1)    ; IR: %12 = icmp sgt %9, -1 (trip 0: the pre-header guard = trip 0 of the latch test) / %21 = icmp sgt %20, -1  [K]
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip, a_j = a_(j-1) & cond_j  [K]  [fresh flag rail]
  call void @cqrt_and_i1(i32 %27, i32 %28, i32 %29)    ; IR: br i1 %12 (trip 0) / br i1 %21 taken  [K]
  %30 = sub i32 -1024, %24    ; IR: %19 = add nsw %17, -1 of this trip: -1023 - (trip index + 1)  (classical: an affine induction is not carried, rule 14; no nsw)
  %31 = call i32 @cq_template_shl_i64_hl(i32 %25, i64 1)    ; IR: %20 = shl nuw %18, 1  (i <<= 1)
  %32 = call i32 @cq_template_select_i32_lh(i32 %29, i32 %30, i32 %26)    ; IR: the exit value of e after this trip = a ? %19 : e
  %33 = call i32 @cq_template_select_i64(i32 %29, i32 %31, i32 %25)    ; IR: next %18 = a ? %20 : %18
  call void @cqrt_push(i32 %25)    ; IR: %18 of this trip (trip 0: %9), for the reverse loop (rule 14)
  call void @cqrt_push(i32 %26)    ; IR: the exit value of e before this trip (trip 0: the seed)
  call void @cqrt_push(i32 %27)    ; IR: the predicate of reaching this trip's test (trip 0: the chain seed)
  call void @cqrt_push(i32 %28)    ; IR: %12 / %21 of this trip
  call void @cqrt_push(i32 %31)    ; IR: %20 of this trip
  %34 = add nuw nsw i32 %24, 1
  %35 = icmp ult i32 %34, 4    ; IR: K-bounded br i1 %21, label %16, label %30  [K]
  br i1 %35, label %23, label %36

36:
  %37 = call i32 @cq_template_and_i64_hl(i32 %7, i64 4503599627370495)    ; IR: %25 = and %4, 0xfffffffffffff  (block %22: the mantissa)
  %38 = call i32 @cq_template_icmp_eq_i64_hl(i32 %37, i64 0)    ; IR: %26 = icmp eq %25, 0
  %39 = call i32 @cq_template_select_i32_ll(i32 %38, i32 2147483647, i32 -2147483648)    ; IR: %27 = select %26, INT_MAX, FP_ILOGBNAN
  %40 = call i32 @cq_template_add_i32_hl(i32 %10, i32 -1023)    ; IR: %29 = add nsw %7, -1023  (block %28: e - 0x3ff)
  %41 = call i32 @cq_template_select_i32_lh(i32 %14, i32 -2147483648, i32 %32)    ; IR: %31 = phi i32 [ %27, %22 ], [ %29, %28 ], [ FP_ILOGB0, %13 ], [ -1023, %11 ], [ %19, %16 ]: the case-0 subtree on %10 (the loop arm's e, -1023 when the guard fails)
  %42 = call i32 @cq_template_select_i32(i32 %12, i32 %39, i32 %40)    ; IR: %31 = phi i32: the case-2047 arm against the default %28
  %43 = call i32 @cq_template_select_i32(i32 %11, i32 %41, i32 %42)    ; IR: %31 = phi i32: the case-0 subtree against the rest  [the result e]
  call void @cqrt_copy_i32(i32 %43, i32 %1)    ; IR: xor e out of %out
  call void @cqrt_copy_i32(i32 %19, i32 %2)    ; IR: xor the new flags out of %flout
  call void @cq_template_select_i32_unc(i32 %43, i32 %11, i32 %41, i32 %42)    ; IR: uncompute %31 = phi i32: the case-0 subtree against the rest
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %42, i32 %12, i32 %39, i32 %40)    ; IR: uncompute %31 = phi i32: the case-2047 arm against the default %28
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %41, i32 %14, i32 -2147483648, i32 %32)    ; IR: uncompute %31 = phi i32 [ %27, %22 ], [ %29, %28 ], [ FP_ILOGB0, %13 ], [ -1023, %11 ], [ %19, %16 ]: the case-0 subtree on %10 (the loop arm's e, -1023 when the guard fails)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %40, i32 %10, i32 -1023)    ; IR: uncompute %29 = add nsw %7, -1023
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %39, i32 %38, i32 2147483647, i32 -2147483648)    ; IR: uncompute %27 = select %26, INT_MAX, FP_ILOGBNAN
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %38, i32 %37, i64 0)    ; IR: uncompute %26 = icmp eq %25, 0
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %37, i32 %7, i64 4503599627370495)    ; IR: uncompute %25 = and %4, 0xfffffffffffff
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  br label %44    ; IR: the reverse loop (rule 14)

44:
  %45 = phi i32 [ 0, %36 ], [ %56, %44 ]    ; IR: reverse trip index
  %46 = phi i32 [ %33, %36 ], [ %53, %44 ]    ; IR: %18 written by this trip
  %47 = phi i32 [ %32, %36 ], [ %52, %44 ]    ; IR: the exit value of e written by this trip
  %48 = phi i32 [ %29, %36 ], [ %51, %44 ]    ; IR: predicate of this trip
  %49 = call i32 @cqrt_pop()    ; IR: %20 of this trip
  %50 = call i32 @cqrt_pop()    ; IR: %12 / %21 of this trip
  %51 = call i32 @cqrt_pop()    ; IR: the predicate of reaching this trip's test
  %52 = call i32 @cqrt_pop()    ; IR: the exit value of e before this trip
  %53 = call i32 @cqrt_pop()    ; IR: %18 of this trip
  call void @cq_template_select_i64_unc(i32 %46, i32 %48, i32 %49, i32 %53)    ; IR: uncompute next %18
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  %54 = sub i32 3, %45    ; IR: the index of the trip being undone, K - 1 - reverse index  [K]
  %55 = sub i32 -1024, %54    ; IR: %19 of that trip, recomputed from the trip index (rule 14: never pushed)
  call void @cq_template_select_i32_lh_unc(i32 %47, i32 %48, i32 %55, i32 %52)    ; IR: uncompute the exit value of e written by this trip
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %49, i32 %53, i64 1)    ; IR: uncompute %20 = shl nuw %18, 1
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %51, i32 %50, i32 %48)    ; IR: uncompute the predicate of this trip (every trip 1..K; the twin makes no a_K)  [self-inverse]
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %50, i32 %53, i64 -1)    ; IR: uncompute %12 / %21 of this trip
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  %56 = add nuw nsw i32 %45, 1
  %57 = icmp ult i32 %56, 4    ; IR: K  [K]
  br i1 %57, label %44, label %58

58:
  call void @cqrt_free(i32 %22)    ; IR: release the -1023 seed directly (rule 7: known basis state)
  call void @cqrt_and_i1(i32 %0, i32 %20, i32 %21)    ; IR: uncompute the chain seed = pred & (S0 & !%10)  [self-inverse]
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket: the conjunct is the negated IR %10
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %20)    ; IR: uncompute the predicate of block %11: S0 & !%10  [self-inverse]
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket (close)
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %19, i32 %17, i32 %18)    ; IR: uncompute flags after block %22 = flags | %24's exception bits
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %18, i32 %12, i32 1, i32 0)    ; IR: uncompute %24 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict) in block %22: INVALID where the case-2047 arm runs (its predicate is S2047 itself)
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %17, i32 %5, i32 %16)    ; IR: uncompute flags after block %13 = the caller's flags | %15's exception bits
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %16, i32 %15, i32 1, i32 0)    ; IR: uncompute %15 = constrained.fdiv(0.0f, 0.0f, round.dynamic, strict): its exception bits, INVALID (FE_INVALID = 1) where block %13 runs; the NaN quotient is stored volatile to a dead local: no gate (rule 24); the mode is not read (a NaN in every mode)
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: uncompute predicate of block %13 = S0 & %10  [self-inverse]
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %14, i32 %13, i64 0)    ; IR: uncompute %10 = icmp eq %9, 0
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %13, i32 %7, i64 12)    ; IR: uncompute %9 = shl %4, 12
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %10, i32 2047)    ; IR: uncompute S2047 = switch %7: case 2047 -> block %22; the default %28 is the complement
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 0)    ; IR: uncompute S0 = switch %7: case 0 -> block %8
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 2047)    ; IR: uncompute %7 = and %6, 2047
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %9, i32 %8)    ; IR: uncompute %6 = trunc nuw nsw %5 to i32
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %8, i32 %7, i64 52)    ; IR: uncompute %5 = lshr %4, 52
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %7, i32 %3)    ; IR: uncompute %4 = bitcast x to i64
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  ret void    ; IR: ret void
}

define internal fastcc { i32, i32 } @__cq_q_logb_1(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_fabs_f64(i32 %0)    ; IR: %2 = fabs(x)
  %5 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %4, double 0x7FF0000000000000)    ; IR: %3 = fcmp ueq %2, inf  (!isfinite(x))  [br %3 -> block %4]
  %6 = call i32 @cq_template_fmul_f64(i32 %0, i32 %0)    ; IR: %5 = fmul x, x  (block %4: x * x)
  %7 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %0, double 0.000000e+00)    ; IR: %7 = fcmp oeq x, 0  (block %6)  [br %7 -> block %8]
  %8 = call i32 @cq_template_fmul_f64(i32 %0, i32 %0)    ; IR: %9 = fmul x, x  (block %8)
  %9 = call i32 @cq_template_fdiv_f64_lh(double -1.000000e+00, i32 %8)    ; IR: %10 = fdiv -1.0, %9
  %10 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %11 (the block that calls ilogb) = !%3 & !%7  [the _ctl clone's predicate]  [fresh flag rail]
  call void @cqrt_not_i1(i32 %5)    ; IR: bracket: the conjunct is NOT %3
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: the conjunct is NOT %7
  call void @cqrt_and_i1(i32 %5, i32 %7, i32 %10)    ; IR: predicate of block %11 = !%3 & !%7
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket (close)
  call void @cqrt_not_i1(i32 %5)    ; IR: bracket (close)
  %11 = call fastcc { i32, i32 } @__cq_q_ilogb_1_ctl(i32 %10, i32 %0, i32 %1, i32 %2)    ; IR: %12 = call @ilogb(x) (block %11): the strictfp clone under block %11's predicate, a _ctl clone because ilogb holds a quantum-exit loop whose a_K is kept (rule 19): the predicate seeds that loop's chain; the templates and the copy-out run unguarded (§1.4) and are merged below
  %12 = extractvalue { i32, i32 } %11, 0    ; IR: %12  [the result e]
  %13 = extractvalue { i32, i32 } %11, 1    ; IR: %12: the flags after ilogb
  %14 = call i32 @cq_template_sitofp_i32_to_f64(i32 %12)    ; IR: %13 = sitofp %12 to double
  %15 = call i32 @cq_template_select_f64(i32 %7, i32 %9, i32 %14)    ; IR: %15 = phi double [ %10, %8 ], [ %13, %11 ], [ %5, %4 ]: the %6 subtree on %7
  %16 = call i32 @cq_template_select_f64(i32 %5, i32 %6, i32 %15)    ; IR: %15 = phi double: the top split on %3  [the result]
  %17 = call i32 @cq_template_select_i32(i32 %7, i32 %2, i32 %13)    ; IR: the flags phi of the same merge: block %8 does not call ilogb, so its arm is the caller's flags; block %11's is ilogb's flags'
  %18 = call i32 @cq_template_select_i32(i32 %5, i32 %2, i32 %17)    ; IR: the flags phi, top split: block %4 keeps the caller's flags  [flags' rail: the returned fenv state]
  %19 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret double %15  [result rail: logb(x)]
  call void @cqrt_copy_f64(i32 %16, i32 %19)    ; IR: copy logb(x) out
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret double %15  [the returned flags rail, copied out too (rule 18, 82)]
  call void @cqrt_copy_i32(i32 %18, i32 %20)    ; IR: copy flags' out
  call void @cq_template_select_i32_unc(i32 %18, i32 %5, i32 %2, i32 %17)    ; IR: uncompute the flags phi, top split: block %4 keeps the caller's flags
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %17, i32 %7, i32 %2, i32 %13)    ; IR: uncompute the flags phi of the same merge: block %8 does not call ilogb, so its arm is the caller's flags; block %11's is ilogb's flags'
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %16, i32 %5, i32 %6, i32 %15)    ; IR: uncompute %15 = phi double: the top split on %3
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %15, i32 %7, i32 %9, i32 %14)    ; IR: uncompute %15 = phi double [ %10, %8 ], [ %13, %11 ], [ %5, %4 ]: the %6 subtree on %7
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %14, i32 %12)    ; IR: uncompute %13 = sitofp %12 to double
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call fastcc void @__cq_q_ilogb_1_ctl_unc(i32 %10, i32 %12, i32 %13, i32 %0, i32 %1, i32 %2)    ; IR: uncompute %12's two result rails (the _ctl twin takes the predicate first)
  call void @cqrt_free(i32 %12)    ; IR: release the e rail (|0>)
  call void @cqrt_free(i32 %13)    ; IR: release the flags rail (|0>)
  call void @cqrt_not_i1(i32 %5)    ; IR: bracket: the conjunct is NOT %3
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: the conjunct is NOT %7
  call void @cqrt_and_i1(i32 %5, i32 %7, i32 %10)    ; IR: uncompute the predicate of block %11  [self-inverse]
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket (close)
  call void @cqrt_not_i1(i32 %5)    ; IR: bracket (close)
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_lh_unc(i32 %9, double -1.000000e+00, i32 %8)    ; IR: uncompute %10 = fdiv -1.0, %9
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %8, i32 %0, i32 %0)    ; IR: uncompute %9 = fmul x, x
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %7, i32 %0, double 0.000000e+00)    ; IR: uncompute %7 = fcmp oeq x, 0
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %6, i32 %0, i32 %0)    ; IR: uncompute %5 = fmul x, x
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %5, i32 %4, double 0x7FF0000000000000)    ; IR: uncompute %3 = fcmp ueq %2, inf
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %4, i32 %0)    ; IR: uncompute %2 = fabs(x)
  call void @cqrt_free(i32 %4)    ; IR: release it (|0>)
  %21 = insertvalue { i32, i32 } poison, i32 %19, 0    ; IR: ret double %15: the result handle
  %22 = insertvalue { i32, i32 } %21, i32 %20, 1    ; IR: and the new flags handle
  ret { i32, i32 } %22    ; IR: ret double %15
}

define internal fastcc void @__cq_q_logb_1_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = call i32 @cq_template_fabs_f64(i32 %2)    ; IR: %2 = fabs(x)
  %7 = call i32 @cq_template_fcmp_ueq_f64_hl(i32 %6, double 0x7FF0000000000000)    ; IR: %3 = fcmp ueq %2, inf  (!isfinite(x))  [br %3 -> block %4]
  %8 = call i32 @cq_template_fmul_f64(i32 %2, i32 %2)    ; IR: %5 = fmul x, x  (block %4: x * x)
  %9 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %2, double 0.000000e+00)    ; IR: %7 = fcmp oeq x, 0  (block %6)  [br %7 -> block %8]
  %10 = call i32 @cq_template_fmul_f64(i32 %2, i32 %2)    ; IR: %9 = fmul x, x  (block %8)
  %11 = call i32 @cq_template_fdiv_f64_lh(double -1.000000e+00, i32 %10)    ; IR: %10 = fdiv -1.0, %9
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %11 (the block that calls ilogb) = !%3 & !%7  [the _ctl clone's predicate]  [fresh flag rail]
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: the conjunct is NOT %3
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: the conjunct is NOT %7
  call void @cqrt_and_i1(i32 %7, i32 %9, i32 %12)    ; IR: predicate of block %11 = !%3 & !%7
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket (close)
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket (close)
  %13 = call fastcc { i32, i32 } @__cq_q_ilogb_1_ctl(i32 %12, i32 %2, i32 %3, i32 %4)    ; IR: %12 = call @ilogb(x) (block %11): the strictfp clone under block %11's predicate, a _ctl clone because ilogb holds a quantum-exit loop whose a_K is kept (rule 19): the predicate seeds that loop's chain; the templates and the copy-out run unguarded (§1.4) and are merged below
  %14 = extractvalue { i32, i32 } %13, 0    ; IR: %12  [the result e]
  %15 = extractvalue { i32, i32 } %13, 1    ; IR: %12: the flags after ilogb
  %16 = call i32 @cq_template_sitofp_i32_to_f64(i32 %14)    ; IR: %13 = sitofp %12 to double
  %17 = call i32 @cq_template_select_f64(i32 %9, i32 %11, i32 %16)    ; IR: %15 = phi double [ %10, %8 ], [ %13, %11 ], [ %5, %4 ]: the %6 subtree on %7
  %18 = call i32 @cq_template_select_f64(i32 %7, i32 %8, i32 %17)    ; IR: %15 = phi double: the top split on %3  [the result]
  %19 = call i32 @cq_template_select_i32(i32 %9, i32 %4, i32 %15)    ; IR: the flags phi of the same merge: block %8 does not call ilogb, so its arm is the caller's flags; block %11's is ilogb's flags'
  %20 = call i32 @cq_template_select_i32(i32 %7, i32 %4, i32 %19)    ; IR: the flags phi, top split: block %4 keeps the caller's flags  [flags' rail: the returned fenv state]
  call void @cqrt_copy_f64(i32 %18, i32 %0)    ; IR: xor logb(x) out of %out
  call void @cqrt_copy_i32(i32 %20, i32 %1)    ; IR: xor the new flags out of %flout
  call void @cq_template_select_i32_unc(i32 %20, i32 %7, i32 %4, i32 %19)    ; IR: uncompute the flags phi, top split: block %4 keeps the caller's flags
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %19, i32 %9, i32 %4, i32 %15)    ; IR: uncompute the flags phi of the same merge: block %8 does not call ilogb, so its arm is the caller's flags; block %11's is ilogb's flags'
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %18, i32 %7, i32 %8, i32 %17)    ; IR: uncompute %15 = phi double: the top split on %3
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %17, i32 %9, i32 %11, i32 %16)    ; IR: uncompute %15 = phi double [ %10, %8 ], [ %13, %11 ], [ %5, %4 ]: the %6 subtree on %7
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %16, i32 %14)    ; IR: uncompute %13 = sitofp %12 to double
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call fastcc void @__cq_q_ilogb_1_ctl_unc(i32 %12, i32 %14, i32 %15, i32 %2, i32 %3, i32 %4)    ; IR: uncompute %12's two result rails (the _ctl twin takes the predicate first)
  call void @cqrt_free(i32 %14)    ; IR: release the e rail (|0>)
  call void @cqrt_free(i32 %15)    ; IR: release the flags rail (|0>)
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket: the conjunct is NOT %3
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: the conjunct is NOT %7
  call void @cqrt_and_i1(i32 %7, i32 %9, i32 %12)    ; IR: uncompute the predicate of block %11  [self-inverse]
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket (close)
  call void @cqrt_not_i1(i32 %7)    ; IR: bracket (close)
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_lh_unc(i32 %11, double -1.000000e+00, i32 %10)    ; IR: uncompute %10 = fdiv -1.0, %9
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %10, i32 %2, i32 %2)    ; IR: uncompute %9 = fmul x, x
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %9, i32 %2, double 0.000000e+00)    ; IR: uncompute %7 = fcmp oeq x, 0
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %8, i32 %2, i32 %2)    ; IR: uncompute %5 = fmul x, x
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_fcmp_ueq_f64_hl_unc(i32 %7, i32 %6, double 0x7FF0000000000000)    ; IR: uncompute %3 = fcmp ueq %2, inf
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_fabs_f64_unc(i32 %6, i32 %2)    ; IR: uncompute %2 = fabs(x)
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  ret void    ; IR: ret void
}

define internal fastcc i32 @__cq_q_scalbn_10(i32 %0, i32 %1) {
  %3 = icmp sgt i32 %1, 1023    ; IR: %3 = icmp sgt n, 1023  [br %3 -> block %4, else %12]  (classical)
  %4 = call i32 @cq_template_fmul_f64_hl(i32 %0, double 0x7FE0000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %5 = add nsw i32 %1, -1023    ; IR: %6 = add nsw n, -1023  (classical)
  %6 = icmp sgt i32 %1, 2046    ; IR: %7 = icmp sgt n, 2046  [br %7 -> block %8]  (classical)
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %4, double 0x7FE0000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %8 = tail call i32 @llvm.smin.i32(i32 %1, i32 3069)    ; IR: %10 = smin(n, 3069)  (classical)
  %9 = add nsw i32 %8, -2046    ; IR: %11 = add nsw %10, -2046  (classical)
  %10 = icmp slt i32 %1, -1022    ; IR: %13 = icmp slt n, -1022  (block %12)  [br %13 -> block %14]  (classical)
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %0, double 0x360000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %12 = add nuw nsw i32 %1, 969    ; IR: %16 = add nuw nsw n, 969  (classical)
  %13 = icmp slt i32 %1, -1991    ; IR: %17 = icmp slt n, -1991  [br %17 -> block %18]  (classical)
  %14 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 0x360000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %15 = tail call i32 @llvm.smax.i32(i32 %1, i32 -2960)    ; IR: %20 = smax(n, -2960)  (classical)
  %16 = add nsw i32 %15, 1938    ; IR: %21 = add nsw %20, 1938  (classical)
  %17 = select i1 %6, i32 %9, i32 %5    ; IR: %23 = phi i32 [ %11, %8 ], [ %6, %4 ], ...: the %4 subtree on %7  (classical)
  %18 = select i1 %13, i32 %16, i32 %12    ; IR: %23 = phi i32 ..., [ %21, %18 ], [ %16, %14 ], ...: the %14 subtree on %17  (classical)
  %19 = select i1 %10, i32 %18, i32 %1    ; IR: %23 = phi i32 ..., [ %1, %12 ]: the %12 subtree on %13  (classical)
  %20 = select i1 %3, i32 %17, i32 %19    ; IR: %23 = phi i32 (n after the clamps): the top split on %3  (classical)
  %21 = call i32 @cqrt_alloc_i1(i1 %6)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7  [the classical conjunct %6 as a seed rail, rule 7]
  %22 = call i32 @cq_template_select_f64(i32 %21, i32 %7, i32 %4)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7
  %23 = call i32 @cqrt_alloc_i1(i1 %13)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17  [the classical conjunct %13 as a seed rail, rule 7]
  %24 = call i32 @cq_template_select_f64(i32 %23, i32 %14, i32 %11)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17
  %25 = call i32 @cqrt_alloc_i1(i1 %10)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13  [the classical conjunct %10 as a seed rail, rule 7]
  %26 = call i32 @cq_template_select_f64(i32 %25, i32 %24, i32 %0)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13
  %27 = call i32 @cqrt_alloc_i1(i1 %3)    ; IR: %24 = phi double (y after the scalings): the top split on %3  [the classical conjunct %3 as a seed rail, rule 7]
  %28 = call i32 @cq_template_select_f64(i32 %27, i32 %22, i32 %26)    ; IR: %24 = phi double (y after the scalings): the top split on %3
  %29 = add nsw i32 %20, 1023    ; IR: %25 = add nsw %23, 1023  (classical)
  %30 = zext i32 %29 to i64    ; IR: %26 = zext %25 to i64  (classical)
  %31 = shl i64 %30, 52    ; IR: %27 = shl %26, 52  (classical)
  %32 = bitcast i64 %31 to double    ; IR: %28 = bitcast i64 %27 to double  (u.f = 2^n)  (classical)
  %33 = call i32 @cq_template_fmul_f64_hl(i32 %28, double %32)    ; IR: %29 = fmul %24, %28  (y * u.f)
  %34 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: scalbn(x, n)]
  call void @cqrt_copy_f64(i32 %33, i32 %34)    ; IR: copy scalbn(x, n) out
  call void @cq_template_fmul_f64_hl_unc(i32 %33, i32 %28, double %32)    ; IR: uncompute %29
  call void @cqrt_free(i32 %33)    ; IR: release the %29 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %28, i32 %27, i32 %22, i32 %26)    ; IR: uncompute %24
  call void @cqrt_free(i32 %28)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %27)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %26, i32 %25, i32 %24, i32 %0)    ; IR: uncompute %24
  call void @cqrt_free(i32 %26)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %25)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %24, i32 %23, i32 %14, i32 %11)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %23)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %22, i32 %21, i32 %7, i32 %4)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %21)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f64_hl_unc(i32 %14, i32 %11, double 0x360000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %14)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %0, double 0x360000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %11)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %4, double 0x7FE0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %4, i32 %0, double 0x7FE0000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %4)    ; IR: release the %5 rail (|0>)
  ret i32 %34    ; IR: ret  (the result handle)
}

define internal fastcc void @__cq_q_scalbn_10_unc(i32 %0, i32 %1, i32 %2) {
  %4 = icmp sgt i32 %2, 1023    ; IR: %3 = icmp sgt n, 1023  [br %3 -> block %4, else %12]  (classical)
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %1, double 0x7FE0000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %6 = add nsw i32 %2, -1023    ; IR: %6 = add nsw n, -1023  (classical)
  %7 = icmp sgt i32 %2, 2046    ; IR: %7 = icmp sgt n, 2046  [br %7 -> block %8]  (classical)
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %5, double 0x7FE0000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %9 = tail call i32 @llvm.smin.i32(i32 %2, i32 3069)    ; IR: %10 = smin(n, 3069)  (classical)
  %10 = add nsw i32 %9, -2046    ; IR: %11 = add nsw %10, -2046  (classical)
  %11 = icmp slt i32 %2, -1022    ; IR: %13 = icmp slt n, -1022  (block %12)  [br %13 -> block %14]  (classical)
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %1, double 0x360000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %13 = add nuw nsw i32 %2, 969    ; IR: %16 = add nuw nsw n, 969  (classical)
  %14 = icmp slt i32 %2, -1991    ; IR: %17 = icmp slt n, -1991  [br %17 -> block %18]  (classical)
  %15 = call i32 @cq_template_fmul_f64_hl(i32 %12, double 0x360000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %16 = tail call i32 @llvm.smax.i32(i32 %2, i32 -2960)    ; IR: %20 = smax(n, -2960)  (classical)
  %17 = add nsw i32 %16, 1938    ; IR: %21 = add nsw %20, 1938  (classical)
  %18 = select i1 %7, i32 %10, i32 %6    ; IR: %23 = phi i32 [ %11, %8 ], [ %6, %4 ], ...: the %4 subtree on %7  (classical)
  %19 = select i1 %14, i32 %17, i32 %13    ; IR: %23 = phi i32 ..., [ %21, %18 ], [ %16, %14 ], ...: the %14 subtree on %17  (classical)
  %20 = select i1 %11, i32 %19, i32 %2    ; IR: %23 = phi i32 ..., [ %1, %12 ]: the %12 subtree on %13  (classical)
  %21 = select i1 %4, i32 %18, i32 %20    ; IR: %23 = phi i32 (n after the clamps): the top split on %3  (classical)
  %22 = call i32 @cqrt_alloc_i1(i1 %7)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7  [the classical conjunct %7 as a seed rail, rule 7]
  %23 = call i32 @cq_template_select_f64(i32 %22, i32 %8, i32 %5)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7
  %24 = call i32 @cqrt_alloc_i1(i1 %14)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17  [the classical conjunct %14 as a seed rail, rule 7]
  %25 = call i32 @cq_template_select_f64(i32 %24, i32 %15, i32 %12)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17
  %26 = call i32 @cqrt_alloc_i1(i1 %11)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13  [the classical conjunct %11 as a seed rail, rule 7]
  %27 = call i32 @cq_template_select_f64(i32 %26, i32 %25, i32 %1)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13
  %28 = call i32 @cqrt_alloc_i1(i1 %4)    ; IR: %24 = phi double (y after the scalings): the top split on %3  [the classical conjunct %4 as a seed rail, rule 7]
  %29 = call i32 @cq_template_select_f64(i32 %28, i32 %23, i32 %27)    ; IR: %24 = phi double (y after the scalings): the top split on %3
  %30 = add nsw i32 %21, 1023    ; IR: %25 = add nsw %23, 1023  (classical)
  %31 = zext i32 %30 to i64    ; IR: %26 = zext %25 to i64  (classical)
  %32 = shl i64 %31, 52    ; IR: %27 = shl %26, 52  (classical)
  %33 = bitcast i64 %32 to double    ; IR: %28 = bitcast i64 %27 to double  (u.f = 2^n)  (classical)
  %34 = call i32 @cq_template_fmul_f64_hl(i32 %29, double %33)    ; IR: %29 = fmul %24, %28  (y * u.f)
  call void @cqrt_copy_f64(i32 %34, i32 %0)    ; IR: xor scalbn(x, n) out of the result rail
  call void @cq_template_fmul_f64_hl_unc(i32 %34, i32 %29, double %33)    ; IR: uncompute %29
  call void @cqrt_free(i32 %34)    ; IR: release the %29 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %29, i32 %28, i32 %23, i32 %27)    ; IR: uncompute %24
  call void @cqrt_free(i32 %29)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %28)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %27, i32 %26, i32 %25, i32 %1)    ; IR: uncompute %24
  call void @cqrt_free(i32 %27)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %26)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %25, i32 %24, i32 %15, i32 %12)    ; IR: uncompute %24
  call void @cqrt_free(i32 %25)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %24)    ; IR: release the seed rail (basis state)
  call void @cq_template_select_f64_unc(i32 %23, i32 %22, i32 %8, i32 %5)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the seed rail (basis state)
  call void @cq_template_fmul_f64_hl_unc(i32 %15, i32 %12, double 0x360000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %15)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %12, i32 %1, double 0x360000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %12)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %5, double 0x7FE0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %1, double 0x7FE0000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

define internal fastcc i32 @__cq_q_scalbn_11(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 1023)    ; IR: %3 = icmp sgt n, 1023  [br %3 -> block %4, else %12]
  %4 = call i32 @cq_template_fmul_f64_hl(i32 %0, double 0x7FE0000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %5 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1023)    ; IR: %6 = add nsw n, -1023
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %1, i32 2046)    ; IR: %7 = icmp sgt n, 2046  [br %7 -> block %8]
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %4, double 0x7FE0000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %8 = call i32 @cq_template_smin_i32_hl(i32 %1, i32 3069)    ; IR: %10 = smin(n, 3069)
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 -2046)    ; IR: %11 = add nsw %10, -2046
  %10 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 -1022)    ; IR: %13 = icmp slt n, -1022  (block %12)  [br %13 -> block %14]
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %0, double 0x360000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %12 = call i32 @cq_template_add_i32_hl(i32 %1, i32 969)    ; IR: %16 = add nuw nsw n, 969
  %13 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 -1991)    ; IR: %17 = icmp slt n, -1991  [br %17 -> block %18]
  %14 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 0x360000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %15 = call i32 @cq_template_smax_i32_hl(i32 %1, i32 -2960)    ; IR: %20 = smax(n, -2960)
  %16 = call i32 @cq_template_add_i32_hl(i32 %15, i32 1938)    ; IR: %21 = add nsw %20, 1938
  %17 = call i32 @cq_template_select_i32(i32 %6, i32 %9, i32 %5)    ; IR: %23 = phi i32 [ %11, %8 ], [ %6, %4 ], ...: the %4 subtree on %7
  %18 = call i32 @cq_template_select_i32(i32 %13, i32 %16, i32 %12)    ; IR: %23 = phi i32 ..., [ %21, %18 ], [ %16, %14 ], ...: the %14 subtree on %17
  %19 = call i32 @cq_template_select_i32(i32 %10, i32 %18, i32 %1)    ; IR: %23 = phi i32 ..., [ %1, %12 ]: the %12 subtree on %13
  %20 = call i32 @cq_template_select_i32(i32 %3, i32 %17, i32 %19)    ; IR: %23 = phi i32 (n after the clamps): the top split on %3
  %21 = call i32 @cq_template_select_f64(i32 %6, i32 %7, i32 %4)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7
  %22 = call i32 @cq_template_select_f64(i32 %13, i32 %14, i32 %11)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17
  %23 = call i32 @cq_template_select_f64(i32 %10, i32 %22, i32 %0)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13
  %24 = call i32 @cq_template_select_f64(i32 %3, i32 %21, i32 %23)    ; IR: %24 = phi double (y after the scalings): the top split on %3
  %25 = call i32 @cq_template_add_i32_hl(i32 %20, i32 1023)    ; IR: %25 = add nsw %23, 1023
  %26 = call i32 @cq_template_zext_i32_to_i64(i32 %25)    ; IR: %26 = zext %25 to i64
  %27 = call i32 @cq_template_shl_i64_hl(i32 %26, i64 52)    ; IR: %27 = shl %26, 52
  %28 = call i32 @cq_template_bitcast_i64_to_f64(i32 %27)    ; IR: %28 = bitcast i64 %27 to double  (u.f = 2^n)
  %29 = call i32 @cq_template_fmul_f64(i32 %24, i32 %28)    ; IR: %29 = fmul %24, %28  (y * u.f)
  %30 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret  [result rail: scalbn(x, n)]
  call void @cqrt_copy_f64(i32 %29, i32 %30)    ; IR: copy scalbn(x, n) out
  call void @cq_template_fmul_f64_unc(i32 %29, i32 %24, i32 %28)    ; IR: uncompute %29
  call void @cqrt_free(i32 %29)    ; IR: release the %29 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %28, i32 %27)    ; IR: uncompute %28
  call void @cqrt_free(i32 %28)    ; IR: release the %28 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %27, i32 %26, i64 52)    ; IR: uncompute %27
  call void @cqrt_free(i32 %27)    ; IR: release the %27 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %26, i32 %25)    ; IR: uncompute %26
  call void @cqrt_free(i32 %26)    ; IR: release the %26 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %25, i32 %20, i32 1023)    ; IR: uncompute %25
  call void @cqrt_free(i32 %25)    ; IR: release the %25 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %24, i32 %3, i32 %21, i32 %23)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %10, i32 %22, i32 %0)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %22, i32 %13, i32 %14, i32 %11)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %21, i32 %6, i32 %7, i32 %4)    ; IR: uncompute %24
  call void @cqrt_free(i32 %21)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %20, i32 %3, i32 %17, i32 %19)    ; IR: uncompute %23
  call void @cqrt_free(i32 %20)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %19, i32 %10, i32 %18, i32 %1)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %18, i32 %13, i32 %16, i32 %12)    ; IR: uncompute %23
  call void @cqrt_free(i32 %18)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %17, i32 %6, i32 %9, i32 %5)    ; IR: uncompute %23
  call void @cqrt_free(i32 %17)    ; IR: release the %23 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %15, i32 1938)    ; IR: uncompute %21
  call void @cqrt_free(i32 %16)    ; IR: release the %21 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %15, i32 %1, i32 -2960)    ; IR: uncompute %20
  call void @cqrt_free(i32 %15)    ; IR: release the %20 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %14, i32 %11, double 0x360000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %14)    ; IR: release the %19 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %13, i32 %1, i32 -1991)    ; IR: uncompute %17
  call void @cqrt_free(i32 %13)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %1, i32 969)    ; IR: uncompute %16
  call void @cqrt_free(i32 %12)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %0, double 0x360000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %11)    ; IR: release the %15 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %10, i32 %1, i32 -1022)    ; IR: uncompute %13
  call void @cqrt_free(i32 %10)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %8, i32 -2046)    ; IR: uncompute %11
  call void @cqrt_free(i32 %9)    ; IR: release the %11 rail (|0>)
  call void @cq_template_smin_i32_hl_unc(i32 %8, i32 %1, i32 3069)    ; IR: uncompute %10
  call void @cqrt_free(i32 %8)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %4, double 0x7FE0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %1, i32 2046)    ; IR: uncompute %7
  call void @cqrt_free(i32 %6)    ; IR: release the %7 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %1, i32 -1023)    ; IR: uncompute %6
  call void @cqrt_free(i32 %5)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %4, i32 %0, double 0x7FE0000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %4)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %3, i32 %1, i32 1023)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %30    ; IR: ret  (the result handle)
}

define internal fastcc void @__cq_q_scalbn_11_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 1023)    ; IR: %3 = icmp sgt n, 1023  [br %3 -> block %4, else %12]
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %1, double 0x7FE0000000000000)    ; IR: %5 = fmul x, 0x1p<emax>  (block %4)
  %6 = call i32 @cq_template_add_i32_hl(i32 %2, i32 -1023)    ; IR: %6 = add nsw n, -1023
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 2046)    ; IR: %7 = icmp sgt n, 2046  [br %7 -> block %8]
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %5, double 0x7FE0000000000000)    ; IR: %9 = fmul %5, 0x1p<emax>  (block %8)
  %9 = call i32 @cq_template_smin_i32_hl(i32 %2, i32 3069)    ; IR: %10 = smin(n, 3069)
  %10 = call i32 @cq_template_add_i32_hl(i32 %9, i32 -2046)    ; IR: %11 = add nsw %10, -2046
  %11 = call i32 @cq_template_icmp_slt_i32_hl(i32 %2, i32 -1022)    ; IR: %13 = icmp slt n, -1022  (block %12)  [br %13 -> block %14]
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %1, double 0x360000000000000)    ; IR: %15 = fmul x, 0x1p<emin> * 0x1p<p>  (block %14)
  %13 = call i32 @cq_template_add_i32_hl(i32 %2, i32 969)    ; IR: %16 = add nuw nsw n, 969
  %14 = call i32 @cq_template_icmp_slt_i32_hl(i32 %2, i32 -1991)    ; IR: %17 = icmp slt n, -1991  [br %17 -> block %18]
  %15 = call i32 @cq_template_fmul_f64_hl(i32 %12, double 0x360000000000000)    ; IR: %19 = fmul %15, 0x1p<emin> * 0x1p<p>  (block %18)
  %16 = call i32 @cq_template_smax_i32_hl(i32 %2, i32 -2960)    ; IR: %20 = smax(n, -2960)
  %17 = call i32 @cq_template_add_i32_hl(i32 %16, i32 1938)    ; IR: %21 = add nsw %20, 1938
  %18 = call i32 @cq_template_select_i32(i32 %7, i32 %10, i32 %6)    ; IR: %23 = phi i32 [ %11, %8 ], [ %6, %4 ], ...: the %4 subtree on %7
  %19 = call i32 @cq_template_select_i32(i32 %14, i32 %17, i32 %13)    ; IR: %23 = phi i32 ..., [ %21, %18 ], [ %16, %14 ], ...: the %14 subtree on %17
  %20 = call i32 @cq_template_select_i32(i32 %11, i32 %19, i32 %2)    ; IR: %23 = phi i32 ..., [ %1, %12 ]: the %12 subtree on %13
  %21 = call i32 @cq_template_select_i32(i32 %4, i32 %18, i32 %20)    ; IR: %23 = phi i32 (n after the clamps): the top split on %3
  %22 = call i32 @cq_template_select_f64(i32 %7, i32 %8, i32 %5)    ; IR: %24 = phi double [ %9, %8 ], [ %5, %4 ], ...: the %4 subtree on %7
  %23 = call i32 @cq_template_select_f64(i32 %14, i32 %15, i32 %12)    ; IR: %24 = phi double ..., [ %19, %18 ], [ %15, %14 ], ...: the %14 subtree on %17
  %24 = call i32 @cq_template_select_f64(i32 %11, i32 %23, i32 %1)    ; IR: %24 = phi double ..., [ %0, %12 ]: the %12 subtree on %13
  %25 = call i32 @cq_template_select_f64(i32 %4, i32 %22, i32 %24)    ; IR: %24 = phi double (y after the scalings): the top split on %3
  %26 = call i32 @cq_template_add_i32_hl(i32 %21, i32 1023)    ; IR: %25 = add nsw %23, 1023
  %27 = call i32 @cq_template_zext_i32_to_i64(i32 %26)    ; IR: %26 = zext %25 to i64
  %28 = call i32 @cq_template_shl_i64_hl(i32 %27, i64 52)    ; IR: %27 = shl %26, 52
  %29 = call i32 @cq_template_bitcast_i64_to_f64(i32 %28)    ; IR: %28 = bitcast i64 %27 to double  (u.f = 2^n)
  %30 = call i32 @cq_template_fmul_f64(i32 %25, i32 %29)    ; IR: %29 = fmul %24, %28  (y * u.f)
  call void @cqrt_copy_f64(i32 %30, i32 %0)    ; IR: xor scalbn(x, n) out of the result rail
  call void @cq_template_fmul_f64_unc(i32 %30, i32 %25, i32 %29)    ; IR: uncompute %29
  call void @cqrt_free(i32 %30)    ; IR: release the %29 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %29, i32 %28)    ; IR: uncompute %28
  call void @cqrt_free(i32 %29)    ; IR: release the %28 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %28, i32 %27, i64 52)    ; IR: uncompute %27
  call void @cqrt_free(i32 %28)    ; IR: release the %27 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %27, i32 %26)    ; IR: uncompute %26
  call void @cqrt_free(i32 %27)    ; IR: release the %26 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %26, i32 %21, i32 1023)    ; IR: uncompute %25
  call void @cqrt_free(i32 %26)    ; IR: release the %25 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %25, i32 %4, i32 %22, i32 %24)    ; IR: uncompute %24
  call void @cqrt_free(i32 %25)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %24, i32 %11, i32 %23, i32 %1)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %14, i32 %15, i32 %12)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %22, i32 %7, i32 %8, i32 %5)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %21, i32 %4, i32 %18, i32 %20)    ; IR: uncompute %23
  call void @cqrt_free(i32 %21)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %20, i32 %11, i32 %19, i32 %2)    ; IR: uncompute %23
  call void @cqrt_free(i32 %20)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %19, i32 %14, i32 %17, i32 %13)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %18, i32 %7, i32 %10, i32 %6)    ; IR: uncompute %23
  call void @cqrt_free(i32 %18)    ; IR: release the %23 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %16, i32 1938)    ; IR: uncompute %21
  call void @cqrt_free(i32 %17)    ; IR: release the %21 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %16, i32 %2, i32 -2960)    ; IR: uncompute %20
  call void @cqrt_free(i32 %16)    ; IR: release the %20 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %15, i32 %12, double 0x360000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %15)    ; IR: release the %19 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %14, i32 %2, i32 -1991)    ; IR: uncompute %17
  call void @cqrt_free(i32 %14)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %13, i32 %2, i32 969)    ; IR: uncompute %16
  call void @cqrt_free(i32 %13)    ; IR: release the %16 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %12, i32 %1, double 0x360000000000000)    ; IR: uncompute %15
  call void @cqrt_free(i32 %12)    ; IR: release the %15 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %11, i32 %2, i32 -1022)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %9, i32 -2046)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_smin_i32_hl_unc(i32 %9, i32 %2, i32 3069)    ; IR: uncompute %10
  call void @cqrt_free(i32 %9)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %5, double 0x7FE0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %2, i32 2046)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %2, i32 -1023)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %1, double 0x7FE0000000000000)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %4, i32 %2, i32 1023)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void    ; IR: ret  (the twin returns nothing)
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare double @llvm.fabs.f64(double)
declare double @llvm.maxnum.f64(double, double)
declare double @logb(double)
declare double @scalbn(double, i32)
declare double @llvm.fmuladd.f64(double, double, double)
declare i32 @cq_template_fdiv_f64_hl(i32, double)
declare void @cq_template_fdiv_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmp_ord_f64_hl(i32, double)
declare void @cq_template_fcmp_ord_f64_hl_unc(i32, i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_or_i1(i32, i32, i32)
declare double @llvm.copysign.f64(double, double)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_fcmp_une_f64_hl(i32, double)
declare void @cq_template_fcmp_une_f64_hl_unc(i32, i32, double)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare i32 @cq_template_copysign_f64(i32, i32)
declare void @cq_template_copysign_f64_unc(i32, i32, i32)
declare i32 @cq_template_fneg_f64(i32)
declare void @cq_template_fneg_f64_unc(i32, i32)
declare i32 @cq_template_fcmp_ueq_f64_hl(i32, double)
declare void @cq_template_fcmp_ueq_f64_hl_unc(i32, i32, double)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_select_f64_lh(i32, double, i32)
declare void @cq_template_select_f64_lh_unc(i32, i32, double, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare void @cqrt_copy_f64(i32, i32)
declare i32 @cq_template_fmax_f64(i32, i32)
declare void @cq_template_fmax_f64_unc(i32, i32, i32)
declare i32 @cq_template_fptosi_f64_to_i32(i32)
declare void @cq_template_fptosi_f64_to_i32_unc(i32, i32)
declare i32 @cq_template_sub_i32_lh(i32, i32)
declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fdiv_f64(i32, i32)
declare void @cq_template_fdiv_f64_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_oeq_f64_hl(i32, double)
declare void @cq_template_fcmp_oeq_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_copysign_f64_lh(double, i32)
declare void @cq_template_copysign_f64_lh_unc(i32, double, i32)
declare i32 @cq_template_fdiv_f64_lh(double, i32)
declare void @cq_template_fdiv_f64_lh_unc(i32, double, i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)
declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @llvm.smin.i32(i32, i32)
declare i32 @llvm.smax.i32(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_smin_i32_hl(i32, i32)
declare void @cq_template_smin_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_smax_i32_hl(i32, i32)
declare void @cq_template_smax_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_bitcast_i64_to_f64(i32)
declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
