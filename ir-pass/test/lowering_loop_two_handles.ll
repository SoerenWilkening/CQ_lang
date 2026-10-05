; lowering_loop_two_handles.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): TWO independent
; persistent rails threaded through one classically-bounded loop, `clang -O1`
; output (attribute groups and metadata trimmed) for
;
;     void two(double s1, double s2, int n) {
;       double q = s1; cq_theta(&q, 0.5);
;       double p = s2; cq_theta(&p, 0.3);
;       for (int i = 0; i < n; i++) { cq_theta(&q, 0.1); cq_theta(&p, 0.2); }
;       cq_measure(q); cq_measure(p);
;     }
;
; Each rail is an independent in-place self-cycle (its own header phi, its own
; `cq_theta` root) and collapses INDEPENDENTLY to its own loop-invariant handle:
; the railRoot fixpoint tracks the two roots separately and never merges them.
; clang orders the header phis p-first (`%14` is p, `%15` is q) while the body
; rotates q first, so a collapse that paired phis by position rather than by
; root would swap the angles. Pins that the per-rail collapse does not
; cross-contaminate: each `cqrt_ry` fires on its own handle with its own angle.
;
; History: written for the pre-3qlq register form `q = cq_phi(q, 0.1); p =
; cq_phi(p, 0.2);` (in-place Rz) in the body. The 3qlq migration deleted both as
; uncontrolled phases and left the body empty; bd jttf (2026-10-05) re-spelled
; them as the in-place Ry gates above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; Two mints + two Ry in the preheader:
; CHECK-LABEL: define void @two(
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[HQ]], double 5.000000e-01)
; CHECK-NEXT: %[[HP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %1)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[HP]], double 3.000000e-01)
; CHECK-NEXT: %[[G:[0-9]+]] = icmp sgt i32 %2, 0
; CHECK-NEXT: br i1 %[[G]], label %[[LOOP:[0-9]+]], label %[[EXIT:[0-9]+]]
; Both rails measured at exit, each on its own handle:
; CHECK:      {{^}}[[EXIT]]:
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[HQ]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[HP]])
; CHECK-NEXT: ret void
; The rolled body: each rail rotated in place with its own angle:
; CHECK:      {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[HQ]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[HP]], double 2.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32 %{{[0-9]+}}, %2
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[EXIT]], label %[[LOOP]]
;
; Whole-module negatives: all four rail phis gone, nothing freed:
; NEG-NOT: phi double
; NEG-NOT: cq_theta_f64
; NEG-NOT: cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define void @two(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #2
  %5 = tail call double @cq_theta_f64(double noundef %1, double noundef 3.000000e-01) #2
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %12, label %7

7:                                                ; preds = %12, %3
  %8 = phi double [ %4, %3 ], [ %16, %12 ]
  %9 = phi double [ %5, %3 ], [ %17, %12 ]
  %10 = tail call double @cq_measure_f64(double noundef %8) #3
  %11 = tail call double @cq_measure_f64(double noundef %9) #3
  ret void

12:                                               ; preds = %3, %12
  %13 = phi i32 [ %18, %12 ], [ 0, %3 ]
  %14 = phi double [ %17, %12 ], [ %5, %3 ]
  %15 = phi double [ %16, %12 ], [ %4, %3 ]
  %16 = tail call double @cq_theta_f64(double noundef %15, double noundef 1.000000e-01) #2
  %17 = tail call double @cq_theta_f64(double noundef %14, double noundef 2.000000e-01) #2
  %18 = add nuw nsw i32 %13, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %7, label %12
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr

declare double @cq_measure_f64(double noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
