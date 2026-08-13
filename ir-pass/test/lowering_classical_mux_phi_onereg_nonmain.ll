; lowering_classical_mux_phi_onereg_nonmain.ll — ACCEPT: the one-register
; merge phi in a NON-main function (test_C_libtooling-5j5, the FreePoint
; regression pin).
;
; History: pre-wi5 this shape was FreePoint-LOUD in non-main functions — the
; live merge phi was an unrecognized user of the handle, so the Phase-5 net
; rejected what `main` (Escaped-by-residency) silently accepted. The wi5
; guard made it decline loudly EVERYWHERE; the 5j5 lift now accepts it
; everywhere: the RAUW removes the phi BEFORE rotation lowering, so FreePoint
; never sees an unrecognized user — the handle's post-lowering users are
; exactly {ry, conditional rz, measure}, and `computeFreePoint` classifies it
; Measured (the measurement owns the register: no adjoint, no free, pinned
; ACCEPT domain).
;
; Same lift predicate + Rule-13 clearance as lowering_classical_mux_phi_onereg.ll
; (see that fixture); this one pins that acceptance is NOT main-residency-
; dependent.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:      call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:      arm:
; CHECK-NEXT:   call void @cqrt_rz_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32
; Measured handle — the measurement owns the register; no free, no adjoint:
; CHECK-NOT:  cqrt_free

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %q2 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
