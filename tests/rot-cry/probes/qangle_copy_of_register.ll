; rot-cry probes (cq-r9j0, rules 10 and 15): the cq-6qum pre-rotation copy with a QUANTUM angle. y = r
; copies a prepared register's merge %8 and rotates it uncontrolled by the angle rail 0.1 * x, while r
; (%8) is still read after the rotation and a second prep with a disjoint predicate re-prepares r. The
; ry_qangle hits a copy of the register (y's rail); the register keeps r's value, and the second prep's
; xorc and Ry land on the register, never on y's rail (as the classical-angle w3 in
; rule2_copy_of_register.ll).
; int f(double a, double b){ int x=0; cq_theta(&x,1.0); int r = 0;
;   if (x == 1) { r = 7; cq_theta(&r, a); }
;   int y = r; cq_theta(&y, 0.1 * (double)x);
;   if (x != 1) { r = 5; cq_theta(&r, b); }
;   return r * 3 + y; }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32 noundef, double noundef)

; CHECK f: call void @cqrt_xorc_i32_controlled(i32 %{{f}}, i32 %[[R]], i32 7)
; CHECK f: call void @cqrt_ry_i32_controlled(i32 %{{f}}, i32 %[[R]], double %0)
; CHECK f: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[Y]])
; CHECK f: call void @cqrt_ry_i32_qangle(i32 %[[Y]], i32 %{{a}})
; CHECK f: call void @cqrt_xorc_i32_controlled(i32 %{{g}}, i32 %[[R]], i32 5)
; CHECK f: call void @cqrt_ry_i32_controlled(i32 %{{g}}, i32 %[[R]], double %1)
; CHECK-COUNT f: @cqrt_ry_i32_qangle( 1
; CHECK-COUNT f: call void @cqrt_xorc_i32_controlled( 2
; CHECK-COUNT f: call void @cqrt_ry_i32_controlled( 2
define i32 @f(double noundef %0, double noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00)
  %4 = icmp eq i32 %3, 1
  br i1 %4, label %5, label %7

5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef %0)
  br label %7

7:
  %8 = phi i32 [ %6, %5 ], [ 0, %2 ]
  %9 = sitofp i32 %3 to double
  %10 = fmul double %9, 1.000000e-01
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef %10)
  br i1 %4, label %14, label %12

12:
  %13 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef %1)
  br label %14

14:
  %15 = phi i32 [ %13, %12 ], [ %8, %7 ]
  %16 = mul nsw i32 %15, 3
  %17 = add nsw i32 %16, %11
  ret i32 %17
}
