# CLOSING REPORT — session 2026-09-20

## THE HEADLINE

**bd `zujr`'s ≥3-round Rule-13 budget is MET, and the two over-declines it filed
at its landing are CLOSED.** The loop-carried handle variable now lowers **at
every integer ABI width** (bd `11qv`) and **behind a zero-trip guard**, i.e. at a
**RUNTIME trip bound** (bd `h1ip`, owner ruling Q1).

The owner's own cascade with `int a` spelled `short a` compiles as written: 50
trace lines, STRICT stage 2b clean, the `i32` stream modulo the width token. A
loop with a genuinely runtime trip count compiles and runs correctly at **zero,
one and two trips on one binary**.

## OWNER RULINGS OBTAINED AT OPEN (all three, `DECISIONS.md`)

**Q1 bd `h1ip`: HOIST IT, ACCEPT THE DEAD ALLOC.** Built.
**Q2 bd `11qv`: FOLD IT INTO THE bd `h7ee` ROUNDS.** Built; the rounds that
attacked it were independent agents that did not write it, which is the only
reading of that ruling Rule 13 permits.
**Q3 bd `3slt`: DECIDE WHEN THE WALL MOVES.** Nothing ruled on the hypothetical.
⚠ The mitigation implied by the accepted risk was applied the same day: the
tripwire obligation is now recorded on **bd `r903` and bd `fg9k`** — the two beads
that would MOVE the wall — so it is discoverable from the side that trips it and
not only from its own file.

## GATES

See `GATES.md`; every row is hash-keyed. The headline numbers:

* corpus A/B over **2107** fixtures, ORACLE `e7bbfd69…` vs SUBJECT:
  **0 A→D · 2 D→A · 0 decline-string moves · 1 stream move**;
* three peel-mutation matrices ((P4), (P0), the `HandleWidth` record):
  **0 movers, 0 crashes each**, with a **null-tag boundary control** at 0;
* duplicate-body fixture scan after two renames: **9 groups, 0 contradictory
  verdicts**, both renamed files absent (no resurrection);
* a from-scratch worktree build at `main` reproduced the primary binary
  **BIT-IDENTICALLY**, and Rule-13 round 3 reproduced it independently.

## THE RULE-13 ROUNDS (bd `h7ee`) — both by independent agents

| round | subject | verdict | P1 |
|---|---|---|---|
| 2 | residuals: break loops, the two backstop escapes, `AsLowered` | `CLEAR-WITH-ITEMS` | **0** |
| 3 | the COMPOSITION vs bd `tu9q` P0+P3, `drbq.12`, `xdu2` | `CLEAR-WITH-ITEMS` | **0** |
| 4 | this session's own bd `11qv` + bd `h1ip` | *(see `round4/`)* | |

⚠ **Round 2 closed residual escape B by construction** (`liftOneRegisterMergePhi`
can never take a carried-handle φ — a structural mutual exclusion:
`latchIsControlMergeRail`'s φ clause needs a TAINTED-branch predecessor while the
lift needs EVERY incoming block's terminator classical, and for a φ those are the
same blocks). Its R2-1 was **fixed in this session** as clause (P0).

⚠ **NEITHER ROUND RAN A SUITE, BY INSTRUCTION**, and round 3 ran no lit either —
**no `FileCheck` line was executed in it**. Both said so themselves. Read each
round's own "what I did not do" before citing it.

## THE FIVE THINGS WORTH CARRYING FORWARD

1. **THE COMPOSED ACCEPT SURFACE IS NOT EMPTY, AND IT WAS EXHIBITED RATHER THAN
   ASSERTED** (bd `4jok`, **now a GATE on the bd `tu9q` P0+P3 landing**). Nine C
   programs compile only with bd `zujr` **and** bd `tu9q` P0+P3 both present —
   one is the owner's rolled cascade plus one line — while the 2106-fixture corpus
   A/B, the 382-cell twin matrix and all 390 e2e slices report **zero**. Fifth
   consecutive session to file *a composition is not cleared by clearing its
   parts*; the first to show the surface.
2. **THE SAFETY ARGUMENT FOR bd `11qv` IS THE WIDTH RECORD, NOT THE RETYPE, AND
   IT WAS FOUND BY READING BEFORE IMPLEMENTING.** `RailBankPromote`'s spelling of
   the same `mutateType` idiom **ERASES** `taint.HandleWidth` where this one must
   **WRITE** it. ⚠ And reachability is **not** claimed — the record is defensive
   and the source says so rather than claiming a fixed bug.
3. **A BEAD THAT NAMES THE NEXT WALL IS A LOWER BOUND — three more instances.**
   `11qv` named one wall for `_Bool` and there are two; `h1ip` named (Z8) and (Z1)
   was in front of it. ⚠ And (Z1) falsifies a **correction** in CLAUDE.md §4e:
   `-O1` emits a preheader **sometimes**, so both the original sentence and its
   round-1 fix were over-general.
4. **A WIDENING THE CORPUS CANNOT SEE IS ONE THE CORPUS CANNOT DEFEND.** The (Z1)
   relaxation moved **zero** of 2107 fixtures, so it got a fixture holding the
   exact shape `-O1` produces. The same logic applies to (P4) and the width
   record, which moved zero too — they are recorded as **defensive and
   unreachable on today's corpus**, in those words, so neither is ever cited as a
   tested fence.
5. **L10 LANDED ON THIS SESSION'S OWN INSTRUMENT.** The first peel sweep reported
   **2065 movers of 2106** because `rc=$?` after a pipeline captured `grep`'s
   status. Caught by a **null-tag boundary control**, which now runs on every
   invocation. Write the control before the first real measurement, not after the
   first implausible one.

## FILED

bd `4jok` (P2, the composition gate) · bd `ix2v` (the narrow-literal ABI
attribute — **pre-existing, attributed by measurement on the oracle**) · bd
`xt20` (R2-2: (P1)'s stated ground is wrong) · bd `lgu8` (R2-3: the MULTI-EXIT
carried handle, a DISTINCT shape from `h1ip`) · bd `xfso` (R2-4) · bd `fhh3`
(R2-5). bd `tu9q` carries the gate on its own bead.

## NOT DONE

* **bd `hyhl`** — the five diagnostic degradations. Not started.
* **bd `3slt`** — ruled to wait for the wall, mitigation applied.
* **CLAUDE.md §4c archived** to `docs/CLAUDE-HISTORY.md` (the §4b treatment) to
  bring the file back under its 150 k budget: 151.8 k → 139.8 k. Moved, not
  deleted; all 9 cross-references repointed, 0 dangling.
