; HAND-WRITTEN. Rules: 23, 18, 26, 5.
; Checked: inexact (%17 -> %31) and w (%27 -> %32), summed classically.
; Clean: every dropped flags rail (the held flags %14 after feupdateenv, scale's returned flags %23 after fesetexceptflag,
; the FE_UPWARD flags %29 after fesetenv), the exception-bit rails %11 and %28, the quantum part of inexact's test (%16),
; p (%10), y (%13), scale's result rail %22, and inside the clone its whole chain.
; Kept: x (%8, the rotated register); the final flags rail %19 (restored | held, an output of rule 23, never freed);
; inexact (%17) and w (%27), measured.
; Rotations: (Ry, x, th, 1).
; Full floating-point environment, part 3 of 3: SAVED ENVIRONMENTS and CALLS. Mode and flags are split into a host part
; and a quantum part as in 80 and 81. A fenv_t or fexcept_t object keeps its host part through the real calls on the real
; alloca; its quantum part (the flags rail, and the mode when it is a handle) is known statically at every fenv call, so it
; is carried as SSA values exactly as -O1 carries a promoted slot (an object that escapes or is written in a loop is a
; classical slot of handles, as 31/70). feholdexcept(&env): save {mode, flags}, clear the flags (the rail becomes empty).
; feupdateenv: restore the saved part, then OR the current flags in. fegetexceptflag/fesetexceptflag(FE_ALL_EXCEPT): save /
; reinstate the flags handle itself (a narrower mask would and/or it). fegetenv/fesetenv: save / reinstate both. A flags
; rail that stops being current state (dropped by fesetexceptflag or fesetenv) is uncomputed; the final one is an output
; and stays. CALLS: a clone of a function that does constrained FP work takes the caller's mode (literal or handle) and
; quantum flags handle as two trailing parameters and returns { result, flags' } (the aggregate ABI of 64), BOTH copied
; into fresh rails before the body is uncomputed (rule 18); its _unc twin takes both returned handles first, then the same
; operands, and zeroes both; the caller frees both after the twin. scale's v * c + c is a constrained llvm.fmuladd, which is
; UNFUSED (§2, cf. 14): a constrained fmul then fadd, each with its _rm value template and _exc exception-bit template;
; flags' ORs both exception rails into the caller's flags, and every partial rail is uncomputed in dependency order.
source_filename = "fenv_env.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }    ; IR: %struct.fenv_t  (the host part keeps its real layout)

define i32 @fenv_env(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = alloca %struct.fenv_t, align 4    ; IR: %5 = alloca fenv_t  (env: host part)
  %6 = alloca i16, align 2    ; IR: %6 = alloca i16  (saved: host part)
  %7 = alloca %struct.fenv_t, align 4    ; IR: %7 = alloca fenv_t  (e2: host part)
  %8 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %8 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %8, double %1)    ; IR: %8 = cq_theta_f64(%0, %1)  [Ry]
  %9 = call i32 @fegetround()    ; IR: round.dynamic: the classical entry mode, read once from the host
  %10 = call i32 @cq_template_fmul_f64_hl_rm(i32 %8, double %2, i32 %9)    ; IR: %9 = constrained.fmul(%8, %2, round.dynamic, strict)
  %11 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %8, double %2, i32 %9)    ; IR: %9: its exception bits  [flags rail]
  %12 = call i32 @feholdexcept(ptr %5)    ; IR: %10 = feholdexcept(%5)  (host call; env's quantum part = {mode, %e0}; the flags rail is now empty)
  %13 = call i32 @cq_template_fdiv_f64_hl_rm(i32 %10, double %2, i32 %9)    ; IR: %11 = constrained.fdiv(%9, %2, round.dynamic, strict)
  %14 = call i32 @cq_template_fdiv_f64_hl_rm_exc(i32 %10, double %2, i32 %9)    ; IR: %11: its exception bits  [flags rail, held]
  %15 = call i32 @fetestexcept(i32 32)    ; IR: %12 = fetestexcept(32): the host part
  %16 = call i32 @cq_template_and_i32_hl(i32 %14, i32 32)    ; IR: %12: the quantum part, flags & 32
  %17 = call i32 @cq_template_or_i32_hl(i32 %16, i32 %15)    ; IR: %12 = host | quantum  [result inexact]
  %18 = call i32 @feupdateenv(ptr %5)    ; IR: %13 = feupdateenv(%5)  (host call)
  %19 = call i32 @cq_template_or_i32(i32 %11, i32 %14)    ; IR: %13: restored flags | current flags  [flags rail; final state at the end]
  %20 = call i32 @fegetexceptflag(ptr %6, i32 63)    ; IR: %14 = fegetexceptflag(%6, 63)  (host call; saved's quantum part = %fu)
  %21 = call fastcc { i32, i32 } @__cq_q_scale_10(i32 %13, double %3, i32 %9, i32 %19)    ; IR: %15 = call @scale(%11, %3), clone (arg 0 quantum) + mode + flags
  %22 = extractvalue { i32, i32 } %21, 0    ; IR: %15  [result rail]
  %23 = extractvalue { i32, i32 } %21, 1    ; IR: %15: the flags after scale
  %24 = call i32 @fesetexceptflag(ptr %6, i32 63)    ; IR: %16 = fesetexceptflag(%6, 63)  (host call; the flags rail is %fu again, %fs is dropped)
  %25 = call i32 @fegetenv(ptr %7)    ; IR: %17 = fegetenv(%7)  (host call; e2's quantum part = {mode, %fu})
  %26 = call i32 @fesetround(i32 2048)    ; IR: %18 = fesetround(2048)  (host call; mode operand 2048)
  %27 = call i32 @cq_template_fmul_f64_hl_rm(i32 %22, double %2, i32 2048)    ; IR: %19 = constrained.fmul(%15, %2, round.dynamic, strict)
  %28 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %22, double %2, i32 2048)    ; IR: %19: its exception bits
  %29 = call i32 @cq_template_or_i32(i32 %19, i32 %28)    ; IR: %19: flags' = flags | exc
  %30 = call i32 @fesetenv(ptr %7)    ; IR: %20 = fesetenv(%7)  (host call; mode and flags back to e2's: the flags rail is %fu, %fw is dropped)
  call void @cq_template_or_i32_unc(i32 %29, i32 %19, i32 %28)    ; IR: uncompute the dropped flags state of %19
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %28, i32 %22, double %2, i32 2048)    ; IR: uncompute %19's exception bits
  call void @cqrt_free(i32 %28)    ; IR: release them (|0>)
  call fastcc void @__cq_q_scale_10_unc(i32 %22, i32 %23, i32 %13, double %3, i32 %9, i32 %19)    ; IR: uncompute %15 and its dropped flags
  call void @cqrt_free(i32 %22)    ; IR: release the %15 rail (|0>)
  call void @cqrt_free(i32 %23)    ; IR: release the dropped flags rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %14, i32 32)    ; IR: uncompute %12's quantum part
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_fdiv_f64_hl_rm_exc_unc(i32 %14, i32 %10, double %2, i32 %9)    ; IR: uncompute %11's exception bits (%fu stays)
  call void @cqrt_free(i32 %14)    ; IR: release them (|0>)
  call void @cq_template_fdiv_f64_hl_rm_unc(i32 %13, i32 %10, double %2, i32 %9)    ; IR: uncompute %11
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %11, i32 %8, double %2, i32 %9)    ; IR: uncompute %9's exception bits
  call void @cqrt_free(i32 %11)    ; IR: release them (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %10, i32 %8, double %2, i32 %9)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  %31 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %21 = cq_measure_si32(%12)
  %32 = call double @cqrt_measure_f64(i32 %27)    ; IR: %22 = cq_measure_f64(%19)
  %33 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %32, metadata !"fpexcept.strict")    ; IR: %23  (classical, host flags)
  %34 = add nsw i32 %33, %31    ; IR: %24 = add nsw i32 %23, %21  (classical)
  ret i32 %34    ; IR: ret i32 %24
}

