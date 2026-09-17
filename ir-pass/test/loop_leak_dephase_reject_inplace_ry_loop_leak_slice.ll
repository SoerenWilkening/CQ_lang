; loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll — DECLINE. The verbatim
; stage-1 module of the UNREGISTERED e2e slice
; `tests/e2e/slice_control_inplace_ry_loop_leak.c`, kept so the conversion costs
; ZERO coverage. bd `test_C_libtooling-6n1s` F-1, 2026-09-18.
;
; ⚠ **THIS PROGRAM SHIPPED A Rule-8 WRONG UNITARY UNDER A GREEN `twin-identical`
; GATE**, and both slice headers called it *"IT IS RULE-6 CORRECT"* — the exact
; sentence `CLAUDE.md` §5's Q-R1-1 correction ruled FALSE for three sibling
; fixtures.
;
;     for (int i = 0; i < 2; ++i) {
;         int s = r * 7;  printf("%d\n", s);       /* -> the output tape */
;         if (q == 5) { r = cq_theta(r, 0.9); }    /* NON-DIAGONAL, on r */
;         cq_phi(0.1);
;         q = cq_theta(q, 0.05);
;     }
;     return cq_measure(q) + cq_measure(r);        /* r IS the observable */
;
; THE HAZARD, read off the DELETED golden: `cq_template_mul_i32_hl(h2,7) -> h3`
; is a COHERENT copy of `h2`'s basis label; `cqrt_tape_write_i32(t0,h3) -> h4`
; COPIES it into the output tape and does NOT collapse it; `h3` is then never
; `_unc`'d and never freed, and `cqrt_ry_i32_controlled(h5, h2, 0.9)` — a
; NON-DIAGONAL gate on `h2` — runs with that record standing, after which `h2` is
; measured. ⚠ ONLY the tape-write RESULT (`h4`) is an `OutputRails` member; its
; OPERAND `h3` is an ordinary interior template rail, so *"it is the program's own
; output"* does **not** excuse it.
;
; ⚠ WHY THE TWIN GATE WAS BLIND, because this is the transferable part: the
; unrolled twin leaks the SAME rail in the SAME place, so `compare_files` over the
; two goldens PASSED. `CLAUDE.md` L10 states the general form — *"a cell whose two
; halves agreed because BOTH were wrong is precisely what ACCEPT-IDENTICAL cannot
; see; only a fence can."*
;
; WHAT REFUSES IT NOW: `declineDephasingUnmarkedLoopRails` conjunct (1) records
; the marked body's discharge promise and `declineUndischargedMarkedBodyRails`
; checks it at the tail of the pass, after `uncompute`, in BOTH entry points —
; using the EXISTING bd `s82e` string, so this file joins that fence's pins.
;
; ⚠ THE UNROLLED TWIN IS **NOT** COVERED AND IS A SEPARATE P1. That fence is
; LOOP-SCOPED by construction, and the twin has no loop, so it still compiles the
; identical hazard at exit 0. It is kept unregistered at
; `tests/e2e/slice_control_inplace_ry_loop_leak_unrolled.c` with its own header,
; and the bead text is in `trackT2/BD_TEXT.md`. Do not read this fixture as
; covering that.
;
; ⚠ RULE-12 HYGIENE (b): a `DS_Error` decline writes ZERO bytes to stdout, so the
; property is pinned by the `not` inversion on the RUN line plus the
; character-for-character message, never by an IR-text `CHECK-NOT`.
;
; ⚠ L8 RETIREMENT TRIGGER: the day this family's which-path leak gains a real
; placement, this file becomes an ACCEPT whose stream must be re-derived against
; the hand-unrolled twin's MULTISET (owner ruling S3); do not delete it, and do
; not restore the deleted goldens.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register

; ModuleID = 'tests/e2e/slice_control_inplace_ry_loop_leak.c'
source_filename = "tests/e2e/slice_control_inplace_ry_loop_leak.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #3
  br label %7

3:                                                ; preds = %16
  %4 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %6 = add nsw i32 %5, %4
  ret i32 %6

7:                                                ; preds = %0, %16
  %8 = phi i32 [ %1, %0 ], [ %18, %16 ]
  %9 = phi i32 [ 0, %0 ], [ %19, %16 ]
  %10 = phi i32 [ %2, %0 ], [ %17, %16 ]
  %11 = mul nsw i32 %10, 7
  %12 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %11)
  %13 = icmp eq i32 %8, 5
  br i1 %13, label %14, label %16

14:                                               ; preds = %7
  %15 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #3
  br label %16

16:                                               ; preds = %14, %7
  %17 = phi i32 [ %15, %14 ], [ %10, %7 ]
  tail call void @cq_phi(double noundef 1.000000e-01) #3
  %18 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-02) #3
  %19 = add nuw nsw i32 %9, 1
  %20 = icmp eq i32 %9, 0
  br i1 %20, label %7, label %3, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
