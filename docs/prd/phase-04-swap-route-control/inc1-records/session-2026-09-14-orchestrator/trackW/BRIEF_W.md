# Track W — IMPLEMENTATION brief: the IN-LOOP bare-`_Bool` controlled-Ry arm / state prep (bd `wx8g`)

**Owner ruling 2026-09-14: this is the loop wall to remove FIRST.** Track L measured that the rolled cascade
has THREE walls, not one, and that bd `xdu2`'s array carve alone does **not** compile the owner's loop — it
clears W1 and hands the program straight to this one. `wx8g` is the cheapest of the three (~120–180 pass
lines, 3 rounds), it is **W2 on the array path anyway**, and it has its **own standalone customer** that
`CLAUDE.md` records as compiling **in no spelling on any binary today** ("its cost is **total**").

Worktree `/Users/sorenwilkening/Desktop/CQ_wx8g`, branch `inloop-bool-prep` (created off `main` 607b6fe4).
Records: `$SES/trackW/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`;
`$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (binding), `CLAUDE.md` (Prime Directive; Rules 1, 3, 5, 6, 7, 8, 9, 12,
**13**, 14, **17**, 19; CORRECTNESS RISK §1 the in-loop rows, §2 "Loop scope" and the condition-wire fences,
§3 **L1/L2/L3/L4/L6**), `bd show wx8g` (**including the 2026-09-14 note**), `bd show l4x4`,
`$SES/trackL/SCOPE_L1a.md` §0 (H1 — the measurement that put you on the critical path) and §7,
`$PREV/trackL/SCOPE_loop.md`, and the drbq PRD `docs/prd/phase-04-swap-route-control/control-in-place-PRD.md`
§4/§12/§13/§14 (the in-place arm, the angle select, the in-loop arm, state prep + F2).

---

## 1. The customer and the wall

```c
for (int k = 0; k < K; k++) { if (b) r = cq_theta(r, theta); }   /* b loop-invariant _Bool */
```
declines **`cq controlled lowering: control flow inside a loop body under quantum control`** at
`ArmClassify.cpp:4396-4397` (R7's loop half, `if (!Rollable)`).

**Root cause, already located and measured (Track L, SCOPE_L1a §0 H1):** `Rollable` can only become true via
a header-φ **root mint** (`railPhiRootMint`, `LoopLowering.cpp:360`). The **ITERATION-LOCAL** spelling has no
header φ for the rail, so `railPhiRootMint` finds no mint and `Rollable` stays false **by construction** —
for every such program, forever. The source says so in writing at `ArmClassify.cpp:4266-4271`: *"R7's LOOP
half below is deliberately NOT skipped: it iterates `BaseWireOrder`, which is empty here, so `Rollable` stays
false and every in-loop state prep declines `control flow inside a loop body` — the ITERATION-LOCAL
spelling."*

⚠ `CLAUDE.md` records this over-decline's cost as **total**: *"with the COMPARE spelling unable to express it
either, Grover as a rolled loop with a bool-controlled rotation or prep compiles in NO spelling on ANY
binary."* Confirm that on the ORACLE before you start, and **also measure the COMPARE spelling** (`if (x > 3)
r = cq_theta(r, θ)` in a loop) — the bead says row W fails at the LICM-hoisted compare, which is the P4
unbounded-cross-block-gap fence. Say which of the two you are fixing, and whether your fix reaches the other.

**Rule 17 governs this increment.** The task is to *implement* the lowering. Do not substitute a narrower
decline or a stub. If it proves genuinely ambiguous, bring the question back to the orchestrator.

## 2. The shape of the fix, and what it must NOT become

One new `Rollable` clause at `ArmClassify.cpp:4396` for the iteration-local spelling. The obligation is to
say what "rollable" **means** for a rail with no header φ, and to prove that the ROLLED emission is the same
unitary as K copies of the arm.

* **Rule 7 / Rule 6 are unchanged.** The in-place controlled-Ry arm mints `cqrt_ry_<W>_controlled(f, h, θ)`
  and then **FREEZES** the rotated register — never reverse-played, never freed (`Ry(θ)|0⟩ ≠ |0⟩`); the
  control register is left allocated too. A per-trip rail that is not provably `|0⟩` is **left allocated**,
  never freed dirty.
* **L1 — the round-2 window is the first thing to answer in writing.** Detection+lowering run TWICE. Does
  your clause compute anything a later stage consumes over a premise round 2 falsifies? Does it need re-asking
  in BOTH entry points? `CLAUDE.md`'s three species (a STAGE, a PREDICATE asked at round-1 taint, a
  TAINT-GROWTH event) are the checklist.
* **L2 — when you widen a set, ask what OTHER set was computed over the same closure.** `collectRailGates`'
  `Gates` + `OnRailOut` (`LoopLowering.cpp:905-914`, `:975-976`), the `MemberSet` skip `:1045`, step-5 `Skip`
  `:2806-2807`, R6 `:4415`, `railWireNamesBackward` `:2256-2258`, `railWireClosure` `:563-598`,
  `reverifyRailCondReads` `:2571`. Track L's recommendation for the *array* was that the design widens
  **none** of them; state per entry whether that holds for **yours**.
* **`staleRailRecordRead`** is grouped per **ROOT MINT** — two chains from one mint are one register and must
  interfere; two mints must not. An iteration-local rail has no mint by the current spelling. **Say what the
  grouping key becomes**, and pin it with a probe where two iteration-local rails must NOT interfere.
* **Rule 14 — reuse.** `markIfRailLocal`, `invariantRegisterRoots`, `collapseRailPhisIn`,
  `hasFiniteClassicalTripBound`, `emitInPlaceRotationRegion` and the M-β RAUW convention already exist. Call
  them. A second spelling of a predicate the tree owns is the drbq Inc-3 (b′) defect.
* **The Q1 quantum-bounded-exit decline stays unconditional.** You are not building the Rule-18 bound
  derivation (bd `m57l`); a quantum-dependent trip count still declines loudly.

## 3. The witness — and an instrument is landing beside you

The shipped witness for in-loop work is **byte identity with the hand-unrolled twin** plus **K-independence
of the lowered IR** (87 lines at K=3 and at K=1000 for the phase path). Produce both for your customer.

⚠ **Track L measured a trap here (SCOPE_L1a §0 H2):** with a compile-time-constant seed, `-O1` folds trip 0
away, so the "unrolled twin" of a const-seed program is *not* the same circuit as the rolled form
("one folded region + one genuine prep" vs "one genuine prep, K times"). **Construct your twin so that the
comparison is meaningful, and state explicitly what you did to avoid that fold.**

⚠ **Track T is widening `e2e-loop-twin-matrix` to `i1` on branch `twin-matrix-bool`, in parallel, and lands
BEFORE you.** All 288 existing cells emit 2 `bool` tokens in total, so today the matrix cannot witness your
subject at all. Therefore: **do NOT edit `tools/loop_twin_matrix*`** — those files belong to Track T for the
duration. If your increment needs new matrix cells, **name them in `IMPL_W.md`** and the merge-and-gate agent
will generate them in the combined worktree with a written reason. The combined group gate runs the **widened**
matrix over your code; expect it to say things about `i1` that no previous gate could.

## 4. Rule 12 and Rule 13

Fixtures first, red-green, positive `CHECK` **plus** a negative `RUN: not … | FileCheck` mirroring each
decline string character-for-character. At minimum: the accept for the iteration-local prep; the accept for
the iteration-local in-place Ry arm; K-independence pinned at two K; a decline fixture for every precondition
your clause relies on (an unbounded trip count, a quantum-derived angle, a multi-latch or nested loop, an
`if`-arm that writes memory, a condition the arm clobbers — §3c); and the probes that pin what must keep
declining. Hygiene: counts in their own whole-file prefix, negatives pure, and run
`$PREV/trackM/probes/impl/vacuity.py` over the accept batch.

**Rule 13 budget: 3 rounds, stated up front.** You do not run the review; the orchestrator spawns it. Your
`IMPL_W.md` must hand the reviewer a written **attack surface**: every predicate you touched, every set you
widened, the L1/L2 answers, and the three programs you think are most likely to be the next hole.

## 5. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build once per edit batch (`cmake --build build -j8`; **never `--target CQPass` alone**); record
`shasum -a 256 build/ir-pass/cq-opt` in `$SES/trackW/GATES.md` after every rebuild. Inner loop =
`lit --filter` + single e2e slices. ONCE at hand-off: `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT corpus
sweep → `$SES/trackW/probes/corpus_<hash16>.txt`, one injection matrix with MISSED reported. **NEVER** the
full suite, **NEVER** `^e2e-`, **NEVER** the equivalence sweep, **NEVER** the twin matrix (Track T owns it).

⚠ **Expected corpus movers:** DECLINE→ACCEPT rows whose ORACLE string was `control flow inside a loop body
under quantum control`. **Any other mover is a FINDING.**

## 6. Deliverables

`$SES/trackW/{IMPL_W.md, GATES.md, probes/}`: the clause as spelled, the L1/L2/L4 answers, the
`staleRailRecordRead` grouping-key answer with its probe, the byte-identity and K-independence witnesses
(with the §3 fold caveat addressed), the fixture table, the corpus movers, the mutation MISSED count, any
matrix cells you need Track T's widened generator to produce, and the attack surface.

Commit on your branch (no push, never touch `main`), message `feat(control): bd wx8g — …` with the two
`CLAUDE.md` trailers. Report back: branch tip, binary hash, gate lines, the witnesses, the fixture table, the
round budget, and anything you could not do. **Rule 19: report only what you ran.**
