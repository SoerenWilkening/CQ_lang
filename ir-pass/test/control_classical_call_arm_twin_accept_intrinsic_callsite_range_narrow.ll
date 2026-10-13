; control_classical_call_arm_twin_accept_intrinsic_callsite_range_narrow.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_intrinsic_callsite_range_narrow.ll
; (bd bwfp, a DECLINE) by the owner ruling of 2026-10-08 (option a).
; control_classical_call_arm_accept_intrinsic_callsite_range.ll's clang -O1 module with
; the ctpop call site's `range(i32 0, 33)` narrowed to `range(i32 0, 5)`, which its
; semantics do not imply (`intrinsicResultRange` proves only a range containing the
; semantic one). For a popcount above 4 the call yields poison, which reaches `@g`'s
; `noundef` parameter: immediate UB on basis states the guard `q > 3` excluded. The
; hoist now calls `@f`'s speculation-safe twin: the unprovable call-site `range` is
; dropped, the ctpop result still counts as possibly poison (facts read through the
; old `range` no longer hold), so `@g`'s argument is frozen, and the `ret` too.
; ANALYTIC (R2): for popcount(%0) <= 4 the range held, every `freeze` is the identity
; and the twin returns `f(%0)`; otherwise the source's own call passes poison to a
; `noundef` parameter (UB) under a true guard, and the twin's value is never merged
; under a false one. Decline neighbour, still refused:
; control_classical_call_arm_twin_reject_decl_own_noundef_range.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %0)
; CHECK-NEXT:    %2 = tail call i32 @llvm.ctpop.i32(i32 %0)
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)
; CHECK-NEXT:    %.fr1 = freeze i32 %3
; CHECK-NEXT:    ret i32 %.fr1

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
