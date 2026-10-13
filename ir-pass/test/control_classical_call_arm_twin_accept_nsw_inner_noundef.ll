; control_classical_call_arm_twin_accept_nsw_inner_noundef.ll — ACCEPT (bd dm7f.21).
; Ordinary C that bwfp declined (the goal-1 over-decline dm7f.21 names first):
;   __attribute__((noinline)) int g(int v) { return v * 3 + 1; }
;   __attribute__((noinline)) int f(int x) { return g(x + 1); }
;   int ex(int k) { int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = f(k); return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; The `add nsw` is poison for k = INT_MAX and reaches `@g`'s `noundef` parameter, so
; hoisting `@f` itself would execute immediate UB on basis states the guard excluded
; (Ry(0): all of them). Owner ruling 2026-10-08 (option a): the hoist stays sound and
; hoists `@f`'s SPECULATION-SAFE TWIN `@__cq_specsafe_f`, whose `noundef` sinks are
; frozen. ANALYTIC (R2): on a basis state where the source runs `f(k)` without UB,
; `x + 1` does not overflow, the `freeze` is the identity, and the twin returns
; `f(k)`; on a state where `f(k)` is UB (k = INT_MAX, guard true) the source has no
; defined behaviour to preserve; on a state the guard excluded the twin returns some
; defined value the controlled copy never merges (it is the identity where the flag
; is 0). The `ret` is frozen too (`@g`'s result carries an unproven `range`), so the
; twin's result is defined for any caller. `@f` itself is untouched for its other
; callers. Neighbour: control_classical_call_arm_twin_accept_inner_param_range.ll (the
; same sink also carrying `range`, which no `freeze` satisfies: batch 053 redirects
; the call to `@g`'s twin, which drops it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=ORIG %s < %t.ll
;
; The original keeps its body: the twin is a new function, not a rewrite.
; ORIG-LABEL: define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0)
; ORIG-NEXT:    %2 = add nsw i32 %0, 1
; ORIG-NEXT:    %3 = tail call i32 @g(i32 noundef %2)
; ORIG-NEXT:    ret i32 %3
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK-NOT:   call i32 @f(
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %0) unnamed_addr #0 !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %2 = add nsw i32 %0, 1
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)
; CHECK-NEXT:    %.fr1 = freeze i32 %3
; CHECK-NEXT:    ret i32 %.fr1
; CHECK:       ![[TW]] = !{ptr @f}

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

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
