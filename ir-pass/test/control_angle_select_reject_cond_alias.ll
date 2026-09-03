; control_angle_select_reject_cond_alias.ll — DECLINE: the rotated base is a
; DIAGONAL ALIAS of the condition register (bd drbq Inc 2b).
;
;     int qd = cq_phi(q, .1);
;     qd = cq_theta(qd, q == 5 ? .9 : .3);   // rotates q's OWN physical rail
;
; SSA-value disjointness is NOT wire disjointness: rotation lowering RAUWs
; `%qd = cq_phi(%q, .)` and `%q` onto the SAME `cqrt_alloc_i32` handle, so this
; Ry lands on the rail the condition reads. Same physics as
; `..._reject_cond_register.ll`, one alias hop out.
;
; GATE 2c fires first here too (prong (a) crosses the diagonal `cq_phi` and finds
; the `cq_theta` on `%q`'s wire), so the message is `condition predates a
; non-diagonal gate`. S8 is the backstop and would name the same rail through
; `railWireClosure`'s `cq_phi` hop; neither is redundant — 2c is position-free
; over the CONDITION's provenance while S8 intersects two RAIL closures, and the
; shapes they cover are only overlapping, not equal.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %qd, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
