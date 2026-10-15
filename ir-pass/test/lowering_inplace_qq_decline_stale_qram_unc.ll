; lowering_inplace_qq_decline_stale_qram_unc.ll — DECLINE, HAND-WRITTEN (bd r2j3.33 /
; dm7f.51 step 1, R11 round 2 finding F3).
;
; A QRAM load reads the target `t` as its INDEX before a pre-tagged in-place
; `cqrt_xor_i32(%a, %t)`; the load's `cqrt_qram_load_i32_unc(%r, %arr, %t)` runs
; AFTER it, so it un-reads the wrong cell. 634f64b4's gate-set postcondition only
; knew `streamGateWrites` slots and missed this `_unc` (rc 0) — NARROWER than the
; b12d4452 `_unc` scan it replaced (L2). Now every `_unc`/`_inv` after the gate is a
; reader of all its other handles, an unclassified reader fails closed, and an
; unenumerable alias set fails closed.
; R11 round 2b (finding N2): this message is the ADJOINT branch's alone (an
; unclassifiable reader and an unenumerable alias set have their own), and the
; adjoint is stale because its forward `cqrt_qram_load_i32` (located by
; EmitInverse's `forwardOfAdjoint`) predates the gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: an adjoint reads a register after its in-place quantum reassignment

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_xor_i32(i32, i32)
declare void @cqrt_free(i32)

define i32 @stale_qram() {
entry:
  %t = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %arr = call i32 @cqrt_qram_alloc_i32(i32 4)
  %r = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %t)
  call void @cqrt_xor_i32(i32 %a, i32 %t), !cq.inplace.qq !0
  call void @cqrt_qram_load_i32_unc(i32 %r, i32 %arr, i32 %t)
  call void @cqrt_free(i32 %r)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

!0 = !{}
