# GATE FILINGS — session 2026-09-18 group gate (Group 1 + Track D)

Findings the MERGE ALONE could see: facts about the two branches TOGETHER, or about the gate
process, that neither track's own records could state. Each written so it can be `bd`-filed
verbatim. Binary: SUBJECT `96d74fe6008133b8`, ORACLE `9bd01598d574b344`.

---

## G-1 — **P1 (process, recurring): the composition is cleared BY MEASUREMENT AND BY NO REVIEW, for the THIRD CONSECUTIVE SESSION**

R20 routed Group 1 and Track D into one gate precisely so that `dD1` would become a composition
measurement rather than a shipped P1 widening. It did, and the measurement is clean
(`COMPOSITION.md`). **What it is not is a review.**

* Track D's Rule-13 round (`review_r13_trackD/REVIEW.md`, verdict `CLEAR-WITH-ITEMS`) read a binary
  on which `dD1` **leaks**; F-1 is filed against that binary.
* Group 1's Rule-13 round has **not delivered a verdict**: `review_r13_group1/` contains nine probes
  (`g1_threeblock_body_rot` … `g9_rail_read_only_in_arm_rot`) and **no `REVIEW.md`**.
* The accept that decides the landing — `dD1` compiling to a *discharged* circuit — was produced by
  this gate and adversarially reviewed by nobody.

CLAUDE.md §5 already carries this as an owed item ("a **Rule-13 opinion on the F × P composition**")
and its own generalisation: ***a composition is not cleared by clearing its parts***, which it notes
"has now cost a filing in each of three consecutive sessions". This is the fourth. Rule 2 is explicit
that a green multiset/twin/2b result is **necessary and not sufficient**.

**Disposition:** the final independent Rule-13 round's subject is the COMPOSITION (R20 says so).
Until it runs, the landing is *gated* but not *cleared*. Both changed files
(`Uncomputation.cpp`, `LoopLowering.cpp`) are named in Rule 13's core list, and so is
`ArmClassify.cpp`.

## G-2 — **P1 → now benign, but the record must say which binary it is true of: F-1's `dD1` over-accept does not exist on the merged tree**

`review_r13_trackD` F-1 is a correctly-filed P1 **about Track D's binary**. On the combined binary the
same module compiles with the rail discharged, `0 left dirty`, no warning, multiset identical to its
hand-unrolled twin. **The finding is not withdrawn — it is scoped.** Anyone reading F-1 without
`COMPOSITION.md` beside it would conclude a P1 shipped; anyone reading only this gate would conclude
Track D never had a defect. Both are wrong.

⚠ The direction that matters for `bd s82e`: **Group 1's P2 also closes the PRE-EXISTING member**
(`dD5`), which accepted dirty-with-a-warning on the ORACLE and on Track D's binary alike. That is a
reduction in `s82e`'s population, measured, and it is the first such reduction this class has had.

**Disposition:** annotate bd `s82e` and bd `drbq.12` with the combined-binary numbers; do NOT close
`s82e` (the `t5j` residual warnings show the class survives for *measured* rail members, and `dD2`/
`dD6`-style benign leaks are untouched).

## G-3 — **P3 (doc, L7-with-a-twist): the merge agent's own reading list carried a correction that had been applied only in its sibling**

`trackT2/QUARANTINE_HANDOFF.md` §2 states:

> **`^e2e-`: NOT RUN HERE, and this branch adds NO e2e entry** — `tests/e2e/CMakeLists.txt` is
> **untouched**, so there is no tail-anchor conflict to resolve from Group 1 …

That is false at the delivered tip: the branch adds **+43 lines** to `tests/e2e/CMakeLists.txt` and
two slices with two goldens. `trackT2/IMPL_T3.md` §6.2 item 2 **corrects exactly this** and cites the
rule by name — *"An earlier revision of this file said 'No e2e slice was added'; that was true when
written and is now false — corrected at the site rather than left to a reader to reconcile
(`CLAUDE.md` L7-with-a-twist)"* — but the correction was not carried into `QUARANTINE_HANDOFF.md`,
which is the file the merge-and-gate brief names as required reading.

