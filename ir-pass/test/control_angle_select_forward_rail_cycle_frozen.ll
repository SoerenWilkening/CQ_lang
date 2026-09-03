; control_angle_select_forward_rail_cycle_frozen.ll — ACCEPT, and it pins a GAP
; rather than a guarantee: S7's three prongs do NOT ask about the rotated
; register's rail FORWARD of the consumer, so a cycle carrying a later gate on the
; SAME rail lowers.
;
; *** ROUND-2 RULE-13 REVIEW, lens R1 item 2 (bd drbq Inc 2b). *** The round-1
; fix widened S7 from "`LI->getLoopFor` of `Cond`/`Sel`/`T`'s blocks" to three
; prongs and its comment claimed S7 "now asks all three questions, ORed,
; over-declining by construction", with the `Exclude = T` rationale reading
; "nothing about the consumer's position is lost by the exclusion". Both sentences
; are FALSE OF THE RAIL PAST `T`, and this fixture is the shape that shows it:
;
;   * prong (i)/(ii) ask three ANCHOR blocks — `Cond`, `Sel`, `T` are all in
;     `entry`, which is on no cycle;
;   * prong (iii) asks the rotated register's wire closure, which carries
;     `Exclude = T` and therefore STOPS at the consumer — so `%g`, the `cq_phi` on
;     `%t` inside the loop, is not a member and is never asked about.
;
; The gate below is on the SAME PHYSICAL RAIL as the controlled rotation (after
; `lowerRotations` both are `%h1`), it executes an unbounded number of times, and
; nothing in this classifier looks at it. Note this is NOT about irreducibility:
; the cycle here is a perfectly ordinary NATURAL loop that `LoopInfo` sees. The
; blind spot is the `Exclude = T` boundary, not the loop recognizer.
;
; *** WHY IT IS SOUND, AND WHY THE SILENCE IS NOT 2b's TO OWN — MEASURED, NOT
; *** ARGUED. The manual by-difference twin of this program
; (`r = R(r,B); if (c) r = R(r,A-B);`, an Inc-2a in-place diamond) is ACCEPTED BY
; THE PRE-2b BINARY, and its emitted `@example` body is BYTE-IDENTICAL to what
; this file pins — same gates, same rails, same order, same frozen-rail
; disposition. So the property that reads alarming here (the plain UNCONTROLLED
; program `t = cq_phi(r, 0.9)` over the same cycle declines LOUDLY, `cq uncompute:
; tainted handle live range crosses a loop backedge`, on BOTH binaries) is
; produced by Inc-1's STRUCTURAL FREEZE — `ChainWalk::railCarriesControlledRotation`
; stops the whole-DAG uncompute spine walking a rail that carries a controlled
; rotation — and it reproduces on the oracle without any 2b code in the build.
; 2b turns no loud decline into silence here; it reaches the same already-shipped
; disposition through a different front door.
;
; WHAT THAT LEAVES: the rail is FROZEN, so it is never reverse-played and never
; freed — left allocated, which is the Rule-6 safe direction (a qubit leak in the
; qubits-not-scarce regime, never a dirty free). The negatives below pin exactly
; that: no adjoint of the unconditional twin, and no `cqrt_free` of the rotated
; rail. A future change that "tidies up" the freeze would redden this file, which
; is the whole reason it is committed as an ACCEPT rather than left in a report.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`) — it declines every angle select. The twin above is what accepts there.
;
; Reproducers from the round-2 review, lens R1
; (`review2b_r2/R1/probes/s7/{fwd,nat}_sel_{ry,rz}.ll`), re-derived without the
; scaffolding block in `fix2b_r2/probes/fwdcycle_{sel,twin,plain}.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_phi_si32(i32 %r, double %ang)
  br label %L

L:
  %i = phi i32 [ 0, %entry ], [ %inext, %L ]
  ; the FORWARD gate on the SAME rail, inside the cycle — asked by NEITHER prong
  %g = call i32 @cq_phi_si32(i32 %t, double 1.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %L

exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; the UNCONDITIONAL twin at B = 0.3
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the by-difference controlled gate, fl(0.9 - 0.3)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: br label %L
; THE UNASKED GATE: inside the cycle, on the rotated rail %[[R]], and reached only
; around the back edge. This line IS the finding.
; CHECK:      call void @cqrt_rz_i32(i32 %[[R]], double 1.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])
; nothing rotates after the measurement (the L6-N11 trailing window)
; CHECK-NOT:  call void @cqrt_ry_
; CHECK-NOT:  call void @cqrt_rz_

; The FROZEN rail, pinned by two absences. `%[[R2]]` re-binds the rotated
; register's alloc for this prefix's own variable scope.
; NOROUTE:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; the adjoint of the unconditional twin — the half-reversal a broken freeze emits,
; and the one an ordinary rotation's spine knows how to invert
; NOROUTE-NOT: double -3.000000e-01
; NOROUTE-NOT: double 0xBFD3333333333333
; the rotated rail is LEFT ALLOCATED, never freed (Rule 6: it is not provably |0>)
; NOROUTE-NOT: call void @cqrt_free(i32 %[[R2]])
; and no route was built
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: select

; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; exactly one free in the whole module — the FLAG's. The rotated rail is frozen.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
