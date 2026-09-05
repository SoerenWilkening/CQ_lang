; control_inplace_ry_reject_stateprep_ifelse_mixed_phase.ll — DECLINE: a state
; prep in the TRUE arm beside a PHASE (`cq_phi`) arm in the false one. Hand IR.
;
; The prep arm is processed first, so the if/else clause fires and `SawPhaseArm`
; is never set. PRD §14.3 row IE-5 predicted `mixed phase/value arm`; that is
; what the OTHER ORDER prints, and it has its own fixture
; (`..._ifelse_phase_first.ll`). The pair is committed deliberately: the message
; for a mixed if/else depends on ARM ORDER, both messages are accurate about a
; real defect, and a reader who sees only one of them would conclude the fence is
; the other one.
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
; ⚠ THE STRING MOVED 2026-09-05 (round-1 Rule-13 review, lens L7 finding
; F-L7-8). HEAD used to print `if/else state prep allocates two rails` here, and
; THIS FILE HAS ONLY ONE PREP: the other arm is a `cq_phi` PHASE arm, so nothing allocates
; two rails and the message described a different program. The §14.2e clause now
; asks what the OTHER arm is — with the same `inPlaceRotationArmTheta` predicate
; it is already inside, never a second spelling — and says
; `if/else state prep beside a chained or phase arm` for this shape, keeping the
; two-rails wording for `..._ifelse_two_preps.ll` and `..._ifelse_diff_seeds.ll`,
; where it is true.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: if/else state prep beside a chained or phase arm under quantum control
; NEW: cq controlled lowering: if/else state prep beside a chained or phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: if/else state prep beside a chained or phase arm under quantum control
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
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
armf:
  call void @cq_phi(double 4.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %p, %armf ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
