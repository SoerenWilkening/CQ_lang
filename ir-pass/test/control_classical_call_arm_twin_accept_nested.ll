; control_classical_call_arm_twin_accept_nested.ll — ACCEPT (bd dm7f.21).
; A twin's own inner call is twinned recursively, and a twin is cached per callee.
; IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int g(int v) { return v * 3 + 1; }
;   __attribute__((noinline)) int f(int x) { return g(x + 1); }
;   __attribute__((noinline)) int e(int x) { return f(x) ^ 7; }
;   int ex(int k)  { int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = e(k); return cq_measure(y); }
;   int ex2(int k) { int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = f(k); return cq_measure(y); }
; target attributes trimmed (R8).
;
; `@e` itself has no sink that sees poison, but its call to `@f` does (the `add nsw`
; reaches `@g`'s `noundef` parameter), so `@e`'s twin calls `@f`'s twin. The twin
; analysis assumes every parameter possibly poison (one twin serves every caller), so
; `@__cq_specsafe_e` also freezes its argument to `@f`'s `noundef` parameter: the
; identity on any defined argument. `ex2` hoists `f(k)` directly and REUSES the twin
; `@__cq_specsafe_f` built for `@e` (found by its `!cq.specsafe.twin` attachment):
; exactly one definition. ANALYTIC (R2) as in
; control_classical_call_arm_twin_accept_nsw_inner_noundef.ll, once per level: every
; freeze is the identity on a UB-free execution of the source's call.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=ONE %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_e(i32 noundef %0)
; CHECK-LABEL: define i32 @ex2(
; CHECK:       tail call i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %0) unnamed_addr #0 !cq.specsafe.twin ![[TF:[0-9]+]] {
; CHECK-NEXT:    %2 = add nsw i32 %0, 1
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)
; CHECK:       define internal i32 @__cq_specsafe_e(i32 noundef %0) unnamed_addr #0 !cq.specsafe.twin ![[TE:[0-9]+]] {
; CHECK-NEXT:    %.fr = freeze i32 %0
; CHECK-NEXT:    %2 = tail call i32 @__cq_specsafe_f(i32 noundef %.fr)
; CHECK:       ![[TF]] = !{ptr @f}
; CHECK:       ![[TE]] = !{ptr @e}
;
; ONE-COUNT-1: define internal i32 @__cq_specsafe_f(
; ONE-NOT:     define internal i32 @__cq_specsafe_f

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 1
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f(i32 noundef %0)
  %3 = xor i32 %2, 7
  ret i32 %3
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @e(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @ex2(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @f(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
