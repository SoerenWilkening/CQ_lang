; control_classical_call_arm_twin_accept_loop_callee.ll — ACCEPT (bd dm7f.27; was
; control_classical_call_arm_twin_reject_loop_callee.ll, a DECLINE since bd dm7f.21).
; The real-C counted-loop callee. IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(int x){ int s = 1; for (int i = 0; i < x; ++i) s = s * 3 + (s >> 2); return g(s); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes and the `!llvm.loop` attachment trimmed (R8). C gives `@h` no
; `mustprogress`, so FunctionAttrs infers no `willreturn` for the loop and the old
; 6.5 purity gate declined; the strict body walk then refused the CFG cycle and the
; twin refused cyclic bodies. Batch 053: the claim keeps memory(none) + nounwind and
; asks `classicalCallHoistRoute`, whose Twin route stands in for `willreturn` with a
; twin that terminates by construction, within ScalarEvolution's constant max trip
; count (TwinTotality.h; a diverging input runs to that bound, accepted by owner
; ruling owner-ruling-twin-divergence-bounded-2026-10-13).
;
; THE TWIN. ScalarEvolution bounds the loop's backedge-taken count (exit
; `{1,+,1} == x`, guarded by `x > 0`), and the twin's header carries a counter
; `%cq.trip` that leaves to `ret i32 0` once it exceeds that bound. The `nsw`
; accumulator reaching `@g`'s `noundef` parameter is frozen, and so are both branch
; conditions (`%0` may be any frozen value in the twin).
; ANALYTIC (R2): on a basis state where the source runs `h(k)` without UB, every
; frozen operand is defined (a `noundef` argument and a branch condition are sinks),
; so each `freeze` is the identity; ScalarEvolution's bound holds on every UB-free
; execution (its facts are modulo poison and UB), so `%cq.trip` never exceeds it and
; `cq.trip.exit` is never taken: the twin returns `h(k)`. On a state the guard
; excluded (Ry(0): all of them) the twin runs at most bound+2 header visits per
; entry and returns some defined value the controlled copy never merges.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=ORIG %s < %t.ll
;
; ORIG-LABEL: define noundef i32 @h(i32 noundef %0)
; ORIG-NEXT:    %2 = icmp sgt i32 %0, 0
; ORIG-NEXT:    br i1 %2, label %6, label %3
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NOT:   call i32 @h(
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R]])
; CHECK:       define internal noundef i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %2 = icmp sgt i32 %0, 0
; CHECK-NEXT:    %.fr = freeze i1 %2
; CHECK-NEXT:    br i1 %.fr, label %6, label %3
; CHECK:       3:
; CHECK-NEXT:    %4 = phi i32 [ 1, %1 ], [ %11, %cq.trip.body ]
; CHECK-NEXT:    %.fr2 = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @g(i32 noundef %.fr2)
; CHECK-NEXT:    ret i32 %5
; CHECK:       6:
; CHECK-NEXT:    %cq.trip = phi i64 [ 0, %1 ], [ %cq.trip.next, %cq.trip.body ]
; CHECK-NEXT:    %7 = phi i32 [ %12, %cq.trip.body ], [ 0, %1 ]
; CHECK-NEXT:    %8 = phi i32 [ %11, %cq.trip.body ], [ 1, %1 ]
; CHECK-NEXT:    %cq.trip.next = add i64 %cq.trip, 1
; CHECK-NEXT:    %cq.trip.over = icmp ugt i64 %cq.trip, 2147483646
; CHECK-NEXT:    br i1 %cq.trip.over, label %cq.trip.exit, label %cq.trip.body
; CHECK:       cq.trip.body:
; CHECK-NEXT:    %9 = mul nsw i32 %8, 3
; CHECK-NEXT:    %10 = ashr i32 %8, 2
; CHECK-NEXT:    %11 = add nsw i32 %9, %10
; CHECK-NEXT:    %12 = add nuw nsw i32 %7, 1
; CHECK-NEXT:    %13 = icmp eq i32 %12, %0
; CHECK-NEXT:    %.fr1 = freeze i1 %13
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
attributes #1 = { nofree noinline norecurse nosync nounwind memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
