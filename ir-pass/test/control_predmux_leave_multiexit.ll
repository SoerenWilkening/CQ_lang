; control_predmux_leave_multiexit.ll — LEAVE→DECLINE (3c6m.14 L6 Inc 1, PRD §7 decline matrix):
; an arm that RETURNS instead of reconverging (E3: single-exit; multi-exit stays with 7.2/offPattern owners).
; PredMux must LEAVE this region (accept-only discipline) so it falls
; through to the existing loud decline — pinned char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.0e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %v1 = add i32 %q, 1
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %armret, label %merge
armret:
  ret i32 7
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %mid ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
