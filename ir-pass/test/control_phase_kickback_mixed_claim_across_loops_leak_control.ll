; ⚠⚠ VERDICT INVERTED: ACCEPT -> DECLINE, **OWNER RULING 2026-09-14** (bd
; test_C_libtooling-3d8q, Rule-13 round-1 finding F-D1-1). Everything below this
; block is the file's ORIGINAL header and its original directives, preserved
; verbatim as the record of what it used to pin, and NEUTERED (`CHECK` ->
; `[check]`, and every `--check-prefix` name likewise) so FileCheck cannot see
; them. Read it; do not delete it.
;
; THE RULED SHAPE, and this module contains it: LOOP B's `int s = r; cq_theta(&s, 0.2)` reads `r`, which LOOP A left behind.
; The name is loop-INVARIANT and is RE-READ on every trip while the wire has
; already moved under it — CLAUDE.md CORRECTNESS RISK §2's rail-staleness rule
; verbatim ("a rail member may be read only where no rail-relabelling gate
; executes between the record's definition and the read WITHOUT that definition
; re-executing"). The owner ruled it a DECLINE on 2026-09-14, on the measurement
; that the source admits TWO realizable circuits and names neither: the aliasing
; chain that was emitted, and the RE-PREPARATION reading, which needs no cloning
; (re-running a known preparation is not copying an unknown state) and which this
; compiler already emits when the source asks unambiguously. Analytically the two
; differ: N i.i.d. samples of the prepared state versus one sample followed by
; N-1 samples locked onto the first outcome.
;
; ⚠ WHAT THIS CONVERSION COSTS, stated rather than hidden (Rule 12(c)).
; The subject was F-C1B-2's per-loop `ClaimedRailRoots` key — *"LOOP A's claim must
; not satisfy clause (0) for LOOP B"* — and it needs LOOP B to hold an in-body
; in-place gate on a root LOOP B did not itself claim, which is exactly a
; loop-invariant re-read. The subject is inseparable from the ruled-out shape, so
; this pin cannot be preserved by an edit either. MEASURED: the discriminating
; ACCEPT half, `control_phase_kickback_mixed_claim_across_loops_accept_control.ll`
; (the same source with LOOP B's `int s = r; cq_theta(&s,0.2)` REMOVED), still ACCEPTS on this
; binary, so the "a narrowed key that refused everything" control is intact; what
; is lost is the REFUSAL direction's only positive pin. Filed as a Track-D
; follow-on. ⚠ Note also that this file's own header records that its
; HAND-UNROLLED twin declines on every binary in the epic — so, exactly as with
; `l1`/`l1u`, the ruling CLOSES a rolled/unrolled disposition split rather than
; opening one.
;
; RETIREMENT TRIGGER (L8): if the 2026-09-14 ruling is ever reversed this file
; inverts back to its preserved ACCEPT form — every directive below is still here
; for exactly that — and `lowering_reject_stale_reader_inloop_invariant_seed.ll`
; inverts with it, in the same commit. Do not move one without the other.
;
; WHICH FENCE (2026-10-05, batch 043). Until then the stale-reader fence refused
; this module (`cq opcode lowering: rotation/measure operand predates a
; non-diagonal gate`, still the message of its twin
; lowering_reject_stale_reader_inloop_invariant_seed.ll). Since bd r2j3.13
; (commit 430ef345) round 1 asks every off-chain absorbed rail op positionally, so
; LOOP B's read of r past LOOP B's in-place gate on r is refused earlier, by the
; loop record fence. Same hazard, same verdict; only the reporting fence moved.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so an IR-text `CHECK-NOT` here
; would be VACUOUS (Rule 12 fixture-hygiene defect (b)); the property is carried
; by the `not` inversion on the RUN line and by the CHECK above.
;
; ───────────── ORIGINAL HEADER AND DIRECTIVES, NEUTERED, BELOW ─────────────
; control_phase_kickback_mixed_claim_across_loops_leak_control.ll —
; ACCEPT-AND-LEAKS. bd test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round,
; finding **F-C1B-2**: `taint.ClaimedRailRoots` was MODULE-WIDE and keyed on the
; ROOT VALUE, while the property `invariantRegisterRoots` clause (0) skips on is
; PER-LOOP.
;
;     int ext_f(int a);                             /* separate TU: return a + 100; */
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       for(int i=0;i<3;i++){ cq_theta(&r,0.1); }  /* LOOP A — tryCaseA CLAIMS r     */
;       int y=5; if (q>5) y=ext_f(7);               /* 6.5 arm -> %out (ROUND 2)      */
;       int acc=0;
;       for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25);
;                             int s=r; cq_theta(&s,0.2); acc+=cq_measure(s); }  /* LOOP B */
;       return cq_measure(y)+acc; }
;
; Clause (0) means *"THIS loop's collapse already proved THIS rail, so do not judge
; it again"*. Keyed on the root alone, LOOP A's claim satisfied it for LOOP B —
; where clause (iii)'s own question (is there an in-loop in-place gate on this
; root?) was then never asked, and loop B's body was MARKED on a rail loop B never
; proved. Instrumented ground truth on the round-2 binary:
;
;     [DBG] R2=0 localRoots=0 claimed=1          <- the claim comes from LOOP A
;     [DBG] IRR TRUE roots=2 marked=0
;     [DBG] markIfRailLocal MARKED 1 blocks      <- loop B marked
;
; and on this HEAD, with the key `(root, the CLAIMING loop's header)`:
;
;     [DBG] R2=0 localRoots=0 claimedTOTAL=1 claimedHERE=0
;     [DBG] IRR FALSE rollback=0                 <- judged, and refused
;
; ⭐ THE OBSERVABLE. The round-2 binary emitted 3 `cq_template_and_i32_hl` mints
; and 3 `_unc` discharges (51 trace lines); 542d588, the round-1 fix and this HEAD
; emit 3 mints / **0** discharges (45 lines, BYTE-IDENTICAL across the three). So
; the per-loop key is not a new over-decline — it REVERTS a widening the second
; round introduced by accident. The lens that found F-C1B-2 graded it LATENT
; because the four spellings it built all decline at a later fence; this fifth one
; does not, which is why the finding has a fixture at all.
;
; The hand-unrolled twin of this source DECLINES on every binary in the epic
; (`cq loop lowering: loop-carried rail has multiple in-place consumers`, the
; Rule-8 fan-out guard), so there is no twin witness in either direction — the
; witness is the three-binary byte diff plus the instrumented marking.
;
; ⚠ A HEADER-BLOCK KEY CAN ONLY EVER REFUSE, which is what makes it admissible
; inside a Rule-13 fence. If the pointer ever failed to survive the round-2
; flatten, the claim would not match, clause (0) would judge the candidate,
; clause (iii) would refuse it, and the module would keep today's leak. It DOES
; survive, MEASURED for BOTH writers (`tryCaseA` at round 1 read at round 2 —
; `p/r33_onward_inv_only.c`, `claimedHERE=1`; `collapseRailPhisIn` step (4) —
; `p/r40_onward_r1open.c`, `claimedHERE=1` at both offers), and every shipped
; customer keeps its 3/3 rolled-vs-unrolled identity.
;

