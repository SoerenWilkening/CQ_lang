; control_inplace_ry_reject_mixed_ifelse.ll — DECLINE: a ROTATION arm beside a
; PHASE arm in one if/else (control-in-place-PRD §4 R3 homogeneity; bd
; test_C_libtooling-drbq).
;
;     if (c) cq_theta(&r, .9); else cq_phi(.2);
;
; A region lowers by ONE method (Rule 7). The phase arm's answer is a phase
; kicked back onto the flag, then stripped by the uncontrolled `icmp_inv`; the
; rotation arm's answer is a superposition produced by a CONTROLLED gate. Mixing
; them has no single recipe — the same defect, and the same string, as a phase
; arm beside a value arm.
;
; THE FLAG MUST BE READ AT EVERY ACCEPT SITE, NOT JUST WRITTEN AT ONE. Measured
; while building this increment: with the homogeneity test only inside the
; rotation clause (which fires when the rotation arm is processed SECOND), this
; module — rotation arm FIRST — declined on R6's stale-record string instead,
; because the sibling arm's (pre-3qlq register) `cq_phi` happened to be a
; post-region user of the base.
; Correct outcome, wrong reason, and luck rather than a fence. The companion
; fixture control_inplace_ry_reject_mixed_ifelse_rz_first.ll pins the other order.
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: mixed phase/value arm under quantum control
; NEW: cq controlled lowering: mixed phase/value arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: mixed phase/value arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %r, %armf ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
