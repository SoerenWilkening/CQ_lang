; control_classical_call_arm_twin_accept_branch_callee.ll — ACCEPT (batch 053, bd dm7f.29).
; An acyclic BRANCHING helper. IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int g2(int v){ return v * 7; }
;   __attribute__((noinline)) int h(int x){ if (x > 10) return g(x + 1); return g2(x - 1); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes trimmed (R8). The two calls keep the branch alive at -O1 (they
; are not `speculatable`). Before batch 053 the strict body walk refused the
; conditional `br` and the arm declined `control flow under quantum control`.
; The `nsw` sums reach the `noundef` parameters of `@g`/`@g2` (x + 1 overflows at
; INT_MAX; the flag proofs see no context, so a dominating `x > 10` proves nothing),
; so the Direct route is refused even past the strict walk. THE TWIN freezes the
; branch condition (a sink), both `noundef` arguments, and the `ret` (`@g2`'s `nsw`
; product may be poison).
; ANALYTIC (R2): on a basis state where the source runs `h(k)` without UB, `x > 10`
; is defined (a branch on poison is UB) and so are both arguments, so every freeze
; but the `ret`'s is the identity, the twin takes the source's edge, and returns
; `h(k)` (a poison result becomes some defined value, a refinement). On a state the
; guard excluded it takes some edge and returns a defined value never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NOT:   call i32 @h(
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; CHECK:       define internal i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %2 = icmp sgt i32 %0, 10
; CHECK-NEXT:    %.fr = freeze i1 %2
; CHECK-NEXT:    br i1 %.fr, label %3, label %6
; CHECK:       3:
; CHECK-NEXT:    %4 = add nuw nsw i32 %0, 1
; CHECK-NEXT:    %.fr2 = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @g(i32 noundef %.fr2)
; CHECK-NEXT:    br label %9
; CHECK:       6:
; CHECK-NEXT:    %7 = add nsw i32 %0, -1
; CHECK-NEXT:    %.fr1 = freeze i32 %7
; CHECK-NEXT:    %8 = tail call i32 @g2(i32 noundef %.fr1)
; CHECK-NEXT:    br label %9
; CHECK:       9:
; CHECK-NEXT:    %10 = phi i32 [ %5, %3 ], [ %8, %6 ]
; CHECK-NEXT:    %.fr3 = freeze i32 %10
; CHECK-NEXT:    ret i32 %.fr3
; CHECK:       ![[TW]] = !{ptr @h}

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define i32 @g2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 7
  ret i32 %2
}

define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp sgt i32 %0, 10
  br i1 %2, label %3, label %6

3:                                                ; preds = %1
  %4 = add nuw nsw i32 %0, 1
  %5 = tail call i32 @g(i32 noundef %4)
  br label %9

6:                                                ; preds = %1
  %7 = add nsw i32 %0, -1
  %8 = tail call i32 @g2(i32 noundef %7)
  br label %9

9:                                                ; preds = %6, %3
  %10 = phi i32 [ %5, %3 ], [ %8, %6 ]
  ret i32 %10
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
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
