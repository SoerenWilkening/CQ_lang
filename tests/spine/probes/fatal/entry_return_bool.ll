; FATAL: cq: unimplemented: spine: an entry returning a quantum value in a C return type narrower than i32
; cq-juf6 (review pass-h3 976_u06): a _Bool entry returning its unmeasured register. The i32 handle does
; not fit the C signature rule 19 keeps; it used to be truncated to i1 (another rail's handle).
declare i1 @cq_theta_i1(i1, double)

define zeroext i1 @u06(i1 zeroext %b0, double %t) {
entry:
  %b = call i1 @cq_theta_i1(i1 %b0, double %t)
  ret i1 %b
}
