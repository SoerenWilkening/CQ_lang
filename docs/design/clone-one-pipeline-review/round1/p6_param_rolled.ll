target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @rolled(i32 noundef %q, i32 noundef %n) {
entry:
 %start = icmp sgt i32 %n, 0
 br i1 %start, label %loop, label %exit
loop:
 %k = phi i32 [0, %entry], [%kn, %loop]
 %acc = phi i32 [0, %entry], [%v, %loop]
 %v = add i32 %acc, %q
 %kn = add nuw nsw i32 %k, 1
 %again = icmp slt i32 %kn, %n
 br i1 %again, label %loop, label %exit
exit:
 %r = phi i32 [0, %entry], [%v, %loop]
 ret i32 %r
}
define i32 @probe(i32 %x, i32 %n) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @rolled(i32 %q, i32 %n)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