Direction: **safe** (it under-promises a conflict, and the three post-union checks are what actually
establish the union). Species: identical to `MERGE_FILINGS.md` F-1/F-2/F-5 and to bd `z9t1`'s
three-round lesson. **Recommendation for the next PROTOCOL:** a hand-off file that states another
file's file-surface must either cite it by `git diff --stat` output or not state it.

## G-4 — **P3 (doc/policy): `--allow-unproven` is now FIVE slices, and CLAUDE.md says four**

Measured: actual flag usages (not comment mentions) go **4 → 5**. The new one is Group 1's
`e2e-slice-loop-hoisted-chain-exit-discharge`.

CLAUDE.md's stage-2b paragraph says *"**Four** `e2e-slice-loop-break*` entries pass `--allow-unproven`
with a written reason … **every other slice runs strict**, and a new `--allow-unproven` needs a reason
of that kind."* The fifth entry **is not** a `loop-break` slice, so both the count and the naming
pattern are now stale.

**The reason given does meet the bar**, and it is recorded in the CMakeLists at the call site: a
discharge placed at a LOOP EXIT is `U3-extern-rail` UNPROVEN *by construction*, because
`free_pairing_check.py` analyses per straight-line STREAM — structural, like the dtzb reverse-play
reason, not a concession. It is measured on both halves (rolled `1 verified, 0 violation(s), 3
unproven`; twin `5 verified, 0 unproven`) and compensated by a POSITIONAL pin in
`ir-pass/test/loop_pairing_accept_hoisted_chain_exit_discharge.ll`.

**Disposition:** routed to the closing docs pass with `MERGE_FILINGS.md` F-3/F-6. This is a real
widening of the set of slices whose stage-2b result is not strict, and it should be visible as such
rather than absorbed.

## G-7 — **P1 (instrument, needs an OWNER/Track-V decision): `e2e-loop-twin-matrix` can no longer speak for 24 cells + 1 pinned boundary control, because Group 1's P2 makes `UNPROVEN` the normal stage-2b answer**

Measured: **24 cells and the boundary control `q_armoncond` return `HARNESS-ERROR`**, every one with
the identical cause — `rolled side: stage 2b (free_pairing_check, STRICT) failed: … UNPROVEN
U3-extern-rail` — and every one reporting **`0 violation(s)` and `0 … left dirty`**. The rails ARE
discharged; `free_pairing_check.py` models a straight-line STREAM and P2 puts the discharge at the
**loop exit**, a different stream from the mint, so `UNPROVEN` is structural.

The matrix's policy is deliberate and says so at the site (`loop_twin_matrix.py:2156`): *"Stage 2b —
STRICT. A cell that needs `--allow-unproven` is not a cell this gate can speak for, and saying so
loudly is the point."* It was right when written. It now collides with a capability.

**Consequences measured at this gate, not predicted:**

1. **The matrix cannot be regenerated to green at all** — a `HARNESS-ERROR` has no verdict to record,
   so no `--regenerate` and no `--refresh-quarantine` can clear those 25.
2. **The six cells that watch class A (bd `1m5p`) are among them**, so the instrument went blind to
   class A **on the very run in which class A changed**.
3. It printed **`QUARANTINE STALE — REMOVE IT`** for those six — an instruction which, followed,
   deletes the only cells that watch the class. It is an artefact: the verdict is `HARNESS-ERROR`, so
   the stale-check fired on a cell whose traces were never compared. **The stale check and the
   harness-error check are not ordered defensively** (G-7a below).

**Options, costed (recommendation labelled as such, not a ruling):** (a) run the rolled side's 2b with
`--allow-unproven` — the instrument stops seeing genuine dirty-rail regressions on those cells, which
is the F-4 class it exists for; (b) teach `free_pairing_check.py` a cross-stream model so a loop-exit
discharge can be *verified* — a real increment with its own Rule-13 round; (c) leave it red — Rule 19
verbatim, *"a gate expected to be red is a gate people stop reading."*
**Recommend (b), with (a) as an explicitly time-boxed stop-gap recorded in the quarantine header.**
⚠ **`tools/loop_twin_matrix*` is Track V's EXCLUSIVELY (R14); I changed nothing.**

