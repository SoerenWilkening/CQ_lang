; FATAL: cq: unimplemented: spine: an entry whose return type rule 19 made the i32 handle returns a classical
; cq-albd: a _Bool entry that returns its unmeasured register on one classical path and a classical
; constant on the other. Rule 19 makes its return type the i32 handle; the classical i1 has no handle.
declare i1 @cq_theta_i1(i1, double)

define zeroext i1 @mixed(i1 zeroext %b0, double %t, i32 %n) {
entry:
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %q, label %k
q:
  %b = call i1 @cq_theta_i1(i1 %b0, double %t)
  ret i1 %b
k:
  ret i1 false
}
