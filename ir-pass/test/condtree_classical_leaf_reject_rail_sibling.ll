; condtree_classical_leaf_reject_rail_sibling.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; `_Bool b = cq_theta(0, .5); if (b && m == n)`: the literal's sibling is a bare
; RAIL (the user's `_Bool` register). The `_hl` template would read the user's
; register in its handle slot — a control read no rail ladder and no spine
; predicate was asked about — so the classifier declines (safe direction; a
; filed follow-on, not a hazard). matrix CASE 8.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @slice(i32 %n, i32 %m) {
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp eq i32 %m, %n
  %a = and i1 %c, %b
  %s = select i1 %a, i32 10, i32 7
  %r1 = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %r1 to i32
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %z, %r2
  ret i32 %r
}
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
