; control_swap_value_reject_speculation.ll — DECLINE: a value arm whose chain
; contains an operation that cannot run UNCONDITIONALLY (bd
; test_C_libtooling-3qlq Inc 2, retire-swap-route-PRD §10.3 lens 8).
;
; `if (q > 5) { p = p*5; p = p/n; }` with `n` a RUN-TIME CLASSICAL value. Since
; Inc 2 the arm's chain is HOISTED into the pred and executed unconditionally on
; the original %p, so an `sdiv`/`udiv`/`srem`/`urem` whose divisor is not proven
; non-zero (and, for the signed forms, not the `INT_MIN / -1` overflow) is UB the
; source never wrote. The fence asks LLVM's OWN `isSafeToSpeculativelyExecute` —
; the predicate SimplifyCFG consults before speculating a block (Rule 14) — and
; declines, lowering nothing (Prime Directive).
;
; ⚠ MEASURED RED-GREEN, AND IT IS A NARROWING, NOT A REPAIR. The pre-3qlq binary
; ($SP/wt/pre-3qlq, commit 52d7764) ACCEPTS this module (exit 0) and emits the
; `sdiv` template UNCONDITIONALLY on a |0> work rail — i.e. `0 sdiv n` with the
; same possibly-zero divisor. The hazard is therefore identical under both
; mechanisms and merely became visible when the chain was hoisted onto a value
; the source can observe. Over-declining is always safe (Prime Directive); the
; accept twin control_swap_value_accept_div_const.ll keeps the fence from being
; a blanket refusal of the division opcodes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = sdiv i32 %v1, %n            ; run-time classical divisor — may be zero
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: value arm op that cannot run unconditionally under quantum control
; nothing is lowered: the decline is PRE-MUTATION (before the hoist)
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cqrt_cswap
