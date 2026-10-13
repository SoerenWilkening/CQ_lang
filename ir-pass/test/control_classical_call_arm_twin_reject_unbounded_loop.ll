; control_classical_call_arm_twin_reject_unbounded_loop.ll — DECLINE (batch 053, bd
; dm7f.27 decline neighbour). IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int h(int x){ int n = 0; while (x > 1) { x = (x & 1) ? 3 * x + 1 : x / 2; ++n; } return n; }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes and the `!llvm.loop` attachment trimmed (R8).
; A loop whose trip count ScalarEvolution cannot bound (the exit tests a `select`, not
; an induction variable): the speculation-safe twin has no counter bound to carry, so
; it could run forever on a frozen value the source's guard excluded, and
; `classicalCallHoistRoute` answers Unsafe (TwinTotality.h `loopBounds`). The Direct
; route needs `willreturn`, which C does not give `@h`. The 6.5 arm declines loudly.
; HONEST SCOPE: a goal-1 gap, not physics. A programmer-supplied bound (`cq_bound(N)`,
; bd wrwo, not built) or a compiler-proven one would let the twin carry a counter.
; Retire this row when either lands. Accept neighbour:
; control_classical_call_arm_twin_accept_loop_callee.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp sgt i32 %0, 1
  br i1 %2, label %3, label %14

3:                                                ; preds = %1, %3
  %4 = phi i32 [ %12, %3 ], [ 0, %1 ]
  %5 = phi i32 [ %11, %3 ], [ %0, %1 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = mul nuw nsw i32 %5, 3
  %9 = add nuw nsw i32 %8, 1
  %10 = lshr exact i32 %5, 1
  %11 = select i1 %7, i32 %10, i32 %9
  %12 = add nuw nsw i32 %4, 1
  %13 = icmp ugt i32 %11, 1
  br i1 %13, label %3, label %14

14:                                               ; preds = %3, %1
  %15 = phi i32 [ 0, %1 ], [ %12, %3 ]
  ret i32 %15
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

attributes #0 = { nofree noinline norecurse nosync nounwind memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
