; rot-cry probes (cq-w1-rot-cry): controlled cq_theta shapes with no state-prep merge phi.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)

; Two thetas of one seed in disjoint arms, nothing reads either (140's r): ONE register rail seeded
; with r0, the else arm's Ry under the negated flag.
; CHECK-COUNT two_one_seed: call i32 @cqrt_alloc_i32( 2
; CHECK two_one_seed: %{{r}} = call i32 @cqrt_alloc_i32(i32 %r0)
; CHECK-COUNT two_one_seed: call void @cqrt_ry_i32_controlled( 2
; CHECK-COUNT two_one_seed: call void @cqrt_xorc_i32_controlled( 0
define void @two_one_seed(i32 %x0, double %t, i32 %k, i32 %r0, double %t1, double %t2) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c = icmp sgt i32 %x, %k
  br i1 %c, label %a, label %b
a:
  %ra = call i32 @cq_theta_si32(i32 %r0, double %t1)
  br label %j
b:
  %rb = call i32 @cq_theta_si32(i32 %r0, double %t2)
  br label %j
j:
  ret void
}

; Two thetas of one seed whose predicates overlap (both may run): two registers.
; CHECK-COUNT overlapping_preds: call i32 @cqrt_alloc_i32(i32 %r0) 2
; CHECK-COUNT overlapping_preds: call void @cqrt_ry_i32_controlled( 2
define void @overlapping_preds(i32 %x0, double %t, i32 %k1, i32 %k2, i32 %r0, double %t1, double %t2) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c1 = icmp sgt i32 %x, %k1
  br i1 %c1, label %a, label %m
a:
  %ra = call i32 @cq_theta_si32(i32 %r0, double %t1)
  br label %m
m:
  %c2 = icmp slt i32 %x, %k2
  br i1 %c2, label %b, label %j
b:
  %rb = call i32 @cq_theta_si32(i32 %r0, double %t2)
  br label %j
j:
  ret void
}

; A rotation of the register its own flag is (`if (q) cq_theta(&q, a)` on a bool): the flag is read
; into a fresh rail first (an in-place target is never its own control, CR 1.3); that copy read q
; before the rotation, so it is never freed (rule 10, A4).
; CHECK self_flag: %{{q}} = call i32 @cqrt_alloc_i1(i1 %b0)
; CHECK self_flag: %{{f}} = call i32 @cqrt_alloc_i1(i1 false)
; CHECK self_flag: call void @cqrt_xor_i1(i32 %{{q}}, i32 %{{f}})
; CHECK self_flag: call void @cqrt_ry_i1_controlled(i32 %{{f}}, i32 %{{q}}, double %a)
; CHECK-COUNT self_flag: call void @cqrt_free( 0
define void @self_flag(i1 %b0, double %t, double %a) {
  %q = call i1 @cq_theta_i1(i1 %b0, double %t)
  br i1 %q, label %y, label %j
y:
  %q2 = call i1 @cq_theta_i1(i1 %q, double %a)
  br label %j
j:
  ret void
}
