; control_classical_call_arm_reject_onward_ctl_spec_fparg.ll — ACCEPT since bd p3kd.9 (the
; historical name is kept; it was a DECLINE, bd afmv, the chained onward-control re-plan's
; ABI boundary). TWO chained 6.5 classical-call arms build a yn71 %out2 control rail (as in
; accept_onward_ctl_spec_replan), and the round-1 Pending candidate `gg16` reads a NARROWED
; `trunc i32 %out2 to i16`. At round 1 `gg16` reads the theta handle `q` (mask 0b10). The
; afmv re-plan recomputes the mask against the FINAL post-yn71 taint (the %out2 rail is now
; in the reseed set): the mask grows to 0b11. Until p3kd.9 `classifyCandidate` step (A)
; admitted only an i32 or fp tainted argument and the re-plan declined `floating-point
; quantum argument or return has no reversible copy`; i16 is now a lift-boundary width
; (`liftHandleWidth`), so the re-plan lifts it with the grown mask (the afmv analog of
; `reject_onward_spec_i16arg.ll`, over a yn71 %out2 rail).
;
; Semantic evidence (read off the lowered IR, 2b clean: 5 verified, 0 violation(s)): the two
; merge rails are built as before ((q > 5) ? f(aa) : 5, then (out > 50) ? f(aa) : 6), the
; caller mints `%t = trunc_i32_to_i16(%out3)`, calls `__cq_q_gg16_11(%t, h_q)` and uncomputes
; and frees `%t` after it; the clone reads the i16 handle through
; `cq_template_sext_i16_to_i32`, multiplies by `b` and is Bennett-wrapped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define void @example(
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i32_to_i16(i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_gg16_11(i32 %[[T]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cq_template_trunc_i32_to_i16_unc(i32 %[[T]], i32 %[[OUT]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-LABEL: define internal i32 @__cq_q_gg16_11(i32 %a, i32 %b)
; CHECK:     call i32 @cq_template_sext_i16_to_i32(i32 %a)
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
; a visible pure body whose first parameter is i16 (a non-i32 handle width).
define i32 @gg16(i16 %a, i32 %b) {
entry:
  %e = sext i16 %a to i32
  %s = mul i32 %e, %b
  ret i32 %s
}

define void @example(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]
  %c2 = icmp sgt i32 %out1, 50
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @f(i32 %aa)
  br label %merge2
merge2:
  %out2 = phi i32 [ %r2, %arm2 ], [ 6, %merge1 ]
  %w16 = trunc i32 %out2 to i16                ; a NON-i32 %out2-derivation (reseed value)
  %z = call i32 @gg16(i16 %w16, i32 %q)        ; round-1 Pending 0b10; re-plan -> 0b11 step-A FpAbi
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
