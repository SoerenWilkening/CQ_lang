; lowering_reject_bitint_raw_iN.ll — Phase 7.1 follow-up D5 (test_C_libtooling-m0yi)
; SAFETY-NET DECLINE (Rule 12, the guard the plan's R-D wanted). clang -O1 never
; emits a raw non-ABI `iN` arithmetic op for _BitInt(N) — it rounds to the ABI
; storage width and masks (see lowering_bitint_intermediate_masked_i40.ll). But IF
; a raw non-ABI width ever reaches a tainted op (a hypothetical -O0 artifact, a
; future codegen change, or a hand-written module), it MUST loud-decline, never
; silently round-up-without-mask (which would be a verify-clean overflow
; miscompile — the i40 wraparound semantics differ from i64).
;
; The reachable gate is the CAST to the non-ABI width: a tainted `trunc i64 -> i40`
; has no template (abiWidthFromType(i40) empty, castInScope false), so it declines
; at the cast BEFORE any raw `add i40` could be reached. This pins that a non-ABI
; intermediate is rejected loudly + source-located, never lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i64 @cq_theta_sll(i64, double)

define void @ex(i64 %u0) {
  %q = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %t = trunc i64 %q to i40
  %s = add i40 %t, %t
  ret void
}

; CHECK: error{{.*}}no template for opcode 'trunc i40' in tainted context
; CHECK-NOT: cq_template
