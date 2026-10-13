; control_classical_call_arm_reject_onward_spec_newcand_fparg.ll — ACCEPT since bd p3kd.9
; (the historical name is kept; it was a DECLINE, bd 9paa, the round-2 DETECTION step-(A)
; ABI boundary). A 6.5 classical-call arm's `%out` is NARROWED (`trunc i32 %out to i16`) and
; passed as the SOLE argument of a wholly-new candidate `@g16(i16)`. Because `g16`'s arg was
; classical at round 1, it is a round-2 NEW candidate (never in Pending — distinct from the
; re-plan's `reject_onward_spec_i16arg.ll`, where `ipow16` is a ROUND-1 candidate). The
; round-2 `detectSpecializations` (9paa) DETECTS it (reads the reseed `%y16`). Until p3kd.9
; `classifyCandidate` step (A) admitted only an i32 or fp tainted argument and this declined
; `floating-point quantum argument or return has no reversible copy`; i16 is now a
; lift-boundary width (`liftHandleWidth`), so round-2 detection lifts it.
;
; Semantic evidence (read off the lowered IR, 2b clean: 4 verified, 0 violation(s)): the
; caller builds the merge rail `%out` = (q > 3) ? f(a) : 5, mints
; `%t = trunc_i32_to_i16(%out)`, calls `__cq_q_g16_1(%t)` and uncomputes and frees `%t`
; after it. The clone reads the i16 handle through `cq_template_sext_i16_to_i32` (its
; logical width recorded in `HandleWidth`), squares it and is Bennett-wrapped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define void @example(
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i32_to_i16(i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_g16_1(i32 %[[T]])
; CHECK:     call void @cq_template_trunc_i32_to_i16_unc(i32 %[[T]], i32 %[[OUT]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-LABEL: define internal i32 @__cq_q_g16_1(i32 %v)
; CHECK:     call i32 @cq_template_sext_i16_to_i32(i32 %v)
; CHECK:     call void @cqrt_copy_i32(
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible pure body whose SOLE parameter is i16 (a non-i32 handle width).
define i32 @g16(i16 %v) {
entry:
  %e = sext i16 %v to i32
  %s = mul i32 %e, %e
  ret i32 %s
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
  %y16 = trunc i32 %y to i16               ; a NON-i32 %out-derivation (reseed value)
  %z = call i32 @g16(i16 %y16)             ; round-2 NEW candidate; tainted i16 arg -> FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
