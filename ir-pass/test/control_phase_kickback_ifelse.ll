; control_phase_kickback_ifelse.ll — ACCEPT. The GENUINE IF/ELSE arm
; (`emitArm(R.ShadowFalse, /*Neg=*/true)`), which shipped with ZERO fixture
; coverage — Rule-13 round-1 finding F-L1-2 (bd test_C_libtooling-3qlq Inc 1
; part A, lens L1).
;
;     if (q == 5) cq_phi(0.9); else cq_phi(0.3);
;
; ⚠ HAND-WRITTEN IR, AND THAT IS THE FINDING, NOT A SHORTCUT. `clang -O1` NEVER
; hands this shape to the pass as an if/else diamond: L1 measured that every C
; spelling collapses to something else — one gate per arm folds to an ANGLE
; SELECT (`control_angle_select_phase_constants.ll`), two-and-one folds to a
; DIAMOND plus a merge-tail `phi double`
; (`control_phase_kickback_ifelse_tail_phi.ll`), and two-and-two folds to TWO
; selects (which decline, F-L1-4). So `emitArm(R.ShadowFalse, true)` is
; hand-IR-only LIVE CODE in the Rule-13 core, and either it is pinned by hand IR
; or it is unpinned; this file is the first choice.
;
; THE POLARITY CONVENTION IT PINS: `Shadow` is `Arm`'s and `ShadowFalse` is
; `ArmFalse`'s BY FIELD IDENTITY, never by edge truth. `ArmNegated` is the
; DIAMOND's polarity and is false for an if/else, so the false arm's bracket is
; UNCONDITIONAL — 0.9 fires on f == 1 with no bracket, 0.3 fires on f == 0 inside
; one `cqrt_x` pair.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; ONE bracket PAIR — the false arm's, not one per gate.
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT: call void @cqrt_x(

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: fneg

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare void @cq_phi(double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @slice() local_unnamed_addr {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %at, label %af
at:
  tail call void @cq_phi(double noundef 9.000000e-01)
  br label %mrg
af:
  tail call void @cq_phi(double noundef 3.000000e-01)
  br label %mrg
mrg:
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %m
}
define i32 @main() local_unnamed_addr { %r = call i32 @slice() ret i32 0 }
