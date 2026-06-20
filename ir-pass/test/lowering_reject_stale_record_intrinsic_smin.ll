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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cq_template_smin

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
