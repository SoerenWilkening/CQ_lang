; control_angle_select_reject_stale_diag_alias_backward.ll — DECLINE (S9): the
; stale record is BEHIND the base (bd drbq Inc 2b).
;
;     int r0 = cq_theta(...); int r = cq_phi(r0, .1);
;     r = cq_theta(r, q == 5 ? .9 : .3);
;     ... cq_measure(r0);                       // r0 is the PRE-Rz name
;
; The base is reached from `%r0` by a diagonal hop, so `%r0` is in the base's
; backward rail closure and its `cq_measure` is a post-gate read of the same
; physical register. Both this and the `_forward` sibling were measured wrong-value
; silent miscompiles in Inc 1's direct-user form (finding J); one walk, both
; directions, is the fix and this is its select-side pin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r = call i32 @cq_phi_si32(i32 %r0, double 1.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %m0 = call i32 @cq_measure_si32(i32 %r0)
  %s = add i32 %mt, %m0
  ret i32 %s
}
