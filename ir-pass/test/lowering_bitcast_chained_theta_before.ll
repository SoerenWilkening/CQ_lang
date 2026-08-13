; lowering_bitcast_chained_theta_before.ll — bd iw81.1 ACCEPT. A chained `cq_theta`
; (an in-place Ry on the wire) BEFORE the bitcast, whose result `%h2` the bitcast
; then names and MEASURES, folds cleanly: `foldIdentityBitcasts` replaces `%b` with
; `%h2` EARLY, reducing this to the direct `cq_theta;cq_theta;measure(%h2)` shape
; the base pass accepts (a measure reads the wire in place — no fresh-rail capture,
; no staleness). The reject twins (a DOWNSTREAM DATA op / select / tape reading a
; wire re-rotated behind the fold) are lowering_reject_bitcast_downstream_stale.ll,
; lowering_reject_bitcast_select_stale.ll, lowering_reject_bitcast_tape_stale.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Both rotations land in place on the one wire, then the folded bitcast's measure
; reads that handle.
; CHECK:     call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; CHECK-NOT: bitcast
; CHECK-NOT: cq_template_bitcast
; CHECK-NOT: cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %h = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  ; Chained in-place Ry on the SAME wire, BEFORE the bitcast (on-ancestry).
  %h2 = call i32 @cq_theta_si32(i32 %h, double 3.000000e-01)
  ; Snapshot the FINAL wire record — no re-rotation follows, so the fold is sound.
  %b = bitcast i32 %h2 to i32
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}
