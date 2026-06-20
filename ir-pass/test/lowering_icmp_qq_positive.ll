; lowering_icmp_qq_positive.ll — Phase 7.1 Increment A primary positive. A
; tainted Q+Q (BOTH-operands-tainted) DATA-position compare (the result routes
; to `cq_measure`, NOT a `br`/`select`/`switch` condition) now LOWERS to the
; bare-QQ flag template `cq_template_icmp_slt_i32(i32 handle, i32 handle)` — the
; already-built `Shape::QQ` branch of `lowerCompareImpl`, fed a width recovered
; from `TaintSet::HandleWidth`.
;
; This is the RED→GREEN conversion of the former `lowering_icmp_qq_negative.ll`
; (which pinned the Phase-3 loud decline). The width is genuinely unrecoverable
; from the two i32-laundered alloc handles at the icmp, so it comes from the
; `HandleWidth` side-table recorded at each `cq_theta` mint (both i32 here →
; AGREEMENT → the bare-QQ symbol at the logical width). The flag handle (i32,
; never i1) flows straight to `cq_measure_i1` → `cqrt_measure_i1`, which
; launders the cross-type i1→i32 RAUW; the second RUN line guards it (risk R2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 9)
; CHECK:     call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `icmp` must be gone (lowered to the QQ template), and the QQ data
; mint must NOT be the HL/LH form (both operands are handles). Guard precisely
; so the `icmp` substring inside `cq_template_icmp_slt_i32` does not trip the
; CHECK-NOT.
; CHECK-NOT: = icmp slt
; CHECK-NOT: _i32_hl(
; CHECK-NOT: _i32_lh(
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  ; Both operands tainted, same recovered width i32 → Q+Q data compare LOWERS.
  ; Result flows to a measure (data position), so it is enqueued, not gated.
  %c = icmp slt i32 %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
