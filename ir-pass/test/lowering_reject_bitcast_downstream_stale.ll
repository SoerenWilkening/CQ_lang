; lowering_reject_bitcast_downstream_stale.ll — bd iw81.1 DECLINE (the Rule-13
; BLOCKER a naive late fold shipped). A same-width int bitcast is folded EARLY
; (foldIdentityBitcasts, before any analysis): `%b` is replaced by `%q`, reducing
; this to the DIRECT program `cq_theta;cq_theta(%q);add %q;measure` — which the
; base pass already DECLINES because the `add`'s template captures the POST-Ry(0.3)
; basis onto a fresh rail while its SSA operand denotes the PRE-Ry(0.3) record (the
; canonical stale-record miscompile). Early folding is what makes the bitcast form
; behave IDENTICALLY to the direct form: with the identity node gone before the
; stale-record guard runs, there is no opaque bitcast to hide the in-place
; re-rotation (which reaches the wire through the bitcast RESULT `%b`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b  = bitcast i32 %q to i32
  ; Chained in-place Ry re-rotates the wire, taken through the bitcast RESULT %b.
  %h2 = call i32 @cq_theta_si32(i32 %b, double 3.000000e-01)
  ; Downstream DATA op reads the ORIGINAL %q — now stale (wire re-rotated above).
  %d  = add i32 %q, 5
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cq_template_bitcast
