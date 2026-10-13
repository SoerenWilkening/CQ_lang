; control_classical_call_arm_accept_onward_ctl_spec_newcand.ll — ACCEPT (bd afmv + 9paa, the
; CASCADE the afmv reseed expansion now handles). TWO chained 6.5 classical-call arms (as in
; accept_onward_ctl_spec_replan): region 1 `if(q>5)` -> %out1 (round-1 rail); region 2
; `if(%out1>50)` -> %out2 (a yn71-produced control rail, lowered by `detectAndLowerOnwardControl`
; in round 2). Here the downstream candidate `h(%out2)` reads ONLY the %out2 rail (NO theta
; handle), so it was ALL-classical at round-1 `detectSpecializations` and never entered
; `plan6.Pending` — a WHOLLY-NEW candidate off a control rail.
;
; PRE-afmv this stayed a safe `kMsgUnknownCallee` decline (9paa's reseed set was frozen before
; the yn71 fixpoint, excluding %out2). WITH the afmv fix the reseed set is computed AFTER
; `detectAndLowerOnwardControl`, so %out2 is in it and 9paa's round-2 `detectSpecializations`
; DETECTS `h(%out2)`, cloning `@__cq_q_h_1` with a bare-QQ `cq_template_mul_i32` reading the
; %out2 rail as a HANDLE (the cascade is now lowered, not over-declined — the combined
; spec/control fixpoint capability the afmv ordering unlocks).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
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
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible pure body with a SINGLE parameter — all-classical at round 1 (reads only %out2).
define i32 @h(i32 %v) {
entry:
  %s = mul i32 %v, %v
  ret i32 %s
}

define void @example(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]
  %c2 = icmp sgt i32 %out1, 50
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @f(i32 %aa)
  br label %merge2
merge2:
  %out2 = phi i32 [ %r2, %arm2 ], [ 6, %merge1 ]
  %z = call i32 @h(i32 %out2)      ; NEW candidate off the yn71 %out2 rail (round-2 DETECTED)
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; The %out2 rail (built by controlled copies under the icmp(%out1,50) flag) is the single
; quantum handle arg of the mask-1 clone — read bare-QQ, never an _hl literal.
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 50)
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_h_1(i32 %[[OUT2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK:     define internal i32 @__cq_q_h_1(i32 %v)
; CHECK:     call i32 @cq_template_mul_i32(i32 %v, i32 %v)
;
; The cascade is LOWERED (not over-declined), reading %out2 bare-QQ.
; CHECK-NOT: cq_template_mul_i32_hl
; ACC-NOT: under quantum control
; ACC-NOT: unknown callee
