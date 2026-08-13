; lowering_bitcast_i32_identity.ll — bd iw81.1: a same-width int<->int `bitcast`
; is a fixed reversible ZERO-GATE identity. `foldIdentityBitcasts` folds it away
; EARLY (before any analysis) — RAUW every use to the tainted handle, no template
; and no gate (there is deliberately no `cq_template_bitcast_*` symbol), erase the
; bitcast. The bits are unchanged, so the result denotes the SAME physical wire as
; the operand; the module reduces to `cq_theta;measure(handle)`, which lowers to
; alloc/ry/measure with the identity node already gone.
;
; A same-width int<->int bitcast is something `clang -O1` folds away before the
; pass ever runs, so this feature is exercised via hand-written IR (recognizer /
; Bennett-parity completeness), never through a C e2e slice.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; Zero-gate identity: the bitcast is folded away (no template, no surviving cast).
; CHECK-NOT: bitcast
; CHECK-NOT: cq_template_bitcast
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  ; Same-width int identity bitcast → folded to the operand handle (zero gates).
  %b = bitcast i32 %a to i32
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}
