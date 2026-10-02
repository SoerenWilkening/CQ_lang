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
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is
; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the
; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns
; the flag to |0> on every branch, and the flag is freed.  The fixture's
; PURPOSE (its header above) is unchanged.
;
; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's
; own Inc-1 output, so keeping it would assert something false.  A `-NOT`
; that used to sit AFTER a positive of its prefix was WINDOWED to the text
; past that positive; re-measuring it whole-file is a strictly stronger
; question, and where the pattern is one of the counted ones the
; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the
; window it replaces, not weaker.
;   * call void @cqrt_rz_i1(   [superseded by the ACNT count]
;   * call void @cqrt_free(   [superseded by the FCNT count]
;   * call void @cqrt_x(   [superseded by the XCNT count]
;   * !cq.branchphase
;
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  br label %L

L:
  %i = phi i32 [ 0, %entry ], [ %inext, %L ]
  ; the FORWARD gate on the SAME rail, inside the cycle — asked by NEITHER prong
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %L

exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @example(i32 %u0, i32 %u1, i32 %n) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double -2.500000e-01)
; bd 5c5b (libcqops vmz9): the dead `%r` root is reverse-played back to its
; runtime seed |u1>, not |0>, so it is kept allocated: no free follows its Ry-dagger.
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: br label %L
; CHECK: L:                                                ; preds = %L, %entry
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %entry ], [ %inext, %L ]
; CHECK-NEXT: %[[INEXT:[a-zA-Z0-9_.]+]] = add i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[INEXT]], %n
; CHECK-NEXT: br i1 %[[DONE]], label %exit, label %L
; CHECK: exit:                                             ; preds = %L
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M2]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: _controlled
;   ^ the kickback gate is UNCONTROLLED, on the flag ancilla
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: double -3.000000e-01
; NOROUTE-NOT: double 0xBFD3333333333333
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
