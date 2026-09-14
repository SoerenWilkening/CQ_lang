; P-B — a 3-incoming phi carrying the theta's result with undef on TWO edges.
; The rule rewrites EVERY same-typed undef incoming of such a phi.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @example(i32 %k) {
entry:
  %q = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  switch i32 %k, label %d [ i32 1, label %x
                            i32 2, label %y ]
x:
  br label %join
y:
  br label %join
d:
  br label %join
join:
  %t = phi i1 [ %q, %x ], [ undef, %y ], [ undef, %d ]
  %a = call i1 @cq_measure_i1(i1 %t)
  %z = zext i1 %a to i32
  ret i32 %z
}
