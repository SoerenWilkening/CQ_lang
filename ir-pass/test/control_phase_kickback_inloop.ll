; control_phase_kickback_inloop.ll — ACCEPT, ROLLED. P6: a kickback region inside
; a classically-bounded loop (PRD §6.2 row P6; the 8h7d.5 rolled in-loop path).
;
; ⚠ READ THE NEXT PARAGRAPH BEFORE THIS FILE'S ASSERTIONS. Its module is
; HAND-WRITTEN IR that `clang -O1` DOES NOT PRODUCE, and its original header
; called it "Grover written as `for (i = 0; i < K; i++) { oracle; diffusion; }`"
; — there is no diffusion in it and NO GATE ON THE REGISTER AT ALL (Rule-13
; round-1 finding F-L5-3). The compare sits in the loop HEADER on a `%q0` defined
; in `entry`; from C, `for (…) { if (q == k) cq_phi(θ); }` with `q` untouched in
; the body has a LOOP-INVARIANT condition register, so `-O1` LICM-hoists that
; compare into the PREHEADER and `condWireDisposition`'s P4 precondition
; (`Cond->getParent() != R.Pred`) returns `DeclineNow` — the program declines
; `condition predates a non-diagonal gate under quantum control`. That is bd
; `drbq.12`'s over-decline arriving at the PHASE stem, where it did not exist
; before — under the register surface a phase arm always gated `q`, so the
; register was loop-VARIANT; under kickback a pure-phase body never gates it.
;
; So this file pins the ROLLED EMISSION SHAPE and nothing about reachability.
; The two files that carry the reachable halves are
; `control_phase_kickback_inloop_body_gate.ll` (ACCEPT — the shape `-O1` really
; produces for a rolled Grover, where the body's own `cq_theta` diffusion makes
; the register loop-variant) and
; `control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` (DECLINE — the
; hoisted-compare class, whose Ry-stem twin has had a fixture since drbq Inc 3
; and whose phase-stem twin had none).
;
; The region is admitted only through `flatRegionRollableInLoop` — the SAME 8h7d.5
; predicate the flat phase path uses, asked from the kickback classifier's own
; pre-peel rather than re-spelled (Rule 14; it is declared in `ControlShape.h` for
; that reason). Everything else on a cycle (irreducible, multi-latch, nested)
; keeps its existing decline and its existing string.
;
; WHAT A KICKBACK NEEDS FROM THE ROUND-2 RAIL COLLAPSE: NOTHING. It emits no gate
; on the loop-carried register at all, so `collapseFlattenedLoopRails` finds
; nothing to collapse for it and `staleRailRecordRead` has no rail record to
; invalidate. Every ancilla it mints — the flag — is stripped and freed INSIDE the
; iteration, so nothing crosses the back edge.
;
; THE PROPERTY THIS PINS is that the BACK EDGE SURVIVES and the body holds
; EXACTLY ONE `cqrt_rz_i1`: the IR is rolled, not unrolled, so its size is
; independent of the trip count (MEASURED elsewhere in this increment at K=3 and
; K=1000: 25 identical `@slice` lines).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C5 < %t.cqd0.ll
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
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c = icmp eq i32 %q0, 5
  br i1 %c, label %arm, label %body
arm:
  call void @cq_phi(double 3.14159265358979323846)
  br label %body
body:
  br label %latch
latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %q0)
  ret i32 %m
}

; THE LOOP IS STILL A LOOP — the header phi survives — and the mint / gate /
; strip / free quadruple sits INSIDE its body, ONCE. Every one of those four is
; per-iteration, so no ancilla crosses the back edge.
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %{{.*}} ], [ %{{.*}}, %latch ]
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; …and the BACK EDGE is intact: the latch still re-enters the header.
; CHECK:      br i1 %{{.*}}, label %exit, label %head

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so every count lives in its own C<n> prefix and NOROUTE carries no positives;
; the prefixes are C1..C5, not the `GCNT` this line used to name — F-L4-2).
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
; ⚠ AND THE UNPAIRED-POLARITY NEGATIVE, ADDED BY THE RULE-13 ROUND-1 REVIEW
; (F-L8-2). This shape emits NO `cqrt_x` at all — its arm is the TRUE successor —
; so an injected or mis-emitted bracket gate would have passed every directive in
; this file silently. A `cqrt_x` on the flag is not cosmetic: an UNPAIRED one
; inverts which branch the phase lands on, i.e. a different unitary.
; NOROUTE-NOT: call void @cqrt_x(

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-1: call i32 @cq_template_icmp_eq_i32_hl(
; C2-NOT:     call i32 @cq_template_icmp_eq_i32_hl(
; C3-COUNT-1: call void @cq_template_icmp_eq_i32_hl_unc(
; C3-NOT:     call void @cq_template_icmp_eq_i32_hl_unc(
; C4-COUNT-1: call void @cqrt_free(
; C4-NOT:     call void @cqrt_free(
; C5-COUNT-1: br label %head
; C5-NOT:     br label %head
