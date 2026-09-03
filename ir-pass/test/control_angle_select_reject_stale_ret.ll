; control_angle_select_reject_stale_ret.ll — DECLINE (S9): the pre-gate SSA name
; of the rotated register is RETURNED (bd drbq Inc 2b).
;
; The `ret` variant of the stale-record family. S9 is deliberately STRICTER than
; the pass-wide `declineStaleRecordOps` (which covers PURE ops only): a
; `cq_measure`, a `ret`, a `store`, an opaque call, a phi — ANY user that is not
; provably before the gate declines. Without that strictness the `0njv` hole
; would be reachable through this accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %r
}
