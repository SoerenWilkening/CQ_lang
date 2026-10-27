; HAND-WRITTEN. Rules: 26, 18 (the cabs and hypot bodies are inlined by clang -O1, so they lower in the entries), 20, 3, 4, 5, 8, 9 (and 1).
; Checked: cabs_complex_h_re: cabs(re + im*I) = hypot(re, im) (measured, %62 -> %63); cabs_complex_h_both: the same with
; both parts quantum (measured, %64 -> %65).
; Clean: every flag, select and arithmetic rail of both entries, all freed before the measurement.
; Kept: the registers (re %4; re %5 and im %6) and the two measured result rails (%62, %64).
; Rotations: (Ry, re, tr, 1) in cabs_complex_h_re; (Ry, re, tr, 1), (Ry, im, ti, 1) in cabs_complex_h_both.
; cabs through the complex.h entry point: the .c defines cabs(z) = hypot_musl(creal z, cimag z) with musl's hypot body.
; clang -O1 inlines the static hypot_musl into cabs and then inlines cabs (its `double complex` parameter already split
; into two scalar doubles by the SysV ABI) into both entries, so the O1.ll holds NO call: there is nothing to lift, no
; clone __cq_q_cabs_10/_11 or __cq_q_hypot_musl_10/_11 can appear (rule 18 lifts a CALL with a quantum argument), and
; every body is shown because it is in the entries. The exported `cabs` itself has no caller and no quantum value
; reaches it: it is a classical function and passes through unchanged (its instructions are annotated `(classical)`);
; nothing of it is quantum, so no rail, flag or gate belongs to it. What differs from 172 is the Annex G prelude of z =
; re + im*I (rule 26): the real part is `im * 0 + re`, a classical fmul and one fadd_f64_hl in the first entry, a
; quantum fmul_f64_hl and a two-handle fadd in the second; cimag(z) is the im value itself. From there the lowering is
; 172's: the union views are bitcast / lshr / trunc templates (rule 20), the swap is one icmp flag and two selects, the
; if-ladder returns are nested selects on the local flags (%18 / %22 / %25 in the first entry: y, x, x + y, innermost
; the sqrt path), the 2^+-700 scaling phis are two nested selects, the split through fptrunc / fpext and the two
; llvm.fmuladd sums (lx, ly) UNFUSED (§2, cf. 14): fmul into a product rail, then fadd, the product uncomputed after the
; sum. Everything but the result rail is uncomputed LIFO and freed before the measurement.
source_filename = "cabs_complex_h.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @cabs(double noundef %0, double noundef %1) {
  %3 = tail call double @llvm.fabs.f64(double %0)    ; IR: %3 = fabs(creal z)  (classical: no quantum value reaches cabs; the function passes through)
  %4 = bitcast double %3 to i64    ; IR: %4  (classical)
  %5 = tail call double @llvm.fabs.f64(double %1)    ; IR: %5  (classical)
  %6 = bitcast double %5 to i64    ; IR: %6  (classical)
  %7 = icmp ult i64 %4, %6    ; IR: %7  (classical)
  %8 = select i1 %7, double %3, double %5    ; IR: %8  (classical)
  %9 = select i1 %7, double %5, double %3    ; IR: %9  (classical)
  %10 = bitcast double %9 to i64    ; IR: %10  (classical)
  %11 = lshr i64 %10, 52    ; IR: %11  (classical)
  %12 = trunc nuw nsw i64 %11 to i32    ; IR: %12  (classical)
  %13 = bitcast double %8 to i64    ; IR: %13  (classical)
  %14 = lshr i64 %13, 52    ; IR: %14  (classical)
  %15 = trunc nuw nsw i64 %14 to i32    ; IR: %15  (classical)
  %16 = icmp eq i64 %14, 2047    ; IR: %16  (classical)
  br i1 %16, label %61, label %17    ; IR: br %16  (classical)

