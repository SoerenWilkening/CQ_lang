; lowering_reject_loop_rail_fanout_rot.ll — DECLINE (the PRE-EXISTING rotation-path
; twin of the dtzb fan-out finding; Rule-13 review 2026-06-26). The same Rule-8
; fan-out over a Case-A PHASE rail: `%qh` is read by two in-place `cq_phi` (Rz)
; gates — `%qn = Rz(1)` carried + `%qm = Rz(2)` escaping:
;     double q = cq_theta(seed, 0.5);
;     for (int i = 0; i < n; i++) { qn = cq_phi(q, 1); qm = cq_phi(q, 2); q = qn; }
;     return cq_measure(qm_last);
; Before the fan-out guard, tryCaseA ACCEPTED this and collapsed BOTH gates onto the
; one rail handle — `cqrt_rz_f64(%h, 1); cqrt_rz_f64(%h, 2)` = Rz(3) applied — so the
; measure reads Rz(3) on q, NOT the source's Rz(2) (and the carried rail is Rz(1+2)
; not Rz(1)). A verify-clean silent miscompile that PREDATES dtzb (the rotation
; closure gap the value path newly exposed). The single fan-out guard closes BOTH
; the value (add/xor) and rotation (cq_phi/rz) paths. LOUD decline; mirror
; CHARACTER-FOR-CHARACTER (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried rail has multiple in-place consumers
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NORZ
; NORZ-NOT: cqrt_rz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @fanout_rot(double %seed, i32 %n) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = phi double [ %q0, %entry ], [ %qn, %loop ]
  %qn = call double @cq_phi_f64(double %qh, double 1.000000e+00)  ; carried Rz
  %qm = call double @cq_phi_f64(double %qh, double 2.000000e+00)  ; FAN-OUT, escapes
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %ans = phi double [ %q0, %entry ], [ %qm, %loop ]
  %m = call double @cq_measure_f64(double %ans)
  ret double %m
}
