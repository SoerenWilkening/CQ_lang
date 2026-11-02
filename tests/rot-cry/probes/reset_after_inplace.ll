; rot-cry probes (cq-2xi3): a prep, then an in-place rotation of the prepared register in a nested
; arm, while a sibling arm resets the variable to the straight-through value (r = s). The merge's
; edge from that arm carries s where the prep fired, so it is not the register: cq::unimplemented
; with the incoming printed (the in-place rotation must not forget the prep's predicate).
; int p19(int x0, double th, int k1, int k2, int k3, int s, int a, double t1, double t2) {
;   int x = x0; cq_theta(&x, th); int r = s;
;   if (x > k1) { r = a; cq_theta(&r, t1);
;     if (x < k2) cq_theta(&r, t2); else if (x == k3) { r = s; cq_phi(t2); } }
;   return cq_measure(r) * 2 + 100 * cq_measure(x); }
; cq-a63l (CR rule 10, cq-oa67): a straight-through edge an in-place rotation of the register may precede:
; the arms merge by rule 9 over the handles (a select chain), the register itself is not the merge.
; CHECK p19: call i32 @cq_template_select_
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @p19(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, double noundef %7, double noundef %8) {
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %11 = icmp sgt i32 %10, %2
  br i1 %11, label %12, label %20

12:
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %7)
  %14 = icmp slt i32 %10, %3
  br i1 %14, label %15, label %17

15:
  %16 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef %8)
  br label %20

17:
  %18 = icmp eq i32 %10, %4
  br i1 %18, label %19, label %20

19:
  tail call void @cq_phi(double noundef %8)
  br label %20

20:
  %21 = phi i32 [ %16, %15 ], [ %5, %19 ], [ %13, %17 ], [ %5, %9 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21)
  %23 = shl nsw i32 %22, 1
  %24 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %25 = mul nsw i32 %24, 100
  %26 = add nsw i32 %25, %23
  ret i32 %26
}