### G-7a — **P2 (instrument, L10): a cell whose verdict could not be COMPUTED is reported as "no longer diverging"**

`QUARANTINE STALE — REMOVE IT` and `HARNESS-ERROR` are emitted for the same cell in the same run, and
they contradict each other. A cell that errored should be reported **unmeasured**, never as
*stale*, because "stale → REMOVE IT" is an instruction to delete a gate. This is the L10 species —
an instrument stating a conclusion it did not measure — and it is in the dangerous direction.

## G-6 — **P1 (population, and it answers an open question nobody had the number for): `review_r13_group1` F-1's HAZARD already ships in 2 registered goldens whose headers carry the Rule-6 sentence CLAUDE.md §5 has already ruled FALSE**

Full record and method: `BLAST_RADIUS_g8.md`. Measured on the COMBINED binary over **383 of 386
shipped e2e slices** (complete; 3 skipped as `*_lib.c` halves).

**The shape** — a TEMPLATE rail that is never `_unc`'d and never freed, copying a register `S`, with a
NON-DIAGONAL gate on `S` later — occurs in exactly **2** shipped slices, and **both are registered
goldens with passing ctest entries**:

| file | dirty | trailing gate | shipping golden? |
|---|---|---|---|
| `tests/e2e/slice_control_inplace_ry_loop_leak.c` | 1 of 2 | `cq_template_mul_i32_hl->h3` copies `h2`; later `cqrt_ry_i32_controlled` **targeting `h2`**; `h2` then MEASURED | **YES** |
| `tests/e2e/slice_control_inplace_ry_loop_leak_unrolled.c` | 2 of 4 | identical, both repetitions | **YES** |

**Both headers assert** *"IT IS RULE-6 CORRECT AND IT IS NOT A REGRESSION. Every leaked rail is LEFT
ALLOCATED; none is freed dirty."* For these two programs that sentence is **false by CLAUDE.md §5's
own Q-R1-1 CORRECTION**, which already ruled it false for three sibling fixtures: *"Where the same
register is rotated by a NON-DIAGONAL gate after the loop and then measured, it is a wrong unitary …
and the ACCEPT was the defect,"* and *"Rule 6 governs whether a dirty rail may be FREED; it says
nothing about whether leaving it entangled is semantically free, and Rule 8 says it is not."* The
correction was applied to the three fixtures §5 names and **never propagated to these two slices** —
L7-with-a-twist again.

⚠ **Both halves of the answer are load-bearing and neither may be quoted alone.** The **HAZARD CLASS**
(bd `s82e`) is **already shipping**, so *"F-1 is probe-only"* is false. F-1's specific **DOOR** (a
marked multi-block body whose ARM mints an interior rail) is reached by **no shipped slice**, so
*"F-1 already ships"* is also false as stated. The two shipping hits arrive through the drbq
Increment-1 structural FREEZE instead.

⚠ **No gate in the tree would go red if this were a miscompile.** All three entries pass — and
`e2e-inplace-ry-loop-leak-twin-identical` passes **because both halves leak the same rails in the same
order**, which is CLAUDE.md's own trap: *"a cell whose two halves agreed because BOTH were wrong is
precisely what `ACCEPT-IDENTICAL` cannot see; only a fence can."*

**Disposition:** file against bd `s82e` with these two slices named; the header correction is owed in
the same change as any fence (L7-with-a-twist: a correction not applied where the claim lives is not
one). **Do not silently regenerate these goldens** — they pin the leaking stream deliberately.

⚠ **The instrument that produced this number reported a clean pass on its first run** and was caught
only by validating it against a known positive first (`-q` suppresses `free_pairing_check`'s census
line, so every module scored `0 dirty`). Had it not been attacked, this filing would have read
"F-1 is probe-only." Recorded because the near-miss is the point, not a footnote.

