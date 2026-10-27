; HAND-WRITTEN. Rules: 18, 20, 3, 4, 5, 8, 9, 2 (and 1).
; Checked: cbrt(x) (measured, %56 -> %57); scalbn(x, n) (measured, %33 -> %34); exp(x) + atan2(x, y) (measured, %7 -> %8);
; sin(x) + log(x) + pow(x, y) (measured, %9 -> %10).
; Clean: every flag, select and arithmetic rail of the four entries, the two clone result rails of the third and the three
; of the fourth (zeroed by the _unc twins, then freed), and the partial sum %7 of the fourth, all freed before each
; measurement.
; Kept: the registers (x %3; x %5 and n %6; x %4; x %4) and the four measured result rails (%56, %33, %7, %9).
; Rotations: (Ry, x, tx, 1) in libm_cbrt_q; (Ry, x, tx, 1), (Ry, n, tn, 1) (cqrt_ry_i32 on the integer register) in
; libm_scalbn_qq; (Ry, x, tx, 1) in libm_exp_atan2_q; (Ry, x, tx, 1) in libm_sin_log_pow_q.
; cbrt_musl and scalbn_musl are static and clang -O1 inlines them, so their musl bodies lower in the entries: the
; `union { double f; unsigned long long i; }` views are bitcast templates (rule 20), the exponent arithmetic is integer
; templates (lshr, trunc, and, udiv, add, zext, shl, or), and the polynomial / Newton steps are fmul, fdiv, fadd, fsub
; templates with the constants as literals (each llvm.fmuladd is UNFUSED, §2: an fmul into a fresh product rail, then an
; fadd, the product uncomputed by its fmul _unc right after the sum and freed). Branches are flags (rule 8) and every merge is a select chain on the local
; flags (rule 9): the %53 phi of cbrt is select(%8, x + x, select(%12 & %19, x, %52)) with one and_i1 for the %13 -> %53 edge;
; the five-incoming phis of %26 in scalbn are four nested selects on %7, %11, %17, %21 with both x and n quantum, so the
; smin/smax clamps and the compares are _hl templates on the n rail. The third and fourth entries reach exp, atan2, sin, log
; and pow (sec. 8 item 14). In the O1.ll, atan2 is a libm call and exp, sin, log, pow are the llvm math intrinsics clang
; emits for them (llvm.exp/sin/log/pow.f64); by rule 18 an intrinsic is the call of the libm function of the same name. The
; compiler injects musl's exp.c, atan2.c, sin.c, log.c and pow.c from the source bundle and lifts them like every other
; callee with a quantum argument: the lowering shows the clone calls __cq_q_exp_1(x), __cq_q_sin_1(x), __cq_q_log_1(x)
; (mask 1) and __cq_q_atan2_10(x, y), __cq_q_pow_10(x, y) (mask 10, y a classical double), each returning a fresh result
; rail (copy-out, rule 18), and their _unc twins zero those rails after the last sum read them; the caller then frees them.
; THE CLONE BODIES ARE DECLARED ONLY: this example witnesses the call sites, the masks and the clone/twin signatures; 184
; shows one lifted libm body (musl atan) in full. For the trace, _tools/trace_stubs.c (exp, atan2) and
; _tools/stubs.d/175_libm_quantum.c (sin, log, pow) print the clone and twin calls so the trace links. Everything but the
; result rails is uncomputed LIFO before each measurement; in the fourth entry the partial sum %7 is uncomputed before the
; sin and log rails it reads (rule 5: an operand rail outlives every _unc that reads it).
source_filename = "libm_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @libm_cbrt_q(double noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_bitcast_f64_to_i64(i32 %3)    ; IR: %4 = bitcast %3 to i64  (u.i)
  %5 = call i32 @cq_template_lshr_i64_hl(i32 %4, i64 32)    ; IR: %5 = lshr %4, 32
  %6 = call i32 @cq_template_trunc_i64_to_i32(i32 %5)    ; IR: %6 = trunc nuw %5 to i32
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 2147483647)    ; IR: %7 = and %6, 0x7fffffff  (hx)
  %8 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %7, i32 2146435071)    ; IR: %8 = icmp ugt %7, 0x7fefffff  (hx >= 0x7ff00000)  [br %8 -> block %9]
  %9 = call i32 @cq_template_fadd_f64(i32 %3, i32 %3)    ; IR: %10 = fadd %3, %3  (block %9: x + x)
  %10 = call i32 @cq_template_icmp_ult_i32_hl(i32 %7, i32 1048576)    ; IR: %12 = icmp ult %7, 0x00100000  (block %11)  [br %12 -> block %13]
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %3, double 0x4350000000000000)    ; IR: %14 = fmul %3, 0x1p54  (block %13)
  %12 = call i32 @cq_template_bitcast_f64_to_i64(i32 %11)    ; IR: %15 = bitcast %14 to i64
  %13 = call i32 @cq_template_lshr_i64_hl(i32 %12, i64 32)    ; IR: %16 = lshr %15, 32
  %14 = call i32 @cq_template_trunc_i64_to_i32(i32 %13)    ; IR: %17 = trunc nuw %16 to i32
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 2147483647)    ; IR: %18 = and %17, 0x7fffffff
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)    ; IR: %19 = icmp eq %18, 0  [br %19 -> exit with %3]
  %17 = call i32 @cq_template_select_i32(i32 %10, i32 %15, i32 %7)    ; IR: %21 = phi i32 [ %18, %13 ], [ %7, %11 ]  (merge of block %20 on %12)
  %18 = call i32 @cq_template_select_i32_ll(i32 %10, i32 696219795, i32 715094163)    ; IR: %22 = phi i32 [ B2, %13 ], [ B1, %11 ]
  %19 = call i32 @cq_template_select_f64(i32 %10, i32 %11, i32 %3)    ; IR: %23 = phi double [ %14, %13 ], [ %3, %11 ]
  %20 = call i32 @cq_template_udiv_i32_hl(i32 %17, i32 3)    ; IR: %24 = udiv %21, 3
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %18)    ; IR: %25 = add nuw nsw %24, %22
  %22 = call i32 @cq_template_bitcast_f64_to_i64(i32 %19)    ; IR: %26 = bitcast %23 to i64
  %23 = call i32 @cq_template_and_i64_hl(i32 %22, i64 -9223372036854775808)    ; IR: %27 = and %26, 1 << 63  (the sign)
  %24 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %28 = zext nneg %25 to i64
  %25 = call i32 @cq_template_shl_i64_hl(i32 %24, i64 32)    ; IR: %29 = shl nuw nsw %28, 32
  %26 = call i32 @cq_template_or_i64(i32 %25, i32 %23)    ; IR: %30 = or disjoint %29, %27
  %27 = call i32 @cq_template_bitcast_i64_to_f64(i32 %26)    ; IR: %31 = bitcast %30 to double  (t)
  %28 = call i32 @cq_template_fmul_f64(i32 %27, i32 %27)    ; IR: %32 = fmul %31, %31
  %29 = call i32 @cq_template_fdiv_f64(i32 %27, i32 %3)    ; IR: %33 = fdiv %31, %3
  %30 = call i32 @cq_template_fmul_f64(i32 %28, i32 %29)    ; IR: %34 = fmul %32, %33  (r)
  %31 = call i32 @cq_template_fmul_f64_hl(i32 %30, double 0x3FF9F1604A49D6C2)    ; IR: %35 = fmuladd(%34, P2, P1)  [unfused product]
  %32 = call i32 @cq_template_fadd_f64_hl(i32 %31, double 0xBFFE28E092F02420)    ; IR: %35 = fmuladd(%34, P2, P1)  [unfused sum]
  %33 = call i32 @cq_template_fmul_f64(i32 %30, i32 %32)    ; IR: %36 = fmuladd(%34, %35, P0)  [unfused product]
  %34 = call i32 @cq_template_fadd_f64_hl(i32 %33, double 0x3FFE03E60F61E692)    ; IR: %36 = fmuladd(%34, %35, P0)  [unfused sum]
  %35 = call i32 @cq_template_fmul_f64(i32 %30, i32 %30)    ; IR: %37 = fmul %34, %34
  %36 = call i32 @cq_template_fmul_f64(i32 %30, i32 %35)    ; IR: %38 = fmul %34, %37  (r*r*r)
  %37 = call i32 @cq_template_fmul_f64_hl(i32 %30, double 0x3FC2B000D4E4EDD7)    ; IR: %39 = fmuladd(%34, P4, P3)  [unfused product]
  %38 = call i32 @cq_template_fadd_f64_hl(i32 %37, double 0xBFE844CBBEE751D9)    ; IR: %39 = fmuladd(%34, P4, P3)  [unfused sum]
  %39 = call i32 @cq_template_fmul_f64(i32 %36, i32 %38)    ; IR: %40 = fmuladd(%38, %39, %36)  [unfused product]
  %40 = call i32 @cq_template_fadd_f64(i32 %39, i32 %34)    ; IR: %40 = fmuladd(%38, %39, %36)  [unfused sum]
  %41 = call i32 @cq_template_fmul_f64(i32 %40, i32 %27)    ; IR: %41 = fmul %40, %31  (t)
  %42 = call i32 @cq_template_bitcast_f64_to_i64(i32 %41)    ; IR: %42 = bitcast %41 to i64
  %43 = call i32 @cq_template_and_i64_hl(i32 %42, i64 -1073741824)    ; IR: %43 = and %42, 0xffffffffc0000000
  %44 = call i32 @cq_template_add_i64_hl(i32 %43, i64 2147483648)    ; IR: %44 = add %43, 0x80000000
  %45 = call i32 @cq_template_bitcast_i64_to_f64(i32 %44)    ; IR: %45 = bitcast %44 to double  (rounded t)
  %46 = call i32 @cq_template_fmul_f64(i32 %45, i32 %45)    ; IR: %46 = fmul %45, %45  (s)
  %47 = call i32 @cq_template_fdiv_f64(i32 %3, i32 %46)    ; IR: %47 = fdiv %3, %46  (r)
  %48 = call i32 @cq_template_fadd_f64(i32 %45, i32 %45)    ; IR: %48 = fadd %45, %45  (w)
  %49 = call i32 @cq_template_fsub_f64(i32 %47, i32 %45)    ; IR: %49 = fsub %47, %45
  %50 = call i32 @cq_template_fadd_f64(i32 %48, i32 %47)    ; IR: %50 = fadd %48, %47
  %51 = call i32 @cq_template_fdiv_f64(i32 %49, i32 %50)    ; IR: %51 = fdiv %49, %50
  %52 = call i32 @cq_template_fmul_f64(i32 %45, i32 %51)    ; IR: %52 = fmuladd(%45, %51, %45)  (t + t*r)  [unfused product]
  %53 = call i32 @cq_template_fadd_f64(i32 %52, i32 %45)    ; IR: %52 = fmuladd(%45, %51, %45)  (t + t*r)  [unfused sum]
  %54 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: P13x = path predicate of the %13 -> %53 edge relative to %11: %12 & %19  [fresh flag rail]
  call void @cqrt_and_i1(i32 %10, i32 %16, i32 %54)    ; IR: P13x = path predicate of the %13 -> %53 edge relative to %11: %12 & %19
  %55 = call i32 @cq_template_select_f64(i32 %54, i32 %3, i32 %53)    ; IR: %54 = phi [ %10, %9 ], [ %52, %20 ], [ %3, %13 ]: inner select on %12 & %19 (return x against the %20 path)
  %56 = call i32 @cq_template_select_f64(i32 %8, i32 %9, i32 %55)    ; IR: %54 = phi: outer select on %8 (x + x)  [result rail]
  call void @cq_template_select_f64_unc(i32 %55, i32 %54, i32 %3, i32 %53)    ; IR: uncompute %54
  call void @cqrt_free(i32 %55)    ; IR: release the %54 rail (|0>)
  call void @cqrt_and_i1(i32 %10, i32 %16, i32 %54)    ; IR: uncompute P13x  [self-inverse]
  call void @cqrt_free(i32 %54)    ; IR: release the P13x rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %53, i32 %52, i32 %45)    ; IR: uncompute %52  [sum]
  call void @cqrt_free(i32 %53)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %52, i32 %45, i32 %51)    ; IR: uncompute %52  [product]
  call void @cqrt_free(i32 %52)    ; IR: release the %52 product rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %51, i32 %49, i32 %50)    ; IR: uncompute %51
  call void @cqrt_free(i32 %51)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %50, i32 %48, i32 %47)    ; IR: uncompute %50
  call void @cqrt_free(i32 %50)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %49, i32 %47, i32 %45)    ; IR: uncompute %49
  call void @cqrt_free(i32 %49)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %48, i32 %45, i32 %45)    ; IR: uncompute %48
  call void @cqrt_free(i32 %48)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %47, i32 %3, i32 %46)    ; IR: uncompute %47
  call void @cqrt_free(i32 %47)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %46, i32 %45, i32 %45)    ; IR: uncompute %46
  call void @cqrt_free(i32 %46)    ; IR: release the %46 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %45, i32 %44)    ; IR: uncompute %45
  call void @cqrt_free(i32 %45)    ; IR: release the %45 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %44, i32 %43, i64 2147483648)    ; IR: uncompute %44
  call void @cqrt_free(i32 %44)    ; IR: release the %44 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %43, i32 %42, i64 -1073741824)    ; IR: uncompute %43
  call void @cqrt_free(i32 %43)    ; IR: release the %43 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %42, i32 %41)    ; IR: uncompute %42
  call void @cqrt_free(i32 %42)    ; IR: release the %42 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %41, i32 %40, i32 %27)    ; IR: uncompute %41
  call void @cqrt_free(i32 %41)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %40, i32 %39, i32 %34)    ; IR: uncompute %40  [sum]
  call void @cqrt_free(i32 %40)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %39, i32 %36, i32 %38)    ; IR: uncompute %40  [product]
  call void @cqrt_free(i32 %39)    ; IR: release the %40 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %38, i32 %37, double 0xBFE844CBBEE751D9)    ; IR: uncompute %39  [sum]
  call void @cqrt_free(i32 %38)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %37, i32 %30, double 0x3FC2B000D4E4EDD7)    ; IR: uncompute %39  [product]
  call void @cqrt_free(i32 %37)    ; IR: release the %39 product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %36, i32 %30, i32 %35)    ; IR: uncompute %38
  call void @cqrt_free(i32 %36)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %35, i32 %30, i32 %30)    ; IR: uncompute %37
  call void @cqrt_free(i32 %35)    ; IR: release the %37 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %34, i32 %33, double 0x3FFE03E60F61E692)    ; IR: uncompute %36  [sum]
  call void @cqrt_free(i32 %34)    ; IR: release the %36 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %33, i32 %30, i32 %32)    ; IR: uncompute %36  [product]
  call void @cqrt_free(i32 %33)    ; IR: release the %36 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %32, i32 %31, double 0xBFFE28E092F02420)    ; IR: uncompute %35  [sum]
  call void @cqrt_free(i32 %32)    ; IR: release the %35 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %31, i32 %30, double 0x3FF9F1604A49D6C2)    ; IR: uncompute %35  [product]
  call void @cqrt_free(i32 %31)    ; IR: release the %35 product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %30, i32 %28, i32 %29)    ; IR: uncompute %34
  call void @cqrt_free(i32 %30)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %29, i32 %27, i32 %3)    ; IR: uncompute %33
  call void @cqrt_free(i32 %29)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %28, i32 %27, i32 %27)    ; IR: uncompute %32
  call void @cqrt_free(i32 %28)    ; IR: release the %32 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %27, i32 %26)    ; IR: uncompute %31
  call void @cqrt_free(i32 %27)    ; IR: release the %31 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %26, i32 %25, i32 %23)    ; IR: uncompute %30
  call void @cqrt_free(i32 %26)    ; IR: release the %30 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %25, i32 %24, i64 32)    ; IR: uncompute %29
  call void @cqrt_free(i32 %25)    ; IR: release the %29 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %24, i32 %21)    ; IR: uncompute %28
  call void @cqrt_free(i32 %24)    ; IR: release the %28 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %23, i32 %22, i64 -9223372036854775808)    ; IR: uncompute %27
  call void @cqrt_free(i32 %23)    ; IR: release the %27 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %22, i32 %19)    ; IR: uncompute %26
  call void @cqrt_free(i32 %22)    ; IR: release the %26 rail (|0>)
  call void @cq_template_add_i32_unc(i32 %21, i32 %20, i32 %18)    ; IR: uncompute %25
  call void @cqrt_free(i32 %21)    ; IR: release the %25 rail (|0>)
  call void @cq_template_udiv_i32_hl_unc(i32 %20, i32 %17, i32 3)    ; IR: uncompute %24
  call void @cqrt_free(i32 %20)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %19, i32 %10, i32 %11, i32 %3)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %18, i32 %10, i32 696219795, i32 715094163)    ; IR: uncompute %22
  call void @cqrt_free(i32 %18)    ; IR: release the %22 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %17, i32 %10, i32 %15, i32 %7)    ; IR: uncompute %21
  call void @cqrt_free(i32 %17)    ; IR: release the %21 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)    ; IR: uncompute %19
  call void @cqrt_free(i32 %16)    ; IR: release the %19 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 2147483647)    ; IR: uncompute %18
  call void @cqrt_free(i32 %15)    ; IR: release the %18 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %14, i32 %13)    ; IR: uncompute %17
  call void @cqrt_free(i32 %14)    ; IR: release the %17 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %13, i32 %12, i64 32)    ; IR: uncompute %16
  call void @cqrt_free(i32 %13)    ; IR: release the %16 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %15
  call void @cqrt_free(i32 %12)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %3, double 0x4350000000000000)    ; IR: uncompute %14
  call void @cqrt_free(i32 %11)    ; IR: release the %14 rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %10, i32 %7, i32 1048576)    ; IR: uncompute %12
  call void @cqrt_free(i32 %10)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %9, i32 %3, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %9)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %8, i32 %7, i32 2146435071)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 2147483647)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %5, i32 %4, i64 32)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %4, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %57 = call double @cqrt_measure_f64(i32 %56)    ; IR: %55 = cq_measure_f64(%54)
  ret double %57    ; IR: ret double %55
}

