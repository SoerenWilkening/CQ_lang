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
; bd p3kd.21 / bd jx32 (2026-10-14) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. The function has no in-module use (an entry
; point / export, `declineQuantumReturnCalls`' Escaped contract) and returns an
; integer WIDER than 32 bits, so its tainted `ret` returns the register's i32
; runtime handle ZERO-EXTENDED to the declared width (`widenQuantumExportReturns`,
; SpecializeGateInline.h; owner ruling owner-ruling-p3kd21-gate-subroutines-2026-10-14: approved for
; integer returns of 32 bits or wider only). The C signature is unchanged, so the
; verifier-abort hazard above cannot arise. L9: this extends the escaped-handle
; contract of i32 returns to i64 callers, cross-TU ones included. The gate stream
; is the one the i32-typed twin of the same body emits (measured on the value
; diamond: identical, call for call; the twin's arm chain is left allocated
; exactly as there). The non-i32 decline remains for a narrower integer or an fp
; return (spec_reject_gate_sub_export_{bool,double}.ll, lowering_reject_f16_return.ll)
; and for a function WITH an in-module use (spec_reject_gate_sub_indirect_nonI32.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i64 @example(i32 %u0, i64 %a)
; CHECK: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[R:%[0-9a-z_.]+]] = {{(tail )?}}call i64 @f(i64 %a)
; CHECK-NEXT: [[C:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 3)
; CHECK-NEXT: [[OUT:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: [[S1:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 [[R]])
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 [[C]], i32 [[S1]], i32 [[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 [[C]])
; CHECK-NEXT: [[S2:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 5)
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 [[C]], i32 [[S2]], i32 [[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 [[C]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C]], i32 [[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 [[C]])
; CHECK-NEXT: [[W:%[0-9a-z_.]+]] = zext i32 [[OUT]] to i64
; CHECK-NEXT: ret i64 [[W]]
declare i32 @cq_theta_si32(i32, double)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
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
