; control_angle_select_reject_stale_diag_alias_forward.ll — DECLINE (S9): the
; stale record is ONE DIAGONAL HOP FORWARD of the base (bd drbq Inc 2b; the
; select form of Inc-1 finding J).
;
;     int r = cq_theta(...); int mark = cq_phi(r, .1);   // mark is FORWARD of r
;     r = cq_theta(r, q == 5 ? .9 : .3);
;     ... cq_measure(mark);
;
; S9 ranges over the base's RAIL, not over its CHAIN: `%mark` is not the base and
; is not a user the fence would see if it scanned `%r`'s direct users for reads —
; it IS a user, but a benign one (an alias hop), and the READ sits one hop out on
; `%mark`. Inc 1 shipped the direct-user version of this scan and both directions
; of this shape were CONFIRMED wrong-value silent miscompiles.
;
; The `_backward` sibling puts the record BEHIND the base instead.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mm = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mt, %mm
  ret i32 %s
}
