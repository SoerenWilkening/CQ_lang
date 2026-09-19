; R2 probe: rail phi in a TRULY INTERIOR region block (J is not the ipdom of entry,
; because Q bypasses it). convertPhis(J) must take the SELECT-CHAIN path.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  %c2 = icmp slt i32 %q, 9
  br i1 %c, label %P, label %Q
P:
  br label %J
Q:
  br i1 %c2, label %J, label %M
J:
  %rp = phi i1 [ %rail, %P ], [ true, %Q ]
  br i1 %rp, label %M, label %C
C:
  br label %M
M:
  %v = phi i32 [ 2, %C ], [ 5, %J ], [ 7, %Q ]
  %w = phi i32 [ 3, %C ], [ 6, %J ], [ 8, %Q ]
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %w)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
