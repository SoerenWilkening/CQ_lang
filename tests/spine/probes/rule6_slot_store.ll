; cq-1jxg: CR rule 6 (owner 2026-11-01 on cq-6a2a): a store of the old value into a local slot cell
; extends its reader set (the cell's later loads), it is no escape; the clean-up follows the last load
; (late when the loads come in a later block), never skipped. Only memory read after the function
; returns (a global) or a QRAM store keeps it.
; @later: x's image u = x + 5; x stored to a local cell and loaded back once more (r = c * c): x is
; cleaned from u after the load.
; @later_block: the load comes after a classical branch, in another block: the clean-up is late.
; @later_block_ssa: the same without the cell (x read directly in the guarded block): the local flush
; at the entry's end must not drop x's clean-up while u is still garbage (u is measured in the join).
; @never_read: the cell is never loaded again: x is cleaned.
; @gated: u is rotated before the load reads x again: no clean-up point, x kept.
; @global: x stored into a global (read after the function returns): an escape, x kept.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

@g = global i32 0

define i32 @later(i32 %x0, double %th) {
  %cell = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  store i32 %x, ptr %cell, align 4
  %c = load i32, ptr %cell, align 4
  %r = mul i32 %c, %c
  %mu = call i32 @cq_measure_si32(i32 %u)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mu, %mr
  ret i32 %s
}
; CHECK-COUNT later: call void @cqrt_copy_i32( 1
; CHECK later: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 5)

define i32 @later_block(i32 %x0, double %th, i32 %k) {
  %cell = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  store i32 %x, ptr %cell, align 4
  %b = icmp sgt i32 %k, 0
  br i1 %b, label %then, label %join
then:
  %c = load i32, ptr %cell, align 4
  %r = mul i32 %c, %c
  %mr = call i32 @cq_measure_si32(i32 %r)
  br label %join
join:
  %p = phi i32 [ %mr, %then ], [ 0, %0 ]
  %mu = call i32 @cq_measure_si32(i32 %u)
  %s = add i32 %mu, %p
  ret i32 %s
}
; CHECK-COUNT later_block: call void @cqrt_copy_i32( 1

define i32 @later_block_ssa(i32 %x0, double %th, i32 %k) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  %b = icmp sgt i32 %k, 0
  br i1 %b, label %then, label %join
then:
  %r = mul i32 %x, %x
  %mr = call i32 @cq_measure_si32(i32 %r)
  br label %join
join:
  %p = phi i32 [ %mr, %then ], [ 0, %0 ]
  %mu = call i32 @cq_measure_si32(i32 %u)
  %s = add i32 %mu, %p
  ret i32 %s
}
; CHECK-COUNT later_block_ssa: call void @cqrt_copy_i32( 1

define i32 @never_read(i32 %x0, double %th) {
  %cell = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  store i32 %x, ptr %cell, align 4
  %mu = call i32 @cq_measure_si32(i32 %u)
  ret i32 %mu
}
; CHECK-COUNT never_read: call void @cqrt_copy_i32( 1

define i32 @gated(i32 %x0, double %th) {
  %cell = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  store i32 %x, ptr %cell, align 4
  %v = call i32 @cq_theta_si32(i32 %u, double %th)
  %c = load i32, ptr %cell, align 4
  %r = mul i32 %c, %c
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mv, %mr
  ret i32 %s
}
; CHECK-COUNT gated: call void @cqrt_copy_i32( 0

define i32 @global(i32 %x0, double %th) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %u = add i32 %x, 5
  store i32 %x, ptr @g, align 4
  %mu = call i32 @cq_measure_si32(i32 %u)
  ret i32 %mu
}
; CHECK-COUNT global: call void @cqrt_copy_i32( 0
