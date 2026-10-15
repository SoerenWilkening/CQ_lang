; control_classical_call_arm_accept_intrinsic_callsite_range.ll — ACCEPT (bd test_C_libtooling-bwfp).
; R11 round 4 (reviewer pointer, confirmed): LLVM 19 InstCombine stamps a call-site
; `range(i32 0, 33)` on `llvm.ctpop` (also ctlz/cttz). The round-3/4 dataflow treated
; every call-site `range` on an intrinsic as an unproven poison source, so
;   int g(int v){return v*3+1;}   int f(unsigned x){return g(__builtin_popcount(x));}
; declined: the popcount reaches `@g`'s `noundef` parameter. Measured on the round-4
; snapshot (sha 86f1d42c): `control flow under quantum control`, opt rc=1. The range
; is now proven from the intrinsic's semantics on its operand's known bits
; (`intrinsicResultRange`). IR: clang 19.1.7 -O1 of that C, target attributes trimmed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = tail call i32 @f(i32 noundef %0)
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R]])

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %0)
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
