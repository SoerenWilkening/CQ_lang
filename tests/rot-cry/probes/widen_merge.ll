; rot-cry probes (cq-oa67, owner 2026-11-02 no stops): rule 10's register merged with straight-through
; values beyond the one seed: several classical values, one defined after the prep, and a quantum value
; that is not the register. Each other value is written into the register on its own edge at the merge
; (xorc of seed ^ u, or a cleared seed and a controlled basis copy of the rail), never a select of the
; rotated rail.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Two classical straight-through values on two edges: the first seeds the register, the second is
; xorc'ed in on its edge.
; CHECK two_straight: %{{r}} = call i32 @cqrt_alloc_i32(i32 %s1)
; CHECK-COUNT two_straight: call void @cqrt_xorc_i32_controlled( 2
; CHECK-COUNT two_straight: call void @cqrt_ry_i32_controlled( 1
; CHECK-COUNT two_straight: @cq_template_select 0
define i32 @two_straight(i32 %x0, double %t, i32 %k1, i32 %k2, i32 %s1, i32 %s2, i32 %v, double %a) {
e:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c1 = icmp sgt i32 %x, %k1
  br i1 %c1, label %p, label %q
p:
  %r1 = call i32 @cq_theta_si32(i32 %v, double %a)
  br label %j
q:
  %c2 = icmp slt i32 %x, %k2
  br i1 %c2, label %j, label %o
o:
  br label %j
j:
  %r = phi i32 [ %r1, %p ], [ %s1, %q ], [ %s2, %o ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The straight-through value is computed in the other arm, after the prep.
; CHECK-COUNT late_straight: call void @cqrt_ry_i32_controlled( 1
; CHECK-COUNT late_straight: @cq_template_select 0
define i32 @late_straight(i32 %x0, double %t, i32 %k, i32 %s, i32 %v, double %a) {
e:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %p, label %q
p:
  %r1 = call i32 @cq_theta_si32(i32 %v, double %a)
  br label %j
q:
  %s3 = mul i32 %s, 3
  br label %j
j:
  %r = phi i32 [ %r1, %p ], [ %s3, %q ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The straight-through value is a rail (x + 1): a controlled copy into the register on its edge.
; CHECK quantum_straight: call void @cqrt_copy_i32_controlled(
; CHECK-COUNT quantum_straight: call void @cqrt_ry_i32_controlled( 1
; CHECK-COUNT quantum_straight: @cq_template_select 0
define i32 @quantum_straight(i32 %x0, double %t, i32 %k, i32 %v, double %a) {
e:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %p, label %q
p:
  %r1 = call i32 @cq_theta_si32(i32 %v, double %a)
  br label %j
q:
  %x1 = add i32 %x, 1
  br label %j
j:
  %r = phi i32 [ %r1, %p ], [ %x1, %q ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
