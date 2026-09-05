; control_phase_kickback_mixed_preheader_addc_inloop.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding **F-C1-1**
; (CONFIRMED MISCOMPILE). C-1's own reproducer PLUS ONE LINE — a dtzb in-place
; `add` on the loop-INVARIANT condition register, in the loop's PREHEADER.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       q = q + 7;                                    /* <- the only difference */
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; `clang -O1` on that source with `@main` dropped. The `!llvm.loop` metadata is
; kept VERBATIM — this is a genuine ROLLED loop, and `llvm.loop.unroll.disable`
; is what keeps it one.
;
; WHAT WENT WRONG — C-1's OWN SENTENCE, ONE STAGE OVER: the proof exists and a
; PRECONDITION excludes the customer. `invariantRegisterRoots` clause (ii) peels
; with `AsLowered=true`, i.e. only through ops whose DISPOSITION is `InPlace`. A
; preheader `add` is in neither `taint.InPlaceRailOps` nor a `blockCanRepeat`
; block, so `railValueConsumerDisposition` answers `Unproven`, the peel STOPS AT
; THE `add`, `dyn_cast<CallInst>(Root)` fails, and the WHOLE extension returns
; false — while `lowerOps`' M-C lowers that very op IN PLACE (`cqrt_addc_i32(%h,
; 7)` is in the emitted trace, so the register the body reads IS the root mint's
; rail and clause (ii)'s (I1) argument carries verbatim).
;
; MEASURED on the pre-fix subject 542d588 **and on the round-1 C-1 fix**
; (`opt` exit 0, verify-clean, STRICT stage 2b `0 violation(s)`): THREE
; `cq_template_and_i32_hl` mints and **ZERO** `_unc` discharges, against a
; hand-unrolled twin at 3/3 and a pre-3qlq ORACLE on the register-surface twin at
; 3/3 rolled==unrolled (38 = 38). It is PRE-EXISTING and F-L5-1-era rather than
; round 1's: the same program with NO carried register (`p/x1_preadd_noR.c`, the
; `NotClaimed` path) leaks identically on both binaries.
;
; THE FIX, and it is a REUSE not a new rule (Rule 14). "Will M-C lower this
; straight-line dtzb op in place?" has exactly ONE spelling in the tree —
; `ArithLowering::classifyInPlaceReassignment` — so `invariantRegisterRoots` asks
; IT, and on success records the op in `taint.InPlaceRailOps`, which is a
; COMMITMENT rather than a hint (`OpcodeLowering` skips M-C for a marked op and
; routes it to `rewriteInPlaceValueRail`; M-C's own G5 refuses a marked site).
; One fact, both readers. A STABILITY conjunct rides with it — the parent must
; have exactly one use — because this prediction is made before the round-2
; control fixpoint and a stale "in place" would be a wrong unitary; see the
; `commitOutOfLoopInPlaceOps` header. On failure every marking is ROLLED BACK, so
; a module this path does not serve is byte-identical.
;
; WITNESS — the trace is now BYTE-IDENTICAL to the hand-unrolled twin's (38 lines
; each; it was 32 vs 38), pinned at the e2e layer by
; `e2e-phase-perbit-loop-mixed-preadd-twin-identical`. This file is the lit stand-in.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
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

; ⭐ THE PREHEADER OP, LOWERED IN PLACE ONTO THE ROOT MINT'S RAIL. This is the
; whole premise of the fix: because the op is `cqrt_addc_i32(%q, 7)` and not a
; fresh `cq_template_add_i32_hl` rail, the register the body's condition reads IS
; `%q`, and clause (ii)'s (I1) exclusion applies to it. It is `cqrt_addc` on
; BOTH the pre-fix binary and this one — what changed is that the analysis now
; KNOWS it, and commits to it.
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[Q]], i32 7)

; The post-loop diffusion on the invariant register, and both measures. `%r`'s
; rail phi is GONE (the collapse RAUW'd it to `%[[R]]`).
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

; ⭐ THE ASSERTION F-C1-1 IS ABOUT. Exactly ONE `and` discharge, in the ROLLED
; body (the loop runs it K times). It was ZERO at 542d588 AND at the round-1 fix.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ THE SECOND DISCRIMINATOR, in its own prefix: the preheader op is the IN-PLACE
; gate, and NO out-of-place `cq_template_add_i32_hl` rail is minted for it. The
; leak-control fixture `..._preheader_add_outofplace_leak_control.ll` is this
; file's mirror and asserts exactly the opposite pair.
; PCNT-COUNT-1: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: call i32 @cq_template_add_i32_hl(

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

; `#cqrt_rz_i1 == #!cq.branchphase`.
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

; ModuleID = 'p/r2_preadd_inv.c'
source_filename = "p/r2_preadd_inv.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = add nsw i32 %2, 7
  br label %10

5:                                                ; preds = %17
  %6 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 9.000000e-01) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %18) #2
  %9 = add nsw i32 %8, %7
  ret i32 %9

10:                                               ; preds = %1, %17
  %11 = phi i32 [ 0, %1 ], [ %19, %17 ]
  %12 = phi i32 [ %3, %1 ], [ %18, %17 ]
  %13 = shl nuw nsw i32 1, %11
  %14 = and i32 %13, %4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %10
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %17

17:                                               ; preds = %16, %10
  %18 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 1.000000e-01) #2
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %5, label %10, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1


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