define internal fastcc { i32, i32 } @__cq_q_scale_10(i32 %0, double %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_fmul_f64_hl_rm(i32 %0, double %1, i32 %2)    ; IR: %3 = constrained.fmuladd(%0, %1, %1, round.dynamic, strict)  [unfused product v * c, mode = the caller's]
  %6 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %0, double %1, i32 %2)    ; IR: %3: the product's exception bits
  %7 = call i32 @cq_template_fadd_f64_hl_rm(i32 %5, double %1, i32 %2)    ; IR: %3  [unfused sum + c]
  %8 = call i32 @cq_template_fadd_f64_hl_rm_exc(i32 %5, double %1, i32 %2)    ; IR: %3: the sum's exception bits
  %9 = call i32 @cq_template_or_i32(i32 %3, i32 %6)    ; IR: %3: the caller's flags | the product's exc
  %10 = call i32 @cq_template_or_i32(i32 %9, i32 %8)    ; IR: %3: flags' = that | the sum's exc  [returned: fenv state]
  %11 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret double %3  [result rail of the call]
  call void @cqrt_copy_f64(i32 %7, i32 %11)    ; IR: copy the result out
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret double %3  [the returned flags rail: the second result, copied out too (rule 18)]
  call void @cqrt_copy_i32(i32 %10, i32 %12)    ; IR: copy flags' out
  call void @cq_template_or_i32_unc(i32 %10, i32 %9, i32 %8)    ; IR: uncompute flags'
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %9, i32 %3, i32 %6)    ; IR: uncompute the partial flags
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_hl_rm_exc_unc(i32 %8, i32 %5, double %1, i32 %2)    ; IR: uncompute the sum's exception bits
  call void @cqrt_free(i32 %8)    ; IR: release them (|0>)
  call void @cq_template_fadd_f64_hl_rm_unc(i32 %7, i32 %5, double %1, i32 %2)    ; IR: uncompute %3 [sum]
  call void @cqrt_free(i32 %7)    ; IR: release the %3 rail (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %6, i32 %0, double %1, i32 %2)    ; IR: uncompute the product's exception bits
  call void @cqrt_free(i32 %6)    ; IR: release them (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %5, i32 %0, double %1, i32 %2)    ; IR: uncompute the product
  call void @cqrt_free(i32 %5)    ; IR: release the product rail (|0>)
  %13 = insertvalue { i32, i32 } poison, i32 %11, 0    ; IR: ret double %3: the result handle
  %14 = insertvalue { i32, i32 } %13, i32 %12, 1    ; IR: and the new flags handle
  ret { i32, i32 } %14    ; IR: ret double %3
}

