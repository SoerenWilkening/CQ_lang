; control_classical_call_arm_accept_i32_ret.ll — ESCAPE-BRANCH accept (8mld): the
; MERGE-OUT ESCAPE GATE admits a `ret` AT i32 (the caller owns the escaped handle —
; FreePoint's Escaped case). An i32 merge phi consumed by a DIRECT `ret i32` (no
; measurement) ACCEPTS and lowers; the returned value is the RAUW'd `%out` i32
; handle. This exercises the `isa<ReturnInst> && MergeIsI32` accept branch of the
; gate (distinct from the measure-sink branch covered by
; control_classical_call_arm_accept.ll / _accept_i64_measure.ll) — guarding against
; a future over-tightening that would decline ALL rets. The i64-width sibling of
; this exact shape DECLINES (control_classical_call_arm_reject_nonI32_ret.ll).
;
; SOURCE INTENT: `int y = 5; if (q > 3) y = f(a); return y;` — f is pure, all
; classical args.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  ret i32 %y
}

attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge fires and the i32 handle escapes via ret:
; CHECK:     call void @cqrt_xorc_i32_controlled(
; CHECK:     ret i32 %[[OUT:[a-zA-Z0-9_.]+]]
; no surviving diamond phi (RAUW'd to %out) and NO clone:
; CHECK-NOT: phi i32
; CHECK-NOT: @__cq_q_

; the region ACCEPTS (lowers) — no decline of any kind:
; ACC-NOT: under quantum control
