; lowering_intrinsic_smin_fanout_skip.ll — Phase 7.1 Increment E, R-E
; source-liveness (the SAFE-SKIP boundary). A DEAD `@llvm.smin` whose tainted
; source %q ALSO feeds a LIVE measured op (fan-out on %q) is NOT linearly
; lineaged, so the whole-DAG uncompute does NOT reverse the dead smin: reversing
; it would need to recompute from %q, but %q is still live (and reversing the
; shared prefix would double-uncompute it — Rule 8). The forward smin producer
; still emits; the dead rail is LEFT ALLOCATED (a benign qubit leak, Rule 6),
; NEVER dirty-freed and NEVER `_unc`'d against a non-recoverable source. This is
; the conservative, safe handling — not a decline (over-declining would also be
; safe, but the existing spine simply skips the non-linear chain).
; SINCE bd r2j3.7 the whole-DAG half above still holds, but the dead smin is an
; ORPHAN and the M-B interior partition discharges it right after its mint, reading
; the live sources' current labels (no shared prefix is reversed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The forward smin still lowers; the live add consumes the fan-out source.
; CHECK:     %[[MIN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_smin_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; bd r2j3.7: an ORPHAN dead template rail (no user) that the whole-DAG spine
; leaves is now an M-B interior candidate, discharged right after its mint
; while its parents are provably unmoved (`isInteriorTerminalHandle` (I2)/(I4)).
; That reads the shared parent's CURRENT label and never reverses the shared
; prefix, so it is not the double-uncompute this file guards against.
; CHECK-NEXT: call void @cq_template_smin_i32_unc(i32 %[[MIN]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[MIN]])
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The shared source chain is NOT reversed and no OTHER rail is freed (no
; dirty/double free): nothing after the measure.
; (Named as CALLS: since r2j3.7 the module also DECLARES both symbols.)
; CHECK-NOT: call void @cq_template_smin_i32_unc
; CHECK-NOT: call void @cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.smin.i32(i32, i32)

define i32 @example(i32 %u, i32 %v) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.smin.i32(i32 %q, i32 %s)   ; dead (only the phi reads it)
  %d = add i32 %q, 1                              ; %q fans out to a LIVE op
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
