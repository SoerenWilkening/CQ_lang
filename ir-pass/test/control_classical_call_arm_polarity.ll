; control_classical_call_arm_polarity.ll — ACCEPT (WI-5.8 polarity probe): the
; classical-call-arm diamond in ORIENTATION B (the gate arm is the FALSE
; successor, `ArmNegated = true` — clang -O1 swaps the successors for an `if(q==k)`
; / `if(q!=k)` condition, Rule 9). `y = (q == 5) ? q : pure_f(7)`: cond-TRUE routes
; the straight-through `q` (Pred edge), cond-FALSE routes the call result (arm
; edge). The emitter orients by `ArmNegated`: the TRUE source is `q` (copied on the
; flag), the FALSE source is the materialized call result (copied on ¬flag,
; X-bracketed). Mirror of control_classical_call_arm_accept.ll with the operands
; swapped — proves the polarity handling is symmetric (a drift would compute
; out = (q==5) ? pure_f(7) : q, the WRONG mux).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
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
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm    ; gate arm is the FALSE successor (orient B)
arm:
  %r = call i32 @pure_f(i32 7)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; ArmNegated stream: the TRUE source is q (copied FIRST, on the flag); the FALSE
; source is the materialized call result (copied on ¬flag) — the operand order is
; the MIRROR of the un-negated accept fixture (the call result's alloc lands AFTER
; the first cqrt_x, like the select_qc classical FALSE operand):
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @pure_f(i32 7)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[RH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: phi i32
; CHECK-NOT: @__cq_q_

; the ¬flag bracket scope (the FALSE = call-result copy sits inside it):
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(

; ACCEPTS — no decline:
; ACC-NOT: under quantum control
