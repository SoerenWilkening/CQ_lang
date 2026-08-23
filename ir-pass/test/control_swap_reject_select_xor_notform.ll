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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_cnot
; CHECK-NOT: cq_template_icmp
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
