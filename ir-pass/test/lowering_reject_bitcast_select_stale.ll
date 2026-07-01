; lowering_reject_bitcast_select_stale.ll — bd iw81.1 DECLINE (Rule-13 BLOCKER #2,
; the tainted-SELECT value-operand shape). A tainted-condition `select` takes the
; folded bitcast RESULT `%b` as a data operand, while a sibling `cq_theta` re-rotates
; that wire in place. SelectClassify's coherent-use / stale gates are BESPOKE walks
; that do NOT share the stale-record wire walker — so a late fold that left `%b`
; standing would hide the re-rotation from them and the 4.4 controlled-XOR copy would
; capture a STALE (post-Ry) basis (a verify-clean silent miscompile). The EARLY fold
; replaces `%b` with `%q` before SelectClassify runs, reducing this to the DIRECT
; `select %c, %q, %p` form the pass already DECLINES — structurally, with no
; per-consumer crossing. Pins that a folded bitcast cannot launder a stale wire past
; the select classifier.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b   = bitcast i32 %q to i32
  %p   = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  ; In-place Ry re-rotates %q's wire, reached only through the bitcast result %b.
  %qr  = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %c   = icmp sgt i32 %p, 5
  ; Tainted-condition select whose data operand %b === the re-rotated wire %q.
  %sel = select i1 %c, i32 %b, i32 %p
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy_i32_controlled
