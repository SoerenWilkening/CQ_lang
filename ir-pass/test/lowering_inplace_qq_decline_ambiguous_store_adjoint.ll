; lowering_inplace_qq_decline_ambiguous_store_adjoint.ll — DECLINE, HAND-WRITTEN
; (bd r2j3.33 / dm7f.51 step 1, R11 round 2c finding F1; reviewer probe
; review_s1R2c/h2b.ll).
;
; Store S1 (entry, BEFORE the in-place gate) and an identical store S2 (arm B) both
; match the arm-A `cqrt_qram_store_i32_unc(%arr, %t, %v)` that runs AFTER the gate.
; The QRAM store's `_unc` names no forward (same args, not out-first), so
; `forwardOfAdjoint` must find a UNIQUE match; 823cfefc took the first (S2, not
; before the gate) and accepted the stale `_unc` with rc 0 (d5c26b12 was loud).
; Now two matches return null, the postcondition cannot place the adjoint, and the
; READER-UNKNOWN message fires (`kMsgInPlaceQQReaderUnknown` — not the stale-
; adjoint one, because the forward is not located at all).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: a reader of an in-place reassigned register cannot be classified

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_xor_i32(i32, i32)

define i32 @stale_store_arm(i1 %c) {
entry:
  %t = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 0, double 6.000000e-01)
  %arr = call i32 @cqrt_qram_alloc_i32(i32 4)
  call void @cqrt_qram_store_i32(i32 %arr, i32 %t, i32 %v)
  br i1 %c, label %A, label %B
A:
  call void @cqrt_xor_i32(i32 %a, i32 %t), !cq.inplace.qq !0
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %t, i32 %v)
  br label %J
B:
  call void @cqrt_qram_store_i32(i32 %arr, i32 %t, i32 %v)
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %t, i32 %v)
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %t, i32 %v)
  br label %J
J:
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

!0 = !{}
