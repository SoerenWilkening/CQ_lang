; cq-bdf3: CR rule 6's escape is "a call argument the callee KEEPS". A clone whose callee has no effect
; (no store, rotation, phase, measurement or host call) and reads the formal only into fresh rails keeps
; nothing: the call is a reader, x is cleaned from x + 1 after it (unc-h2 p21). @storing_clone: the callee
; stores its formal into a global: an escape, x is kept.
; CHECK-COUNT pure_clone: call void @cqrt_copy_i32( 1
; CHECK-COUNT storing_clone: call void @cqrt_copy_i32( 0
;
; C: static __attribute__((noinline)) int sq(int v) { return v * v; }
; C: int g_kept;
; C: static __attribute__((noinline)) int keep(int v) { g_kept = v; return v + 1; }
; C: int pure_clone(int x0, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int r = cq_measure(sq(x));
; C:     x = x + 1;
; C:     cq_theta(&x, th);
; C:     return r ^ cq_measure(x);
; C: }
; C: int storing_clone(int x0, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int r = cq_measure(keep(x));
; C:     x = x + 1;
; C:     cq_theta(&x, th);
; C:     return r ^ cq_measure(x);
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g_kept = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @pure_clone(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = tail call fastcc i32 @sq(i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = add nsw i32 %3, 1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %1)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = xor i32 %8, %5
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @sq(i32 noundef %0) unnamed_addr {
  %2 = mul nsw i32 %0, %0
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @storing_clone(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = tail call fastcc i32 @keep(i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = add nsw i32 %3, 1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %1)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = xor i32 %8, %5
  ret i32 %9
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @keep(i32 noundef %0) unnamed_addr {
  store i32 %0, ptr @g_kept, align 4
  %2 = add nsw i32 %0, 1
  ret i32 %2
}



