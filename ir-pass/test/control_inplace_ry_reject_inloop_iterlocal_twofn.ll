; control_inplace_ry_reject_inloop_iterlocal_twofn.ll — DECLINE (bd
; `test_C_libtooling-wx8g`, review round 1 finding F-W1-1): TWO ORDINARY KERNELS
; IN ONE TRANSLATION UNIT, the first one PASSING the round-2 re-ask and the
; second one owing a decline.
;
;     int kernel_a(void) { for (k<2) { bool t = 0; cq_theta(&t,.5); int r = 7; cq_theta(&r,.25);
;                                      if (t) cq_theta(&r,.2); … } }      // PASSES
;     int kernel_b(void) { for (k<2) { int  u = 5; cq_theta(&u,.5); int r = 7; cq_theta(&r,.25);
;                                      if ((u>>1)&1) cq_theta(&r,.2); … } }  // MUST DECLINE
;     int main(void) { return kernel_a() + kernel_b(); }
;
; ⚠ THIS FILE EXISTS BECAUSE THE TWO-FUNCTION AXIS WAS UNINSTRUMENTED AND A
; SILENT MISCOMPILE SHIPPED THROUGH IT. `declineUnmarkedRolledIterLocal` declared
; its "already diagnosed this loop" set as a module-scoped
; `SmallPtrSet<const Loop *>` while the `LoopInfo` that OWNS those `Loop` objects
; was declared per function. The pointers dangled across functions, the next
; `LoopInfo` re-used the allocation, and `insert(L).second` returned FALSE FOR A
; DIFFERENT LOOP IN A DIFFERENT FUNCTION — so BOTH conjuncts of the re-ask were
; `continue`d over for `kernel_b`. MEASURED on the pre-fix binary
; `daeb93a36bdc57b3`: this module ACCEPTED at 40 trace lines with
; `cq_template_and_i32_hl` minted TWICE and `cq_template_and_i32_hl_unc`
; emitted ZERO times — one entangled which-path record of `u`'s bits leaked per
; activation. `opt` exit 0, `opt -verify` clean, STRICT stage 2b
; `0 violation(s)`.
;
; NO `noinline` AND NO ATTRIBUTE OF ANY KIND: `-O1` keeps two loop-bearing
; kernels separate on its own, so this is what an ordinary two-kernel C file
; compiles to. The module order is the only variable — the same pair written the
; other way round declined even on the defective binary, which is what isolated
; the set as the cause.
;
; ITS TWO HALVES ALREADY SHIP AS SINGLE-FUNCTION FIXTURES AND BOTH ARE GREEN
; EITHER WAY: `control_inplace_ry_inloop_iterlocal_no_root.ll` (the `kernel_a`
; shape, ACCEPT) and `control_inplace_ry_reject_inloop_iterlocal_no_root_derived.ll`
; (the `kernel_b` shape, DECLINE). That is the whole point — every fixture in
; this tree that carries two `define`s gives them the SAME disposition, so the
; suppression had nothing to bite on. What this file adds is the MIXED pair.
;
; ⚠ WHAT THIS FILE IS AND IS NOT, AS A REGRESSION DETECTOR (review round 2,
; finding F-W2-4's hygiene note, 2026-09-14). POST-FIX its decline is
; STRUCTURAL — the dedup sets are per-function and keyed on `L->getHeader()`, a
; `BasicBlock *` that outlives the analysis — so it is a sound FORWARD pin.
; PRE-FIX it declined ONLY BECAUSE ADDRESSES WERE RECYCLED across the four
; `LoopInfo` instances this module builds (its `@main` carries both loops
; inlined, so even the in-function axis had to alias). So as a detector against
; someone RE-INTRODUCING a module-scoped set it is only as good as the
; allocator: it caught the defect on this machine and a different allocator
; could let the same defect through it. Do not treat a green run of this file as
; proof that no module-scoped `Loop *` set exists — read the declaration.
;
; RETIREMENT TRIGGER (L8): if the `kernel_b` shape ever becomes an accept (see
; the sibling's own trigger — a spine that can discharge an iteration-local
; template rail without the block marking), this file becomes an ACCEPT whose
; stream is `kernel_a`'s 14 lines followed by `kernel_b`'s discharged 30.
; Re-derive it then; do NOT delete it, because its subject is the per-function
; scoping and not the `kernel_b` verdict.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so an IR-text `CHECK-NOT`
; here would be VACUOUS (Rule 12 hygiene (b)); the property is pinned by the
; `not` INVERSION on the RUN line plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error{{.*}}control flow inside a loop body under quantum control
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes/b6_noattr.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes/b6_noattr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @kernel_a() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %9
  ret i32 %15

2:                                                ; preds = %0, %9
  %3 = phi i32 [ 0, %0 ], [ %15, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %16, %9 ]
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %5, label %7, label %9

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #2
  br label %9

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ %6, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %13 = zext i1 %12 to i32
  %14 = add i32 %11, %3
  %15 = add i32 %14, %13
  %16 = add nuw nsw i32 %4, 1
  %17 = icmp eq i32 %4, 0
  br i1 %17, label %2, label %1, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @kernel_b() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %11
  ret i32 %16

2:                                                ; preds = %0, %11
  %3 = phi i32 [ 0, %0 ], [ %16, %11 ]
  %4 = phi i32 [ 0, %0 ], [ %17, %11 ]
  %5 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %7 = and i32 %5, 2
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %2
  %10 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #2
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %10, %9 ], [ %6, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %15 = add i32 %13, %3
  %16 = add i32 %15, %14
  %17 = add nuw nsw i32 %4, 1
  %18 = icmp eq i32 %4, 0
  br i1 %18, label %2, label %1, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %8, %0
  %2 = phi i32 [ 0, %0 ], [ %14, %8 ]
  %3 = phi i32 [ 0, %0 ], [ %15, %8 ]
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %4, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ %5, %1 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #2
  %12 = zext i1 %11 to i32
  %13 = add i32 %10, %2
  %14 = add i32 %13, %12
  %15 = add nuw nsw i32 %3, 1
  %16 = icmp eq i32 %3, 0
  br i1 %16, label %1, label %17, !llvm.loop !6

17:                                               ; preds = %8, %26
  %18 = phi i32 [ %31, %26 ], [ 0, %8 ]
  %19 = phi i32 [ %32, %26 ], [ 0, %8 ]
  %20 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %21 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %22 = and i32 %20, 2
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %26, label %24

24:                                               ; preds = %17
  %25 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 2.000000e-01) #2
  br label %26

26:                                               ; preds = %24, %17
  %27 = phi i32 [ %25, %24 ], [ %21, %17 ]
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #2
  %29 = tail call i32 @cq_measure_si32(i32 noundef %20) #2
  %30 = add i32 %28, %18
  %31 = add i32 %30, %29
  %32 = add nuw nsw i32 %19, 1
  %33 = icmp eq i32 %19, 0
  br i1 %33, label %17, label %34, !llvm.loop !9

34:                                               ; preds = %26
  %35 = add nsw i32 %31, %14
  ret i32 %35
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
!9 = distinct !{!9, !7, !8}