## G-5 — **P3 (instrument gap, carried not new): stage 2b cannot witness what Group 1 landed, and the twin matrix is therefore load-bearing for this gate**

`trackT2/QUARANTINE_HANDOFF.md` §2 states it and this gate confirms it on three independent modules
(`dD1` 1 unproven, `dD5` 1 unproven, `t5j` 2 unproven): every rail this increment discharges is
TEMPLATE-minted, and STRICT stage 2b has no `cqrt_alloc` to count for those — worse, a discharge at a
JOIN or LOOP EXIT is reported `UNPROVEN` rather than verified. **So a green stage 2b says nothing here
in either direction**, and the evidence for the landing is (a) the gate-symbol multisets against
hand-unrolled twins, (b) the `_unc`/`free` census read off the trace, and (c) `e2e-loop-twin-matrix`.

This is the same structural blindness CLAUDE.md records for the C-1 leak family and that
`MERGE_FILINGS.md` F-6 says is now only *partly* true (the CENSUS layer gained
`N template rail mint(s) of which M left dirty` at `95949550`). **This gate used that census as its
primary numeric witness** — `0 left dirty` is exactly the segment F-6 describes — so F-6's correction
is load-bearing, not cosmetic.

---

# PASS-2 DISPOSITIONS — what the two extra landings did to the filings above

