; HAND-WRITTEN. Rules: 23, 4, 9, 5, 2.
; Checked: fenv_rounding: w + (double)m, w = ((x * c) + c) * c under the three modes, m the quantum mode;
; quantum_mode_classical_op: s = a + b rounded under the quantum mode (measured).
; Clean: fenv_rounding: the product y, the compare flag, the sum z; quantum_mode_classical_op: the compare flag and
; the mode rail.
; Kept: the user register x of each function; fenv_rounding's mode rail (measured as m) and result rail w;
; quantum_mode_classical_op's result rail s.
; Rotations: Ry(th) on x (each function).
; Full floating-point environment, part 1 of 3: the ROUNDING MODE (rule 23). Under `#pragma STDC FENV_ACCESS ON`
; clang -O1 emits llvm.experimental.constrained.* with round.dynamic: every such op reads the current mode. The fenv
; is program state (as the escaping global of 71), split in two: the HOST part, kept exactly by the real fenv calls
; for classical ops, and the QUANTUM part, the mode and flags as rails. The mode is classical (an i32 value the
; compiler tracks: the last classical fesetround argument, or fegetround() at entry) until a quantum value is written
; into it; then it is a handle and no host call is made. Template grammar (§1.2), one rule for all three fenv
; examples: cq_template_<op>[_<pred>]_<W>[_hl|_lh|_ll][_rm|_rmq][_exc][_unc]
;   _rm  = the mode is a classical i32 operand, last; _rmq = the mode is a handle, last; _exc = see example 81.
; A constrained op whose operands are all classical but whose mode is quantum is QUANTUM (its result depends on the
; mode): quantum_mode_classical_op shows it, `a + b` becomes cq_template_fadd_f64_ll_rmq. fegetround() under a quantum
; mode returns the mode handle itself. fpexcept.ignore here (`#pragma clang fp exceptions(ignore)`): no exception
; bits; 81 has them. Mode constants are the x86-64 host's: FE_TONEAREST 0, FE_DOWNWARD 1024, FE_UPWARD 2048,
; FE_TOWARDZERO 3072.
source_filename = "fenv_rounding.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @fenv_rounding(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @fesetround(i32 2048)    ; IR: %6 = fesetround(2048)  (classical mode: the host call stays; the mode operand is now 2048)
  %7 = call i32 @cq_template_fmul_f64_hl_rm(i32 %5, double %2, i32 2048)    ; IR: %7 = constrained.fmul(%5, %2, round.dynamic)  [mode = classical 2048]
  %8 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %5, double %3)    ; IR: %8 = constrained.fcmps ogt %5, %3  (fpexcept.ignore: the value only)
  %9 = call i32 @cq_template_select_i32_ll(i32 %8, i32 2048, i32 1024)    ; IR: %9 = select i1 %8, i32 2048, i32 1024  [the quantum mode]
  ; IR: %10 = fesetround(%9): the mode becomes the handle %mq; no host call (the host mode is unused until a classical mode returns)
  %10 = call i32 @cq_template_fadd_f64_hl_rmq(i32 %7, double %2, i32 %9)    ; IR: %11 = constrained.fadd(%7, %2, round.dynamic)  [mode = handle %mq]
  ; IR: %12 = fegetround(): the current mode, i.e. the handle %mq itself (no gate)
  %11 = call i32 @fesetround(i32 0)    ; IR: %13 = fesetround(0)  (classical again: host call, mode operand 0)
  %12 = call i32 @cq_template_fmul_f64_hl_rm(i32 %10, double %2, i32 0)    ; IR: %14 = constrained.fmul(%11, %2, round.dynamic)  [mode = classical 0]
  call void @cq_template_fadd_f64_hl_rmq_unc(i32 %10, i32 %7, double %2, i32 %9)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %8, i32 %5, double %3)    ; IR: uncompute %8 (%mq stays: it is measured as m)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_rm_unc(i32 %7, i32 %5, double %2, i32 2048)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %13 = call double @cqrt_measure_f64(i32 %12)    ; IR: %15 = cq_measure_f64(%14)
  %14 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %16 = cq_measure_si32(%12)  (measures the quantum mode register)
  %15 = call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %14, metadata !"round.dynamic", metadata !"fpexcept.ignore")    ; IR: %17  (classical, host mode 0)
  %16 = call double @llvm.experimental.constrained.fadd.f64(double %13, double %15, metadata !"round.dynamic", metadata !"fpexcept.ignore")    ; IR: %18  (classical, host mode 0)
  ret double %16    ; IR: ret double %18
}

define double @quantum_mode_classical_op(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %6, double %2)    ; IR: %7 = constrained.fcmps ogt %6, %2
  %8 = call i32 @cq_template_select_i32_ll(i32 %7, i32 2048, i32 1024)    ; IR: %8 = select i1 %7, i32 2048, i32 1024; %9 = fesetround(%8)  [the quantum mode; no host call]
  %9 = call i32 @cq_template_fadd_f64_ll_rmq(double %3, double %4, i32 %8)    ; IR: %10 = constrained.fadd(%3, %4, round.dynamic)  [both operands classical, the mode a handle: s is QUANTUM]
  %10 = call i32 @fesetround(i32 0)    ; IR: %11 = fesetround(0)  (classical again: host call; the quantum mode is no longer state)
  call void @cq_template_select_i32_ll_unc(i32 %8, i32 %7, i32 2048, i32 1024)    ; IR: uncompute %8 (the old mode rail)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %7, i32 %6, double %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %11 = call double @cqrt_measure_f64(i32 %9)    ; IR: %12 = cq_measure_f64(%10)
  ret double %11    ; IR: ret double %12
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @fesetround(i32)
declare i32 @cq_template_fmul_f64_hl_rm(i32, double, i32)
declare void @cq_template_fmul_f64_hl_rm_unc(i32, i32, double, i32)
declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)
declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_fadd_f64_hl_rmq(i32, double, i32)
declare void @cq_template_fadd_f64_hl_rmq_unc(i32, i32, double, i32)
declare i32 @cq_template_fadd_f64_ll_rmq(double, double, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
declare i32 @cqrt_measure_i32(i32)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
