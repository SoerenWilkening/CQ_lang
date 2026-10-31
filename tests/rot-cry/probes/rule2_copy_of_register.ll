; rot-cry probes (cq-6qum): rule 2 (uncontrolled) rotates y = r, a copy of a prepared register's merge
; %15, while r (%15) is still read after the rotation and a second prep with a disjoint predicate
; re-prepares r. The Ry hits a copy of the register (y's rail); the register keeps r's value, and the
; second prep's xorc and Ry land on the register, never on y's rail.
; int w3(int x0, double th, int k, int s, int a, int b, double t1, double t2, double t3) {
;   int x = x0; cq_theta(&x, th); int r = s;
;   if (x > k) { r = a; cq_theta(&r, t1); }
;   int y = r; cq_theta(&y, t2);
;   if (x <= k) { r = b; cq_theta(&r, t3); }
;   return cq_measure(r) + 2 * cq_measure(y) + 4 * cq_measure(x); }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; CHECK w3: %[[R]] = call i32 @cqrt_alloc_i32(i32 %3)
; CHECK w3: %[[Y]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK w3: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[Y]])
; CHECK w3: call void @cqrt_ry_i32(i32 %[[Y]], double %7)
; CHECK w3: call void @cqrt_ry_i32_controlled(i32 %{{f}}, i32 %[[R]], double %8)
; CHECK-COUNT w3: call void @cqrt_copy_i32( 1
; CHECK-COUNT w3: call void @cqrt_xorc_i32_controlled( 2
; CHECK-COUNT w3: call void @cqrt_ry_i32_controlled( 2
define i32 @w3(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, double noundef %6, double noundef %7, double noundef %8) local_unnamed_addr #0 {
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %11 = icmp sgt i32 %10, %2
  br i1 %11, label %12, label %14

12:                                               ; preds = %9
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %6) #2
  br label %14

14:                                               ; preds = %12, %9
  %15 = phi i32 [ %13, %12 ], [ %3, %9 ]
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef %7) #2
  br i1 %11, label %19, label %17

17:                                               ; preds = %14
  %18 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %8) #2
  br label %19

19:                                               ; preds = %17, %14
  %20 = phi i32 [ %18, %17 ], [ %15, %14 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %23 = shl nsw i32 %22, 1
  %24 = add nsw i32 %23, %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %26 = shl nsw i32 %25, 2
  %27 = add nsw i32 %24, %26
  ret i32 %27
}
