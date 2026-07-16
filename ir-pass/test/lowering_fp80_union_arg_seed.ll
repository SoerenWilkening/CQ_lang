; lowering_fp80_union_arg_seed.ll — ACCEPT (bd vqlq): promoteFp80Union admits
; an ARGUMENT-derived fp80 seed (`sitofp i32 %arg -> x86_fp80`) as an
; OPPORTUNISTIC candidate. The helper here is purely CLASSICAL (untainted) —
; the promotion must still be applied so a later specialization (or a purely
; classical caller) sees the register form: it is fence-sound regardless of
; taint (the §4.1 padding walk is a value-flow bit-divergence analysis; every
; observable — return, call, compare, out-store — with a diverged bit
; declines), and the promoted body computes bit-identical classical values.
; The classical remainder keeps plain IR ops (bitcast/lshr/or on i80 —
; untainted values never mint templates). The quantum anchor keeps the module
; off the passthrough early-out.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

define i32 @helper(i32 noundef %0) {
  %2 = alloca %union.IEEEl2bits, align 16
  %3 = sitofp i32 %0 to x86_fp80
  store x86_fp80 %3, ptr %2, align 16
  %4 = getelementptr inbounds i8, ptr %2, i64 8
  %5 = load i64, ptr %4, align 8
  %6 = and i32 %0, 32767
  %7 = zext nneg i32 %6 to i64
  %8 = and i64 %5, -32768
  %9 = or disjoint i64 %8, %7
  store i64 %9, ptr %4, align 8
  %10 = load x86_fp80, ptr %2, align 16
  %11 = fmul x86_fp80 %10, 0xK40018000000000000000
  %12 = fptosi x86_fp80 %11 to i32
  ret i32 %12
}

; the helper's union is promoted to classical register form (plain IR ops, no
; templates — nothing tainted) and the union memory is gone; the anchor (which
; precedes @helper in the output) lowers normally:
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i32 @helper(
; CHECK-NOT: alloca
; CHECK:     bitcast x86_fp80 %{{[0-9]+}} to i80
; CHECK-NOT: store x86_fp80
