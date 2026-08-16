; control_classical_call_arm_reject_onward_spec_newcand_inbody.ll — DECLINE (bd 9paa,
; the round-2 DETECTION decline path + the Diagnosed dedup, filter (d)). A 6.5 classical-call
; arm's `%out` is the SOLE argument of a wholly-new candidate `@g(i32)` whose body has a
; tainted-scrutinee SWITCH (an N-way routing shape `scanBody` declines at detection — 5po2
; I2 lifts `br` diamonds / controlled-returns, but an in-clone `switch` is a later
; increment). Because `g`'s arg was classical at round 1, it is a round-2 NEW candidate
; (never in Pending, so `replanReseedSpecialization` skips it). The round-2
; `detectSpecializations` (9paa) DETECTS it (reads the reseed `%out`), but
; `classifyCandidate`/`scanBody` rejects the `switch` terminator `InBodyControl`. So
; round-2 detection LOUD-DECLINES it with the precise specialization message and records it
; in `plan6.Diagnosed`, so the re-run `declineTaintEscapes` carve suppresses the generic
; `kMsgUnknownCallee` — exactly ONE diagnostic, not a confusing pair.
; Over-decline is safe (Prime Directive): a switch-routed callee is not yet reversibilizable.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
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
; a visible body with a tainted-scrutinee SWITCH — never liftable (scanBody InBodyControl).
define i32 @g(i32 %v) {
entry:
  switch i32 %v, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  ret i32 10
o:
  ret i32 20
def:
  %d = add i32 %v, 3
  ret i32 %d
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
  %z = call i32 @g(i32 %y)      ; round-2 NEW candidate g(%out) -> in-body-control decline
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
