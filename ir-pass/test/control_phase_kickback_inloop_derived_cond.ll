; control_phase_kickback_inloop_derived_cond.ll — ACCEPT, and the pin for the
; Rule-13 round-1 CONFIRMED MISCOMPILE F-L7-2 / F-L5-1 / F-L2-1b (bd
; test_C_libtooling-3qlq Inc 1 part A; found by three lenses and by the
; orchestrator's own per-bit measurement).
;
;     for (int i = 0; i < 4; ++i) if ((q >> i) & 1) cq_phi(0.3);
;
; `clang -O1` output verbatim. This is owner decision D4's PER-BIT IDIOM — the
; ONE way the register-free surface expresses a register-wide Z — rolled at K=4.
;
; WHAT WENT WRONG. The body puts NO gate on `q`, so `q` is loop-INVARIANT, the
; header carries no tainted phi, `collapseRailPhisIn` finds nothing to collapse,
; `markIfRailLocal` is never called, and `Uncomputation.cpp`'s
; `if (canRepeat(&BB) && !IterationLocalBlocks.count(&BB)) continue;` SILENTLY
; skipped the body's interior candidate. MEASURED: K derived condition rails
; (`cq_template_and_i32_hl(h, 1<<i)`) minted and NEVER `_unc`-reversed, never
; freed — 4 of them at K=4, 32 at K=32 — while the HAND-UNROLLED spelling of the
; same source discharged all K.
;
; NOT A "RULE-6 SAFE LEAK". Each leaked rail holds one BIT of `q`, a which-path
; record, and this idiom exists to be a Grover phase oracle whose next step is a
; diffusion that interferes different `x`. Rule 8: "a permutation that leaves a
; rail dirty AND entangled still dephases under later interference." Rolled and
; unrolled were DIFFERENT UNITARIES — the 8h7d.5 F-4 signature — and both shipped
; gates were blind: `opt` exit 0, verify-clean, and STRICT
; `free_pairing_check.py` reported `0 violation(s)` because the leaked rail has no
; `cqrt_alloc` and was never counted as minted (its own header says so).
;
; IT WAS A REGRESSION, NOT AN INHERITED HAZARD. Under the retired register
; surface `q = cq_phi(q, θ)` in the arm made `q` LOOP-CARRIED, so the collapse
; claimed it, the body was marked, and the pre-3qlq oracle emitted the discharging
; stream for the same program (MEASURED on $SP/wt/pre-3qlq).
;
; THE FIX is `LoopLowering::invariantRegisterRoots`: it supplies `markIfRailLocal`
; — UNCHANGED — with the `Roots` a loop-carried rail would have supplied, for a
; loop whose registers are loop-INVARIANT, and admits ONLY a ROOT MINT (a
; classical-arg-0 `cq_theta`, peeled through in-place gates). See
; `control_phase_kickback_inloop_reject_hoisted_temp.ll`, which is the
; discriminating control for the one thing that restriction refuses.
;
; THE REAL WITNESS IS THE e2e ROLLED == UNROLLED BYTE-DIFF, not this file: at K=4
; the rolled trace is now BYTE-IDENTICAL to its hand-unrolled twin (39 lines,
; 4 `and` mints / 4 `and_unc` / 8 frees on both), and at K=32 all 32 discharge.
; This fixture pins the IR-level shape so the class cannot silently return.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; ROLLED — the whole region plus the in-body discharge sits inside ONE block that
; the back edge re-enters, so IR size is independent of K.
; CHECK: %[[OP:.*]] = call i32 @cq_template_and_i32_hl(i32 %h, i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OP]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[OP]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[OP]], i32 %h, i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ONE phase gate in the rolled body.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; THE SHARP END — ONE derived-condition discharge per activation. Before the fix
; this count was ZERO and every other directive in this file still passed.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; TWO frees per trip: the derived rail and the flag. The register `q` is NOT one
; of them (it is measured, and it is alloc-minted — clause I1).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: double -
; NOROUTE-NOT: fneg


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.

; The `cqrt_x` census. An UNPAIRED bracket is a wrong-branch phase.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  br label %4

2:                                                ; preds = %10
  %3 = tail call i32 @cq_measure_si32(i32 noundef %1) #1
  ret i32 %3

4:                                                ; preds = %0, %10
  %5 = phi i32 [ 0, %0 ], [ %11, %10 ]
  %6 = shl nuw nsw i32 1, %5
  %7 = and i32 %6, %1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %10, label %9

9:                                                ; preds = %4
  tail call void @cq_phi(double noundef 3.000000e-01) #1
  br label %10

10:                                               ; preds = %4, %9
  %11 = add nuw nsw i32 %5, 1
  %12 = icmp eq i32 %11, 4
  br i1 %12, label %2, label %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
