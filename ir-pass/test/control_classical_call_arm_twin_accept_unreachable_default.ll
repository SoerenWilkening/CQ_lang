; control_classical_call_arm_twin_accept_unreachable_default.ll — ACCEPT (batch 053, R11
; round-1 finding A-F3, bd dm7f.27/.29). IR: clang 19 -O1 of exactly
;   __attribute__((noinline)) int g1(int v){ return v ^ 5; }
;   __attribute__((noinline)) int g2(int v){ return v * 7; }
;   __attribute__((noinline)) int g3(int v){ return v + 11; }
;   __attribute__((noinline)) int h(int x){
;     int s = 1;
;     for (int i = 0; i < x; ++i) {
;       switch (i % 4) {
;       case 0: s = g1(s); break;  case 1: s = g2(s); break;
;       case 2: s = g3(s); break;  case 3: s = g1(s + 1); break;
;       default: break; } }
;     return s; }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes and the `!llvm.loop` attachment trimmed (R8). -O1 proves
; `i % 4` is `i & 3` (i >= 0) and turns the switch default into `unreachable`; the
; totality walk refused that terminator. Fixed: the twin turns each `unreachable`
; into `ret <zero>` (the device of `cq.trip.exit`). The loop gets its trip counter
; and the switch condition, the branch conditions and the `noundef` arguments
; their freezes, as in the loop and branch rows.
; ANALYTIC (R2): reaching `unreachable` is UB in the source, so on a basis state
; where the source runs `h(k)` without UB block `%18` is never reached and the twin
; computes `h(k)`; elsewhere (a frozen switch value outside 0..3 is impossible
; after `and 3` but the twin does not rely on it) it returns some defined value,
; never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NOT:   call i32 @h(
; CHECK:       define internal i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin !{{[0-9]+}} {
; CHECK:         %cq.trip.over = icmp ugt i64 %cq.trip, 2147483646
; CHECK:       cq.trip.body:
; CHECK-NEXT:    %8 = and i32 %6, 3
; CHECK-NEXT:    %[[S:[.a-z0-9]+]] = freeze i32 %8
; CHECK-NEXT:    switch i32 %[[S]], label %18 [
; CHECK:       18:
; CHECK-NEXT:    ret i32 0
; CHECK-NOT:   unreachable
; CHECK:       cq.trip.exit:
; CHECK-NEXT:    ret i32 0

define noundef i32 @g1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define i32 @g2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 7
  ret i32 %2
}

define i32 @g3(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 11
  ret i32 %2
}

define i32 @h(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %5, label %3

3:                                                ; preds = %19, %1
  %4 = phi i32 [ 1, %1 ], [ %20, %19 ]
  ret i32 %4

5:                                                ; preds = %1, %19
  %6 = phi i32 [ %21, %19 ], [ 0, %1 ]
  %7 = phi i32 [ %20, %19 ], [ 1, %1 ]
  %8 = and i32 %6, 3
  switch i32 %8, label %18 [
    i32 0, label %9
    i32 1, label %11
    i32 2, label %13
    i32 3, label %15
  ]

9:                                                ; preds = %5
  %10 = tail call i32 @g1(i32 noundef %7)
  br label %19

11:                                               ; preds = %5
  %12 = tail call i32 @g2(i32 noundef %7)
  br label %19

13:                                               ; preds = %5
  %14 = tail call i32 @g3(i32 noundef %7)
  br label %19

15:                                               ; preds = %5
  %16 = add nsw i32 %7, 1
  %17 = tail call i32 @g1(i32 noundef %16)
  br label %19

18:                                               ; preds = %5
  unreachable

19:                                               ; preds = %9, %11, %13, %15
  %20 = phi i32 [ %17, %15 ], [ %14, %13 ], [ %12, %11 ], [ %10, %9 ]
  %21 = add nuw nsw i32 %6, 1
  %22 = icmp eq i32 %21, %0
  br i1 %22, label %3, label %5
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
