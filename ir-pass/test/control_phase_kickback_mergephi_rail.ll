; control_phase_kickback_mergephi_rail.ll — ACCEPT (bd `3qps`, Track P). THE
; HEADLINE CUSTOMER: `bool b1 = 0; if (b0) cq_theta(&b1, θ); if (b1)
; cq_phi(φ);` — the register-free BRANCH PHASE controlled on a preceding
; controlled state PREP's MERGE φ.
;
; ⚠ RED ON THE ORACLE, AND THAT IS THE POINT. At `59ac5b7` this declined
; `branch phase on a bare i1 condition`: `isCondRailLeaf` admits a `cq_theta_i1`
; CALL and a `PHINode` was off-grammar, so the kickback never asked whether the
; φ was a register. It always was one — bd `boi6` / Track M measured the `int`
; twin ACCEPTING with a COMPARE over the same φ (probe `m26`, 25 lines), which is
; why this was filed as a LEAF-GRAMMAR over-decline and NOT as bd `drbq.7`'s wire
; fence. The fix admits the φ through the SAME predicate the 4.4 data select uses
; — `preppedRailPhiRegionIdx`, CALLED, never re-derived (Rule 14).
;
; THE EMITTED STREAM IS THE SHIPPED RAIL STREAM, BYTE FOR BYTE. A φ is just
; another `Value *` control to `emitKickbackGroup`, so the widening adds an
; ACCEPT and not a STREAM. The discriminator is
; `control_phase_kickback_rail_after_prep.ll` — the same module AFTER the prep's
; M-β, which the ORACLE already accepts with these very gates.
;
; UNITARY, checkable without running anything (Rule 2). The prep leaves
; `Σ_x α_x |x⟩_{b0} ⊗ |β(x)⟩_{b1}`; `cqrt_rz_i1(h_{b1}, φ)` is DIAGONAL in `b1`'s
; basis, so it multiplies exactly the `|b1 = 1⟩` component by `e^{iφ}` — which is
; what the source says. NOTHING is minted, stripped or freed: the register IS the
; flag (Rule 7's kickback), and NO `cqrt_x` ever touches a user register.
; `h1` is left ALLOCATED (Rule 6 — `Ry(θ)|0⟩ ≠ |0⟩`, so it is never freed dirty).
;
; ⚠ THE EMISSION ORDER IS THE OPPOSITE OF THE 4.4 SELECT'S, and it is what makes
; this emitter need no re-read of a RAUW'd condition. A kickback has real block
; fields, so the bd `hcrg` alias pre-flight sees that its `Pred` IS the prep's
; `MergeBB` and takes the sanctioned `sequentialChainAlias` edge
; `Precedes[kickback] = {prep}`: the KICKBACK is emitted FIRST, while the φ is
; still live, and the prep's later M-β RAUW rewrites this gate's operand to the
; hoisted theta, which `lowerRotations` then RAUWs to the `i32` handle. That the
; φ must live in the kickback's own `Pred` is CHECKED, not assumed —
; `condWireDisposition` declines a cross-block condition
; (`control_phase_kickback_reject_mergephi_cross_block.ll`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHI < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; ---- Whole-file negatives, each in its OWN pure prefix (a positive line inside
; a negative prefix WINDOWS every negative after it — CLAUDE.md Rule 12(a)).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: cqrt_cnot
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
; PHI-NOT: = phi
