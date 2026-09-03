; control_angle_select_reject_stale_diag_alias_two_hop.ll — DECLINE (S9): the
; stale record is TWO diagonal hops out (bd drbq Inc 2b).
;
; Pins that the rail closure is TRANSITIVE, not one-hop: `%h2 = cq_phi(%h1, .)`
; where `%h1 = cq_phi(%r, .)`. A one-hop fence would accept this and emit a
; measurement of the post-Ry register. The bd 8h7d.5 F-3 lesson in miniature —
; when you widen a set, ask how far it has to reach.
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
  %h1 = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %h2 = call i32 @cq_phi_si32(i32 %h1, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %m2 = call i32 @cq_measure_si32(i32 %h2)
  %s = add i32 %mt, %m2
  ret i32 %s
}
