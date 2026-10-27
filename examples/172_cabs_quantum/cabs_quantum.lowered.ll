; HAND-WRITTEN. Rules: 18 (the musl hypot body is inlined by clang, so it lowers in the entry), 20, 3, 4, 5, 8, 9 (and 1).
; Checked: cabs_quantum_re: hypot(re, im) (measured, %60 -> %61); cabs_quantum_both: hypot(re, im) with both quantum
; (measured, %62 -> %63).
; Clean: every flag, select and arithmetic rail of both entries, all freed before the measurement.
; Kept: the registers (re %4; re %5 and im %6) and the two measured result rails (%60, %62).
; Rotations: (Ry, re, tr, 1) in cabs_quantum_re; (Ry, re, tr, 1), (Ry, im, ti, 1) in cabs_quantum_both.
; cabs is hypot; musl's body is static and clang -O1 inlines it, so no clone appears: the whole function is
; straight-line templates in the entry. The `union { double f; unsigned long long i; }` views are SSA values (rule 20):
; a bitcast template between f64 and i64, the exponent read is lshr + trunc, and fabs clears the sign. The conditional
; swap `if (ux.i < uy.i)` is one icmp flag and two selects (rule 9). Every `return` of the if ladder is an exit edge:
; the four-incoming phi of %63 is three nested selects on the local branch flags (%18: return y; %22 = or_i1 of the two
; equality flags: return x; %25: x + y), innermost the sqrt path, so each select is dominated by the previous flag's
; false case and no path conjunction is needed; the three-incoming phis of %38 (the scaling by 2^+-700 and z) are two
; nested selects on %29 and %34 the same way. The split x = hx + lx goes through fptrunc / fpext templates, the two
; llvm.fmuladd sums (lx, ly) UNFUSED (§2, cf. 14): an fmul into a fresh product rail, then an fadd of product and
; addend, the product uncomputed after the sum, and sqrt is a template. In the second entry the compare, the selects and
; the sum are two-handle templates (both operands quantum). Everything but the result rail is uncomputed LIFO and freed
; before the measurement.
source_filename = "cabs_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @cabs_quantum_re(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fabs_f64(i32 %4)    ; IR: %5 = fabs(re)
  %6 = call i32 @cq_template_bitcast_f64_to_i64(i32 %5)    ; IR: %6 = bitcast to i64  (ux.i, sign cleared)
  %7 = tail call double @llvm.fabs.f64(double %2)    ; IR: %7 = fabs(im)  (classical)
  %8 = bitcast double %7 to i64    ; IR: %8 = bitcast to i64  (uy.i)  (classical)
  %9 = call i32 @cq_template_icmp_ult_i64_hl(i32 %6, i64 %8)    ; IR: %9 = icmp ult %6, %8  (ux.i < uy.i: swap)
  %10 = call i32 @cq_template_select_f64_hl(i32 %9, i32 %5, double %7)    ; IR: %10 = select %9, %5, %7  (the smaller magnitude: y after the swap)
  %11 = call i32 @cq_template_select_f64_lh(i32 %9, double %7, i32 %5)    ; IR: %11 = select %9, %7, %5  (the larger magnitude: x after the swap)
  %12 = call i32 @cq_template_bitcast_f64_to_i64(i32 %11)    ; IR: %12 = bitcast to i64  (ux.i)
  %13 = call i32 @cq_template_lshr_i64_hl(i32 %12, i64 52)    ; IR: %13 = lshr %12, 52  (ex)
  %14 = call i32 @cq_template_trunc_i64_to_i32(i32 %13)    ; IR: %14 = trunc nuw nsw %13 to i32
  %15 = call i32 @cq_template_bitcast_f64_to_i64(i32 %10)    ; IR: %15 = bitcast to i64  (uy.i)
  %16 = call i32 @cq_template_lshr_i64_hl(i32 %15, i64 52)    ; IR: %16 = lshr %15, 52  (ey)
  %17 = call i32 @cq_template_trunc_i64_to_i32(i32 %16)    ; IR: %17 = trunc nuw nsw %16 to i32
  %18 = call i32 @cq_template_icmp_eq_i64_hl(i32 %16, i64 2047)    ; IR: %18 = icmp eq %16, 2047  (ey == 0x7ff)  [br -> exit with %10]
  %19 = call i32 @cq_template_icmp_eq_i64_hl(i32 %13, i64 2047)    ; IR: %20 = icmp eq %13, 2047  (ex == 0x7ff)
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 0)    ; IR: %21 = icmp eq %15, 0  (uy.i == 0)
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %22 = or i1 %21, %20  [br -> exit with %11]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %20, i32 %19, i32 %21)    ; IR: %22 = or i1 %21, %20  [br -> exit with %11]
  %22 = call i32 @cq_template_sub_i32(i32 %14, i32 %17)    ; IR: %24 = sub nsw %14, %17  (ex - ey)
  %23 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %22, i32 64)    ; IR: %25 = icmp sgt %24, 64  [br -> block %26: x + y]
  %24 = call i32 @cq_template_fadd_f64_hl(i32 %5, double %7)    ; IR: %27 = fadd %7, %5  (x + y)  (commutative, quantum operand first)
  %25 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %12, i64 6908521828386340863)    ; IR: %29 = icmp ugt %12, 0x5FDFFFFFFFFFFFFF  (ex > 0x3ff + 510)
  %26 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 0x1430000000000000)    ; IR: %31 = fmul %11, 0x1p-700
  %27 = call i32 @cq_template_fmul_f64_hl(i32 %10, double 0x1430000000000000)    ; IR: %32 = fmul %10, 0x1p-700
  %28 = call i32 @cq_template_icmp_ult_i64_hl(i32 %15, i64 2580562586483294208)    ; IR: %34 = icmp ult %15, 0x23D0000000000000  (ey < 0x3ff - 450)
  %29 = call i32 @cq_template_fmul_f64_hl(i32 %11, double 0x6BB0000000000000)    ; IR: %36 = fmul %11, 0x1p700
  %30 = call i32 @cq_template_fmul_f64_hl(i32 %10, double 0x6BB0000000000000)    ; IR: %37 = fmul %10, 0x1p700
  %31 = call i32 @cq_template_select_f64(i32 %28, i32 %30, i32 %10)    ; IR: %39 = phi [ %32, .. ], [ %37, .. ], [ %10, .. ]: inner select on %34 (the outer select fixes the %29 case)
  %32 = call i32 @cq_template_select_f64(i32 %25, i32 %27, i32 %31)    ; IR: %39 = phi (y scaled): outer select on %29
  %33 = call i32 @cq_template_select_f64(i32 %28, i32 %29, i32 %11)    ; IR: %40 = phi [ %31, .. ], [ %36, .. ], [ %11, .. ]: inner select on %34
  %34 = call i32 @cq_template_select_f64(i32 %25, i32 %26, i32 %33)    ; IR: %40 = phi (x scaled): outer select on %29
  %35 = call i32 @cq_template_select_f64_ll(i32 %28, double 0x1430000000000000, double 1.000000e+00)    ; IR: %41 = phi [ 0x1p700, .. ], [ 0x1p-700, .. ], [ 1.0, .. ]: inner select on %34
  %36 = call i32 @cq_template_select_f64_lh(i32 %25, double 0x6BB0000000000000, i32 %35)    ; IR: %41 = phi (z): outer select on %29
  %37 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %34)    ; IR: %42 = fptrunc %40 to float
  %38 = call i32 @cq_template_fpext_f32_to_f64(i32 %37)    ; IR: %43 = fpext %42 to double  (hx)
  %39 = call i32 @cq_template_fsub_f64(i32 %34, i32 %38)    ; IR: %44 = fsub %40, %43  (lx)
  %40 = call i32 @cq_template_fmul_f64(i32 %38, i32 %38)    ; IR: %45 = fmul %43, %43  (hx*hx)
  %41 = call i32 @cq_template_fadd_f64(i32 %34, i32 %34)    ; IR: %46 = fadd %40, %40  (x + x)
  %42 = call i32 @cq_template_fsub_f64(i32 %41, i32 %39)    ; IR: %47 = fsub %46, %44
  %43 = call i32 @cq_template_fmul_f64(i32 %39, i32 %39)    ; IR: %48 = fmul %44, %44  (lx*lx)
  %44 = call i32 @cq_template_fmul_f64(i32 %39, i32 %42)    ; IR: %49 = fmuladd(%44, %47, %48)  (lx)  [unfused product]
  %45 = call i32 @cq_template_fadd_f64(i32 %44, i32 %43)    ; IR: %49 = fmuladd(%44, %47, %48)  (lx)  [unfused sum]
  %46 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %32)    ; IR: %50 = fptrunc %39 to float
  %47 = call i32 @cq_template_fpext_f32_to_f64(i32 %46)    ; IR: %51 = fpext %50 to double  (hy)
  %48 = call i32 @cq_template_fsub_f64(i32 %32, i32 %47)    ; IR: %52 = fsub %39, %51  (ly)
  %49 = call i32 @cq_template_fmul_f64(i32 %47, i32 %47)    ; IR: %53 = fmul %51, %51  (hy*hy)
  %50 = call i32 @cq_template_fadd_f64(i32 %32, i32 %32)    ; IR: %54 = fadd %39, %39  (y + y)
  %51 = call i32 @cq_template_fsub_f64(i32 %50, i32 %48)    ; IR: %55 = fsub %54, %52
  %52 = call i32 @cq_template_fmul_f64(i32 %48, i32 %48)    ; IR: %56 = fmul %52, %52  (ly*ly)
  %53 = call i32 @cq_template_fmul_f64(i32 %48, i32 %51)    ; IR: %57 = fmuladd(%52, %55, %56)  (ly)  [unfused product]
  %54 = call i32 @cq_template_fadd_f64(i32 %53, i32 %52)    ; IR: %57 = fmuladd(%52, %55, %56)  (ly)  [unfused sum]
  %55 = call i32 @cq_template_fadd_f64(i32 %54, i32 %45)    ; IR: %58 = fadd %57, %49  (ly + lx)
  %56 = call i32 @cq_template_fadd_f64(i32 %49, i32 %55)    ; IR: %59 = fadd %53, %58  (+ hy)
  %57 = call i32 @cq_template_fadd_f64(i32 %40, i32 %56)    ; IR: %60 = fadd %45, %59  (+ hx)
  %58 = call i32 @cq_template_sqrt_f64(i32 %57)    ; IR: %61 = sqrt(%60)
  %59 = call i32 @cq_template_fmul_f64(i32 %36, i32 %58)    ; IR: %62 = fmul %41, %61  (z * sqrt)
  %60 = call i32 @cq_template_select_f64(i32 %23, i32 %24, i32 %59)    ; IR: %64 = phi [ %27, .. ], [ %62, .. ], [ %10, .. ], [ %11, .. ]: innermost select on %25 (x + y against the sqrt path)
  %61 = call i32 @cq_template_select_f64(i32 %21, i32 %11, i32 %60)    ; IR: %64 = phi: select on %22 (return x)
  %62 = call i32 @cq_template_select_f64(i32 %18, i32 %10, i32 %61)    ; IR: %64 = phi: select on %18 (return y)  [result rail]
  call void @cq_template_select_f64_unc(i32 %61, i32 %21, i32 %11, i32 %60)    ; IR: uncompute %64
  call void @cqrt_free(i32 %61)    ; IR: release the %64 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %60, i32 %23, i32 %24, i32 %59)    ; IR: uncompute %64
  call void @cqrt_free(i32 %60)    ; IR: release the %64 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %59, i32 %36, i32 %58)    ; IR: uncompute %62
  call void @cqrt_free(i32 %59)    ; IR: release the %62 rail (|0>)
  call void @cq_template_sqrt_f64_unc(i32 %58, i32 %57)    ; IR: uncompute %61
  call void @cqrt_free(i32 %58)    ; IR: release the %61 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %57, i32 %40, i32 %56)    ; IR: uncompute %60
  call void @cqrt_free(i32 %57)    ; IR: release the %60 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %56, i32 %49, i32 %55)    ; IR: uncompute %59
  call void @cqrt_free(i32 %56)    ; IR: release the %59 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %55, i32 %54, i32 %45)    ; IR: uncompute %58
  call void @cqrt_free(i32 %55)    ; IR: release the %58 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %54, i32 %53, i32 %52)    ; IR: uncompute %57  [sum]
  call void @cqrt_free(i32 %54)    ; IR: release the %57 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %53, i32 %48, i32 %51)    ; IR: uncompute %57  [product]
  call void @cqrt_free(i32 %53)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %52, i32 %48, i32 %48)    ; IR: uncompute %56
  call void @cqrt_free(i32 %52)    ; IR: release the %56 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %51, i32 %50, i32 %48)    ; IR: uncompute %55
  call void @cqrt_free(i32 %51)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %50, i32 %32, i32 %32)    ; IR: uncompute %54
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %49, i32 %47, i32 %47)    ; IR: uncompute %53
  call void @cqrt_free(i32 %49)    ; IR: release the %53 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %48, i32 %32, i32 %47)    ; IR: uncompute %52
  call void @cqrt_free(i32 %48)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %47, i32 %46)    ; IR: uncompute %51
  call void @cqrt_free(i32 %47)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %46, i32 %32)    ; IR: uncompute %50
  call void @cqrt_free(i32 %46)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %45, i32 %44, i32 %43)    ; IR: uncompute %49  [sum]
  call void @cqrt_free(i32 %45)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %44, i32 %39, i32 %42)    ; IR: uncompute %49  [product]
  call void @cqrt_free(i32 %44)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %43, i32 %39, i32 %39)    ; IR: uncompute %48
  call void @cqrt_free(i32 %43)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %42, i32 %41, i32 %39)    ; IR: uncompute %47
  call void @cqrt_free(i32 %42)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %41, i32 %34, i32 %34)    ; IR: uncompute %46
  call void @cqrt_free(i32 %41)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %40, i32 %38, i32 %38)    ; IR: uncompute %45
  call void @cqrt_free(i32 %40)    ; IR: release the %45 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %39, i32 %34, i32 %38)    ; IR: uncompute %44
  call void @cqrt_free(i32 %39)    ; IR: release the %44 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %38, i32 %37)    ; IR: uncompute %43
  call void @cqrt_free(i32 %38)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %37, i32 %34)    ; IR: uncompute %42
  call void @cqrt_free(i32 %37)    ; IR: release the %42 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %36, i32 %25, double 0x6BB0000000000000, i32 %35)    ; IR: uncompute %41
  call void @cqrt_free(i32 %36)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %35, i32 %28, double 0x1430000000000000, double 1.000000e+00)    ; IR: uncompute %41
  call void @cqrt_free(i32 %35)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %34, i32 %25, i32 %26, i32 %33)    ; IR: uncompute %40
  call void @cqrt_free(i32 %34)    ; IR: release the %40 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %28, i32 %29, i32 %11)    ; IR: uncompute %40
  call void @cqrt_free(i32 %33)    ; IR: release the %40 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %32, i32 %25, i32 %27, i32 %31)    ; IR: uncompute %39
  call void @cqrt_free(i32 %32)    ; IR: release the %39 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %31, i32 %28, i32 %30, i32 %10)    ; IR: uncompute %39
  call void @cqrt_free(i32 %31)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %30, i32 %10, double 0x6BB0000000000000)    ; IR: uncompute %37
  call void @cqrt_free(i32 %30)    ; IR: release the %37 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %29, i32 %11, double 0x6BB0000000000000)    ; IR: uncompute %36
  call void @cqrt_free(i32 %29)    ; IR: release the %36 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %28, i32 %15, i64 2580562586483294208)    ; IR: uncompute %34
  call void @cqrt_free(i32 %28)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %27, i32 %10, double 0x1430000000000000)    ; IR: uncompute %32
  call void @cqrt_free(i32 %27)    ; IR: release the %32 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %26, i32 %11, double 0x1430000000000000)    ; IR: uncompute %31
  call void @cqrt_free(i32 %26)    ; IR: release the %31 rail (|0>)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %25, i32 %12, i64 6908521828386340863)    ; IR: uncompute %29
  call void @cqrt_free(i32 %25)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %24, i32 %5, double %7)    ; IR: uncompute %27
  call void @cqrt_free(i32 %24)    ; IR: release the %27 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %23, i32 %22, i32 64)    ; IR: uncompute %25
  call void @cqrt_free(i32 %23)    ; IR: release the %25 rail (|0>)
  call void @cq_template_sub_i32_unc(i32 %22, i32 %14, i32 %17)    ; IR: uncompute %24
  call void @cqrt_free(i32 %22)    ; IR: release the %24 rail (|0>)
  call void @cqrt_or_i1(i32 %20, i32 %19, i32 %21)    ; IR: uncompute %22  [self-inverse]
  call void @cqrt_free(i32 %21)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %20, i32 %15, i64 0)    ; IR: uncompute %21
  call void @cqrt_free(i32 %20)    ; IR: release the %21 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %19, i32 %13, i64 2047)    ; IR: uncompute %20
  call void @cqrt_free(i32 %19)    ; IR: release the %20 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %18, i32 %16, i64 2047)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %17, i32 %16)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %16, i32 %15, i64 52)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %15, i32 %10)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %14, i32 %13)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %13, i32 %12, i64 52)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %11, i32 %9, double %7, i32 %5)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_f64_hl_unc(i32 %10, i32 %9, i32 %5, double %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %9, i32 %6, i64 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %63 = call double @cqrt_measure_f64(i32 %62)    ; IR: %65 = cq_measure_f64(%64)
  ret double %63    ; IR: ret double %65
}

