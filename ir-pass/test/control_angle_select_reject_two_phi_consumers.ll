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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u2, double 1.250000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t1 = call i32 @cq_phi_si32(i32 %r, double %ang)
  %t2 = call i32 @cq_phi_si32(i32 %s, double %ang)
  %m1 = call i32 @cq_measure_si32(i32 %t1)
  %m2 = call i32 @cq_measure_si32(i32 %t2)
  %x = add i32 %m1, %m2
  ret i32 %x
}
