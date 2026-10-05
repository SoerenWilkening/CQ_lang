; lowering_reject_break_phase_answer.ll — DECLINE (Phase 7.4 Inc 1, y05j.1; PRD-7.4
; §2.6, §2.10 phase-arm row): a classically-bounded loop with a tainted early break
; and a `cq_phi` phase in its body:
;     double q = seed; cq_theta(&q, 0.5);
;     for (int i = 0; i < n; i++) {
;         cq_phi(0.1);               // a branch phase inside the loop
;         if (q < 3.0) break;        // tainted break flag
;     }
;     return cq_measure(q);
;
; The fused exit `select(%brk, true, %bound)` is the 7.4 break shape. Before bd 3qlq
; the body was `q = cq_phi(q, 0.1)`, so the exit merge phi carried a PHASE-class
; answer that the §2.2 `cqrt_copy_<W>` (CNOT) capture would dephase (Rule 7), and
; this file pinned `early break preserves a phase answer`. Since 3qlq the loop fence
; fires first (note below); `lowering_reject_break_phase_answer_kickback.ll` pins
; the B3 string.
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
