; control_phase_kickback_onward_merge.ll — ACCEPT, and the pin for the Rule-13
; ROUND-1 CONFIRMED SILENT MISCOMPILE F-L3-1 (bd test_C_libtooling-3qlq Inc 1
; part A, lens L3).
;
;     int slice(void) {
;         int q = 3; cq_theta(&q, 0.5);
;         int y = 5;
;         if (q > 5) y = ext_f(7);                     // 6.5 classical-call arm -> %out
;         if (y > 50) cq_phi(0.9); else cq_phi(0.3);   // P2 on the ONWARD rail
;         return cq_measure(y);
;     }
;
; This module is `clang -O1` + `llvm-link` output verbatim (the same two-TU
; harness the shipped `e2e-slice-control-cond-onward-ctl-phase` uses), with
; `ext_f`'s body linked in so the fixture is self-contained.
;
; WHAT WENT WRONG. `deleteGlobalPhases` (P7) ran immediately after
; `lowerControlRegions`, which is BEFORE `repropagateControlMerges` — and that
; stage's `detectAndLowerOnwardControl` is a SECOND, FULL round of
; `detectControlRegions` + `lowerControlRegions`. The second region's condition
; reads the 6.5 arm's `%out` rail, so at round 1 it is CLASSICAL and its `cq_phi`
; was deleted as a "global phase" BEFORE its region had ever been looked at.
;
; TWO defects came out of that one deletion, and the second is worse than the
; first — (1) the branch phase P(0.9)/P(0.3) vanished; and (2) with its only
; consumer gone, the ANGLE `select` was re-classified at round 2 as plain fp DATA
; and lowered through the 4.4/kjd1 merge — MEASURED
; `cqrt_alloc_f64(0x1.ccccccccccccdp-1)` … `cqrt_copy_f64_controlled(...)`, i.e. a
; ROTATION ANGLE materialised on a quantum f64 rail, an operand of nothing and
; never freed. That is the Rule-3 wire-crossing `CLAUDE.md` names outright: "a
; floating-point merge phi is an angle, not data — do not cross these wires." (wording retired from CLAUDE.md R3 on 2026-10-08: fp merge values can carry data; angle use is decided at rotation consumers)
; `opt` exit 0, verify-clean, STRICT stage 2b PASS, linked, 23 trace lines.
;
; NEITHER FENCE COULD SEE IT, both for structural reasons: at the old position the
; onward branch's condition is not yet in `taint.Tainted`, so the Rule-1 assert's
; `reachedThroughTaintedBranch` had nothing to find; and the ROUND-1 tainted `br`
; that walk would otherwise have found on the predecessor path had already been
; ERASED by its own region's flatten.
;
; THE FIX IS THE STAGE'S POSITION: `deleteGlobalPhases` now runs AFTER
; `repropagateControlMerges` in both pipeline entry points, so P7's stated premise
; ("every tainted br has been claimed or declined; a survivor is under classical
; control only") is true rather than aspirational, and the Rule-1 assert is asked
; with ROUND-2 taint on the ROUND-2 CFG.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; THE ROUND-1 6.5 CLASSICAL-CALL ARM, ASSERTED FIRST — Rule-13 round-2 finding
; F-R2-8. This chain used to start at the SECOND region, leaving the round-1
; region in the same function entirely unasserted while the fixture's whole point
; is the INTERACTION between the two rounds. The classical call is HOISTED (it is
; pure — 6.5), the flag is minted from `%h`, `%out` is the |0> merge rail, and the
; two arms are controlled copies with a `cqrt_x` bracket around the false one.
; CHECK: %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @ext_f(i32 noundef 7)
; CHECK-NEXT: %[[F1:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])

; The onward region lowers as an ordinary P2 angle select on the %out rail:
; the false-arm angle inside the cqrt_x bracket, the true-arm angle outside it.
; CHECK-NEXT: %[[F2:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 50)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[OUT]], i32 50)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])

; Two phase gates per inlined copy of the region; the module carries the same
; program twice (`@slice` and `@main`), hence four.
; ACNT-COUNT-4: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE. The f64 assertions are the sharp end:
; they are what the pre-fix binary emitted instead of a phase.
; NOROUTE-NOT: cqrt_alloc_f64
; NOROUTE-NOT: cqrt_copy_f64_controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: double -


; Function Attrs: nounwind ssp uwtable

; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: call void @cqrt_cswap(

; The `cqrt_x` census. An UNPAIRED bracket is a wrong-branch phase.
; XCNT-COUNT-8: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(


define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = icmp sgt i32 %6, 50
  %8 = select i1 %7, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %8) #3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = icmp sgt i32 %6, 50
  %8 = select i1 %7, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %8) #3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  ret i32 0
}

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
