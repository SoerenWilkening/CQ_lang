; loop_pairing_accept_hoisted_chain_exit_discharge.ll — ACCEPT, AND IT DISCHARGES
; AT THE LOOP EXIT. bd `test_C_libtooling-tu9q`, the HOISTED-TEMPLATE half, piece
; **P2**. THE RED HALF of its red-green pair, and it closes bd
; `test_C_libtooling-1m5p` and a LIVE Rule-8 OVER-ACCEPT at the same time.
;
; SOURCE (`trackT2/probes/a1_apost.c`, `clang -O1`, no `-g`) — bd `1m5p`'s own
; "reachable consequence", which nobody had built until the 2026-09-18 scoping:
;
;     int a = 0; int r = 0;
;     cq_theta(&a, 0.5);
;     cq_theta(&r, 0.3);
;     for (int i = 0; i < 2; ++i)
;         if (sqrt(a + 3.) <= (double)off) { cq_theta(&r, 0.9); }
;     cq_theta(&a, 0.7);                      /* <- the interference */
;     return cq_measure(a) + cq_measure(r);
;
; ⚠ WHAT IT WAS: `opt` exit **0**, 26 trace lines against the hand-unrolled twin's
; 28, `cq_template_sqrt_f64_unc` count **0 rolled / 1 unrolled**, and the ONLY
; instrument that saw it was a WARNING (`cq rotation lowering: non-diagonal gate
; over a live derived record`, rolled; SILENT on the twin). The leaked
; `h = sqrt((double)a + 3.0)` rail is an INJECTIVE function of `a`'s basis label —
; a perfect which-path record — standing at a non-diagonal `cqrt_ry_i32(h, 0.7)` on
; `a`, which is then measured. Rolled and flat were DIFFERENT UNITARIES
; (`CLAUDE.md` Rule 8's last sentence), and `declineDephasingUnmarkedLoopRails` does
; **not** refuse it: its conjunct (3) quantifies over `L`'s OWN blocks and this rail
; is minted in the PREHEADER, so the fence for this hazard class is structurally
; blind to the hoisted instance of it.
;
; ⚠ WHY IT LEAKED, precisely, because "the compiler forgot" is not a mechanism.
; `planInteriorComponent`'s convergence loop asks
; `provablyBeforePerActivation(U, At, R)` with the rail's own MINT as the barrier.
; For a PREHEADER-minted rail with an IN-BODY consumer and an IN-BODY `At`, every
; path `At ⇝ U` goes round the back edge and NEVER re-executes the preheader, so
; the barrier walk finds a barrier-free path, the helper returns false and the rail
; is DROPPED from `Owned`. The partition then re-converged on the SHORTER prefix
; and discharged `%h_cast`/`%h_op` IN THE PREHEADER while `%h_intr`, derived from
; them, was still live — the LIFO inversion bd `1m5p` records.
;
; THE FIX IS A PLACEMENT (Rule 17): `Uncomputation::anchorForConsumer` anchors a
; rail minted OUTSIDE the cycle its consumer runs in at that cycle's unique EXIT —
; the point at which the consumer is finished for good. Nothing downstream is
; relaxed; the convergence test, §4's dominance/post-dominance, §2.9's
; at-most-once, P1's multiplicity and clause (d) all re-run at the new point.
;
; WHAT TO READ IN THE CHECKS, in one sentence: the WHOLE chain
; (`sitofp → fadd → sqrt`) is adjointed **LIFO in the loop-exit block**, and the
; last free lands **BEFORE** `cqrt_ry_i32(%h, 0.7)` — which is the entire
; correctness claim, because a which-path record discharged before the
; interference cannot dephase it.
;
; MEASURED AT THE LANDING, and the claim is MULTISET + commutation, never byte
; identity (owner ruling S3, `$THIS/DECISIONS.md`: byte identity is an INSTRUMENT,
; not the target): rolled **28** == hand-unrolled twin **28**, trace multiset
; IDENTICAL with handle numbers normalised, order-divergent, and `opt` stderr
; **0 bytes** where it previously carried the warning. The warning going silent is
; itself the witness that the record is discharged rather than that the warn stage
; stopped looking — `warnLiveRecordRotations` still fires on the sibling shapes.
;
; ⚠ STAGE 2b CANNOT WITNESS THIS AND IT IS STRUCTURAL. `free_pairing_check.py`
; analyses per straight-line STREAM, so a discharge at a LOOP EXIT is
; `U3-extern-rail` UNPROVEN by construction (measured: `1 verified, 0 violation(s),
; 3 unproven`, against the hand-unrolled twin's `5 verified, 0 unproven`). The rail
; identities are pinned HERE instead, by position.
;
; ⚠ L8 RETIREMENT TRIGGER: if `loopExitDischargePoint` is ever widened to a
; MULTI-EXIT loop, this file does not change but its boundary sibling does —
; re-derive them together. If the three `_unc` lines below ever move back INSIDE
; `%3`, P2 has been inverted and bd `1m5p` is live again.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
;
; The chain is hoisted into the preheader, ABOVE the `br` into the loop.
; CHECK-LABEL: define i32 @slice
; CHECK: %h_cast = call i32 @cq_template_sitofp_i32_to_f64(i32 %h)
; CHECK-NEXT: %h_op = call i32 @cq_template_fadd_f64_hl(i32 %h_cast, double 3.000000e+00)
; CHECK-NEXT: %h_intr = call i32 @cq_template_sqrt_f64(i32 %h_op)
; CHECK-NEXT: br label %3
;
; …and the WHOLE chain is adjointed LIFO in the loop-EXIT block, with the last
; free strictly BEFORE the interfering rotation. `CHECK-NEXT` throughout, so
; nothing may be inserted between them.
; CHECK: call void @cq_template_sqrt_f64_unc(i32 %h_intr, i32 %h_op)
; CHECK-NEXT: call void @cqrt_free(i32 %h_intr)
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %h_op, i32 %h_cast, double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %h_cast, i32 %h)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cast)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; The body is UNMARKED and the per-trip flag is the only thing minted and freed
; inside it — P2 needs no marking, which is what separates it from P0/P3.
; CHECK: %h_cmp = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %h_intr, double %6)
; CHECK: call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %h_cmp, i32 %h_intr, double %6)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
;
; ONE mint and ONE adjoint per chain member, in PROGRAM ORDER — own whole-file
; prefix, so no positive above can window a negative (Rule 12 fixture-hygiene
; defect (a)), and the trailing `-NOT` bounds the tail.
; COUNT-COUNT-1: call i32 @cq_template_sitofp_i32_to_f64(
; COUNT-COUNT-1: call i32 @cq_template_fadd_f64_hl(
; COUNT-COUNT-1: call i32 @cq_template_sqrt_f64(
; COUNT-COUNT-1: call void @cq_template_sqrt_f64_unc(
; COUNT-COUNT-1: call void @cq_template_fadd_f64_hl_unc(
; COUNT-COUNT-1: call void @cq_template_sitofp_i32_to_f64_unc(
; COUNT-NOT: call i32 @cq_template_sqrt_f64(
; COUNT-NOT: call void @cq_template_sqrt_f64_unc(
;
; THE FREE CENSUS, in its own prefix. FOUR: the three chain members at the loop
; exit plus the per-trip condition flag in the body. An EXTRA free is a hidden
; measurement (Rule 6).
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
;
; THE ROTATION CENSUS, its own prefix. Added because the injection matrix
; MEASURED this file MISSING an injected `cqrt_ry`. THREE uncontrolled ones:
; the two source preps and the post-loop interference. The per-trip
; `cqrt_ry_i32_controlled` is a DIFFERENT symbol and is deliberately not in this
; pattern — it is the arm's gate, and counting it here would make the census move
; with the trip count.
; RYCNT-COUNT-3: call void @cqrt_ry_i32(
; RYCNT-NOT: call void @cqrt_ry_i32(

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/a1_apost.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/trackT2/probes/a1_apost.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %3 = sitofp i32 %1 to double
  %4 = fadd double %3, 3.000000e+00
  %5 = tail call double @llvm.sqrt.f64(double %4)
  br label %11

6:                                                ; preds = %19
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %10 = add nsw i32 %9, %8
  ret i32 %10

11:                                               ; preds = %0, %19
  %12 = phi i32 [ 0, %0 ], [ %21, %19 ]
  %13 = phi i32 [ %2, %0 ], [ %20, %19 ]
  %14 = load volatile i32, ptr @off, align 4, !tbaa !6
  %15 = sitofp i32 %14 to double
  %16 = fcmp ugt double %5, %15
  br i1 %16, label %19, label %17

17:                                               ; preds = %11
  %18 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 9.000000e-01) #3
  br label %19

19:                                               ; preds = %11, %17
  %20 = phi i32 [ %18, %17 ], [ %13, %11 ]
  %21 = add nuw nsw i32 %12, 1
  %22 = icmp eq i32 %12, 0
  br i1 %22, label %11, label %6, !llvm.loop !10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
