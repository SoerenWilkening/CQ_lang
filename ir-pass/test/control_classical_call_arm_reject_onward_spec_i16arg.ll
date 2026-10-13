; control_classical_call_arm_reject_onward_spec_i16arg.ll — ACCEPT since bd p3kd.9 (the
; historical name is kept; it was a DECLINE, bd 0vvq Increment 2, the re-plan's scope
; boundary). A 6.5 classical-call arm's `%out` is NARROWED (`trunc i32 %out to i16`) and
; passed to a Phase-6 candidate `@ipow16(i32, i16)`. At round 1 the merge is untainted, so
; `%y16` is a classical i16 arg and the candidate is masked `0b01`. The round-2 re-plan
; recomputes the mask to `0b11` (the narrowed `%out` is now quantum) and re-classifies.
; Until p3kd.9 `classifyCandidate` step (A) admitted only an i32 or fp tainted argument and
; this declined `floating-point quantum argument or return has no reversible copy`; i16 is
; now a lift-boundary width (`liftHandleWidth`: it has `cqrt_copy_i16`), so the re-plan
; lifts it with the grown mask.
;
; Semantic evidence (read off the lowered IR, 2b clean: 5 verified, 0 violation(s)): the
; caller builds the 6.5 merge rail `%out` = (q > 3) ? f(a) : 5 exactly as before, mints
; `%t = trunc_i32_to_i16(%out)`, calls `__cq_q_ipow16_11(h_q, %t)`, then uncomputes `%t`
; (`trunc_i32_to_i16_unc`) and frees it. The clone's i16 slot is the retyped i32 handle
; with logical width i16 in `HandleWidth`, so its `sext` lowers to
; `cq_template_sext_i16_to_i32`; it computes base*base + sext(exp) and is Bennett-wrapped
; (copy out, reverse, free scratch). The merge rail stays allocated (a control-owned rail,
; the leak main accepts at top level).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define void @example(
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i32_to_i16(i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_ipow16_11(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]])
; CHECK:     call void @cq_template_trunc_i32_to_i16_unc(i32 %[[T]], i32 %[[OUT]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-LABEL: define internal i32 @__cq_q_ipow16_11(i32 %base, i32 %exp)
; CHECK:     call i32 @cq_template_sext_i16_to_i32(i32 %exp)
; CHECK:     call void @cqrt_copy_i32(
; CHECK:     call void @cq_template_sext_i16_to_i32_unc(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible pure body whose second parameter is i16 (a non-i32 handle width).
define i32 @ipow16(i32 %base, i16 %exp) {
entry:
  %e = sext i16 %exp to i32
  %sq = mul i32 %base, %base
  %r = add i32 %sq, %e
  ret i32 %r
}

define void @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %y16 = trunc i32 %y to i16                 ; a NON-i32 %out-derivation
  %z = call i32 @ipow16(i32 %q, i16 %y16)    ; arg1 = tainted i16 -> re-plan step (A) FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
