; lowering_reject_loop_quantum_bound.ll — DECLINE (Phase 7.3 Inc 1, 799w.1; PRD
; §2.6, L1): a loop whose EXIT condition is a live tainted value
;     double q = seed; cq_theta(&q, 0.5);
;     while (q < 10.0) cq_phi(0.1);
;     return cq_measure(q);
; is a genuinely quantum/measurement-bounded loop — a runtime branch on a qubit,
; which would require coherent superposition over trip counts. PERMANENT decline
; for the trace-only / fixed-template model (the "unbounded / quantum-conditioned
; while" ROADMAP §"Beyond the freeze" parks).
;
; Verified against real `clang -O1` output (Rule 11): the exit `fcmp olt double
; %qh, 10.0` reads the live tainted register, so every EXITING block's
; condition is tainted (L1 fails). `lowerLoops` runs BEFORE `detectControlRegions`
; and partitions this out with the dedicated `loop under quantum control` message
; (rather than the generic `nested control flow under quantum control`
; ControlDetect would otherwise emit). LoopLowering OWNS the diagnostic via
; `diagnoseUnderControl(_, "loop")`; this CHECK mirrors it (Rule 12). Over-
; declining is always safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @qbound(double %seed) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %c0 = fcmp olt double %q0, 1.000000e+01
  br i1 %c0, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %qh = phi double [ %q0, %entry ], [ %qh, %loop ]
  call void @cq_phi(double 1.000000e-01)
  %c = fcmp olt double %qh, 1.000000e+01         ; TAINTED exit condition (q-derived)
  br i1 %c, label %loop, label %exit

exit:                                             ; preds = %entry, %loop
  %qx = phi double [ %q0, %entry ], [ %qh, %loop ]
  %m = call double @cq_measure_f64(double %qx)
  ret double %m
}
