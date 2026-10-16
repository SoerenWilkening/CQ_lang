; lowering_stale_speccall_tail_hoist_reject.ll — DECLINE, loud (bd
; test_C_libtooling-r2j3.37; the dead twin of
; lowering_stale_speccall_independent_gates_placed_accept.ll). `r = f(q, p)` with
; `f(x,y) = x*3 + y` reads `q` after `cq_theta(&q2, .3)` rotated its wire (a stale
; read, bd r2j3.6) and leaves `p` DEAD. The call's add chain is hoisted to the
; caller (`r = s + p`, `s = f__cqsrc0(q, p)` = 3q): in place on `p`, the source
; temporary `s` records the OLD `q` and must be uncomputed after the gate that
; rotated `q`, which the stale-reader fence refuses loudly, as it does for the
; inlined `r = q*3 + p`. WAS (main ef72239c): accepted, the lifted call placed
; before the gate and `p`'s old rail left beside `r`. Retire when the hoisted
; group (source, chain, discharge) is placed before the gate as one unit.
;
; Source: f6.c (lane L scratch), clang-19 -O1 -include CQ.h.
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
; HOIST: error: {{.*}}cq opcode lowering: operand predates a non-diagonal gate
source_filename = "f6.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  %5 = tail call i32 @f(i32 noundef %1, i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %8 = add nsw i32 %7, %6
  ret i32 %8
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
