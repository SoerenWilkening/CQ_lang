; control_classical_call_arm_twin_reject_inner_param_range.ll — DECLINE (bd dm7f.21).
; The still-unsound neighbour of control_classical_call_arm_twin_accept_nsw_inner_noundef.ll
; (and of the flipped ..._twin_accept_inner_noundef_param_poison.ll /
; ..._twin_accept_intrinsic_callsite_range_narrow.ll): the same clang -O1 module with
; ONE hand edit, `@g`'s parameter also carries `range(i32 0, 100)`.
;
; A `freeze` yields SOME defined value; it cannot promise one inside `[0, 100)`, and
; a defined value outside the range is poison in a `noundef` parameter: immediate UB.
; So the twin cannot discharge this sink (bd 9hea's whitelist reasoning, one call
; deeper), and the poison dataflow refuses any value-constraining parameter attribute
; in the call tree (`paramContractIsInert`). The 6.5 hoist declines loudly.
; HONEST SCOPE: unsound for the freeze mechanism, not for physics. A twin of `@g`
; that DROPS the `range` (dropping a constraint never re-poisons a value) would make
; it lowerable; that is a widening beyond the 2026-10-08 ruling, filed as a dm7f.21
; follow-up. Retire this row when it lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

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
