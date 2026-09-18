; ARM ON THE FALSE SUCCESSOR (so buildNegation runs on the rail and track()s it),
; and TWO merge phis whose every incoming is the i1 constant false — so the
; BoolAlg composer DROPS every term and NOTHING references the edge predicates.
; The rail's only other use is the branch condition, which the flatten erases.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %rail, label %merge, label %arm
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