define internal fastcc void @__cq_q_scale_10_unc(i32 %0, i32 %1, i32 %2, double %3, i32 %4, i32 %5) {
  %7 = call i32 @cq_template_fmul_f64_hl_rm(i32 %2, double %3, i32 %4)    ; IR: recompute %3 [product]
  %8 = call i32 @cq_template_fmul_f64_hl_rm_exc(i32 %2, double %3, i32 %4)    ; IR: recompute the product's exception bits
  %9 = call i32 @cq_template_fadd_f64_hl_rm(i32 %7, double %3, i32 %4)    ; IR: recompute %3 [sum]
  %10 = call i32 @cq_template_fadd_f64_hl_rm_exc(i32 %7, double %3, i32 %4)    ; IR: recompute the sum's exception bits
  %11 = call i32 @cq_template_or_i32(i32 %5, i32 %8)    ; IR: recompute the partial flags
  %12 = call i32 @cq_template_or_i32(i32 %11, i32 %10)    ; IR: recompute the new flags
  call void @cqrt_copy_f64(i32 %9, i32 %0)    ; IR: xor the result out of %out
  call void @cqrt_copy_i32(i32 %12, i32 %1)    ; IR: xor the new flags out of %flout
  call void @cq_template_or_i32_unc(i32 %12, i32 %11, i32 %10)    ; IR: uncompute the new flags
  call void @cqrt_free(i32 %12)    ; IR: release them (|0>)
  call void @cq_template_or_i32_unc(i32 %11, i32 %5, i32 %8)    ; IR: uncompute the partial flags
  call void @cqrt_free(i32 %11)    ; IR: release them (|0>)
  call void @cq_template_fadd_f64_hl_rm_exc_unc(i32 %10, i32 %7, double %3, i32 %4)    ; IR: uncompute the sum's exception bits
  call void @cqrt_free(i32 %10)    ; IR: release them (|0>)
  call void @cq_template_fadd_f64_hl_rm_unc(i32 %9, i32 %7, double %3, i32 %4)    ; IR: uncompute %3 [sum]
  call void @cqrt_free(i32 %9)    ; IR: release the %3 rail (|0>)
  call void @cq_template_fmul_f64_hl_rm_exc_unc(i32 %8, i32 %2, double %3, i32 %4)    ; IR: uncompute the product's exception bits
  call void @cqrt_free(i32 %8)    ; IR: release them (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %7, i32 %2, double %3, i32 %4)    ; IR: uncompute the product
  call void @cqrt_free(i32 %7)    ; IR: release the product rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @fegetround()
declare i32 @fesetround(i32)
declare i32 @feholdexcept(ptr)
declare i32 @feupdateenv(ptr)
declare i32 @fetestexcept(i32)
declare i32 @fegetexceptflag(ptr, i32)
declare i32 @fesetexceptflag(ptr, i32)
declare i32 @fegetenv(ptr)
declare i32 @fesetenv(ptr)
declare i32 @cq_template_fmul_f64_hl_rm(i32, double, i32)
declare void @cq_template_fmul_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fmul_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fmul_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_fdiv_f64_hl_rm(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fdiv_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_fadd_f64_hl_rm(i32, double, i32)
declare void @cq_template_fadd_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fadd_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fadd_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_or_i32_hl(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata)
