; control_classical_call_arm_twin_accept_inner_param_range.ll — ACCEPT (bd dm7f.25; was
; control_classical_call_arm_twin_reject_inner_param_range.ll, a DECLINE since bd
; dm7f.21).
; The neighbour of control_classical_call_arm_twin_accept_nsw_inner_noundef.ll: the
; same clang -O1 module with ONE hand edit, `@g`'s parameter also carries
; `range(i32 0, 100)`.
;
; A `freeze` yields SOME defined value; it cannot promise one inside `[0, 100)`, and
; a defined value outside the range is poison in a `noundef` parameter: immediate
; UB. So the call `@g(freeze(x + 1))` in `@f`'s twin would still be UB on states the
; guard excluded. dm7f.25: the call is REDIRECTED to `@g`'s own twin, whose
; parameter DROPS the `range` (as does the redirected call site). Dropping a
; constraint never makes a defined value poison, and the twin re-verifies its body
; without it: `@g`'s `nsw` flags, which `range` proved, are no longer proven, so
; `@g`'s twin freezes its `ret`.
; ANALYTIC (R2): on a basis state where the source runs `f(k)` without UB, `k + 1`
; is defined and inside `[0, 100)` (a violation is UB in the source), so both
; argument freezes are the identity, the dropped `range` held, and the twins return
; `f(k)`; elsewhere a defined value the controlled copy never merges.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=ORIG %s < %t.ll
;
; ORIG-LABEL: define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef range(i32 0, 100) %0)
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK-NOT:   call i32 @f(
; CHECK:       define internal i32 @__cq_specsafe_g(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TG:[0-9]+]] {
; CHECK-NEXT:    %2 = mul nsw i32 %0, 3
; CHECK-NEXT:    %3 = add nsw i32 %2, 1
; CHECK-NEXT:    %.fr = freeze i32 %3
; CHECK-NEXT:    ret i32 %.fr
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TF:[0-9]+]] {
; CHECK-NEXT:    %2 = add nsw i32 %0, 1
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @__cq_specsafe_g(i32 noundef %.fr)
; CHECK-NEXT:    %.fr1 = freeze i32 %3
; CHECK-NEXT:    ret i32 %.fr1
; CHECK-DAG:   ![[TG]] = !{ptr @g}
; CHECK-DAG:   ![[TF]] = !{ptr @f}

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef range(i32 0, 100) %0) local_unnamed_addr #0 {
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
