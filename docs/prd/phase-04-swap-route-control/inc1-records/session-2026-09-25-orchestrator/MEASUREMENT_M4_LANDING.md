# bd `fn1q` increment 5a — the ROUND-2 P1 and the M4 FIX, verified by the orchestrator

```
ORACLE   9b9664170fb33f95   git HEAD a9a227e4, no patch   (rebuilt CLEAN after the reviewer
                                                           reused wt-oracle as a mutant tree;
                                                           reproduced BIT-IDENTICAL)
SUBJECT  5fd7183282ee0d38   HEAD + increment 5a as it stood
M4       fe5805a41df2e173   SUBJECT + the placement conjunct
```

## 1. THE P1, REPRODUCED INDEPENDENTLY BEFORE ANY FIX WAS APPLIED

Round 2 (`REVIEW_R13_R2_INC5A.md`) returned **BLOCKED, 1 P1**. I did not take it on trust.
Re-measured from the reviewer's exhibit (`probes/r13r2/c13.c`, six lines of ordinary `CQ.h`
C, `clang -O1`, no `volatile`):

| binary | rc | stderr |
|---|---|---|
| ORACLE | 1 | **113 bytes** — `cq controlled lowering: control flow under quantum control` |
| SUBJECT | **0** | **0 BYTES** |
| M4 | 1 | the ORACLE's string, byte for byte |

And the emitted circuit is WRONG, checked by me and not quoted:
* `grep -c 'icmp (sgt|slt).*5'` on the lowered module → **0**. The inner `q > 5` compare is
  ABSENT; only the outer `icmp_sge` survives (3 `cq_template_icmp_sge_i32_hl`).
* the rail `%h6` is `cqrt_alloc_i1` + `cqrt_ry_i1` + `cqrt_measure_i1` and appears as a
  CONTROL operand **nowhere** — every `cqrt_copy_i32_controlled` is controlled by
  `%h_cmp`/`%h_cmp2`, both from the outer compare.
* `free_pairing_check.py`: **`2 verified, 0 violation(s), 0 unproven`** — the Rule-6 gate is
  structurally blind to it, as its own file header predicts for this class.

⚠ **IT IS NOT A DEFECT IN ROUND 1's FIX.** Hunks 3 and 4 are each mutant-validated
load-bearing (M2a / M2b both still mis-accept the exhibit). The P1 is in HUNK 2, the
original E6 admission. **The session's "round 2 finds a defect in round 1's fix — three for
three" streak is BROKEN at four**, and that is worth recording precisely because the brief
predicted otherwise: the operating rule "a fix is a change" survives, but "the fix is where
the next defect lives" did not hold here.

⚠ **AND IT IS THE ORCHESTRATOR'S OWN HYPOTHESIS A2 WITH A WORSE ENDING THAN PREDICTED.** I
handed the reviewer A2 as *"`buildNegation` has a SECOND unchecked cast and hunks 3+4 guard
only the first"* and expected a CRASH. The cast is ASSERTION-ONLY (`(void)TC`), so Release
does not crash: it returns `and(¬EP, ¬true)` = **false**, the arm's edge predicate goes
constant-false, its value is dropped from the merge and its cone is dead-swept — so nothing
off-grammar survives for a downstream owner to object to. **A predicted crash that is
actually a silent miscompile is the worse of the two, and the difference was invisible to
reading; only the +Asserts build and the emitted stream separated them.**

## 2. THE FIX, AND WHAT I VERIFIED RATHER THAN INHERITED

