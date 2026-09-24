; condtree_classical_leaf_reject_xor.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; `(q > 2) != (m == n)` is an `xor i1` with a classical child. The literal is an
; `and`/`or` capability only (no mixed-xor probe family), so the classical leaf
; stays an untainted compare LEAF and the per-leaf gate declines — the SAME
; string the pre-xdu2.13 binary printed. matrix CASE 9.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp sgt i32 %q, 2
  %c = icmp ne i32 %m, %n
  %x = xor i1 %c, %t
  %s = select i1 %x, i32 7, i32 10
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
