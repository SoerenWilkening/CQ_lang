; lowering_loop_phase_accum_const.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): the
; CONST-bound in-place phase accumulator
;     double q = seed; cq_theta(&q, 0.5);
;     for (int i = 0; i < 4; i++) q = cq_phi(q, 0.1);
;     return cq_measure(q);
; (pre-3qlq register form) lowers ROLLED IN PLACE. This was the headline Case A
; (the owner's phase accumulation / Trotterization shape). The uncontrolled phase
; is a global phase the 3qlq migration deleted, so the body is now empty and the
; loop-carried header phi is the pure self-cycle `%qh = phi [%q0, entry], [%qh,
; loop]`, rooted at the `cq_theta` mint `%q0`. A KNOWN-≥1-trip const bound has NO
; zero-trip guard and NO exit phi (verified on real `clang -O1` output, Rule 11).
;
; THE COLLAPSE (LoopLowering::tryCaseA): the in-place self-cycle header phi
; collapses to its single persistent rail (RAUW %qh -> %q0, erase) BEFORE
; rotation lowering. The loop CFG (backedge, classical induction) is PRESERVED;
; zero measurements inserted, zero in-body frees (the rail is measured after L).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Mint + Ry in the preheader (entry), in place:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %{{.*}})
; CHECK:      call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; The rolled loop CFG survives (its body is empty since 3qlq):
; CHECK:      loop:
; CHECK:        br i1 %{{.*}}, label %exit, label %loop
; The exit measures the ONE handle; the rail phi is GONE:
; CHECK:      exit:
; CHECK-NEXT:   call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NOT:  phi double
; CHECK-NOT:  cq_phi_f64
; CHECK-NOT:  cq_theta_f64
; Case A emits NO in-body free and NO uncompute (the rail is measured after L):
; CHECK-NOT:  cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @acck(double %seed) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]   ; classical induction
  %qh = phi double [ %q0, %entry ], [ %qh, %loop ] ; loop-carried rail (in-place self-cycle)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 4
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call double @cq_measure_f64(double %qh)
  ret double %m
}
