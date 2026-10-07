target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @conddata(i32 noundef %a) {
entry:
 %c1 = icmp sgt i32 %a, 3
 %c2 = icmp slt i32 %a, 88
 %g = and i1 %c1, %c2
 %t = xor i32 %a, 7
 %f = add i32 %a, 2
 %v = select i1 %g, i32 %t, i32 %f
 %gi = zext i1 %g to i32
 %ci = zext i1 %c1 to i32
 %v1 = add i32 %v, %gi
 %r = add i32 %v1, %ci
 ret i32 %r
}
define i32 @probe(i32 %x) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @conddata(i32 %q)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
