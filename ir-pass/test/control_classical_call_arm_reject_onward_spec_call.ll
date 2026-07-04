; control_classical_call_arm_reject_onward_spec_call.ll — DECLINE (dugh, Phase 4×6;
; the spec-clone silent-miscompile regression): a 6.5 classical-call arm whose
; UNTAINTED merge `%out` is passed as an argument to a ROUND-1 Phase-6 specialization
; candidate whose clone mask treats that argument as CLASSICAL.
;
; THE MISCOMPILE THIS PINS (found by the dugh Rule-13 adversarial sweep, fixed by
; `declineReseedIntoSpecCalls`): `detectSpecializations` (pre-emit) clones `@ipow`
; from the ROUND-1 taint — arg0 `%q` is the theta handle (quantum), arg1 `%y` is the
; then-untainted merge (classical) — lowering the body's `base+exp` as
; `cq_template_add_i32_hl(base, exp)` with `exp` a CLASSICAL LITERAL. dugh re-taints
; `%out` (= the `y` argument) in round 2, but the clone's mask is FROZEN: the emitted
; `_hl` template would read the `%out` QUBIT HANDLE as a literal (adding the handle
; tag, not the superposed value) — a verify-clean silent miscompile. PRE-dugh this
; declined at the retired merge-out gate. dugh declines it BEFORE the
; `declineTaintEscapes` `shouldSpecialize` carve would let it through, because a
; specialized call consuming a control-merge register is a clone×merge composition
; (deferred Phase 4×6), out of dugh's arith/phase scope. A round-1-only spec call (no
; `%out` argument) still clones normally. NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible pure body — the Phase-6 clone-on-taint candidate.
define i32 @ipow(i32 %base, i32 %exp) {
entry:
  %sq = mul i32 %base, %base
  %r = add i32 %sq, %exp
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
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]   ; UNTAINTED merge -> %out (quantum in round 2)
  %z = call i32 @ipow(i32 %q, i32 %y)        ; arg0=%q (round-1 Q), arg1=%y=%out (round-2 Q, C-mask)
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
