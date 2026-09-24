; condtree_classical_leaf_reject_undef_literal.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; A CONSTANT child (`and i1 undef, %t`) is never a literal: a Constant has no
; single SSA identity (`undef` is read as two values by a forward and its `_unc`,
; `LiteralIntegrity.cpp`). It is walked, is no leaf, and the grammar declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %a = and i1 undef, %t
  %s = select i1 %a, i32 10, i32 7
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
