target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @wide(i32 noundef %a, i32 noundef %b) {
entry:
 %ca = icmp slt i32 %a, 71
 %cb = icmp ne i32 %b, 12
 %g = and i1 %ca, %cb
 %t = mul i32 %a, %b
 %f = add i32 %a, %b
 %r = select i1 %g, i32 %t, i32 %f
 ret i32 %r
}
define i32 @probe(i32 %x) {
entry:
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 switch i32 %q, label %d [ i32 1, label %a i32 4, label %b ]
a:
 br label %merge
b:
 br label %merge
d:
 br label %merge
merge:
 %v = phi i32 [5, %a], [8, %b], [12, %d]
 %r = call i32 @wide(i32 %q, i32 %v)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
