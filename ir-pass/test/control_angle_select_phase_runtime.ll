; control_angle_select_phase_runtime.ll — ACCEPT. RUN-TIME ANGLE ARMS, admitted
; for the REGISTER-FREE PHASE stem and ONLY for it (PRD §12 owner question Q3,
; assumed answer YES; §3 "Angle select").
;
; THE TWO STEMS NOW HAVE OPPOSITE DISPOSITIONS ON ONE INPUT SHAPE, so pin both
; directions. Its twin `control_angle_select_ry_reject_runtime_arms.ll` is the Ry
; half and still DECLINES; deleting either file leaves the split unpinned.
;
; WHY THE SPLIT IS THE ARITHMETIC AND NOT A POLICY. 2b's Ry lowering emits an
; unconditional `R(h, B)` plus ONE `R_controlled(f, h, A−B)`, so it must COMPUTE
; `A − B`. The clearance review (blocker F-11) measured what that costs with
; run-time arms: the realized true-arm angle is `B + fl(A−B)`, whose error is
; unbounded in ABSOLUTE radians — 0.858 rad from plain C with π and 1e16, i.e.
; `Ry(π)` realized as `Ry(4.0)` — and `fl(A−B)` can be `inf` from two FINITE arms
; (±8.99e307). Neither is fenceable at compile time, so run-time arms were
; narrowed OUT.
;
; THIS STEM SUBTRACTS NOTHING. Each arm's value is passed VERBATIM into its own
; `cqrt_rz_i1`, so `%a` and `%b` appear in the emitted gates unchanged and no
; `fsub` exists anywhere in the module. There is no rounding residual to bound,
; and `angleSelectArmsAdmissible` — the whole fence — is not asked at all.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
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



; ── THE BRANCH-PHASE RECORD, COUNTED — Rule-13 round-2 finding F-R2-7 ────────
; The `!cq.branchphase` record is what stops the whole-DAG spine adjointing a
; kickback gate (round-1 F-L7-1, a CONFIRMED miscompile that cancelled the user's
; phase EXACTLY). It is minted at SIX emission sites, and until this file grew
; the two directives below the `AngleSelectEmit` stem — TWO of those six —
; was pinned by exactly ONE fixture in 1665, whose own stated subject is the
; deliberate `inf`-arm pass-through. Dropping the mark at `AngleSelectEmit.cpp`
; reddened one file. It now reddens three, and the two flagship P2 accepts are
; two of them.
;
; MDCNT counts the GATES, MDTAG counts the MARKED gates, in separate prefixes so
; the two questions cannot be answered by one directive. They must AGREE. (Read
; the pair precisely — round-2 F-R2-11: an unmarked gate BEFORE the marked one
; moves only MDCNT, a dropped mark moves only MDTAG, and an extra marked gate
; after moves both. All three are caught; only the second is what F-L7-1 was.)
; MDCNT-COUNT-2: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-2: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %a, double %b
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE ARMS ARE PASSED THROUGH, BY SSA NAME — this is the assertion that separates
; this lowering from the by-difference one: `%a` and `%b` themselves reach the
; gates, so no value the source did not name enters a gate slot.
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %b), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %a), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
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
; NOROUTE-NOT: fsub
; NOROUTE-NOT: = select

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-2: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_x(
; C2-NOT:     call void @cqrt_x(
; C3-COUNT-1: call void @cqrt_free(
; C3-NOT:     call void @cqrt_free(
