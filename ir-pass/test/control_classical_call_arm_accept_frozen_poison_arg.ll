; control_classical_call_arm_accept_frozen_poison_arg.ll — ACCEPT (bd 9hea).
;
; *** THIS FILE WAS `control_classical_call_arm_reject_poison_arg.ll` UNTIL bd 9hea,
; AND THE RENAME IS THE POINT. *** Its subject — the bd wve8 argument clause
; declining a poison-capable value at a `noundef` parameter — was CORRECT and is now
; DISCHARGED rather than refused: the emitter `freeze`s the hoisted argument, so the
; hoist no longer manufactures UB and the shape lowers. A census of all 1062 fixtures
; found this to be the ONLY file whose decline was owned by that clause, so it is the
; whole affected set; it is renamed rather than deleted because its history is the
; reason the clause exists.
;
; THE ORIGINAL SUBJECT, PRESERVED. Both CALLEE proofs are satisfied and the UB lived
; at the CALL, not inside the function. `@pf` is impeccable: visible,
; non-interposable, single-block, `add`-only, `memory(none) nounwind willreturn`, so
; it passes `isSpeculatableTotalCallee` outright. What was not impeccable is
; `%p = shl i32 1, %n`, POISON for `%n >= 32`, passed to a `noundef` parameter —
; immediate UB, and the 6.5 hoist manufactured it out of nothing, because the source
; evaluates the call only under a quantum guard whose amplitude may be zero. Note the
; poison is computed in the PRED, not the arm: the arm is exactly call + br by
; classification, so the hoist moves only the CALL, and that alone turned a defined
; program into an undefined one.
;
; WHY `freeze` DISCHARGES IT. `freeze` turns poison into an arbitrary but DEFINED
; value, so the `noundef` contract is satisfied and the hoist introduces no UB. On the
; basis states the source DID take the arm, the source's own argument was poison
; there, so any frozen value is a legal refinement; on the states it did not, the
; controlled copy is the identity and the result is never merged into `%out`. `freeze`
; is a codegen no-op, so THE EMITTED CIRCUIT IS UNCHANGED — the only new IR is the
; `freeze` itself, which lowers to nothing.
;
; WHAT WAS NOT DONE, AND WHY (bd 9hea, and commit 9dc909e is the reason): NOT
; `dropPoisonGeneratingFlags` on the argument to remove the `shl`'s poison. Flag drops
; are not a safe direction in this tree — `Fp80Union.cpp`'s `PaddingWalk` reads
; `nsw`/`nuw`/`exact` as BLOCKERS, so removing one can flip a decline into an ACCEPT.
; `freeze` adds a fact instead of removing one.
;
; THE FENCE IS A WHITELIST, NOT A BLACKLIST — see
; `control_classical_call_arm_reject_frozen_arg_range.ll`, the arm-kill: add
; `range(i32 0, 10)` beside the `noundef` and the SAME module DECLINES again, because
; `freeze` yields an ARBITRARY defined value and an out-of-range one is poison all
; over again. Only a parameter whose sole poison-relevant attribute is `noundef` is
; discharged. A whitelist over-declines when LLVM adds a fifth such attribute; a
; blacklist would silently accept it (the bd s6ao discipline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; passes every callee-side clause of the totality gate.
define internal i32 @pf(i32 noundef %x) #0 {
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @example(i32 noundef %u0, i32 noundef %n) {
entry:
  %p = shl i32 1, %n                ; poison for %n >= 32, computed unconditionally
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 noundef %p) ; poison -> noundef param, now FROZEN at the hoist
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; The argument is FROZEN and the frozen value is what the hoisted call receives:
; CHECK: %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %p
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @pf(i32 noundef %[[FR]])

; And the region lowers as an ordinary 6.5 classical-call arm — flag mint, out-rail,
; the two controlled writes (bd dm7f.81: the classical call result is a controlled
; xor of its value, the quantum %h a controlled copy) with the ¬flag cqrt_x bracket
; around the second, strip, single free:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK-NEXT: %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[O]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[H]], i32 %[[O]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK: call void @cqrt_free(i32 %[[F]])
