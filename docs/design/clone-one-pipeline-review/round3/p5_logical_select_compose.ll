target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @logical(i32 noundef %a) {
entry:
 %c1 = icmp eq i32 %a, 23
 %c2 = icmp slt i32 %a, 4
 %c3 = icmp ne i32 %a, 1
 %o = select i1 %c1, i1 true, i1 %c2
 %g = select i1 %o, i1 %c3, i1 false
 br i1 %g, label %yes, label %no
yes:
 %t = add i32 %a, 3
 br label %exit
no:
 %f = xor i32 %a, 17
 br label %exit
exit:
 %r = phi i32 [%t,%yes], [%f,%no]
 ret i32 %r
}
define i32 @probe(i32 %x) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @logical(i32 %q)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
