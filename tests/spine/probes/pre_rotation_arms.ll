; cq-drcl: regressions of cq-s32y's pre-rotation copy. A reader of the old value in the sibling arm
; of the rotation (quantum or classical branch) is not after the rotation: no copy, it reads the
; register. Rule 2's classical collapse is not refused by a classical join between the rotation of a
; source and its reader.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@g = global i32 0

; rev s32y-n1 a1: r rotated in the then arm of a quantum branch, read in the else arm.
define i32 @sib_q(i32 %x0, double %tx, i32 %r0, double %tr, i32 %k, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %r = call i32 @cq_theta_si32(i32 %r0, double %tr)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %a, label %b
a:
  %r2 = call i32 @cq_theta_si32(i32 %r, double %t)
  br label %j
b:
  %m3 = mul nsw i32 %r, 3
  %s1 = add nsw i32 %m3, 1
  br label %j
j:
  %rm = phi i32 [ %r2, %a ], [ %r, %b ]
  %s = phi i32 [ 0, %a ], [ %s1, %b ]
  %o1 = call i32 @cq_measure_si32(i32 %rm)
  %o2 = call i32 @cq_measure_si32(i32 %s)
  %o3 = call i32 @cq_measure_si32(i32 %x)
  %u = add nsw i32 %o1, %o2
  %v = add nsw i32 %u, %o3
  ret i32 %v
}
; CHECK sib_q: %{{r}} = call i32 @cqrt_alloc_i32(i32 %{{r0}})
; CHECK sib_q: = call i32 @cq_template_mul_i32_hl(i32 %{{r}}, i32 3)
; CHECK-COUNT sib_q: cqrt_copy 0

; rev s32y-n1 a2: the same under a classical branch (the else arm measures its value there: a2's
; quantum s merged at the classical join is cq-pugt).
define i32 @sib_c(i32 %x0, double %tx, i32 %c, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %z = icmp eq i32 %c, 0
  br i1 %z, label %b, label %a
a:
  %x2 = call i32 @cq_theta_si32(i32 %x, double %t)
  br label %j
b:
  %m3 = mul nsw i32 %x, 3
  %s1 = call i32 @cq_measure_si32(i32 %m3)
  br label %j
j:
  %xm = phi i32 [ %x2, %a ], [ %x, %b ]
  %s = phi i32 [ 0, %a ], [ %s1, %b ]
  %o1 = call i32 @cq_measure_si32(i32 %xm)
  %u = add nsw i32 %s, %o1
  ret i32 %u
}
; CHECK sib_c: = call i32 @cq_template_mul_i32_hl(i32 %{{x}}, i32 3)
; CHECK-COUNT sib_c: cqrt_copy 0

; rev s32y-n1 b1x: y = x + 7 after a classical join; x rotated before the join, then measured: y * 3
; collapses to the classical recomputation from x's outcome (as without the join).
define i32 @collapse_join(i32 %x0, double %tx, i32 %c, i32 %r0, double %tr) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %r = call i32 @cq_theta_si32(i32 %r0, double %tr)
  %z = icmp eq i32 %c, 0
  br i1 %z, label %j, label %s
s:
  store i32 1, ptr @g, align 4
  br label %j
j:
  %y = add nsw i32 %x, 7
  %yf = sitofp i32 %y to double
  %a = fmul double %yf, 2.500000e-01
  %r2 = call i32 @cq_theta_si32(i32 %r, double %a)
  %m = call i32 @cq_measure_si32(i32 %x)
  %y3 = mul nsw i32 %y, 3
  %t = add nsw i32 %m, %y3
  %mr = call i32 @cq_measure_si32(i32 %r2)
  %o = add nsw i32 %t, %mr
  ret i32 %o
}
; CHECK collapse_join: %{{y3}} = mul nsw i32 %{{yc}}, 3
; CHECK-COUNT collapse_join: cq_template_mul 0
; CHECK-COUNT collapse_join: cqrt_measure_i32 2
