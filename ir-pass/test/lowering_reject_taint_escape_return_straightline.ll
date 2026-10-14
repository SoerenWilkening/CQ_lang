; lowering_reject_taint_escape_return_straightline.ll — DECLINE: a tainted value
; of NON-i32 width returned straight-line (test_C_libtooling-udw, member 1/3).
;
; Every lowering path RAUWs an iN-typed tainted SSA value to an ALWAYS-i32 runtime
; handle (`cqrt_alloc_*` returns i32; RotationLowering.cpp §1) and relies on
; LAUNDERING-BY-ERASURE: the type mismatch is transient because every tainted user
; is itself lowered and erased. A `ret` user is NEVER erased. So `ret i64 %q`
; leaves `ret i64 <i32 handle>` in the final IR and the verifier aborts with
; report_fatal_error("Broken module found") + bug-report banner — loud and
; unconsumable, but NOT the Rule-1 source-located DiagnosticInfoUnsupported decline.
;
; The fix declines this escape pre-RAUW (declineTaintEscapes): a `ret` of a tainted
; value at a width other than i32 cannot be laundered — the same move as
; ArmClassify::taintedAngleGate ("declining here turns the later broken-module abort
; into a clean, source-located decline"). i32-width tainted rets stay accepted
; (FreePoint Escaped; pinned lowering_uncompute_escape_return.ll).
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
; CHECK-LABEL: define i64 @slice(i64 %x)
; CHECK: [[H:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 %x)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 [[H]], double 2.500000e-01)
; CHECK-NEXT: [[W:%[0-9a-z_.]+]] = zext i32 [[H]] to i64
; CHECK-NEXT: ret i64 [[W]]
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define i64 @slice(i64 %x) {
entry:
  %q = call i64 @cq_theta_sll(i64 %x, double 2.500000e-01)
  ret i64 %q                                       ; non-i32 escape — cannot launder
}

