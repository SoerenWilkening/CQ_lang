; P-A — MergePhiPeel's P3b clause REFUSES to peel a phi with an undef incoming.
; bd z9t1's phi rule rewrites undef incomings of any phi carrying the theta's
; result, so this phi now PASSES P3b.  Note `%t` is a DIFFERENT C object from the
; seed object, and is undefined on ONE edge only -- so the record's gloss
; ("only where the object was undefined on BOTH edges") does not describe it.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %q = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %q, label %arm, label %join
arm:
  br label %join
join:
  %t = phi i1  [ %q, %arm ], [ false, %entry ]
  %y = phi i32 [ 9, %arm ],  [ 7, %entry ]
  %a = call i1 @cq_measure_i1(i1 %t)
  %b = call i32 @cq_measure_si32(i32 %y)
  %z = zext i1 %a to i32
  %s = add i32 %b, %z
  ret i32 %s
}
