; w1 — IN-LOOP controlled STATE PREP (the class bd wx8g admits), carrying the
; CYCLIC hole: %v is a loop-header phi taking the M-descendant %carry on its
; BACK EDGE, so %v DOMINATES both of F2's slots (the arm theta's arg-0 and the
; merge phi's pred-edge incoming) and is a genuine collider pinned to the seed 7.
; The dominance skip in collectStatePrepPhiDescendants keeps %v OUT of the
; exclusion set, so F2 must still find it.  EXPECT: DECLINE at F2.
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %zero = and i32 %q, 0
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %t = phi i32 [ 0, %entry ], [ %tn, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %loop ]
  %mask = and i32 %q, %zero
  %carry = or i32 %mask, 7
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %tn = add i32 %t, %mm
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %tn
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
