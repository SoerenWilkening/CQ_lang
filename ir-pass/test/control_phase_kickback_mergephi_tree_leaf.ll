; control_phase_kickback_mergephi_tree_leaf.ll — ACCEPT (bd `4aiu`, Track P).
; THE INTERIOR-LEAF WIDENING: a prep merge φ as a LEAF of a compound condition
; tree (`if (b1 && q > 3) cq_phi(φ);`) rather than as the tree's ROOT.
;
; ⚠ THIS IS THE RETIREMENT OF TRACK M's `V == Root` CONJUNCT, and that conjunct
; was a SCOPE decision with a written trigger (L8 — they work): "the increment
; that widens this must flip `control_swap_reject_select_mergephi_tree_leaf.ll`
; from a decline to an accept and derive its stream from the pass output — do not
; delete that fixture, re-derive it." Done: that file is now
; `control_swap_accept_select_mergephi_tree_leaf.ll` (`git mv`, contents
; re-derived), and this is its PHASE twin.
;
; THE EMITTER NEEDED ONE CLAUSE AND NO NEW STREAM. An interior φ takes exactly
; the path an interior RAIL leaf has taken since bd 3qlq.4: `CondTreeEmit` maps
; the leaf to ITSELF (`FlagOf[V] = V`, nothing minted) and the AND node reads it
; as a READ-ONLY CONTROL of `cqrt_toffoli`. Measured on the ORACLE with the φ
; already RAUW'd to its theta (probe `trackP/probes/p18.ll`, 18 trace lines):
; identical gates, identical order.
;
; UNITARY: `g = |0⟩`; `cqrt_toffoli(b1, cmp, g)` sets `g = b1 ∧ (q>3)`, a
; permutation of read-only controls; `cqrt_rz_i1(g, φ)` phases exactly that
; branch; the SAME toffoli (self-inverse) returns `g` to `|0⟩` on EVERY branch,
; which is what makes `cqrt_free(g)` a proven-`|0⟩` free (Rule 6). The user's
; register `h2` is read ONLY as a control — never `cqrt_x`-bracketed, never freed.
;
; ⚠ RED ON THE ORACLE: `control flow` (the grammar refused the φ, and the
; `IsCondTree` split correctly reported a TREE rather than a bare `i1`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TOFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  %c = icmp sgt i32 %q, 3
  %and = and i1 %b1, %c
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HQ]], i32 3)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[HQ]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; TOFCNT-COUNT-2: call void @cqrt_toffoli(
; TOFCNT-NOT: call void @cqrt_toffoli(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
