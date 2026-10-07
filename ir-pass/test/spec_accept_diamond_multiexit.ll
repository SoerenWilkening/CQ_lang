; spec_accept_diamond_multiexit.ll — Phase 6 / issue 5po2 I2: a MULTI-EXIT
; controlled-return (a classical-sentinel early return guarding a tainted
; fall-through — the fp80-transcendental shape `if(x>MAXLOGL) return C; … return
; f(x)`) now LIFTS into a reversible clone. `normalizeReturnMerge` folds the two
; `ret`s into a single-exit merge phi; the scoped PredMux fixpoint (claimAll)
; flattens the 2-incoming diamond to `select(icmp, 999, b+7)`; `lowerCloneSelect`
; MATERIALIZES the classical sentinel `999` into a leaked |const⟩ copy-source rail
; and emits the forward-only 4.4 controlled-XOR mux; the Bennett wrap plays the
; single reverse (copy⁻¹, icmp `_unc`, add `_unc`) and frees the proven-|0⟩ rails.
; This was the I1 decline fixture `spec_reject_diamond_multiexit.ll`, flipped to
; accept when I2 landed.
;
; bd p3kd.7.8: the flattened select is now lowered by MAIN's 4.4 SelectMergeEmit
; (the clone-only `lowerCloneSelect` is gone): the same two-copy merge, the out
; rail is SelectMergeEmit's, and main's inline strip (closing `cqrt_x`, compare
; `_unc` + free) is elided by the Bennett wrap, whose reverse is now the EXACT
; mirror (both copies and the `cqrt_x` replayed). Trace on |b>: f = [b>100]; out
; gets 999 under f, then (f flipped) b+7 under ¬f, so out = b>100 ? 999 : b+7, the
; source's two returns; the mirror un-copies b+7, re-flips f, un-copies 999 (out
; -> |0>), then the compare and add `_unc`s zero f and a. The |999> sentinel rail
; is only ever read, stays |999>, and is never freed (R5); the result never freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp sgt i32 %b, 100
  br i1 %t, label %early, label %main
early:
  ret i32 999
main:
  %a = add i32 %b, 7
  ret i32 %a
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The tainted-arg clone lifts the multi-exit controlled-return to a reversible mux.
; The CHECK-NEXT chain covers the whole clone body, so it also proves the |999>
; sentinel rail K is never freed.
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT: entry:
; the tainted fall-through, the guard flag, the |0> out rail, the materialized
; classical sentinel, and the two-copy controlled-XOR mux:
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 7)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 100)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 999)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[A]], i32 %[[OUT]])
; the Bennett copy-out, then the exact mirror (copies, x, icmp `_unc`, add `_unc`):
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[RES]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %b, i32 100)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[A]], i32 %b, i32 7)
; every proven-|0> rail freed (the materialized |999> rail K is left allocated):
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[RES]]
; CHECK-NEXT: }
