; control_angle_select_reject_rounding_pi_1e16.ll — DECLINE (S1, the ROUNDING
; fence): `A = pi`, `B = 1e16`, and the emitted true-arm angle is wrong by
; **0.858 rad**.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L7-F1). THE ALGEBRA IS
; EXACT AND THE ARITHMETIC IS NOT. `R(A) = R(B)·R(A−B)` holds over the reals; the
; emitted stream realizes `B + fl(A−B)`, and the error
;
;     delta = A − (B + fl(A−B))
;
; is bounded by half an ulp OF THE DIFFERENCE, i.e. roughly `|A−B|·2^-53` — which
; is negligible when the two angles are the same size and MACROSCOPIC when they
; are not. Here `fl(pi − 1e16) = −0x1.1c37937e07ffep+53` and the composed true-arm
; angle is exactly `4.0`, against a source that wrote `pi`:
;
;     delta = -0x1.b7812aeef4bap-1 = -8.584073e-01 rad
;
; A rotation that is 0.86 radians off is a different unitary by any standard, and
; the PRE-2b BINARY DECLINED THIS SHAPE LOUDLY (`rotation angle`) — so 2b must not
; convert a loud refusal into a silently wrong answer.
;
; THE FENCE: when BOTH arms are `ConstantFP`, S1 computes `delta` EXACTLY at
; compile time with the TwoSum error-free transformation in APFloat at
; `rmNearestTiesToEven` (the residual of the subtraction IS the angle error — see
; the derivation at `kAngleSelectMaxRoundingRad` in ArmClassify.cpp) and returns
; `NotApplicable` when `|delta|` exceeds `kAngleSelectMaxRoundingRad = 2^-40 rad`.
;
; THE THRESHOLD IS A PLACEHOLDER ON THE OWNER'S DESK, not a derived constant. It
; is chosen so the shape this increment exists for (ordinary angles, `0.9 / 0.3`,
; delta = 2^-54) is untouched (Rule 17) while every macroscopic case declines
; (Rule 1). The two questions for the owner are recorded verbatim in
; CONTROL_IN_PLACE_INC2B_NOTES.md §9: (i) is round-to-nearest angle arithmetic IN
; the model, and (ii) if not, the exact alternative is the two-controlled form
; `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)` — no fsub at all.
;
; RUNTIME arms cannot be fenced at compile time (the `fsub` is real), so THEY NOW
; DECLINE TOO — the accept class is CONSTANT arms only (Rule-13 CLEARANCE review,
; finding F-11 / owner option (2); `control_angle_select_reject_runtime_arms.ll`).
; Until that narrowing this file's own pair, spelled as run-time values, ACCEPTED
; and emitted a realized true-arm angle of 4.0 rad — i.e. the fence used to depend
; on how the user SPELLED the angle. The defence offered for that ("it is the same
; arithmetic the manual by-difference C twin performs, so the twin witness cannot
; see it either") was true of the ARITHMETIC and false of any PROGRAM CQ compiles:
; the manual twin with run-time arms declines `control flow` on BOTH binaries.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  ; 0x400921FB54442D18 = pi ; 0x4341C37937E08000 = 1e16
  %ang = select i1 %c, double 0x400921FB54442D18, double 0x4341C37937E08000
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
