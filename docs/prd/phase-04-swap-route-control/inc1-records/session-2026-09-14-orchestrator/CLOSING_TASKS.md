# Closing-pass task list — session 2026-09-14

Items that must be applied ON `main` AFTER the merge lands, because fixing them in a track worktree now
would move a branch tip the merge gate is already running against.

## 1. `trackD/IMPL_D.md` §15.1 — the a5 row states a FENCE THAT DOES NOT EXIST (round 3, F-D3-1)

It reads as a category: *"an IV starting at a runtime value MUST decline … if this ever accepts, leg 1b has
become an over-accept."* **That is false as a rule.** Measured (`review_r3_probes/rc6`):
`if (u > 0) for (i = u; i < u+3; i++) if (i == u)` is a runtime-start IV that reaches leg 1b and **ACCEPTS,
soundly**. `a5` declines because **SCEV cannot decide**, not because the start is runtime.

⚠ This is the L7 hazard in its exact shape — a future widener reads a non-existent fence and either respects
it forever or "retires" it and thinks they have licensed something. Reword to say what is true: *the a5 row
is a SCEV-decidability boundary, not a runtime-start boundary.*

## 2. Counts — re-measure, never copy (Rule 19)

`ctest --test-dir build -N` · `ls ir-pass/test/*.ll | wc -l` · `ls tests/e2e/*.expected.log | wc -l` ·
`grep -c '^m_' tools/loop_twin_matrix.expected.txt` + `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt`.
Known to have moved: the twin matrix (259+29=288 → 309+29=**338**), the fixture count (every track), goldens,
ctest entries. `trackL/SCOPE_L1a.md` §5's blind-spot row (`grep -c -i bool` == 2) is now stale and should be
annotated rather than silently left.

## 3. `CLAUDE.md` — consume `CLAUDE_MD_EDITS.md`

Two blocks are authored by the tracks that measured them and are to be carried VERBATIM: Track F's
φ-descendant availability paragraph (§1 there) and Track U's bd `z9t1` disclosure, whose NORMATIVE copy is
`IMPL_U.md` §2(b′) in the `undef-seed-zero` worktree. Plus the proposed L10-neighbourhood lesson on
instruments (§2 there) — six measured instances this session, all reporting a PASS.

## 4. The owner's two open items, to carry into the handoff

* **F-U1-1** — the `LiteralIntegrity` GUARD 1 count drop at CQ type `double`, where the seed and the angle
  share the LLVM type. Measurements point AWAY from restoring the decline (the genuine pairing hazard still
  fires; the survivor occupies one slot; the result is deterministic; the project already ships a
  materialized undef in a golden; population is zero). Round 2 added a fifth outcome — a SIGABRT on 2 of
  1922 mutants, pre-existing and not C-reachable.
* **F-U3-1** — the φ clause disarms ruling clause 4 UPSTREAM of the sink: `cq_measure` of an undef declines
  by the ruling, but the clause deletes the undef before `MeasureLowering` sees it. 4 of 710 rows, all
  byte-identical to the written-zero twin, and the DIRECT spelling still declines.

## 5. bd hygiene

Close what landed; leave open what is filed. `bd remember` per landed increment and per lesson — including
the measured effect of PROTOCOL §S1/§S2 (how many full suites this session actually cost, and whether the
closing citation held).
