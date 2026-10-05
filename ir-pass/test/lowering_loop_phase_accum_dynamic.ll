; lowering_loop_phase_accum_dynamic.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): the
; DYNAMIC-bound in-place rotation accumulator, `clang -O1` output (attribute
; groups and metadata trimmed) for
;
;     double accum(double seed, int n) {
;       double q = seed; cq_theta(&q, 0.5);
;       for (int i = 0; i < n; i++) cq_theta(&q, 0.1);
;       return cq_measure(q);
;     }
;
; It lowers ROLLED IN PLACE, IDENTICALLY to the const bound (A1). This is the
; central reversal vs. the old "prove K at compile time" rule (owner decision
; 2026-06-24): the trip count need NOT be a compile-time constant; a dynamic but
; CLASSICAL bound runs the body the right number of times at runtime.
;
; A possibly-zero-trip bound emits a zero-trip GUARD (`if (n>0) goto loop`) and
; therefore TWO tainted phis: the loop-carried HEADER phi `%10` AND the
; zero-trip/exit MERGE phi `%6 = phi [%3, %2], [%11, %8]` in the exit block
; (n<=0 ⇒ the unrotated `%3`; n>0 ⇒ the loop result `%11`). BOTH denote the one
; persistent rail and BOTH collapse to the `cq_theta` mint `%3` (the rail's
; preheader incoming peels to the mint; the exit phi's every incoming peels to
; the mint's rail). Without the exit-phi collapse this would still decline at
; `declineClassicalMuxes` (kMsgClassicalPhi).
;
; History: written for the pre-3qlq register form `q = cq_phi(q, 0.1)` (an
; in-place Rz) in the body. The 3qlq migration deleted it as an uncontrolled
; phase and left the body empty; bd jttf (2026-10-05) re-spelled the body gate as
; the in-place Ry above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; Mint + Ry in the preheader (entry), in place; the classical zero-trip guard is
; UNTOUCHED (a classical condition over `%1`):
; CHECK-LABEL: define double @accum(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[G:[0-9]+]] = icmp sgt i32 %1, 0
; CHECK-NEXT: br i1 %[[G]], label %[[LOOP:[0-9]+]], label %[[EXIT:[0-9]+]]
; The exit measures the ONE handle on BOTH entries (zero-trip and loop exit):
; CHECK:      {{^}}[[EXIT]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NEXT: ret double %[[M]]
; The rolled body: ONE in-place Ry on the loop-invariant handle:
; CHECK:      {{^}}[[LOOP]]:
; CHECK-NEXT: %[[I:[0-9]+]] = phi i32 [ %{{[0-9]+}}, %[[LOOP]] ], [ 0, %{{[0-9]+}} ]
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 1.000000e-01)
; CHECK-NEXT: %[[INEXT:[0-9]+]] = add nuw nsw i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[0-9]+]] = icmp eq i32 %[[INEXT]], %1
; CHECK-NEXT: br i1 %[[DONE]], label %[[EXIT]], label %[[LOOP]]
;
; Whole-module negatives: BOTH rail phis are GONE; no free, no uncompute:
; NEG-NOT: phi double
; NEG-NOT: cq_theta_f64
; NEG-NOT: cq_measure_f64
; NEG-NOT: cqrt_free
; NEG-NOT: double -1.000000e-01
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define double @accum(double noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %8, %2
  %6 = phi double [ %3, %2 ], [ %11, %8 ]
  %7 = tail call double @cq_measure_f64(double noundef %6) #3
  ret double %7

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %12, %8 ], [ 0, %2 ]
  %10 = phi double [ %11, %8 ], [ %3, %2 ]
  %11 = tail call double @cq_theta_f64(double noundef %10, double noundef 1.000000e-01) #2
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, %1
  br i1 %13, label %5, label %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr

declare double @cq_measure_f64(double noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
