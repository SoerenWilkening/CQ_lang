

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %m2, label %arm2
arm2:
  %t2 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %m2
m2:
  %b1 = phi i32 [ %t2, %arm2 ], [ 0, %m1 ]
  %cq.peel.cond = icmp eq i32 %out, 13
  %amux = select i1 %cq.peel.cond, i32 2, i32 5
  %c3 = icmp eq i32 %amux, 5
  br i1 %c3, label %m3, label %arm3
arm3:
  %t3 = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  br label %m3
m3:
  %b2 = phi i32 [ %t3, %arm3 ], [ 0, %m2 ]
  %x3 = call i32 @cq_measure_si32(i32 %b2)
  %x0 = call i32 @cq_measure_si32(i32 %b0)
  %x1 = call i32 @cq_measure_si32(i32 %out)
  %x2 = call i32 @cq_measure_si32(i32 %b1)
  %xa = call i32 @cq_measure_si32(i32 %amux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  %s3 = add nsw i32 %s2, %xa
  ret i32 %s3
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }




define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}
