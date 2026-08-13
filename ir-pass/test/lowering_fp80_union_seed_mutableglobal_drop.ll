; lowering_fp80_union_seed_mutableglobal_drop.ll — SILENT-DROP PIN (bd 3c6m.55
; Inc 1, Lever A.1b — the discriminating decline probe): the const-global seed
; admission is EXACTLY "GlobalVariable, isConstant, definitive initializer"
; memory, NEVER a blanket global-load rule. A union whose fp80 seed is loaded
; from (a) a MUTABLE global (`@mut` — another store could alias it; the loaded
; bits are runtime state, not a constant-rooted value) or (b) an EXTERNAL
; constant DECLARATION (`@extc` — no definitive initializer to vouch for) is
; NOT admitted: `fpSeedValueOk` drops the candidate and the union stays in
; memory (all classical here — no taint escape, the module compiles). If the
; admission ever loosened, these unions would promote and the
; `CHECK-NOT: bitcast{{.*}}to i80` would FAIL. Mirrors the curated positive
; `lowering_fp80_union_seed_constglobal.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

@mut = internal global [2 x x86_fp80] [x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK40008000000000000000], align 16
@extc = external constant [2 x x86_fp80], align 16

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; seed loaded from a MUTABLE global — must NOT promote.
define i32 @helper_mut(x86_fp80 noundef %x) {
  %u = alloca %union.IEEEl2bits, align 16
  %c = load x86_fp80, ptr @mut, align 16
  %s = fmul x86_fp80 %c, %x
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; seed loaded from an EXTERNAL constant declaration — must NOT promote.
define i32 @helper_extc(x86_fp80 noundef %x) {
  %u = alloca %union.IEEEl2bits, align 16
  %c = load x86_fp80, ptr @extc, align 16
  %s = fmul x86_fp80 %c, %x
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; both unions stay in memory (the global-load seed is inadmissible → dropped):
; CHECK:     define i32 @helper_mut(
; CHECK:       alloca
; CHECK:     define i32 @helper_extc(
; CHECK:       alloca
; CHECK-NOT: bitcast x86_fp80 %{{[a-z0-9.]+}} to i80
