; A prep of a classical value under a quantum predicate with a quantum angle (cq-oa67): rule 10's
; register (seeded with the straight-through value r0, xorc to r0 ^ x0 under the flag) rotated by rule
; 15's primitive under the flag; the merge names the register, no select.
; CHECK prep_controlled: %{{r}} = call i32 @cqrt_alloc_i32(i32 %r0)
; CHECK-COUNT prep_controlled: call void @cqrt_ry_i32_qangle_controlled( 1
; CHECK-COUNT prep_controlled: @cq_template_select 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @prep_controlled(i32 %x0, i32 %r0, double %t, double %c, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %xd = sitofp i32 %x to double
  %a = fmul double %xd, %c
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @cq_theta_si32(i32 %r0, double %a)
  br label %done
done:
  %rr = phi i32 [ %r, %then ], [ %r0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rr)
  ret i32 %m
}
