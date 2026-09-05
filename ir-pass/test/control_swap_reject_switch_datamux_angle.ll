; control_swap_reject_switch_datamux_angle.ll — ***THIS FIXTURE NOW ACCEPTS.***
; It pinned a DECLINE from 4.5 WI-4 through the dugh/yn71 rework; bd
; `test_C_libtooling-drbq` Increment 2b lowers the shape. The name is kept for
; git continuity and because it is cited elsewhere — read `reject` as historical.
;
; THE SHAPE, unchanged: an all-`ConstantInt` DATA-MUX `switch` whose merge result
; is compared and used as a rotation ANGLE selector.
;     %rm  = phi [3, entry], [7, a0], [9, a1]     ; the data mux
;     %c   = icmp ne i32 %rm, 0
;     %ang = select i1 %c, double 0.9, double 0.3
;     cq_phi(%qx, %ang)
;
; *** THE TWO ANGLE ARMS WERE `double %a, double %b` — RUN-TIME PARAMETERS — AND
; *** ARE NOW THE CONSTANTS 0.9 / 0.3 (Rule-13 CLEARANCE review, finding F-11 /
; *** blocker B1; orchestrator decision: ship option (2), the angle-select accept
; *** narrows to CONSTANT arms). The shape this file exists to exercise — the yn71
; *** ONWARD-control fixpoint reaching a 2b region — is unchanged and is what the
; *** assertions below still pin. The RUN-TIME spelling now DECLINES and has its
; *** own file, `control_swap_reject_switch_datamux_angle_runtime.ll`, so this
; *** axis keeps both cells rather than losing one.
;
; WHY IT DECLINED, AND WHY THAT WAS RIGHT AT THE TIME. The mux phi has
; all-`ConstantInt` incomings, so SSA data-flow leaves it UNTAINTED; the dugh
; second propagation (`repropagateControlMerges`) re-seeds from the emitted
; `%out` rail and taints `%rm`, the `icmp`, and the select — after which the
; select's CONDITION is quantum and the angle it produces is entangled with the
; scrutinee. With no controlled-rotation lowering available, the only sound
; disposition was a loud decline: realizing that angle as a NUMBER would have been
; the f64/angle wrong unitary (Rule 3), and there was no pre-emit backstop.
;
; WHY IT ACCEPTS NOW, and the distinction is the whole point. 2b does not realize
; the angle at all. It splits the rotation by angle additivity into an
; UNCONDITIONAL `rz(qx, 0.3)` plus a CONTROLLED `rz_controlled(f, qx, fl(0.9-0.3))`
; whose control is the quantum predicate `[out != 0]` — i.e. it emits the
; controlled rotation the source actually describes. Every angle in the emitted
; stream is a CLASSICAL CONSTANT; no quantum value ever reaches an angle slot, and
; no qubit is allocated for one. Rule 3 forbids quantum data in the angle operand,
; not a quantum CONTROL on the rotation.
;
; THE FLAG STRIP IS VALID, which is the accept's own obligation: the only gate
; between the mint `icmp_ne_i32_hl(out, 0)` and its `_unc` is the controlled Rz on
; `%h4` — a different rail from `%out`, and diagonal besides — so `%out`'s basis
; at the strip is the basis the mint read and the flag returns to |0> before its
; `cqrt_free` (Rule 6). Stage 2b (`free_pairing_check.py`) is clean: 5 rail mints,
; 5 left allocated, 3 frees, 3 verified.
;
; IT IS ALSO THE LIVE EXERCISE OF ONE DESIGN DECISION. This region is detected and
; emitted inside the yn71 ONWARD-control fixpoint, which builds a LOCAL `plan2`,
; emits it and DISCARDS it — while `lowerRotations` is later handed the FIRST
; plan. The gate's control flag therefore has to be recorded on `TaintSet`
; (`taint.ControlledRotations`), not on `ControlPlan`; a plan-hosted map would
; lose this entry and lower the gate UNCONDITIONALLY, which is a wrong unitary
; (control-in-place-PRD §6, Inc-1 finding G). This fixture is the shape where that
; is not hypothetical.
;
; THE ARITHMETIC CAVEAT, IN ITS CONSTANT-ARM FORM. The by-difference identity
; `R(A) = R(B)·R(A-B)` is exact over the REALS; what the machine realizes on the
; TRUE edge is `B + fl(A-B)`, with error `delta = A - (B + fl(A-B))`,
; `|delta| <= 1/2 ulp(A-B)`. For THIS pair (0.9 / 0.3) `delta = -2^-54` rad and the
; emitted constant is `0x3FE3333333333334`, which is NOT `fl(0.6)`
; (`0x3FE3333333333333`) — the one-ulp gap is the whole of the residual here and
; it is pinned as BITS below rather than described. Because both arms are
; `ConstantFP`, `angleSelectArmsAdmissible` EVALUATES that residual at compile
; time (TwoSum, exact) and refuses anything above `kAngleSelectMaxRoundingRad`
; = 2^-40 rad, refuses a non-finite arm, and refuses a non-finite difference of
; two finite arms. The RUN-TIME spelling this file used to carry could be given
; none of those checks — the `fsub` happens at run time — which is why it now
; declines; see `control_angle_select_reject_runtime_arms.ll` for the measured
; reproducers and the owner's one-line widening option (1).
;
; A COVERAGE GAP IN THIS FILE THAT IS *NOT* 2b's, recorded so it is not mistaken
; for one (Rule-13 clearance review, non-blocking observation 5): rewriting the
; **4.5 data mux's OWN** mint (`icmp_eq_i32_hl(%h, 0)` / `(%h, 1)`) *and* its
; matching `_unc` strip to read the ROTATED rail `%h4` instead of the scrutinee
; `%h` stays GREEN on all four prefixes here, while the SAME mutation of 2b's
; mint/strip pair goes RED (the `%[[OUT]]`/`%[[QX]]` anchors below). The blind
; spot belongs to the 4.5 datamux assertions, which this increment merely
; inherited; closing it is out of 2b's scope and is left visible rather than
; papered over.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`), GREEN here — Rule 12 red-green.
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
;   * call void @cqrt_x   [superseded by the XCNT count]
;   * call i32 @cqrt_alloc_i32(
;   * call void @cqrt_free(   [superseded by the FCNT count]
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 42 line(s) of prose that annotated the OLD CHECK block were removed with
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
define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %c = icmp ne i32 %rm, 0
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %qx)
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
; CHECK: define i32 @example(i32 %u0, i32 %u1) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H4]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[DELTA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP]], i32 %[[DELTA]], i32 %[[OUT]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[DELTA2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP1]], i32 %[[DELTA2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[H_CMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[H_CMP3]], i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP3]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H4]])
; CHECK-NEXT: ret i32 %[[M5]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)
;
; MEASURED NOT APPLICABLE to this fixture (the candidate FIRES on the clean
; output, so asserting it would be false).  Recorded rather than dropped in
; silence — an absent assertion nobody explained is how a fence rots:
;   * cqrt_copy   (present in this fixture's own output)
;   * _controlled   (present in this fixture's own output)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: cqrt_alloc_f64
; NOROUTE-NOT: cq_template_fsub
; NOROUTE-NOT: fsub double
; NOROUTE-NOT: select
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_rz_i32(i32
; NOROUTE-NOT: call void @cqrt_rz_i32_controlled(i32

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-3: call void @cqrt_free(
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
