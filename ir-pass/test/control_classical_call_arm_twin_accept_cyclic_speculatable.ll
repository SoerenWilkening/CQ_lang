; control_classical_call_arm_twin_accept_cyclic_speculatable.ll — ACCEPT (bd dm7f.27;
; was control_classical_call_arm_twin_reject_cyclic_speculatable.ll, a DECLINE since
; bd dm7f.21).
; A CYCLIC callee whose `noundef` sink sees poison, the `speculatable` neighbour of
; control_classical_call_arm_twin_accept_loop_callee.ll. IR: clang 19 -O1 of
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(int x){ int s = 1; for (int i = 0; i < x; ++i) s = s * 3 + (s >> 2); return g(s); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; with ONE hand edit: `@h` carries `mustprogress willreturn speculatable`. The
; attribute satisfies the Direct route's totality disjunct, but the `add nsw`
; accumulator still reaches `@g`'s `noundef` parameter, so Direct is refused and the
; Twin route runs: the totality walk ignores `speculatable` on a BODY (R11 round 1,
; H2: it promises nothing about the values a freeze invents) and walks it,
; ScalarEvolution bounds the loop, and the twin carries the trip counter and the
; frozen sinks of the real-C row. The analytic argument is that row's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NOT:   call i32 @h(
; CHECK:       define internal noundef i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK:         %.fr2 = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @g(i32 noundef %.fr2)
; CHECK:         %cq.trip.over = icmp ugt i64 %cq.trip, 2147483646
; CHECK-NEXT:    br i1 %cq.trip.over, label %cq.trip.exit, label %cq.trip.body
; CHECK:         %.fr1 = freeze i1 %13
; CHECK-NEXT:    br i1 %.fr1, label %3, label %6
; CHECK:       cq.trip.exit:
; CHECK-NEXT:    ret i32 0
; CHECK:       ![[TW]] = !{ptr @h}

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %6, label %3

3:                                                ; preds = %6, %1
  %4 = phi i32 [ 1, %1 ], [ %11, %6 ]
  %5 = tail call i32 @g(i32 noundef %4)
  ret i32 %5

6:                                                ; preds = %1, %6
  %7 = phi i32 [ %12, %6 ], [ 0, %1 ]
  %8 = phi i32 [ %11, %6 ], [ 1, %1 ]
  %9 = mul nsw i32 %8, 3
  %10 = ashr i32 %8, 2
  %11 = add nsw i32 %9, %10
  %12 = add nuw nsw i32 %7, 1
  %13 = icmp eq i32 %12, %0
  br i1 %13, label %3, label %6
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #3
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn speculatable memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
