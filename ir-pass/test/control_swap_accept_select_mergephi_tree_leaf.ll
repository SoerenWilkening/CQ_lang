; control_swap_accept_select_mergephi_tree_leaf.ll — ACCEPT (bd `4aiu`, Track P).
; WAS `control_swap_reject_select_mergephi_tree_leaf.ll` (bd `boi6` D-B / Track M,
; probe `m31`), a DECLINE that carried its own retirement trigger:
;
;   "The increment that widens `AllowRailPhi` past the root must flip THIS FILE
;    from a decline to an ACCEPT and derive its stream from the pass output
;    (expect the r9e5 non-root-rail network: one compare flag for `%cmp`, the RAIL
;    as a bare control, one `cqrt_toffoli` onto a fresh ancilla, stripped LIFO).
;    Re-derive it then; do not delete it."
;
; That prediction is CHARACTER-FOR-CHARACTER what the pass now emits, and the
; CHECK block below is derived from the pass output rather than from the
; prediction (L8 — retirement triggers work, and they are still not evidence).
; The file was `git mv`'d, not deleted.
;
; THE SHAPE: a prep merge φ as an INTERIOR leaf of a compound condition tree
; (`if (b1 && q > 3) …`), which `clang -O1` hands over as `and i1 %phi, %cmp`.
; Track M's grammar admitted a φ leaf ONLY as the tree's ROOT; bd `4aiu` drops
; that conjunct, so the φ is admitted at any position and asked rung
; 0/(i)/(ii)/(iii) per leaf exactly as a root φ is.
;
; ⚠ WHY THE EMITTER NEEDED NOTHING HERE. By the time `SelectMergeEmit` re-derives
; this tree, the prep's M-β has already RAUW'd the φ to the hoisted `cq_theta_i1`
; CALL, so `CondTreeEmit` sees an ordinary `isCondRailLeaf` rail at an interior
; position — the path shipped since bd 3qlq.4. (The PHASE consumer is the opposite
; case: it is emitted BEFORE the prep, so its φ is still a `PHINode` at emit time
; and `emitCondNetwork` needed one membership clause for it. Same grammar, two
; emission orders — see `control_phase_kickback_mergephi_tree_leaf.ll`.)
;
; UNITARY: `g = |0⟩`; `cqrt_toffoli(rail, cmpflag, g)` computes `b1 ∧ (q>3)` by a
; permutation of READ-ONLY controls; the two X-bracketed
; `cqrt_copy_i32_controlled` write `out = (g ? 2 : 5)` into a fresh `|0⟩` rail;
; the SAME toffoli returns `g` to `|0⟩` on every branch, which is what makes
; `cqrt_free(g)` a proven-`|0⟩` free (Rule 6). ⚠ BOTH `cqrt_x` are on the ANCILLA
; `g` — never on the prep rail and never on `%q` (the NOX prefix pins it).
;
; ⚠ RED ON THE ORACLE: `control flow` at `59ac5b7` (the ROOT-ONLY grammar).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TOFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOPHI < %t.cqd0.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %merge, label %arm
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %t, %arm ], [ false, %entry ]
  %c = icmp sgt i32 %q, 3
  %and = and i1 %p, %c
  %sel = select i1 %and, i32 2, i32 5
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %z1, %m2
  ret i32 %s
}

; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double -5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HQ]], i32 3)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[HQ]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ---- Whole-file negatives, each in its OWN pure prefix (Rule 12(a)).
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_rz
; NOX-NOT: cq_phi
; NOX-NOT: call i1 @cq_theta_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; TOFCNT-COUNT-2: call void @cqrt_toffoli(
; TOFCNT-NOT: call void @cqrt_toffoli(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT: call void @cqrt_x(
; NOPHI-NOT: = phi
