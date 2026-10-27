; HAND-WRITTEN. Rules: 23, 8, 4, 5, 2.
; Checked: f + g, f = fetestexcept(INEXACT | OVERFLOW | INVALID), g = fetestexcept(ALL) after feclearexcept(INEXACT)
; (measured).
; Clean: the quotient y, its exception bits, the compare flag and its signaling exception bits, every intermediate
; flags state, the raised bits select(y > k, 8, 0), and both fetestexcept quantum parts.
; Kept: the user register x; the final flags rail (flags & ~32, fenv state, an output); the result rails f, g
; (measured).
; Rotations: Ry(th) on x.
; Full floating-point environment, part 2 of 3: the EXCEPTION FLAGS (rule 23). With fpexcept.strict every constrained
; op on quantum data has a second template, ..._exc, with the same operands and mode, that computes the op's exception
; bits (host encoding: INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32) into a fresh i32 rail. The flags
; are split like the mode (80): the HOST register, kept by the real calls, holds what classical ops raise; the quantum
; FLAGS RAIL holds what templates raise. It is sticky and advances out of place: flags' = cq_template_or_i32(flags,
; exc), and while it is empty the first exc rail is the flags rail. feraiseexcept(m) under a quantum predicate: or with
; select(pred, m, 0); unconditioned it is the host call. feclearexcept(m): host call + and with ~m. fetestexcept(m):
; host call | (flags & m), a fresh quantum i32. The signaling compare (constrained fcmps, C's `>`) raises INVALID on a
; NaN through cq_template_fcmps_<pred>_<W>_exc; its value is the ordinary fcmp template. Every intermediate flags state
; and every exc rail is uncomputed in the mirror; the FINAL flags rail is observable fenv state, an output like the
; global of 71, and stays allocated. The rounding mode is classical here: fegetround() at entry.
source_filename = "fenv_flags.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @fenv_flags(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @fegetround()    ; IR: round.dynamic: the classical entry mode, read once from the host
  %7 = call i32 @feclearexcept(i32 63)    ; IR: %6 = feclearexcept(63)  (host call; the quantum flags rail is still empty)
  %8 = call i32 @cq_template_fdiv_f64_hl_rm(i32 %5, double %2, i32 %6)    ; IR: %7 = constrained.fdiv(%5, %2, round.dynamic, strict)
  %9 = call i32 @cq_template_fdiv_f64_hl_rm_exc(i32 %5, double %2, i32 %6)    ; IR: %7: its exception bits  [the flags rail from here on]
  %10 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %8, double %3)    ; IR: %8 = constrained.fcmps ogt %7, %3  [path predicate of block %9]
  %11 = call i32 @cq_template_fcmps_ogt_f64_hl_exc(i32 %8, double %3)    ; IR: %8: signaling compare, INVALID on a NaN
  %12 = call i32 @cq_template_or_i32(i32 %9, i32 %11)    ; IR: %8: flags' = flags | exc  (sticky)
  %13 = call i32 @cq_template_select_i32_ll(i32 %10, i32 8, i32 0)    ; IR: br i1 %8 -> block %9: %10 = feraiseexcept(8) under the predicate
  %14 = call i32 @cq_template_or_i32(i32 %12, i32 %13)    ; IR: %10: flags' = flags | (pred ? 8 : 0)
  %15 = call i32 @fetestexcept(i32 41)    ; IR: %12 = fetestexcept(41): the host part
  %16 = call i32 @cq_template_and_i32_hl(i32 %14, i32 41)    ; IR: %12: the quantum part, flags & 41
  %17 = call i32 @cq_template_or_i32_hl(i32 %16, i32 %15)    ; IR: %12 = host | quantum  [result f]
  %18 = call i32 @feclearexcept(i32 32)    ; IR: %13 = feclearexcept(32)  (host call)
  %19 = call i32 @cq_template_and_i32_hl(i32 %14, i32 -33)    ; IR: %13: flags' = flags & ~32  [final flags rail: an output]
  %20 = call i32 @fetestexcept(i32 63)    ; IR: %14 = fetestexcept(63): the host part
  %21 = call i32 @cq_template_and_i32_hl(i32 %19, i32 63)    ; IR: %14: the quantum part
  %22 = call i32 @cq_template_or_i32_hl(i32 %21, i32 %20)    ; IR: %14 = host | quantum  [result g]
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %19, i32 63)    ; IR: uncompute %14's quantum part
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %14, i32 41)    ; IR: uncompute %12's quantum part
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %14, i32 %12, i32 %13)    ; IR: uncompute the flags state after %10 (%fl4 stays)
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %10, i32 8, i32 0)    ; IR: uncompute the raised bits of %10
  call void @cqrt_free(i32 %13)    ; IR: release them (|0>)
  call void @cq_template_or_i32_unc(i32 %12, i32 %9, i32 %11)    ; IR: uncompute the flags state after %8
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_fcmps_ogt_f64_hl_exc_unc(i32 %11, i32 %8, double %3)    ; IR: uncompute %8's exception bits
  call void @cqrt_free(i32 %11)    ; IR: release them (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %10, i32 %8, double %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fdiv_f64_hl_rm_exc_unc(i32 %9, i32 %5, double %2, i32 %6)    ; IR: uncompute %7's exception bits
  call void @cqrt_free(i32 %9)    ; IR: release them (|0>)
  call void @cq_template_fdiv_f64_hl_rm_unc(i32 %8, i32 %5, double %2, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %23 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %15 = cq_measure_si32(%12)
  %24 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %16 = cq_measure_si32(%14)
  %25 = add nsw i32 %24, %23    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %25    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @fegetround()
declare i32 @feclearexcept(i32)
declare i32 @fetestexcept(i32)
declare i32 @cq_template_fdiv_f64_hl_rm(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fdiv_f64_hl_rm_exc(i32, double, i32)
declare void @cq_template_fdiv_f64_hl_rm_exc_unc(i32, i32, double, i32)
declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)
declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmps_ogt_f64_hl_exc(i32, double)
declare void @cq_template_fcmps_ogt_f64_hl_exc_unc(i32, i32, double)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_or_i32_hl(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
