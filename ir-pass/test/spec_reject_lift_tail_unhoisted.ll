; spec_reject_lift_tail_unhoisted.ll — DECLINE, loud (bd test_C_libtooling-r2j3.37,
; the reporter's repro; the batch-055 INTERIM). `r = f(t, a)` with
; `f(t,a){ t ^= a; return t; }` and `t` DEAD after the call: a lifted call is a
; Bennett embedding |t>|a>|0> -> |t>|a>|t^a>, so the old `t` rail would stand
; beside `r` and record `a`, and the later Ry on `a` dephases (main ef72239c, rc 0:
; P(a=0, r=0) 0.7960 emitted vs 0.7659 for the program's circuit, independent
; state-vector replay of the `_Bool` twin). Lowering it in place across the call
; is not built (owner question open: the return-chain hoist, a consuming clone, or
; loud; SpecializeTailHoist.h `kLiftTailHoistEnabled`), so the late backstop
; (`declineUnhoistedLiftTails`: the call's chain reaches a tainted argument that is
; dead at the call and a user register's value, and the result survives) fails
; LOUDLY. RETIREMENT: when in place across a call is built, this becomes the
; accept of spec_accept_tail_hoist_inplace.ll's `c_xor`. Twins that must stay
; accepted: spec_accept_tail_hoist_live_arg.ll (live `t`) and
; spec_accept_lift_tail_derived_arg.ll (a derived dead argument).
;
; Source: g1.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq specialization: a lifted call overwrites a dead quantum argument, which is not lowered in place across the call
source_filename = "g1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = xor i32 %1, %0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #3
  %3 = tail call i32 @f(i32 noundef %2, i32 noundef %1)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
