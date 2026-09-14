; control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll — DECLINE (bd
; `test_C_libtooling-wx8g`, review round 1 finding F-W1-2): a bare-`_Bool` rail
; region on a LOOP-CARRIED rotated register — granted by R7-loop clause (b'),
; NOT by clause (c) — in a loop whose body mints a per-trip template rail the
; spine never discharges.
;
;     bool b = cq_theta(0,.5); int r = cq_theta(7,.25);
;     for (k<2) { int u = cq_theta(5,.5);
;                 if ((u>>1)&1) r = cq_theta(r,.2);      // derived cond, carried r
;                 if (b)        r = cq_theta(r,.3);      // THE RAIL REGION
;                 s += cq_measure(u + (int)b); }         // the invariant read
;
; ⚠ WHY IT IS A SEPARATE FILE FROM THE CLAUSE-(c) DECLINES. The round-2 re-ask
; was first written at the clause-(c) grant ALONE, on the reading that only an
; iteration-local rail could leak. This module measured that false: it is granted
; by (b'), so it got NO record, NO re-ask and NO conjunct 2, and on the pre-fix
; binary `daeb93a36bdc57b3` it ACCEPTED at 30 trace lines against a hand-unrolled
; twin at 34 — missing one `cq_template_and_i32_hl_unc` and one `cqrt_free` PER
; ACTIVATION. The ORACLE `f7b65d8c…` REFUSED this module outright (the l4x4.b
; in-loop rail carve-out this increment retires), so it is a NEW CUSTOMER on a
; known-defective path, which is CLAUDE.md's `1m5p`/`a3z7` formulation: *"'pre-
; existing' is true of the defect and FALSE of its population."*
;
; THE ROUTE, so the next reader does not have to bisect it: the body READS the
; loop-invariant tainted rail `b` in a non-control position (`u + (int)b`), which
; trips `markIfRailLocal`'s "accumulating loop-invariant tainted input" clause;
; the whole marking is refused, the body never enters `taint.IterationLocalBlocks`,
; and the per-trip `and` rail leaks. DELETE THE `(int)b` TERM AND IT LOWERS —
; that sibling is twin-identical at 32 = 32 and is not in the tree as a fixture
; only because its accept is already covered.
;
; THE FIX THIS PINS IS THE RECORD SITE, NOT A PREDICATE: `ArmClassify`'s R7 block
; now writes `taint.RolledLoopRegionGates` on the far side of `if (!Rollable)
; decline`, with a per-entry bit naming the granting clause, so EVERY R7-LOOP
; grant is re-asked. CLAUDE.md L1: the record must be at every R7-loop grant
; site. ⚠ NOT "every in-loop grant" (scoped by bd `s82e`, 2026-09-14): the leak
; is REGION-INDEPENDENT and the R7 slice is a strict subset, so a sibling with
; no tainted control flow at all still leaks silently.
;
; RETIREMENT TRIGGER (L8): this becomes an ACCEPT the day `markIfRailLocal` (or
; whatever succeeds it) can mark a body that reads a loop-invariant tainted rail,
; or the day the spine discharges a per-trip template rail without the marking.
; Re-derive the stream then — it is the 34-line hand-unrolled twin's, rolled —
; do not delete this file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so an IR-text `CHECK-NOT`
; here would be VACUOUS (Rule 12 hygiene (b)); the property is pinned by the
; `not` INVERSION on the RUN line plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error{{.*}}control flow inside a loop body under quantum control
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes/d3_invariant_read.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes/d3_invariant_read.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = zext i1 %1 to i32
  br label %7

4:                                                ; preds = %20
  %5 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %6 = add nsw i32 %5, %24
  ret i32 %6

7:                                                ; preds = %0, %20
  %8 = phi i32 [ %2, %0 ], [ %21, %20 ]
  %9 = phi i32 [ 0, %0 ], [ %25, %20 ]
  %10 = phi i32 [ 0, %0 ], [ %24, %20 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %12 = and i32 %11, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %16, label %14

14:                                               ; preds = %7
  %15 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #2
  br label %16

16:                                               ; preds = %14, %7
  %17 = phi i32 [ %15, %14 ], [ %8, %7 ]
  br i1 %1, label %18, label %20

18:                                               ; preds = %16
  %19 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 3.000000e-01) #2
  br label %20

20:                                               ; preds = %18, %16
  %21 = phi i32 [ %19, %18 ], [ %17, %16 ]
  %22 = add nsw i32 %11, %3
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #2
  %24 = add nsw i32 %23, %10
  %25 = add nuw nsw i32 %9, 1
  %26 = icmp eq i32 %9, 0
  br i1 %26, label %7, label %4, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 %1
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
