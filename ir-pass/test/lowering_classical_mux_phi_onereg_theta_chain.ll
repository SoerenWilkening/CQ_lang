; lowering_classical_mux_phi_onereg_theta_chain.ll — ACCEPT: one-register
; merge phi whose arm chain is TWO in-place gates including a chained
; cq_theta (test_C_libtooling-5j5, the theta-gate + multi-gate-chain variant):
;     if (classical_c) { q = cq_theta(q, t2); q = cq_phi(q, t3); }  measure(q);
;
; A tainted-operand cq_theta is IN PLACE exactly like cq_phi: RotationLowering
; emits ry-only on the EXISTING handle (no second allocation — "chained theta")
; and RAUWs the result to its operand. So the wire resolution walks
; %q3 -> %q2 -> %q through two collected gate call sites to the one base, and
; the whole chain sits in the arm block: entering via the arm edge implies
; both gates ran, this traversal, in block order; entering via the straight
; edge implies neither did. The phi is a pure renaming either way.
;
; Note the Ry is NON-diagonal and that is still fine HERE: the only
; downstream consumer is the measure of the merged value itself, whose
; per-path record matches the wire per path. A tainted PURE op reading the
; pre-gate base past the arm is a different shape and is already owned by
; `declineStaleRecordOps` (runs BEFORE this guard; WireWalk finds the arm
; theta forward of the base).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; One allocation only (the chained theta must NOT mint a second register):
; CHECK:      call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NOT:  call i32 @cqrt_alloc_i32
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; Both arm gates stay inside the arm, in source order, on the SAME handle:
; CHECK:      arm:
; CHECK-NEXT:   call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT:   call void @cqrt_rz_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      merge:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  phi i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 1.250000e-01)   ; chained Ry, in place
  %q3 = call i32 @cq_phi_si32(i32 %q2, double 2.500000e-01)    ; Rz, in place
  br label %merge
merge:
  %p = phi i32 [ %q3, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
