; control_phase_kickback_ifelse_tail_phi.ll — ACCEPT. THE MERGE-TAIL ANGLE PHI —
; P2 spelled as a `phi double` rather than a `select` (orchestrator decision (1),
; 2026-09-05, on the prep-b measurement OQ-7 / finding 3(b)).
;
; This module is `clang -O1`'s OUTPUT for `tests/e2e/slice_control_phase_ifelse_
; derived.c`, transcribed. ⚠ THE COMMITTED COPY OF THAT SLICE IS STILL ON THE
; RETIRED SURFACE (`q = cq_phi(q, 0.9)`), so `clang` refuses it here and the
; transcription cannot be re-derived from the tree as it stands; the rewritten
; slice lands with branch `3qlq-inc1-slices` (prep-b), merged before this epic's
; commit (Rule-13 round-2 finding F-R2-4). The IR below is what this file
; asserts on, and it stands on its own:
;
;     cq_phi(0.9);                                  // pre-region: a global phase
;     if (q > 5) { cq_phi(0.25); cq_phi(0.125); }   // TWO gates in the true arm
;     else       { cq_phi(0.75); }
;
; `-O1` does NOT always fold an if/else into a `select` over the angle. When the
; arms differ by more than the angle it leaves a DIAMOND and sinks the LAST gate
; of each arm into the merge with its angle MUXED BY A PHI:
;
;     %5 = phi double [ 1.250000e-01, %arm ], [ 7.500000e-01, %pred ]
;     call void @cq_phi(double %5)
;
; That is the same lowering as the `select` spelling — one `cqrt_rz_i1` per
; incoming, on the region's own flag, bracketed by THAT INCOMING's polarity — and
; it needs no arithmetic, so nothing of 2b's arm-value fence applies.
;
; ⚠ THIS SHAPE FOUND A BROKEN MODULE IN THIS INCREMENT BEFORE IT SHIPPED, and
; that is why `phaseAngleTail` is a CORRECTNESS FENCE and not only a widening.
; The pre-refinement classifier never looked at the merge's phis, so it ACCEPTED
; this program and `flattenRegion` spliced the merge block away with the
; `phi double` still standing in it: `PHI nodes not grouped at top of basic
; block!`. ⚠ NOT "at `opt` exit 0" — that spelling shipped in this header and is
; MEASURED FALSE (Rule-13 round-1 finding F-L3-5, re-flagged for this file by
; round-2 finding F-R2-3, which found the claim still standing in two fixture
; headers after the two SOURCE comments were corrected). `cq-opt` builds
; `CQLoweringPass -> VerifierPass -> print` and `VerifierPass`'s default
; `FatalErrors=true` makes a failure a `report_fatal_error`: the process ABORTS
; with `LLVM ERROR: Broken module found, compilation aborted!`, **exit 134
; (SIGABRT)**, and NO module is written. A broken module is LOUD; what it is not
; is a DECLINE, and Rule 1 wants a decline. Every φ in the merge is now accounted
; for — this one, which the emitter erases before the flatten, or the region is
; NotApplicable.
;
; NOTE the uncontrolled `cq_phi(0.9)` before the region: it is a GLOBAL phase and
; is DELETED (owner decision D2), which is why no gate for it appears below.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll


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

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(



; ── THE BRANCH-PHASE RECORD, COUNTED — Rule-13 round-2, the `g_drop_mark`
; injection. Round 1's F-L7-1 was a CONFIRMED miscompile in which the whole-DAG
; spine ADJOINTED a kickback gate and cancelled the user's phase exactly; the
; `!cq.branchphase` record on every emitted gate is what stops it. Dropping that
; record from one gate was CAUGHT by 15 of the 35 gate-bearing accepts and MISSED
; by 20 — including every P4 nest but one and every P5 switch but one. MDCNT
; counts the GATES and MDTAG the MARKED gates, in SEPARATE prefixes, and they
; must agree. (An unmarked gate BEFORE a marked one moves only MDCNT; a dropped
; mark moves only MDTAG; an extra marked gate after moves both — round-2 F-R2-11.)
; MDCNT-COUNT-3: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-3: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  call void @cq_phi(double 9.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 2.500000e-01)
  br label %merge
merge:
  %a = phi double [ 1.250000e-01, %arm ], [ 7.500000e-01, %entry ]
  call void @cq_phi(double %a)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ONE flag; the arm's own gate and the phi's ARM incoming fire on f, the phi's
; PRED incoming fires on ¬f and carries the bracket. `P(0.25)·P(0.125)` on the
; true branch, `P(0.75)` on the false one — exactly the source, with no
; arithmetic performed on any angle.
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 1.250000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so every count lives in its own GCNT prefix and NOROUTE carries no positives).
;
; The four things a register-free kickback must NEVER emit:
;   * a route of any kind — the whole point is that no work rail exists;
;   * a `_controlled` gate — the gate is UNCONTROLLED, on the flag ancilla;
;   * `cqrt_rz_<W>` for W != i1 — the TENSORED per-register Rz is the defect
;     this increment removes (PRD §1: it marks `(-1)^popcount(target)` and can
;     never mark |0..0>, which made every Grover golden the identity on q);
;   * a surviving `@cq_phi` CALL — it is lowered here or deleted (D2), never
;     left for the linker.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; ⚠ ONE COMPLEMENT PATTERN, NOT SIX ENUMERATED WIDTHS — Rule-13 round-1 findings
; F-L6-4 / F-L8-1 / F-L4-2. The shipped ABI has NINE Rz widths
; (`runtime/cq_runtime.h`: i1, i8, i16, i32, i64, f16, f32, f64, f80) and the
; enumeration listed SIX: `f16` and `f80` were absent from ALL of these fixtures,
; so the block's own claim ("no TENSORED Rz at any width") was 6/8 true.
; MEASURED by injection into this file's own pass output: `cqrt_rz_i32` was
; caught, `cqrt_rz_i1` was caught by the count prefix, and `cqrt_rz_f80` /
; `cqrt_rz_f16` were NOT. The regex below is validated in BOTH directions —
; it fires on an injected `cqrt_rz_i16` and does NOT fire on the clean output's
; `cqrt_rz_i1`, which is the one case a bare prefix test gets wrong (`cqrt_rz_i1`
; is a textual prefix of `cqrt_rz_i16`), so the trailing `(` is load-bearing.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: = phi double

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-3: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_x(
; C2-NOT:     call void @cqrt_x(
; C3-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; C3-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(
; C4-COUNT-1: call void @cqrt_free(
; C4-NOT:     call void @cqrt_free(
