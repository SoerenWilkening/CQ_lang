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
;
; bd dm7f.83 (ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16): FLIPPED TO
; LOUD. A classical-immediate in-place site here is refused by the M-C fence
; (`inPlaceFenceHolds`, G7: an earlier reader of the register has an obligation
; not yet settled, so in place could corrupt that reader's adjoint (a late
; discharge of the dead parent after its readers' adjoints is the build)) while
; its handle is a DEAD USER REGISTER (register-level: no later read, rotation
; or measure of its rail under any SSA name, `registerLiveAfter`, bd dm7f.83.3)
; beside a KEPT result, so out of place would leave the old rail beside the
; result, the r2j3.33 hazard class. MEASURED (laneL/dm7f83_flips.md): in THIS
; fixture that fallback was observably correct (the record is only measured, or
; every later Ry on it cancels, or its which-path information already sits in
; another kept rail), so this decline is the ruling's, an over-decline until
; the refusal is lowered. The in-place round now fails
; loudly (InPlaceQQImm.cpp), as owner Q1 requires. The fixture's original
; expectation is kept dormant: its RUN lines are spelled MC-CMD and no RUN line
; reads its CHECK prefixes. RETIREMENT: restore them when the refused shape
; converts (G7's lowering, named above).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DM7F83
; DM7F83: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
;
; MC-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; MC-CMD: %filecheck %s < %t.cqd0.ll
;
; The forward smin still lowers; the live add consumes the fan-out source.
; CHECK:     call i32 @cq_template_smin_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; The dead smin chain is NOT reversed and NO rail is freed (no dirty/double free).
; CHECK-NOT: cq_template_smin_i32_unc
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
