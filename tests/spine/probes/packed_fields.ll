; cq-0umd: CR rule 26 with rule 3. -O1 coerces struct { int, int } to one i64 by zext / shl 32 / or
; disjoint and unpacks it by trunc / lshr 32 / trunc (159, 166). The packing and unpacking are classical
; ABI arithmetic on the coercion: no gate, the fields stay their own rails. A classical field rides
; along as a classical value (%c below), and a read of the classical half alone is classical.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @pack_two(i32 %x, double %tx, i32 %y, double %ty) {
  %a = tail call i32 @cq_theta_si32(i32 %x, double %tx)
  %b = tail call i32 @cq_theta_si32(i32 %y, double %ty)
  %zb = zext i32 %b to i64
  %sb = shl nuw i64 %zb, 32
  %za = zext i32 %a to i64
  %p = or disjoint i64 %sb, %za
  %lo = trunc i64 %p to i32
  %h = lshr i64 %p, 32
  %hi = trunc nuw i64 %h to i32
  %m1 = tail call i32 @cq_measure_si32(i32 %lo)
  %m2 = tail call i32 @cq_measure_si32(i32 %hi)
  %r = add i32 %m1, %m2
  ret i32 %r
}

define i32 @pack_mixed(i32 %x, double %tx, i32 %c) {
  %a = tail call i32 @cq_theta_si32(i32 %x, double %tx)
  %zc = zext i32 %c to i64
  %sc = shl nuw i64 %zc, 32
  %za = zext i32 %a to i64
  %p = or disjoint i64 %sc, %za
  %lo = trunc i64 %p to i32
  %h = lshr i64 %p, 32
  %hi = trunc nuw i64 %h to i32
  %s = add i32 %lo, %hi
  %m = tail call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
; CHECK-COUNT pack_two: @cq_template_ 0
; CHECK pack_two: call i32 @cqrt_measure_i32(i32 %{{a}})
; CHECK pack_two: call i32 @cqrt_measure_i32(i32 %{{b}})
; CHECK-COUNT pack_mixed: @cq_template_zext 0
; CHECK-COUNT pack_mixed: @cq_template_shl 0
; CHECK-COUNT pack_mixed: @cq_template_or 0
; CHECK-COUNT pack_mixed: @cq_template_lshr 0
; CHECK-COUNT pack_mixed: @cq_template_trunc 0
; CHECK-COUNT pack_mixed: @cq_template_add_i32_hl( 1
