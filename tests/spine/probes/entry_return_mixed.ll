; cq-albd, cq-29ej: a _Bool entry that returns its unmeasured register on one classical path and a
; classical constant on the other. Rule 19 makes its return type the i32 handle; the classical i1 is
; returned as a seed rail of its value (rule 7), escaped like the register.
; CHECK mixed: call i32 @cqrt_alloc_i1(i1 false)
; (No USERCHECK: cqcheck user reads a rule-19 retyped return with the C type, cq-gpam.)
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
