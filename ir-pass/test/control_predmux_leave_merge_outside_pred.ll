; control_predmux_leave_merge_outside_pred.ll — LEAVE→DECLINE (3c6m.14 L6,
; PRD §7 row "M has a predecessor outside R"; the Rule-13 clearance fixture
; gap): the nested tainted region's merge block is ALSO reachable from a
; block OUTSIDE the region — a CLASSICAL-condition bypass edge (classical so
; no enclosing tainted region can subsume the shape). E3's preds(Merge) ⊆
; Region gate LEAVES both the inner claim (bypass ∉ R) and the mid-rooted
; claim (inner ∉ R); the surviving tainted control then declines loudly via
; the existing paths.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %cc, label %bypass, label %inner
bypass:
  %b1 = add i32 %q, 9
  br label %merge
inner:
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %v1 = add i32 %q, 1
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  %v2 = xor i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %b1, %bypass ], [ %q, %inner ], [ %v1, %mid ], [ %v2, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK: error{{.*}}under quantum control
