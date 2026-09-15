declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]
  %dz = zext i32 %q to i64
  %dd = add i64 %dz, -7
  %mz = zext i32 %MB to i64
  %pm = mul i64 %dd, %mz
  %u = trunc i64 %pm to i32
  %r = call i32 @cq_theta_si32(i32 %MB, double 9.000000e-01)
  %m0 = call i32 @cq_measure_si32(i32 %r)
  br label %J
Y:
  br label %J
J:
  %p = phi i32 [ %u, %mB ], [ 0, %Y ]
  %mp = phi i32 [ %m0, %mB ], [ 0, %Y ]
  ret i32 %mp
}
