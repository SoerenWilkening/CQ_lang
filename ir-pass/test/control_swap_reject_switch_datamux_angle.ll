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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ANGLE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ROT   < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %g = call i32 @cq_phi_si32(i32 %qx, double %ang)
  %m = call i32 @cq_measure_si32(i32 %g)
  ret i32 %m
}

; ROUND-1 RULE-13 REVIEW, LENS L6-N1 — THIS ASSERTION BLOCK WAS BLIND TO SIX
; MUTATIONS and is rewritten below. It had no COUNT prefix at all (so a double
; free, a DIRTY free of the rotated rail `%h4`, and a tail `cqrt_x`/`cqrt_cswap`
; all stayed GREEN), and it bound `%[[QX]]` ON THE TWIN LINE — which makes the
; binding tautological: a CONSISTENTLY wrong rail (every 2b line naming `%h`
; instead of `%h4`) matched, because FileCheck simply bound `QX` to whatever the
; twin named. The rail is now bound at its ALLOC, so the chain has to agree with
; the SOURCE register and not merely with itself. This file is the ONLY exercise
; of the yn71 onward-control path for 2b and it has no e2e slice, so it is
; carrying that whole axis alone.
;
; the rotated register, bound AT ITS ALLOC (not on the twin line)
; CHECK:      %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QX]], double 0x3FE6666666666666)
; the 4.5 data mux builds `%out` (preload 3, then the two XOR deltas 4 and 10 —
; 3^4 = 7 and 3^10 = 9), unchanged by this increment
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; the 2b stream, as an adjacency chain: unconditional twin, mint, controlled
; gate, strip, free. THE DIFFERENCE IS FOLDED — with two `ConstantFP` arms
; `IRBuilder`'s folder evaluates `0.9 - 0.3` at round-to-nearest and no `fsub`
; instruction is emitted at all, so the chain now starts at the twin. The folded
; constant is pinned as BITS: `0x3FE3333333333334` is one ulp above `fl(0.6)`
; (`0x3FE3333333333333`), which is the residual `delta = -2^-54` made visible.
; CHECK:      call void @cqrt_rz_i32(i32 %[[QX]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[QX]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F]], i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; THE ORIGINAL FIXTURE'S REAL ASSERTION, KEPT: no quantum value is ever realized
; as an angle. No `cqrt_alloc_f64` for the angle, no template computes it, and the
; select is gone. The route and X spellings are added by the round-1 review: this
; lowering is CONTROL-IN-PLACE, so a `cqrt_cswap` work-rail route or a `cqrt_x`
; polarity bracket appearing anywhere in it is a different lowering, not a
; variant of this one (a select has no polarity case at all). The bare `fsub` is
; added by the clearance narrowing: with constant arms the difference MUST fold,
; so an `fsub` surviving anywhere in this module means the fold did not happen.
; ANGLE:     define{{.*}}@example
; ANGLE-NOT: cqrt_alloc_f64
; ANGLE-NOT: cq_template_fsub
; ANGLE-NOT: fsub double
; ANGLE-NOT: select
; ANGLE-NOT: call void @cqrt_cswap
; ANGLE-NOT: call void @cqrt_x

; EXACT COUNTS (round-1 review, L6-N1). Five allocs — the two source registers,
; the data mux `%out`, and its two XOR deltas — and NO work rail. THREE frees:
; the two data-mux eq flags and the 2b flag, and NOTHING ELSE, which is what makes
; a DIRTY free of the rotated rail `%h4` (`Rz` leaves it in superposition, Rule 6)
; go red rather than green. All five allocs precede all three frees in this
; module, so the two count/NOT pairs compose in program order.
; CNT-COUNT-5: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; EXACTLY ONE unconditional Rz (the twin) and EXACTLY ONE controlled Rz (the
; rewired consumer) — a stray extra rotation on the rail, before or after the
; free, is the mutation the adjacency chain alone cannot see because the chain
; stops at the free.
; ROT-COUNT-1: call void @cqrt_rz_i32(i32
; ROT-NOT:     call void @cqrt_rz_i32(i32
; ROT-COUNT-1: call void @cqrt_rz_i32_controlled(i32
; ROT-NOT:     call void @cqrt_rz_i32_controlled(i32
; the TRAILING repeat is not redundant: a `-NOT` between two positive directives
; covers only the span between their matches, so without this line a stray
; rotation AFTER the last controlled gate stays green (measured — the injected
; `cqrt_rz_i32(%h4, 0.1)` before the measure passed every other assertion here).
; ROT-NOT:     call void @cqrt_rz_i32(i32
