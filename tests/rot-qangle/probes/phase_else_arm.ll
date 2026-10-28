; Rule 15 on the false edge of a quantum branch: `if (x > k) {} else cq_phi(a)` with a quantum angle is one
; rz_qangle_controlled on the flag of the else predicate; never the NOT-rail identity rz(-a) plus a global
; phase (79: with a quantum angle the leftover is relative), and never deleted (rule 12 is for classical
; angles).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @phase_else_arm(i32 %x0, double %t, double %c, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %xd = sitofp i32 %x to double
  %a = fmul double %xd, %c
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %done, label %else
else:
  call void @cq_phi(double %a)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK phase_else_arm: call void @cqrt_rz_qangle_controlled(i32 %{{g}}, i32 %{{a}})
; CHECK-COUNT phase_else_arm: qangle 1
; CHECK-COUNT phase_else_arm: rz_i1 0
