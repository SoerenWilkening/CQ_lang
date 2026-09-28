; a1 BEFORE SimplifyCFG's sink + InstSimplify's select(q==s,q,s)->s: the program the user wrote.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @slice(i32 %m, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 7, double 4.000000e-01)
  %c2 = icmp sgt i32 %q2, 3
  br i1 %c2, label %outer, label %merge
outer:
  %c = icmp eq i32 %q, %s
  br i1 %c, label %then, label %else
then:
  %a = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %imerge
else:
  %b = call i32 @cq_theta_si32(i32 %s, double 9.000000e-01)
  br label %imerge
imerge:
  %ri = phi i32 [ %a, %then ], [ %b, %else ]
  br label %merge
merge:
  %r = phi i32 [ %s, %entry ], [ %ri, %imerge ]
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mq2 = call i32 @cq_measure_si32(i32 %q2)
  %x = add i32 %mr, %mq2
  ret i32 %x
}
