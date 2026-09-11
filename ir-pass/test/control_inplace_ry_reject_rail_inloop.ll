; control_inplace_ry_reject_rail_inloop.ll — DECLINE, AND IT IS AN INCREMENT
; BOUNDARY RATHER THAN A FENCE: the in-place controlled-Ry arm on a bare `_Bool`
; condition INSIDE a classically-bounded loop, with `b` loop-INVARIANT and `r`
; loop-CARRIED (probe `t5`). Carved out as bd `test_C_libtooling-l4x4`
; sub-increment **l4x4.c**.
;
; IT IS NOT REFUSED FOR ANY REASON INTRINSIC TO THE SHAPE. It reaches
; `classifyArms` — `ControlDetect::flatRegionRollableInLoop` has already proved
; the CFG half — and R7's (b)/(b′) clauses would carry unchanged, since both are
; questions about the ROTATED register and neither mentions the condition. Two
; things are missing, and both are about VERIFICATION rather than lowering:
;
;   * THERE IS NO ORACLE TWIN. The COMPARE spelling of this program declines
;     `condition predates a non-diagonal gate` (probe `t5c`, MEASURED on `main`):
;     `-O1` LICM-hoists the invariant compare out of the loop and
;     `condWireDisposition`'s P4 prong refuses a cross-block condition, while
;     `railCondWireDisposition` deliberately has NO P4 prong. So the rail form is
;     a capability the compare form structurally cannot express, and the usual
;     rolled-vs-hand-unrolled `compare_files` gate would have nothing to compare
;     against but itself.
;   * IT IS THE C-1 MIXTURE. A loop-INVARIANT condition register beside a
;     loop-CARRIED rotated one is exactly the axis that produced EIGHT confirmed
;     silent miscompiles over SIX adversarial rounds in `markIfRailLocal`'s
;     neighbourhood (`invariantRegisterRoots`, `ClaimedRailRoots`,
;     `InPlaceRailOps`, `InLoopFlattenedPreds`), and STAGE 2b IS STRUCTURALLY
;     BLIND to the leak they share — it reported `0 violation(s)` on every broken
;     circuit in that family.
;
; THE STRING IS THE LOOP ONE, not `bare i1 register condition`: the shape is
; refused for being in a loop, and `ControlDetect`'s in-loop scope fence part 2
; says the same words for the same kind of reason.;
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
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: control flow inside a loop body under quantum control

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t5_inloop_ry_rail.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t5_inloop_ry_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %8

3:                                                ; preds = %13
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %5 = zext i1 %4 to i32
  %6 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %15, %13 ]
  %10 = phi i32 [ %2, %0 ], [ %14, %13 ]
  br i1 %1, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %13

13:                                               ; preds = %8, %11
  %14 = phi i32 [ %12, %11 ], [ %10, %8 ]
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %15, 3
  br i1 %16, label %3, label %8, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %3

3:                                                ; preds = %8, %0
  %4 = phi i32 [ 0, %0 ], [ %10, %8 ]
  %5 = phi i32 [ %2, %0 ], [ %9, %8 ]
  br i1 %1, label %6, label %8

6:                                                ; preds = %3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 9.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %7, %6 ], [ %5, %3 ]
  %10 = add nuw nsw i32 %4, 1
  %11 = icmp eq i32 %10, 3
  br i1 %11, label %12, label %3, !llvm.loop !6

12:                                               ; preds = %8
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
