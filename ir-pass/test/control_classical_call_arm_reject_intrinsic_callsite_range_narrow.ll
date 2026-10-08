; control_classical_call_arm_reject_intrinsic_callsite_range_narrow.ll — DECLINE (bd test_C_libtooling-bwfp).
; The decline twin of control_classical_call_arm_accept_intrinsic_callsite_range.ll:
; the same clang -O1 module with the ctpop call site's `range(i32 0, 33)` narrowed to
; `range(i32 0, 5)`, which its semantics do not imply (ctpop of an unconstrained i32 is
; in [0, 33)). For a popcount above 4 the call yields poison, which reaches `@g`'s
; `noundef` parameter: immediate UB on basis states the guard `q > 3` excluded.
; `intrinsicResultRange` proves only a range that contains the semantic one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call range(i32 0, 5) i32 @llvm.ctpop.i32(i32 %0)
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:
  %5 = tail call i32 @f(i32 noundef %0)
  br label %6

6:
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @llvm.ctpop.i32(i32)
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
