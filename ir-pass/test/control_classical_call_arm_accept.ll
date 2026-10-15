; control_classical_call_arm_accept.ll — ACCEPT: a pure classical call inside a
; tainted-condition `br`-diamond arm, its i32 result routed into the controlled
; register via the 4.4 controlled-XOR copy merge over a FLATTENED diamond (6.5,
; DD-7). NO clone, NO cswap/route, NO reverse-play.
;
; SOURCE INTENT: `int y = q; if (q > 5) y = pure_f(7);  measure y;` — `pure_f` is
; a VISIBLE `memory(none)` (readnone) callee with a CLASSICAL constant arg, so
; the diamond's merge phi is [%q (tainted, straight-through Pred edge), %r (a
; direct classical call result, arm edge)]. `classifyClassicalCallArm` recognizes
; it: the call is HOISTED into Pred (inert because pure), then the controlled-copy
; merge fires — mint the flag from the icmp -> alloc the |0> out rail -> copy the
; TRUE / cond-true value (%r, the call result, materialized via cqrt_alloc) on the
; flag -> X-bracket + copy the FALSE / cond-false value (%q, tainted -> identity)
; on ¬flag -> icmp_inv strip -> the ONE cqrt_free (the flag) -> RAUW %y -> %out ->
; FLATTEN the dead diamond. q, %out, and the materialized scratch are LEFT
; ALLOCATED (freeing an operand entangled with %out via the copy is a hidden
; measurement, Rule 6/8).
;
; This is the clone-ORTHOGONAL Phase-6 capability (DD-7): all-classical-args means
; `readsTaintedValue` is false, so the call is in NO SpecPlan candidate set and is
; never declined by `declineTaintEscapes` — there is NO clone (`@__cq_q_`), the
; call arg 7 is never promoted to a qubit handle (no input-tainting).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
define i32 @pure_f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pure_f(i32 7)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge stream, in §5a contract order. The scrutinee
; theta lowers to the alloc+ry handle (RAUW q -> the i32 handle); the pure call is
; HOISTED into the (now straight-line) pred ahead of the flag mint:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @pure_f(i32 7)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 %[[R]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; the merge is a COPY, not a route — no cswap, no controlled rotation, no
; surviving diamond phi (NARROWED: bare `_controlled` would false-fire on the
; intended copy_controlled):
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: cqrt_ry{{.*}}_controlled
; CHECK-NOT: phi i32
; NO clone (clone-orthogonal — DD-7); the call arg is never qubit-allocated:
; CHECK-NOT: @__cq_q_

; the ¬flag bracket scope is order-sensitive (§16.3, verify-clean-invisible): a
; mis-bracket (x before BOTH copies) yields the IDENTICAL symbol multiset. Pin
; write -> x -> write -> x (bd dm7f.81: the classical-call arm is an xorc):
; ORD: call void @cqrt_xorc_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(

; exactly ONE cqrt_free (the flag; q/%out/scratch leak), and EXACTLY TWO cqrt_x
; (pins the bracket COUNT — a stray 3rd x computes the swapped/dirty-flag unitary
; out=f?False:True yet still matches ORD):
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; XCT-COUNT-2: call void @cqrt_x(
; XCT-NOT:     call void @cqrt_x(

; the region ACCEPTS (lowers) — no decline of any kind:
; ACC-NOT: under quantum control
