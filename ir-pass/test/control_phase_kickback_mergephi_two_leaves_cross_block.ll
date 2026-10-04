; control_phase_kickback_mergephi_two_leaves_cross_block.ll — ACCEPT
; (bd `test_C_libtooling-hn29` case (2) == bd `test_C_libtooling-leyd`, Track P′).
;
; ⚠ TWO BEADS, ONE PROGRAM. `hn29` case (2) ("TWO prep φ conjoined when the second
; prep's diamond pushes the first φ out of `Pred`", probe `trackP/probes/p20.c`)
; and `leyd` ("two prep merge φs as the TWO LEAVES of one kickback tree", probe
; `trackX/probes/fp_x3_two_preps_two_phi_leaves.c`) were filed a session apart by
; two agents as different defects. The two `.c` files are the SAME program up to
; renaming and one angle, and both declined at the SAME site. Measured, not read.
;
; ⚠ AND `leyd`'s STATED FENCE WAS THE WRONG ONE — verify, do not inherit (Rule 11).
; It records the decline as firing on *"the WIRE fence (condWireDisposition /
; railCondWireDisposition) and therefore never reach[ing] the in-Pred grammar at
; all"*. It does not. For a TREE, `R.Condition` is the `select i1` ROOT, which IS
; in `Pred`, so `condWireDisposition`'s cross-block prong has no subject; what
; fired is `classifyPhaseKickback` step 6's per-leaf window, whose
; `P->getParent() != Region.Pred` conjunct IS the in-`Pred` grammar. The anchor
; `leyd` recorded (the `&&` select) is `declAnchor`, which both sites share, so the
; anchor alone could not tell them apart — the IR could, and did.
;
; THE SHAPE, straight off `clang -O1` on `p20.c` (this is that module by hand):
; `if (b0) cq_theta(&b1,.5); if (b0) cq_theta(&b2,.9); if (b1 && b2)
; cq_phi(.3);`. The SECOND prep's diamond owns the kickback's `Pred` (`m2`), so
; `%p2` is in `Pred` and `%p1` — the FIRST prep's merge φ — is one block back.
;
; THE UNITARY, checkable without running anything (Rule 2). Both preps leave
; `Ry(θ)|0⟩` rails controlled on `b0`; `cqrt_toffoli(h1, h2, g)` writes
; `b1 ∧ b2` into a FRESH `|0⟩` ancilla; `cqrt_rz_i1(g, .3)` is DIAGONAL, so it
; multiplies exactly the `b1 = b2 = 1` component by `e^{i·0.3}` — which is what the
; source says; the second `cqrt_toffoli` returns `g` to `|0⟩` on every branch, so
; its single `cqrt_free` is a proven-`|0⟩` one (Rule 6). `h1` and `h2` are read ONLY
; as toffoli CONTROLS — never `cqrt_x`-bracketed, never freed — and `h0` is never
; touched by the kickback at all.
;
; ⚠ THE `p20` SPELLING ALSO PINS THE ORDER, and it is the case where bd `hn29`'s
; premise happens to be TRUE: the hcrg chain (`kickback.Pred == prep2.MergeBB`,
; `prep2.Pred == prep1.MergeBB`) Kahn-sorts to kickback → prep2 → prep1 with no
; help from Track P′'s `PrepRegionIdxs` edge. The edge is what carries
; `…_reject_mergephi_cross_block.ll`, where no such chain exists. Both spellings
; must keep lowering; they exercise DIFFERENT halves of the increment.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHI < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm1, label %m1
arm1:
  %t1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %m1
m1:
  %p1 = phi i1 [ %t1, %arm1 ], [ false, %entry ]
  br i1 %b0, label %arm2, label %m2
arm2:
  %t2 = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %m2
m2:
  %p2 = phi i1 [ %t2, %arm2 ], [ false, %m1 ]
  %and = select i1 %p1, i1 %p2, i1 false
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %p1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H2]], double 9.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; ---- Whole-file negatives, each in its OWN pure prefix (a positive line inside
; a negative prefix WINDOWS every negative after it — CLAUDE.md Rule 12(a)).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: cqrt_cnot
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; TCNT-COUNT-2: call void @cqrt_toffoli(
; TCNT-NOT: call void @cqrt_toffoli(
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
; PHI-NOT: = phi