17:
  %18 = icmp eq i64 %11, 2047    ; IR: %18  (classical)
  %19 = icmp eq i64 %13, 0    ; IR: %19  (classical)
  %20 = or i1 %19, %18    ; IR: %20  (classical)
  br i1 %20, label %61, label %21    ; IR: br %20  (classical)

21:
  %22 = sub nsw i32 %12, %15    ; IR: %22  (classical)
  %23 = icmp sgt i32 %22, 64    ; IR: %23  (classical)
  br i1 %23, label %24, label %26    ; IR: br %23  (classical)

24:
  %25 = fadd double %3, %5    ; IR: %25  (classical)
  br label %61    ; IR: br  (classical)

26:
  %27 = icmp ugt i64 %10, 6908521828386340863    ; IR: %27  (classical)
  br i1 %27, label %28, label %31    ; IR: br %27  (classical)

28:
  %29 = fmul double %9, 0x1430000000000000    ; IR: %29  (classical)
  %30 = fmul double %8, 0x1430000000000000    ; IR: %30  (classical)
  br label %36    ; IR: br  (classical)

31:
  %32 = icmp ult i64 %13, 2580562586483294208    ; IR: %32  (classical)
  br i1 %32, label %33, label %36    ; IR: br %32  (classical)

33:
  %34 = fmul double %9, 0x6BB0000000000000    ; IR: %34  (classical)
  %35 = fmul double %8, 0x6BB0000000000000    ; IR: %35  (classical)
  br label %36    ; IR: br  (classical)

36:
  %37 = phi double [ %30, %28 ], [ %35, %33 ], [ %8, %31 ]    ; IR: %37  (classical)
  %38 = phi double [ %29, %28 ], [ %34, %33 ], [ %9, %31 ]    ; IR: %38  (classical)
  %39 = phi double [ 0x6BB0000000000000, %28 ], [ 0x1430000000000000, %33 ], [ 1.000000e+00, %31 ]    ; IR: %39  (classical)
  %40 = fptrunc double %38 to float    ; IR: %40  (classical)
  %41 = fpext float %40 to double    ; IR: %41  (classical)
  %42 = fsub double %38, %41    ; IR: %42  (classical)
  %43 = fmul double %41, %41    ; IR: %43  (classical)
  %44 = fadd double %38, %38    ; IR: %44  (classical)
  %45 = fsub double %44, %42    ; IR: %45  (classical)
  %46 = fmul double %42, %42    ; IR: %46  (classical)
  %47 = tail call double @llvm.fmuladd.f64(double %42, double %45, double %46)    ; IR: %47  (classical)
  %48 = fptrunc double %37 to float    ; IR: %48  (classical)
  %49 = fpext float %48 to double    ; IR: %49  (classical)
  %50 = fsub double %37, %49    ; IR: %50  (classical)
  %51 = fmul double %49, %49    ; IR: %51  (classical)
  %52 = fadd double %37, %37    ; IR: %52  (classical)
  %53 = fsub double %52, %50    ; IR: %53  (classical)
  %54 = fmul double %50, %50    ; IR: %54  (classical)
  %55 = tail call double @llvm.fmuladd.f64(double %50, double %53, double %54)    ; IR: %55  (classical)
  %56 = fadd double %55, %47    ; IR: %56  (classical)
  %57 = fadd double %51, %56    ; IR: %57  (classical)
  %58 = fadd double %43, %57    ; IR: %58  (classical)
  %59 = tail call double @llvm.sqrt.f64(double %58)    ; IR: %59  (classical)
  %60 = fmul double %39, %59    ; IR: %60  (classical)
  br label %61    ; IR: br  (classical)

61:
  %62 = phi double [ %25, %24 ], [ %60, %36 ], [ %8, %2 ], [ %9, %17 ]    ; IR: %62  (classical)
  ret double %62    ; IR: ret %62  (classical)
}

