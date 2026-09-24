; condtree_classical_leaf_reject_callee_quantum_return_nested.ll — DECLINE (bd
; test_C_libtooling-xdu2.13 / bd test_C_libtooling-3jru).
;
; The same refusal through TWO calls: `g` returns `h(k) + 1`, and `h` returns a
; `cq_theta` register. bd 3jru's `propagate` fixpoint taints `h`'s call inside
; `g`, so `g`'s `ret` is tainted and so is `g`'s call site (chains and recursion
; iterate to a fixpoint). Red on bc42274e.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: quantum value returned across a function boundary

define i32 @h(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  ret i32 %t
}
define i32 @g(i32 %k) noinline {
  %v = call i32 @h(i32 %k)
  %w = add i32 %v, 1
  ret i32 %w
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
