; w3 — the BARE-`_Bool` RAIL in-loop controlled STATE PREP (bd wx8g's headline
; capability, the RailCond && Region.InLoop carve-out it retired) carrying the
; CYCLIC hole.  The LVI anchor is the condition rail %b itself, reached forward
; through %bz -> %mask2 -> %mask -> %carry, so no EXTRA loop-invariant rail is
; read in the body (that reads as an R7 decline and masks F2 — measured, w2c).
; %v is a loop-header phi taking the M-descendant %carry on its BACK EDGE, so it
; DOMINATES both of F2's slots and is pinned to the seed 7.
; EXPECT: DECLINE at F2 — the dominance skip keeps %v out of the exclusion set.
define i32 @example() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %t = phi i32 [ 0, %entry ], [ %tn, %merge ]
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %loop ]
  %bz = zext i1 %b to i32
  %mask2 = and i32 %bz, 0
  %mask = and i32 %rm, %mask2
  %carry = or i32 %mask, 7
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %tn = add i32 %t, %mm
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
