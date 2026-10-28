; Rule 11: an angle chosen by a phi on a quantum flag is computed by the merge's select template into an
; f64 rail and consumed by one rz_qangle; no per-arm rz_i1.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @phase_phi_angle(i32 %x0, double %t, i32 %k, double %p, double %q) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  br label %done
done:
  %a = phi double [ %p, %then ], [ %q, %entry ]
  call void @cq_phi(double %a)
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK phase_phi_angle: call void @cqrt_rz_qangle(i32 %{{a}})
; CHECK-COUNT phase_phi_angle: cq_template_select_f64 2
; CHECK-COUNT phase_phi_angle: rz_i1 0
; CHECK-COUNT phase_phi_angle: qangle 1
