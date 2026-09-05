; control_angle_select_reject_two_phi_consumers.ll — DECLINE (S2): ONE angle
; select feeding TWO `cq_phi` consumers on DIFFERENT registers (bd drbq Inc 2b).
;
; THE SIBLING OF `..._reject_two_consumers.ll`, AND THE ONE THAT ACTUALLY FENCES
; S2. Measured by mutation: with S2's `hasOneUse` clause stubbed out, the
; two_consumers fixture stays green because its two consumers are a `cq_theta`
; and a `cq_phi`, so S6's positional scan sees the theta in the window and
; declines anyway. Here BOTH consumers are `cq_phi` — nothing else in the ladder
; refuses the shape, and `Sel->hasOneUse()` is the only thing standing between it
; and an emitter that would lower ONE consumer and erase the select the OTHER one
; still reads.
;
; (The emitter re-validates `hasOneUse` too and would bail LOUDLY before emitting
; anything, so this is a decline-vs-decline distinction, not a miscompile. But a
; clause with no red fixture is an unfenced clause, and a detection-time refusal
; is worth a fixture of its own — the emitter's copy is defence in depth, not the
; accept predicate.)
;
; N consumers is a recorded follow-on: each needs its own unconditional twin and
; controlled gate, and they must share ONE flag whose mint/strip bracket ALL of
; them.
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
  call void @cq_phi(double %ang)
  call void @cq_phi(double %ang)
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m2 = call i32 @cq_measure_si32(i32 %s)
  %x = add i32 %m1, %m2
  ret i32 %x
}
