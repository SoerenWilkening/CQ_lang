; spec_accept_tail_hoist_gate_inline.ll — ACCEPT, in place (bd
; test_C_libtooling-r2j3.37): a lift site the gate-subroutine inliner (bd
; p3kd.21) EXPOSES after the hoist's first slot is hoisted at the later slots.
;   c_phase1  `g(t,a){ cq_phi(.3); return f(t,a); }`: `g` is a gate subroutine,
;             inlined by the first phase; `f(t,a) = t ^ a` is then a lift site
;             in `c_phase1`, hoisted at the SECOND slot (before slot B).
;   c_phase2  `h(t,a){ y = f(t,a); cq_theta(&y,.2); return y; }`: inlined by the
;             CrossCallResults phase (it returns its own register through a lifted
;             result); hoisted at the THIRD slot, after that phase.
; Both: cnot(a, t) in place, no clone. Without the later slots each site reaches
; `specialize()` unhoisted and fails loudly at the late backstop (`cq
; specialization: a lifted call overwrites a dead quantum argument the
; return-chain hoist did not see`, measured before the slots existed).
;
; Source: f7.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; INTERIM (batch 055): the return-chain hoist this fixture was written for
; crosses owner-ruling-lift-classical-only-2026-10-06 / R14 and is DISABLED
; pending the owner's choice ((a) the hoist as a ruled exception, (b) a
; consuming clone, (c) loud until (b); SpecializeTailHoist.h
; `kLiftTailHoistEnabled`). Until then every owed site fails LOUDLY with the
; backstop's diagnostic, pinned below. The hoist expectation is kept verbatim
; under the dormant prefix HOIST (no RUN line reads it). RETIREMENT: under (a)
; restore the HOIST lines as CHECK and the original RUN; under (b) rewrite them
; for the consuming clone; under (c) keep this.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq specialization: a lifted call overwrites a dead quantum argument, which is not lowered in place across the call
;
; HOIST-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; HOIST-CMD: %filecheck %s < %t.ll
; HOIST-CMD: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; HOIST-ERR-NOT: error
;
; HOIST-LABEL: define {{.*}}i32 @c_phase1(
; HOIST:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; HOIST-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; HOIST-NEXT: call void @cqrt_cnot(i32 [[A]], i32 [[T]]), !cq.inplace.qq
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; HOIST-NEXT: call i1 @cqrt_measure_i1(i32 [[A]])
;
; HOIST-LABEL: define {{.*}}i32 @c_phase2(
; HOIST:      [[A:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 5.000000e-01)
; HOIST-NEXT: [[T:%[a-z0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 4.000000e-01)
; HOIST-NEXT: call void @cqrt_cnot(i32 [[A]], i32 [[T]]), !cq.inplace.qq
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[T]], double 2.000000e-01)
; HOIST-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
; HOIST-NOT:  define {{.*}}@__cq_q_
source_filename = "f7.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define noundef zeroext i1 @g(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #1 {
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  %3 = tail call zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1)
  ret i1 %3
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define zeroext i1 @h(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #1 {
  %3 = tail call zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 2.000000e-01) #5
  ret i1 %4
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 4) i32 @c_phase1() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #5
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #5
  %3 = tail call zeroext i1 @g(i1 noundef zeroext %2, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #5
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  ret i32 %9
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define range(i32 0, 4) i32 @c_phase2() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #5
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #5
  %3 = tail call zeroext i1 @h(i1 noundef zeroext %2, i1 noundef zeroext %1)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #5
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 7) i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @c_phase1()
  %2 = tail call i32 @c_phase2()
  %3 = add nuw nsw i32 %2, %1
  ret i32 %3
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
