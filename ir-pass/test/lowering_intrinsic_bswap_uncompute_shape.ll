; lowering_intrinsic_bswap_uncompute_shape.ll — Phase 7.1 Increment E, R-E
; adjoint-shape fence (Class-1 involution). A DEAD `@llvm.bswap.i32` (kept alive
; past -O1 DCE by a `cq_phi` Rz whose result is dropped) is reversed by the
; whole-DAG uncompute spine ENTIRELY via the additive-producer mechanism it
; already has — ZERO new uncompute code. Pins the EXACT `_unc` slot order
; (out rail first, then the forward operands) and the free count: the bswap rail
; is freed once, then the theta source is uncomputed and freed once. No dirty
; free, no double free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bswap_i32(i32 %[[H]])
; The `_unc` twin: out rail (the bswap result) is arg 0, the live source follows.
; CHECK:     call void @cq_template_bswap_i32_unc(i32 %[[INTR]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[INTR]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.0
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: @llvm.bswap
; The involution producer reverses via `_unc`, never the `_inv` twin.
; CHECK-NOT: cq_template_bswap_i32_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @llvm.bswap.i32(i32)

define void @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.bswap.i32(i32 %q)
  %k = call i32 @cq_phi_si32(i32 %r, double 3.000000e-01)  ; Rz keep-alive (dead)
  ret void
}
