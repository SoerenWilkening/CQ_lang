; HAND-WRITTEN. Rules: 23, 8, 4, 5, 2.
; Checked: fenv_bracket: y = x * c; fenv_tested: y + (double)f, f = fetestexcept(FE_INEXACT) (y measured; f is classical
; by rule 2 and is a classical read).
; Clean: the compare flag y > k of each function; the flags rail select(y > k, 32, 0) of each function; fenv_tested's
; flags & 32 and host | quantum rails. All of them collapse after the measurement of y (rule 2).
; Kept: the user register x of each function; the result rail y (measured).
; Rotations: Ry(th) on x (each function).
; Classical reads (rule 2): 1 (fenv_tested's cq_measure(f): f is classical after y's measurement, no gate).
; This is the DEFAULT-ENVIRONMENT case of rule 23: without `#pragma STDC FENV_ACCESS ON` clang emits plain
; fadd/fmul/fcmp, which assume round-to-nearest and raise no flags, so every FP op lowers to its ordinary template;
; examples 80-82 are the full model (constrained ops). The fenv calls are classical calls on thread-global state and
; are kept exactly as clang emitted them (host calls on the real fenv_t slot); classical code is never deleted. The
; flags are split as in 81: the host register holds what classical code raises, the quantum FLAGS RAIL what quantum
; code raises. Plain ops raise nothing, so the only quantum write is an explicit feraiseexcept under a quantum
; predicate: flags' = flags | select(pred, m, 0), no host call (while the rail is empty, the select rail is the flags
; rail). fetestexcept(m) = host call | (flags & m). fenv_bracket: the feholdexcept/feupdateenv pair brackets no
; quantum flags (the rail is empty throughout), so it is host calls only. fenv_tested: fesetround(FE_UPWARD) is a host
; call but does not reach the plain fmul, which clang compiled for the default environment, so the template rounds to
; nearest exactly as the IR says.
; CLASSICAL COLLAPSE (rule 2, ruling 2026-10-29): both functions measure y, and every rail computed from y alone (the
; compare, the flags rail, fenv_tested's f chain) is a function of the outcome and classical values. Rule 2 is a
; data-flow condition, not a program-order one: those rails were computed BEFORE the measurement, and "while its
; sources still hold the outcome" is exactly that case (the _unc reads the measured rail, which still holds m). So each
; such rail is uncomputed right after the measurement (convention: as early as the invariant allows) and its value is
; recomputed by ordinary classical instructions from m. The flags rail is fenv state: its classical value is written to
; the HOST environment by feraiseexcept(v) at the collapse point (v = 0 raises nothing), so rule 23's "final flags rail
; is an output" has nothing left to keep. fenv_tested's cq_measure(f) measures a value rule 2 made classical: it is a
; classical read and emits no measurement (one measurement per call, y's). f's host part (%11) was read at its program
; point, before the write-back, exactly as the C program read it.
source_filename = "fenv_bracket.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }    ; IR: %struct.fenv_t  (the host part keeps its real layout)

define double @fenv_bracket(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = alloca %struct.fenv_t, align 4    ; IR: %5 = alloca fenv_t  (env, host slot)
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = call i32 @fegetround()    ; IR: %7 = fegetround()  (host call)
  %8 = call i32 @fesetround(i32 0)    ; IR: %8 = fesetround(0)  (host call)
  %9 = call i32 @feholdexcept(ptr %5)    ; IR: %9 = feholdexcept(%5)  (host call; the quantum flags rail is empty)
  %10 = call i32 @cq_template_fmul_f64_hl(i32 %6, double %2)    ; IR: %10 = fmul double %6, %2  [result rail y]  (plain op: raises nothing)
  %11 = call i32 @feupdateenv(ptr %5)    ; IR: %11 = feupdateenv(%5)  (host call; empty | empty)
  %12 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %10, double %3)    ; IR: %12 = fcmp ogt double %10, %3  [predicate of block %13]
  %13 = call i32 @cq_template_select_i32_ll(i32 %12, i32 32, i32 0)    ; IR: br i1 %12 -> block %13: %14 = feraiseexcept(32) under the predicate  [flags rail]
  %14 = call i32 @fesetround(i32 %7)    ; IR: %16 = fesetround(%7)  (host call)
  %15 = call double @cqrt_measure_f64(i32 %10)    ; IR: %17 = cq_measure_f64(%10)  [outcome m; %10 holds it from here on]
  call void @cq_template_select_i32_ll_unc(i32 %13, i32 %12, i32 32, i32 0)    ; IR: rule 2 collapse: the flags rail is a function of y alone; uncompute it while %12 still holds its value
  call void @cqrt_free(i32 %13)    ; IR: release the flags rail (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %12, i32 %10, double %3)    ; IR: uncompute %12 while %10 holds the outcome
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  %16 = fcmp ogt double %15, %3    ; IR: %12 recomputed classically from the outcome (rule 2)
  %17 = select i1 %16, i32 32, i32 0    ; IR: the flags rail's classical value: select(y > k, 32, 0)
  %18 = call i32 @feraiseexcept(i32 %17)    ; IR: the collapsed flags written to the host environment (rule 23; raises nothing when %17 = 0)
  ret double %15    ; IR: ret double %17
}

define double @fenv_tested(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @fesetround(i32 2048)    ; IR: %6 = fesetround(2048)  (host call; does not reach the plain fmul)
  %7 = call i32 @feclearexcept(i32 32)    ; IR: %7 = feclearexcept(32)  (host call; the quantum flags rail is still empty)
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %5, double %2)    ; IR: %8 = fmul double %5, %2  [result rail y]
  %9 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %8, double %3)    ; IR: %9 = fcmp ogt double %8, %3  [predicate of block %10]
  %10 = call i32 @cq_template_select_i32_ll(i32 %9, i32 32, i32 0)    ; IR: br i1 %9 -> block %10: %11 = feraiseexcept(32) under the predicate  [flags rail]
  %11 = call i32 @fetestexcept(i32 32)    ; IR: %13 = fetestexcept(32): the host part, read at its program point
  %12 = call i32 @cq_template_and_i32_hl(i32 %10, i32 32)    ; IR: %13: the quantum part, flags & 32
  %13 = call i32 @cq_template_or_i32_hl(i32 %12, i32 %11)    ; IR: %13 = host | quantum  [f]
  %14 = call double @cqrt_measure_f64(i32 %8)    ; IR: %14 = cq_measure_f64(%8)  [outcome m; %8 holds it from here on]
  call void @cq_template_or_i32_hl_unc(i32 %13, i32 %12, i32 %11)    ; IR: rule 2 collapse: f is a function of y alone; uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %10, i32 32)    ; IR: uncompute %13's quantum part
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %10, i32 %9, i32 32, i32 0)    ; IR: uncompute the flags rail (a function of y alone)
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %9, i32 %8, double %3)    ; IR: uncompute %9 while %8 holds the outcome
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %15 = fcmp ogt double %14, %3    ; IR: %9 recomputed classically from the outcome (rule 2)
  %16 = select i1 %15, i32 32, i32 0    ; IR: the flags rail's classical value: select(y > k, 32, 0)
  %17 = and i32 %16, 32    ; IR: %13's quantum part, classical
  %18 = or i32 %17, %11    ; IR: %13 = host | quantum, classical  [f]
  %19 = call i32 @feraiseexcept(i32 %16)    ; IR: the collapsed flags written to the host environment (rule 23)
  %20 = sitofp i32 %18 to double    ; IR: %16 = sitofp i32 %15 to double  (%15 = cq_measure_si32(%13) is a classical read of f: no measurement)
  %21 = fadd double %14, %20    ; IR: %17 = fadd double %14, %16  (classical)
  ret double %21    ; IR: ret double %17
}

declare i32 @fegetround()
declare i32 @fesetround(i32)
declare i32 @feholdexcept(ptr)
declare i32 @feupdateenv(ptr)
declare i32 @feclearexcept(i32)
declare i32 @feraiseexcept(i32)
declare i32 @fetestexcept(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)
declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32_hl(i32, i32)
declare void @cq_template_or_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
