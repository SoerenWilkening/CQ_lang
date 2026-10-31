; cq-oqih: CR rule 6's "dead" must not take a read in a sibling arm of the update's own quantum branch
; for an earlier one (49, 158 regressed to 'cleanupBijective requested twice'). Both arms read the
; register x: a quantum branch emits both arms, so x is read after the first arm's update and is
; dead after neither; rule 6 cleans nothing (158's reference) and both arms' rails are rule 5 garbage.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @sibling(i32 %x0, double %th, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %c = icmp sgt i32 %x, 1
  br i1 %c, label %l, label %r
l:
  %a = add nsw i32 %x, %k
  br label %j
r:
  %b = sub nsw i32 %x, %k
  br label %j
j:
  %m = phi i32 [ %a, %l ], [ %b, %r ]
  %o = call i32 @cq_measure_si32(i32 %m)
  ret i32 %o
}
; CHECK-COUNT sibling: call void @cqrt_copy_i32( 0
; CHECK-COUNT sibling: call void @cq_template_add_i32_hl_unc( 1
; CHECK-COUNT sibling: call void @cq_template_sub_i32_hl_unc( 1
