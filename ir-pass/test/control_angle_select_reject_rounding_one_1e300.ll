; control_angle_select_reject_rounding_one_1e300.ll — DECLINE (S1, the ROUNDING
; fence): `A = 1.0`, `B = 1e300`, and the emitted true-arm angle is **0.0**
; against a source that wrote `1.0`. `delta = 1.0` rad exactly.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L7-F1) — the TOTAL
; CANCELLATION cell, and the reason the fence cannot be phrased as "the arms must
; be close". `fl(1.0 − 1e300) = −1e300` exactly (1.0 is below the ulp of 1e300),
; so `B + fl(A−B) = 1e300 − 1e300 = 0`. The whole of the true arm's angle is lost:
;
;     delta = A − (B + fl(A−B)) = 1.0 − 0.0 = 0x1p+0
;
; This is the same clause as `control_angle_select_reject_rounding_pi_1e16.ll`
; (`|delta| > kAngleSelectMaxRoundingRad = 2^-40`) exercised at its extreme, and
; both are kept because they fail differently: pi/1e16 loses PART of the angle,
; this one loses ALL of it, and a threshold expressed as a RELATIVE error would
; have caught only one of them. The bound is ABSOLUTE, in radians, deliberately —
; an angle's physical meaning is absolute.
;
; NOTE THE NEAR MISS THAT ACCEPTS, because it is what makes the absolute reading
; the right one: `A = 1e-20, B = 1.0` also cancels totally (`fl(A−B) = −1.0`,
; composed angle 0.0), but its delta is `1e-20` rad — physically nothing — and it
; ACCEPTS. Relative error there is 100%; absolute error is negligible. Measured,
; not argued (`review2b/L7/fp.out`).
;
; THE PRE-2b BINARY DECLINED THIS SHAPE (`rotation angle`), so the fence restores
; that disposition rather than inventing one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  ; 0x3FF0000000000000 = 1.0 ; 0x7E37E43C8800759C = 1e300
  %ang = select i1 %c, double 0x3FF0000000000000, double 0x7E37E43C8800759C
  %t = call i32 @cq_phi_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
