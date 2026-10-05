; lowering_classical_mux_phi_onereg.ll — ACCEPT: the ONE-REGISTER merge phi
; (test_C_libtooling-5j5, the headline lift). The natural classical-if-around-
; a-quantum-gate program, `clang -O1` output (below, attribute groups and
; metadata trimmed) for
;
;     int main(int argc, char **argv) {
;       int q = 7; cq_theta(&q, 0.5);
;       if (argc > 1) cq_theta(&q, 0.25);   /* CLASSICAL condition */
;       return cq_measure(q);
;     }
;
; The merge phi `%8 = phi [%6, %5], [%3, %2]` has two DISTINCT SSA incomings
; denoting the SAME register: the arm gate is an in-place Ry (`%6 = cq_theta(%3,
; .25)`), which rotation lowering emits on %3's handle AT THE CALL'S POSITION and
; RAUWs to its operand. The opaque call cannot be speculated, so clang never
; produces a select here.
;
; THE LIFT (TaintPropagation::liftOneRegisterMergePhi): both incomings
; tainted; both resolve through the in-place cq_theta arg-0 wire to the ONE
; base %3; the gate chain lives entirely in its edge's incoming block; no path
; can fire the arm gate and then enter the merge through the straight edge (no
; back edges). The phi is RAUW'd to %3 and ERASED before rotation lowering.
;
; Rule-13 trace clearance: the condition is CLASSICAL, so each shot runs one
; path; the lift adds/moves/removes NO gate, only an SSA name disappears. The
; arm's Ry stays INSIDE the arm block, so per shot the gate stream is exactly
; the executed source path's (Ry(0.25) fires iff argc > 1): no superposed
; control, no flag, no free.
;
; DECLINE complements (Rule 12): select_onereg (speculated gate), phi_tworeg
; (distinct registers), phi_derived_add (fresh template rail),
; phi_crossblock_chain (pre-branch gate), phi_loop (back-edge staleness),
; and the pinned wi5 mixed-incoming fixtures (phi_measured et al.).
;
; History: written for the pre-3qlq register form `if (c) q = cq_phi(q, θ);`,
; an in-place Rz in the arm. The 3qlq migration deleted that uncontrolled phase
; and left the arm empty; bd jttf (2026-10-05) re-spelled the arm gate as the
; in-place Ry above, which has the property under test (an in-place gate on the
; one register inside the arm). The two-gate arm is ..._onereg_theta_chain.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; Mint + Ry in entry, the classical branch untouched:
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[0-9]+]] = icmp sgt i32 %0, 1
; CHECK-NEXT: br i1 %[[C]], label %[[ARM:[0-9]+]], label %[[MERGE:[0-9]+]]
; The arm gate stays INSIDE the arm (the true successor), on the SAME handle:
; CHECK:      {{^}}[[ARM]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: br label %[[MERGE]]
; The merge measures the ONE handle; the renaming phi is GONE:
; CHECK:      {{^}}[[MERGE]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
;
; Whole-module negatives (own prefix, no positive to window them). ONE
; allocation; main-resident handle, so process exit reclaims it and no free is
; emitted; every front-end intrinsic is lowered:
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; NEG-NOT: cq_measure_si32
; NEG-NOT: cqrt_free
; NEG-NOT: _controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.500000e-01) #2
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
