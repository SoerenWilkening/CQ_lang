; condtree_classical_leaf_reject_callee_quantum_return.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; Rule-13 round 2 F-1 (reviewer probe q04/q05). `g` RETURNS a `cq_theta` register,
; and taint does not cross a call return (pre-existing P1, bd
; test_C_libtooling-3jru), so `%r = call @g` is UNTAINTED in the caller although
; its value is a quantum register's HANDLE ID. `icmp eq %r, %n` must never become
; a classical `_hl` literal. `condLiteralAdmissible` conjunct (d) walks the
; literal's operand cone and refuses a call to a defined function whose return
; cone carries a tainted value, so the mixed select keeps its pre-xdu2.13
; `control flow` decline. Red on bc42274e (it accepted, emitting
; `and_i1_hl(h_cmp, icmp eq <handle id>, %n)`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @g(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  ret i32 %t
}
define internal i32 @slice(i32 %m, i32 %n) {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @g(i32 %m)
  %t = icmp sgt i32 %q, 1
  %c = icmp eq i32 %r, %n
  %a = and i1 %t, %c
  %s = select i1 %a, i32 10, i32 7
  %m1 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
