; lowering_ctlz_idiom_reject_i128.ll — DECLINE (bd ww4c Inc 1, the Z9 probe). The
; accepted shape at i128.
;
; Z9 admits integer widths in the SHIPPED ctlz set {i8, i16, i32, i64}
; (tools/intrinsic_table.yaml:136) and nothing else. The closed form's `mod N` is
; `and (N-1)` only for N a power of two — which i128 is — so this is not a
; mathematical fence but an ABI one: there is no cq_template_ctlz_i128 to call,
; and Rule 15 forbids minting one here (edit the YAML and regenerate, with its
; own drift check and its own review). `nm -g build/runtime/libcq_templates.a`
; confirms ctlz stops at i64 while and/shl/sub run to i128 — so a fence keyed on
; the arithmetic alone would over-accept into a link failure at best.
;
; i80, i1, non-power-of-two `_BitInt` widths, vectors and non-integers decline on
; the same clause.
;
; Note how the seed is reached: i128 is DEFERRED as a theta/measure suffix
; (WidthDispatch.cpp:36-38 — the C ABI shreds `__int128` into {i64,i64}), so a
; tainted i128 exists only as an INTERMEDIATE. The seed is therefore an i64 theta
; widened by `sext`, which is exactly how a real i128 recurrence would arise, and
; the counter is narrowed back by `trunc` at the sink. Getting this wrong is how
; the first draft of this fixture silently proved nothing: with `cq_theta_si128`
; the module carried NO taint at all, the pass returned it byte-identical, and
; the "decline" was a passthrough wearing a decline's clothes.
;
; WHAT MAKES THIS FIXTURE PROVE ANYTHING is its width-only minimal pair,
; @widened_seed in lowering_ctlz_idiom_i64.ll: the same structure and the same
; sext/trunc seed route at i64, which ACCEPTS. Without it this file would only
; show "something declined" — the recognizer never speaks, so a Z9 miss and a Z8
; miss and a typo in the seed all look identical from outside. With it, Z9 is
; isolated as the clause that fires.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @reject_i128(i64 %u) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %w = sext i64 %q to i128
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i128 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i128 [ %w, %entry ], [ %sh, %loop ]
  %dec = add nsw i128 %ix, -1
  %sh = shl nuw i128 %x, 1
  %pos = icmp sgt i128 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %narrow = trunc i128 %dec to i64
  %m = call i64 @cq_measure_sll(i64 %narrow)
  ret i64 %m
}
