; condtree_classical_leaf_reject_measured_self.ll — DECLINE (bd
; test_C_libtooling-xdu2.13, Rule-13 round 1 P3-3 / reviewer probe p36_measself).
;
; `q` is MEASURED, then read by the tainted leaf of a mixed `and (m == n), (q != 0)`
; 4.4 select. Before xdu2.13 the classical leaf declined first at the per-leaf
; taint gate (`control flow`); now the literal is admitted and the SAME select
; reaches the pre-existing measured-before rung, so the string MOVES to the more
; precise `condition measured before the control route`. The verdict is unchanged
; (decline); this pins the new owner character-for-character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: condition measured before the control route under quantum control

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %t = icmp ne i32 %q, 0
  %c = icmp eq i32 %m, %n
  %a = and i1 %c, %t
  %s = select i1 %a, i32 10, i32 7
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