Measured at SUBJECT `07d937842bfb5135` (Group 1 + D + Group 1's F-1 fix + Track C). ⚠ Every number
here is re-measured at that hash; none is carried from pass 1 or cited from a track's hand-off.

## G-4 — **RESOLVED.** The exception is gone, not widened

Track C's (T4) rule proves all three `U3-extern-rail` rails, so the flag and its reason were removed:
`1 verified / 3 unproven / rc=1` → **`4 verified / 0 unproven / rc=0`**. Actual `--allow-unproven`
count **5 → 4**, and all four survivors are the `dtzb whole-loop reverse-play` loop-break entries —
**CLAUDE.md's "Four `e2e-slice-loop-break*` entries" sentence is true again.** This is the good
outcome the filing asked for: the instrument was taught to prove the shape rather than excuse it.

## G-7 / G-7a — **RESOLVED for the cause, and the artefact question is retired with it**

The 24 `HARNESS-ERROR` cells and the `q_armoncond` control were the checker's per-stream model
meeting P2's loop-exit discharge. (T4) proves that shape, so those cells verdict normally again and
the "QUARANTINE STALE — REMOVE IT" artefact cannot arise from this cause. ⚠ **G-7a's underlying
instrument defect is NOT fixed** — the stale-quarantine check and the harness-error check are still
not ordered defensively, so a cell that errors for some *other* reason would still be reported as
"no longer diverging". It is filed as a bead against Track V's file and must not be closed by this
gate's green.

## G-6 — **HALF closed, and the surviving half is now under no gate at all**

| the 2 shipping goldens | pass 2 |
|---|---|
| `slice_control_inplace_ry_loop_leak.c` (ROLLED) | **DECLINES** — pinned by `loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll` |
| `…_unrolled.c` (TWIN) | **still ACCEPTS at exit 0**, identical hazard, loop-free |

Both entries were unregistered and both goldens deleted, so **the surviving hazard is observed by
nothing in the suite.** That is the *correct* disposition — pinning it would pin a known-wrong
stream, which CLAUDE.md forbids for exactly this family — but it means the new P1 is **unwitnessed
until its fence lands**, and a green suite from here on says nothing about it. The `.c` is kept with
an L8 retirement trigger.

⚠ **A limit I declared in G-6 is now closed in the STRENGTHENING direction.** I wrote that the
detector could not tell whether `cqrt_tape_write_i32` collapses `h3`, and that "if it does, the two
hits weaken". Group 1's fixture header settles it: the tape write **copies and does not collapse**,
and only the *result* (`h4`/`h7`) is an `OutputRails` member while the *operand* `h3` is an ordinary
interior template rail. **The hits were real, and the caveat is retired rather than left standing.**

## G-1 — **UNCHANGED and now larger.** The composition still has no Rule-13 opinion

Four landings now compose in one binary (Group 1 P1+P2, Group 1's F-1 fix, Track D's P4, Track C's
(T4) checker). `review_r13_group1` reviewed Group 1 *before* its own fix; `review_r13_trackD` reviewed
D on a binary where `dD1` leaked; **nobody has adversarially read the four together.** This gate's
evidence — verdicts, multisets, STRICT 2b, byte-diffs — is what Rule 2 calls *necessary and not
sufficient*. **Fourth consecutive session for this filing.**

## G-2 / G-3 / G-5 — carried unchanged

G-2 (F-1's scoping) is now historical for the ROLLED half. G-3 (the stale `QUARANTINE_HANDOFF` claim)
and G-5 (stage 2b's structural blindness) stand — though G-5 is *narrower* than it was: (T4) removes
the loop-exit case from the blind set, which is why `dD1`/`dD5` went `1 unproven → 0`.

## G-8 — **NEW (P3, process): a check of mine printed a verdict it had not measured**

Before merging Track D's records-only tip I ran a guard that printed `[empty = safe]` from an
**unconditional `echo`**, beside a diff taken in the wrong basis that actually listed 30 files. The
label was meaningless; the conclusion happened to be right, which is the dangerous case. Re-verified
properly (`HEAD~1..HEAD`: 610 insertions, 0 deletions, nothing under `ir-pass`/`include`/`runtime`/
`tools`/`tests`). Recorded because it is the same species as the blast detector's false CLEAN and as
every instrument in CLAUDE.md L10: **a guard whose pass message is not computed from its own
measurement is not a guard.**

## G-9 — **NEW (P2, instrument): my matrix parser reported a quarantine verdict it did not read**

`gate/probes/parse_matrix.py` labelled the six class-A `oder` cells `(not quarantined)`. The matrix
prints **two** lines for those cells — first `ROLLED AND UNROLLED TRACES DIFFER`, then
`QUARANTINED SIGNATURE CHANGED — this is a red, not a refresh` — and my parser keyed on the first and
never read the second.

**Consequence had I acted on it:** six NEW quarantine blocks authored for cells that already have
blocks and need only `--refresh-quarantine`, i.e. duplicate rows for one defect — and, worse, the
*wrong operation*, since a refresh re-pins a known class while a new block asserts a new one.

Caught by reading the matrix's own raw text instead of trusting my summary of it. **The general form
is the one this gate keeps re-learning: a parser is an instrument, and an instrument that summarises
a report can drop the half of the report that matters.**

## G-10 — **NEW (P2, method): a signature from one renderer is not comparable to a signature from another**

`PASS2_PREP` (B) recorded my `ctlprobe.py` signature `3fa9d45cd851c1b3` for `q_armoncond` and made it
the **retirement trigger's comparison key** — *"if the pass-2 signature differs … re-derive."* The
matrix reported `d81485c481c5ad07`, the trigger fired, and I re-derived.

**The trigger had misfired.** Re-measured at pass 2, the control's divergence is **byte-identical to
pass 1** — same 24 == 24, same multiset equality, same first differing line, and my tool returns
`3fa9d45cd851c1b3` again. The two numbers were never comparable: both call themselves "sha-256 of the
unified diff", but mine is over `difflib`'s rendering at `n=1` and the matrix's is over its own. **I
had even written "none of these signatures may be pinned" — and then used one as a comparison key
anyway**, which is the same mistake one sentence later.

Same species as PROTOCOL S3's *"lowered-IR md5s are NOT comparable ACROSS sweeps"*, one layer up.
**Recommendation for the next PROTOCOL:** a retirement trigger keyed on a digest must name the
renderer that produced it, or key on something renderer-independent (here: the first differing line
pair and the counts, which WERE stable and would have given the right answer).

⚠ Direction: **safe but costly** — a misfiring trigger spends a re-derivation, where a missing one
would have shipped a stale argument. It is the correct failure direction, and the fix is to make the
key honest rather than to weaken the trigger.
