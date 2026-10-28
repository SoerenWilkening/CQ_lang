; Rule 15 under a quantum predicate, in place (rule 2): `if (x > k) cq_theta(&x, y * c)` rotates the rail x
; by the angle rail A = (double)y * c with one ry_i32_qangle_controlled(flag, x, A); no per-arm rotation, no
; new register. The flag read x before its rotation, so it stays allocated (A4, as rule 10 keeps it).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @theta_inplace_controlled(i32 %x0, i32 %y0, double %t, double %c, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = call i32 @cq_theta_si32(i32 %y0, double %t)
  %yd = sitofp i32 %y to double
  %a = fmul double %yd, %c
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %x2 = call i32 @cq_theta_si32(i32 %x, double %a)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
; CHECK theta_inplace_controlled: %{{a}} = call i32 @cq_template_fmul_f64_hl(i32 %{{yd}}, double %{{c}})
; CHECK theta_inplace_controlled: call void @cqrt_ry_i32_qangle_controlled(i32 %{{f}}, i32 %{{x}}, i32 %{{a}})
; CHECK theta_inplace_controlled: call void @cq_template_fmul_f64_hl_unc(i32 %{{a}}, i32 %{{yd}}, double %{{c}})
; CHECK-COUNT theta_inplace_controlled: qangle 1
; CHECK-COUNT theta_inplace_controlled: @cqrt_ry_i32( 2
