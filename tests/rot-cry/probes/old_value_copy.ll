; rot-cry probes (cq-sx24): a second prep of a register with predicates disjoint from the first, while
; the register's earlier value (the first prep's merge %12) is still read after it (-O1 sank the
; reader %17 past the second prep). The reader reads a copy taken just before the second prep.
; int between(int x0, double th, int k, int r0, double t1, double t2) {
;   int x = x0; cq_theta(&x, th); int r = r0;
;   if (x > k) { r = 0; cq_theta(&r, t1); }
;   int y = r * 3 + 1; int z = (y > 5);
;   if (x <= k) { r = 1; cq_theta(&r, t2); }
;   return cq_measure(r) + cq_measure(x) + cq_measure(z); }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; CHECK-COUNT between: call i32 @cqrt_alloc_i32(i32 %3) 1
; CHECK-COUNT between: call i32 @cqrt_alloc_i32(i32 0) 1
; CHECK-COUNT between: call void @cqrt_copy_i32( 1
; CHECK-COUNT between: call void @cqrt_ry_i32_controlled( 2
; CHECK-COUNT between: = fneg double 0
define i32 @between(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %8 = icmp sgt i32 %7, %2
  br i1 %8, label %9, label %11

9:
  %10 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %4)
  br label %11

11:
  %12 = phi i32 [ %10, %9 ], [ %3, %6 ]
  br i1 %8, label %15, label %13

13:
  %14 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef %5)
  br label %15

15:
  %16 = phi i32 [ %14, %13 ], [ %12, %11 ]
  %17 = icmp sgt i32 %12, 1
  %18 = zext i1 %17 to i32
  %19 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %20 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %21 = add nsw i32 %20, %19
  %22 = tail call i32 @cq_measure_si32(i32 noundef %18)
  %23 = add nsw i32 %21, %22
  ret i32 %23
}
