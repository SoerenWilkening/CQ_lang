@g_probe = global i32 0


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
  %amux = phi i32 [ 5, %arm2 ], [ 2, %m1 ]
  %b1 = phi i32 [ %t2, %arm2 ], [ 0, %m1 ]
  %ht = call fastcc i32 @helper(i32 %amux)
  %hm = call i32 @cq_measure_si32(i32 %ht)
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




define internal fastcc i32 @helper(i32 %x) unnamed_addr #0 {
  %y = add nsw i32 %x, 1
  ret i32 %y
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}
