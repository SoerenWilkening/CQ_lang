; control_predmux_accept_rail_leaf_boolalg_twin.ll — the ALREADY-SHIPPED spelling,
; and the baseline its `br` sibling inherits clearance from (bd
; test_C_libtooling-fn1q increment 2, Rule-13 round 1 finding P2-2).
;
; The identical program written with plain `select`s — what `clang -O1` produces
; whenever it does if-convert the arm. IT ACCEPTS ON THE PRE-INCREMENT ORACLE
; (measured, exit 0), which is the whole point: this increment moves a `br`
; spelling onto a path the compiler was already lowering, and the `diff` RUN lines
; in control_predmux_accept_rail_leaf_boolalg.ll assert the two emit the SAME GATE
; STREAM.
;
; ⚠ DO NOT "SIMPLIFY" THIS FILE. Its value is that it is NOT new: every gate it
; emits was emitted by the oracle. Changing its shape to match the sibling more
; closely would destroy the baseline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 noundef %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %p  = and i1 %rail, %c
  %a4 = select i1 %rail, i32 2, i32 5
  %b5 = select i1 %rail, i32 2, i32 6
  %c6 = select i1 %rail, i32 2, i32 7
  %sel = select i1 %p, i32 %a4, i32 %b5
  %m1 = call i32 @cq_measure_si32(i32 %sel)
  %m2 = call i32 @cq_measure_si32(i32 %c6)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double 5.000000e-01)
; CHECK:     call void @cqrt_toffoli(
