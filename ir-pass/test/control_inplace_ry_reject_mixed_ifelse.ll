; control_inplace_ry_reject_mixed_ifelse.ll — DECLINE: a ROTATION arm beside a
; PHASE arm in one if/else (control-in-place-PRD §4 R3 homogeneity; bd
; test_C_libtooling-drbq).
;
;     if (c) r = cq_theta(r, .9); else r = cq_phi(r, .2);
;
; A region lowers by ONE method (Rule 7). The phase arm's answer is a phase kept
; in place and the flag is stripped by the uncontrolled `icmp_inv`; the rotation
; arm's answer is a superposition produced by a CONTROLLED gate. Mixing them has
; no single recipe — the same defect, and the same string, as a phase arm beside a
; value arm.
;
; THE FLAG MUST BE READ AT EVERY ACCEPT SITE, NOT JUST WRITTEN AT ONE. Measured
; while building this increment: with the homogeneity test only inside the
; rotation clause (which fires when the rotation arm is processed SECOND), this
; module — rotation arm FIRST — declined on R6's stale-record string instead,
; because the sibling arm's `cq_phi` happens to be a post-region user of the base.
; Correct outcome, wrong reason, and luck rather than a fence. The companion
; fixture control_inplace_ry_reject_mixed_ifelse_rz_first.ll pins the other order.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}mixed phase/value arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %rf = call i32 @cq_phi_si32(i32 %r, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
