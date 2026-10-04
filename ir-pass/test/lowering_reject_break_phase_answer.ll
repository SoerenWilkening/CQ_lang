; lowering_reject_break_phase_answer.ll — DECLINE (Phase 7.4 Inc 1, y05j.1; PRD-7.4
; §2.6, §2.10 phase-arm row): a classically-bounded loop with a tainted early break
; whose ESCAPING ANSWER is PHASE-class (an Rz / `cq_phi` accumulator):
;     double q = seed; cq_theta(&q, 0.5);
;     for (int i = 0; i < n; i++) {
;         q = cq_phi(q, 0.1);        // Rz — a relative phase
;         if (q < 3.0) break;        // compares the phase rail as data
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/v2_phase.ll): the
; fused exit `select(%brk, true, %bound)` is the SAME break shape as the value-arm
; accept, but the exit merge phi's loop incoming is a `cq_phi` (Rz) result — a
; PHASE answer. Such an answer cannot use the §2.2 `cqrt_copy_<W>` (CNOT) copy-out:
; a CNOT copies a basis label, not a phase, so the capture + reverse-play would
; DEPHASE the answer (the canonical method-B-on-a-phase-arm miscompile, Rule 7,
; P0 0.585->0.500). Moreover the break `fcmp` over an Rz rail is DEGENERATE: `Rz`
; does not change the computational-basis value, so the condition is
; iteration-invariant (fires at iteration 0 or never). PERMANENT decline (§2.6) —
; `tryBreak` classifies the merge-phi incoming lineage exactly as the 7.2
; `retLineageCarriesPhase` walk (Risk 5). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ 3qlq Inc 1 ROUND 2 (2026-09-05, merge be4e2ea): the B3 carrier string this file
; pinned is PRE-EMPTED for this module — after the round-2 carrier fix (F-R1-2:
; post-dominance over RETURNING paths; F-L5-6: the kickback-phased-register record)
; the loop fence `loop under quantum control` fires first. The disposition is still a
; LOUD DECLINE (never an accept); only the string moved. Whether ANY module can still
; reach `early break preserves a phase answer` is the clearance's question (fix_r1
; F-L5-6 recorded its reachability as UNCONFIRMED); until one is constructed this
; file pins the fence that actually fires. Orchestrator edit; measured on be4e2ea.
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @break_phase(double %seed, i32 %n) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi double [ %q0, %entry ], [ %q, %loop ]
  call void @cq_phi(double 1.000000e-01)  ; Rz — phase
  %brk = fcmp olt double %q, 3.000000e+00                       ; TAINTED break flag
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                                ; CLASSICAL bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound                ; FUSED exit
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi double [ %q0, %entry ], [ %q, %loop ]  ; PHASE-class incoming (%q = Rz)
  %m = call double @cq_measure_f64(double %ans)
  ret double %m
}
