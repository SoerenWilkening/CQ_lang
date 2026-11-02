; cq-5nj9 (unc-h1 p20): a classical merge (a phi over handles) of x itself and its bijective update x + 7:
; x is dead on the updated path only, after the reader x * k's uncompute; that clean-up needs a classical
; branch at its point, not built: an internal error, never a kept dead old value.
; FATAL: rule 6 on a classical merge of a bijective update of a dead register
;
; C: __attribute__((noinline)) static void h(int c) { if (c) __builtin_trap(); }
; C: int f(int x0, double th, int k, int c, double p) {
; C:   int x = x0; cq_theta(&x, th);
; C:   int y = x * k;
; C:   if (c > 1) { x = x + 7; h(c - 9); }
; C:   if (y > 3) cq_phi(p);
; C:   return cq_measure(x);
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %7 = mul nsw i32 %6, %2
  %8 = icmp sgt i32 %3, 1
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = add nsw i32 %6, 7
  %11 = add nsw i32 %3, -9
  tail call fastcc void @h(i32 noundef %11)
  br label %12

12:                                               ; preds = %9, %5
  %13 = phi i32 [ %10, %9 ], [ %6, %5 ]
  %14 = icmp sgt i32 %7, 3
  br i1 %14, label %15, label %16

15:                                               ; preds = %12
  tail call void @cq_phi(double noundef %4)
  br label %16

16:                                               ; preds = %15, %12
  %17 = tail call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

; Function Attrs: noinline nounwind ssp memory(inaccessiblemem: write) uwtable
define internal fastcc void @h(i32 noundef %0) unnamed_addr {
  %2 = icmp eq i32 %0, 0
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  tail call void @llvm.trap()
  unreachable

4:                                                ; preds = %1
  ret void
}

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap()



