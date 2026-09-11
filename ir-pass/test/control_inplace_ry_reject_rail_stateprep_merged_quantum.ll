; control_inplace_ry_reject_rail_stateprep_merged_quantum.ll — DECLINE at F1's
; SECOND clause: an in-place Ry on the CONDITION'S OWN REGISTER, as `clang -O1`
; actually hands it to the pass (probe `t6`).
;
;     _Bool b = cq_theta(b, 0.5);
;     if (b) { b = cq_theta(b, 0.9); }
;
; ⚠ THE FENCE THAT FIRES IS NOT R4, AND SCOPING THE CLOBBER DECLINE ONTO R4
; WOULD HAVE PINNED NOTHING (SCOPE §0 measurement 4). On the arm edge `-O1`
; PROVES `b == true` and const-folds the arm's `cq_theta(b, .9)` to
; `cq_theta_i1(i1 true, .9)` — so the shape arriving here is a STATE PREP, for
; which R4 and R6 are SKIPPED outright (`if (!StatePrep)`). What refuses it is
; F1's second clause: the merge's Pred-edge incoming is the TAINTED rail `%1`,
; i.e. a NO-CLONING MUX between a freshly prepared rail and a LIVE QUANTUM
; REGISTER (Rule 8), not a faithful merge.
;
; Verified against the COMPARE twin (probe `t6c`), which declines with the
; identical string on `main` — so this is an inherited fence reached through a
; new gate, not a new one.;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate, so neither binary
; can witness this fence at all. The string below is reachable only because
; l4x4.b widened that gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative a
; decline fixture could carry is VACUOUS — `2>&1 | FileCheck` sees the diagnostic
; and nothing else. What pins "no silent lowering" is the `not` INVERSION on the
; RUN line above (the pass must exit non-zero) plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: state prep merged with a quantum register under quantum control

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t6_ry_on_cond_wire.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t6_ry_on_cond_wire.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %1, label %2, label %4

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 9.000000e-01) #2
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ %1, %0 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %7 = zext i1 %6 to i32
  ret i32 %7
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %1, label %2, label %4

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 9.000000e-01) #2
  br label %4

4:                                                ; preds = %0, %2
  %5 = phi i1 [ %3, %2 ], [ %1, %0 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
