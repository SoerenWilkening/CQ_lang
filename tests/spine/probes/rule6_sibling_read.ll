; cq-tmvo: CR rule 6's "dead" sees a read in a sibling arm of a branch that joined before the update as
; earlier (review pass-h3 971_u01). s = z + x with z and x both rotated registers, both dead, z read
; only in one quantum arm: neither is garbage, so operand 0 (z) is cleaned, t = s - x, and x is kept.
; Then s2 = s + w: s is no garbage rule 5 can uncompute any more (its _unc would read the cleaned z),
; so again operand 0 (s) is cleaned, t = s2 - w, and w is kept (CR rule 6, both operands dead).
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)

define i32 @u01(i32 %x0, double %th, i32 %z0, double %th2, i32 %w0, double %th3, double %a) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %z = call i32 @cq_theta_si32(i32 %z0, double %th2)
  %w = call i32 @cq_theta_si32(i32 %w0, double %th3)
  %c = icmp sgt i32 %x, 1
  br i1 %c, label %l, label %r
l:
  %cz = icmp sgt i32 %z, 2
  br i1 %cz, label %p, label %j
r:
  %cw = icmp sgt i32 %w, 3
  br i1 %cw, label %p, label %j
p:
  call void @cq_phi(double %a)
  br label %j
j:
  %s = add nsw i32 %z, %x
  %s2 = add nsw i32 %s, %w
  ret i32 %s2
}
; CHECK u01: call void @cqrt_add_i32(i32 %1, i32 %2)
; CHECK u01: call void @cqrt_add_i32(i32 %3, i32 %2)
; CHECK-COUNT u01: call void @cq_template_add_i32_unc( 0
