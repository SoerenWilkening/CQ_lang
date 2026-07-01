; lowering_byref_uncompute_fanout.ll — bd g387 (Rule 13): the two by-ref producers
; fan out from the SAME source; when dead, each must reverse EXACTLY ONCE via its
; `_unc` twin (recomputing from the still-live source), and the SHARED source must
; be reversed EXACTLY ONCE — never double-uncomputed. In a non-`main` helper (Phase
; 5 uncompute is gated off in `main`) the mantissa and exponent chains are kept
; alive by `cq_phi` (Rz reads its operand) but dropped, so the whole DAG is dead.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward: source, then BOTH producers off the same handle.
; CHECK:     call void @cqrt_ry_f64(i32 %[[Q:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     call i32 @cq_template_frexp_f64(i32 %[[Q]])
; CHECK:     call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[Q]])
;
; Reverse (LIFO): each producer reversed once, recomputing from the LIVE source Q;
; then the source itself reversed ONCE (negated angle) and freed.
; CHECK:     call void @cq_template_frexpexp_f64_to_i32_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[Q]])
; CHECK:     call void @cq_template_frexp_f64_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[Q]])
; CHECK:     call void @cqrt_ry_f64(i32 %[[Q]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[Q]])

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_phi_si32(i32, double)
declare double @frexp(double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define void @slice(double %xin) {
entry:
  %e = alloca i32, align 4
  %x = call double @cq_theta_f64(double %xin, double 2.500000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %e)
  %m = call double @frexp(double %x, ptr %e)
  %mi = fptosi double %m to i32
  %k1 = call i32 @cq_phi_si32(i32 %mi, double 5.000000e-01)
  %ev = load i32, ptr %e, align 4
  %k2 = call i32 @cq_phi_si32(i32 %ev, double 6.000000e-01)
  call void @llvm.lifetime.end.p0(i64 4, ptr %e)
  ret void
}
