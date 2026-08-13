; lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll — Phase 7.1 Increment E,
; bd 20xt.1: a SUBTLE-but-SOUND reclassification the Rule-13 review flagged. The
; funnel `fshl(%a, %p, 5)` is written with two DISTINCT SSA operands (%a and %p),
; so at the escape-carve (BEFORE rotation lowering) it looks like the general
; funnel. But %p = cq_phi(%a) is an Rz (a DIAGONAL gate, in place): rotation
; lowering RAUWs %p to %a's OWN handle. So by the time rewriteIntrinsic runs,
; arg0 == arg1 — it reclassifies to the ROTATION form and lowers to
; `cq_template_fshl_i32_hl(handle, 5)`, NOT the general qql producer.
;
; This is CORRECT, not a miscompile: Rz is diagonal, so %a and %p carry the SAME
; basis value x on the shared rail, and fshl(x, x, 5) = rotate-left(x, 5) — exactly
; what the `_hl` rotation form computes. The predicate is taint-invariant by
; design (it runs pre-RAUW at the carve and post-RAUW at the rewrite); this fixture
; pins that the post-RAUW alias is handled by the rotation path, never mislowered.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call void @cqrt_rz_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 3.0
; CHECK:     call i32 @cq_template_fshl_i32_hl(i32 %[[H]], i32 5)
; CHECK-NOT: @llvm.fshl
; CHECK-NOT: cq_template_fshl_i32_qql

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %p = call i32 @cq_phi_si32(i32 %a, double 3.000000e-01)  ; Rz on %a -> RAUW %p to %a's handle
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %p, i32 5)       ; distinct SSA, same rail post-RAUW
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
