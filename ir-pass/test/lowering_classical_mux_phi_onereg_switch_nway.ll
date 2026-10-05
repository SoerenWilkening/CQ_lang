; lowering_classical_mux_phi_onereg_switch_nway.ll — ACCEPT: the N-ARY (N>2)
; one-register merge phi (test_C_libtooling-sbt1.3, Phase 7.1 Increment C). The
; natural classical N-way `switch` around an in-place quantum gate on ONE
; register, `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int main(int argc, char **argv) {
;       int q = 7; cq_theta(&q, 0.5);
;       switch (argc) {                   /* CLASSICAL scrutinee */
;       case 1: cq_theta(&q, 0.25);  break;
;       case 2: cq_theta(&q, 0.125); break;
;       default: break;
;       }
;       return cq_measure(q);
;     }
;
; It survives clang -O1 as a switch with one merge phi whose 3 incomings
; (`%3` straight from the default edge, `%5` and `%7` from the case arms) all
; denote the SAME register: each case's in-place Ry is emitted on %3's handle in
; its own case block, so the phi is a pure SSA renaming. The N-ary lift (the
; Increment C generalization of liftOneRegisterMergePhi) proves every edge's
; chain lives in its own case block AND no arm gate can reach the merge through
; ANY OTHER edge whose record omits it (the generalized (7a) over all j != i),
; then RAUWs the phi to the wire base and erases it.
;
; Rule-13 trace clearance: the scrutinee is CLASSICAL, so each shot takes
; exactly one case; the lift adds/moves/removes NO gate, only an SSA name
; disappears: no superposed control, no flag, no controlled gates.
;
; N==2 reduces EXACTLY to the prior `1-i` complement (the arity-2 fixtures
; lowering_classical_mux_phi_onereg*.ll); the third-edge hole a naive
; `1-i`-only extension would leave is pinned by
; lowering_reject_classical_mux_phi_onereg_nway_loop.ll.
;
; History: written for the pre-3qlq register form `case k: q = cq_phi(q, a_k)`.
; The 3qlq migration deleted both uncontrolled phases and left every case block
; empty; bd jttf (2026-10-05) re-spelled them as the in-place Ry gates above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ONE < %t.cqd0.ll
;
; ONE allocation (the single register), its Ry in entry, the switch untouched:
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: switch i32 %0, label %[[MERGE:[0-9]+]] [
; CHECK-NEXT: i32 1, label %[[A1:[0-9]+]]
; CHECK-NEXT: i32 2, label %[[A2:[0-9]+]]
; Each case keeps its own Ry, on the ONE handle:
; CHECK:      {{^}}[[A1]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: br label %[[MERGE]]
; CHECK:      {{^}}[[A2]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT: br label %[[MERGE]]
; The merge measures the ONE handle; the renaming phi is GONE:
; CHECK:      {{^}}[[MERGE]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
;
; Exactly ONE allocation in the module (count + negative of the same pattern,
; alone in its prefix):
; ONE-COUNT-1: call i32 @cqrt_alloc_i32(
; ONE-NOT:     call i32 @cqrt_alloc_i32(
; Whole-module negatives:
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; NEG-NOT: _controlled
; NEG-NOT: cqrt_free
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  switch i32 %0, label %8 [
    i32 1, label %4
    i32 2, label %6
  ]

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.500000e-01) #2
  br label %8

6:                                                ; preds = %2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01) #2
  br label %8

8:                                                ; preds = %2, %6, %4
  %9 = phi i32 [ %3, %2 ], [ %7, %6 ], [ %5, %4 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
