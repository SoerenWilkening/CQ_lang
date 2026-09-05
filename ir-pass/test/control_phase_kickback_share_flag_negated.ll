; control_phase_kickback_share_flag_negated.ll — ACCEPT, and the CONTROL that
; keeps the F-L7-1 fix a statement about MEMBERSHIP rather than about polarity
; (bd test_C_libtooling-3qlq Inc 1 part A, Rule-13 round-1 lens L1 §F-L1-1).
;
;     int q = cq_theta(3, 0.5);
;     int f = (q > 5);                        // DATA use of the compare
;     if (!f) { cq_phi(0.25); cq_phi(0.75); } // the arm is the FALSE successor
;     return cq_measure(q + f);
;
; `clang -O1` output verbatim (`$SP/progress/review_r1_L1/probes/
; u6_datause_negshare.c`). SAME ziov shared-flag path as
; `control_phase_kickback_share_flag.ll`, OPPOSITE arm polarity — so the emitter
; brackets the two gates with `cqrt_x(f)`.
;
; WHY THIS FILE EXISTS. Before the fix, lens L1 MEASURED that F-L7-1 was
; POLARITY-DEPENDENT: this spelling was CORRECT and its un-negated twin was not.
; The reason was an accident, not a fence — `ChainWalk::isInPlaceGateOn`
; deliberately does not recognise `cqrt_x`, so a bracketed flag carried an
; UNRECOGNIZED consumer, the DAG went `NotClosed`, and nothing was inverted. A
; user's phase survived or did not according to which branch polarity
; `clang -O1` happened to canonicalize to.
;
; Post-fix BOTH polarities are correct for ONE reason (the `!cq.branchphase`
; record), and this file is what proves the claim is not vacuous: it is the
; polarity that was ALREADY green, so it must stay green and must stay
; negative-angle-free. Its emitted stream is BYTE-IDENTICAL before and after the
; fix (MEASURED: `diff` of the two traces is empty) — the fix moved the reason,
; not the output, on this half. Stated exactly, because red-green matters:
; against the PRE-FIX binary this file reddens on the `!cq.branchphase` assertion
; ALONE (line 43) — every other directive, including the whole-file negatives,
; passes there. That is the honest statement of what it pins on this half: THE
; RECORD, whose absence is what made the OTHER polarity wrong.
;
; It also pins lens L1's F-L1-3 correction: N gates in ONE arm take ONE bracket
; pair, not one per gate (`cqrt_x` is self-inverse, so `x;g1;x;x;g2;x` and
; `x;g1;g2;x` are the same unitary) — two `cqrt_x`, not four.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{.*}}, i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 7.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])

; Two phase gates on the ONE flag.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; ONE bracket pair for the whole arm — F-L1-3.
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT: call void @cqrt_x(

; The FLAG is left allocated (the spine cannot close it). The `zext` DATA rail is
; a different rail with no kickback on it, and it is still discharged and freed —
; so exactly one free, and it names the cast, not the flag.
; FCNT-COUNT-1: call void @cqrt_free(i32 %h_cast)
; FCNT-NOT: call void @cqrt_free(

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: double -
; NOROUTE-NOT: fneg
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cqrt_rz_i32

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %4, label %3

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 2.500000e-01) #2
  tail call void @cq_phi(double noundef 7.500000e-01) #2
  br label %4

4:                                                ; preds = %3, %0
  %5 = zext i1 %2 to i32
  %6 = add nsw i32 %1, %5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