define double @libm_scalbn_qq(double noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register n]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 1023)    ; IR: %7 = icmp sgt %6, 1023  [br %7 -> block %8, else %16]
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %5, double 0x7FE0000000000000)    ; IR: %9 = fmul %5, 0x1p1023  (block %8)
  %9 = call i32 @cq_template_add_i32_hl(i32 %6, i32 -1023)    ; IR: %10 = add nsw %6, -1023
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 2046)    ; IR: %11 = icmp sgt %6, 2046  [br %11 -> block %12]
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %8, double 0x7FE0000000000000)    ; IR: %13 = fmul %9, 0x1p1023  (block %12)
  %12 = call i32 @cq_template_smin_i32_hl(i32 %6, i32 3069)    ; IR: %14 = smin(%6, 3069)
  %13 = call i32 @cq_template_add_i32_hl(i32 %12, i32 -2046)    ; IR: %15 = add nsw %14, -2046
  %14 = call i32 @cq_template_icmp_slt_i32_hl(i32 %6, i32 -1022)    ; IR: %17 = icmp slt %6, -1022  (block %16)  [br %17 -> block %18]
  %15 = call i32 @cq_template_fmul_f64_hl(i32 %5, double 0x360000000000000)    ; IR: %19 = fmul %5, 0x1p-1022 * 0x1p53  (block %18)
  %16 = call i32 @cq_template_add_i32_hl(i32 %6, i32 969)    ; IR: %20 = add nuw nsw %6, 969
  %17 = call i32 @cq_template_icmp_slt_i32_hl(i32 %6, i32 -1991)    ; IR: %21 = icmp slt %6, -1991  [br %21 -> block %22]
  %18 = call i32 @cq_template_fmul_f64_hl(i32 %15, double 0x360000000000000)    ; IR: %23 = fmul %19, 0x1p-1022 * 0x1p53  (block %22)
  %19 = call i32 @cq_template_smax_i32_hl(i32 %6, i32 -2960)    ; IR: %24 = smax(%6, -2960)
  %20 = call i32 @cq_template_add_i32_hl(i32 %19, i32 1938)    ; IR: %25 = add nsw %24, 1938
  %21 = call i32 @cq_template_select_i32(i32 %10, i32 %13, i32 %9)    ; IR: %27 = phi i32 [ %15, %12 ], [ %10, %8 ], ...: the %8 subtree on %11
  %22 = call i32 @cq_template_select_i32(i32 %17, i32 %20, i32 %16)    ; IR: %27 = phi i32 ..., [ %25, %22 ], [ %20, %18 ], ...: the %18 subtree on %21
  %23 = call i32 @cq_template_select_i32(i32 %14, i32 %22, i32 %6)    ; IR: %27 = phi i32 ..., [ %6, %16 ]: the %16 subtree on %17
  %24 = call i32 @cq_template_select_i32(i32 %7, i32 %21, i32 %23)    ; IR: %27 = phi i32 (n after the clamps): the top split on %7
  %25 = call i32 @cq_template_select_f64(i32 %10, i32 %11, i32 %8)    ; IR: %28 = phi double [ %13, %12 ], [ %9, %8 ], ...: the %8 subtree on %11
  %26 = call i32 @cq_template_select_f64(i32 %17, i32 %18, i32 %15)    ; IR: %28 = phi double ..., [ %23, %22 ], [ %19, %18 ], ...: the %18 subtree on %21
  %27 = call i32 @cq_template_select_f64(i32 %14, i32 %26, i32 %5)    ; IR: %28 = phi double ..., [ %5, %16 ]: the %16 subtree on %17
  %28 = call i32 @cq_template_select_f64(i32 %7, i32 %25, i32 %27)    ; IR: %28 = phi double (y after the scalings): the top split on %7
  %29 = call i32 @cq_template_add_i32_hl(i32 %24, i32 1023)    ; IR: %29 = add nsw %27, 1023
  %30 = call i32 @cq_template_zext_i32_to_i64(i32 %29)    ; IR: %30 = zext %29 to i64
  %31 = call i32 @cq_template_shl_i64_hl(i32 %30, i64 52)    ; IR: %31 = shl %30, 52
  %32 = call i32 @cq_template_bitcast_i64_to_f64(i32 %31)    ; IR: %32 = bitcast %31 to double  (u.f = 2^n)
  %33 = call i32 @cq_template_fmul_f64(i32 %28, i32 %32)    ; IR: %33 = fmul %28, %32  (y * u.f)  [result rail]
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %32, i32 %31)    ; IR: uncompute %32
  call void @cqrt_free(i32 %32)    ; IR: release the %32 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %31, i32 %30, i64 52)    ; IR: uncompute %31
  call void @cqrt_free(i32 %31)    ; IR: release the %31 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %30, i32 %29)    ; IR: uncompute %30
  call void @cqrt_free(i32 %30)    ; IR: release the %30 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %29, i32 %24, i32 1023)    ; IR: uncompute %29
  call void @cqrt_free(i32 %29)    ; IR: release the %29 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %28, i32 %7, i32 %25, i32 %27)    ; IR: uncompute %28
  call void @cqrt_free(i32 %28)    ; IR: release the %28 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %27, i32 %14, i32 %26, i32 %5)    ; IR: uncompute %28
  call void @cqrt_free(i32 %27)    ; IR: release the %28 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %26, i32 %17, i32 %18, i32 %15)    ; IR: uncompute %28
  call void @cqrt_free(i32 %26)    ; IR: release the %28 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %25, i32 %10, i32 %11, i32 %8)    ; IR: uncompute %28
  call void @cqrt_free(i32 %25)    ; IR: release the %28 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %24, i32 %7, i32 %21, i32 %23)    ; IR: uncompute %27
  call void @cqrt_free(i32 %24)    ; IR: release the %27 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %23, i32 %14, i32 %22, i32 %6)    ; IR: uncompute %27
  call void @cqrt_free(i32 %23)    ; IR: release the %27 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %22, i32 %17, i32 %20, i32 %16)    ; IR: uncompute %27
  call void @cqrt_free(i32 %22)    ; IR: release the %27 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %21, i32 %10, i32 %13, i32 %9)    ; IR: uncompute %27
  call void @cqrt_free(i32 %21)    ; IR: release the %27 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %20, i32 %19, i32 1938)    ; IR: uncompute %25
  call void @cqrt_free(i32 %20)    ; IR: release the %25 rail (|0>)
  call void @cq_template_smax_i32_hl_unc(i32 %19, i32 %6, i32 -2960)    ; IR: uncompute %24
  call void @cqrt_free(i32 %19)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %18, i32 %15, double 0x360000000000000)    ; IR: uncompute %23
  call void @cqrt_free(i32 %18)    ; IR: release the %23 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %17, i32 %6, i32 -1991)    ; IR: uncompute %21
  call void @cqrt_free(i32 %17)    ; IR: release the %21 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %16, i32 %6, i32 969)    ; IR: uncompute %20
  call void @cqrt_free(i32 %16)    ; IR: release the %20 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %15, i32 %5, double 0x360000000000000)    ; IR: uncompute %19
  call void @cqrt_free(i32 %15)    ; IR: release the %19 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %14, i32 %6, i32 -1022)    ; IR: uncompute %17
  call void @cqrt_free(i32 %14)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %13, i32 %12, i32 -2046)    ; IR: uncompute %15
  call void @cqrt_free(i32 %13)    ; IR: release the %15 rail (|0>)
  call void @cq_template_smin_i32_hl_unc(i32 %12, i32 %6, i32 3069)    ; IR: uncompute %14
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %8, double 0x7FE0000000000000)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %6, i32 2046)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %6, i32 -1023)    ; IR: uncompute %10
  call void @cqrt_free(i32 %9)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %5, double 0x7FE0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 1023)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %34 = call double @cqrt_measure_f64(i32 %33)    ; IR: %34 = cq_measure_f64(%33)
  ret double %34    ; IR: ret double %34
}

