; cq-6a2a: CR rule 6 Dead is asked at the clean-up point (CQ_spec cbda16a, owner ruling on cq-k7f8).
; @later: x's image u = x + 5 is live, x is read once more after the update (r = x * x, measured): the
; reader only moves the clean-up after it (t = u - 5, copy into x, free x).
; @gated: u is rotated before the later reader: no point lies after the reader and before the gate on
; the image, so x is kept (no copy).
; @rmw: 94's shape. An atomicrmw add on a slot cell holding x leaves x + c there; the cmpxchg's select
; reads the old x after it; x is cleaned from x + c after the select.
; @twice: x has two bijective images (b' = x ^ y, then y rotated, then x ^ m); the clean-up point is
; after the last reader, the second update, whose image is the live one (180).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @later(i32 %x0, double %th) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  %r = mul i32 %x, %x
  %mu = call i32 @cq_measure_si32(i32 %u)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mu, %mr
  ret i32 %s
}
; CHECK-COUNT later: call void @cqrt_copy_i32( 1
; CHECK later: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 5)

define i32 @gated(i32 %x0, double %th) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  %v = call i32 @cq_theta_si32(i32 %u, double %th)
  %r = mul i32 %x, %x
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mv, %mr
  ret i32 %s
}
; CHECK-COUNT gated: call void @cqrt_copy_i32( 0

define i32 @rmw(i32 %x0, double %th, i32 %c, i32 %e) {
  %cell = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  call void @llvm.lifetime.start.p0(i64 4, ptr %cell)
  store i32 %c, ptr %cell, align 4
  store atomic i32 %x, ptr %cell seq_cst, align 4
  %old = atomicrmw add ptr %cell, i32 %c seq_cst, align 4
  %cx = cmpxchg ptr %cell, i32 %e, i32 %old seq_cst seq_cst, align 4
  %ok = extractvalue { i32, i1 } %cx, 1
  %seen = extractvalue { i32, i1 } %cx, 0
  %okz = zext i1 %ok to i32
  %now = load atomic i32, ptr %cell seq_cst, align 4
  %m1 = call i32 @cq_measure_si32(i32 %now)
  %m2 = call i32 @cq_measure_si32(i32 %okz)
  %m3 = call i32 @cq_measure_si32(i32 %seen)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  call void @llvm.lifetime.end.p0(i64 4, ptr %cell)
  ret i32 %s2
}
; CHECK-COUNT rmw: call void @cqrt_copy_i32( 1
; CHECK rmw: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 %c)

define i32 @twice(i32 %x0, double %tx, i32 %y0, double %ty) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %y = call i32 @cq_theta_si32(i32 %y0, double %ty)
  %b = xor i32 %y, %x
  %y2 = call i32 @cq_theta_si32(i32 %y, double %ty)
  %mb = call i32 @cq_measure_si32(i32 %b)
  %c = xor i32 %x, %mb
  %mc = call i32 @cq_measure_si32(i32 %c)
  %my = call i32 @cq_measure_si32(i32 %y2)
  %s = add i32 %mc, %my
  ret i32 %s
}
; CHECK-COUNT twice: call void @cqrt_copy_i32( 1
; CHECK twice: call i32 @cq_template_xor_i32_hl(i32 %{{t}}, i32 %{{m}})
