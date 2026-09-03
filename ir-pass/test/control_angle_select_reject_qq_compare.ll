; control_angle_select_reject_qq_compare.ll — DECLINE (S4): a Q+Q condition
; (bd drbq Inc 2b).
;
;     if (q > p) r = cq_theta(r,.9); else r = cq_theta(r,.3);
;
; BOTH compare operands are quantum. S4 requires EXACTLY ONE tainted operand —
; the `_hl`/`_lh` shape `lowerCompareToFlag` mints from with an empty `qqWidth`
; — so the Q+Q leaf declines here rather than reaching the emitter and hitting a
; mid-mint null bail (detect-before-mutate, the ziov.4 discipline).
;
; The 4.4 data select DOES admit a Q+Q leaf (bd adia, through the QQ template
; grid and `qqSelectLeafWidth`). Adopting that here is a follow-on, not a
; correctness gap: it needs the strip to be re-proved over TWO condition wires,
; which doubles S8's intersection obligation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u2, double 3.000000e-01)
  %c = icmp sgt i32 %q, %p
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mp = call i32 @cq_measure_si32(i32 %p)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s1 = add i32 %mq, %mp
  %s2 = add i32 %s1, %mt
  ret i32 %s2
}
