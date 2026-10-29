; cq-mjwb: rule 18 copy-out of a clone's return phi chosen classically (119). The copy-out is made on
; each incoming edge into a result rail of its own (an edge leaving a block that branches elsewhere
; gets a block of its own), the arm's garbage is uncomputed in its own arm, and the return returns
; the phi of the result rails. @crit: the base case is the entry's edge to the join (critical, the
; formal is copied). @plain: both edges leave single-successor blocks. @konst: one arm is classical
; (seeded into the result rail).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @return_phi(i32 %x0, double %t, i32 %n) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = call i32 @crit(i32 %x, i32 %n)
  %b = call i32 @plain(i32 %x, i32 %n)
  %c = call i32 @konst(i32 %x, i32 %n)
  %ma = call i32 @cq_measure_si32(i32 %a)
  %mb = call i32 @cq_measure_si32(i32 %b)
  %mc = call i32 @cq_measure_si32(i32 %c)
  %s0 = add i32 %ma, %mb
  %s = add i32 %s0, %mc
  ret i32 %s
}

define internal i32 @crit(i32 %q, i32 %n) noinline {
entry:
  %z = icmp slt i32 %n, 1
  br i1 %z, label %join, label %arm
arm:
  %u = add i32 %q, 3
  %v = mul i32 %u, %n
  br label %join
join:
  %r = phi i32 [ %v, %arm ], [ %q, %entry ]
  ret i32 %r
}

define internal i32 @plain(i32 %q, i32 %n) noinline {
entry:
  %z = icmp slt i32 %n, 1
  br i1 %z, label %a, label %b
a:
  %u = add i32 %q, 3
  br label %join
b:
  %v = sub i32 %q, %n
  %w = xor i32 %v, 5
  br label %join
join:
  %r = phi i32 [ %u, %a ], [ %w, %b ]
  ret i32 %r
}

define internal i32 @konst(i32 %q, i32 %n) noinline {
entry:
  %z = icmp slt i32 %n, 1
  br i1 %z, label %join, label %arm
arm:
  %u = add i32 %q, 7
  br label %join
join:
  %r = phi i32 [ %u, %arm ], [ 5, %entry ]
  ret i32 %r
}
; CHECK __cq_q_crit_10: call void @cqrt_copy_i32(i32 %0, i32 %{{f}})
; CHECK-COUNT __cq_q_crit_10: call i32 @cqrt_alloc_i32(i32 0) 2
; CHECK-COUNT __cq_q_crit_10: call void @cqrt_copy_i32( 2
; CHECK-COUNT __cq_q_crit_10: phi i32 1
; CHECK-COUNT __cq_q_crit_10: call void @cqrt_free( 2
; CHECK-COUNT __cq_q_plain_10: call i32 @cqrt_alloc_i32(i32 0) 2
; CHECK-COUNT __cq_q_plain_10: call void @cqrt_copy_i32( 2
; CHECK-COUNT __cq_q_plain_10: call void @cqrt_free( 3
; CHECK-COUNT __cq_q_plain_10: phi i32 1
; CHECK __cq_q_konst_10: call i32 @cqrt_alloc_i32(i32 5)
; CHECK-COUNT __cq_q_konst_10: call void @cqrt_copy_i32( 1
