declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = and i32 %q, 3
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %a = phi i32 [ 5, %entry ], [ %an, %latch ]
  %b = phi i32 [ 6, %entry ], [ %bn, %latch ]
  switch i32 %s, label %c0 [ i32 1, label %c1
                             i32 2, label %c2 ]
c0:
  %a0 = add i32 %a, 1
  br label %latch
c1:
  %a1 = add i32 %a, 2
  br label %latch
c2:
  %a2 = add i32 %a, 3
  br label %latch
latch:
  %an = phi i32 [ %a0, %c0 ], [ %a1, %c1 ], [ %a2, %c2 ]
  %bn = phi i32 [ 7, %c0 ], [ 8, %c1 ], [ 9, %c2 ]
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %an)
  %m2 = call i32 @cq_measure_si32(i32 %bn)
  %r = add i32 %m1, %m2
  ret i32 %r
}
