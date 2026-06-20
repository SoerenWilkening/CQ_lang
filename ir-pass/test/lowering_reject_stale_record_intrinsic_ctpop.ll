; lowering_reject_stale_record_intrinsic_ctpop.ll — Phase 7.1 Increment E: the
; stale-record fence for the UNARY curated mechanism class (companion to the
; binary smin fence). A chained `cq_theta(%q, %t2)` re-rotates %q's wire, then
; `@llvm.ctpop.i32` reads the PRE-Ry %q scheduled AFTER — the template would read
; the post-Ry basis while %q denotes the pre-Ry record. inLowerOpsScope routes
; the unary intrinsic through the same declineStaleRecordOps path as add/cast.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cq_template_ctpop

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
