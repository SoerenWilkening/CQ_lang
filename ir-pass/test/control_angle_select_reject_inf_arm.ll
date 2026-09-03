; control_angle_select_reject_inf_arm.ll — DECLINE (S1, the ARM-VALUE fence): one
; select arm is a NON-FINITE `ConstantFP` (`+inf`).
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L7-F2). The by-difference
; identity `R(A) = R(B)·R(A−B)` is an identity over the REALS. With `B = +inf` and
; `A = 1.0` the emitted difference is `fl(1.0 − inf) = −inf`, so the stream is
;
;     ry(h, +inf) ; ry_controlled(f, h, −inf)
;
; and on the TRUE edge the composed angle is `inf + (−inf) = NaN` — the source's
; WELL-DEFINED true arm `Ry(1.0)` has become a NaN rotation. 2b MANUFACTURES a
; value the source never named, on the edge that was fine.
;
; WHAT THIS FIXTURE DOES *NOT* CLAIM, and the distinction is load-bearing: an
; UNCONTROLLED `cq_theta(r, INFINITY)` lowers to `cqrt_ry_i32(h, inf)` on the
; pre-2b binary too. That is a PRE-EXISTING disposition about a single
; user-written angle and it is not this increment's to change (lens L7's
; `p06_inf_inf.c` measured it identical on both binaries). What 2b added is the
; manufacture of a SECOND non-finite angle, and the destruction of the finite arm
; by it. The fence is therefore on the ARM VALUES OF A SELECT 2b claims, not on
; non-finite angles in general.
;
; THE FIX: S1 returns `NotApplicable` when either arm is a `ConstantFP` that is
; not finite (`isNaN() || isInfinity()`), so the caller's pre-existing
; `rotation angle` decline fires unchanged — no new string, and the pre-2b
; disposition is restored exactly.
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
  %ang = select i1 %c, double 1.000000e+00, double 0x7FF0000000000000
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
