target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @countshift(i32 noundef %x) {
entry:
 br label %loop
loop:
 %v = phi i32 [ %x, %entry ], [ %vn, %loop ]
 %c = phi i32 [ 57, %entry ], [ %cn, %loop ]
 %cn = add i32 %c, -1
 %vn = shl i32 %v, 1
 %again = icmp sgt i32 %vn, 0
 br i1 %again, label %loop, label %exit
exit:
 ret i32 %cn
}
define i32 @probe(i32 %x) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @countshift(i32 %q)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
