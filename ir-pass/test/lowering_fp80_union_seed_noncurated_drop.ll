; lowering_fp80_union_seed_noncurated_drop.ll — SILENT-DROP PIN (bd 3c6m.55
; Inc 1, Lever A.1a — the discriminating decline probe): the seed-walk intrinsic
; admission is EXACT `isCuratedReversibleIntrinsic` membership, NEVER a
; `starts_with("llvm.")` blanket. A union whose fp80 seed is derived through a
; NON-curated call — a transcendental `@llvm.sin.f80` (a library function,
; source-injected not recognized, Rule 18) or an opaque `@blackbox` — is NOT a
; transparent fp-derivation op: `fpSeedValueOk` returns false, the seed fixpoint
; drops the candidate, and the union stays in memory (all classical here — no
; taint escape, the module compiles). If the admission ever widened to a name
; prefix, these unions would promote and the `CHECK-NOT: bitcast{{.*}}to i80`
; would FAIL. Mirrors the curated positive `lowering_fp80_union_seed_fmuladd.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare x86_fp80 @llvm.sin.f80(x86_fp80)
declare x86_fp80 @blackbox(x86_fp80)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; seed via a NON-curated intrinsic (@llvm.sin) — must NOT promote.
define i32 @helper_sin(x86_fp80 noundef %x) {
  %u = alloca %union.IEEEl2bits, align 16
  %s = call x86_fp80 @llvm.sin.f80(x86_fp80 %x)
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; seed via an opaque call (@blackbox) — must NOT promote.
define i32 @helper_opaque(x86_fp80 noundef %x) {
  %u = alloca %union.IEEEl2bits, align 16
  %s = call x86_fp80 @blackbox(x86_fp80 %x)
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; both unions stay in memory (the non-curated seed is inadmissible → dropped):
; CHECK:     define i32 @helper_sin(
; CHECK:       alloca
; CHECK:     define i32 @helper_opaque(
; CHECK:       alloca
; CHECK-NOT: bitcast x86_fp80 %{{[a-z0-9.]+}} to i80
