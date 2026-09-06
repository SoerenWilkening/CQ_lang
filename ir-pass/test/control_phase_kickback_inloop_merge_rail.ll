; control_phase_kickback_inloop_merge_rail.ll — ACCEPT. bd test_C_libtooling-3qlq
; Inc 1, Rule-13 ROUND-2 finding F-R1-1, THE ROUND-1 HALF — and it is here
; because F-R1-1 was reported as a stage-ORDER finding and the population turned
; out to be wider than that.
;
;     int q = 3; q = cq_theta(q, 0.5);
;     int y = (q > 5) ? 7 : 5;                   // 4.4 SELECT merge  ->  %out
;     for (int i = 0; i < 3; ++i)
;         if (((y >> i) & 1)) cq_phi(0.25);      // D4's per-bit idiom, ROLLED
;     return cq_measure(y);
;
; `clang -O1` output verbatim (`@main` dropped). NOTHING here is onward: the 4.4
; `SelectMergeEmit` region is claimed at ROUND 1, so `collapseFlattenedLoopRails`
; DOES see this loop at its original slot — and the rails leaked anyway, because
; `invariantRegisterRoots` clause (ii) admitted only a `cq_theta` ROOT MINT and
; this loop's invariant register is a `cqrt_alloc_i32` `%out` rail. MEASURED at
; `c4bd888`: 3 `cq_template_and_i32_hl` mints, **0** `_unc`. The switch data-mux
; (`switch(q){case 1: y=7; …}`) leaks identically at round 1 and is the same
; clause; the 6.5 onward arm is the round-2 one and is
; `control_phase_kickback_onward_inloop.ll`.
;
; So the two files partition the fix, and each pins ONE half:
;   * THIS file needs clause **(ii-b)** (`invariantRegisterRoots` admitting a
;     control-owned `cqrt_alloc_<W>` merge out-rail as a Root) and NOTHING else —
;     it is green with the onward pass deleted.
;   * `control_phase_kickback_onward_inloop.ll` needs (ii-b) AND the onward
;     `collapseFlattenedLoopRails` call at the end of `repropagateControlMerges`.
; MUTATION-VALIDATED both ways (see the notes' §2 table).
;
; WHY (ii-b) IS SOUND, in one line, because it is a widening inside a Rule-13
; fence — clause (ii)'s whole proof is that a Root can never be the PREHEADER
; forward gate whose interior `At` lands in the K-times body, and that proof is
; `ChainWalk::isInteriorTerminalHandle` clause (I1) — which needs
; `isTemplateProducer` AND a `cq_template_`-prefixed callee. A `cqrt_alloc_<W>`
; merge out-rail fails both, exactly as a root mint does. The hoisted
; `cq_template_mul_i32_hl` rail of
; `control_phase_kickback_inloop_reject_hoisted_temp.ll` is what (I1) ADMITS, so
; it is what this clause must not, and that file is still green and still leaking.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The 4.4 select merge lowers first (round 1) and mints `%out`.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(

; The ROLLED body, in order, with the per-iteration discharge that was missing.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ THE ASSERTION. ZERO before the fix; every other directive in this file
; passed at that HEAD.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; Three frees: the 4.4 compare flag, then the body's bit rail + flag. An extra
; `cqrt_free` is a hidden measurement (Rule 6).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Four `cqrt_x`: the 4.4 merge's two polarity brackets and the kickback's ¬flag
; bracket. An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

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

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2
  %2 = icmp sgt i32 %1, 5
  %3 = select i1 %2, i32 7, i32 5
  br label %6

4:                                                ; preds = %12
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #2
  ret i32 %5

6:                                                ; preds = %0, %12
  %7 = phi i32 [ 0, %0 ], [ %13, %12 ]
  %8 = shl nuw nsw i32 1, %7
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef 2.500000e-01) #2
  br label %12

12:                                               ; preds = %6, %11
  %13 = add nuw nsw i32 %7, 1
  %14 = icmp eq i32 %13, 3
  br i1 %14, label %4, label %6, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
