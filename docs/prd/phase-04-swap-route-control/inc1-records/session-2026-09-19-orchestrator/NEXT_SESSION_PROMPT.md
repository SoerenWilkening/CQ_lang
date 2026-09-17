# Session 2026-09-20 — brief

Read in this order: `CLAUDE.md` (§4e is new), `ROADMAP.md`, `$PREV/PROTOCOL.md`,
`$PREV/CLOSING_REPORT.md`, `$PREV/DECISIONS.md` (D1–D7, Q1–Q3),
`$PREV/REVIEW_R13.md`, `$PREV/GATES.md`, then this file.

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang
SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-20-*/
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-19-orchestrator/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

## 0. STATE AT CLOSE (measured, hash-keyed — `$PREV/GATES.md`)

`main` `89b8a649`; primary `build/ir-pass/cq-opt` =
`e7bbfd69a9e25d383237…` (`libCQPass.so` `84061321f9d6f9747b80…`), rebuilt once at
the close and bit-identical to the gated worktree binary. Full `ctest -j6`
**464/464 in 579.63 s**; equivalence **2106/0**; twin matrix **312 expected + 70
quarantine = 382** cells; fixtures **2106**; goldens **398**.

**The owner's loop program COMPILES.** `example/grover/grover_oracle_uncompute.c`
in its rolled form: exit 0, stderr 0 bytes, 50 trace lines, STRICT 2b clean,
K-independent. ⚠ **Verify with the hash before believing any decline** —
`shasum -a 256 build/ir-pass/cq-opt` — a stale `cq-opt` makes a fixed program look
broken by hand and a broken pass look green in lit.

## 1. THE FIRST THING TO DO: bd `h7ee` — Rule-13 rounds 2 and 3

bd `zujr` is OPEN for exactly this reason. Its DONE-MEANS asks for ≥3 rounds; ONE
ran, verdict `CLEAR-WITH-ITEMS`, no P1, no P2, six P3s (all addressed in source or
filed). ⚠ **Three consecutive sessions before this one found a P1 on round 1 of a
loop change and this round found none** — that is either good work or a round
that looked in the wrong places, and rounds 2 and 3 are how the project tells
those apart. Round 1's own list of what it did NOT attack is in `$PREV/REVIEW_R13.md`
and in bd `h7ee`:

* a `break` loop beside a carried handle (two hand probes only);
* the two residual escapes from the promotion backstop — a `use_empty()` φ, and
  `liftOneRegisterMergePhi` succeeding on a HEADER φ;
* the `AsLowered` mismatch between `collectCarriedHandleChains` (false) and
  `railLocalQualifies`' `onRail` (true) — unobservable today, live the day (Z6)
  admits an in-place latch step;
* **the COMPOSITION** against bd `tu9q`'s parked P0+P3 (`tu9q-p0-p3-wip`), bd
  `drbq.12` and bd `xdu2`. *A composition is not cleared by clearing its parts* —
  filed in FOUR consecutive sessions now.

## 2. THEN, IN THIS ORDER

1. **bd `11qv`** — the NARROW-WIDTH carried handle (`mutateType(i32)` on the φ at
   the promotion). A `_Bool` carried handle is the shape the owner's own programs
   are full of, and it declines today. It unblocks **bd `832l`**, which was
   REOPENED this session by measurement (its literal subject is unmoved).
2. **bd `h1ip`** — the GUARDED / rotated loop, i.e. a RUNTIME trip bound. Owner
   question Q1 attached (it allocates a register a zero-trip loop never uses).
3. **bd `hyhl`** — the five declines that degraded to the generic string.
4. **bd `3slt` / bd `s82e`** — the Rule-8 tripwire is now a filed customer of that
   P1, with the red-green pair named in the fixture's own header.

## 3. OWNER QUESTIONS TO BATCH AT OPEN

Q1 (bd `h1ip`, the zero-trip allocation), Q2 (bd `11qv`, is `_Bool` worth its own
round), Q3 (bd `3slt`, warning or decline once the select wall moves) — all three
written out in `$PREV/DECISIONS.md`.

## 4. ⚠ ERRATUM OWED TO LAB ENTRY 012

Entry 012's header records the close hash as `e2fd1a16` — the merge commit before
`git pull --rebase` linearised it, no longer reachable from `main`. The correct
hash is **`89b8a649`**. The entry is SEALED, so **entry 013 owes the dated
erratum**; do not edit a sealed entry.

## 5. PROTOCOL — carry `$PREV/PROTOCOL.md` forward with THESE additions

* **The peel instrument earned its keep and is NOT in the tree.** An env-gated
  `cqPeel("tag")` that turns each candidate decline into a skip is how the
  four-wall ladder was mapped in ONE binary; without it each wall costs a rebuild,
  because `LLVMContext::diagnose` EXITS on the first `DS_Error`. It is scratch by
  design (it must never ship), so **the next session re-creates it** — the file is
  in `$PREV/probes/` if it was copied, and it is 25 lines either way.
* **A retirement trigger that names the NEXT wall is a LOWER BOUND.** Eleven
  fixtures moved this session, every one carrying a trigger that predicted this
  increment, and **every one named the wrong next wall**. Write triggers as
  *"this file moves when X lands; RE-DERIVE it, do not delete it"* and do not
  predict the resulting string.
* **Before closing a bead the charter names, run its LITERAL subject.** bd `832l`
  was closed and reopened the same day because the charter's item 1 named it and
  the increment built the promotion for a different kind.
* **An accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled
  probe with a trailing non-diagonal gate on every register the condition reads**
  (carried from `$PREV`; it produced
  `loop_carried_handle_reject_postloop_rotation.ll` this session).

## 6. Close
Standard Session Completion (CLAUDE.md): bd (`--append-notes`), lab entry 013
(≤5 pages, `--seal`, **with the entry-012 erratum**), `CLOSING_REPORT` /
`DECISIONS` / `GATES`, `git pull --rebase && git push`.
