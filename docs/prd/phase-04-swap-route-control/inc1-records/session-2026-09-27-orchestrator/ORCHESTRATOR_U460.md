# bd `test_C_libtooling-u460` — the orchestrator's record of the round

**VERDICT: the woa0 cross-claim fence is CLEARED WITH ITEMS.** Two independent
Rule-13 rounds, both `CLEAR-WITH-ITEMS`, **0 P1 each**. Budget of two: MET.
bd `u460` CLOSED.

```
SUBJECT   cq-opt 15adcac40d4455a7f2d9f785 · libCQPass.so bab2a8b70c57c6b036c859f8
ORACLE    cq-opt fe5805a41df2e173fdfa572b   (git 18d18728, pre-fix)
HEAD at start  90e79229     CLAUDE.md 149959 B
```

## 1. How the round was run, and the one deviation

Two agents, neither of which wrote `357f2528`, neither of which read the other's
report. Disjoint PRIMARY surfaces, both free to range:

* **Round A** — completeness of the RECORD and of the OBSERVATION. Can the
  original hazard still fire without the fence seeing it?
* **Round B** — the RE-ASK itself: `AtFn`'s lifetime, the pre-emptive slot, the
  `lowerCloneControl` record, and the FALSE-POSITIVE direction.

⚠ **THE DEVIATION, STATED SO IT IS NOT MISREAD: they ran CONCURRENTLY on a FROZEN
SUBJECT, not sequentially.** The "budget two" precedent on this bead family is
5a's round 2 finding a P1 inside round 1's *fix*; that value exists only when a
fix lands between the rounds, and none did. Concurrency bought disjoint-surface
coverage at half the wall-clock and gave up nothing that was in play.
**Any fix for the findings below owes a further round** — that property is
preserved where it actually bites.

## 2. The result that matters

**THE TWO ROUNDS CONVERGED, INDEPENDENTLY, ON THE SAME P2.** `F-RA-1` and
`F-RB-1` are one defect found twice, by four different exhibits, from opposite
assignments — round A looking for an under-record, round B for a false positive.
`Leaves` is committed at the **E6 ADMISSION** while `run()` mints edge predicates
**LAZILY**, so a rail φ can be RECORDED AND NEVER READ, and a later claim's
**vacuous RAUW** then declines a module the oracle compiles correctly.

Both rounds independently built the one-line `!P->use_empty()` gate. **Both
measured it INSUFFICIENT** — it recovers the never-minted sub-class (`ra1`,
`rb3`) and not the minted-then-dead one (`ra2`) — so the class has ≥2 members
and the total fix records at the READ (`literal()`/`edgePred`). bd
`test_C_libtooling-707a`. It is an over-DECLINE, hence P2; P1 here is reserved
for over-accepts.

⚠ **WHY NEITHER THE SUITE NOR THE CHANGE'S OWN MATRIX COULD HAVE FOUND IT.** Of
the eight shipped probes, **both accepting rows commit nothing**, so the matrix
has **zero cells in the quadrant "record populated ∧ module accepts"** — and the
corpus cannot supply one (5 commit modules in 2157, none converts). Round A
found this by running *the implementer's own instrument over the implementer's
own probe set*, which is a move worth copying. *A clean `A→D = 0` over a
population with no members of the class is not evidence about the class.*

## 3. Every one of the bead's eight attack items was reached

| # | item | outcome |
|---|---|---|
| 1 | G-13 missed | **LIVE, not vacuous** — the record spans three fixpoints, so the axis is real; three attempted pairs stopped at earlier walls. bd `0ues` |
| 2 | no `+Asserts` | **BUILT.** 2157 swept, **4 aborts, exactly round 3's four, woa0 adds none.** A four-fixture bill, not an impossibility. bd `r4f6` |
| 3 | `AtFn` raw pointer | conclusion **SURVIVES** (every `eraseFromParent` in the window enumerated); window is **three nested fixpoints**, not "a few statements"; null case **silently ACCEPTS**. bd `qs5w` |
| 4 | clone slot | **disjoint BY CONSTRUCTION**, verified in code; residual written down (after the module re-ask, a module-record violation is observed by nobody) |
| 5 | pre-emptive slot | **CONSTRUCTED** — it masks a real `cq taint escape`, and disables `CQ_SPEC_DBG` on exactly the modules it fires on. bd `nkgt`; the masking half is an **owner question** |
| 6 | `!BoolAlg` pin | witness property **SOUND** (re-measured against MUTANTS); stream pin **6/12 injection-vacuous**, one NEG directive cannot fail on any binary. bd `lit8` |
| 7 | round-2 / L1 | **RE-DERIVED**: seven call sites, no defaults on either parameter, one recording arm and one recording scope over all three scopes |
| 8 | hides a 41g3 accept? | **YES, measured** — `rb8` substitutes the boolean-algebra residue and gets rc=0 on both binaries |

