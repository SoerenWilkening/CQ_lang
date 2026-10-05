; control_classical_call_arm_accept_onward_phase.ll — ACCEPT (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`) is
; measured: the controlled-XOR copy merge builds `%out` and `%m` measures `%out`.
;
; (History: the fixture was written for an ONWARD phase on the merge, pre-3qlq
; register form `y = cq_phi(y, 0.25)`, which PRE-dugh DECLINED at the merge-out
; gate and dugh lowered in place on `%out` after `repropagateControlMerges`
; re-seeded taint from it. The 3qlq migration deleted that uncontrolled phase, so
; the onward-phase subject is gone; the merge-then-measure path stays pinned.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
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
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge builds %out, then the measure reads %out:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; no controlled Rz, no surviving @cq_phi, and the region ACCEPTS:
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: @cq_phi
; ACC-NOT: under quantum control
