; lowering_reject_transcendental_sin_no_inject.ll — DECLINE. Retargeted by bd
; 3c6m.71 (owner ruling 2026-10-06): `double` sin/cos/tan now lower directly to a
; Bennett-backed template (lowering_intrinsic_trig_f64_bennett.ll), which retires
; this fixture's former `f64` decline and its p119 "never re-add a transcendental
; template" note. The direct route is `double` ONLY, so a tainted
; `@llvm.sin.f80` (long double) with no injected body still rides the loud
; kMsgUnknownCallee escape decline; through tools/cqc it binds openlibm's sinl
; source instead (LibmBinding.h), which does not lower yet (bd 3c6m.79).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_sin

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.sin.f80(x86_fp80)

define x86_fp80 @example(x86_fp80 %u) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @llvm.sin.f80(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}
