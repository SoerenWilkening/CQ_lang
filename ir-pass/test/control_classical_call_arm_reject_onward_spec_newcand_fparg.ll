; control_classical_call_arm_reject_onward_spec_newcand_fparg.ll — DECLINE (bd 9paa,
; the round-2 DETECTION step-(A) ABI boundary). A 6.5 classical-call arm's `%out` is
; NARROWED (`trunc i32 %out to i16`) and passed as the SOLE argument of a wholly-new
; candidate `@g16(i16)`. Because `g16`'s arg was classical at round 1, it is a round-2 NEW
; candidate (never in Pending — distinct from the re-plan's `reject_onward_spec_i16arg.ll`,
; where `ipow16` is a ROUND-1 candidate re-planned to FpAbi). The round-2
; `detectSpecializations` (9paa) DETECTS it (reads the reseed `%y16`), but
; `classifyCandidate` step (A) requires every TAINTED argument to arrive as an i32 handle
; (Rule 15, the runtime ABI): arg0 is a TAINTED i16, no i32-handle representation. So
; detection LOUD-DECLINES it with the precise specialization ABI message and records it
; Diagnosed, so the re-run `declineTaintEscapes` carve suppresses the generic
; `kMsgUnknownCallee`. Over-decline is safe (Prime Directive): a narrowed reseed value is
; outside the i32-handle clone ABI.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: unknown callee
; CHECK-NOT: under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatablePureCallee`). The old
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
