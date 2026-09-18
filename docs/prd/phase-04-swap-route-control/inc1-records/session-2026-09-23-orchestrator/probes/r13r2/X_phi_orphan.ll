; A 2-incoming `i1` phi (isCondRailPhiShape == true) whose ONLY use is a flatten
; residue.  No attribute lie anywhere -- a PHI is trivially dead when unused.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c0 = icmp sgt i32 %u, 0
  br i1 %c0, label %p, label %j
p:
  %pb = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %j
j:
  %ph = phi i1 [ %pb, %p ], [ false, %entry ]
  %dead = and i1 %ph, false
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %j ]
  %p2 = phi i1 [ %dead, %arm ], [ false, %j ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
