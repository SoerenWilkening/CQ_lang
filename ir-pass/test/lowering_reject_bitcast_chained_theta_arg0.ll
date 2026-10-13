; lowering_reject_bitcast_chained_theta_arg0.ll — DECLINE since bd test_C_libtooling-57ch.3 (batch 053;
; the diagnostic changed: the stale read is placed, a different hazard remains).
;
; The stale `add` is now PLACED (57ch.3) between `%q2` and `%q3`; what still
; declines is the fan-out (`%q3` reads `%q` after `%q2` consumed it), a `cq_theta`
; reader no placement can fix: 57ch (B), with the reader fence's own string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate
; CHECK-NOT: cq_template_bitcast
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_reject_bitcast_chained_theta_arg0.ll — bd iw81.1 DECLINE (Rule-13
; BLOCKER #1, the chained-theta-arg-0 shape). A chained `cq_theta` takes the folded
; bitcast RESULT `%b` as its arg-0 handle, and a SIBLING `cq_theta` re-rotates the
; same wire; a downstream `add %q2` then reads `%q2`'s pre-sibling record. The
; early fold replaces `%b` with `%q`, so `%q2 = cq_theta(%q, t2)` becomes a plain
; chained rotation and the whole program reduces to the DIRECT form the base pass
; DECLINES ("operand predates a non-diagonal gate"). This pins the shape that a
; per-consumer wire-walk crossing MISSED (the chained-theta backward hop) — early
; folding closes it structurally, because no bitcast survives for any walk to be
; blind to.
;

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, double %t3) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double %g)
  %b  = bitcast i32 %q to i32
  ; Chained Ry whose arg-0 handle IS the folded bitcast result.
  %q2 = call i32 @cq_theta_si32(i32 %b, double %t2)
  ; Sibling Ry on the SAME wire, before the downstream data op.
  %q3 = call i32 @cq_theta_si32(i32 %q, double %t3)
  ; Downstream DATA op reads %q2's pre-Ry(t3) record — stale.
  %d  = add i32 %q2, 1
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