define double @cabs_complex_h_re(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = fmul double %2, 0.000000e+00    ; IR: %5 = fmul %2, 0  (im * I: real part im*0)  (classical)
  %6 = call i32 @cq_template_fadd_f64_hl(i32 %4, double %5)    ; IR: %6 = fadd %5, %4  (creal(z) = re + im*0)  (commutative, quantum operand first)
  %7 = call i32 @cq_template_fabs_f64(i32 %6)    ; IR: %7 = fabs(re)
  %8 = call i32 @cq_template_bitcast_f64_to_i64(i32 %7)    ; IR: %8 = bitcast to i64  (ux.i, sign cleared)
  %9 = tail call double @llvm.fabs.f64(double %2)    ; IR: %9 = fabs(im)  (classical)
  %10 = bitcast double %9 to i64    ; IR: %10 = bitcast to i64  (uy.i)  (classical)
  %11 = call i32 @cq_template_icmp_ult_i64_hl(i32 %8, i64 %10)    ; IR: %11 = icmp ult %8, %10  (ux.i < uy.i: swap)
  %12 = call i32 @cq_template_select_f64_hl(i32 %11, i32 %7, double %9)    ; IR: %12 = select %11, %7, %9  (the smaller magnitude: y after the swap)
  %13 = call i32 @cq_template_select_f64_lh(i32 %11, double %9, i32 %7)    ; IR: %13 = select %11, %9, %7  (the larger magnitude: x after the swap)
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
  %26 = call i32 @cq_template_fadd_f64_hl(i32 %7, double %9)    ; IR: %29 = fadd %9, %7  (x + y)  (commutative, quantum operand first)
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
  call void @cq_template_fadd_f64_hl_unc(i32 %26, i32 %7, double %9)    ; IR: uncompute %29
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
  call void @cq_template_select_f64_lh_unc(i32 %13, i32 %11, double %9, i32 %7)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_select_f64_hl_unc(i32 %12, i32 %11, i32 %7, double %9)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %11, i32 %8, i64 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %6, i32 %4, double %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %65 = call double @cqrt_measure_f64(i32 %64)    ; IR: %67 = cq_measure_f64(%66)
  ret double %65    ; IR: ret %67
}

