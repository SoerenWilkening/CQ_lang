; control_inplace_ry_reject_ssa_alias.ll — DECLINE: the rotated register is an
; SSA ALIAS of the condition register (`int a = q`; PRD shape S8-with-theta, bd
; test_C_libtooling-drbq).
;
;     int q = 0; cq_theta(&q,.5); int a = q;
;     if (q > 5) cq_theta(&a, .9);
;
; `int a = q` mints no IR at all — `a` IS `%q` — so the Ry lands on the very wire
; the flag was minted from. The Rz twin of this shape ACCEPTS (§3c permits a
; diagonal op on a condition variable).
;
; ⚠ THE REASON CHANGED WITH bd test_C_libtooling-dm7f.4 (2026-10-05); THE STRING
; DID NOT. An Ry on the condition's own register now lowers with the flag kept
; (control_inplace_ry_cond_register_flag_kept.ll), so the shared wire alone no
; longer declines. What declines here is the read `cq_measure(%q)` AFTER the
; region: C says `q` is unrotated (only `a` was), the emitted measurement would
; read the rail the controlled Ry relabelled. That is R6's
; `stale rail record read past a controlled Ry`, re-spelled by `declineArm` as
; the deferred wire-gate message because the condition wire carries the arm's
; gate. Drop the `cq_measure(%q)` and this module is the flag-kept accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %at = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %am = phi i32 [ %at, %arm ], [ %q, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %ma = call i32 @cq_measure_si32(i32 %am)
  %s  = add i32 %mq, %ma
  ret i32 %s
}