define double @libm_exp_atan2_q(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @__cq_q_exp_1(i32 %4)    ; IR: %5 = llvm.exp.f64(%4): the injected musl exp body, quantum clone (mask 1; body not shown, see the header)
  %6 = call i32 @__cq_q_atan2_10(i32 %4, double %2)    ; IR: %6 = atan2(%4, %2): the injected musl atan2 body, quantum clone (mask 10; body not shown)
  %7 = call i32 @cq_template_fadd_f64(i32 %5, i32 %6)    ; IR: %7 = fadd %5, %6  [result rail]
  call void @__cq_q_atan2_10_unc(i32 %6, i32 %4, double %2)    ; IR: uncompute the result rail(s) of %6
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @__cq_q_exp_1_unc(i32 %5, i32 %4)    ; IR: uncompute the result rail(s) of %5
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %8 = cq_measure_f64(%7)
  ret double %8    ; IR: ret double %8
}

define double @libm_sin_log_pow_q(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @__cq_q_sin_1(i32 %4)    ; IR: %5 = llvm.sin.f64(%4): the libm sin (rule 18), the injected musl sin body, quantum clone (mask 1; body not shown)
  %6 = call i32 @__cq_q_log_1(i32 %4)    ; IR: %6 = llvm.log.f64(%4): the libm log, the injected musl log body, quantum clone (mask 1; body not shown)
  %7 = call i32 @cq_template_fadd_f64(i32 %5, i32 %6)    ; IR: %7 = fadd %5, %6
  %8 = call i32 @__cq_q_pow_10(i32 %4, double %2)    ; IR: %8 = llvm.pow.f64(%4, %2): the libm pow, the injected musl pow body, quantum clone (mask 10, y a classical double; body not shown)
  %9 = call i32 @cq_template_fadd_f64(i32 %8, i32 %7)    ; IR: %9 = fadd %8, %7  [result rail]
  call void @__cq_q_pow_10_unc(i32 %8, i32 %4, double %2)    ; IR: uncompute the result rail of %8
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %7, i32 %5, i32 %6)    ; IR: uncompute %7 (reads %5, %6: they outlive it)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @__cq_q_log_1_unc(i32 %6, i32 %4)    ; IR: uncompute the result rail of %6
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @__cq_q_sin_1_unc(i32 %5, i32 %4)    ; IR: uncompute the result rail of %5
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  %10 = call double @cqrt_measure_f64(i32 %9)    ; IR: %10 = cq_measure_f64(%9)
  ret double %10    ; IR: ret double %10
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare i32 @cq_template_udiv_i32_hl(i32, i32)
declare void @cq_template_udiv_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_or_i64(i32, i32)
declare void @cq_template_or_i64_unc(i32, i32, i32)
declare i32 @cq_template_bitcast_i64_to_f64(i32)
declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fdiv_f64(i32, i32)
declare void @cq_template_fdiv_f64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_smin_i32_hl(i32, i32)
declare void @cq_template_smin_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_smax_i32_hl(i32, i32)
declare void @cq_template_smax_i32_hl_unc(i32, i32, i32)
declare i32 @__cq_q_exp_1(i32)
declare void @__cq_q_exp_1_unc(i32, i32)
declare i32 @__cq_q_atan2_10(i32, double)
declare void @__cq_q_atan2_10_unc(i32, i32, double)
declare i32 @__cq_q_sin_1(i32)
declare void @__cq_q_sin_1_unc(i32, i32)
declare i32 @__cq_q_log_1(i32)
declare void @__cq_q_log_1_unc(i32, i32)
declare i32 @__cq_q_pow_10(i32, double)
declare void @__cq_q_pow_10_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
