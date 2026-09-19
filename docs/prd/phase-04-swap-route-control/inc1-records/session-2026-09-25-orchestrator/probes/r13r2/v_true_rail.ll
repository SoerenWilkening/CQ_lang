; R2 probe: interior rail phi, and every merge phi lists J LAST so ONLY the
; FALSE-edge literal of J is demanded (literal(J,0), which would carry the
; off-grammar select, is never built).
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
  %rp = phi i1 [ true, %P ], [ %rail, %Q ]
  br i1 %rp, label %M, label %C
C:
  br label %M
M:
  %v = phi i32 [ 2, %C ], [ 7, %Q ], [ 5, %J ]
  %w = phi i32 [ 3, %C ], [ 8, %Q ], [ 6, %J ]
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %w)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
