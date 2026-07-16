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
; CHECK: define internal i32 @__cq_q_helper_1(i32 %b)
; the tainted fall-through, the guard flag, the |0> out rail, the materialized
; classical sentinel, and the forward-only controlled-XOR mux:
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %b, i32 7)
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 100)
; CHECK: %cqq.sel = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %selop = call i32 @cqrt_alloc_i32(i32 999)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; the Bennett copy-out then the single reverse (copy⁻¹, icmp `_unc`, add `_unc`):
; CHECK: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32(i32 %cqq.sel, i32 %cqq.out)
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %b, i32 100)
; CHECK: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %b, i32 7)
; every proven-|0> rail freed (the materialized |const⟩ selop is left allocated):
; CHECK: call void @cqrt_free(i32 %h_op)
; CHECK: call void @cqrt_free(i32 %h_cmp)
; CHECK: call void @cqrt_free(i32 %cqq.sel)
; CHECK: ret i32 %cqq.out
