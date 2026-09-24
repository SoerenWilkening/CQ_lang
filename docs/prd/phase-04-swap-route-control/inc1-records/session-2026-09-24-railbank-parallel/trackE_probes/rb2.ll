define i32 @f(i32 %x, i32 %y, i32 %m, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %g = icmp eq i32 %m, %n
  %tg = and i1 %g, %t
  br i1 %tg, label %A, label %M

A:
  %u = icmp sgt i32 %q, 2
  br i1 %u, label %B, label %D

B:
  br label %D

D:
  %kk = phi i32 [ %x, %A ], [ %y, %B ]
  %c = icmp eq i32 %kk, 0
  br i1 %c, label %E, label %M

E:
  br label %M

M:
  %r = phi i32 [ 7, %entry ], [ 8, %D ], [ 9, %E ]
  %m0 = call i32 @cq_measure_si32(i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m0, %m1
  ret i32 %s
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
