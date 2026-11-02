; cq-5nj9: an update whose value is only an arm of a later quantum merge (125) does not clean its old
; operand itself (its rail is the merge's rule-5 garbage, so that clean-up would be dropped): the merge's
; composite update cleans r (t = c ? r' ^ y : r' - 3). @merge_phi (unc-h1 p8): a three-way phi under a
; phase arm; @merge_select (p8b): the select spelling. Before: r kept in both.
; CHECK-COUNT merge_phi: call void @cqrt_copy_i32( 1
; CHECK merge_phi: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 3)
; CHECK-COUNT merge_select: call void @cqrt_copy_i32( 1
;
; C: int merge_phi(int x0, double th, int r0, double tr, int k, int m, double p) {
; C:   int x = x0; cq_theta(&x, th);
; C:   int r = r0; cq_theta(&r, tr);
; C:   if (x > k) { int y = x * m; r ^= y; if (y > m) cq_phi(p); }
; C:   else { r += 3; }
; C:   return cq_measure(r) + cq_measure(x);
; C: }
; C: int merge_select(int x0, double th, int r0, double tr, int k, int m) {
; C:   int x = x0; cq_theta(&x, th);
; C:   int r = r0; cq_theta(&r, tr);
; C:   if (x > k) { int y = x * m; r ^= y; }
; C:   else { r += 3; }
; C:   return cq_measure(r) + cq_measure(x);
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @merge_phi(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3)
  %10 = icmp sgt i32 %8, %4
  br i1 %10, label %11, label %16

11:                                               ; preds = %7
  %12 = mul nsw i32 %8, %5
  %13 = xor i32 %9, %12
  %14 = icmp sgt i32 %12, %5
  br i1 %14, label %15, label %18

15:                                               ; preds = %11
  tail call void @cq_phi(double noundef %6)
  br label %18

16:                                               ; preds = %7
  %17 = add nsw i32 %9, 3
  br label %18

18:                                               ; preds = %11, %15, %16
  %19 = phi i32 [ %17, %16 ], [ %13, %15 ], [ %13, %11 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19)
  %21 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %22 = add nsw i32 %21, %20
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: nounwind ssp uwtable
define i32 @merge_select(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3)
  %9 = icmp sgt i32 %7, %4
  %10 = mul nsw i32 %7, %5
  %11 = xor i32 %8, %10
  %12 = add nsw i32 %8, 3
  %13 = select i1 %9, i32 %11, i32 %12
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %16 = add nsw i32 %15, %14
  ret i32 %16
}



