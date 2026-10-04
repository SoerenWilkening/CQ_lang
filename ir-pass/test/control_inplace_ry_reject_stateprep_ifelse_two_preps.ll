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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}if/else state prep allocates two rails under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

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
