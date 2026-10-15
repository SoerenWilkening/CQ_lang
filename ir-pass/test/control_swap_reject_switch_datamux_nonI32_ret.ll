; control_swap_reject_switch_datamux_nonI32_ret.ll — NON-i32 RETURN reject (8mld,
; the switch sibling of control_classical_call_arm_reject_nonI32_ret.ll;
; re-routed by dugh): a tainted-scrutinee `switch` whose all-`ConstantInt` merge phi
; is `i64` and is consumed by a DIRECT `ret i64`. The data-mux emitter preloads +
; XOR-delta-copies into a FRESH `%out` handle and RAUWs the merge phi to it;
; `cqrt_alloc_<W>` is i32 at every width (Rule 15), so accepting leaves
; `ret i64 <i32 handle>` — a BROKEN MODULE the verifier aborts on, NOT a Rule-1
; decline. A crash on well-formed valid input (opt -verify exit 0) violates Rule 1.
;
; The data-mux merge is UNTAINTED (all-ConstantInt incomings). dugh (Phase 4×6)
; retired the `proveSwitchDataMux` G6 merge-out gate and instead RE-SEEDS a second
; propagation from the emitted `%out` (`repropagateControlMerges`); the now-tainted
; `ret` declines via the precise `kMsgNonI32Return`. The return check keys on the
; FUNCTION return type (i64), not the RAUW'd RV type (i32), so it catches the
; post-emit mismatch and `exit(1)`s before the verifier. i64-MEASURE data-muxes stay
; accepted (the sink re-types); the non-i32 raw quantum return is the (A1) limit that
; STAYS declined (feature jx32). NEVER lowered.
;
; bd p3kd.21 / bd jx32 (2026-10-14) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. The function has no in-module use (an export,
; `declineQuantumReturnCalls`' Escaped contract; `main` is NOT under it, bd r2j3.35:
; spec_reject_gate_sub_main_return.ll) and returns an
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
; CHECK-LABEL: define i64 @example(i32 %u0)
; CHECK: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[OUT:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 5)
; CHECK-NEXT: [[C0:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i64_controlled(i32 [[C0]], i32 [[OUT]], i64 15)
; CHECK-NEXT: [[C1:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_xorc_i64_controlled(i32 [[C1]], i32 [[OUT]], i64 17)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C0]], i32 [[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 [[C0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C1]], i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C1]])
; CHECK-NEXT: [[W:%[0-9a-z_.]+]] = zext i32 [[OUT]] to i64
; CHECK-NEXT: ret i64 [[W]]
declare i32 @cq_theta_si32(i32, double)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  br label %merge
c1:
  br label %merge
merge:
  %y = phi i64 [ 10, %c0 ], [ 20, %c1 ], [ 5, %entry ]   ; UNTAINTED all-const i64 data-mux
  ret i64 %y                                             ; non-i32 ret of the RAUW'd i32 handle
}
