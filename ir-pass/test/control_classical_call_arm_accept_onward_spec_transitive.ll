; control_classical_call_arm_accept_onward_spec_transitive.ll — ACCEPT (bd 0vvq
; Increment 2): the round-2 spec-clone re-plan is TRANSITIVE. A 6.5 classical-call arm
; builds `%out`; it feeds `@outer(q, %out)`, a Phase-6 candidate whose body calls a
; NESTED classical helper `@inner(exp)`. At round 1 the merge is untainted, so
; `outer(q, %out)` is masked `0b01` and — crucially — `inner(%exp)` reads the CLASSICAL
; `%exp` param, so it is an ordinary classical subcall (NOT specialized). Re-planning the
; top mask to `0b11` (`%out` quantum) seeds BOTH of the clone's params, so `inner(%exp)`
; now reads a TAINTED arg and the DRIVER's existing depth-first 6.3 machinery specializes
; it: the inner clone `@__cq_q_inner_1` (|x>|0> -> |x>|x*x>) plus its VOID uncompute twin
; `@__cq_q_inner_1_unc`, reversed inside the outer Bennett wrap. This proves the re-plan
; needs NO new transitive code — updating the top mask is consumed by the 6.3 recursion.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

define i32 @inner(i32 %x) {
entry:
  %s = mul i32 %x, %x
  ret i32 %s
}

define i32 @outer(i32 %base, i32 %exp) {
entry:
  %i = call i32 @inner(i32 %exp)     ; round-1: classical subcall; round-2: __cq_q_inner_1
  %r = add i32 %base, %i
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
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %z = call i32 @outer(i32 %q, i32 %y)   ; re-planned 0b01 -> 0b11
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; The top clone is mask-11; its body calls the transitively-specialized inner clone
; (a quantum handle result) whose void uncompute twin the outer wrap reverses.
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_outer_11(
; CHECK:     define internal i32 @__cq_q_outer_11(i32 %base, i32 %exp)
; CHECK:     %[[I:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_inner_1(i32 %exp)
; CHECK:     call i32 @cq_template_add_i32(i32 %base, i32 %[[I]])
; The inner clone is reversed in the outer wrap via its VOID uncompute twin.
; CHECK:     call void @__cq_q_inner_1_unc(i32 %[[I]], i32 %exp)
; CHECK:     define internal i32 @__cq_q_inner_1(i32 %x)
; CHECK:     call i32 @cq_template_mul_i32(i32 %x, i32 %x)
; CHECK:     define internal void @__cq_q_inner_1_unc(i32 %out, i32 %x)
;
; No stale-mask _hl leak of the merged register, and the region accepts.
; CHECK-NOT: cq_template_add_i32_hl
; ACC-NOT: under quantum control
