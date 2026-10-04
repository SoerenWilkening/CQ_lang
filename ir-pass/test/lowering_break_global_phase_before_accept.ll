; lowering_break_global_phase_before_accept.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the Rule-13 CLEARANCE §4 (ii): the DISCRIMINATING
; CONTROL for `lowering_reject_break_phase_answer_kickback.ll`.
;
;     __attribute__((noinline))
;     int run(int seed, int n){ int q = seed; cq_theta(&q, 0.25);
;       cq_phi(0.3);                              // UNCONTROLLED -> a GLOBAL phase
;       for (int i = 0; i < n; i++) { q = q ^ 5; if ((q & 1) == 0) break; }
;       return cq_measure(q); }
;
; `clang -O1`, `@main` dropped (`clearance_c1`'s sibling source
; `f3_break_global_phase_before.c`).
;
; WHAT IT PINS, AND WHY IT IS NOT DECORATION. The B3 fence
; `cq loop lowering: early break preserves a phase answer` fires on the SAME
; program with `if (q == 5) cq_phi(0.3)` in place of the bare call. If a bare
; `cq_phi` before the loop declined too, that fence would be a WALL — "any
; `cq_phi` near a break loop declines" — rather than the post-dominance /
; phase-lineage discriminator it claims to be. It is not: an UNCONTROLLED
; `cq_phi` is a GLOBAL phase and owner decision D2 DELETES it (a documented
; semantic, not a diagnostic), so nothing phases the escaping answer and the 7.4
; break lowering runs untouched.
;
; MEASURED on the pre-fix subject 542d588 through the full pipeline: this program
; accepts and its trace is **BYTE-IDENTICAL** to the plain break loop's — the same
; source with the `cq_phi` line deleted (`p/f0_break_plain.c`, 209 lines each,
; `diff` empty). Stage 2b reports `unproven` for both, exactly as the four shipped
; `slice_loop_break*` slices do (`--allow-unproven`, the dtzb whole-loop
; reverse-play; see CLAUDE.md's stage-2b note) — that is the break lowering's
; standing disposition and is not what this file is about.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOPHASE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll

; The D2 deletion: no Rz of any width is emitted anywhere, and no `@cq_phi` call
; survives. THIS is the clause that makes the sibling decline a discriminator.
; NOPHASE-NOT: @cqrt_rz_
; NOPHASE-NOT: @cq_phi
; NOPHASE-NOT: @cq_theta

; The 7.4 break lowering runs: the rail is collapsed to one in-place handle and
; the index-gated capture fires.
; CHECK: call i32 @cqrt_alloc_i32(
; CHECK: call void @cqrt_xorc_i32(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call i32 @cqrt_measure_i32(

; THE CENSUSES. They exist because this round's injection matrix caught NOTHING
; with the two original prefixes alone -- an extra `cqrt_free`, an extra
; `cqrt_x`, an extra `cqrt_cswap` and a DELETED `cqrt_free` were all MISSED.
; The counts are the
; shipped 7.4 break lowering's, MEASURED on this module; this file's subject is
; the D2 deletion, and these keep it from being blind to everything else.
; FCNT-COUNT-16: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; ZERO `cqrt_x` -- the break lowering brackets nothing here, so any is injected.
; XCNT-NOT: call void @cqrt_x(i32

; The capture census: 2 `cqrt_toffoli` fire-flags, and NO `cqrt_cswap` anywhere
; (the 7.4 capture is copy-NOT-move, PRD-7.4 section 2.2).
; CCNT-COUNT-2: call void @cqrt_toffoli(
; CCNT-NOT: call void @cqrt_toffoli(
; CCNT-NOT: @cqrt_cswap

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @run(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %14

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %11, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %8, %5 ], [ %3, %2 ]
  %8 = xor i32 %7, 5
  %9 = and i32 %8, 1
  %10 = icmp eq i32 %9, 0
  %11 = add nuw nsw i32 %6, 1
  %12 = icmp eq i32 %11, %1
  %13 = select i1 %10, i1 true, i1 %12
  br i1 %13, label %14, label %5, !llvm.loop !6

14:                                               ; preds = %5, %2
  %15 = phi i32 [ %3, %2 ], [ %8, %5 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
