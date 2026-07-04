; control_classical_call_arm_reject_onward_spec_newcand.ll — DECLINE (bd 0vvq Increment 2,
; the SCOPE-BOUNDARY probe: round-2 spec RE-PLAN vs round-2 spec DETECTION). A 6.5
; classical-call arm's `%out` is the SOLE argument of a visible pure body `@g(i32)`.
; Because ALL of `g`'s arguments were classical at round 1 (the merge was data-untainted),
; `g` never read a tainted operand at `detectSpecializations` — so it is NOT in `plan6.Pending`
; and NOT a re-plan target. Increment 2 re-plans an EXISTING Pending candidate (a mask that
; GREW); it deliberately does NOT re-DETECT a wholly-new round-2 candidate (that is a distinct
; capability — a round-2 `detectSpecializations`, interacting with the already-flattened
; control + the Diagnosed dedup — tracked as follow-on bd test_C_libtooling-9paa). So this call stays declined by the
; re-run escape net: a visible-body callee consuming a tainted value it does not own, the
; generic `kMsgUnknownCallee`. Over-decline is safe (Prime Directive); pinning it here proves
; the re-plan does NOT silently widen into round-2 detection.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible pure body with a SINGLE parameter — all-classical at round 1.
define i32 @g(i32 %v) {
entry:
  %s = mul i32 %v, %v
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
  %z = call i32 @g(i32 %y)     ; g(%out): NO tainted arg at round 1 -> never a candidate
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
