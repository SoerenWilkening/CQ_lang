; lowering_reject_taint_escape_return_phase_diamond.ll — DECLINE: a phase-arm
; diamond whose merge result is RETURNED at NON-i32 width
; (test_C_libtooling-udw, member 2/3).
;
; `if (q > 5) { rz(q,a); rz(q,b); } return q;` — the i32-width twin of this shape
; is the ACCEPT fixture control_swap_ifelse_escape.ll (the merge phi RAUWs to the
; escaping handle q and the boolean is stripped). At i64 width the answer rail q is
; an i32 runtime handle but the function returns i64, so the merge ret leaves
; `ret i64 <i32 handle>` and the verifier aborts ("Broken module found") instead of
; declining. declineTaintEscapes catches the tainted non-i32 ret BEFORE control
; detection runs, so the diamond is never emitted — a clean, source-located decline.
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
; CHECK-LABEL: define i64 @example(i64 %u0, double %a, double %b)
; CHECK: [[H:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 [[H]], double 5.000000e-01)
; CHECK-NEXT: [[C:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 [[H]], i64 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[C]], double %a), !cq.branchphase
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[C]], double %b), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i64_hl_unc(i32 [[C]], i32 [[H]], i64 5)
; CHECK-NEXT: call void @cqrt_free(i32 [[C]])
; CHECK-NEXT: [[W:%[0-9a-z_.]+]] = zext i32 [[H]] to i64
; CHECK-NEXT: ret i64 [[W]]
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @cq_phi(double)
declare i64 @cq_theta_sll(i64, double)

define i64 @example(i64 %u0, double %a, double %b) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c = icmp sgt i64 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)
  br label %merge
merge:
  ret i64 %q                                      ; non-i32 escape — cannot launder
}

