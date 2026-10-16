; spec_accept_consume_merged_target.ll — ACCEPT, in place (bd
; test_C_libtooling-r2j3.37.2; R11 r1 rL1C-F3, E2 asked once). `if (c) t ^= b;
; r = f(t, a);` with `c` QUANTUM and `t` dead after the call. The merge lowers
; `t ^= b` onto `t`'s own rail (controlled copies + cnot), so at the late round the
; call's operand is user data and dead: consumed, cnot(a, t). E2 is asked only
; there (`qqTargetIsUserData`); the specialize-time lineage that used to pre-judge
; it is gone. Analytic replay (lane L) equals the textbook Toffoli(c,b->t);
; cnot(a->t) circuit on all 16 outcomes.
;
; Source: q5.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK:      call void @__cq_q_f_11_c0(i32 [[T:%[a-z0-9]+]], i32 [[A:%[a-z0-9]+]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[A]], double 0x3FE6666666666666)
source_filename = "q5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 16) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #3
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #3
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #3
  %5 = select i1 %1, i1 %3, i1 false
  %6 = xor i1 %4, %5
  %7 = tail call zeroext i1 @f(i1 noundef zeroext %6, i1 noundef zeroext %2)
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 0x3FE6666666666666) #3
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #4
  %10 = zext i1 %9 to i32
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #4
  %12 = select i1 %11, i32 2, i32 0
  %13 = or disjoint i32 %12, %10
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #4
  %15 = select i1 %14, i32 4, i32 0
  %16 = or disjoint i32 %13, %15
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #4
  %18 = select i1 %17, i32 8, i32 0
  %19 = or disjoint i32 %16, %18
  ret i32 %19
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
