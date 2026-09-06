; control_inplace_ry_reject_stateprep_ifelse_phase_first.ll — DECLINE: the
; REVERSED-ORDER twin of `..._ifelse_mixed_phase.ll` — the PHASE arm is
; `Region.Arm` and is processed first, so `SawPhaseArm` is set and the rotation
; clause's own homogeneity check fires before the if/else clause is reached.
;
; ⚠ THIS IS THE `SawRotationArm` LESSON RUN IN THE OTHER DIRECTION (Inc 1's
; measured note: "with only the one-directional test, a mixed if/else declined —
; but on R6's stale-record string, BY LUCK. Luck is not a fence."). Committing
; both orders is what turns "the mixture declines" from a claim into a
; measurement, and it is why the homogeneity flags are read at EVERY accept site
; rather than only at the one that writes them.
;
; MEASURED ON THE PRE-INC-4 ORACLE: `control flow` — so this row's string moved
; too, and for the same reason as IE-3/IE-4 (the arm is now recognized).
; §14.2e — THE IF/ELSE CLAUSE, AN OWNER RULING SPELLED OUT. It gets its own
; string rather than riding F1's absence, because F1 fires through the ABSENCE of
; a Pred edge (an if/else merge φ has none), and a fence that fires by absence is
; a fence nobody can find — which is how a later widener removes a bound without
; noticing there was one.
;
; ⚠ THE "R3 WOULD LET IT THROUGH" AND "M-β WOULD BE PHYSICALLY CORRECT"
; PARAGRAPHS WERE REMOVED FROM THIS FILE 2026-09-05 (round-1 Rule-13 review, lens
; L7 finding F-L7-8): both are about TWO ARMS WHOSE SEEDS ARE THE SAME CONSTANT,
; which is true of `..._ifelse_two_preps.ll` and of no other file that carried
; them. They live there.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: mixed phase/value arm under quantum control
; NEW: cq controlled lowering: impure phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  call void @cq_phi(double 4.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %p, %armt ], [ %rf, %armf ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
