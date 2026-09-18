declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u, double 7.000000e-01)
  switch i32 %s, label %merge [ i32 1, label %a1
                                i32 2, label %a2 ]
a1:
  %x1 = add i32 %q, 3
  br label %merge
a2:
  %x2 = mul i32 %q, 5
  br label %merge
merge:
  %p1 = phi i1 [ false, %a1 ], [ false, %a2 ], [ false, %entry ]
  %p2 = phi i1 [ false, %a1 ], [ false, %a2 ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %a  = add i32 %z1, %z2
  %b  = add i32 %a, %m
  ret i32 %b
}
