; control_predmux_accept_negated_nested_no_orphan_inner.ll — ACCEPT (bd qesi).
; ARM: the same `buildNegation` orphan defect ONE LEVEL DEEPER — a nested
; `a && (b && c)` orphans the INNER `and i1` node as well as the compare leaves.
; The leaf-only fixture cannot witness this: it has no inner node to lose.
;
; *** IN THIS MODULE, `cq_template_and_i1` IN THE OUTPUT IS THE ORPHAN FINGERPRINT,
; AND THAT IS WHY THIS FIXTURE IS CHEAP TO READ. *** The flag mint never builds
; and/or from arithmetic templates — it builds them from `cqrt_toffoli` / `cqrt_cnot`
; over a `cqrt_alloc_i1(false)` rail. So here a `cq_template_and_i1` can only be a
; tree node that fell OUT of the flag tree and got lowered by `lowerOps` as ordinary
; tainted arithmetic. Measured on the positive-polarity twin: ZERO.
;
; *** DO NOT GENERALISE THAT INTO "an `and_i1` gate is always an orphan" — AN EARLIER
; DRAFT OF THIS HEADER DID, AND IT IS FALSE. *** The fingerprint holds only in a
; module with no i1 DATA operations. Counter-example, committed and measured:
; `control_predmux_accept_i1phi_data.ll` emits FOUR LIVE `cq_template_and_i1` (plus an
; `or_i1`), every one consumed — they are the `convertPhis` BoolAlg conversion of an
; i1 DATA phi, feeding `cq_template_zext_i1_to_i32`. Orphan count there: 0. This
; file's own `NOORPHAN-NOT` remains sound because THIS module has no i1 data phi; it
; is the universal that was wrong, and it is exactly what a future agent would grep
; for when diagnosing an unexplained `and_i1`.
;
; PRE-FIX, MEASURED: this module leaks FOUR dead gates, not two —
;     cq_template_icmp_sgt_i32_hl   (original %a)
;     cq_template_icmp_slt_i32_hl   (original %b)
;     cq_template_icmp_ne_i32_hl    (original %c)
;     cq_template_and_i1            (original %in, the INNER node)
; Note the orphan CONE is larger than the count of zero-use gates: an orphaned
; inner node keeps its own children "used", so a use_empty scan reports only the
; cone ROOTS (2 here) and undercounts. Assert on symbol ABSENCE, not on a use count.
;
; POST-FIX the tree is `!a || (!b && !c)` with every predicate inverted at the leaf
; (the no-NOT invariant), so the surviving compares are `sle`/`sge`/`eq` and the
; originals `sgt`/`slt`/`ne` are absent from the module entirely — as is any
; `cq_template_and_i1`, because the new tree's `and`/`or` are flag-mint gates.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=NOORPHAN

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %c = icmp ne i32 %q, 7
  %in = and i1 %b, %c                      ; the INNER node this row exists for
  %sc = and i1 %a, %in
  br i1 %sc, label %merge, label %arm      ; arm = FALSE successor (clang -O1)

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; Claimed, flattened, and every predicate inverted at the leaf:
; CHECK: cq_template_icmp_sle_i32_hl
; CHECK: cq_template_icmp_sge_i32_hl
; CHECK: cq_template_icmp_eq_i32_hl
; CHECK: cqrt_copy_i32_controlled

; No orphan leaf, and — the row's own subject — no orphan INNER node:
; NOORPHAN-NOT: cq_template_icmp_sgt
; NOORPHAN-NOT: cq_template_icmp_slt
; NOORPHAN-NOT: cq_template_icmp_ne
; NOORPHAN-NOT: cq_template_and_i1
