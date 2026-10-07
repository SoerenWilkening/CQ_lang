target triple = "x86_64-unknown-linux-gnu"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @classloop(i32 noundef %q, i32 noundef %a) {
entry:
 br label %loop
loop:
 %k = phi i32 [ 0, %entry ], [ %kn, %loop ]
 %v = phi i32 [ %a, %entry ], [ %vn, %loop ]
 %vn = mul i32 %v, 3
 %kn = add nuw nsw i32 %k, 1
 %go = icmp ult i32 %kn, 4
 br i1 %go, label %loop, label %exit, !llvm.loop !0
exit:
 %r = add i32 %q, %vn
 ret i32 %r
}
define i32 @probe(i32 %x, i32 %a) {
 %q = call i32 @cq_theta_si32(i32 %x, double 0.5)
 %r = call i32 @classloop(i32 %q, i32 %a)
 %m = call i32 @cq_measure_si32(i32 %r)
 ret i32 %m
}
!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
