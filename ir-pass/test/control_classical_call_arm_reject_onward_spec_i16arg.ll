; control_classical_call_arm_reject_onward_spec_i16arg.ll — DECLINE (bd 0vvq Increment 2,
; the re-plan's scope boundary). A 6.5 classical-call arm's `%out` is NARROWED
; (`trunc i32 %out to i16`) and passed to a Phase-6 candidate `@ipow16(i32, i16)`. At
; round 1 the merge is untainted, so `%y16` is a classical i16 arg and the candidate is
; masked `0b01` (Accept — arg0 the theta handle is i32). The round-2 re-plan recomputes the
; mask to `0b11` (the narrowed `%out` is now quantum) and re-classifies: `classifyCandidate`
; step (A) requires EVERY tainted argument to arrive as an i32 handle (Rule 15, the runtime
; ABI), but arg1 is a TAINTED i16 — no i32-handle representation. So the re-plan CANNOT
; unfreeze it: it declines LOUDLY with the precise specialization ABI message (NOT dugh's
; generic "under quantum control", NOT the escape net's "unknown callee"), marks it
; Diagnosed, and drops it from Pending so the driver never clones a stale-mask body.
; Over-decline is safe (Prime Directive): a narrowed / non-i32 reseed value is outside the
; i32-handle clone ABI.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; bd 3c6m.82 (LiftDiagnostics.h): this error is located in the USER's function while the
; re-plan lifts the site, so no "lifted from here" note precedes it (a note would print first).
; CHECK-NOT: note:
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; (R10, 2026-10-08: the CHECK-NOT lines that followed the error were removed as vacuous —
; opt exits on the first DS_Error, so nothing can follow it.)
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
