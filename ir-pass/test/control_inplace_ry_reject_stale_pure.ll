; control_inplace_ry_reject_stale_pure.ll — ACCEPT since bd test_C_libtooling-57ch.1 and 57ch.3 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The stale pure op is PLACED before its staling gate (StaleReadPlacement.h): its
; template copies the pre-gate label, the stream the read-first program lowers to
; (twin: lowering_stale_record_add_before_theta.ll, the same CHECK chain).
; Here the staling gate is the ARM's in-place Ry under a TAINTED condition and the
; read is after the merge: the slot is the terminator of the block that dominates
; both (bd 57ch.1), so the template copies `r` before the region and the region
; then lowers as an in-place controlled Ry. R6 never sees a stale read.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK:      call void @cqrt_ry_i32(i32 %[[R:[a-z0-9]+]], double 3.000000e-01)
; CHECK-NEXT: %[[P:[a-z_0-9]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 7)
; CHECK-NEXT: %[[F:[a-z_0-9]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[P]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; control_inplace_ry_reject_stale_pure.ll — DECLINE: a PURE op reads the
; pre-region record of the rotated register after the region (bd
; test_C_libtooling-drbq; the PURE-op corner of R6).
;
;     if (q > 5) cq_theta(&r, .9);
;     p = mark * 7;                     // mark == the pre-Ry `r`
;
; Committed because the coverage is SHARED and the sharing is worth pinning: this
; one declines on the PASS-WIDE `declineStaleRecordOps` (`cq opcode lowering:
; operand predates a non-diagonal gate`), which runs BEFORE control detection and
; already owns tainted pure producers scheduled past a non-diagonal wire gate. R6
; never sees it. So the message here is deliberately the OTHER one, and the
; fixture's job is to record which guard owns which consumer kind — a future
; change that narrows `declineStaleRecordOps` would turn this module into an R6
; case, and this file is where that shows up.
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %p  = mul i32 %r, 7
  %d  = call i32 @cq_measure_si32(i32 %rm)
  %e  = call i32 @cq_measure_si32(i32 %p)
  %s  = add i32 %d, %e
  ret i32 %s
}
