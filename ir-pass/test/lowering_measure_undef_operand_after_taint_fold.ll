; lowering_measure_undef_operand_after_taint_fold.ll — ACCEPT, and it pins the
; DISCLOSED SHAPE: a measurement the author wrote OF A QUANTUM REGISTER is
; lowered as a classical zero and is ABSENT from the emitted circuit.
;
; bd test_C_libtooling-fve8, owner ruling 2026-09-15 `DECISIONS.md` **E9**
; (ACCEPT, AND DISCLOSE THE QUANTUM RIVAL), on the P1 `F-E2-1` of the
; independent Rule-13 round `review_r13_e2/REVIEW.md` §1. The disclosure it
; belongs to is at the mechanism in `MeasureLowering.cpp` (clause (1a),
; "RIVAL 2 (QUANTUM)"); the normative copy is `$SES/trackE2/IMPL_E2.md` §6 as
; extended by `$SES/e2fix/FIX.md` §1.
;
; ── THE PROGRAM, NOT THE IR SHAPE ────────────────────────────────────────────
;
;     int u; int q = 0; cq_theta(&q, 0.3); return cq_measure(q + u);
;
; The module below is that program's linked stage 1: `clang -O1` folds
; `add nsw i32 %q, undef` → `undef`, and THE FOLD DELETES THE DATA-FLOW EDGE TO
; THE THETA. So `taint.Tainted` is correct in saying the measure operand has no
; quantum lineage, branch (1) is entered legitimately, and clause (1a) reports
; the type's zero. The user's measurement is not declined, not diagnosed, and
; not emitted — it is GONE, and stderr is 0 bytes.
;
; ⚠ THIS FIXTURE IS NOT A CELEBRATION OF A CAPABILITY. It exists because it is
; the only artefact in the tree that makes the next reader SEE this shape
; (REVIEW §1: "whichever way the owner rules, the first fixture must exist").
; Rule 5's hard invariant — never INSERT a measurement the user did not write —
; is intact here; its MIRROR is not.
;
; ── WHY THE OWNER RULED ACCEPT (the two grounds, both measured) ───────────────
;   1. THE CLASS PRE-EXISTS AT HEAD. `cq_measure(q * u)` and `cq_measure(q & u)`
;      fold to a CONCRETE `0` at stage 1 — not to `undef` — so they enter the
;      same classical branch with a defined operand and ALREADY SHIP THIS EXACT
;      2-LINE STREAM ON THE SESSION ORACLE (equal trace sha `684d2394674bd01b`).
;      A decline here would be a NEW refusal that leaves those two untouched.
;   2. After `-O1` no predicate can separate the readings: the discriminator
;      would have to be "this operand ONCE carried taint", and the fold has
;      already erased the edge that fact lived on (CLAUDE.md L5). The mitigation
;      is DISCLOSURE, not a fence — and NO WARNING (owner, twice on this
;      family).
;
; ⚠ THE TRACK'S REFINEMENT INSTRUMENT CANNOT SEE THIS MODULE.
; `$SES/trackE2/probes/refinement_check.py` reports it BYTE-IDENTICAL, because
; its one-token twin rewrites the measure operand of THE MODULE THE PASS SEES
; and therefore INHERITS THE VERY FOLD THAT ERASED THE TAINT. CLAUDE.md L10 on
; a checker this repo ships. Do not cite "0 divergences" as covering this.
;
; ── RED-GREEN ────────────────────────────────────────────────────────────────
; On the session ORACLE (`main` 74eabd2c, `cq-opt` 0e280fc6) this module is a
; DECLINE — `cq_measure_<sfx> operand is an undef/poison literal; a classical
; measurement needs a defined value` — so this file is RED there on the EXIT
; CODE (stdout is 0 bytes and every prefix below fails).
;
; ── MUTATION VALIDATION (Rule 12: by mutation, never by re-reading prefixes) ──
; Change the ONE token `undef` on the `@cq_measure_si32` line to `%1` — the
; theta's result, i.e. the program the source names once `u` is initialised —
; and this file goes RED: `NOMEASURE` fails, because the measurement is then
; emitted. That mutant is committed as its own fixture,
; `lowering_measure_taint_fold_control.ll`, which is GREEN on BOTH binaries.
; The pair is the subject: one token apart, one emits the user's measurement
; and one does not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMEASURE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINTR < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main() {
  %1 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = call i32 @cq_measure_si32(i32 noundef undef)
  ret i32 %2
}
; the quantum content the ORACLE never reached (the decline PREEMPTED the whole
; module — `LLVMContext::diagnose` EXITS on the first `DS_Error`, bd `br4a`) is
; lowered, and the user's measurement is answered with the type's zero:
; CHECK-LABEL: define i32 @main()
; CHECK:         %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:         call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
; CHECK:         ret i32 0

; ── WHOLE-FILE PREFIXES (Rule 12 (a): a positive count WINDOWS every negative
; that follows it inside the same prefix, so each gets its own) ───────────────
;
; exactly one rail and one rotation — the theta's — and no second one minted
; for the classical measure. ⚠ each pattern names the CALL, never the bare
; symbol: the lowered module also carries a `declare` for each.
; COUNT-COUNT-1: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-NOT: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-COUNT-1: cqrt_ry_i32(i32 %h
; COUNT-NOT: cqrt_ry_i32(i32 %h
;
; ⚠ THE POINT OF THE FILE. There is no measurement gate ANYWHERE in the emitted
; module — not a call and not even a `declare`, because `measureRtFn` (which
; lazily declares `@cqrt_measure_<W>`) is only reached inside the QUANTUM
; branch. The user wrote one. It is not here.
; ⚠ NOT a vacuity risk in the bd `qta2` sense: this module's own `; ModuleID` /
; `source_filename` lines carry the FILE PATH, and the path contains `measure`
; but never `cqrt_measure`.
; NOMEASURE-NOT: cqrt_measure
;
; every front-end intrinsic call is gone (Rule 1's checked postcondition,
; `declineSurvivingIntrinsicCalls`):
; NOINTR-NOT: call{{.*}}@cq_measure_
; NOINTR-NOT: call{{.*}}@cq_theta_
;
; and the module accepts SILENTLY — 0 bytes of stderr, no warning. The owner
; ruled against a warning on this family twice, and `DECISIONS.md` E9 repeats it
; for exactly this shape:
; ACC-NOT: undef/poison literal
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: warning
