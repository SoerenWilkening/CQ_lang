; control_classical_call_arm_reject_impure.ll — purity reject (DD-7 / WI-5.4): a
; classical call inside a tainted-condition diamond arm whose callee has a SIDE
; EFFECT. The 6.5 lowering HOISTS the call into the pred so it runs
; unconditionally, so purity is NECESSARY for it to be observationally inert. An
; impure callee (here `@impure_f`, declared with NO `memory(none)`/`nounwind`/
; `willreturn` attributes, so it may write memory / throw / not return) would be
; executed even on the inactive branch, changing observable behavior.
; `classifyClassicalCallArm` gates on `!doesNotAccessMemory() ||
; mayHaveSideEffects()` and DECLINES loudly (the rejection set is load-bearing for
; the inert-hoist claim — §2.13). NEVER lowered.
;
; *** PURITY IS NOT SUFFICIENT, AND THIS FIXTURE PINS ONLY THE PURITY HALF ***
; (bd wve8). `mayHaveSideEffects()` is `mayWriteToMemory() || mayThrow() ||
; !willReturn()`, so it says nothing about IMMEDIATE UB inside the callee; a
; `memory(none) nounwind willreturn` callee that traps passed this gate and
; shipped a hoisted SIGFPE on a source with no UB on any basis state. The
; TOTALITY half is gated separately and pinned by
; control_classical_call_arm_reject_opaque_callee.ll (no visible body),
; control_classical_call_arm_twin_accept_partial_callee.ll (a visible PARTIAL body,
; hoisted since batch 053 only as its divisor-guarded twin) and
; control_classical_call_arm_accept_speculatable_decl.ll (the `speculatable`
; accept). Do not read this file as covering that.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED with a pure body and NO attribute group. That combination is
; what makes this fixture DISCRIMINATING again. With the old opaque `declare` the
; module failed the purity gate AND, independently, the new totality gate, so it
; was overdetermined: deleting the purity conjunct from the source left it green.
; A visible `add` body PASSES totality, so purity is the only thing declining it,
; and the one-edit arm-kill works again — add `#0` below and it ACCEPTS. The two
; gates separate exactly here because purity is ATTRIBUTE-based
; (`Call->doesNotAccessMemory()`) while totality is BODY-based.
define i32 @impure_f(i32 %a) {   ; no purity attrs — may write memory / throw
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @impure_f(i32 7)      ; impure — hoisting it would not be inert
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
