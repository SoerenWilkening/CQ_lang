# Track W — FIX brief for review round 1 (bd `wx8g`) — verdict **NOT CLEAR**, two over-ACCEPTs

Worktree `/Users/sorenwilkening/Desktop/CQ_wx8g`, branch `inloop-bool-prep`, tip `11fc1b3c`.
**READ FIRST:** `$SES/trackW/REVIEW_W_R1.md` in full (41 probes, 79 artefacts in `review_r1_probes/`).

Three of your own judgements were upheld and you should not re-litigate them: **(c3) survives L4** (the
failure mode needs an exemption; `iterationLocalTaintEscape` has none and is consumed as `== nullptr`, a pure
∀, so a first witness is a complete answer to ∃ — one gap: your recorded trigger names exemptions but not
**closure** widening, L2's half, so extend it); **H-3 is genuinely unreachable**, on a *stronger* ground than
you stated (`peelInPlaceStep` **stops at** a `cq_phi`, whose arg-0 is the untainted angle, rather than
stepping through, and both callers pass register-typed values) — no fixture is correct, record the better
ground; and **retirement argument 1 ("wrong twin") is sound**, independently verified plus two new
twin-identical accepts (`a1`/`a2`).

## F-W1-1 — over-ACCEPT / silent miscompile. A DANGLING POINTER. Fix first.

`declineUnmarkedRolledIterLocal` declares `SmallPtrSet<const Loop *> Diagnosed` **outside** the
`for (Function &)` loop, while `LoopInfo LI(DT)` — which **OWNS** those `Loop` objects — is declared
**inside**. Pointers dangle across functions and the next `LoopInfo` reuses the allocation, so
`Diagnosed.insert(L).second` returns false for **a different loop in a different function** and the entire
re-ask — **both conjuncts** — is `continue`d over.

Four controls isolate it: `w_j` alone declines; **`w_i`-then-`w_j` ACCEPTS**; the reversed pair declines; a
first function that writes no record declines; two failing functions decline. The accepted stream **leaks
`and_unc` + its free per activation** (2 mints / 0 `_unc`) — **your own 19-vs-27 signature, shipped through
the fence you built to stop it**. `opt` exit 0, verify-clean, stage-2b `0 violation(s)`. **No `noinline`
needed**: two ordinary kernels in one TU reproduce it.

**Fix:** scope `Diagnosed` per function, or key it on `L->getHeader()`. It is the **only**
`SmallPtrSet<const Loop *>` in the tree, and its neighbour `reverifyRailCondReads` already has the correct
shape — call that shape, do not invent a third.

## F-W1-2 — over-ACCEPT / silent miscompile. The halves do not cover the same set.

**Half 1 retires the carve-out for EVERY rail region in a loop. Half 2's record+re-ask is written ONLY at
the clause-(c) grant.** A rail region on a loop-**CARRIED** register is granted by (b′) with **no record and
no conjunct 2**. `d3_invariant_read.c`: ORACLE **DECLINE** → SUBJECT **ACCEPT**, 30 vs 34 lines, missing
`and_unc` + free per activation. Mechanism: the body reads a loop-invariant tainted rail, so
`markIfRailLocal`'s *"accumulating loop-invariant tainted input"* clause refuses the marking.

The leak itself is pre-existing and arm-class-independent (`d4` diverges byte-identically on ORACLE and
SUBJECT) — **but the ORACLE REFUSED `d3`**, so this is a **new customer on a known-defective path**, not a
quarantinable divergence. ⚠ `IMPL_W.md` §2.1 **asserts the opposite in writing**, and that sentence is
**load-bearing for the retirement**. Correct it.

**Build the non-declining fix**, not the re-narrowing: **record at EVERY R7-loop grant with a per-entry
clause bit, and run conjunct 2 only for (b)/(b′)**. Re-narrowing half 1 would restore an over-decline the
owner has ruled a defect; if you conclude the record-at-every-grant design cannot be made sound, STOP and
bring it back rather than re-narrowing on your own judgement (Rule 17).

## F-W1-3 — over-DECLINE ×3, one root cause. This is the fifth you were asked for.

`bodyHasSpineDischargeCandidate` **is a proxy and is too coarse**. Three one-token deltas from an accepting
baseline decline at conjunct 2 while their hand-unrolled twins accept with **zero** `_unc`/`free` in the
body: `r ^= 3` and `cq_measure(r + 1)` (both lower **in place** to `cqrt_xorc`/`cqrt_addc`, minting nothing)
and `cq_measure(r & 3)` (a **measured** rail is never uncomputed or freed). **Fix direction:** exclude
`taint.InPlaceRailOps` by **CALLING the M-C record** (Rule 14 — it is committed with the proven operand
index precisely so no consumer re-derives it); file the measured-terminal case separately if it needs its own
predicate. Accept-direction, so its own retirement trigger binds — write one.

## F-W1-4 — record hygiene

The `runOnFunction` mirror depends on a marking that shim **structurally cannot produce** (it never calls the
round-1 `collapseFlattenedLoopRails`, and round 2 skips those preds). Zero callers today. Say so plainly
rather than implying parity.

## The meta-finding — carry it, it is bigger than this increment

**Both over-accepts were invisible to 1937 fixtures, 15 e2e entries, a COMPLETE corpus sweep, a 0-MISSED
injection matrix and 328 twin cells, for the same structural reason: every one of those corpora is
effectively ONE FUNCTION PER MODULE.** F-W1-1 needs two functions in one TU; F-W1-2 needs a second region.
The orchestrator is filing the instrument gap; your part is to **add the two-function probes you now have as
committed fixtures**, so the next increment inherits a pin rather than a lesson.

## Gates (PROTOCOL FIX-agent row)

`cmake --build build -j8` (**never `--target CQPass` alone**); record the new `shasum -a 256` in `GATES.md`.
Re-run: the four F-W1-1 controls, `d3`/`d4`, the three F-W1-3 deltas and their twins, your 8 twin pairs, the
K-independence pair, every fixture you touch, and **`ctest -R ir-pass-lit` ONCE**. **NO corpus sweep** (one
per session, the merge gate's — yours stands for the pre-fix binary only and must be labelled so), **NO**
full suite, `^e2e-`, equivalence sweep, or twin matrix.
⚠ Every gate line against `daeb93a3` is **void for the new binary**. Re-record; mark `cited:` vs `ran:`.

## Deliverable

Update `IMPL_W.md` (including §2.1's wrong sentence) and `GATES.md`, add `FIX_W_R1.md` with each finding's
disposition, commit on the same branch with the two `CLAUDE.md` trailers. Report: new tip, new binary hash,
the four F-W1-1 controls before/after, `d3` before/after, the three F-W1-3 deltas before/after with their
twins, the new two-function fixtures, and every gate line as `ran:`/`cited:`. Round 2 will start at your fix.
