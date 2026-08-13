; lowering_intrinsic_ctpop_sources_live.ll — Phase 7.1 Increment E, the DEEPEST
; R-E fence: Class-2 SOURCE-LIVENESS. ctpop is non-injective — it is reversible
; ONLY because its `_unc` recomputes ctpop(source) from the still-LIVE source and
; XORs the out rail to |0>, NEVER recovering the input. The load-bearing
; correctness is that the source is kept LIVE THROUGH its own `_unc`: a source
; freed/uncomputed BEFORE the `_unc` would make the recompute read a collapsed
; rail (the silent-collapse class, Rule 8). This pins the order: the ctpop `_unc`
; reads the live source %[[H]], the out rail is freed, and ONLY THEN is the
; source uncomputed (cqrt_ry -theta) and freed — never the reverse.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctpop_i32(i32 %[[H]])
; The `_unc` reads the LIVE source %[[H]] (recompute-from-live-source):
; CHECK:     call void @cq_template_ctpop_i32_unc(i32 %[[INTR]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[INTR]])
; The source is uncomputed + freed ONLY AFTER its own `_unc` (ordered match):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.0
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: @llvm.ctpop
; Class-2 has no inverse — never an `_inv` twin.
; CHECK-NOT: cq_template_ctpop_i32_inv

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @llvm.ctpop.i32(i32)

define void @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.ctpop.i32(i32 %q)
  %k = call i32 @cq_phi_si32(i32 %r, double 3.000000e-01)  ; Rz keep-alive (dead)
  ret void
}
