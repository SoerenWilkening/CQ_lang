; lowering_reject_stale_record_intrinsic_ctpop.ll — ACCEPT since bd test_C_libtooling-57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; The curated unary intrinsic is a pure producer, placed like an `add`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: %[[D:[a-z_0-9]+]] = call i32 @cq_template_ctpop_i32(i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_reject_stale_record_intrinsic_ctpop.ll — Phase 7.1 Increment E: the
; stale-record fence for the UNARY curated mechanism class (companion to the
; binary smin fence). A chained `cq_theta(%q, %t2)` re-rotates %q's wire, then
; `@llvm.ctpop.i32` reads the PRE-Ry %q scheduled AFTER — the template would read
; the post-Ry basis while %q denotes the pre-Ry record. inLowerOpsScope routes
; the unary intrinsic through the same declineStaleRecordOps path as add/cast.
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctpop.i32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry re-rotates %q's wire
  %d  = call i32 @llvm.ctpop.i32(i32 %q)              ; reads PRE-Ry %q, scheduled AFTER
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
