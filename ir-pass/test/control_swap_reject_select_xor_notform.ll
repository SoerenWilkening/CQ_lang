; control_swap_reject_select_xor_notform.ll — DECLINE (bd 3c6m.67): the
; CONSTANT-OPERAND xor, i.e. `xor i1 %c, true` — the logical NOT — as a select
; condition. The 3c6m.67 widening admits an xor node with TWO NON-CONSTANT i1
; operands and nothing else, so this stays declined.
;
; WHY THE LINE IS DRAWN AT "NON-CONSTANT" AND NOT AT "xor". A constant operand
; has no compare leaf and therefore NO FLAG RAIL to CNOT from: the emitter's
; node case reads `FlagOf.lookup(operand)` for both children, and a ConstantInt
; child resolves to null. Admitting it would need a materialize-a-constant-rail
; path that does not exist and that nothing measured wants — the four census
; cells this widening exists for (`s_nextafterl.c:55` and siblings) all carry
; two genuine compares. So the narrow admission is the whole intended shape and
; this is an INPUT outside it, not a punt on the work (Rule 17).
;
; NOTE THE DELIBERATE GRAMMAR ASYMMETRY THIS PINS, because it is pre-existing
; and the widening does NOT touch it: PredMux's E6 `isSupportedCondTree` DOES
; admit `xor X, 1` (it is the no-NOT invariant's own negation spelling, consumed
; by `buildNegation` as `¬¬x = x`), while `collectCondTree` admits no constant
; operand at all. A region reaching the SELECT path in this shape declines here
; — loudly, exit non-zero, lowering nothing — which is the safe direction.
;
; The CHECK-NOTs scan stderr only (opt writes no module on a nonzero-exit
; decline); they pin the diagnostic's cleanliness, while the no-mutation
; property lives in the `collectCondTree` detection reject itself.
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 (the file keeps its
; name, L8). "A materialize-a-constant-rail path that does not exist" now does,
; one level up: the NOT condition is tagged a fresh REGISTER CONDITION
; (RegCondLeaf.h), lowered out of place by `lowerOps` (`xor_i1_hl(c1, 1)`, a fresh
; rail holding `!c1`, never an X on a user register; R11 round 1: M-C now
; negates the dead compare flag in place, `xorc_i1(c1, 1)`), and the 4.4 select reads it
; as a register ROOT through the copy flag (`AllowRegRoot`, SelectClassify.cpp).
; Stream: compare, `!c1`, bf = copy, out = !c1 ? q : x, uncopy, free bf. The
; compare and `!c1` are left allocated here because nothing follows (the spine
; discharges them before a later gate on `q`: probed with `cq_theta(&q, .7)`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK:       %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT:  call void @cqrt_xorc_i1(i32 %[[C1]], i1 true)
; CHECK-NEXT:  %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[C1]], i32 %[[BF]])
; ARM POLARITY (R11 round 1, C-F1), derived by hand from the source: the copy
; merge fires its UNBRACKETED copy when the condition holds and its
; `cqrt_x`-bracketed copy when it does not, so the first copy's source must be
; the select's TRUE operand and the bracketed copy's source its FALSE operand.
; `select !c1, q, x`: TRUE = %q, FALSE = %x.
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[Q]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT:  %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[X]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[C1]], i32 %[[BF]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[BF]])
; CHECK-NOT:   cqrt_x(i32 %[[Q]])
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c   = xor i1 %c1, true                  ; NOT — constant operand, off-grammar
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
