; lowering_classical_mux_phi_onereg_theta_chain.ll — ACCEPT: one-register
; merge phi whose arm chain is TWO in-place gates (test_C_libtooling-5j5, the
; theta-gate + multi-gate-chain variant). `clang -O1` output (attribute groups
; and metadata trimmed) for
;
;     int main(int argc, char **argv) {
;       int q = 7; cq_theta(&q, 0.5);
;       if (argc > 1) { cq_theta(&q, 0.125); cq_theta(&q, 0.25); }
;       return cq_measure(q);
;     }
;
; A tainted-operand cq_theta is IN PLACE: RotationLowering emits ry-only on the
; EXISTING handle (no second allocation, "chained theta") and RAUWs the result
; to its operand. So the wire resolution walks %7 -> %6 -> %3 through two
; collected gate call sites to the one base, and the whole chain sits in the arm
; block: entering via the arm edge implies both gates ran, this traversal, in
; block order; entering via the straight edge implies neither did. The phi is a
; pure renaming either way.
;
; Note the Ry is NON-diagonal and that is still fine HERE: the only downstream
; consumer is the measure of the merged value itself, whose per-path record
; matches the wire per path. A tainted PURE op reading the pre-gate base past
; the arm is a different shape and is already owned by `declineStaleRecordOps`
; (runs BEFORE this guard; WireWalk finds the arm theta forward of the base).
;
; History: pre-3qlq the arm's second gate was the register form
; `q = cq_phi(q, t3)` (an in-place Rz). The 3qlq migration deleted it as an
; uncontrolled phase and left a one-gate arm, the shape of
; lowering_classical_mux_phi_onereg.ll; bd jttf (2026-10-05) restored the
; two-gate chain with a second in-place Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[0-9]+]] = icmp sgt i32 %0, 1
; CHECK-NEXT: br i1 %[[C]], label %[[ARM:[0-9]+]], label %[[MERGE:[0-9]+]]
; Both arm gates stay inside the arm, in source order, on the SAME handle:
; CHECK:      {{^}}[[ARM]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: br label %[[MERGE]]
; CHECK:      {{^}}[[MERGE]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
;
; One allocation only (the chained thetas must NOT mint a second register):
; ONE-COUNT-1: call i32 @cqrt_alloc_i32(
; ONE-NOT:     call i32 @cqrt_alloc_i32(
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; NEG-NOT: cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #2
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %7, %5 ], [ %3, %2 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
