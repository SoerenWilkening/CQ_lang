target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
define internal i32 @boolcalc(i1 noundef %b, i32 noundef %a) {
entry:
 %t = add i32 %a, 11
 %r = select i1 %b, i32 %t, i32 %a
 ret i32 %r
}
define i32 @probe(i1 %b, i32 %a) {
 %q = call i1 @cq_theta_i1(i1 %b, double 0.5)
 %r = call i32 @boolcalc(i1 %q, i32 %a)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
