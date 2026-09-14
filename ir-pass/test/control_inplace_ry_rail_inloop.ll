; control_inplace_ry_rail_inloop.ll — ACCEPT: the in-place controlled-Ry arm on a
; bare `_Bool` condition INSIDE a classically-bounded loop, with `b` loop-INVARIANT
; and `r` loop-CARRIED (probe `t5`), lowered ROLLED.
;
;     bool b = cq_theta(0, .5); int r = cq_theta(7, .25);
;     for (i < 3) if (b) r = cq_theta(r, .9);
;
; ⚠ THIS FILE SHIPPED AS A DECLINE UNTIL 2026-09-14 (bd `test_C_libtooling-wx8g`,
; l4x4.c) and is REWRITTEN IN FULL rather than edited, in the same style as
; `control_inplace_ry_inloop_diamond.ll` when Inc 3 flipped it. It was NOT a
; fence: l4x4.b's own comment said "IT IS NOT REFUSED FOR ANY REASON INTRINSIC TO
; THE SHAPE … R7's (b)/(b′) clauses would carry unchanged", and the carve-out was
; an increment boundary resting on two VERIFICATION claims. Both are now measured
; false, and this file is where that is recorded:
;
;   * "THERE IS NO ORACLE TWIN" — true of the COMPARE twin (probe `t5c`, which
;     declines `condition predates a non-diagonal gate` because `-O1` LICM-hoists
;     a loop-invariant compare and P4 refuses a cross-block condition; re-measured
;     on the 2026-09-14 ORACLE and STILL TRUE, row W is not fixed) and IRRELEVANT.
;     The in-loop witness discipline in this tree is ROLLED versus HAND-UNROLLED,
;     never rolled-versus-compare, and the hand-unrolled `_Bool` twin is l4x4.b's
;     own flat capability. MEASURED: the C form of this module and its unrolled
;     twin are BYTE-IDENTICAL at 8 trace lines
;     (tests/e2e/slice_control_inplace_ry_bool_loop{,_unrolled}.expected.log,
;     ctest `e2e-inplace-ry-bool-loop-twin-identical`).
;   * "IT IS THE C-1 MIXTURE" — the loop-INVARIANT condition beside a
;     loop-CARRIED register, whose leak signature is a per-trip CONDITION CHAIN
;     the rolled form never discharges. TRUE of a compare or derived condition and
;     VACUOUS for a rail: A BARE `_Bool` CONDITION MINTS NOTHING AND DERIVES
;     NOTHING. The stream below is the proof — one `cqrt_ry_i32_controlled` per
;     activation and nothing else; no flag mint, no `cq_template_*`, no `cqrt_x`,
;     no `cqrt_free` anywhere in the module.
;
; ⚠ AND THE COST THAT IS NOW PAID: `CLAUDE.md` recorded this over-decline's cost
; as TOTAL — *"Grover as a rolled loop with a bool-controlled rotation or prep
; compiles in NO spelling on ANY binary."* The e2e slice
; `slice_control_inplace_ry_bool_loop_grover.c` is that sentence's program.
;
; WHAT MUST BE IN THE OUTPUT: exactly ONE `cqrt_ry_i32_controlled(%h, %h1, .9)`
; per function, INSIDE the surviving loop block, with `%h` (the user's `_Bool`)
; as the CONTROL — read only, never bracketed, never freed (`Ry(θ)|0> != |0>`,
; Rule 6) — and `%h1` (the carried register) as the target, FROZEN by Increment
; 1's structural freeze. Both registers are left ALLOCATED; that is the required
; direction, not a shortfall, and it is identical in the hand-unrolled twin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: %h1 = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
; The loop SURVIVES (rolled, one copy of the body) and the region is flattened
; into it. The controlled Ry is the ONLY gate in the body:
; CHECK: phi i32 [ 0, %0 ], [
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 9.000000e-01)
; CHECK-NEXT: add nuw nsw i32
;
; ⚠ THE COUNTS LIVE IN THEIR OWN WHOLE-FILE PREFIX, never inline among the
; positives and never inside a negative prefix — a positive `CHECK-COUNT` placed
; in a negative prefix WINDOWS every negative after it (CLAUDE.md Rule 12
; hygiene defect (a), which was caught by 0 of 20 blocks the one time it shipped).
; Two functions in this module, one gate each:
; COUNT-COUNT-2: call void @cqrt_ry_i32_controlled(
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
;
; ⚠ A PURE NEGATIVE PREFIX. A rail condition mints NOTHING, so none of these
; symbols may appear anywhere in the module — not a flag, not a strip, not a
; bracket, not a free, and not the retired route. Every name below IS defined or
; emitted somewhere in this tree, so none of these is vacuous by absence of the
; symbol from the ABI; they are absent because this lowering does not use them.
; NOMINT-NOT: cq_template_
; NOMINT-NOT: call void @cqrt_x(
; NOMINT-NOT: call void @cqrt_free(
; NOMINT-NOT: call void @cqrt_cswap(
; NOMINT-NOT: call void @cqrt_cnot(
; NOMINT-NOT: @cq_theta_
;
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
