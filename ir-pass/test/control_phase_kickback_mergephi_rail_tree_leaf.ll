; control_phase_kickback_mergephi_rail_tree_leaf.ll — ACCEPT (bd `4aiu`, Track P).
; A MIXED tree: one prep merge φ AND one plain `cq_theta_i1` RAIL leaf conjoined
; (`if (b1 && b2) cq_phi(φ);`).
;
; It is the pin that the two leaf KINDS compose. `Tree.RailLeaves` and
; `Tree.RailPhiLeaves` are separate fields with separate element TYPES (bd `boi6`
; H-3 — the type is the enforcement), each gets its own ladder in
; `classifyPhaseKickback` (step 5b for the rail, step 5c for the φ), and BOTH
; seed the SAME `Prov` set that rung (iii) walks. `CondTreeEmit` then maps each
; to ITSELF and the AND node reads both as READ-ONLY controls of one
; `cqrt_toffoli` — one ancilla, one `rz`, one self-inverse undo, one
; proven-`|0⟩` free (Rule 6).
;
; ⚠ NEITHER user register is minted from, bracketed or freed. `h1` (`b2`) and
; `h2` (the prepped `b1`) are both left ALLOCATED — `Ry(θ)|0⟩ ≠ |0⟩`.
;
; ⚠ RED ON THE ORACLE: `control flow` at `59ac5b7` (the ROOT-ONLY grammar refused
; the φ, and the `IsCondTree` split correctly reported a TREE).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %b2 = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  %and = and i1 %b1, %b2
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 1.100000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[HB2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[HB2]], double 9.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[HB2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 1.100000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[HB2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; NOX-NOT: cqrt_cnot
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
