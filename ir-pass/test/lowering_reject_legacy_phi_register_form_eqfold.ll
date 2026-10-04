; lowering_reject_legacy_phi_register_form_eqfold.ll — DECLINE, and the pin for
; the Rule-13 round-1 CONFIRMED finding F-L6-1 (bd test_C_libtooling-3qlq Inc 1
; part A, lens L6): a Rule-1 "no third path" violation — a construct the pass
; NEITHER lowered NOR declined, at `opt` exit 0.
;
; This module is `clang -O1` output verbatim for the FLAGSHIP CUSTOMER compiled
; against a STALE (pre-3qlq) header:
;
;     int slice(int u) {
;         int q = u; cq_theta(&q, 0.5);
;         if (q == 5) { q = cq_phi(q, 3.141592653589793); }   /* the Grover oracle */
;         return cq_measure(q);
;     }
;
; NOTE `%5 = tail call i32 @cq_phi_si32(i32 noundef 5, ...)`. `clang -O1`
; CONST-FOLDS arg 0 to the literal `i32 5` on the `q == 5` edge (the drbq Inc-4
; F2 fold class), so the operand is CLASSICAL — which is exactly why the
; disposition its sibling `lowering_reject_legacy_phi_register_form.ll` pinned
; could not apply: `declineTaintEscapes` fires only on a TAINTED operand.
;
; WHAT HAPPENED AT THE INCREMENT'S HEAD. `ArmClassify::isPhiCall` still
; recognised the call by the `cq_phi_` PREFIX and CLAIMED it as an arm gate;
; `emitInPlaceRotationRegion` hoisted it and recorded `taint.ControlledRotations`;
; and the `PhiCalls` loop in `RotationLowering` that used to lower it had been
; DELETED (correctly — `taint.PhiCalls` is permanently empty), so nothing
; consumed the claimed gate. The emitted module was:
;
;     %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
;     %2     = tail call i32 @cq_phi_si32(i32 %h, double PI)     <-- UNLOWERED
;              call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
;              call void @cqrt_free(i32 %h_cmp)
;
; — `opt` exit 0, verify-clean, STRICT `free_pairing_check.py` `2 verified, 0
; violation(s)`, the flag minted and stripped and freed, and THE PHASE GATE
; DROPPED — the emitted circuit is the IDENTITY on `q`, which is PRD §1's own
; defect class reached through a different door. The only thing that noticed was
; `ld` (`Undefined symbols: "_cq_phi_si32"`), and it is one linkable body away
; from being silent.
;
; THE FIX is a reserved-name decline on ANY USE of the retired family, in
; `resolveSources` — plus, as a backstop, `declineSurvivingIntrinsicCalls` at the
; END of both pipeline entry points, which turns the pass's documented
; postcondition ("all `cq_*` intrinsics gone") from a comment into a checked
; property. The narrowing to `!use_empty` (rather than the declaration alone, as
; the other 33 reserved names use) is deliberate and argued at the clause.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)
; CHECK-NOT: cqrt_rz

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #1
  %3 = icmp eq i32 %2, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @cq_phi_si32(i32 noundef 5, double noundef 0x400921FB54442D18) #1
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #1
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_phi_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
