; lowering_inplace_qq_decline_reader_unknown.ll — DECLINE, HAND-WRITTEN (bd r2j3.33 /
; dm7f.51 step 1, R11 round 2c finding F2; reviewer probe review_s1R2c/h2.ll).
;
; Pins the postcondition's FAIL-CLOSED branch (`kMsgInPlaceQQReaderUnknown`): a
; FORWARD `cqrt_qram_store_i32(%arr, %t, %v)` after the pre-tagged in-place
; `cqrt_xor_i32(%a, %t)` reads the relabelled `%t` as its index. A QRAM store is
; neither a forward producer minting a fresh rail, a sink, nor a gate with a known
; write set in `classifyLaterUse`, so the postcondition cannot place it and fails
; loudly rather than skip it. (Its own `_unc`s follow; the first unclassifiable
; reader fires.)
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

define i32 @stale_store() {
entry:
  %t = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 0, double 6.000000e-01)
  %arr = call i32 @cqrt_qram_alloc_i32(i32 4)
  call void @cqrt_qram_store_i32(i32 %arr, i32 %t, i32 %v)
  call void @cqrt_xor_i32(i32 %a, i32 %t), !cq.inplace.qq !0
  call void @cqrt_qram_store_i32(i32 %arr, i32 %t, i32 %v)
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %t, i32 %v)
  call void @cqrt_qram_store_i32_unc(i32 %arr, i32 %t, i32 %v)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

!0 = !{}
