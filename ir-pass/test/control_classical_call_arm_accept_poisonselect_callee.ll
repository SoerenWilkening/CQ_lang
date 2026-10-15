; control_classical_call_arm_accept_poisonselect_callee.ll — the ARM-KILL PARTNER
; of control_classical_call_arm_twin_accept_poisonbr_callee.ll (bd wve8; a decline
; until batch 053 froze the branch condition in a twin), and the file
; that says what the totality gate is NOT about.
;
; `@pf` here carries the IDENTICAL poison-capable computation as the reject file —
; `%s = shl i32 1, %x` is poison for `%x >= 32`, and `%c = icmp eq i32 %s, 7`
; propagates it — and computes the IDENTICAL value. The ONLY difference is that
; the `br i1 %c` becomes a `select i1 %c`. This module LOWERS.
;
; WHAT THAT ISOLATES, and it is the whole point of committing it:
;   * the decline over there is the `br i1`, NOT the `shl`, NOT the poison, NOT
;     the visible body and NOT the call. POISON IS NOT THE OBLIGATION HERE.
;     Selecting on poison yields poison; BRANCHING on poison is UB. Only the
;     second one turns a hoist into UB the source did not have, and only the
;     second one is refused.
;   * the poison in `%r` is harmless downstream for the reason the gate's own
;     comment gives: `cqrt_copy_i32_controlled` is the identity wherever the flag
;     is 0, so on exactly the basis states the source shielded the hoisted value
;     never reaches `%out`; and on the states the source DID take, the source
;     computed the same poison itself.
;   * a MULTI-BLOCK callee is not excluded either — an unconditional `br` passes,
;     since it has no condition and cannot be UB. Only `br i1` is refused.
;
; If someone later tightens this gate to a DEFINEDNESS test on the CALLEE BODY,
; THIS FIXTURE GOES RED, and that is the intended tripwire: definedness of the
; RESULT is a strictly stronger obligation than the one this site carries, and
; adopting it here would be the deleted-S4 mistake (bd 3c6m.14.2) repeated at a
; new address.
;
; `@example`'s parameters carry `noundef` deliberately, matching what clang -O1
; emits for `int example(int, int)`. Without it the ARGUMENT half of the totality
; gate declines: `%k` would be an `Argument` with no `noundef`, hence not provably
; defined, passed to `@pf`'s `noundef` parameter. That is not incidental tidying —
; it is the gate working, and the reason the poison in this fixture has to live
; INSIDE the callee (the `shl`) rather than in the argument.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=BODY < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %s = shl i32 1, %x            ; poison when %x >= 32 — deliberately kept
  %c = icmp eq i32 %s, 7        ; poison — deliberately kept
  %v = select i1 %c, i32 1, i32 2
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; the call is HOISTED ahead of the flag mint and its result route-merged:
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @pf(i32 %k)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 {{.*}}, i32 3)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 %[[R]])
; CHECK-NOT: @__cq_q_

; the callee body is UNTOUCHED — 6.5 is clone-orthogonal and never lowers it, so
; the poison-capable shift survives verbatim (own prefix: `@pf` is printed BEFORE
; `@example`, and CHECK is sequential):
; BODY:      define internal i32 @pf(i32 noundef %x)
; BODY-NEXT: entry:
; BODY-NEXT:   %s = shl i32 1, %x
; BODY:        %v = select i1 %c, i32 1, i32 2
; ACC-NOT: under quantum control