## 4. Found beyond the list

`F-RB-3` the **`xor`-of-`select` mechanism is measurably FALSE at six sites** (no
`xor` exists; the owner is `SelectClassify`'s data-select grammar) ·
`F-RA-3`/`F-RB-7` `MergePhiPeel.cpp:568` and `SwapRouteEmit.cpp:573` also convert
a φ to a `select`, so "the only converter" is a file claim, not a pass claim ·
`F-RA-2` the record is keyed on SSA identity across two **cloning** pre-passes
and identity stability is argued nowhere (bd `tzw2`) · `F-RA-7` the diagnostic
prints `<unknown>:0:0` on every module that reaches it · `F-RB-6` `runOnFunction`
returns the opposite of its siblings · `F-RA-8` §5's census is **5 of 2157**.

## 5. Independently reproduced — neither round took the record's word

Corpus A/B ORACLE vs SUBJECT = **1 mover of 2157**, the increment's own fixture,
by **both** rounds each with its own null control run FIRST · round A additionally
swept **all 403 compilable `tests/e2e/slice_*.c`: 0 movers**, a layer
`MEASUREMENT_WOA0.md` did not sweep · round A **rebuilt `90e79229` and got a
binary BIT-IDENTICAL to SUBJECT** · the owner's program byte-identical on a
re-derived stage 1 and a **live customer** of the record on both rounds ·
round A **measured** `WeakVH`'s RAUW semantics against LLVM 19 and reports the
source comment right and its own recollection wrong.

## 6. What landed here, and its null control

Comment-only corrections at every false or over-stated site (CLAUDE.md L7: a
correction not applied to the source is not a correction). ⚠ **The null control
is mechanical and it fired: the rebuilt `cq-opt` and `libCQPass.so` are
BIT-IDENTICAL to the pre-edit binaries** (`15adcac40d4455a7f2d9f785` /
`bab2a8b70c57c6b036c859f8`), which proves the edits are behaviour-free more
strongly than any sweep could.

Sites: `PredMuxFlatten.h`'s *"cannot be wrong in either direction"* ·
`PredMuxFlatten.cpp:11`'s *"PredMux can only widen the accept surface"* — **the
OTHER header in the file `357f2528` half-fixed**, which is L7-with-a-twist inside
one file · the re-ask's own doc comment · both *"reads as a rail leaf"* field
comments · the `xor` mechanism at all four mutable sites · `AtFn`'s window and
its null-case trigger · the identity-stability trigger · the two "only converter"
scope claims. Plus CLAUDE.md **§4k**, a dated **ERRATA** block (E1–E5) on
`MEASUREMENT_WOA0.md`, and four counts blocks **archived VERBATIM** to
`docs/CLAUDE-HISTORY.md` to keep CLAUDE.md under its own 150 k budget.

## 7. ⚠ What this round does NOT establish

* **No fix for the converged P2 was attempted**, deliberately. Narrowing a
  decline is an ACCEPT-direction change; the one-liner is measured insufficient
  and the total version re-opens bd `0fly`'s `{R.Merge}` cell.
* **Neither round reached the fence from C.** Round A: 8 perturbations of the
  owner's program, `MOVERS=0`, 0 of 8 reached it. Round B could not build either
  spelling because `-O1` folds what they need. Every exhibit is hand-written IR.
* **Neither round attacked bd `0fly`'s conjunct, bd `41g3`'s residual, bd `cfmv`,
  increments 1–5a, or 5b.** Their shared ORACLE contains all of them, which is
  what makes the woa0 delta clean, and that is all it was used for.
* **Neither round ran the full `ctest`.** Round A ran 7 targeted lit tests; round
  B ran `FileCheck` by hand on three fixtures. Both say so in their own words.
  The full suite was run by the orchestrator, separately, and is reported with
  its load.
* **No simulation, no statevector** (Rule 2). Every claim is a verdict, a string,
  a byte-diff, an event count or an analytic argument.
* **`+Asserts` is now possible but is not a gate** — the four fixtures are unfixed.

## 8. Findings → beads

`707a` (P2, the converged over-decline) · `tzw2` (P2, SSA identity across the
cloning pre-passes) · `lit8` (P2, fixture pin vacuity) · `nkgt` (P3, pre-emption
masking + `CQ_SPEC_DBG`) · `qs5w` (P3, the three re-ask code defects) · `0ues`
(P3, G-13 live but unreached) · `r4f6` (P3, the `+Asserts` four-fixture bill).
Notes appended to `4hnu` and `0fly` for what the rounds did and did not touch.
