; taint_reject_quantum_return_chain_store.ll — DECLINE (bd test_C_libtooling-3jru).
;
; Pins the cross-function FIXPOINT, not just the refusal. `g` returns `h() + 1`,
; `h` returns a `cq_theta` register, and `@main` STORES `g()`'s result. `g` is
; defined BEFORE `h`, so a single pass over the module taints `h`'s call inside
; `g` but never reaches `g`'s call site in `@main`. Only the ITERATED fixpoint
; taints `%x`, which lets the existing store-escape guard speak first with its
; own string. (Without it, the late `declineQuantumReturnCalls` would still
; decline, with the return string instead — which is why mutation M37, a
; one-pass fixpoint, needs this fixture to be killed.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: tainted value stored to memory

@G = global i32 0

define i32 @g(i32 %k) noinline {
  %v = call i32 @h(i32 %k)
  %w = add i32 %v, 1
  ret i32 %w
}

define i32 @h(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  ret i32 %t
}

define i32 @main(i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %x = call i32 @g(i32 %m)
  store i32 %x, ptr @G
  %r = call i32 @cq_measure_si32(i32 %q)
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
