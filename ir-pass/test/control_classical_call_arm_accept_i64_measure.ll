; control_classical_call_arm_accept_i64_measure.ll — SURGICAL-BOUNDARY accept
; (8mld): the classical-call arm 8mld fix is a per-consumer MERGE-OUT ESCAPE GATE,
; NOT a blanket "i32 merge only" decline. A measurement sink's handle-arg is i32 at
; EVERY width and the sink RE-TYPES its result (`cqrt_measure_i64(i32 handle) ->
; i64`), so a non-i32 merge consumed ONLY by a measure stays ACCEPTED — the direct
; contrast to control_classical_call_arm_reject_nonI32_ret.ll (same i64 merge, but
; a `ret` escape declines). This pins that the crash fix does NOT over-decline the
; working i64-measure shape (Rule 17: do not gate the intended shape behind an
; over-safe decline).
;
; SOURCE INTENT: `int64_t y = 5; if (q > 3) y = f(a); measure y;` — f is pure
; (memory(none)/willreturn/nounwind), all-classical args. Handle args stay i32;
; only the measure RETURN widens to i64.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_measure_sll(i64)
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
  %r = call i64 @f(i64 %a)
  br label %merge
merge:
  %y = phi i64 [ %r, %arm ], [ 5, %entry ]
  %m = call i64 @cq_measure_sll(i64 %y)
  ret i64 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge fires over the i64 rail (handles are i32; only the
; measure return is i64), and the merge lowers to `cqrt_measure_i64(i32 %out)`:
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK:     ret i64
; no surviving diamond phi (RAUW'd to %out) and NO clone:
; CHECK-NOT: phi i64
; CHECK-NOT: @__cq_q_

; the region ACCEPTS (lowers) — no decline of any kind:
; ACC-NOT: under quantum control
