; control_angle_select_reject_rounding_above_bound.ll — DECLINE (S1, the
; ARM-VALUE fence, clause (3)): the by-difference rounding residual is ONE BINADE
; above the threshold, `|delta| = 2^-39 rad`.
;
; THE SIBLING OF `control_angle_select_accept_rounding_at_bound.ll`, and the two
; only mean anything together (bd drbq Inc 2b, ROUND-2 Rule-13 review, lens R1
; item 6). Read that file's header for why the threshold was pinned by nothing
; before them. In one line: the accept cell sits AT `2^-40` and this one at
; `2^-39`, so halving the constant reddens the accept cell, doubling it reddens
; THIS one, and re-spelling the `<=` refusal test as a strict `<` reddens the
; accept cell alone.
;
; THE ARITHMETIC, computed independently of the pass in a hand-written TwoSum C
; program (the same six round-to-nearest `double` operations the clause performs
; in `APFloat`):
;
;     A = 0x40E0000000000000 = 2^15  = 32768
;     B = 0x3D80000000000000 = 2^-39
;     ulp(32768) = 2^(15-52) = 2^-37, so B is a QUARTER of an ulp and
;     fl(A - B) = 32768 EXACTLY (round to nearest)
;     delta = A - (B + fl(A-B)) = 32768 - (2^-39 + 32768) = -2^-39
;
; `|delta| = 2^-39 > 2^-40`, so the clause refuses and the caller's pre-existing
; `rotation angle` decline fires — no new diagnostic string.
;
; WHY THE PAIR IS SPELLED AT THIS MAGNITUDE rather than with two ordinary angles:
; `|delta| <= 1/2 ulp(A-B) = 2^(e-53)`, so `|delta| > 2^-40` FORCES `e >= 14` —
; the fence CANNOT decline any constant pair whose difference is below 2^14 =
; 16384 rad (~2607 full turns). Every pair that straddles the threshold is
; therefore necessarily enormous, and that is a property of the bound, not of the
; fixture: it is the measured content of the Rule-17 claim that this fence cannot
; touch the shape the increment set out to build.
;
; ORACLE DISPOSITION: the pre-2b binary declines it `rotation angle under quantum
; control` too (it declines every angle select), so this is a decline both sides —
; the red-green is against a mis-set threshold, not against the oracle.
;
; Reproducer from the round-2 review, lens R1
; (`review2b_r2/R1/probes/delta/p16_32768_2m39_theta.ll`).
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
  ; 0x40E0000000000000 = 32768 = 2^15 ; 0x3D80000000000000 = 2^-39
  %ang = select i1 %c, double 0x40E0000000000000, double 0x3D80000000000000
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
