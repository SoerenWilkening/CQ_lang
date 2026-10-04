; control_phase_kickback_mixed_invariant_carried_inloop.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the Rule-13 CLEARANCE finding **C-1** (the BLOCK).
; THE MIXED LOOP: the kickback's condition register is loop-INVARIANT (D4's
; per-bit idiom) while the SAME loop also CARRIES a second tainted register.
;
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); cq_theta(&r,0.1); }
;       cq_theta(&q,0.9); return cq_measure(q)+cq_measure(r); }
;
; `clang -O1` on that source with `@main` dropped. The `!llvm.loop` metadata is
; kept VERBATIM — this is a genuine ROLLED loop, and `llvm.loop.unroll.disable`
; is what keeps it one. (`-O1` emits the per-bit test as `shl nuw nsw 1, i` +
; `and %q, %shl`, so the only template rail the body mints is the `and`.)
;
; WHAT WENT WRONG, AND IT IS A DISPATCH PRECONDITION, NOT A MISSING PROOF.
; `collapseFlattenedLoopRails` calls `collapseRailPhisIn`, which CLAIMS `r`'s
; header phi and returns `Collapsed` with `Roots = {r's mint}`. On that branch
; `markIfRailLocal` was handed ONLY the carried root, and its
; "an accumulating loop-invariant tainted input" clause then read `%q` — tainted,
; defined outside `L`, not `onRail` — and returned WITHOUT marking. Nothing in
; the body was certified iteration-local, so `Uncomputation`'s in-loop guard
; silently skipped every interior candidate. `invariantRegisterRoots` — the
; round-1 F-L5-1 fix that admits exactly this `%q` — was reachable only on
; `NotClaimed`. The mixed loop was served by NEITHER path.
;
; MEASURED at 542d588 (`opt` exit 0, verify-clean, STRICT stage 2b
; `0 violation(s)`): THREE `cq_template_and_i32_hl` mints and **ZERO** `_unc`
; discharges, while the hand-unrolled spelling of the same source discharges all
; three (3/3) and the PRE-3qlq ORACLE on the register-surface twin discharges
; them too (rolled == unrolled, 37 = 37). Three entangled which-path records of
; `q`'s low bits stay live through the `cqrt_ry_i32(%h, 0.9)` diffusion that
; follows, so rolled and unrolled are DIFFERENT UNITARIES — the 8h7d.5 F-4
; signature this epic graded CONFIRMED MISCOMPILE in round 1 (F-L7-2) and again
; in round 2 (F-R1-1). Stage 2b is structurally blind to it: a leaked TEMPLATE-
; minted rail has no `cqrt_alloc` to count.
;
; THE FIX. On the `Collapsed` branch `collapseFlattenedLoopRails` now ALSO
; collects the loop-INVARIANT roots — into a SEPARATE candidate set, unioned into
; the carried `Roots` only on success — and `invariantRegisterRoots` skips any
; candidate the collapse already owns (its `CarriedRoots` parameter). The proof is
; clause (ii)'s OWN and is not widened: a root mint lowers to `cqrt_alloc_<W>` +
; `cqrt_ry_<W>` and fails `ChainWalk::isInteriorTerminalHandle` clause (I1), so it
; can never be the preheader forward gate whose adjoint `At` lands in the K-times
; body — a property of the ROOT, not of whether some OTHER register crosses the
; back edge.
;
; WITNESS — the trace of this program is now BYTE-IDENTICAL to the hand-unrolled
; twin's (37 lines each; it was 31 vs 37), pinned at the e2e layer by
; `e2e-phase-perbit-loop-mixed-twin-identical`. This file is the lit-layer stand-in.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The two root mints, in source order: the INVARIANT condition register `%q`
; first, then the CARRIED register `%r`.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)

; The post-loop diffusion on the invariant register, and both measures. The rail
; phi for `%r` is GONE (the collapse RAUW'd it to `%[[R]]`), which is why the
; measure names the mint.
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; THE ROLLED BODY, in full and in order: mint the bit rail off the INVARIANT
; register, mint the flag, the ¬flag bracket, the kickback gate, the flag
; strip+free — AND the per-iteration discharge of the bit rail (⭐ the finding),
; then the CARRIED register's own per-trip gate.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[Q]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; ⭐ THE ASSERTION C-1 IS ABOUT. Exactly ONE `and` discharge, in the ROLLED body
; (the loop runs it K times). It was ZERO at 542d588 and every other directive in
; this file passed at that HEAD — so this count is the discriminator.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE kickback gate in the rolled body.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; TWO frees, both in the body: the bit rail and the flag. The two ROOT rails are
; the measures' and are never freed by the spine (Rule 6).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; The `cqrt_x` census: exactly the kickback's ¬flag bracket. An UNPAIRED one is a
; wrong-branch phase.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; `#cqrt_rz_i1 == #!cq.branchphase` — every emitted Rz is a recorded branch phase,
; so the uncompute spine can never adjoint the user's answer (round-1 F-L7-1).
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg
; NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  br label %9

4:                                                ; preds = %16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %8 = add nsw i32 %7, %6
  ret i32 %8

9:                                                ; preds = %1, %16
  %10 = phi i32 [ 0, %1 ], [ %18, %16 ]
  %11 = phi i32 [ %3, %1 ], [ %17, %16 ]
  %12 = shl nuw nsw i32 1, %10
  %13 = and i32 %12, %2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %9
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %16

16:                                               ; preds = %15, %9
  %17 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 1.000000e-01) #2
  %18 = add nuw nsw i32 %10, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %4, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
