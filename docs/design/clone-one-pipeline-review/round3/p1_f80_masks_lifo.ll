target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
define internal i32 @mix(x86_fp80 noundef %x, i32 noundef %i, double noundef %c) {
entry:
 %if = sitofp i32 %i to x86_fp80
 %cf = fpext double %c to x86_fp80
 %a = fadd x86_fp80 %x, %if
 %b = fsub x86_fp80 %x, %cf
 %c1 = fcmp olt x86_fp80 %a, %cf
 %c2 = icmp ne i32 %i, 0
 %g = and i1 %c1, %c2
 %r = select i1 %g, x86_fp80 %a, x86_fp80 %b
 %n = fptosi x86_fp80 %r to i32
 ret i32 %n
}
define i32 @probe(x86_fp80 %x, i32 %i, double %c) {
 %q = call x86_fp80 @cq_theta_f80(x86_fp80 %x, double 0.5)
 %j = call i32 @cq_theta_si32(i32 %i, double 0.75)
 %r = call i32 @mix(x86_fp80 %q, i32 %j, double %c)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
