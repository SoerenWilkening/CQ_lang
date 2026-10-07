target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @fresh(i32 noundef %a) {
entry:
 %c1 = icmp sgt i32 %a, 10
 %c2 = icmp ne i32 %a, 16
 %g = and i1 %c1, %c2
 %t = add i32 %a, 2
 %f = xor i32 %a, 1
 %r = select i1 %g, i32 %t, i32 %f
 ret i32 %r
}
define i32 @probe(i32 %x) {
entry:
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 switch i32 %q, label %d [ i32 2, label %a i32 9, label %b ]
a:
 br label %merge
b:
 br label %merge
d:
 br label %merge
merge:
 %v = phi i32 [11, %a], [16, %b], [19, %d]
 %r = call i32 @fresh(i32 %v)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
