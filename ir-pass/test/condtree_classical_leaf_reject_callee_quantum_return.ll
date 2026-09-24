; condtree_classical_leaf_reject_callee_quantum_return.ll — DECLINE (bd
; test_C_libtooling-xdu2.13 / bd test_C_libtooling-3jru).
;
; Rule-13 round 2 F-1 (reviewer probes q04/q05). `g` RETURNS a `cq_theta`
; register. Before bd 3jru, taint did not cross a call return, so `%r = call @g`
; was UNTAINTED in the caller even though its value is a quantum register's
; HANDLE ID. `icmp eq %r, %n` then became a classical `_hl` literal (red on
; bc42274e: it accepted, emitting `and_i1_hl(h_cmp, icmp eq <handle id>, %n)`).
; [HISTORY: round 2 fenced this with a syntactic conjunct (d) in
; `condLiteralAdmissible`. Round 3 defeated it five ways, and it is REMOVED.]
; bd 3jru now TAINTS `%r` at the call site (the `propagate` fixpoint), and
; `declineQuantumReturnCalls` refuses the use loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: quantum value returned across a function boundary

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
