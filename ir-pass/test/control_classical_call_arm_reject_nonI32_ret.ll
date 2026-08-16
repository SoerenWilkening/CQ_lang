; control_classical_call_arm_reject_nonI32_ret.ll — NON-i32 RETURN reject (8mld;
; re-routed by dugh): a PURE classical call inside a tainted-condition diamond arm
; whose merge phi is `i64` and is consumed by a DIRECT `ret i64`. The 6.5 emitter
; RAUWs the merge phi to the FRESH `%out` handle, and `cqrt_alloc_<W>` returns an
; i32 at every width (Rule 15) — so accepting this leaves `ret i64 <i32 handle>`, a
; BROKEN MODULE the LLVM verifier aborts on, NOT a Rule-1 source-located decline. A
; crash on well-formed valid input (opt -verify exit 0) violates Rule 1.
;
; The merge phi is UNTAINTED (a classical call result + a classical constant), so
; the FIRST `declineTaintEscapes` (pre-emit, TAINT-gated) never sees it. dugh
; (Phase 4×6) retired the detection-time merge-out gate and instead RE-SEEDS a
; second propagation from the emitted `%out` (`repropagateControlMerges`) and
; re-runs the escape net: the now-tainted `ret` declines via the precise
; `kMsgNonI32Return`. The return-escape check keys on the FUNCTION return type (i64),
; NOT the RAUW'd RV type (i32) — so it catches the post-emit mismatch and declines
; BEFORE the verifier ever sees the broken module (`exit(1)` on the DS_Error). The
; non-i32 raw quantum return is the (A1) ABI limit that STAYS declined (feature
; jx32); dugh converts only the (A2) onward-quantum subset. NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value returned at non-i32 width
declare i32 @cq_theta_si32(i32, double)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i64 @f(i64 %a) #0 {
  %s = add i64 %a, 100
  ret i64 %s
}

define i64 @example(i32 %u0, i64 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i64 @f(i64 %a)                       ; PURE, all-classical args — 6.5 shape
  br label %merge
merge:
  %y = phi i64 [ %r, %arm ], [ 5, %entry ]       ; UNTAINTED i64 merge
  ret i64 %y                                     ; non-i32 ret of the RAUW'd i32 handle
}

attributes #0 = { nounwind willreturn memory(none) }
