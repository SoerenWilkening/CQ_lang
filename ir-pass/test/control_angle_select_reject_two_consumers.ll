; control_angle_select_reject_two_consumers.ll — DECLINE (S2): ONE select feeding
; TWO rotations' angle slots (bd drbq Inc 2b).
;
;     double a = q == 5 ? .9 : .3;
;     cq_theta(&r, a); s = cq_phi(s, a);
;
; A RECORDED FOLLOW-ON, not a hazard of the construct: each consumer would get its
; own unconditional twin and its own controlled gate, and the two would need to
; SHARE one flag (minting twice and stripping twice is sound but wasteful; minting
; once means the mint and the strip bracket BOTH gates). What makes N consumers
; more than bookkeeping is S6: its positional scan is deliberately WIRE-BLIND, so
; with two consumers the window `(Cond, T)` differs per consumer and the accept
; would become ORDER-dependent — a verdict that changes with textual position is
; exactly what this project's detection discipline forbids (Rule 9).
;
; Inc 2b ships ONE consumer, which is what the C target shape produces.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u2, double 1.250000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t1 = call i32 @cq_theta_si32(i32 %r, double %ang)
  call void @cq_phi(double %ang)
  %m1 = call i32 @cq_measure_si32(i32 %t1)
  %m2 = call i32 @cq_measure_si32(i32 %s)
  %x = add i32 %m1, %m2
  ret i32 %x
}
