; c2 — bd hrts / l3i1's ACYCLIC half MEETING bd wx8g's in-loop capability: a
; classical branch INSIDE the loop body bypasses the state-prep region and
; re-joins at %j, where %p is a phi taking the M-descendant %carry on the region
; edge and 7 on the bypass.  %p's block is NOT dominated by MergeBB, so the
; dominance skip drops %p from the exclusion set — but %p is defined AFTER the
; region and is available at NEITHER slot, so dropping it is a pure over-decline.
define i32 @example(i32 %arg) {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %j ]
  %t = phi i32 [ 0, %entry ], [ %tn, %j ]
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %bypass, label %pred
pred:
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %pred ]
  %bz = zext i1 %b to i32
  %mask2 = and i32 %bz, 0
  %mask = and i32 %rm, %mask2
  %carry = or i32 %mask, 7
  %mm = call i32 @cq_measure_si32(i32 %rm)
  br label %j
bypass:
  br label %j
j:
  %p = phi i32 [ %carry, %merge ], [ 7, %bypass ]
  %mmp = phi i32 [ %mm, %merge ], [ 0, %bypass ]
  %mp = call i32 @cq_measure_si32(i32 %p)
  %tn0 = add i32 %t, %mmp
  %tn = add i32 %tn0, %mp
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %r = add i32 %tn, %zb
  ret i32 %r
}
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
