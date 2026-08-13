; control_classical_call_arm_accept_onward_spec_newcand.ll — ACCEPT (bd 9paa,
; round-2 spec DETECTION; the detection twin of the 0vvq re-plan). A 6.5 classical-call
; arm's UNTAINTED merge `%out` is the SOLE argument of a visible pure body `@g(i32)`.
; Because ALL of `g`'s arguments were classical at round 1 (the merge was data-untainted),
; `g` never read a tainted operand at `detectSpecializations` (step 127, pre-emit) — so it
; is NOT in `plan6.Pending` and `replanReseedSpecialization` (0vvq Inc 2) does NOT touch it
; (the re-plan only updates EXISTING Pending candidates). dugh over-declined this
; `kMsgUnknownCallee`; 0vvq deferred it as bead test_C_libtooling-9paa.
;
; WHAT 9paa DOES: `repropagateControlMerges` re-taints `%out` (round-2), then RE-RUNS
; `detectSpecializations` on the reseed set, feeding the SAME `plan6`. `g(%out)` reads a
; reseed value (`%out`, an i32 quantum handle) and is not already Pending/Diagnosed, so it
; is DETECTED as a wholly-new candidate (mask `0b1`). The step-262 driver then clones the
; Q body `@__cq_q_g_1`: `mul %v,%v` lowers bare-QQ (`cq_template_mul_i32`, NOT `_hl`),
; reversed by its `_unc` twin, Bennett-wrapped (compute -> cqrt_copy_i32 -> reverse -> free
; scratch). `%out` is read as the superposed HANDLE it is, NOT the qubit-handle tag read as
; a classical `_hl` literal (the D2 verify-clean wrong unitary dugh/0vvq guarded against).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible pure body with a SINGLE parameter — all-classical at round 1.
define i32 @g(i32 %v) {
entry:
  %s = mul i32 %v, %v
  ret i32 %s
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
  %z = call i32 @g(i32 %y)     ; g(%out): NO tainted arg at round 1 -> a round-2 NEW candidate
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; Caller: the theta handle is allocated, the merge builds %out (controlled-XOR copy), and
; the call retargets to the mask-1 clone carrying %out as its single quantum handle arg.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_g_1(i32 %[[OUT]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; Clone: internal linkage, the single param a quantum handle; mul lowers bare-QQ (NOT _hl).
; CHECK:     define internal i32 @__cq_q_g_1(i32 %v)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %v, i32 %v)
; CHECK:     %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[CO]])
; CHECK:     call void @cq_template_mul_i32_unc(i32 %[[OP]], i32 %v, i32 %v)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     ret i32 %[[CO]]
;
; The %out qubit handle is read bare-QQ (never an _hl literal), the region ACCEPTS (no
; decline), and the source intrinsics are lowered.
; CHECK-NOT: cq_template_mul_i32_hl
; CHECK-NOT: cq_theta_si32
; ACC-NOT: under quantum control
; ACC-NOT: unknown callee
