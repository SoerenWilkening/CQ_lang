; control_classical_call_arm_reject_escape_leak.ll — HANDLE-LEAK reject (8mld;
; re-routed by dugh): a PURE classical call inside a tainted-condition diamond arm
; whose i32 merge phi is consumed by a `store` to a CLASSICAL pointer. The 6.5
; emitter RAUWs the merge phi to the FRESH `%out` QUBIT handle; a `store i32 <handle>`
; would SILENTLY write the register id to classical memory — a verify-clean
; classical-over-quantum leak (the (A1) escape that must stay declined).
;
; The merge is UNTAINTED (classical call result + constant), so the FIRST
; `declineTaintEscapes` (TAINT-gated) never fires. dugh (Phase 4×6) retired the
; detection-time merge-out gate and RE-SEEDS a second propagation from the emitted
; `%out` (`repropagateControlMerges`); the now-tainted `store` declines via the
; precise `kMsgStore`. The opaque-ptr store is the (A1) escape that STAYS declined;
; dugh converts only the (A2) onward-QUANTUM subset (arith/phase → measure). NEVER
; lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value stored to memory
declare i32 @cq_theta_si32(i32, double)
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
define void @example(i32 %u0, i32 %a, ptr %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)                        ; PURE, all-classical args — 6.5 shape
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]        ; UNTAINTED i32 merge
  store i32 %y, ptr %p                            ; LEAK: writes the qubit handle to memory
  ret void
}

attributes #0 = { nounwind willreturn memory(none) }
