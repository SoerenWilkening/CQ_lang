# Track D — IMPLEMENTATION brief: the STALE-READER fence (bd `3d8q`, P1) — the project's one known silent miscompile

**Owner ruling 2026-09-14: this gets a track this session.** It is CORRECTNESS, not expressiveness, and its
population has been widened twice since it was filed.

Worktree: `/Users/sorenwilkening/Desktop/CQ_3d8q`, branch `stale-reader-fence` (already created off `main`
607b6fe4). Records: `$SES/trackD/` **inside your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`; `$PREV` =
`…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (binding), `CLAUDE.md` (Prime Directive; Rules 1, 2, 3, 8, 10, 11, 12,
**13**, 14, 19; CORRECTNESS RISK §2 "Rail staleness in loops", §3 **L1/L2/L3/L4**, §5 "Pre-existing silent
miscompiles"), `bd show 3d8q` (description **and all three NOTES blocks** — the population has been widened
twice), and the reproducers + report named below.

---

## 1. The defect, exactly

One line of plain C, no control flow, byte-identical on three binaries:

```c
int b = cq_theta(q, .5);  int c = cq_theta(q, .9);  return cq_measure(b) + cq_measure(c);
```

`b` and `c` are two **SIBLING** in-place Ry on **ONE** rail (`lowerRotations` RAUWs both to `q`'s handle).
The source names **two different states of one register** — a no-cloning request (Rule 8; `docs/frontend.md`
§3.2's linear rule says DECLINE) — and the emitted stream `ry(.3); ry(.5); ry(.9); measure; measure` is
**byte-identical** to the well-formed chain `a=θ(q,.5); c=θ(a,.9); measure(c)+measure(c)`. Two different
programs, one circuit. `opt -verify` clean, exit 0, golden self-consistent. This is the Rule-2 failure mode
in its purest form.

**ROOT CAUSE, already located.** `OpcodeLowering.cpp::inLowerOpsScope` — the set `declineStaleRecordOps`
sweeps — is `BinaryOperator | UnaryOperator | CastInst | data-position Cmp | curated intrinsics`. A
`@cq_theta_*` call and a `@cq_measure_*` call are **NOT in it**, so the (now correct, F-1b-1-widened) walker
is **never asked** for them. A **pure-op** reader of a stale name DECLINES (`operand predates a non-diagonal
gate`); a **theta or measure** reader ACCEPTS.

**FIX SKETCH** (from the reviewer who filed it, hand-traced on 4 programs): sweep `@cq_theta_*` (**arg-0
only** — arg-1 is the classical ANGLE, Rule 3) and `@cq_measure_*` with the **same position-aware
`checkStaleOp`**, **EXCLUDING `I` itself** from the candidate set. The well-formed chain and `cq_measure(b)`
on it stay ACCEPT (ancestry exempt); `f1`/`g1` DECLINE.

---

## 2. Reproducers and the population — measure ALL of them, ORACLE vs SUBJECT

`$PREV/../session-3qlq4/review_1b_r2_probes/` — `f1_two_siblings_nocontrol`, `f1w2_chain_measure_twice`,
`g1_chain_measure_both`, `g2_measure_parent`, `g3_pureop_after_theta`, `g4_sibling_measure_only_c`,
`l1_inloop_sibling_invariant`, `l1u_unrolled` (`.c`); report `review_1b_r2.md` §F-1b2-1/2.

The population has since grown **three** times — each is a customer your fence must catch, and each is a
currently-shipped ACCEPT that must become a DECLINE:
* the `MergePhiPeel` mux out-rail (bd `b6ap` round-2 F-B6R2-2): probe `review_b6ap_r2_probes` S03 (two
  sibling `cq_theta` on one peeled mux out-rail, both measured, byte-identical to its hand-peeled twin) and
  **S04, which reproduces on `main` with NO peel**;
* integration review I-3 probe `G8` in `$PREV/../session-2026-09-11-orchestrator/review_integration_probes`;
* Track M (`59ac5b7`): `$PREV/trackM/probes/impl/p3d8q_sibling.c` (φ spelling, DECLINE→ACCEPT 31),
  `$PREV/trackM/review_M_r1_probes/r15_p3d8q_sibling.c` (ACCEPT 31: `ry_i1(h1,¼)` then `measure_i1(h1)`
  TWICE), and `p3d8q_sibling_rail.c` (ACCEPTS on the pre-session oracle at 30) — plus `s04` at 16 with no φ.

---

## 3. What MUST NOT move — the over-decline side of the ledger

This increment widens a DECLINE. The Prime Directive says over-declining is safe; the owner's 2026-09-11
ruling says an over-decline of a **valid** circuit is a **defect**. Both are true, so you must show the fence
is exact, not merely conservative:

* the **well-formed chain** `a=θ(q,.5); c=θ(a,.9); measure(c)` stays ACCEPT — **ancestry exempt** (L4: the
  question is a gate SET and a per-entry exemption bit, never a boolean from a return-first walker);
* ~~`cq_measure(b)` on a well-formed chain stays ACCEPT (`g2_measure_parent`);~~
  ⚠ **ERRATUM, orchestrator 2026-09-14 — THIS LINE WAS WRONG AND IS WITHDRAWN.** The round-1 reviewer
  adjudicated it on the unitary and the implementer's deviation was CORRECT: `g2_measure_parent` must
  **DECLINE**. `q` denotes `Ry(.3)|0>` while the register holds `Ry(.8)|0>` — different distributions,
  silently — and the pure-op twin (`q+1` in place of `cq_measure(q)`, the identical wire question) has
  declined **on the ORACLE since Phase 5**. The mis-attribution is **mine, in this brief**, not bd `3d8q`'s:
  `3d8q`'s *"stays ACCEPT (ancestry exempt)"* is about the chain **TIP** (`f1w2`, ancestry `{%b,%a,%q}`),
  which still accepts and is in the must-not-move list below. `review_1b_r2.md`'s boundary table lists
  `g2_measure_parent.c` in the **DEFECT** row beside `f1`/`g1`. Keep the decline.
* `cq_measure` of the chain **TIP** stays ACCEPT (`f1w2`) — that is the shape `3d8q`'s sentence means;
* **`p07_chained_after` and `control_phase_kickback_rail_post_ry.ll` must be re-measured explicitly** —
  `ProvenPostRegion` must survive (bd `3d8q` names this);
* **L3**: a set is being NARROWED-by-widening here. Ask what OTHER predicate names the same instruction and
  whether it must change too — and remember the answer is not always yes (`preservesBorrowedParent` answers
  `true` BY NAME for a kickback gate and that verdict is SOUND).
* **L1**: `lowerOps` runs after the round-2 fixpoint — state where your sweep runs relative to
  `repropagateControlMerges` and whether a value can become a stale reader only in round 2.

## 4. The IN-LOOP member and the TWIN MATRIX — read this twice

bd `3d8q` F-1b2-2: `l1_inloop_sibling_invariant.c` **ROLLED accepts** (the condition is genuinely fresh per
trip; `c=θ(t,.9)` and `measure(c)` are the stale reads) while its **hand-unrolled twin DECLINES on the fix**
— a **rolled ≠ unrolled disposition split** that this fix is expected to CLOSE.

⚠ That means `tools/loop_twin_matrix.expected.txt` and/or `tools/loop_twin_matrix.quarantine.txt` may move.
The quarantine pins each blessed divergence by `(verdict, SHA-256 of the exact unified diff)` and **fails if
the signature moves, if the cell stops diverging, or if it appears in both files**. Regenerating a baseline
is a **deliberate act with a written reason** (Rule 12), never a reflex. If a cell moves: say which, why, in
which direction, and whether the new state is the CORRECT one — and if a cell stops diverging, that is the
fix working and the quarantine row must be REMOVED with that reason recorded. **Do not run
`--regenerate` to make a red go green.**

## 5. Rule 13 — budget the rounds UP FRONT

This is a change to the lowering core (`declineStaleRecordOps` / `OpcodeLowering`), so it needs independent
adversarial clearance, and `CLAUDE.md` is explicit that the measured hit rate says the next round finds
something (7.4 break: 13 holes over three rounds, three of them AFTER the epic was closed as cleared; 3qlq
Inc 1's C-1 family: 8 instances over 6 rounds on one function, two introduced by a fix). **Budget ≥2 rounds
and say so in your report.** You do not run the review yourself — the orchestrator spawns it — but your
IMPL report must hand the reviewer a written attack surface: every predicate you touched, every set you
widened, and the three programs you think are most likely to be the next hole.

## 6. Rule 12 — fixtures first

Red-green per accept/decline predicate: a positive fixture for every shape that must stay ACCEPT, and a
negative `RUN: not … | FileCheck` mirroring the new diagnostic **character-for-character**, for the sibling
theta reader, the sibling measure reader, the peel/mux out-rail customer, and the Track-M φ customer.
Fixture hygiene (PROTOCOL §S3 and Rule 12's three shipped defects): counts in their own whole-file prefix,
negatives pure, and run `$PREV/trackM/probes/impl/vacuity.py` over any new accept batch.

⚠ **A shipped ACCEPT fixture or golden that your fence turns into a DECLINE is not automatically a
regression — it may be the miscompile you are fixing.** Decide per file, in writing, and rewrite it as a
decline fixture with a retirement note (L8) rather than deleting it. `p3d8q_sibling.c` and `r15_*` are
probes, not fixtures; check whether Track M committed any of that family as a fixture or slice.

## 7. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build ONCE per edit batch (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix
llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release`; `cmake --build build -j8`; **never `--target CQPass`
alone**); record `shasum -a 256 build/ir-pass/cq-opt` in `$SES/trackD/GATES.md` after every rebuild. Inner
loop = `lit --filter` + single e2e slices. ONCE at hand-off: `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT
corpus sweep → `$SES/trackD/probes/corpus_<hash16>.txt`, one injection matrix. **NEVER** `^e2e-`, the full
suite, or the equivalence sweep — **with ONE exception**: you MAY run `ctest -R '^e2e-loop-twin-matrix$'`
once if and only if §4 tells you a cell moved, because no other layer can witness it; record it as `ran:`.

⚠ **Expected corpus movers, for the group gate's attribution:** ACCEPT→DECLINE rows whose new string is your
stale-reader diagnostic, on sibling-theta / sibling-measure / mux-out-rail / prep-φ shapes. **Any other
mover — in particular any ACCEPT→DECLINE on a well-formed chain — is a FINDING** and is the over-decline
this fence must not cause.

## 8. Deliverables

`$SES/trackD/{IMPL_D.md, GATES.md, probes/}` in your worktree: the sweep as spelled, the L1/L3/L4 answers,
the full reproducer table (ORACLE verdict → SUBJECT verdict, per probe, all of §2), the must-not-move table
(§3), the twin-matrix disposition (§4), the fixture table, the corpus movers, the mutation MISSED count, the
attack surface for the reviewer, and every gate line as `ran:`/`cited:`.

Commit on your branch (no push, never touch `main`), message `fix(lowering): bd 3d8q — …` with the two
`CLAUDE.md` trailers. Report back: branch tip, binary hash, gate lines, the two tables, the round budget, and
anything you could not do. **Rule 19: report only what you ran.**
