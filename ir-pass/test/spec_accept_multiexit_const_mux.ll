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
; bd p3kd.7.8: `lowerCloneSelect` is gone; main's 4.4 `SelectMergeEmit` lowers the
; select with the same materialized |100> and |200> source rails, the merge's trailing
; `cqrt_x` strip is elided in the forward, and the wrap emits the exact mirror. Hand
; trace, |a>: SEL = [a>5]·100 ⊕ ¬[a>5]·200 copied out; the mirror undoes the 200 copy,
; restores the flag, undoes the 100 copy (SEL = 0), the `_unc` zeroes the flag; only
; the flag and SEL are freed, the two |const> rails stay allocated.
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

; CHECK-LABEL: define internal i32 @__cq_q_branchy_1(i32 %a)
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 5)
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; both classical sentinels materialized into leaked |const⟩ copy-source rails:
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[SEL]], i32 100)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[SEL]], i32 200)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; the single Bennett mirror + frees (materialized [[K100]]/[[K200]] left allocated):
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[SEL]], i32 200)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[SEL]], i32 100)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %a, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
