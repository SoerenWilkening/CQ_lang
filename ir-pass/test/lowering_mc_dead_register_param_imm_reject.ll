; lowering_mc_dead_register_param_imm_reject.ll — DECLINE, loud (bd
; test_C_libtooling-dm7f.83; ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16).
; `int t = q + m; cq_theta(&t, .2)` with `q` a dead rotated register and `m` a
; function PARAMETER. The classical-immediate M-C round refuses the in-place
; `cqrt_addc` at G4 (`inPlaceFenceHolds`: stage 2b cannot vouch for a formal-
; parameter immediate), so `q`'s old rail would stand beside the kept `t` — the
; r2j3.33 wrong unitary. WAS (main ef72239c): accepted with only the warning
; `non-diagonal gate over a live derived record`. NOW: any in-place-fence refusal
; on a DEAD USER REGISTER beside a kept result is LOUD
; (owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1), asked by the in-place round
; (InPlaceQQImm.cpp), no "only if later rotated" carve-out.
; THE TWIN CELL (recorded per the ruling): INLINED `t = q + m` -> LOUD (here);
; LIFTED `t = h(q, m)`, `h(a,k) = a + k` -> ACCEPT in place
; (spec_accept_consume_param_imm.ll: the consuming clone's body applies
; `cqrt_addc_i32(t, k)` with `k` a parameter the clone's handle mask proves
; classical). RETIREMENT TRIGGER (bd dm7f.83 follow-up): when stage 2b vouches for
; a classical parameter immediate on positive pass-emitted evidence and G4 is
; dropped, this fixture becomes the in-place accept and the cell closes.
;
; Source: n1.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
source_filename = "n1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = add nsw i32 %2, %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #2 {
  %3 = add nsw i32 %0, 4
  %4 = tail call i32 @slice(i32 noundef %3)
  ret i32 0
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
