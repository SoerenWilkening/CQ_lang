; control_classical_call_arm_reject_onward_spec_newcand_inbody.ll — DECLINE (bd 9paa,
; the round-2 DETECTION decline path + the Diagnosed dedup, filter (d)). A 6.5 classical-call
; arm's `%out` is the SOLE argument of a wholly-new candidate `@g(i32)` whose body has
; IN-BODY control flow (`if (v>0) v+1 else v-1`, a multi-block value body). Because `g`'s
; arg was classical at round 1, it is a round-2 NEW candidate (never in Pending, so
; `replanReseedSpecialization` skips it). The round-2 `detectSpecializations` (9paa) DETECTS
; it (reads the reseed `%out`), but `classifyCandidate`/`scanBody` rejects the multi-block
; body `InBodyControl` — a straight-line value body is the only liftable shape (§8). So
; round-2 detection LOUD-DECLINES it with the precise specialization message and records it
; in `plan6.Diagnosed`, so the re-run `declineTaintEscapes` carve suppresses the generic
; `kMsgUnknownCallee` — exactly ONE diagnostic, not a confusing pair.
; Over-decline is safe (Prime Directive): an in-body-control callee is not reversibilizable.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: unknown callee
; CHECK-NOT: under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible body with IN-BODY control (multi-block) — never liftable (scanBody InBodyControl).
define i32 @g(i32 %v) {
entry:
  %c = icmp sgt i32 %v, 0
  br i1 %c, label %pos, label %neg
pos:
  %a = add i32 %v, 1
  br label %done
neg:
  %b = sub i32 %v, 1
  br label %done
done:
  %r = phi i32 [ %a, %pos ], [ %b, %neg ]
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
  %z = call i32 @g(i32 %y)      ; round-2 NEW candidate g(%out) -> in-body-control decline
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
