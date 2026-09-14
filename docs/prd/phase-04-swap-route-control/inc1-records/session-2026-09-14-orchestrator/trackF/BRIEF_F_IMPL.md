# Track F — IMPLEMENTATION brief: the φ-DESCENDANT exclusion in F2 (bd `om35`, owner-ruled 2026-09-14)

**Owner ruling 2026-09-14, after reading your own scoping table:** build the **φ-descendant predicate of
`SCOPE_F.md` §6**, **not** R-2′ as spelled. R-2′ stays FILED as a costed capability. The owner's reason, in
their terms — they asked *"which one would result in a more general method not over-declining, so compiling
code that actually leads to valid quantum circuits?"* and accepted this answer: R-2′ admits more program
classes by raw count, but its safety rests on two **capability** fences (R3 `:4168-4170`, F1 `:3906-3915`)
that this project is actively working to remove, so its margin expires on our own roadmap, and it has a
demonstrated fp hole. The φ-descendant rule is narrow in *fixtures touched* and **general over the whole
cascade family** — any N, any threshold, constant or runtime register — which is the program family the
owner actually writes.

Worktree `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant` (created off `main` 607b6fe4).
Records: `$SES/trackF/` **in your worktree** (your scoping outputs `SCOPE_F.md`, `GATES.md` and the 163
probes are already in the MAIN checkout — copy what you need, and keep your implementation records separate
as `IMPL_F.md`). `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`;
`$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (binding), your own `$SES/trackF/SCOPE_F.md` (§6 especially),
`CLAUDE.md` (Prime Directive; Rules 1, 9, 11, **12**, **13**, 14, 17, 19; CORRECTNESS RISK §2 the F1/F2
fences, §3 **L1/L5/L8**, §4 the F2-narrowing disclosure paragraph — *what the F2 narrowing silently absorbs,
in the words it must be said in*), `bd show om35` (now carrying your scoping as its 2026-09-14 note),
`bd show rb9x` (the landed `PeelClones` conjunct — the model for where and how to add yours).

---

## 1. The predicate

At `ArmClassify.cpp:1682-1683`: **`V` is not a collider if the region's own state-prep merge φ is in `V`'s
transitive operand closure in this function.** A value that uses the φ is available neither in the arm nor on
the pred edge, so it cannot have been the register the author rotated — it did not exist yet at that point.

Measured by you: the collider **is** a φ descendant in the owner's file, in `vd.c` and in `w2.c`
(`%9 = icmp sgt i32 %8, 2` with `%8 = select i1 %6, …`); it is a φ descendant in **0 of the 25** fixtures
R-2′ would have flipped. **Expected cost: ZERO shipped fixtures flip.** If any does, STOP and report — that
is a finding about the predicate, not a fixture to update.

## 2. Where it goes, and the three things that must not happen

Model it on the landed `rb9x` conjunct (`94c085e`), whose discipline is already proven:

* **At the TEST, never at the LVI ANCHOR.** `CLAUDE.md`: *"The `CondWire` exclusion is applied at the
  equality TEST, never at the LVI ANCHOR (at the anchor, all 40 F2 fixtures flip)."* Yours sits beside
  `!CondWire.count(V)` and `!taint.isPeelClone(V)` as **ONE conjunct**.
* **Never prune the users walk.** `rb9x` kept the forward users walk intact deliberately;
  `control_peel_reject_fp_stateprep.ll` declines through `f2Model`'s conservative arm on an fp select
  reachable ONLY via the clone. Pruning would vacate that.
* **A dominance conjunct is REFUSED IN WRITING** (≥11 shipped F2 fixtures pin MERGE-BLOCK colliders:
  `range_forward_*`, `sideways_*`, `merge_edge_sideways`, `step_cap_over`). Do not reach for one.

**The argument to write in the source, in these words:** the ground is **availability**, not "same wire" —
a value in the transitive operand closure of the region's own merge φ is not available on either edge of the
region's branch, so no reading of the source can have named it as the rotated register.

## 3. Rule 13 — 2 rounds, and round 2's assignment is already written

Your scoping recorded the predicate as **recorded, not cleared**. It owes its own rival audit, and you
already named the assignment: **prove that `-O1` cannot rewrite a non-φ-dependent SOURCE value into a
φ-dependent MODULE value.** That is the L5 trap in its exact shape — a syntactic answer to a semantic
question loses, and F2 has lost four rounds running to precisely that. Hand the reviewer that question in
writing, along with the rewrites you checked (`-O1` sinks, hoists, fuses, folds selects on angles,
const-folds equality edges on both sides, rewrites compares sideways and downward, LICM-hoists, and rewrites
affine add-recurrences into closed form — `CLAUDE.md` Rule 9's list is the checklist).

**RETIREMENT TRIGGER (L8), written as a file:line condition in the source:** the predicate's single trigger
is `f2Model`'s `SelectInst` union at `:1211-1219` — if that union stops being a union, re-derive the
availability argument from scratch.

## 4. Disclosure — the §4 obligation transfers to you

`CLAUDE.md` CORRECTNESS RISK §4 records, in the words it insists on, what the *previous* F2 narrowing
silently absorbs: programs that were LOUDLY REFUSED now receive the circuit for the *other* reading with no
diagnostic, and *"the mitigation is disclosure, not a predicate"*. **Your increment owes the same paragraph**:
state, in plain terms and with the measured counts, exactly which program class stops being refused, what the
rival reading was, and why it has no lowering to be robbed of. That paragraph goes in `IMPL_F.md` and the
orchestrator will carry it into `CLAUDE.md`. Do **not** add a warning diagnostic (it would fire on every
cascade the ruling exists to enable).

## 5. Customers — these MUST compile when you are done

* **C1 — the owner's real file** `example/grover/grover_oracle_uncompute.c` (git-excluded, three bools).
  **Commit the compiling program as `tests/e2e/slice_control_cascade_three_bools.c` with its golden**, and
  record its trace-line count, STRICT stage-2b line and `opt` exit in `IMPL_F.md`.
* **C2** — `$PREV/trackR/probes/vd.c` (the `if (b0 == 1)` spelling).
* **C3** — `w2.c`, the same cascade with a **runtime** `a` (`argc + 4`): proves the class is not an IPSCCP
  artefact and that the rule holds for a **range**-derived pin, not only a constant-derived one.
* Add at least one **N=4** cascade, since the claim is generality over N.

## 6. Must stay byte-identical / must keep declining

All 29 fixtures that decline with F2's string (the 25 R-2′ would have flipped **and** the 4 that decline
through the `Truncated` disjunct at `:4155-4157`), every `control_peel_*`, the `rb9x` pair,
`control_inplace_ry_reject_stateprep_second_flag_i1.ll`, `slice_control_cascade_two_bools.expected.log`
(29 lines), `va` (19), `slice_control_stateprep_bool_under_int_compare_fused` (22). Re-run the F2 family
explicitly and report the count.

## 7. Gates you own — PROTOCOL §matrix

Configure + build once per edit batch (`cmake --build build -j8`; **never `--target CQPass` alone**); record
`shasum -a 256 build/ir-pass/cq-opt` in your `GATES.md` after every rebuild. Inner loop = `lit --filter` +
single slices. ONCE at hand-off: `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT corpus sweep →
`$SES/trackF/probes/corpus_<hash16>.txt`, one injection matrix with MISSED reported. **NEVER** the full
suite, `^e2e-`, or the equivalence sweep.

⚠ **Expected corpus movers:** DECLINE→ACCEPT rows whose ORACLE string was `state prep seed is proven equal to
the condition register under quantum control`, **and only on cascade shapes**. Any other mover is a FINDING.

⚠ **Track P (bd `3qps`/`4aiu`) is editing `ArmClassify.cpp` in parallel** — the phase-kickback classifier, a
different region of the file from F2's test. You are in the SAME merge GROUP and will be merged together;
keep your edit localized and do not refactor shared helpers. If you must touch something Track P plausibly
touches, say so in your report.

## 8. Deliverables

`$SES/trackF/{IMPL_F.md, GATES.md, probes/}` in your worktree: the conjunct as spelled, the availability
argument, the L1 answer (does the plan's committed region record exist at round 1, round 2, or both — and is
the re-ask owed in both entry points?), the disclosure paragraph of §4, the customer table with measured
traces, the must-not-move count, the corpus movers, the mutation MISSED count, the round-2 assignment for the
reviewer, and every gate line as `ran:`/`cited:`.

Commit on your branch (no push, never touch `main`), message `feat(control): bd om35 — …` with the two
`CLAUDE.md` trailers. **Rule 17**: build the intent; bring questions back rather than shipping a decline.
**Rule 19**: report only what you ran.