define double @cabs_quantum_both(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_f64(double %2)    ; IR: %6 = cq_theta_f64(%2, %3)  [register im]
  call void @cqrt_ry_f64(i32 %6, double %3)    ; IR: %6 = cq_theta_f64(%2, %3)  [Ry]
  %7 = call i32 @cq_template_fabs_f64(i32 %5)    ; IR: %7 = fabs(re)
  %8 = call i32 @cq_template_bitcast_f64_to_i64(i32 %7)    ; IR: %8 = bitcast to i64  (ux.i, sign cleared)
  %9 = call i32 @cq_template_fabs_f64(i32 %6)    ; IR: %9 = fabs(im)
  %10 = call i32 @cq_template_bitcast_f64_to_i64(i32 %9)    ; IR: %10 = bitcast to i64  (uy.i)
  %11 = call i32 @cq_template_icmp_ult_i64(i32 %8, i32 %10)    ; IR: %11 = icmp ult %8, %10  (ux.i < uy.i: swap)
  %12 = call i32 @cq_template_select_f64(i32 %11, i32 %7, i32 %9)    ; IR: %12 = select %11, %7, %9  (the smaller magnitude: y after the swap)
  %13 = call i32 @cq_template_select_f64(i32 %11, i32 %9, i32 %7)    ; IR: %13 = select %11, %9, %7  (the larger magnitude: x after the swap)
  %14 = call i32 @cq_template_bitcast_f64_to_i64(i32 %13)    ; IR: %14 = bitcast to i64  (ux.i)
  %15 = call i32 @cq_template_lshr_i64_hl(i32 %14, i64 52)    ; IR: %15 = lshr %14, 52  (ex)
  %16 = call i32 @cq_template_trunc_i64_to_i32(i32 %15)    ; IR: %16 = trunc nuw nsw %15 to i32
  %17 = call i32 @cq_template_bitcast_f64_to_i64(i32 %12)    ; IR: %17 = bitcast to i64  (uy.i)
  %18 = call i32 @cq_template_lshr_i64_hl(i32 %17, i64 52)    ; IR: %18 = lshr %17, 52  (ey)
  %19 = call i32 @cq_template_trunc_i64_to_i32(i32 %18)    ; IR: %19 = trunc nuw nsw %18 to i32
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %18, i64 2047)    ; IR: %20 = icmp eq %18, 2047  (ey == 0x7ff)  [br -> exit with %12]
  %21 = call i32 @cq_template_icmp_eq_i64_hl(i32 %15, i64 2047)    ; IR: %22 = icmp eq %15, 2047  (ex == 0x7ff)
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 0)    ; IR: %23 = icmp eq %17, 0  (uy.i == 0)
  %23 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %24 = or i1 %23, %22  [br -> exit with %13]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %22, i32 %21, i32 %23)    ; IR: %24 = or i1 %23, %22  [br -> exit with %13]
  %24 = call i32 @cq_template_sub_i32(i32 %16, i32 %19)    ; IR: %26 = sub nsw %16, %19  (ex - ey)
  %25 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %24, i32 64)    ; IR: %27 = icmp sgt %26, 64  [br -> block %28: x + y]
  %26 = call i32 @cq_template_fadd_f64(i32 %9, i32 %7)    ; IR: %29 = fadd %9, %7  (x + y)
  %27 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %14, i64 6908521828386340863)    ; IR: %31 = icmp ugt %14, 0x5FDFFFFFFFFFFFFF  (ex > 0x3ff + 510)
  %28 = call i32 @cq_template_fmul_f64_hl(i32 %13, double 0x1430000000000000)    ; IR: %33 = fmul %13, 0x1p-700
  %29 = call i32 @cq_template_fmul_f64_hl(i32 %12, double 0x1430000000000000)    ; IR: %34 = fmul %12, 0x1p-700
  %30 = call i32 @cq_template_icmp_ult_i64_hl(i32 %17, i64 2580562586483294208)    ; IR: %36 = icmp ult %17, 0x23D0000000000000  (ey < 0x3ff - 450)
  %31 = call i32 @cq_template_fmul_f64_hl(i32 %13, double 0x6BB0000000000000)    ; IR: %38 = fmul %13, 0x1p700
  %32 = call i32 @cq_template_fmul_f64_hl(i32 %12, double 0x6BB0000000000000)    ; IR: %39 = fmul %12, 0x1p700
  %33 = call i32 @cq_template_select_f64(i32 %30, i32 %32, i32 %12)    ; IR: %41 = phi [ %34, .. ], [ %39, .. ], [ %12, .. ]: inner select on %36 (the outer select fixes the %31 case)
  %34 = call i32 @cq_template_select_f64(i32 %27, i32 %29, i32 %33)    ; IR: %41 = phi (y scaled): outer select on %31
  %35 = call i32 @cq_template_select_f64(i32 %30, i32 %31, i32 %13)    ; IR: %42 = phi [ %33, .. ], [ %38, .. ], [ %13, .. ]: inner select on %36
  %36 = call i32 @cq_template_select_f64(i32 %27, i32 %28, i32 %35)    ; IR: %42 = phi (x scaled): outer select on %31
  %37 = call i32 @cq_template_select_f64_ll(i32 %30, double 0x1430000000000000, double 1.000000e+00)    ; IR: %43 = phi [ 0x1p700, .. ], [ 0x1p-700, .. ], [ 1.0, .. ]: inner select on %36
  %38 = call i32 @cq_template_select_f64_lh(i32 %27, double 0x6BB0000000000000, i32 %37)    ; IR: %43 = phi (z): outer select on %31
  %39 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %36)    ; IR: %44 = fptrunc %42 to float
  %40 = call i32 @cq_template_fpext_f32_to_f64(i32 %39)    ; IR: %45 = fpext %44 to double  (hx)
  %41 = call i32 @cq_template_fsub_f64(i32 %36, i32 %40)    ; IR: %46 = fsub %42, %45  (lx)
  %42 = call i32 @cq_template_fmul_f64(i32 %40, i32 %40)    ; IR: %47 = fmul %45, %45  (hx*hx)
  %43 = call i32 @cq_template_fadd_f64(i32 %36, i32 %36)    ; IR: %48 = fadd %42, %42  (x + x)
  %44 = call i32 @cq_template_fsub_f64(i32 %43, i32 %41)    ; IR: %49 = fsub %48, %46
  %45 = call i32 @cq_template_fmul_f64(i32 %41, i32 %41)    ; IR: %50 = fmul %46, %46  (lx*lx)
  %46 = call i32 @cq_template_fmul_f64(i32 %41, i32 %44)    ; IR: %51 = fmuladd(%46, %49, %50)  (lx)  [unfused product]
  %47 = call i32 @cq_template_fadd_f64(i32 %46, i32 %45)    ; IR: %51 = fmuladd(%46, %49, %50)  (lx)  [unfused sum]
  %48 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %34)    ; IR: %52 = fptrunc %41 to float
  %49 = call i32 @cq_template_fpext_f32_to_f64(i32 %48)    ; IR: %53 = fpext %52 to double  (hy)
  %50 = call i32 @cq_template_fsub_f64(i32 %34, i32 %49)    ; IR: %54 = fsub %41, %53  (ly)
  %51 = call i32 @cq_template_fmul_f64(i32 %49, i32 %49)    ; IR: %55 = fmul %53, %53  (hy*hy)
  %52 = call i32 @cq_template_fadd_f64(i32 %34, i32 %34)    ; IR: %56 = fadd %41, %41  (y + y)
  %53 = call i32 @cq_template_fsub_f64(i32 %52, i32 %50)    ; IR: %57 = fsub %56, %54
  %54 = call i32 @cq_template_fmul_f64(i32 %50, i32 %50)    ; IR: %58 = fmul %54, %54  (ly*ly)
  %55 = call i32 @cq_template_fmul_f64(i32 %50, i32 %53)    ; IR: %59 = fmuladd(%54, %57, %58)  (ly)  [unfused product]
  %56 = call i32 @cq_template_fadd_f64(i32 %55, i32 %54)    ; IR: %59 = fmuladd(%54, %57, %58)  (ly)  [unfused sum]
  %57 = call i32 @cq_template_fadd_f64(i32 %56, i32 %47)    ; IR: %60 = fadd %59, %51  (ly + lx)
  %58 = call i32 @cq_template_fadd_f64(i32 %51, i32 %57)    ; IR: %61 = fadd %55, %60  (+ hy)
  %59 = call i32 @cq_template_fadd_f64(i32 %42, i32 %58)    ; IR: %62 = fadd %47, %61  (+ hx)
  %60 = call i32 @cq_template_sqrt_f64(i32 %59)    ; IR: %63 = sqrt(%62)
  %61 = call i32 @cq_template_fmul_f64(i32 %38, i32 %60)    ; IR: %64 = fmul %43, %63  (z * sqrt)
  %62 = call i32 @cq_template_select_f64(i32 %25, i32 %26, i32 %61)    ; IR: %66 = phi [ %29, .. ], [ %64, .. ], [ %12, .. ], [ %13, .. ]: innermost select on %27 (x + y against the sqrt path)
  %63 = call i32 @cq_template_select_f64(i32 %23, i32 %13, i32 %62)    ; IR: %66 = phi: select on %24 (return x)
  %64 = call i32 @cq_template_select_f64(i32 %20, i32 %12, i32 %63)    ; IR: %66 = phi: select on %20 (return y)  [result rail]
  call void @cq_template_select_f64_unc(i32 %63, i32 %23, i32 %13, i32 %62)    ; IR: uncompute %66
  call void @cqrt_free(i32 %63)    ; IR: release the %66 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %62, i32 %25, i32 %26, i32 %61)    ; IR: uncompute %66
  call void @cqrt_free(i32 %62)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %61, i32 %38, i32 %60)    ; IR: uncompute %64
  call void @cqrt_free(i32 %61)    ; IR: release the %64 rail (|0>)
  call void @cq_template_sqrt_f64_unc(i32 %60, i32 %59)    ; IR: uncompute %63
  call void @cqrt_free(i32 %60)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %59, i32 %42, i32 %58)    ; IR: uncompute %62
  call void @cqrt_free(i32 %59)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %58, i32 %51, i32 %57)    ; IR: uncompute %61
  call void @cqrt_free(i32 %58)    ; IR: release the %61 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %57, i32 %56, i32 %47)    ; IR: uncompute %60
  call void @cqrt_free(i32 %57)    ; IR: release the %60 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %56, i32 %55, i32 %54)    ; IR: uncompute %59  [sum]
  call void @cqrt_free(i32 %56)    ; IR: release the %59 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %55, i32 %50, i32 %53)    ; IR: uncompute %59  [product]
  call void @cqrt_free(i32 %55)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %54, i32 %50, i32 %50)    ; IR: uncompute %58
  call void @cqrt_free(i32 %54)    ; IR: release the %58 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %53, i32 %52, i32 %50)    ; IR: uncompute %57
  call void @cqrt_free(i32 %53)    ; IR: release the %57 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %52, i32 %34, i32 %34)    ; IR: uncompute %56
  call void @cqrt_free(i32 %52)    ; IR: release the %56 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %51, i32 %49, i32 %49)    ; IR: uncompute %55
  call void @cqrt_free(i32 %51)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %50, i32 %34, i32 %49)    ; IR: uncompute %54
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %49, i32 %48)    ; IR: uncompute %53
  call void @cqrt_free(i32 %49)    ; IR: release the %53 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %48, i32 %34)    ; IR: uncompute %52
  call void @cqrt_free(i32 %48)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %47, i32 %46, i32 %45)    ; IR: uncompute %51  [sum]
  call void @cqrt_free(i32 %47)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %46, i32 %41, i32 %44)    ; IR: uncompute %51  [product]
  call void @cqrt_free(i32 %46)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %45, i32 %41, i32 %41)    ; IR: uncompute %50
  call void @cqrt_free(i32 %45)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %44, i32 %43, i32 %41)    ; IR: uncompute %49
  call void @cqrt_free(i32 %44)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %43, i32 %36, i32 %36)    ; IR: uncompute %48
  call void @cqrt_free(i32 %43)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %42, i32 %40, i32 %40)    ; IR: uncompute %47
  call void @cqrt_free(i32 %42)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %41, i32 %36, i32 %40)    ; IR: uncompute %46
  call void @cqrt_free(i32 %41)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %40, i32 %39)    ; IR: uncompute %45
  call void @cqrt_free(i32 %40)    ; IR: release the %45 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %39, i32 %36)    ; IR: uncompute %44
  call void @cqrt_free(i32 %39)    ; IR: release the %44 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %38, i32 %27, double 0x6BB0000000000000, i32 %37)    ; IR: uncompute %43
  call void @cqrt_free(i32 %38)    ; IR: release the %43 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %37, i32 %30, double 0x1430000000000000, double 1.000000e+00)    ; IR: uncompute %43
  call void @cqrt_free(i32 %37)    ; IR: release the %43 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %36, i32 %27, i32 %28, i32 %35)    ; IR: uncompute %42
  call void @cqrt_free(i32 %36)    ; IR: release the %42 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %35, i32 %30, i32 %31, i32 %13)    ; IR: uncompute %42
  call void @cqrt_free(i32 %35)    ; IR: release the %42 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %34, i32 %27, i32 %29, i32 %33)    ; IR: uncompute %41
  call void @cqrt_free(i32 %34)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %30, i32 %32, i32 %12)    ; IR: uncompute %41
  call void @cqrt_free(i32 %33)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %32, i32 %12, double 0x6BB0000000000000)    ; IR: uncompute %39
  call void @cqrt_free(i32 %32)    ; IR: release the %39 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %31, i32 %13, double 0x6BB0000000000000)    ; IR: uncompute %38
  call void @cqrt_free(i32 %31)    ; IR: release the %38 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %30, i32 %17, i64 2580562586483294208)    ; IR: uncompute %36
  call void @cqrt_free(i32 %30)    ; IR: release the %36 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %29, i32 %12, double 0x1430000000000000)    ; IR: uncompute %34
  call void @cqrt_free(i32 %29)    ; IR: release the %34 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %28, i32 %13, double 0x1430000000000000)    ; IR: uncompute %33
  call void @cqrt_free(i32 %28)    ; IR: release the %33 rail (|0>)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %27, i32 %14, i64 6908521828386340863)    ; IR: uncompute %31
  call void @cqrt_free(i32 %27)    ; IR: release the %31 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %26, i32 %9, i32 %7)    ; IR: uncompute %29
  call void @cqrt_free(i32 %26)    ; IR: release the %29 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %25, i32 %24, i32 64)    ; IR: uncompute %27
  call void @cqrt_free(i32 %25)    ; IR: release the %27 rail (|0>)
  call void @cq_template_sub_i32_unc(i32 %24, i32 %16, i32 %19)    ; IR: uncompute %26
  call void @cqrt_free(i32 %24)    ; IR: release the %26 rail (|0>)
  call void @cqrt_or_i1(i32 %22, i32 %21, i32 %23)    ; IR: uncompute %24  [self-inverse]
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %22, i32 %17, i64 0)    ; IR: uncompute %23
  call void @cqrt_free(i32 %22)    ; IR: release the %23 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %21, i32 %15, i64 2047)    ; IR: uncompute %22
  call void @cqrt_free(i32 %21)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %20, i32 %18, i64 2047)    ; IR: uncompute %20
  call void @cqrt_free(i32 %20)    ; IR: release the %20 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %19, i32 %18)    ; IR: uncompute %19
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %18, i32 %17, i64 52)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %17, i32 %12)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %16, i32 %15)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %15, i32 %14, i64 52)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %13, i32 %11, i32 %9, i32 %7)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %12, i32 %11, i32 %7, i32 %9)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_ult_i64_unc(i32 %11, i32 %8, i32 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %9, i32 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %7, i32 %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %65 = call double @cqrt_measure_f64(i32 %64)    ; IR: %67 = cq_measure_f64(%66)
  ret double %65    ; IR: ret double %67
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare double @llvm.fabs.f64(double)
declare i32 @cq_template_icmp_ult_i64_hl(i32, i64)
declare void @cq_template_icmp_ult_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_f64_hl(i32, i32, double)
declare void @cq_template_select_f64_hl_unc(i32, i32, i32, double)
declare i32 @cq_template_select_f64_lh(i32, double, i32)
declare void @cq_template_select_f64_lh_unc(i32, i32, double, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare void @cq_template_icmp_ugt_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare i32 @cq_template_fptrunc_f64_to_f32(i32)
declare void @cq_template_fptrunc_f64_to_f32_unc(i32, i32)
declare i32 @cq_template_fpext_f32_to_f64(i32)
declare void @cq_template_fpext_f32_to_f64_unc(i32, i32)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare i32 @cq_template_sqrt_f64(i32)
declare void @cq_template_sqrt_f64_unc(i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_icmp_ult_i64(i32, i32)
declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
