; lowering_intrinsic_funnel_fshl_qq_uncompute.ll — Phase 7.1 Increment E,
; bd 20xt.1: the GENERAL funnel shift as a Class-2 additive producer whose result
; is DEAD (kept alive only by a phase-arm `cq_phi`/Rz, then reversed). Confirms
; the whole-DAG LIFO uncompute emits the void `_unc` twin — recompute-and-XOR
; from the still-LIVE sources (a, b, amount) — and frees the now-|0> rail, with
; NO `_inv` (Class-2). The `_unc` is minted by the GENERIC EmitInverse
; data-template path (`cq_template_…_unc(out, srcs…)`), the SAME machinery the
; fma qql uses — a distinct STEM needs zero uncompute-spine code (Rule 14).
; Sources are kept live through the forward pass and uncomputed in strict reverse
; program order; every rail is freed only after being returned to |0> (Rule 6/8).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Forward: alloc both, forward funnel producer, phase-arm Rz.
; CHECK:     %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[HB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fshl_i32_qql(i32 %[[HA]], i32 %[[HB]], i32 16)
; Reverse-play (LIFO): undo Rz, void `_unc` (out-first), free funnel rail, then
; undo+free each source theta.
; CHECK:     call void @cq_template_fshl_i32_qql_unc(i32 %[[R]], i32 %[[HA]], i32 %[[HB]], i32 16)
; CHECK:     call void @cqrt_free(i32 %[[R]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[HB]], double -2.5
; CHECK:     call void @cqrt_free(i32 %[[HB]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[HA]], double -5.0
; CHECK:     call void @cqrt_free(i32 %[[HA]])
;
; CHECK-NOT: @llvm.fshl
; CHECK-NOT: cq_template_fshl_i32_qql_inv
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define void @example(i32 %u, i32 %v) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 16)
  ret void
}
