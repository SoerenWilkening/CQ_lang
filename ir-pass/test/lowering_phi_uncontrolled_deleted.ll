; lowering_phi_uncontrolled_deleted.ll — ACCEPT. P7: an UNCONTROLLED or
; CLASSICALLY-CONTROLLED `cq_phi` is a GLOBAL PHASE and is DELETED (PRD §6.2 row
; P7, owner decision D2). A documented semantic, NOT a diagnostic — owner question
; Q2's assumed answer is "no remark".
;
; `cq_phi(θ)` means "multiply the amplitude of the CURRENT BRANCH by e^{iθ}". With
; no tainted condition above it there is only one branch — the whole state — so
; the operation is a global phase: unobservable, and therefore removable.
;
; BOTH SPELLINGS ARE HERE and both must go: the straight-line call, and one under
; a CLASSICAL (`volatile int`) branch, which is equally a global phase because the
; classical condition has a definite value on any run.
;
; POSITION IS THE SOUNDNESS ARGUMENT (`deleteGlobalPhases` runs immediately after
; `lowerControlRegions`): by then `detectControlRegions` has CLAIMED every tainted
; `br`/`switch` — and its emitter erased the phase call it claimed — or DECLINED
; it loudly, Rule 1's "there is no third path". A SURVIVOR therefore sits under
; classical control only, and that is ASSERTED rather than assumed: a survivor
; reachable through a tainted branch condition declines `unclaimed branch phase
; under quantum control` instead of vanishing (PRD §10.3 lens 4).
;
; The module must also leave NO `@cq_phi` declaration behind — an unresolved
; extern is a Stage-3 LINK error, which is why `PhaseCalls` is in the pass's
; passthrough early-out predicate.
;
; ⚠ THE `unclaimed branch phase` BRANCH IS UNREACHED BY THE WHOLE CORPUS, AND
; SAYING SO IS THE POINT (Rule-13 round-1 finding F-L8-3). That string has NO
; fixture — three files, this one among them, mention it in PROSE and none
; exercises it. It is Rule 1's assert inside `deleteGlobalPhases`: a surviving
; `cq_phi` whose block is reachable through a TAINTED branch condition. Lens L3
; probed 90+ shapes and could not reach it, for a structural reason worth
; carrying — every region kind that CLAIMS a tainted `br` also REMOVES it (the
; flatten, the abort park's `br label`, the loop lowering's bound), and every
; kind that declines exits `opt` at its first `DS_Error` — so on every reachable
; program state there is no tainted `br` left to find. Constructing a module that
; reaches it would itself be a third-path finding, not a fixture.
; The assert is nonetheless KEPT and is now correctly POSITIONED (F-L3-1 moved
; `deleteGlobalPhases` after the round-2 control fixpoint, which is where its
; premise is true), because the hazard it was written for is real: at the old
; position it could not see an ONWARD region's tainted branch at all, and that
; was the round's second CONFIRMED miscompile.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; NOROUTE-NOT: call void @cqrt_x(i32
; NOROUTE-NOT: call void @cqrt_free(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

@cc = external global i32

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  call void @cq_phi(double 4.000000e-01)
  %cv = load volatile i32, ptr @cc, align 4
  %c = icmp eq i32 %cv, 0
  br i1 %c, label %merge, label %arm
arm:
  call void @cq_phi(double 6.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The Ry that made `q` quantum is untouched; nothing else is emitted for the two
; deleted phases — no gate, no flag, no ancilla.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)

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
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: cqrt_free
; ⚠ AND `cqrt_x` (F-L8-2). A DELETED global phase must leave NOTHING behind —
; no gate, no bracket, no rail. Without this line an emitted polarity bracket
; would have passed every directive in this file silently.
; NOROUTE-NOT: cqrt_x(

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call i32 @cqrt_alloc_i32(
; C1-NOT:     call i32 @cqrt_alloc_i32(
; C2-COUNT-1: call void @cqrt_ry_i32(
; C2-NOT:     call void @cqrt_ry_i32(
