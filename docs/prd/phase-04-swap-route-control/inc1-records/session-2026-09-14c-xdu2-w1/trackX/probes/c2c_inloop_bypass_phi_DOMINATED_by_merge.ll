; c2c — the ISOLATING TWIN of c2.  The SAME collider value %p, the same program
; meaning, the same loop; the ONLY difference is that the classical bypass is
; nested INSIDE the region's merge-dominated region, so %p's block IS dominated
; by MergeBB and %p therefore STAYS in the exclusion set.
; Together with c2 this measures bd hrts / l3i1's capability cost on ONE binary:
; F2 fires or does not fire purely on where the bypass sits.
define i32 @example(i32 %arg) {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %j ]
  %t = phi i32 [ 0, %entry ], [ %tn, %j ]
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
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %bypass, label %thru
thru:
  br label %j
bypass:
  br label %j
j:
  %p = phi i32 [ %carry, %thru ], [ 7, %bypass ]
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