M4 gates the E6 rail-φ arm on the φ being one the flatten will **not** convert (the mirror
of `isConvertiblePhiCond`'s condition 2), and **FALLS THROUGH** rather than returning — the
reviewer's first spelling returned, which declined an all-constant interior `i1` φ that both
ORACLE and SUBJECT accept byte-identically (2 A→D cells in NEITHER the corpus NOR round 1's
probes). A fix is a change.

| check | result |
|---|---|
| my M4 build vs the reviewer's | **BIT-IDENTICAL**, `fe5805a41df2e173` |
| the P1 exhibit | declines, ORACLE's string, `gate=E6-condtree` |
| `example/grover/grover_oracle_uncompute.c` | **lowered module BYTE-IDENTICAL to SUBJECT's**, exit 0, 0 bytes stderr, 130 lines, 2b STRICT `3 verified, 0 violation(s), 0 unproven` |
| `lit ir-pass/test` | **2154 discovered, 2153 passed, 1 XFAIL** (85.16 s, load 149) |
| new fixture on M4 | PASS |
| new fixture on the DEFECTIVE binary | **FAIL** (mutation-validated both directions; binary restored and sha-checked afterwards) |

⚠ The `lit` run matters because the reviewer's own boundary says its A/B *"compares exit
code, the decline string and the emitted IR and does NOT evaluate any fixture's directives"*
— so "0 movers of 2154" was never "lit is green". Both now hold, measured separately.

## 3. THE NEW FIXTURE, AND THE LESSON IT COST

`ir-pass/test/control_predmux_reject_rail_phi_interior_convertible.ll` — `clang -O1` output,
unedited but for renaming `@main`, stripping attribute groups and dropping `!tbaa`.

⚠ **PROVENANCE IS LOAD-BEARING HERE**: every hand-written interior-φ IR probe (the
reviewer's `p1`/`p2`, and three of mine) dies at `gate=W-witness` instead, because a φ with
two in-region predecessors is a JOIN and tends to BE the region's merge. The shape needs an
outer region that actually claims, and `-O1` produces one where hand-construction did not.

⚠ **AND ITS FIRST DRAFT WAS RED FOR A REASON THAT WAS ENTIRELY ITS OWN COMMENT.** The header
spelled a FileCheck directive prefix in prose; FileCheck created a directive from the
SENTENCE and tried to match it. That is CLAUDE.md's standing lesson — *naming a directive in
prose creates one* — **paid for the third time in three sessions**, this time in a header
whose subject is a silent miscompile. The corrected header says so and carries the warning
above the RUN lines.

## 4. WHAT IS STILL OWED — M4 IS NOT CLEARED

M4 is a **NARROWING of an accept predicate**, so L3 applies and it owes:
* its own **Rule-13 round** by an agent that did not write it (this is round 3 for 5a);
* the corpus A/B and full `ctest -j6` (running at the time of writing; `lit` is green);
* ⚠ a filed **over-decline**: the interior rail φ it now refuses is REALIZABLE, so by the
  2026-09-11 owner ruling it is compiler structure, not physics. The route that would make
  it lower is to RECORD the φ so `convertPhis` cannot select-chain it — which removes the
  defect rather than hiding it. The fixture carries that retirement trigger.

Round 2's other open items (both P2): the increment's central claim *"no decline becomes
silence"*, written in four places, is now measurably FALSE; and `buildNegation`'s select arm
never tests `isOne()` while `canonicalizePred`'s twin does — a latent wrong-predicate hole
**no `+Asserts` build can see**. Plus the P3 that explains why this whole family has no
gate: **the tree has never had a `+Asserts` `cq-opt`, because building one aborts on four
committed ACCEPT fixtures, all pre-existing.**

## 5. THE INSTRUMENT LESSON THIS SESSION PAID FOR, IN ITS GENERAL FORM

CLAUDE.md Rule 19 says *"never relink a binary under a running measurement"*. **That is a
special case of a wider rule, and the wider one is what actually bit, three times in one
day:**

> **A MEASUREMENT'S INPUTS ARE MUTABLE AND SOMETHING ELSE OWNS THEM.**

| instance | what changed under what | how it was caught |
|---|---|---|
| Round 2's reviewer built mutant M2a into `wt-oracle` | the ORACLE BINARY became a second SUBJECT | a hash recorded earlier had changed — **only** because it had been recorded |
| The orchestrator ran two corpus sweeps concurrently over fixed `/tmp` scratch paths | each sweep's per-module intermediates | a 260-mover count against a reviewer-measured 0 — **implausible enough to re-check** |
| (a peer session, different repo, same box, same day) a mandated commit-splitting procedure edited a tracked source file in place while its test gate ran | the SOURCE the gate was regenerating goldens from | the agent noticed and killed the run rather than trusting it |

⚠ **THE THIRD ONE IS THE MOST INSTRUCTIVE AND IT IS NOT OURS.** The mutation arrived through
a procedure that repo's own rules PRESCRIBE — so following the rules is what walks you into
it. Rule 19's wording ("relink", "binary") does not reach a SOURCE file mutated by a
sanctioned workflow, and it does not reach shared scratch either. Both are the same defect.

**Operational consequences adopted here:**
* every sweep gets its own `mktemp -d`; two sweeps never share scratch (fixed, re-validated
  against a null AND a positive control);
* every mutant is built into a worktree whose NAME says what it is — `wt-oracle` was renamed
  `wt-m4` the moment it stopped being an oracle;
* a baseline binary's sha is RECORDED at the moment it is built, because "the hash changed"
  is the only detector that fired on its own;
* source-comment corrections owed to this increment (round 2's four measurably-false
  "no decline becomes silence" sites) are **deliberately HELD while round 3 reviews the
  code**. The first reason is the one above — a reviewer verifying against a tree that never
  existed as a commit is the same defect one level up. ⚠ **THE SECOND REASON IS BETTER AND
  IT IS NOT ABOUT CONFLICT AT ALL** (owed to the peer session that supplied the
  generalisation): land them mid-audit and no later reader can tell whether the verdict was
  reached BEFORE or AFTER them, so **the verdict stops being attributable, which means it
  stops being evidence.** Holding costs minutes; not holding costs the clearance.

⚠ **AND THE IN-REPO PRECEDENT FOR THE HASH-PINNING DETECTOR ALREADY EXISTS — cite it rather
than the principle.** `tools/loop_twin_matrix.quarantine.txt` pins each blessed divergence by
`(verdict, SHA-256 of the exact unified diff)` and fails if the signature moves, if the cell
stops diverging, or if it appears in both files. Any new guard of this kind is copying that,
not importing an idea.

## 6. ROUND 3 ON M4 — `CLEAR-WITH-ITEMS`, 0 P1 (`REVIEW_R13_R3_M4.md`)

M4 holds. It restores the ORACLE's verdict, string **and whole `CQ_PREDMUX_DBG` gate trace
byte-for-byte** on the exhibit — so it is a pre-claim decline, not a claim-then-decline —
and it closes **FOUR measured instances of the P1 class, not one** (`c13`, `p4_jlast`,
`p6_nomeasure`, `p9_twofunc`, plus the round's own `x3`).

| gate | result |
|---|---|
| ORACLE ↔ M4, 2155 fixtures | **1 mover** (the increment's own accept fixture), 0 A→D, 0 crash-flips, 0 stream moves |
| SUBJECT ↔ M4, 2155 fixtures (orchestrator's independent sweep) | **A→D=1** (the new decline fixture — the intended direction), D→A=0, decline-string=0, stream=0 |
| owner's program | rc=0, 0 B stderr, lowered module byte-identical to SUBJECT's, 2b STRICT `3 verified, 0 violation(s), 0 unproven`, **88 trace lines byte-identical to the golden** |
| `lit ir-pass/test` | 2155 / 2154 passed / 1 XFAIL |

⚠ **TWO P2s STAY OPEN AND BOTH ARE ABOUT THE SAME CONJUNCT** — bd `woa0` (the conjunct is a
POINT-IN-TIME property: an inner region's flatten makes a block's terminator unconditional,
so the outer region's E6 loop — which walks only CONDITIONAL terminators — stops seeing the
rail φ on the next fixpoint pass, claims, and converts it; **L1's shape one stage over**,
landing on a loud decline only via round 2's "downstream accident, not a fence") and bd
`0fly` (the conjunct over-admits exactly `{R.Merge}`, held closed by an UNWRITTEN
E3-derived dominance argument; fires 22× in 18 modules, exactly one takes the `!InRegion`
branch).

⚠ **AND ROUND 3 CAUGHT A MISTAKE OF MINE THAT IS THIS SESSION'S OWN GENERALISATION BITING
BACK.** I renamed the reviewer's mutant tree `wt-oracle` → `wt-m4` with `git worktree move`
so its name would stop lying — but a CMake build directory bakes ABSOLUTE paths, so
`wt-m4/build` was still configured against the deleted `wt-oracle` and **the sources round 3
was reading were never the ones compiled.** The reviewer closed it by building the landing
source itself, bit-identical to `fe5805a41df2e173`. *A measurement's inputs are mutable and
something else owns them* — I wrote that in §5 and then did it, two tool calls later, in the
act of fixing a different instance of it. **Renaming a worktree invalidates its build dir;
re-configure or rebuild before handing it to anyone.**

⚠ Round 3's own instruments **lied twice before its controls caught them**: a corpus sweep
that reported 0 events because `export -f` does not work under zsh, and a null control set
to the EMPTY STRING, which `getenv` reports as PRESENT. Both re-run. That is three sessions
running in which the reviewing agent's instrument failed before the code did.


## 7. ⚠ THE POSITIVE CONTROL THREW A FALSE RED, AND I CAUSED IT — the third instance in one session

```
[M4REAL]  SUBJECT vs M4   n=2155  A->D=1  D->A=0  decline-string=0  stream=0
          A->D  control_predmux_reject_rail_phi_interior_convertible.ll   <- the NEW fixture,
                                                                             INTENDED direction
[POSCTL]  ORACLE  vs M4   n=2155  A->D=1  D->A=1  decline-string=0  stream=0
          D->A  control_predmux_accept_rail_phi_cond.ll                   <- 5a's own accept
          A->D  spec_accept_undef_outside_return_cone.ll                  <- ⚠ RETRACTED
```

**The `A->D` row is RETRACTED as CONTENTION.** Re-run SERIALLY on a settled box: `rc=0` on
BOTH binaries, **3 of 3 runs each**, and `lit` passes that fixture on M4. Round 3's
independently measured `0 A->D` for ORACLE↔M4 STANDS; my sweep was wrong, not the fix.

⚠ **THE CAUSE WAS MINE: I started the full `ctest -j6` while the POSCTL sweep was still
running.** Load went 6.7 → 132 across it. CLAUDE.md's Rule 19 says in as many words that
*contention causes false FAILURES, never false passes* and to re-run any red serially
BEFORE calling it a regression — and this is the THIRD instance of "a measurement's inputs
are mutable and something else owns them" that I produced in this one session, after the
shared-scratch sweeps and the worktree rename that invalidated a build dir.

**The distinction that made it cheap to resolve, and it is the same one as §5's:** a
verdict flip is read from an EXIT CODE, so contention can starve a process into a
non-zero exit and manufacture a false `A->D` — while a PASS under contention is still a
pass, because starvation cannot make a wrong answer right. So the concurrent `ctest`'s
GREEN rows need no re-run, and its RED rows would have. Same run, two different
reliabilities, exactly as in §5.
