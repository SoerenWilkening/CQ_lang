; lowering_reject_stale_record_intrinsic_smin.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; The curated binary intrinsic is a pure producer, placed like an `add`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: %[[D:[a-z_0-9]+]] = call i32 @cq_template_smin_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_reject_stale_record_intrinsic_smin.ll — Phase 7.1 Increment E, the
; STALE-RECORD fence (Rule-13 blocker fix). A curated intrinsic is a tainted pure
; producer subject to the SAME stale-record precondition as add/mul/cast: its
; handle operand must not predate a non-diagonal wire gate. Here a chained
; `cq_theta(%q, %t2)` applies a SECOND Ry to %q's wire, then `@llvm.smin.i32`
; reads the PRE-Ry %q but is SCHEDULED AFTER that Ry — so the template would read
; the post-Ry basis while %q denotes the pre-Ry record (the verify-clean
; stale-record miscompile). Increment E added curated intrinsics to lowerOps, so
; inLowerOpsScope MUST include them or declineStaleRecordOps would skip them
; (it adjudicates add identically — see lowering_reject_stale_record_add.ll).
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.smin.i32(i32, i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry re-rotates %q's wire
  %d  = call i32 @llvm.smin.i32(i32 %q, i32 7)        ; reads PRE-Ry %q, scheduled AFTER
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
