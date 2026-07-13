; control_predmux_leave_inloop.ll — LEAVE→DECLINE (3c6m.14 L6 Inc 1, PRD §7 decline matrix):
; a pure-value nest whose entry sits on a CFG cycle (E2: acyclic only; in-loop control is 3lro, the d8jl guard owns it).
; PredMux must LEAVE this region (accept-only discipline) so it falls
; through to the existing loud decline — pinned char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.0e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %acc = phi i32 [ %q, %entry ], [ %rm, %latch ]
  %c1 = icmp sgt i32 %acc, 5
  br i1 %c1, label %mid, label %latch
mid:
  %v1 = add i32 %acc, 1
  %c2 = icmp slt i32 %acc, 9
  br i1 %c2, label %arm, label %latch
arm:
  %v2 = xor i32 %acc, 3
  br label %latch
latch:
  %rm = phi i32 [ %acc, %loop ], [ %v1, %mid ], [ %v2, %arm ]
  %inext = add i32 %i, 1
  %cl = icmp slt i32 %inext, 3
  br i1 %cl, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
