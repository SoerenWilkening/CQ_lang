; control_inplace_ry_reject_stateprep_ifelse_two_preps.ll — DECLINE: an if/else
; with TWO state preps of the IDENTICAL seed. Hand IR only.
;
; ⚠ FROM PLAIN C THIS SHAPE DOES NOT REACH `classifyArms` AT ALL, and that is the
; scope correction §7's Inc-4 bullet needed. `-O1` (SimplifyCFG) merges
; `if (c) { r = 0; cq_theta(&r,A); } else { r = 0; cq_theta(&r,B); }` into ONE theta with a
; tainted-condition ANGLE `select`, which lands in `classifyAngleSelect` and is
; refused at S3 with `rotation angle` — measured (probe `p14a`), and pinned by
; the pre-existing `control_angle_select_reject_state_prep.ll`. So Inc 4 has TWO
; customer sites and ships only the first; the second is follow-on `drbq.13`
; (PRD §14.11 Q5), and it inherits every §12.3 by-difference arithmetic concern.
; §14.2e — THE IF/ELSE CLAUSE, AN OWNER RULING SPELLED OUT. It gets its own
; string rather than riding F1's absence, for two reasons. First, F1 fires
; through the ABSENCE of a Pred edge (an if/else merge φ has none), and a fence
; that fires by absence is a fence nobody can find — which is how a later widener
; removes a bound without noticing there was one. Second, and this one is
; MEASURED: R3 WOULD LET IT THROUGH. With two arms whose seeds are the SAME
; constant, `Routed` is anchored by the first arm to that `Constant` and the
; second arm's `RotBase` is the pointer-identical `Constant`, so
; `RotBase != Routed` is FALSE.
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): NO LONGER TRUE — this shape now DOES reach
; `classifyArms` from plain C. With `nomerge` on every `cq_theta_*` (CQ.h) the arms are
; not merged: drbq.13's `a1.c` and fmt3's no-region `n9.c` decline here (measured),
; pinned by `control_inplace_ry_reject_stateprep_nomerge_noregion_pin.ll`.
;
; ⚠ AND THE LOWERING M-β WOULD PRODUCE IS PHYSICALLY CORRECT FOR THE SOURCE. The
; two hoisted gates would chain onto ONE rail carrying
; `alloc(SEED); cRy(f,A); x; cRy(f,B); x` — which IS
; `if (c) r = Ry(SEED,A); else r = Ry(SEED,B);`. Nothing allocates two rails
; except a reading in which SSA names are wires, and they are not. The owner
; ruled DECLINE anyway; the observation is on the desk as PRD §14.11 Q4.
;
; ⚠ FLIPPED TO AN ACCEPT BY bd test_C_libtooling-dm7f.54 (item B, 2026-10-15), NAME
; KEPT (gahu precedent, L8), under the delegated ruling
; `ruling-dm7f54-literal-base-and-ifelse-prep-2026-10-15` (Q2): the archived Q4
; decline MOVES. Two prep arms with the IDENTICAL literal seed lower as the ONE-rail
; stream the ternary `int r = 0; cq_theta(&r, q == 5 ? .9 : .4)` emits: M-β chains
; the else-arm gate on the then-arm gate, so the then-arm theta is the SOURCE
; (`cqrt_alloc_i32(0)`) and both are controlled Ry on that one rail. F2 is asked on
; BOTH arm edges (nothing is pinned to 0 here). ANALYTIC: q == 5 -> r = Ry(.9)|0>,
; else r = Ry(.4)|0>; the flag strip recomputes q == 5 on an untouched q.
; Different seeds per arm stay loud (`..._ifelse_diff_seeds.ll`); F2's per-edge
; refusal is `..._stateprep_nomerge_noregion_pin.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.ll
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; NEG-NOT: br i1
; NEG-NOT: phi
; ACNT-COUNT-2: call i32 @cqrt_alloc_i32(
; ACNT-NOT:     call i32 @cqrt_alloc_i32(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
