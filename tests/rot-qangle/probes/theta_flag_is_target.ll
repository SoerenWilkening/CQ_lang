; CR §1.3: an in-place target is never one of its own controls. `if (b) cq_theta(&b, a)` with a quantum
; angle reads the flag b into a fresh i1 rail first (alloc_i1 0, xor_i1), then one
; ry_i1_qangle_controlled(copy, b, A).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @theta_flag_is_target(i1 %b0, i32 %y0, double %t, double %c) {
entry:
  %b = call zeroext i1 @cq_theta_i1(i1 zeroext %b0, double %t)
  %y = call i32 @cq_theta_si32(i32 %y0, double %t)
  %yd = sitofp i32 %y to double
  %a = fmul double %yd, %c
  br i1 %b, label %then, label %done
then:
  %b2 = call zeroext i1 @cq_theta_i1(i1 zeroext %b, double %a)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
; CHECK theta_flag_is_target: %{{g}} = call i32 @cqrt_alloc_i1(i1 false)
; CHECK theta_flag_is_target: call void @cqrt_xor_i1(i32 %{{b}}, i32 %{{g}})
; CHECK theta_flag_is_target: call void @cqrt_ry_i1_qangle_controlled(i32 %{{g}}, i32 %{{b}}, i32 %{{a}})
; CHECK-COUNT theta_flag_is_target: qangle 1
