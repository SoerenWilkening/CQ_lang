; lowering_fp80_union_seed_fmuladd.ll — ACCEPT (bd 3c6m.55 Inc 1, Lever A.1a):
; promoteFp80Union admits an fp80 union SEED derived through a curated pure fp
; intrinsic (`@llvm.fmuladd.f80`) — the openlibm expl/coshl idiom where the
; union stores a polynomial/Horner reduction result (`u.e = fmuladd(x, c, c)`)
; before extracting its exponent/sign words. Before this increment the seed walk
; (`fpSeedValueOk`) had no transparent case for a `call` — a fmuladd-derived
; seed fell to `default → false`, so the candidate was dropped by the seed
; fixpoint and the union stayed in memory (the seed-cascade that left 6/9 of
; expl's unions un-promoted). The intrinsic is admitted PARALLEL to `fmul`/
; `fadd` (a pure fp producer of admissible operands is a legitimate fp value),
; via the exported `isCuratedReversibleIntrinsic` predicate (accept-set =
; lowered-set). The helper here is CLASSICAL (arg-derived, untainted) — the
; promotion is the OPPORTUNISTIC path (the pre-specialization register-form
; canonicalization a later fp-arg clone inherits), fence-sound regardless of
; taint (the §4.1 padding walk is a value-flow bit-divergence analysis). The
; quantum anchor keeps the module off the passthrough early-out.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; u.e = fmuladd(x, 1.5, 0.5); return (int)(u.bits.expsign)  (GET_LDBL exponent)
define i32 @helper(x86_fp80 noundef %x) {
  %u = alloca %union.IEEEl2bits, align 16
  %s = call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %x, x86_fp80 0xK3FFFC000000000000000, x86_fp80 0xK3FFE8000000000000000)
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; the fmuladd-seeded union is promoted to classical register form (the union
; memory is gone; the seed is relabelled via `bitcast x86_fp80 -> i80`); the
; anchor (which precedes @helper in the output) lowers normally:
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i32 @helper(
; CHECK-NOT: alloca
; CHECK:     bitcast x86_fp80 %{{[a-z0-9.]+}} to i80
; CHECK-NOT: store x86_fp80