; The two root mints. NOTE the printed BLOCK ORDER below is entry, then the 6.5
; region's block, then LOOP A's body, then LOOP B's — `-O1` rotates both loops, so
; these CHECKs follow file order, not source order.
; [check]: call void @cqrt_ry_i32(i32 %{{.*}}, double 5.000000e-01)
; [check]-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; [check]-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)

; The 6.5 arm's out-rail, minted between the two loops.
; [check]: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)

; LOOP A: the carried rail collapsed to its root — one `cqrt_ry` per trip on `%r`.
; [check]: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; LOOP B: the bit rail off `%out`, the flag, the kickback, the strip and the flag
; free — and NO discharge of the bit rail. That is the leak this file pins.
; [check]: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; [check]-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; [check]-NEXT: call void @cqrt_x(i32 %[[F]])
; [check]-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; [check]-NEXT: call void @cqrt_x(i32 %[[F]])
; [check]-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; [check]-NEXT: call void @cqrt_free(i32 %[[F]])
; [check]-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)

; ⭐ THE ASSERTION: ZERO `and` discharges anywhere. It was ONE on the round-2 binary.
; [ucnt]-NOT: call void @cq_template_and_i32_hl_unc(

; One kickback gate, in loop B's body.
; [acnt]-COUNT-1: call void @cqrt_rz_i1(
; [acnt]-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).
; [mdcnt]-COUNT-1: !cq.branchphase
; [mdcnt]-NOT: !cq.branchphase

; The `cqrt_free` census — a dropped or an extra free is a Rule-6 defect the
; positive CHECKs cannot see.
; [fcnt]-COUNT-2: call void @cqrt_free(
; [fcnt]-NOT: call void @cqrt_free(

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; [xcnt]-COUNT-4: call void @cqrt_x(i32
; [xcnt]-NOT: call void @cqrt_x(i32

; WHOLE-FILE PURE-NEGATIVE.
; [noroute]-NOT: @cqrt_cswap
; [noroute]-NOT: @cq_phi
; [noroute]-NOT: @cq_theta
; [noroute]-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; [noroute]-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(

; ModuleID = 'llvm-link'
source_filename = "llvm-link"

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  br label %6

4:                                                ; preds = %6
  %5 = icmp sgt i32 %2, 5
  br i1 %5, label %12, label %14

6:                                                ; preds = %6, %1
  %7 = phi i32 [ %3, %1 ], [ %9, %6 ]
  %8 = phi i32 [ 0, %1 ], [ %10, %6 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 1.000000e-01) #3
  %10 = add nuw nsw i32 %8, 1
  %11 = icmp eq i32 %10, 3
  br i1 %11, label %4, label %6, !llvm.loop !6

12:                                               ; preds = %4
  %13 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %14

14:                                               ; preds = %12, %4
  %15 = phi i32 [ %13, %12 ], [ 5, %4 ]
  br label %19

16:                                               ; preds = %26
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = add nsw i32 %17, %29
  ret i32 %18

19:                                               ; preds = %26, %14
  %20 = phi i32 [ 0, %14 ], [ %30, %26 ]
  %21 = phi i32 [ 0, %14 ], [ %29, %26 ]
  %22 = shl nuw nsw i32 1, %20
  %23 = and i32 %22, %15
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %26, label %25

25:                                               ; preds = %19
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %26

26:                                               ; preds = %25, %19
  %27 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01) #3
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  %29 = add nsw i32 %28, %21
  %30 = add nuw nsw i32 %20, 1
  %31 = icmp eq i32 %30, 3
  br i1 %31, label %16, label %19, !llvm.loop !9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
