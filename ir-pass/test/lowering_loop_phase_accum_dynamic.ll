; lowering_loop_phase_accum_dynamic.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): the
; RUNTIME-bound in-place phase accumulator
;     double q = seed; cq_theta(&q, 0.5);
;     for (int i = 0; i < n; i++) q = cq_phi(q, 0.1);   // n a runtime param
;     return cq_measure(q);
; lowers ROLLED IN PLACE — IDENTICALLY to the const bound (A1). This is the
; central reversal vs. the old "prove K at compile time" rule (owner decision
; 2026-06-24): the trip count need NOT be a compile-time constant; a dynamic but
; CLASSICAL bound runs the body the right number of times at runtime.
;
; Verified against real `clang -O1` output (Rule 11): a possibly-zero-trip bound
; emits a zero-trip GUARD (`if (n>0) goto loop`) and therefore TWO tainted phis —
; the loop-carried HEADER phi `%qh` AND a zero-trip/exit MERGE phi `%qx = phi
; [%q0, entry], [%qn, loop]` in the exit block (n<=0 ⇒ the unrotated `%q0`; n>0 ⇒
; the loop result `%qn`). BOTH denote the one persistent rail and BOTH collapse to
; the `cq_theta` mint `%q0` (the rail's preheader incoming peels to the mint; the
; exit phi's every incoming peels to the mint's rail). Without the exit-phi
; collapse this would still decline at `declineClassicalMuxes` (kMsgClassicalPhi).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Mint + Ry in the preheader (entry), in place; the classical zero-trip guard is
; UNTOUCHED (a classical condition over `%n`):
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %{{.*}})
; CHECK:      call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:      br i1 %{{.*}}, label %loop, label %exit
; The rolled body: ONE in-place Rz on the loop-invariant handle:
; CHECK:      loop:
; The exit measures the ONE handle; BOTH rail phis are GONE:
; CHECK:      exit:
; CHECK-NEXT:   call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NOT:  phi double
; CHECK-NOT:  cq_phi_f64
; CHECK-NOT:  cq_theta_f64
; CHECK-NOT:  cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @accum(double %seed, i32 %n) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit         ; classical zero-trip guard

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = phi double [ %q0, %entry ], [ %qh, %loop ] ; loop-carried rail
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n                  ; classical exit condition
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %qx = phi double [ %q0, %entry ], [ %qh, %loop ] ; zero-trip / exit merge phi
  %m = call double @cq_measure_f64(double %qx)
  ret double %m
}
