; lowering_reject_bitcast_downstream_stale.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; The early identity-bitcast fold still runs first, so the module is the direct one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-z_0-9]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
; CHECK-NOT:  cq_template_bitcast
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
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
