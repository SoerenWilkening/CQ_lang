; control_phase_kickback_abort_global_phase.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-2 (an OVER-DECLINE
; the round-1 F-L5-6 fix introduced, and a "LATENT / unreachable at HEAD" claim
; that was measurably false).
;
;     void abort(void);
;     int slice(int u){ int q = u; cq_theta(&q, 0.5);
;       if (q == 5) abort();     // the 7.2 abort park
;       cq_phi(0.75);            // UNCONDITIONAL — a GLOBAL phase; D2 DELETES it
;       return cq_measure(q); }
;
; `clang -O1` output verbatim. At `c4bd888` this DECLINED
; `cq controlled lowering: phase-class value escaping under quantum control`,
; while the SAME program with the `cq_phi` one line EARLIER compiled, and the
; round-1 binary compiled BOTH to the identical 8-line trace. A statement the
; compiler is REQUIRED to delete made a compiling program stop compiling.
;
; ROOT CAUSE. `AbortParkEmit::lineageCarriesPhase` asks
; `functionCarriesBranchPhase`, whose header promises "CONTROL-DEPENDENT ON a
; tainted branch" and whose first implementation asked
; `reachedThroughTaintedBranch` — `deleteGlobalPhases`' Rule-1 assert, which
; answers the strictly weaker "is a tainted branch ANYWHERE on ANY path reaching
; this block". That crudeness is SOUND at P7's slot (every tainted `br` is by
; then claimed-and-erased or declined, so the honest answer is always "no") and
; UNSOUND at the three carriers' slot, which is BEFORE `lowerControlRegions`
; while every tainted `br` still stands.
;
; THE FIX AND ITS ONE SUBTLETY. `controlDependentOnTaintedBranch` is the textbook
; predicate — `BB` post-dominates a successor of the tainted branch and does not
; post-dominate the branch — with post-dominance read over RETURNING paths only,
; so the park's own `unreachable` arm decides nothing. That last clause is not a
; convenience — the classical CFG says the abort arm does not continue, while the
; EMITTED circuit routes `q` into a graveyard rail and runs the remainder
; COHERENTLY ON EVERY BRANCH — so a phase after a park really is global, and a
; textbook post-dominance query (which treats the `unreachable` block as its own
; root) would have answered "control-dependent" and kept the decline.
;
; WHAT THIS FILE ASSERTS is the whole park circuit with NO Rz anywhere: the
; global phase is gone, by deletion and not by diagnostic (owner decision D2,
; owner question Q2's assumed answer: no remark). The trace of this program is
; BYTE-IDENTICAL to the same source with the `cq_phi` line removed by hand — that
; is the e2e-level witness this file stands in for.
;
; THE FENCE IS STILL A DISCRIMINATOR, not a blanket:
; `control_phase_kickback_reject_abort_branch_phase.ll` is the same park reached
; by a GENUINE branch phase and still declines, from plain `clang -O1` C.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The 7.2 park, in full: the flag, the graveyard rail, the route, the tape write.
; CHECK: %[[T:.*]] = call i32 @cqrt_tape_alloc()
; CHECK: %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[G:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[G]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[T]], i32 %[[F]])
; CHECK: %[[M:.*]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]

; The park frees NOTHING (the flag is the tape's, `q` is the measure's, the
; graveyard rail is left allocated — Rule 6). An extra `cqrt_free` here would be
; a hidden measurement.
; FCNT-NOT: call void @cqrt_free(

; And no polarity bracket: the park's arm is the TRUE successor.
; XCNT-NOT: call void @cqrt_x(i32

; ⭐ WHOLE-FILE PURE-NEGATIVE: NO Rz OF ANY WIDTH. The global phase is DELETED,
; which is the finding — this file is red at `c4bd888` on the RUN line itself
; (the pass exits non-zero), and green only once the carrier asks control
; dependence.
; NOROUTE-NOT: call void @cqrt_rz_i1(
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: !cq.branchphase
; NOROUTE-NOT: fneg

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %2, 5
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  tail call void @abort() #3
  unreachable

5:                                                ; preds = %1
  tail call void @cq_phi(double noundef 7.500000e-01) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @abort() local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
attributes #3 = { noreturn nounwind }
