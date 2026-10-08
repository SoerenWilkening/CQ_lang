; control_classical_call_arm_twin_accept_root_freeze.ll — ACCEPT (bd dm7f.21).
; The ROOT argument needs bd 9hea's freeze AND the callee needs its speculation-safe
; twin; the two compose. IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int g(int v) { return v * 3 + 1; }
;   __attribute__((noinline)) int f(int x) { return g(x + 1); }
;   int ex(int k) { int a = k + 1; int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = f(a); return cq_measure(y) + a; }
; target attributes trimmed (R8). (`a` is used on both paths, so clang computes the
; `add nsw` in the predecessor; written as `f(k + 1)` the add stays in the arm and
; the 6.5 arm-shape gate declines, a separate pre-existing gap.)
;
; `%2 = add nsw %0, 1` is poison for k = INT_MAX and is passed to `@f`'s `noundef`
; parameter: the hoisted call freezes it first (bd 9hea, `hoistedArgPoisonIsUB`,
; asked before the move), unchanged. Inside `@f` the second `add nsw` reaches `@g`'s
; `noundef` parameter, so the hoist calls `@__cq_specsafe_f`, whose sink is frozen.
; ANALYTIC (R2): for k < INT_MAX - 1 neither add overflows, both freezes are the
; identity and the hoisted value is `f(k + 1)`; otherwise the source's own call is
; UB under a true guard, and the value is never merged under a false one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %2 = add nsw i32 %0, 1
; CHECK:       %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %2
; CHECK-NEXT:  %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_f(i32 noundef %[[FR]])
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK-NEXT:    %2 = add nsw i32 %0, 1
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)

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

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = add nsw i32 %0, 1
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @f(i32 noundef %2)
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ %3, %1 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %10 = add nsw i32 %9, %2
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
