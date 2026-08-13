; lowering_fp80_union_arg_seed_multiblock.ll — ACCEPT (bd vqlq, the Rule-13
; reviewer's envelope pin): a MULTI-BLOCK argument-seeded union promotes with
; an f80 merge phi, never an i80 one. The canonicalization is seed-class-
; agnostic — every access to the fresh alloca is full-width x86_fp80 (the i80
; extract/insert brackets stay LOCAL around each access) — so PromoteMemToReg
; can only mint x86_fp80 phis and the kMsgFp80I80Merge defensive scan stays
; quiet, for the argument-seeded path exactly as for the tainted one (this
; fixture pins that claim with a test rather than only the analytic argument).
; The helper is classical (untainted): mini-scalbnl shape — seed from the int
; arg, a conditional fp80 re-seed arm, a masked exponent read at the join (no
; padding bit observed — the walk accepts).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

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

define i32 @mb(i32 noundef %0, i1 noundef %c) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  %s = sitofp i32 %0 to x86_fp80
  store x86_fp80 %s, ptr %u, align 16
  br i1 %c, label %rescale, label %join
rescale:
  %e = load x86_fp80, ptr %u, align 16
  %d = fmul x86_fp80 %e, 0xK407F8000000000000000
  store x86_fp80 %d, ptr %u, align 16
  br label %join
join:
  %p = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %p, align 8
  %m = and i64 %w, 32767              ; masked exp read — no padding observed
  %t = trunc i64 %m to i32
  ret i32 %t
}

; the anchor (first in the output) lowers normally; the classical multi-block
; union promotes to register form with an x86_fp80 merge phi and NO i80 phi,
; no union memory, and no diagnostic:
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i32 @mb(
; CHECK-NOT: alloca
; CHECK:     phi x86_fp80
; CHECK-NOT: phi i80
; CHECK-NOT: store x86_fp80
