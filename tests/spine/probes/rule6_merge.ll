; cq-6h4w: CR rule 6 through a select whose arms are bijective updates of y or y itself (125), as a
; quantum-join phi and as a quantum select: the old y is cleaned by t = the same select chain over
; the arms' inverses read from y' (sub/xor of y', y' itself), copy_<W>(t, y), uncompute, free.
; @phi_upd: 125's shape. @sel_upd: a select of y ^ z and y. @three: a three-arm merge (a nested
; chain). @cond_reads: the condition reads y, so y' = (y > k) ? y + 1 : y is no bijection in y and
; the old y stays (no copy).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @phi_upd(i32 %x0, double %tx, i32 %y0, double %ty, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %a, label %j
a:
  %u = add nsw i32 %y, 1
  br label %j
j:
  %yp = phi i32 [ %u, %a ], [ %y, %entry ]
  %m = call i32 @cq_measure_si32(i32 %yp)
  ret i32 %m
}
; CHECK phi_upd: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 1)
; CHECK-COUNT phi_upd: call void @cqrt_copy_i32( 1
; CHECK-COUNT phi_upd: call i32 @cq_template_select_i32( 2
; CHECK-COUNT phi_upd: call void @cq_template_select_i32_unc( 1

define i32 @sel_upd(i32 %x0, double %tx, i32 %y0, double %ty, i32 %z0, double %tz, i32 %k) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %z = call i32 @cq_theta_si32(i32 %z0, double %tz)
  %c = icmp sgt i32 %x, %k
  %u = xor i32 %y, %z
  %yp = select i1 %c, i32 %u, i32 %y
  %m = call i32 @cq_measure_si32(i32 %yp)
  %mz = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %m, %mz
  ret i32 %s
}
; CHECK-COUNT sel_upd: call void @cqrt_copy_i32( 1
; CHECK-COUNT sel_upd: call i32 @cq_template_xor_i32( 2

define i32 @three(i32 %x0, double %tx, i32 %y0, double %ty, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %a, label %b
a:
  %u = add i32 %y, 1
  br label %j
b:
  %d = icmp eq i32 %x, 0
  br i1 %d, label %bb, label %j
bb:
  %v = mul i32 %y, 3
  br label %j
j:
  %yp = phi i32 [ %u, %a ], [ %v, %bb ], [ %y, %b ]
  %m = call i32 @cq_measure_si32(i32 %yp)
  ret i32 %m
}
; CHECK-COUNT three: call void @cqrt_copy_i32( 1
; CHECK-COUNT three: call i32 @cq_template_mul_i32_hl( 2

define i32 @cond_reads(i32 %y0, double %ty, i32 %k) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %c = icmp sgt i32 %y, %k
  br i1 %c, label %a, label %j
a:
  %u = add nsw i32 %y, 1
  br label %j
j:
  %yp = phi i32 [ %u, %a ], [ %y, %entry ]
  %m = call i32 @cq_measure_si32(i32 %yp)
  ret i32 %m
}
; CHECK-COUNT cond_reads: call void @cqrt_copy_i32( 0
