target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @leaf(i32 noundef %a) {
entry:
 %c1 = icmp sgt i32 %a, 1
 %c2 = icmp slt i32 %a, 19
 %g = and i1 %c1, %c2
 %t = xor i32 %a, 41
 %f = add i32 %a, 13
 %r = select i1 %g, i32 %t, i32 %f
 ret i32 %r
}
define internal i32 @outer(i32 noundef %q) {
entry:
 %a = call i32 @leaf(i32 %q)
 %b = call i32 @leaf(i32 %a)
 %c1 = icmp slt i32 %b, 100
 %c2 = icmp ne i32 %q, 7
 %g = and i1 %c1, %c2
 %r = select i1 %g, i32 %a, i32 %b
 ret i32 %r
}
define i32 @probe(i32 %x) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @outer(i32 %q)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
