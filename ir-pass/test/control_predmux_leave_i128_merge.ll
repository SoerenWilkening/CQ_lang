; control_predmux_leave_i128_merge.ll — LEAVE→DECLINE (3c6m.14 L6 Inc 1, PRD §7 decline matrix):
; an i128 merge phi (E7: mux type gates mirror the copy families' envelopes).
; PredMux must LEAVE this region (accept-only discipline) so it falls
; through to the existing loud decline — pinned char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i64 @cq_theta_sl(i64, double)
declare i64 @cq_measure_sl(i64)
define i64 @example(i64 %u0) {
entry:
  %q = call i64 @cq_theta_sl(i64 %u0, double 5.0e-01)
  %qw = sext i64 %q to i128
  %c1 = icmp sgt i128 %qw, 5
  br i1 %c1, label %mid, label %merge
mid:
  %v1 = add i128 %qw, 1
  %c2 = icmp slt i128 %qw, 9
  br i1 %c2, label %arm, label %merge
arm:
  %v2 = xor i128 %qw, 3
  br label %merge
merge:
  %rm = phi i128 [ %qw, %entry ], [ %v1, %mid ], [ %v2, %arm ]
  %rt = trunc i128 %rm to i64
  %m = call i64 @cq_measure_sl(i64 %rt)
  ret i64 %m
}
; CHECK: error{{.*}}value-arm swap-route under quantum control