define double @cabs_complex_h_both(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register re]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_f64(double %2)    ; IR: %6 = cq_theta_f64(%2, %3)  [register im]
  call void @cqrt_ry_f64(i32 %6, double %3)    ; IR: %6 = cq_theta_f64(%2, %3)  [Ry]
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %6, double 0.000000e+00)    ; IR: %7 = fmul %6, 0  (im * I: real part im*0, quantum by rule 3)
  %8 = call i32 @cq_template_fadd_f64(i32 %5, i32 %7)    ; IR: %8 = fadd %5, %7  (creal(z) = re + im*0)
  %9 = call i32 @cq_template_fabs_f64(i32 %8)    ; IR: %9 = fabs(re)
  %10 = call i32 @cq_template_bitcast_f64_to_i64(i32 %9)    ; IR: %10 = bitcast to i64  (ux.i, sign cleared)
  %11 = call i32 @cq_template_fabs_f64(i32 %6)    ; IR: %11 = fabs(im)
  %12 = call i32 @cq_template_bitcast_f64_to_i64(i32 %11)    ; IR: %12 = bitcast to i64  (uy.i, sign cleared)
  %13 = call i32 @cq_template_icmp_ult_i64(i32 %10, i32 %12)    ; IR: %13 = icmp ult %10, %12  (ux.i < uy.i: swap)
  %14 = call i32 @cq_template_select_f64(i32 %13, i32 %9, i32 %11)    ; IR: %14 = select %13, %9, %11  (the smaller magnitude: y after the swap)
  %15 = call i32 @cq_template_select_f64(i32 %13, i32 %11, i32 %9)    ; IR: %15 = select %13, %11, %9  (the larger magnitude: x after the swap)
  %16 = call i32 @cq_template_bitcast_f64_to_i64(i32 %15)    ; IR: %16 = bitcast to i64  (ux.i)
  %17 = call i32 @cq_template_lshr_i64_hl(i32 %16, i64 52)    ; IR: %17 = lshr %16, 52  (ex)
  %18 = call i32 @cq_template_trunc_i64_to_i32(i32 %17)    ; IR: %18 = trunc nuw nsw %17 to i32
  %19 = call i32 @cq_template_bitcast_f64_to_i64(i32 %14)    ; IR: %19 = bitcast to i64  (uy.i)
  %20 = call i32 @cq_template_lshr_i64_hl(i32 %19, i64 52)    ; IR: %20 = lshr %19, 52  (ey)
  %21 = call i32 @cq_template_trunc_i64_to_i32(i32 %20)    ; IR: %21 = trunc nuw nsw %20 to i32
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %20, i64 2047)    ; IR: %22 = icmp eq %20, 2047  (ey == 0x7ff)  [br -> exit with %14]
  %23 = call i32 @cq_template_icmp_eq_i64_hl(i32 %17, i64 2047)    ; IR: %24 = icmp eq %17, 2047  (ex == 0x7ff)
  %24 = call i32 @cq_template_icmp_eq_i64_hl(i32 %19, i64 0)    ; IR: %25 = icmp eq %19, 0  (uy.i == 0)
  %25 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %26 = or i1 %25, %24  [br -> exit with %15]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %24, i32 %23, i32 %25)    ; IR: %26 = or i1 %25, %24  [br -> exit with %15]
  %26 = call i32 @cq_template_sub_i32(i32 %18, i32 %21)    ; IR: %28 = sub nsw %18, %21  (ex - ey)
  %27 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %26, i32 64)    ; IR: %29 = icmp sgt %28, 64  [br -> block %30: x + y]
  %28 = call i32 @cq_template_fadd_f64(i32 %11, i32 %9)    ; IR: %31 = fadd %11, %9  (x + y)
  %29 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %16, i64 6908521828386340863)    ; IR: %33 = icmp ugt %16, 0x5FDFFFFFFFFFFFFF  (ex > 0x3ff + 510)
  %30 = call i32 @cq_template_fmul_f64_hl(i32 %15, double 0x1430000000000000)    ; IR: %35 = fmul %15, 0x1p-700
  %31 = call i32 @cq_template_fmul_f64_hl(i32 %14, double 0x1430000000000000)    ; IR: %36 = fmul %14, 0x1p-700
  %32 = call i32 @cq_template_icmp_ult_i64_hl(i32 %19, i64 2580562586483294208)    ; IR: %38 = icmp ult %19, 0x23D0000000000000  (ey < 0x3ff - 450)
  %33 = call i32 @cq_template_fmul_f64_hl(i32 %15, double 0x6BB0000000000000)    ; IR: %40 = fmul %15, 0x1p700
  %34 = call i32 @cq_template_fmul_f64_hl(i32 %14, double 0x6BB0000000000000)    ; IR: %41 = fmul %14, 0x1p700
  %35 = call i32 @cq_template_select_f64(i32 %32, i32 %34, i32 %14)    ; IR: %43 = phi [ %36, .. ], [ %41, .. ], [ %14, .. ]: inner select on %38 (the outer select fixes the %33 case)
  %36 = call i32 @cq_template_select_f64(i32 %29, i32 %31, i32 %35)    ; IR: %43 = phi (y scaled): outer select on %33
  %37 = call i32 @cq_template_select_f64(i32 %32, i32 %33, i32 %15)    ; IR: %44 = phi [ %35, .. ], [ %40, .. ], [ %15, .. ]: inner select on %38
  %38 = call i32 @cq_template_select_f64(i32 %29, i32 %30, i32 %37)    ; IR: %44 = phi (x scaled): outer select on %33
  %39 = call i32 @cq_template_select_f64_ll(i32 %32, double 0x1430000000000000, double 1.000000e+00)    ; IR: %45 = phi [ 0x1p700, .. ], [ 0x1p-700, .. ], [ 1.0, .. ]: inner select on %38
  %40 = call i32 @cq_template_select_f64_lh(i32 %29, double 0x6BB0000000000000, i32 %39)    ; IR: %45 = phi (z): outer select on %33
  %41 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %38)    ; IR: %46 = fptrunc %44 to float
  %42 = call i32 @cq_template_fpext_f32_to_f64(i32 %41)    ; IR: %47 = fpext %46 to double  (hx)
  %43 = call i32 @cq_template_fsub_f64(i32 %38, i32 %42)    ; IR: %48 = fsub %44, %47  (lx)
  %44 = call i32 @cq_template_fmul_f64(i32 %42, i32 %42)    ; IR: %49 = fmul %47, %47  (hx*hx)
  %45 = call i32 @cq_template_fadd_f64(i32 %38, i32 %38)    ; IR: %50 = fadd %44, %44  (x + x)
  %46 = call i32 @cq_template_fsub_f64(i32 %45, i32 %43)    ; IR: %51 = fsub %50, %48
  %47 = call i32 @cq_template_fmul_f64(i32 %43, i32 %43)    ; IR: %52 = fmul %48, %48  (lx*lx)
  %48 = call i32 @cq_template_fmul_f64(i32 %43, i32 %46)    ; IR: %53 = fmuladd(%48, %51, %52)  (lx)  [unfused product]
  %49 = call i32 @cq_template_fadd_f64(i32 %48, i32 %47)    ; IR: %53 = fmuladd(%48, %51, %52)  (lx)  [unfused sum]
  %50 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %36)    ; IR: %54 = fptrunc %43 to float
  %51 = call i32 @cq_template_fpext_f32_to_f64(i32 %50)    ; IR: %55 = fpext %54 to double  (hy)
  %52 = call i32 @cq_template_fsub_f64(i32 %36, i32 %51)    ; IR: %56 = fsub %43, %55  (ly)
  %53 = call i32 @cq_template_fmul_f64(i32 %51, i32 %51)    ; IR: %57 = fmul %55, %55  (hy*hy)
  %54 = call i32 @cq_template_fadd_f64(i32 %36, i32 %36)    ; IR: %58 = fadd %43, %43  (y + y)
  %55 = call i32 @cq_template_fsub_f64(i32 %54, i32 %52)    ; IR: %59 = fsub %58, %56
  %56 = call i32 @cq_template_fmul_f64(i32 %52, i32 %52)    ; IR: %60 = fmul %56, %56  (ly*ly)
  %57 = call i32 @cq_template_fmul_f64(i32 %52, i32 %55)    ; IR: %61 = fmuladd(%56, %59, %60)  (ly)  [unfused product]
  %58 = call i32 @cq_template_fadd_f64(i32 %57, i32 %56)    ; IR: %61 = fmuladd(%56, %59, %60)  (ly)  [unfused sum]
  %59 = call i32 @cq_template_fadd_f64(i32 %58, i32 %49)    ; IR: %62 = fadd %61, %53  (ly + lx)
  %60 = call i32 @cq_template_fadd_f64(i32 %53, i32 %59)    ; IR: %63 = fadd %57, %62  (+ hy)
  %61 = call i32 @cq_template_fadd_f64(i32 %44, i32 %60)    ; IR: %64 = fadd %49, %63  (+ hx)
  %62 = call i32 @cq_template_sqrt_f64(i32 %61)    ; IR: %65 = sqrt(%64)
  %63 = call i32 @cq_template_fmul_f64(i32 %40, i32 %62)    ; IR: %66 = fmul %45, %65  (z * sqrt)
  %64 = call i32 @cq_template_select_f64(i32 %27, i32 %28, i32 %63)    ; IR: %68 = phi [ %31, .. ], [ %66, .. ], [ %14, .. ], [ %15, .. ]: innermost select on %29 (x + y against the sqrt path)
  %65 = call i32 @cq_template_select_f64(i32 %25, i32 %15, i32 %64)    ; IR: %68 = phi: select on %26 (return x)
  %66 = call i32 @cq_template_select_f64(i32 %22, i32 %14, i32 %65)    ; IR: %68 = phi: select on %22 (return y)  [result rail]
  call void @cq_template_select_f64_unc(i32 %65, i32 %25, i32 %15, i32 %64)    ; IR: uncompute %68
  call void @cqrt_free(i32 %65)    ; IR: release the %68 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %64, i32 %27, i32 %28, i32 %63)    ; IR: uncompute %68
  call void @cqrt_free(i32 %64)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %63, i32 %40, i32 %62)    ; IR: uncompute %66
  call void @cqrt_free(i32 %63)    ; IR: release the %66 rail (|0>)
  call void @cq_template_sqrt_f64_unc(i32 %62, i32 %61)    ; IR: uncompute %65
  call void @cqrt_free(i32 %62)    ; IR: release the %65 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %61, i32 %44, i32 %60)    ; IR: uncompute %64
  call void @cqrt_free(i32 %61)    ; IR: release the %64 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %60, i32 %53, i32 %59)    ; IR: uncompute %63
  call void @cqrt_free(i32 %60)    ; IR: release the %63 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %59, i32 %58, i32 %49)    ; IR: uncompute %62
  call void @cqrt_free(i32 %59)    ; IR: release the %62 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %58, i32 %57, i32 %56)    ; IR: uncompute %61  [sum]
  call void @cqrt_free(i32 %58)    ; IR: release the %61 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %57, i32 %52, i32 %55)    ; IR: uncompute %61  [product]
  call void @cqrt_free(i32 %57)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %56, i32 %52, i32 %52)    ; IR: uncompute %60
  call void @cqrt_free(i32 %56)    ; IR: release the %60 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %55, i32 %54, i32 %52)    ; IR: uncompute %59
  call void @cqrt_free(i32 %55)    ; IR: release the %59 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %54, i32 %36, i32 %36)    ; IR: uncompute %58
  call void @cqrt_free(i32 %54)    ; IR: release the %58 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %53, i32 %51, i32 %51)    ; IR: uncompute %57
  call void @cqrt_free(i32 %53)    ; IR: release the %57 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %52, i32 %36, i32 %51)    ; IR: uncompute %56
  call void @cqrt_free(i32 %52)    ; IR: release the %56 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %51, i32 %50)    ; IR: uncompute %55
  call void @cqrt_free(i32 %51)    ; IR: release the %55 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %50, i32 %36)    ; IR: uncompute %54
  call void @cqrt_free(i32 %50)    ; IR: release the %54 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %49, i32 %48, i32 %47)    ; IR: uncompute %53  [sum]
  call void @cqrt_free(i32 %49)    ; IR: release the %53 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %48, i32 %43, i32 %46)    ; IR: uncompute %53  [product]
  call void @cqrt_free(i32 %48)    ; IR: release the product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %47, i32 %43, i32 %43)    ; IR: uncompute %52
  call void @cqrt_free(i32 %47)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %46, i32 %45, i32 %43)    ; IR: uncompute %51
  call void @cqrt_free(i32 %46)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %45, i32 %38, i32 %38)    ; IR: uncompute %50
  call void @cqrt_free(i32 %45)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %44, i32 %42, i32 %42)    ; IR: uncompute %49
  call void @cqrt_free(i32 %44)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %43, i32 %38, i32 %42)    ; IR: uncompute %48
  call void @cqrt_free(i32 %43)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fpext_f32_to_f64_unc(i32 %42, i32 %41)    ; IR: uncompute %47
  call void @cqrt_free(i32 %42)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %41, i32 %38)    ; IR: uncompute %46
  call void @cqrt_free(i32 %41)    ; IR: release the %46 rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %40, i32 %29, double 0x6BB0000000000000, i32 %39)    ; IR: uncompute %45
  call void @cqrt_free(i32 %40)    ; IR: release the %45 rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %39, i32 %32, double 0x1430000000000000, double 1.000000e+00)    ; IR: uncompute %45
  call void @cqrt_free(i32 %39)    ; IR: release the %45 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %38, i32 %29, i32 %30, i32 %37)    ; IR: uncompute %44
  call void @cqrt_free(i32 %38)    ; IR: release the %44 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %37, i32 %32, i32 %33, i32 %15)    ; IR: uncompute %44
  call void @cqrt_free(i32 %37)    ; IR: release the %44 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %36, i32 %29, i32 %31, i32 %35)    ; IR: uncompute %43
  call void @cqrt_free(i32 %36)    ; IR: release the %43 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %35, i32 %32, i32 %34, i32 %14)    ; IR: uncompute %43
  call void @cqrt_free(i32 %35)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %34, i32 %14, double 0x6BB0000000000000)    ; IR: uncompute %41
  call void @cqrt_free(i32 %34)    ; IR: release the %41 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %33, i32 %15, double 0x6BB0000000000000)    ; IR: uncompute %40
  call void @cqrt_free(i32 %33)    ; IR: release the %40 rail (|0>)
  call void @cq_template_icmp_ult_i64_hl_unc(i32 %32, i32 %19, i64 2580562586483294208)    ; IR: uncompute %38
  call void @cqrt_free(i32 %32)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %31, i32 %14, double 0x1430000000000000)    ; IR: uncompute %36
  call void @cqrt_free(i32 %31)    ; IR: release the %36 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %30, i32 %15, double 0x1430000000000000)    ; IR: uncompute %35
  call void @cqrt_free(i32 %30)    ; IR: release the %35 rail (|0>)
  call void @cq_template_icmp_ugt_i64_hl_unc(i32 %29, i32 %16, i64 6908521828386340863)    ; IR: uncompute %33
  call void @cqrt_free(i32 %29)    ; IR: release the %33 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %28, i32 %11, i32 %9)    ; IR: uncompute %31
  call void @cqrt_free(i32 %28)    ; IR: release the %31 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %27, i32 %26, i32 64)    ; IR: uncompute %29
  call void @cqrt_free(i32 %27)    ; IR: release the %29 rail (|0>)
  call void @cq_template_sub_i32_unc(i32 %26, i32 %18, i32 %21)    ; IR: uncompute %28
  call void @cqrt_free(i32 %26)    ; IR: release the %28 rail (|0>)
  call void @cqrt_or_i1(i32 %24, i32 %23, i32 %25)    ; IR: uncompute %26  [self-inverse]
  call void @cqrt_free(i32 %25)    ; IR: release the %26 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %24, i32 %19, i64 0)    ; IR: uncompute %25
  call void @cqrt_free(i32 %24)    ; IR: release the %25 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %23, i32 %17, i64 2047)    ; IR: uncompute %24
  call void @cqrt_free(i32 %23)    ; IR: release the %24 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %22, i32 %20, i64 2047)    ; IR: uncompute %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %21, i32 %20)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %20, i32 %19, i64 52)    ; IR: uncompute %20
  call void @cqrt_free(i32 %20)    ; IR: release the %20 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %19, i32 %14)    ; IR: uncompute %19
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %18, i32 %17)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %17, i32 %16, i64 52)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %16, i32 %15)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %15, i32 %13, i32 %11, i32 %9)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %14, i32 %13, i32 %9, i32 %11)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_icmp_ult_i64_unc(i32 %13, i32 %10, i32 %12)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %11, i32 %6)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %9, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %8, i32 %5, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %6, double 0.000000e+00)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %67 = call double @cqrt_measure_f64(i32 %66)    ; IR: %69 = cq_measure_f64(%68)
  ret double %67    ; IR: ret %69
}

declare void @cqrt_free(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
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
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_icmp_ult_i64(i32, i32)
declare void @cq_template_icmp_ult_i64_unc(i32, i32, i32)
declare double @llvm.fabs.f64(double)
declare double @llvm.fmuladd.f64(double, double, double)
declare double @llvm.sqrt.f64(double)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
