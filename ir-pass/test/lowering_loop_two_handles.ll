; lowering_loop_two_handles.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): TWO independent
; persistent rails threaded through one classically-bounded loop
;     double q = cq_theta(s1, 0.5);  double p = cq_theta(s2, 0.3);
;     for (int i = 0; i < n; i++) { q = cq_phi(q, 0.1); p = cq_phi(p, 0.2); }
;     cq_measure(q); cq_measure(p);
; Each rail is an independent in-place self-cycle (its own header phi, its own
; `cq_theta` root) and collapses INDEPENDENTLY to its own loop-invariant handle —
; the railRoot fixpoint tracks the two roots separately and never merges them.
; Pins that the per-rail collapse does not cross-contaminate (each `cqrt_rz` fires
; on its own handle with its own angle).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Two mints + two Ry in the preheader:
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %s1)
; CHECK:      call void @cqrt_ry_f64(i32 %[[HQ]], double 5.000000e-01)
; CHECK:      %[[HP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %s2)
; CHECK:      call void @cqrt_ry_f64(i32 %[[HP]], double 3.000000e-01)
; The rolled body: each rail rotated in place with its own angle:
; CHECK:      loop:
; CHECK:        call void @cqrt_rz_f64(i32 %[[HQ]], double 1.000000e-01)
; CHECK:        call void @cqrt_rz_f64(i32 %[[HP]], double 2.000000e-01)
; Both rails measured at exit; both rail phis gone:
; CHECK:      exit:
; CHECK:        call double @cqrt_measure_f64(i32 %[[HQ]])
; CHECK:        call double @cqrt_measure_f64(i32 %[[HP]])
; CHECK-NOT:  phi double
; CHECK-NOT:  cq_phi_f64
; CHECK-NOT:  cqrt_free

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define void @two(double %s1, double %s2, i32 %n) {
entry:
  %q0 = call double @cq_theta_f64(double %s1, double 5.000000e-01)
  %p0 = call double @cq_theta_f64(double %s2, double 3.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = phi double [ %q0, %entry ], [ %qn, %loop ]
  %ph = phi double [ %p0, %entry ], [ %pn, %loop ]
  %qn = call double @cq_phi_f64(double %qh, double 1.000000e-01)
  %pn = call double @cq_phi_f64(double %ph, double 2.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %qx = phi double [ %q0, %entry ], [ %qn, %loop ]
  %px = phi double [ %p0, %entry ], [ %pn, %loop ]
  call double @cq_measure_f64(double %qx)
  call double @cq_measure_f64(double %px)
  ret void
}
