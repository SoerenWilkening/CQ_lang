; control_classical_call_arm_accept_onward_spec_call.ll — ACCEPT (bd 0vvq Increment 2,
; the Phase-6 spec-clone RE-PLAN; the D2 silent-miscompile core). The dugh regression
; that DECLINED (control_classical_call_arm_reject_onward_spec_call.ll, now deleted):
; a 6.5 classical-call arm whose UNTAINTED merge `%out` is passed to a ROUND-1 Phase-6
; specialization candidate `@ipow` whose per-arg MASK was frozen CLASSICAL for that
; argument at `detectSpecializations` (pre-emit).
;
; WHAT INCREMENT 2 UNFREEZES: the "frozen plan" is the `plan6.Pending` candidate's MASK
; (fixed at detection, step 127), NOT a built clone — the specialization DRIVER runs at
; step 262, DOWNSTREAM of `repropagateControlMerges` (step 200). So `replanReseedSpecialization`
; simply RECOMPUTES the mask against the round-2 taint (`%out` now QUANTUM) — `0b01 -> 0b11` —
; re-classifies (Accept: `%out` is an i32 handle), and UPDATES the Pending mask. The driver
; then clones the Q+Q body `@__cq_q_ipow_11`: `mul %base,%base` and `add %sq,%exp` BOTH lower
; QQ (`cq_template_mul_i32` / `cq_template_add_i32`, bare, NOT `_hl`), reversed by their
; `_unc` twins. `%exp` is now the superposed `%out` value, NOT the qubit-handle tag read as a
; classical `_hl` literal (the verify-clean wrong unitary dugh over-declined). Same `@ipow`
; body as spec_accept_two_arg_mask.ll — only the mask (and so the clone) flips 01 -> 11.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible pure body — the Phase-6 clone-on-taint candidate.
define i32 @ipow(i32 %base, i32 %exp) {
entry:
  %sq = mul i32 %base, %base
  %r = add i32 %sq, %exp
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
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]   ; UNTAINTED merge -> %out (quantum in round 2)
  %z = call i32 @ipow(i32 %q, i32 %y)        ; arg0=%q (round-1 Q), arg1=%y=%out (round-2 Q, re-planned)
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; Caller: the theta handle is allocated, the merge builds %out (controlled-XOR copy), and
; the call retargets to the MASK-11 clone carrying the theta handle in arg0 and %out in arg1.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_ipow_11(i32 %[[H]], i32 %[[OUT]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; Clone: internal linkage, BOTH params quantum handles; add lowers bare-QQ (NOT _hl).
; CHECK:     define internal i32 @__cq_q_ipow_11(i32 %base, i32 %exp)
; CHECK:     %[[SQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %base, i32 %base)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[SQ]], i32 %exp)
; CHECK:     %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[CO]])
; CHECK:     call void @cq_template_add_i32_unc(i32 %[[OP]], i32 %[[SQ]], i32 %exp)
; CHECK:     call void @cq_template_mul_i32_unc(i32 %[[SQ]], i32 %base, i32 %base)
; CHECK:     ret i32 %[[CO]]
;
; The frozen-plan _hl miscompile is GONE (exp is a handle, not an _hl literal), the region
; ACCEPTS (no decline), and the source intrinsics are lowered.
; CHECK-NOT: cq_template_add_i32_hl
; CHECK-NOT: cq_theta_si32
; ACC-NOT: under quantum control
