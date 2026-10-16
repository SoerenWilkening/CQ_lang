; spec_reject_tail_hoist_self_dependent.ll — DECLINE, loud (bd
; test_C_libtooling-r2j3.37): a lifted `f(t,a) = t ^ (t + a)` with `t` DEAD after
; the call. The hoisted chain is `t ^ s`, `s = f__cqsrc0(t, a)` = t + a: the
; source of the in-place xor depends on the dead register's old value, which has
; no clean in-place form. The in-place round refuses it LOUDLY exactly as for the
; inlined `r = t ^ (t + a)` (ruling-dm7f51-step1-departures-2026-10-15 Q2,
; `dependsOnTarget` walking through the source call's operands). WAS (main
; ef72239c): accepted out of place inside the clone, the old `t` rail left beside
; `r` (rc 0). Retire when the self-dependent permutation circuit exists (the dm7f
; gap issue the ruling filed).
;
; Source: f3.c (lane L scratch), clang-19 -O1 -include CQ.h.
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
; HOIST-CMD: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; HOIST: error: {{.*}}cq in-place lowering: the source of a quantum reassignment depends on the dead register's old value
source_filename = "f3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i8 @f(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = add i8 %1, %0
  %4 = xor i8 %3, %0
  ret i8 %4
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 511) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 4.000000e-01) #3
  %3 = tail call zeroext i8 @f(i8 noundef zeroext %2, i8 noundef zeroext %1)
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 0x3FE6666666666666) #3
  %5 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %4) #4
  %6 = zext i8 %5 to i32
  %7 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3) #4
  %8 = zext i8 %7 to i32
  %9 = add nuw nsw i32 %8, %6
  ret i32 %9
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

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
