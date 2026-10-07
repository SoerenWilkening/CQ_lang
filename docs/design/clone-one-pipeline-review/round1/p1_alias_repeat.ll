target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @calc(i32 noundef %a, i32 noundef %b) {
entry:
 %ca = icmp slt i32 %a, 17
 %cb = icmp ne i32 %b, 0
 %c = and i1 %ca, %cb
 %t = add i32 %a, 6
 %f = xor i32 %b, 29
 %v = select i1 %c, i32 %t, i32 %f
 %d = icmp eq i32 %a, 12
 %u = select i1 %d, i32 %v, i32 %b
 %r = add i32 %u, %a
 ret i32 %r
}
define i32 @probe(i32 %x) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @calc(i32 %q, i32 %q)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
