; lowering_reject_stale_record_crossblock.ll — ACCEPT since bd test_C_libtooling-57ch.1 and 57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; Across blocks (bd 57ch.1): the `add`'s block post-dominates the gate's and the
; span (none: `br %cc, %tail, %tail`) is acyclic, so the slot is the gate itself.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: %[[D:[a-z_0-9]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK-NEXT: br i1 %cc
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_reject_stale_record_crossblock.ll — DECLINE: the straight-line
; stale-record shape with the pure producer in a LATER BLOCK than the chained
; theta (test_C_libtooling-uzb adversarial probe).
;
; Same wire as lowering_reject_stale_record_add.ll, but a (classical-
; condition) branch separates the chained Ry from the add, so the order proof
; is cross-block: `DT.dominates(add, theta)` is false (the theta's block
; dominates the add's), hence the add's template is NOT provably emitted
; before the Ry on any trace — it provably is not — and the guard declines.
; Position comparison via `Instruction::comesBefore` alone would be undefined
; across blocks; the dominance formulation handles multi-block layouts and
; conservatively declines anything it cannot prove (Prime Directive).
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, i1 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained, in-place Ry
  br i1 %cc, label %tail, label %tail                 ; classical branch
tail:
  %d = add i32 %q, 1                                  ; SSA denotes the PRE-Ry record
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
