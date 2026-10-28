; rot-cry probes (cq-w1-rot-cry): state-prep merges (rule 10), lowered through rot::lowerStatePrepMerge.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; A prep of a classical value v that is neither 0 nor the straight-through value s: the reset is
; xorc(s ^ v) under the flag, computed classically.
; CHECK prep_other_value: %{{r}} = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK prep_other_value: %{{l}} = xor i32 %s, %v
; CHECK prep_other_value: call void @cqrt_xorc_i32_controlled(i32 %{{f}}, i32 %{{r}}, i32 %{{l}})
; CHECK prep_other_value: call void @cqrt_ry_i32_controlled(i32 %{{f}}, i32 %{{r}}, double %a)
; CHECK-COUNT prep_other_value: @cq_template_select 0
define i32 @prep_other_value(i32 %x0, double %t, i32 %k, i32 %s, i32 %v, double %a) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c = icmp eq i32 %x, %k
  br i1 %c, label %p, label %j
p:
  %r1 = call i32 @cq_theta_si32(i32 %v, double %a)
  br label %j
j:
  %r = phi i32 [ %r1, %p ], [ %s, %0 ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; Three preps of one register under three conditions (133 prep_twice, once more): before each prep,
; every earlier prep that may still be the register's state there is undone by its adjoint, last
; first, under the conjunction flag. Prep 3 undoes prep 2 (under c2 & c3) and prep 1 where prep 2 did
; not overwrite it (under c1 & !c2 & c3).
; CHECK-COUNT prep_thrice: call i32 @cqrt_alloc_i32(i32 %r0) 1
; CHECK-COUNT prep_thrice: call void @cqrt_ry_i32_controlled( 6
; CHECK-COUNT prep_thrice: call void @cqrt_xorc_i32_controlled( 6
; CHECK-COUNT prep_thrice: = fneg double %t1 2
; CHECK-COUNT prep_thrice: = fneg double %t2 1
; CHECK-COUNT prep_thrice: @cq_template_select 0
define i32 @prep_thrice(i32 %x0, double %t, i32 %k1, i32 %k2, i32 %k3, i32 %r0, double %t1, double %t2, double %t3) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %c1 = icmp sgt i32 %x, %k1
  br i1 %c1, label %p1, label %j1
p1:
  %a1 = call i32 @cq_theta_si32(i32 0, double %t1)
  br label %j1
j1:
  %r1 = phi i32 [ %a1, %p1 ], [ %r0, %0 ]
  %c2 = icmp slt i32 %x, %k2
  br i1 %c2, label %p2, label %j2
p2:
  %a2 = call i32 @cq_theta_si32(i32 0, double %t2)
  br label %j2
j2:
  %r2 = phi i32 [ %a2, %p2 ], [ %r1, %j1 ]
  %c3 = icmp eq i32 %x, %k3
  br i1 %c3, label %p3, label %j3
p3:
  %a3 = call i32 @cq_theta_si32(i32 0, double %t3)
  br label %j3
j3:
  %r3 = phi i32 [ %a3, %p3 ], [ %r2, %j2 ]
  %m = call i32 @cq_measure_si32(i32 %r3)
  ret i32 %m
}
