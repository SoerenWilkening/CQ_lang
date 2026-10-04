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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}operand predates a non-diagonal gate
; CHECK-NOT: cqrt_ry_i32_controlled

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
