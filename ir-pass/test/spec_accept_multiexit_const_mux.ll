; spec_accept_multiexit_const_mux.ll — Phase 6 / issue 5po2 I2: a multi-exit
; controlled-return whose BOTH arms are classical constants (`branchy(a) = a>5 ?
; 100 : 200`) now LIFTS into a reversible clone. `normalizeReturnMerge` folds the
; two `ret`s; PredMux flattens to `select(icmp, 100, 200)`; `lowerCloneSelect`
; MATERIALIZES BOTH sentinels into leaked |const⟩ copy-source rails (selop=100,
; selop1=200) and emits the forward-only 4.4 controlled-XOR mux (copy_T · ¬flag
; `cqrt_x` · copy_F · `cqrt_x`); the Bennett wrap plays the single reverse and
; frees the two proven-|0⟩ rails (the flag + the out rail). This supersedes the
; Phase-6.1 straight-line-only decline fixture `spec_reject_inbody_control.ll` —
; I2 lifts a value/data-mux body, so the two-constant mux is a correct accept.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @branchy(i32 %a) {
entry:
  %c = icmp sgt i32 %a, 5
  br i1 %c, label %t, label %f
t:
  ret i32 100
f:
  ret i32 200
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @branchy(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: define internal i32 @__cq_q_branchy_1(i32 %a)
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 5)
; CHECK: %cqq.sel = call i32 @cqrt_alloc_i32(i32 0)
; both classical sentinels materialized into leaked |const⟩ copy-source rails:
; CHECK: %selop = call i32 @cqrt_alloc_i32(i32 100)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: %selop1 = call i32 @cqrt_alloc_i32(i32 200)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; the single Bennett reverse + frees (materialized selop/selop1 left allocated):
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 5)
; CHECK: call void @cqrt_free(i32 %h_cmp)
; CHECK: call void @cqrt_free(i32 %cqq.sel)
; CHECK: ret i32 %cqq.out
