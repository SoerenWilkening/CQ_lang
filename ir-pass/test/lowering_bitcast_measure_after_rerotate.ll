; lowering_bitcast_measure_after_rerotate.ll — bd iw81.1 ACCEPT boundary + Rule-13
; OVER-DECLINE regression pin. A same-width int bitcast `%b` is named, then a chained
; `cq_theta` re-rotates the operand `%h`'s wire IN PLACE, and finally `%b` is
; MEASURED. `foldIdentityBitcasts` replaces `%b` with `%h` EARLY, so this reduces to
; the direct `cq_theta;cq_theta;measure(%h)` shape the base pass accepts: a measure
; reads the wire in place (captures nothing onto a fresh rail, so there is no stale-
; record hazard). It lowers to `ry(0.5); ry(0.3); measure(h)` — the same stream as
; the direct form.
;
; This pins that a re-rotation on the folded wire does NOT spuriously decline a
; MEASURE (over-decline, Rule 17). Only a downstream DATA op / select / tape reading
; a re-rotated wire declines (lowering_reject_bitcast_downstream_stale.ll,
; lowering_reject_bitcast_select_stale.ll, lowering_reject_bitcast_tape_stale.ll),
; never a measure. (An earlier attempt that declined the bitcast itself over-declined
; this accepted shape — the correction is early folding + no bitcast-specific guard.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
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
  %h  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b  = bitcast i32 %h to i32
  ; Chained in-place Ry re-rotates the wire AFTER the bitcast...
  %h2 = call i32 @cq_theta_si32(i32 %h, double 3.000000e-01)
  ; ...and %b (=== the wire) is MEASURED — reads the wire in place (no capture).
  %m  = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}
