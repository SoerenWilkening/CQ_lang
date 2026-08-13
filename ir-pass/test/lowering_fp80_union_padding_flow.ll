; lowering_fp80_union_padding_flow.ll — bd 3c6m.51 Inc 3 ACCEPT (fence widening):
; the straddle word flows through an `add` BEFORE the padding-clearing mask. The
; Inc-1 fence (everyUserMasksPadding) required every DIRECT user of the straddle
; load to be a clearing `and` and would have declined this; the widened §4.1
; per-bit padding-taint walk follows the flow — `add` taints upward from the
; lowest diverged bit (carry), the `and 32767` then clears every diverged bit —
; and proves the observable (`cq_measure`) sees ZERO padding-taint. Promote.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @flow() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8       ; straddle: diverged bits [16,64)
  %s = add i64 %hi, 1                    ; carry taints [16,64) — but nothing below
  %r = and i64 %s, 32767                 ; clears every diverged bit
  %m = call i64 @cq_measure_sll(i64 %r)  ; observable sees zero padding-taint
  ret i64 %m
}

; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_add_i64_hl
; CHECK-DAG: call i32 @cq_template_and_i64_hl
; CHECK: call i64 @cqrt_measure_i64
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store
